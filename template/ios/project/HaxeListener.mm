#import "HaxeListener.h"
#import "plumob/ios/Events.h"

@implementation HaxeListener

+ (HaxeListener*)make:(int)_listener {
  HaxeListener* ret = [HaxeListener alloc];
  ret->listener = _listener;
  return ret;
}

- (void)handle:(id)sender {
  ::plumob::ios::Events_obj::handleNative(self->listener);
}

@end
