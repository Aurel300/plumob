import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import plat.*;

import Project.ProjectStatus;

class Main {
  static var PLATFORMS:Array<Platform> = [
      new IOSGroup([
           new IOS("arm64") // "ios-arm64"
          ,new IOS("armv7") // "ios-armv7"
        ])
      ,new IOSGroup([
          new IOS("sim") // "ios-sim"
        ], true)
    ];
  static var PROJECT_FILES:Array<String> = [
       "Main.hx"
      ,"plumob.json"
    ];
  public static var SELF:String;
  
  public static function error(reason:String):Void {
    Sys.println("error: " + reason);
    Sys.exit(1);
  }
  
  public static function projectError(status:ProjectStatus):Void {
    switch (status) {
      case OK(_): return;
      case NoPath: error("no such directory");
      case NoConfig: error("no project found");
      case Misconfig(err): error("project misconfigured: " + err);
      case Error(err): error(Std.string(err));
    }
  }
  
  public static function run(cmd:String, args:Array<String>, ?dir:String):Int {
    var oldCwd = Sys.getCwd();
    if (dir != null) {
      Sys.setCwd(Path.join([Sys.getCwd(), dir]));
    }
    Sys.println('$cmd $args');
    var ret = Sys.command(cmd, args);
    if (dir != null) {
      Sys.setCwd(oldCwd);
    }
    return ret;
  }
  
  public static function runOrDie(cmd:String, args:Array<String>, ?dir:String):Bool {
    if (run(cmd, args, dir) == 0) {
      return true;
    }
    error('command failed ($cmd)');
    return false;
  }
  
  public static function glob(test:EReg, dir:String):Array<String> {
    return [for (f in FileSystem.readDirectory(dir))
        if (test.match(f)) f
      ];
  }
  
  public static function copyOrDie(src:String, dest:String):Bool {
    try {
      Sys.println('cp $src $dest');
      File.copy(src, dest);
    } catch (ex:Dynamic) {
      error("copy failed");
      return false;
    }
    return true;
  }
  
  public static function platform(name:String):Platform {
    for (p in PLATFORMS) {
      var pr = p.find(name);
      if (pr != null) {
        return pr;
      }
    }
    error("platform not found: " + name);
    return null;
  }
  
  public static function main():Void {
    function usage(?code:Int = 0):Void {
      Sys.println("plumob usage:
haxelib run plumob help
                 ^ create
                 ^ info
                 ^ build
                 ^ deploy
                 ^ test");
      Sys.exit(code);
    }
    var args = Sys.args();
    SELF = Sys.getCwd();
    Sys.setCwd(args.pop());
    function run(args:Array<String>):Void {
      switch (args) {
        case ["help"]:
        Sys.println("plumob help:
haxelib run plumob help
  Displays this help.

haxelib run plumob create [<project>]
  Creates a new project.

haxelib run plumob info [<project>]
  Checks and prints info about a project.

haxelib run plumob build [<target>] [<project>]
  Builds the given project target.

haxelib run plumob deploy [<target>] [<project>]
  Deploys the given project target.

haxelib run plumob test [<target>] [<project>]
  Tests the given project target.

<project> is a path to an existing directory which should
  contain the file plumob.json if it contains a project.
  If this path is not specified, it defaults to the current
  working path.

<target> is the name of a target configuration. If none
  is specified, the project default is used.

Platform list:
" + [ for (p in PLATFORMS) '  ${p.name}' ].join("\n"));
        
        case ["create"]: run(args.concat([Sys.getCwd()]));
        case ["create", dir]:
        dir = FileSystem.absolutePath(dir);
        switch (Project.check(dir)) {
          case NoConfig | Misconfig(_) | Error(_):
          PROJECT_FILES.map(function(p:String) {
              File.copy(Path.join([SELF, "template", p]), Path.join([dir, p]));
            });
          
          case NoPath: error("no such directory");
          case OK(_): error("project already exists");
        }
        
        case ["info"]: run(args.concat([Sys.getCwd()]));
        case ["info", dir]:
        switch (Project.check(dir)) {
          case OK(project): project.info();
          case s: projectError(s);
        }
        
        case ["build"]: run(args.concat([null]));
        case ["build", target]: run(args.concat([Sys.getCwd()]));
        case ["build", target, dir]:
        switch (Project.check(dir)) {
          case OK(project):
          Sys.setCwd(dir);
          project.select(target);
          project.build();
          FileSystem.createDirectory(Path.join([project.buildDir, target]));
          for (p in PLATFORMS) {
            p.build();
          }
          for (p in PLATFORMS) {
            p.glue();
          }
          case s: projectError(s);
        }
        
        case ["deploy"]: run(args.concat([null]));
        case ["deploy", target]: run(args.concat([Sys.getCwd()]));
        case ["deploy", target, dir]:
        switch (Project.check(dir)) {
          case OK(project):
          Sys.setCwd(dir);
          project.select(target);
          project.deploy();
          case s: projectError(s);
        }
        
        case ["test"]: run(args.concat([null]));
        case ["test", target]: run(args.concat([Sys.getCwd()]));
        case ["test", target, dir]:
        switch (Project.check(dir)) {
          case OK(project):
          Sys.setCwd(dir);
          project.select(target);
          project.test();
          case s: projectError(s);
        }
        
        case _: usage(1);
      }
    }
    run(args);
  }
}
