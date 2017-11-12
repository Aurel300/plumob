package plumob;

import haxe.macro.Context;
import haxe.macro.Expr;

class ObjCWrap {
  /*
  public static function extend():Array<Field> {
    var pos = Context.currentPos();
    var cls = Context.getLocalClass().get();
    var fields = Context.getBuildFields();
    return null;
  }
  */
  /*
  public static macro function anonymousClass(fields:Expr):Expr {
    var pos = Context.currentPos();
    var protocol = Context.getExpectedType();
    if (protocol == null) {
      throw "unknown type for anonymousClass";
    }
    trace(protocol);
    throw "ok";
    return macro [];
  }
  */
  
  public static function wrap(specRaw:Expr):Array<Field> {
    var pos = Context.currentPos();
    var cls = Context.getLocalClass().get();
    switch (specRaw) {
      case {expr: EObjectDecl([
           {field: "hppImports", expr: {expr: EArrayDecl(hppImportsRaw), pos: _}}
          ,{field: "cppImports", expr: {expr: EArrayDecl(cppImportsRaw), pos: _}}
          ,{field: "ext", expr: {expr: EConst(CString(ext)), pos: _}}
          ,{field: "protocols", expr: {expr: EArrayDecl(protocolsRaw), pos: _}}
          ,{field: "fields", expr: {expr: EArrayDecl(fieldsRaw), pos: _}}
          ,{field: "methods", expr: {expr: EArrayDecl(methodsRaw), pos: _}}
        ]), pos: _}:
      var name = cls.name + "Native";
      function parseArr(e:Array<Expr>):Array<String> {
        return [ for (er in e) switch (er) {
            case {expr: EConst(CString(str)), pos: _}: str;
            case _: throw "invalid @:wrap sytnax";
          } ];
      }
      var hppImports = parseArr(hppImportsRaw);
      var cppImports = parseArr(cppImportsRaw);
      var protocols = parseArr(protocolsRaw);
      var fields = [ for (fieldRaw in fieldsRaw) switch (fieldRaw) {
          case {expr: EObjectDecl([
               {field: "name", expr: {expr: EConst(CString(name)), pos: _}}
              ,{field: "type", expr: {expr: EConst(CString(type)), pos: _}}
              ,{field: "nativeType", expr: {expr: EConst(CString(nativeType)), pos: _}}
            ]), pos: _}:
          var typePack = type.split(".");
          var typeName = typePack.pop();
          {name: name, type: TPath({
               name: typeName
              ,pack: typePack
            }), nativeType: nativeType};
          case _: throw "invalid @:wrap sytnax";
        } ];
      var methods = [ for (methodRaw in methodsRaw) switch (methodRaw) {
          case {expr: EObjectDecl([
               {field: "args", expr: {expr: EArrayDecl(argsRaw), pos: _}}
              ,{field: "code", expr: {expr: EConst(CString(code)), pos: _}}
              ,{field: "ret", expr: {expr: EConst(CString(ret)), pos: _}}
            ]), pos: _}:
          {name: "", code: code, args: [ for (argRaw in argsRaw) switch (argRaw) {
              case {expr: EObjectDecl([
                   {field: "desc", expr: {expr: EConst(CString(desc)), pos: _}}
                  ,{field: "name", expr: {expr: EConst(CString(name)), pos: _}}
                  ,{field: "type", expr: {expr: EConst(CString(type)), pos: _}}
                ]), pos: _}:
              {desc: desc, name: name, type: type};
              case _: throw "invalid @:wrap sytnax";
            } ], ret: ret};
          case {expr: EObjectDecl([
               {field: "name", expr: {expr: EConst(CString(name)), pos: _}}
              ,{field: "code", expr: {expr: EConst(CString(code)), pos: _}}
              ,{field: "ret", expr: {expr: EConst(CString(ret)), pos: _}}
            ]), pos: _}:
          {name: name, code: code, args: [], ret: ret};
          case _: throw "invalid @:wrap sytnax";
        } ];
      var cppCode = [ for (imp in cppImports) '#import $imp\n' ].join("")
        + '@implementation $name
+ (${name}*)make'
        + [ for (field in fields) ':(${field.nativeType})_${field.name}' ].join("")
        + ' {
  ${name}* ret = [${name} alloc];
' + [ for (field in fields) '  ret->${field.name} = _${field.name};' ].join("\n") + '
  return ret;
}
' + [ for (m in methods) '- (${m.ret})${m.name}' + [ for (a in m.args) '${a.desc}:(${a.type})${a.name}' ].join(" ") + ' {
  ${m.code}
}' ].join("\n") + '
@end
';
      var hppCode = [ for (imp in hppImports) '#import $imp\n' ].join("")
        + '@interface $name: $ext '
        + (protocols.length > 0 ? "<" + [ for (p in protocols) p ].join(", ") + "> " : "") + '{
' + [ for (field in fields) '  ${field.nativeType} ${field.name};' ].join("\n") + '
}
+ (${name}*)make'
        + [ for (field in fields) ':(${field.nativeType})_${field.name}' ].join("")
        + ';
' + [ for (m in methods) '- (${m.ret})${m.name}' + [ for (a in m.args) '${a.desc}:(${a.type})${a.name}' ].join(" ") + ';' ].join("\n") + '
@end
';
      cls.meta.add(":cppFileCode", [{expr: EConst(CString(cppCode)), pos: pos}], pos);
      cls.meta.add(":headerCode", [{expr: EConst(CString(hppCode)), pos: pos}], pos);
      var nativeType:ComplexType = TPath({name: name, pack: cls.pack});
      Context.defineType({
          fields: [{
               access: [APublic, AStatic]
              ,kind: FFun({
                   args: [ for (field in fields) {name: field.name, type: field.type} ]
                  ,expr: null
                  ,ret: nativeType
                })
              ,name: "make"
              ,pos: pos
            }]
          ,isExtern: true
          ,kind: TDClass(null, [], false)
          ,meta: [
               {name: ":objc", pos: pos}
              ,{name: ":native", params: [{expr: EConst(CString(name)), pos: pos}], pos: pos}
            ]
          ,name: name
          ,pack: cls.pack
          ,pos: pos
        });
      case _:
      throw "invalid @:wrap syntax";
    }
    //var fields = Context.getBuildFields();
    //throw "ok";
    return null;
  }
}
