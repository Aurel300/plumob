package plat;

import haxe.io.Path;
import sys.FileSystem;

class IOS extends Platform {
  public var version:String;
  
  public function new(version:String) {
    super("ios-" + version);
    this.version = version;
  }
  
  override public function build():Void {
    if (!enabled) {
      return;
    }
    for (d in [
         "ios/hx"
        ,"ios/hx-out"
        ,"ios/project/project.xcodeproj"
      ]) {
      FileSystem.createDirectory(Path.join([targetPath(), d]));
    }
    for (f in [
         "main.mm"
        ,"HaxeAppDelegate.mm"
        ,"HaxeAppDelegate.h"
        ,"HaxeListener.mm"
        ,"HaxeListener.h"
        ,"Prefix.pch"
      ]) {
      var dest = Path.join([targetPath(), "ios/project", f]);
      if (!FileSystem.exists(dest)) {
        Main.copyOrDie(Path.join([Main.SELF, "template/ios/project", f]), dest);
      }
    }
    Main.runOrDie("haxe", [
      for (l in project.activeTarget.haxelibs) for (f in ["-lib", l]) f
    ].concat([
       "Main"
      ,"-D", "objc"
      ,"-D", "PLUMOB_IOS"
      ,"-D", "DEVELOPER_DIR=" + (cast parent:IOSGroup).xcodeDir()
      ,"-D", "ios"
      ,"-D", "HXCPP_CPP11"
      ,"-cpp", Path.join([targetPath(), "ios/hx"])
    ]).concat(version == "sim" ? [
       "-D", "iphonesim"
      ,"-D", "HXCPP_M64" // TODO: 32-bit?
    ] : [
       "-D", "iphone"
      ,"-D", "HXCPP_" + version.toUpperCase()
    ]).concat(project.activeTarget.buildFlagsHaxe));
  }
}
