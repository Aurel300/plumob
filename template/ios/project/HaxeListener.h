#import <UIKit/UIKit.h>

@interface HaxeListener: NSObject {
  int listener;
}

+ (HaxeListener*)make:(int)_listener;

- (void)handle:(id)sender;

@end
