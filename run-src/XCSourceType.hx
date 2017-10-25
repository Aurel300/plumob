enum XCSourceType {
  ObjC(path:String);
  ObjCpp(path:String);
  ObjCHeader(path:String);
  Framework(name:String);
  Archive(name:String, path:String);
  Library;
}
