package plat;

import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;

class IOSGroup extends Platform {
  public var sim:Bool;
  
  public function new(sub:Array<Platform>, ?sim:Bool = false) {
    super();
    this.children = sub;
    for (s in sub) {
      s.parent = this;
    }
    this.sim = sim;
  }
  
  public function xcodeDir():String {
    return (
        project.env.exists("xcode_developer_dir")
        ? project.env.get("xcode_developer_dir")
        : "/Applications/Xcode.app/Contents/Developer"
      );
  }
  
  override public function productPaths():Array<String> {
    return [
      Path.join([
           targetPath()
          ,"ios/project/build/Release-" + (sim ? "iphonesimulator" : "iphoneos")
          ,project.slug + ".app"
        ])
    ];
  }
  
  override public function glue():Void {
    if (!enabled) {
      return;
    }
    var proj = new XCProject();
    proj.sim = sim;
    proj.name = project.slug;
    proj.pack = project.pack;
    [
       "Foundation"
      ,"UIKit"
      ,"CoreAudio"
      ,"CoreGraphics"
    /*
       "Foundation"
      ,"UIKit"
      ,"OpenGLES"
      ,"QuartzCore"
      ,"CoreMotion"
      ,"GameController"
      ,"CoreAudio"
      ,"AudioToolbox"
      ,"AVFoundation"
      ,"CoreGraphics"
      ,"ImageIO"
      ,"MobileCoreServices"
    */
    ].map(function(f) proj.addSource(Framework(f)));
    proj.addSource(ObjCpp("main.mm"));
    proj.addSource(ObjCpp("HaxeAppDelegate.mm"));
    proj.addSource(ObjCHeader("HaxeAppDelegate.h"));
    proj.addSource(ObjCpp("HaxeListener.mm"));
    proj.addSource(ObjCHeader("HaxeListener.h"));
    /*
    proj.addSource(ObjCpp("HaxeView.mm"));
    proj.addSource(ObjCpp("HaxeView.h"));
    proj.addSource(ObjCpp("HaxeViewController.mm"));
    proj.addSource(ObjCpp("HaxeViewController.h"));
    */
    if (sim) {
      Main.copyOrDie(
           Path.join([targetPath(), "ios/hx/liboutput.iphonesim-64.a"])
          ,Path.join([targetPath(), "ios/hx-out/hx.fat-iphonesim.a"])
        );
      proj.addSource(Archive("libMain.iphonesim.a", "../hx-out/hx.fat-iphonesim.a"));
    } else {
      proj.arch.push("armv7"); // TODO: probably shouldn't be here?
      Main.runOrDie("lipo", [
          "-create"
        ].concat(Main.glob(~/^liboutput\.iphoneos([^\.]*)\.a$/, "ios/hx"))
        .concat([
          "-output", "../hx-out/hx.fat-iphoneos.a"
        ]), "ios/hx");
      proj.addSource(Archive("libMain.iphoneos.a", "../hx-out/hx.fat-iphoneos.a"));
    }
    File.saveContent(
         Path.join([targetPath(), "ios/project/Info.plist"])
        ,proj.encodePlist()
      );
    File.saveContent(
         Path.join([targetPath(), "ios/project/project.xcodeproj/project.pbxproj"])
        ,proj.encode()
      );
    var dev = xcodeDir();
    var sdk = (
        project.env.exists("xcode_sdk_ios")
        ? project.env.get("xcode_sdk_ios")
        : Path.join([
             dev
            ,"/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS10.2.sdk"
          ])
      );
    var sdkSim = (
        project.env.exists("xcode_sdk_ios_sim")
        ? project.env.get("xcode_sdk_ios_sim")
        : Path.join([
             dev
            ,"/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator10.2.sdk"
          ])
      );
    Main.runOrDie(Path.join([
        dev, "/usr/bin/xcodebuild"
      ]), [
         "CODE_SIGNING_REQUIRED=NO"
        ,"-verbose"
        ,"-sdk", sim ? sdkSim : sdk
      ].concat(sim ? [
         'ARCHS="x86_64"' // TODO: 32-bit?
        ,"ONLY_ACTIVE_ARCH=NO"
      ] : []), Path.join([
        targetPath(), "ios/project"
      ]));
    if (project.env.exists("ldid_path")) {
      for (p in productPaths()) {
        Main.runOrDie(project.env.get("ldid_path"), [
            "-S", Path.join([p, project.slug])
          ]);
      }
    }
  }
}
