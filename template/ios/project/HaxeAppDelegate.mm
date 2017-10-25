#import <hxcpp.h>
#import "Main.h"
#import "HaxeAppDelegate.h"

@implementation HaxeAppDelegate

- (BOOL)application:(UIApplication *)application 
willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  HX_TOP_OF_STACK hx::Boot();
  __boot_all();
  return YES;
}

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  ::Main_obj::main();
  return YES;
}

- (void)dealloc {
  [super dealloc];
}

@end
