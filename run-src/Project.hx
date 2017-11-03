import haxe.DynamicAccess;
import haxe.Json;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

using StringTools;

class Project {
  public static var PROJECT_CONFIG:String = "plumob.json";
  
  public static var REQUIRED_CONFIG:Array<String> = [
      "name", "package", "targets"
    ];
  public static var ALL_CONFIG:Array<String> = [
       "name", "slug", "package", "version", "default-target", "build-dir"
      ,"env", "assets", "targets"
    ];
  
  public static var REQUIRED_TARGET:Array<String> = [
      "name", "arch"
    ];
  public static var ALL_TARGET:Array<String> = [
      "name", "arch", "haxelibs", "build-flags-haxe", "deploy", "test"
    ];
  
  public static function check(dir:String):ProjectStatus {
    dir = FileSystem.absolutePath(dir);
    if (!FileSystem.exists(dir) || !FileSystem.isDirectory(dir)) {
      return NoPath;
    }
    var configPath = Path.join([dir, PROJECT_CONFIG]);
    if (!FileSystem.exists(configPath)) {
      return NoConfig;
    }
    return (try {
        var c = Json.parse(File.getContent(configPath));
        OK(new Project(c));
      } catch (e:ProjectStatus) {
        switch (e) {
          case Misconfig(_): e;
          case _: throw e;
        }
      } catch (ex:Dynamic) {
        Error(ex);
      });
    /*
    var any = false;
    var all = true;
    for (f in PROJECT_FILES) {
      if (FileSystem.exists(Path.join([dir, f]))) {
        any = true;
      } else {
        all = false;
      }
    }
    return (if (any && all) {
        ProjectFull;
      } else if (any) {
        ProjectExists;
      } else {
        NoProject;
      });
    */
  }
  
  public var name:String;
  public var slug:String;
  public var pack:String;
  public var version:String;
  public var defaultTarget:String;
  public var buildDir:String;
  public var assets:Array<String>;
  public var env:DynamicAccess<String>;
  public var targets:Array<Target>;
  public var activeTarget:Target;
  
  public function new(configRaw:Dynamic) {
    var config:DynamicAccess<Dynamic> = configRaw;
    for (c in REQUIRED_CONFIG) {
      if (!config.exists(c)) {
        throw ProjectStatus.Misconfig("missing required config key: " + c);
      }
    }
    for (c in config.keys()) {
      if (ALL_CONFIG.indexOf(c) == -1) {
        throw ProjectStatus.Misconfig("invalid config key: " + c);
      }
    }
    name = config.get("name");
    slug = (config.exists("slug") ? config.get("slug") : name.replace(" ", ""));
    pack = config.get("package");
    version = (config.exists("version") ? config.get("version") : "1.0.0");
    buildDir = (config.exists("build-dir") ? config.get("build-dir") : "build");
    assets = (config.exists("assets") ? config.get("assets") : []);
    env = (config.exists("env") ? config.get("env") : {});
    if (env.exists("hxcpp_path")) {
      XCProject.HXCPP_PATH = env.get("hxcpp_path");
    }
    var ctargets:Array<DynamicAccess<Dynamic>> = config.get("targets");
    function parseCommands(cs:Array<Dynamic>):Array<Command> {
      return [ for (c in cs) {
          if (Std.is(c, String)) {
            Command.Raw(c);
          } else {
            throw ProjectStatus.Misconfig("invalid command");
          }
        } ];
    }
    targets = [ for (t in ctargets) {
        for (c in REQUIRED_TARGET) {
          if (!t.exists(c)) {
            throw ProjectStatus.Misconfig("missing required target key: " + c);
          }
        }
        for (c in t.keys()) {
          if (ALL_TARGET.indexOf(c) == -1) {
            throw ProjectStatus.Misconfig("invalid target key: " + c);
          }
        }
        var arch = (cast t.get("arch"):Array<String>);
        for (a in arch) {
          if (Main.platform(a) == null) {
            throw ProjectStatus.Misconfig("invalid platform: " + a);
          }
        }
        var haxelibs:Array<String> = [];
        if (t.exists("haxelibs")) {
          haxelibs = (cast t.get("haxelibs"):Array<String>);
        }
        if (haxelibs.indexOf("plumob") == -1) {
          haxelibs.push("plumob");
        }
        {
           name: (cast t.get("name"):String)
          ,arch: arch
          ,haxelibs: haxelibs
          ,buildFlagsHaxe: (t.exists("build-flags-haxe")
              ? (cast t.get("build-flags-haxe"):Array<String>) : []
            )
          ,deploy: (t.exists("deploy") ? parseCommands(t.get("deploy")) : [])
          ,test: (t.exists("test") ? parseCommands(t.get("test")) : [])
        };
      } ];
    if (targets.length == 0) {
      throw ProjectStatus.Misconfig("no targets");
    }
    var tnames = [];
    for (t in targets) {
      if (tnames.indexOf(t.name) != -1) {
        throw ProjectStatus.Misconfig("duplicate target name: " + t.name);
      }
      tnames.push(t.name);
    }
    defaultTarget = (config.exists("default-target")
        ? config.get("default-target") : tnames[0]
      );
    if (tnames.indexOf(defaultTarget) == -1) {
      throw ProjectStatus.Misconfig("invalid default target");
    }
  }
  
  public function info():Void {
    Sys.println('name: $name
package: $pack
version: $version
defaultTarget: $defaultTarget
targets:');
    for (t in targets) {
      Sys.println('
  - name: ${t.name}
  - arch: ${t.arch}');
    }
  }
  
  public function findTarget(name:String):Target {
    if (name == null) {
      name = defaultTarget;
    }
    for (t in targets) {
      if (t.name == name) {
        return t;
      }
    }
    Main.error("target not found: " + name);
    return null;
  }
  
  private function productPath():Array<String> {
    var paths = [];
    for (p in activeTarget.arch) {
      for (pp in Main.platform(p).productPaths()) {
        if (paths.indexOf(pp) == -1) {
          paths.push(pp);
        }
      }
    }
    return paths;
  }
  
  private function runCommand(cmd:Command):Void {
    switch (cmd) {
      case Raw(raw):
      var t = (new haxe.Template(raw)).execute({
          product: {
             path: productPath()[0]
            ,filename: haxe.io.Path.withoutDirectory(productPath()[0])
          }
          ,name: name
          ,slug: slug
          ,"package": pack
        });
      var quoted = ~/"([^"]*)"|(\S+)/; // "
      var cn = [];
      while (quoted.match(t)) {
        cn.push(quoted.matched(quoted.matched(2) != null ? 2 : 1));
        t = quoted.matchedRight();
      }
      Main.runOrDie(cn.shift(), cn);
    }
  }
  
  public function select(name:String):Void {
    activeTarget = findTarget(name);
    for (p in activeTarget.arch) {
      Main.platform(p).select(this);
    }
  }
  
  public function build():Void {
    for (p in activeTarget.arch) {
      Main.platform(p).enable();
    }
  }
  
  public function deploy():Void {
    activeTarget.deploy.map(runCommand);
  }
  
  public function test():Void {
    activeTarget.test.map(runCommand);
  }
}

enum ProjectStatus {
  NoPath;
  NoConfig;
  Misconfig(?err:String);
  Error(?err:Dynamic);
  OK(p:Project);
}
