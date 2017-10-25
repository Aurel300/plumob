package plumob.ios;

import com.apple.*;

class Events {
  private static var listeners:Map<Int, EventListener> = new Map();
  private static var listenerId:Int = 0;
  
  public static function listen(
    control:UIControl, event:UIControlEvents, handler:Void->Void
  ):EventListener {
    var ret = new EventListener(control, event, handler);
    ret.native = HaxeListener.make(listenerId);
    control.addTarget_action_forControlEvents(
        ret.native, untyped __cpp__("@selector(handle:)"), event
      );
    listeners[listenerId++] = ret;
    return ret;
  }
  
  @:keep
  private static function handleNative(id:Int):Void {
    listeners[id].handler();
  }
}

class EventListener {
  public var control:UIControl;
  public var event:UIControlEvents;
  public var handler:Void->Void;
  public var native:HaxeListener;
  
  public function new(
    control:UIControl, event:UIControlEvents, handler:Void->Void
  ) {
    this.control = control;
    this.event = event;
    this.handler = handler;
  }
}
