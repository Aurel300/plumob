class XCSource {
  public var uuid          :String;
  public var uuid_fileref  :String;
  public var uuid_filebuild:String;
  public var type          :XCSourceType;
  
  public function new(type:XCSourceType) {
    this.type = type;
  }
  
  public function encodeFileReference(buf:StringBuf):Void {
    if (type == Library) {
      return;
    }
    buf.add("    ");
    buf.add(uuid_fileref);
    buf.add(" = {isa = PBXFileReference; lastKnownFileType = ");
    switch (type) {
      case Framework(name):
      buf.add("wrapper.framework");
      buf.add("; name = " + name + ".framework");
      buf.add("; path = System/Library/Frameworks/" + name + ".framework");
      buf.add("; sourceTree = SDKROOT");
      
      case Archive(name, path):
      buf.add("archive.ar");
      buf.add("; name = \"" + name + "\"");
      buf.add("; path = \"" + path + "\"");
      buf.add("; sourceTree = SOURCE_ROOT");
      
      case ObjC(path) | ObjCpp(path) | ObjCHeader(path):
      buf.add(switch (type) {
          //case None: "file";
          case ObjC(_): "sourcecode.c.objc";
          case ObjCpp(_): "sourcecode.cpp.objcpp";
          case ObjCHeader(_): "sourcecode.c.h";
          case _: "";
        });
      buf.add("; fileEncoding = 4");
      buf.add("; path = \"" + path + "\"");
      buf.add("; sourceTree = SOURCE_ROOT");
      
      case _:
    }
    buf.add("; };\n");
  }
  
  public function encodeFileBuild(buf:StringBuf):Void {
    switch (type) {
      case ObjC(_) | ObjCpp(_) | Framework(_) | Archive(_, _):
      buf.add("    ");
      buf.add(uuid_filebuild);
      buf.add(" = {isa = PBXBuildFile; ");
      buf.add("fileRef = ");
      buf.add(uuid_fileref);
      buf.add("; };\n");
      
      case _:
    }
  }
  
  public function encodePhaseSources(buf:StringBuf, ?ref:Bool = false):Void {
    buf.add(switch (type) {
        case ObjC(_) | ObjCpp(_): "        " + (ref ? uuid_fileref : uuid_filebuild) + ",\n";
        case _: "";
      });
  }
  
  public function encodePhaseFrameworks(buf:StringBuf, ?ref:Bool = false):Void {
    buf.add(switch (type) {
        case Framework(_) | Archive(_, _):
        "        " + (ref ? uuid_fileref : uuid_filebuild) + ",\n";
        case _: "";
      });
  }
}
