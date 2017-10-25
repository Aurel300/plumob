class XCProject {
  public static inline var HXCPP_PATH = "/usr/local/lib/haxe/lib/hxcpp/git";
  
  public var name:String;
  public var pack:String;
  public var sim:Bool = false;
  public var version:String = "8.0";
  public var arch:Array<String> = [];
  
  public var appFilename(get, never):String;
  private inline function get_appFilename():String {
    return name + ".app";
  }
  
  private var sources:Array<XCSource> = [];
  private var uuidCache:Map<String, String>;
  private var uuidCount:Int;
  
  public function new() {
    uuidCache = new Map();
    uuidCount = 0;
  }
  
  private function uuid(?name:String):String {
    if (name == null) {
      return "ABCDEFABCDEFABCD" + ('00000000${uuidCount++}').substr(-8);
    }
    if (!uuidCache.exists(name)) {
      uuidCache[name] = uuid();
    }
    return uuidCache[name];
  }
  
  public function addSource(type:XCSourceType):Void {
    var source = new XCSource(type);
    source.uuid = uuid();
    source.uuid_fileref = uuid();
    source.uuid_filebuild = uuid();
    sources.push(source);
  }
  
  private inline function getSources(type):Array<XCSource> {
    return sources.filter(function(s) return s.type == type);
  }
  
  public function encodePlist():String {
    return '<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>en</string>
	<key>CFBundleDisplayName</key>
	<string>${name}</string>
	<key>CFBundleExecutable</key>
	<string>$${EXECUTABLE_NAME}</string>
	<key>CFBundleIcons</key>
	<dict>
		<key>CFBundlePrimaryIcon</key>
		<dict>
			<key>CFBundleIconFiles</key>
			<array>
				<string>AppIcon29x29</string>
				<string>AppIcon40x40</string>
				<string>AppIcon60x60</string>
			</array>
		</dict>
	</dict>
	<key>CFBundleIdentifier</key>
	<string>${pack}</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$${PRODUCT_NAME}</string>
	<key>CFBundlePackageType</key>
	<string>APPL</string>
	<key>CFBundleShortVersionString</key>
	<string>1.1</string>
	<key>CFBundleSignature</key>
	<string>????</string>
	<key>CFBundleVersion</key>
	<string>4</string>
	<key>LSApplicationCategoryType</key>
	<string></string>
	<key>LSRequiresIPhoneOS</key>
	<true/>
	<key>UILaunchImages</key>
	<array>
		<dict>
			<key>UILaunchImageMinimumOSVersion</key>
			<string>7.0</string>
			<key>UILaunchImageName</key>
			<string>LaunchImage-700</string>
			<key>UILaunchImageOrientation</key>
			<string>Portrait</string>
			<key>UILaunchImageSize</key>
			<string>{320, 480}</string>
		</dict>
		<dict>
			<key>UILaunchImageMinimumOSVersion</key>
			<string>7.0</string>
			<key>UILaunchImageName</key>
			<string>LaunchImage-700-568h</string>
			<key>UILaunchImageOrientation</key>
			<string>Portrait</string>
			<key>UILaunchImageSize</key>
			<string>{320, 568}</string>
		</dict>
	</array>
	<key>UIRequiredDeviceCapabilities</key>
	<dict>' + [ for (a in arch) '<key>$a</key><true/>' ].join("") + '
	</dict>
	<key>UIStatusBarHidden</key>
	<true/>
	<key>UISupportedInterfaceOrientations</key>
	<array>
		<string>UIInterfaceOrientationPortrait</string>
	</array>
</dict>
</plist>';
  }
  
  public function encode():String {
    var buf = new StringBuf();
    
    inline function addLine(l:String):Void {
      buf.add(l);
      buf.add("\n");
    }
    inline function addLines(arr:Array<String>):Void {
      for (l in arr) {
        addLine(l);
      }
    }
    
    var libs = getSources(Library);
    
    addLines([
         "// !$*UTF8*$!"
        ,"{"
        ,"  archiveVersion = 1;"
        ,"  classes = {"
        ,"  };"
        ,"  objectVersion = 45;"
        ,"  objects = {"
      ]);
    for (s in sources) {
      s.encodeFileReference(buf);
      s.encodeFileBuild(buf);
    }
    addLines([
         "    " + uuid("root") + " = {"
        ,"      isa = PBXProject;"
        ,"      buildConfigurationList = " + uuid("buildConfigList") + ";"
        ,"      compatibilityVersion = \"Xcode 3.1\";"
        ,"      hasScannedForEncodings = 1;"
        ,"      mainGroup = " + uuid("mainGroup") + ";"
        ,"      projectDirPath = \"\";"
        ,"      projectRoot = \"\";"
        ,"      targets = ("
        ,"        " + uuid("target") + ","
        ,"      );"
        ,"    };"
        ,"    " + uuid("buildConfigList") + " = {"
        ,"      isa = XCConfigurationList;"
        ,"      buildConfigurations = ("
        ,"        " + uuid("buildConfig") + ","
        ,"      );"
        ,"      defaultConfigurationIsVisible = 0;"
        ,"      defaultConfigurationName = Release;"
        ,"    };"
        ,"    " + uuid("buildConfig") + " = {"
        ,"      isa = XCBuildConfiguration;"
        ,"      buildSettings = {"
        ,"        ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;"
        ,"        ASSETCATALOG_COMPILER_LAUNCHIMAGE_NAME = LaunchImage;"
        ,"        ALWAYS_SEARCH_USER_PATHS = NO;"
        ,"        CLANG_CXX_LANGUAGE_STANDARD = \"gnu++11\";"
        ,"        CLANG_CXX_LIBRARY = \"libc++\";"
        ,"        CLANG_ENABLE_MODULES = YES;"
        ,"        CLANG_ENABLE_OBJC_ARC = NO;"//YES;"
        ,"        CLANG_WARN_BOOL_CONVERSION = YES;"
        ,"        CLANG_WARN_CONSTANT_CONVERSION = YES;"
        ,"        CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;"
        ,"        CLANG_WARN_EMPTY_BODY = YES;"
        ,"        CLANG_WARN_ENUM_CONVERSION = YES;"
        ,"        CLANG_WARN_INFINITE_RECURSION = YES;"
        ,"        CLANG_WARN_INT_CONVERSION = YES;"
        ,"        CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;"
        ,"        CLANG_WARN_SUSPICIOUS_MOVE = YES;"
        ,"        CLANG_WARN_UNREACHABLE_CODE = YES;"
        ,"        CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;"
        ,"        COPY_PHASE_STRIP = YES;"
        ,"        ENABLE_NS_ASSERTIONS = NO;"
        ,"        ENABLE_STRICT_OBJC_MSGSEND = YES;"
        ,"        GCC_C_LANGUAGE_STANDARD = gnu99;"
        ,"        GCC_NO_COMMON_BLOCKS = YES;"
        ,"        GCC_WARN_64_TO_32_BIT_CONVERSION = YES;"
        ,"        GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;"
        ,"        GCC_WARN_UNDECLARED_SELECTOR = YES;"
        ,"        GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;"
        ,"        GCC_WARN_UNUSED_FUNCTION = YES;"
        ,"        GCC_WARN_UNUSED_VARIABLE = YES;"
        ,"        GCC_PRECOMPILE_PREFIX_HEADER = YES;"
        ,"        GCC_PREFIX_HEADER = \"Prefix.pch\";"
        ,'        IPHONEOS_DEPLOYMENT_TARGET = $version;'
        ,"        INFOPLIST_FILE = \"Info.plist\";"
        ,'        SDKROOT = ${sim ? "iphoneos" : "iphoneos"};'
        ,"        VALIDATE_PRODUCT = YES;"
        ,'        PRODUCT_BUNDLE_IDENTIFIER = "$pack";'
        ,'        PRODUCT_NAME = "$name";'
        ,"        WRAPPER_EXTENSION = app;"
        ,"        OTHER_CFLAGS = (" // <--
        ,"          \"-D_CRT_SECURE_NO_DEPRECATE\","
        ,"          \"-DHX_UNDEFINE_H\","
        ,"          \"-DENABLE_BITCODE=YES\","
        ,"          \"-fno-stack-protector\","
        ,"          \"-DIPHONE=IPHONE\","
        ,'          "-DIPHONEOS=${sim ? "IPHONESIM" : "IPHONEOS"}",'
        ,"          \"-DSTATIC_LINK\","
        ,"          \"-DHXCPP_VISIT_ALLOCS\","
        ,"          \"-DHXCPP_API_LEVEL=331\","
        ,"          \"-fexceptions\","
        ,"          \"-fstrict-aliasing\","
        ,"        );"
      ]);
    addLine("        HEADER_SEARCH_PATHS = (");
    addLine('          "../hx/include/",');
    addLine('          "../hx-out/",');
    addLine('          "${HXCPP_PATH}/include/"'); //<--
    addLine("        );");
    addLines([
         "      };"
        ,"      name = Release;"
        ,"    };"
        ,"    " + uuid("mainGroup") + " = {"
        ,"      isa = PBXGroup;"
        ,"      children = ("
        ,"        " + uuid("groupSources") + ","
        ,"        " + uuid("groupFrameworks") + ","
        ,"        " + uuid("groupProducts") + ","
        ,"      );"
        ,"      name = MainGroup;"
        ,"      sourceTree = \"<group>\";"
        ,"    };"
        ,"    " + uuid("groupSources") + " = {"
        ,"      isa = PBXGroup;"
        ,"      children = ("
      ]);
    for (s in sources) {
      s.encodePhaseSources(buf, true);
    }
    addLines([
         "      );"
        ,"      name = Sources;"
        ,"      sourceTree = \"<group>\";"
        ,"    };"
        ,"    " + uuid("groupFrameworks") + " = {"
        ,"      isa = PBXGroup;"
        ,"      children = ("
      ]);
    for (s in sources) {
      s.encodePhaseFrameworks(buf, true);
    }
    addLines([
         "      );"
        ,"      name = Frameworks;"
        ,"      sourceTree = \"<group>\";"
        ,"    };"
        ,"    " + uuid("groupProducts") + " = {"
        ,"      isa = PBXGroup;"
        ,"      children = ("
        ,"        " + uuid("product") + ","
        ,"      );"
        ,"      name = Products;"
        ,"      sourceTree = \"<group>\";"
        ,"    };"
        ,"    " + uuid("target") + " = {"
        ,"      isa = PBXNativeTarget;"
        ,"      buildConfigurationList = " + uuid("buildConfigList") + ";"
        ,"      buildPhases = ("
        ,"        " + uuid("phaseSources") + ","
        ,"        " + uuid("phaseFrameworks") + ","
        ,"      );"
        ,"      buildRules = ("
        ,"      );"
        ,"      dependencies = ("
        ,"      );"
        ,'      name = "$name";'
        ,'      productName = "$name";'
        ,'      productReference = ${uuid("product")};'
        ,"      productType = \"com.apple.product-type.application\";"
        ,"    };"
        ,"    " + uuid("product") + " = {"
        ,"      isa = PBXFileReference;"
        ,"      explicitFileType = wrapper.application;"
        ,"      includeInIndex = 0;"
        ,'      path = "$appFilename";'
        ,"      sourceTree = BUILT_PRODUCTS_DIR;"
        ,"    };"
        ,"    " + uuid("phaseSources") + " = {"
        ,"      isa = PBXSourcesBuildPhase;"
        ,"      buildActionMask = 2147483647;"
        ,"      files = ("
      ]);
    for (s in sources) {
      s.encodePhaseSources(buf);
    }
    addLines([
         "      );"
        ,"    };"
        ,"    " + uuid("phaseFrameworks") + " = {"
        ,"      isa = PBXFrameworksBuildPhase;"
        ,"      buildActionMask = 2147483647;"
        ,"      files = ("
      ]);
    for (s in sources) {
      s.encodePhaseFrameworks(buf);
    }
    addLines([
         "      );"
        ,"      runOnlyForDeploymentPostprocessing = 0;"
        ,"    };"
        ,"  };"
        ,"  rootObject = " + uuid("root") + ";"
        ,"}"
      ]);
    return buf.toString();
  }
}
