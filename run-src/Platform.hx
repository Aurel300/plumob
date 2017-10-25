import haxe.io.Path;

class Platform {
  public var name:String;
  public var children:Array<Platform> = [];
  public var parent:Platform;
  public var enabled:Bool = false;
  public var productPath:String;
  public var project:Project;
  
  public var enabledChildren(get, never):Array<Platform>;
  private inline function get_enabledChildren():Array<Platform> {
    return [ for (c in children) if (c.enabled) c ];
  }
  
  public function new(?name:String) {
    this.name = name;
  }
  
  public function select(project:Project):Void {
    this.project = project;
    if (parent != null) {
      parent.select(project);
    }
  }
  
  public function targetPath():String {
    return Path.join([
         project.buildDir
        ,project.activeTarget.name
      ]);
  }
  
  public function productPaths():Array<String> {
    if (parent != null) {
      return parent.productPaths();
    }
    return [];
  }
  
  public function info(?tabs:String) {
    if (tabs == null) {
      tabs = "";
    }
    Sys.println('$tabs- $name (${enabled ? "ON" : "OFF"})');
    for (c in children) {
      c.info("  " + tabs);
    }
  }
  
  public function find(name:String):Platform {
    if (this.name != null && this.name == name) {
      return this;
    }
    for (c in children) {
      var cr = c.find(name);
      if (cr != null) {
        return cr;
      }
    }
    return null;
  }
  
  public function enable():Void {
    enabled = true;
    if (parent != null) {
      parent.enable();
    }
  }
  
  public function build():Void {
    if (!enabled) {
      return;
    }
    for (c in children) {
      c.build();
    }
  }
  
  public function glue():Void {}
}
