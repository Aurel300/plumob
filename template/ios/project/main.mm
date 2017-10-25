#include "HaxeAppDelegate.h"

int main(int argc, char** argv) {
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  int retVal = UIApplicationMain(
      argc, argv, nil, NSStringFromClass([HaxeAppDelegate class])
    );
  [pool release];
  return retVal;
}
