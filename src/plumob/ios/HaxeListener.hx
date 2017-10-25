package plumob.ios;

import cpp.objc.*;

@:objc
@:native("HaxeListener")
@:include("../../project/HaxeListener.h")
extern class HaxeListener {
  @:native("make:listener")
  public static function make(listener:Int):HaxeListener;
}
