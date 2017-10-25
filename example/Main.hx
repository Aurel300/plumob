import com.apple.*;

using plumob.ios.Events;

@:objc
@:keep
class Main {
  @:unreflective
  public static function main():Void {
    // Make sure our traces can show up in the simulator console
    haxe.Log.trace = function(v:Dynamic, ?infos:haxe.PosInfos):Void {
      cpp.objc.NSLog.log('HAXE TRACE: $v');
    };
    try {
      trace("Creating a window ...");
      var frame = UIScreen.mainScreen().bounds();
      trace('${frame.origin.x} ${frame.origin.y} ${frame.size.width} ${frame.size.height}');
      var window:UIWindow
        = cast UIWindow.alloc().initWithFrame(frame);
      
      trace("Creating a view ...");
      var view = UIView.alloc();
      view.initWithFrame(frame);
      view.setBackgroundColor(UIColor.whiteColor());
      
      trace("Creating a label ...");
      var label:UILabel = cast UILabel.alloc().initWithFrame(
          UIKit.CGRectMake(10.0, 20.0, frame.size.width - 20.0, 30.0)
        );
      label.setText("Hello world!");
      
      trace("Creating a button ...");
      var button:UIButton = cast UIButton.buttonWithType(UIButtonTypeSystem);
      button.setFrame(
          UIKit.CGRectMake(10.0, 60.0, frame.size.width - 20.0, 30.0)
        );
      button.setTitle_forState("Tap me!", UIControlStateNormal);
      
      trace("Setting button action ...");
      var taps = 0;
      button.listen(UIControlEvents.UIControlEventTouchUpInside, function() {
          taps++;
          label.setText('Button has been tapped $taps times!');
        });
      
      trace("Adding components to view ...");
      view.addSubview(label);
      view.addSubview(button);
      
      trace("Adding view to window ...");
      window.addSubview(view);
      
      trace("Showing window ...");
      window.makeKeyAndVisible();
    } catch (ex:Dynamic) {
      trace('EXCEPTION: $ex');
    }
  }
}
