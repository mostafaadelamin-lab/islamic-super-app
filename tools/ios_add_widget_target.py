"""Adds the PrayerWidget WidgetKit extension target to ios/Runner.xcodeproj (no Mac needed).

Run once: python3 tools/ios_add_widget_target.py   (it refuses to run twice).
What it adds: the PrayerWidgetExtension target (bundle id org.rattil.app.PrayerWidget, iOS 14+,
App Group group.org.rattil.app), built from ios/PrayerWidget/PrayerWidget.swift, and the
"Embed Foundation Extensions" phase in Runner (placed before "Thin Binary", which avoids the
Xcode "Cycle inside Runner" error). Signing comes from Codemagic (xcode-project use-profiles)."""
import pathlib, re

root = pathlib.Path(__file__).resolve().parent.parent / 'apps/mobile/ios'
p = root / 'Runner.xcodeproj/project.pbxproj'
s = p.read_text()
assert 'PrayerWidgetExtension' not in s, 'already added'

I = {k: f'C3E6D0000000000000000{n:03d}' for n, k in enumerate([
    'swiftRef', 'plistRef', 'entRef', 'appexRef', 'wkRef', 'suiRef',
    'swiftBuild', 'wkBuild', 'suiBuild', 'appexBuild',
    'group', 'fwGroup', 'target', 'sources', 'frameworks', 'resources', 'embed',
    'proxy', 'dep', 'cfgList', 'debug', 'release', 'profile', 'xcRef'])}

def add(section, text):
    global s
    end = f'/* End {section} section */'
    if end in s:
        s = s.replace(end, text + end, 1)
    else:  # a section the project does not have yet: put it before the next one in Xcode's order
        nxt = '/* Begin PBXFileReference section */' if section == 'PBXCopyFilesBuildPhase' else None
        s = s.replace(nxt, f'/* Begin {section} section */\n{text}/* End {section} section */\n\n{nxt}', 1)

add('PBXBuildFile', f'''\t\t{I['swiftBuild']} /* PrayerWidget.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {I['swiftRef']} /* PrayerWidget.swift */; }};
\t\t{I['wkBuild']} /* WidgetKit.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {I['wkRef']} /* WidgetKit.framework */; }};
\t\t{I['suiBuild']} /* SwiftUI.framework in Frameworks */ = {{isa = PBXBuildFile; fileRef = {I['suiRef']} /* SwiftUI.framework */; }};
\t\t{I['appexBuild']} /* PrayerWidgetExtension.appex in Embed Foundation Extensions */ = {{isa = PBXBuildFile; fileRef = {I['appexRef']} /* PrayerWidgetExtension.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};
''')
add('PBXContainerItemProxy', f'''\t\t{I['proxy']} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = 97C146E61CF9000F007C117D /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {I['target']};
\t\t\tremoteInfo = PrayerWidgetExtension;
\t\t}};
''')
add('PBXCopyFilesBuildPhase', f'''\t\t{I['embed']} /* Embed Foundation Extensions */ = {{
\t\t\tisa = PBXCopyFilesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tdstPath = "";
\t\t\tdstSubfolderSpec = 13;
\t\t\tfiles = (
\t\t\t\t{I['appexBuild']} /* PrayerWidgetExtension.appex in Embed Foundation Extensions */,
\t\t\t);
\t\t\tname = "Embed Foundation Extensions";
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
''')
add('PBXFileReference', f'''\t\t{I['swiftRef']} /* PrayerWidget.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PrayerWidget.swift; sourceTree = "<group>"; }};
\t\t{I['plistRef']} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
\t\t{I['xcRef']} /* PrayerWidget.xcconfig */ = {{isa = PBXFileReference; lastKnownFileType = text.xcconfig; path = PrayerWidget.xcconfig; sourceTree = "<group>"; }};
\t\t{I['entRef']} /* PrayerWidget.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = PrayerWidget.entitlements; sourceTree = "<group>"; }};
\t\t{I['appexRef']} /* PrayerWidgetExtension.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = PrayerWidgetExtension.appex; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{I['wkRef']} /* WidgetKit.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = WidgetKit.framework; path = System/Library/Frameworks/WidgetKit.framework; sourceTree = SDKROOT; }};
\t\t{I['suiRef']} /* SwiftUI.framework */ = {{isa = PBXFileReference; lastKnownFileType = wrapper.framework; name = SwiftUI.framework; path = System/Library/Frameworks/SwiftUI.framework; sourceTree = SDKROOT; }};
''')
add('PBXFrameworksBuildPhase', f'''\t\t{I['frameworks']} /* Frameworks */ = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{I['suiBuild']} /* SwiftUI.framework in Frameworks */,
\t\t\t\t{I['wkBuild']} /* WidgetKit.framework in Frameworks */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
''')
add('PBXGroup', f'''\t\t{I['group']} /* PrayerWidget */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{I['swiftRef']} /* PrayerWidget.swift */,
\t\t\t\t{I['plistRef']} /* Info.plist */,
\t\t\t\t{I['entRef']} /* PrayerWidget.entitlements */,
\t\t\t\t{I['xcRef']} /* PrayerWidget.xcconfig */,
\t\t\t);
\t\t\tpath = PrayerWidget;
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{I['fwGroup']} /* Frameworks */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{I['wkRef']} /* WidgetKit.framework */,
\t\t\t\t{I['suiRef']} /* SwiftUI.framework */,
\t\t\t);
\t\t\tname = Frameworks;
\t\t\tsourceTree = "<group>";
\t\t}};
''')
# main group + products
s = s.replace('''\t\t\t\t331C8082294A63A400263BE5 /* RunnerTests */,
\t\t\t);
\t\t\tsourceTree = "<group>";''', f'''\t\t\t\t331C8082294A63A400263BE5 /* RunnerTests */,
\t\t\t\t{I['group']} /* PrayerWidget */,
\t\t\t\t{I['fwGroup']} /* Frameworks */,
\t\t\t);
\t\t\tsourceTree = "<group>";''', 1)
s = s.replace('''\t\t\t\t331C8081294A63A400263BE5 /* RunnerTests.xctest */,
\t\t\t);
\t\t\tname = Products;''', f'''\t\t\t\t331C8081294A63A400263BE5 /* RunnerTests.xctest */,
\t\t\t\t{I['appexRef']} /* PrayerWidgetExtension.appex */,
\t\t\t);
\t\t\tname = Products;''', 1)
add('PBXNativeTarget', f'''\t\t{I['target']} /* PrayerWidgetExtension */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {I['cfgList']} /* Build configuration list for PBXNativeTarget "PrayerWidgetExtension" */;
\t\t\tbuildPhases = (
\t\t\t\t{I['sources']} /* Sources */,
\t\t\t\t{I['frameworks']} /* Frameworks */,
\t\t\t\t{I['resources']} /* Resources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = PrayerWidgetExtension;
\t\t\tproductName = PrayerWidgetExtension;
\t\t\tproductReference = {I['appexRef']} /* PrayerWidgetExtension.appex */;
\t\t\tproductType = "com.apple.product-type.app-extension";
\t\t}};
''')
# Runner: embed phase before Thin Binary, dependency on the widget
s = s.replace('''\t\t\t\t9705A1C41CF9048500538489 /* Embed Frameworks */,
\t\t\t\t3B06AD1E1E4923F5004D2608 /* Thin Binary */,''', f'''\t\t\t\t9705A1C41CF9048500538489 /* Embed Frameworks */,
\t\t\t\t{I['embed']} /* Embed Foundation Extensions */,
\t\t\t\t3B06AD1E1E4923F5004D2608 /* Thin Binary */,''', 1)
runner = s.index('97C146ED1CF9000F007C117D /* Runner */ = {\n\t\t\tisa = PBXNativeTarget;')
dep_at = s.index('\t\t\tdependencies = (\n', runner) + len('\t\t\tdependencies = (\n')
s = s[:dep_at] + f'\t\t\t\t{I["dep"]} /* PBXTargetDependency */,\n' + s[dep_at:]
s = s.replace('''\t\t\t\t331C8080294A63A400263BE5 /* RunnerTests */,
\t\t\t);
\t\t};
/* End PBXProject section */''', f'''\t\t\t\t331C8080294A63A400263BE5 /* RunnerTests */,
\t\t\t\t{I['target']} /* PrayerWidgetExtension */,
\t\t\t);
\t\t}};
/* End PBXProject section */''', 1)
s = s.replace('''\t\t\t\t\t97C146ED1CF9000F007C117D = {''', f'''\t\t\t\t\t{I['target']} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t\t97C146ED1CF9000F007C117D = {{''', 1)
add('PBXResourcesBuildPhase', f'''\t\t{I['resources']} /* Resources */ = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
''')
add('PBXSourcesBuildPhase', f'''\t\t{I['sources']} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{I['swiftBuild']} /* PrayerWidget.swift in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
''')
add('PBXTargetDependency', f'''\t\t{I['dep']} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {I['target']} /* PrayerWidgetExtension */;
\t\t\ttargetProxy = {I['proxy']} /* PBXContainerItemProxy */;
\t\t}};
''')

def cfg(key, name, debug):
    return f'''\t\t{I[key]} /* {name} */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = AccentColor;
\t\t\t\tCLANG_ENABLE_OBJC_WEAK = YES;
\t\t\t\tCODE_SIGN_ENTITLEMENTS = PrayerWidget/PrayerWidget.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Manual;
\t\t\t\tCURRENT_PROJECT_VERSION = "$(FLUTTER_BUILD_NUMBER)";
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = PrayerWidget/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 14.0;
\t\t\t\tLD_RUNPATH_SEARCH_PATHS = (
\t\t\t\t\t"$(inherited)",
\t\t\t\t\t"@executable_path/Frameworks",
\t\t\t\t\t"@executable_path/../../Frameworks",
\t\t\t\t);
\t\t\t\tMARKETING_VERSION = "$(FLUTTER_BUILD_NAME)";
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = org.rattil.app.PrayerWidget;
\t\t\t\tPRODUCT_NAME = "$(TARGET_NAME)";
\t\t\t\tSKIP_INSTALL = YES;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_OPTIMIZATION_LEVEL = {'"-Onone"' if debug else '"-O"'};
\t\t\t\tSWIFT_VERSION = 5.0;
\t\t\t\tTARGETED_DEVICE_FAMILY = "1,2";
\t\t\t}};
\t\t\tname = {name};
\t\t}};
'''
# The extension takes FLUTTER_BUILD_NAME / NUMBER (its version must equal the app's) from
# PrayerWidget.xcconfig, which includes only Flutter/Generated.xcconfig (not the Pods settings).
add('XCBuildConfiguration', cfg('debug', 'Debug', True) + cfg('release', 'Release', False) + cfg('profile', 'Profile', False))
for k, n in (('debug', 'Debug'), ('release', 'Release'), ('profile', 'Profile')):
    s = s.replace(f'\t\t{I[k]} /* {n} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n',
                  f'\t\t{I[k]} /* {n} */ = {{\n\t\t\tisa = XCBuildConfiguration;\n\t\t\tbaseConfigurationReference = {I["xcRef"]} /* PrayerWidget.xcconfig */;\n', 1)
add('XCConfigurationList', f'''\t\t{I['cfgList']} /* Build configuration list for PBXNativeTarget "PrayerWidgetExtension" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{I['debug']} /* Debug */,
\t\t\t\t{I['release']} /* Release */,
\t\t\t\t{I['profile']} /* Profile */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
''')
assert s.count('{') == s.count('}'), 'unbalanced braces'
p.write_text(s)

(root / 'PrayerWidget/Info.plist').write_text('''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key>
	<string>$(DEVELOPMENT_LANGUAGE)</string>
	<key>CFBundleDisplayName</key>
	<string>رتّل وصلِّ</string>
	<key>CFBundleExecutable</key>
	<string>$(EXECUTABLE_NAME)</string>
	<key>CFBundleIdentifier</key>
	<string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
	<key>CFBundleInfoDictionaryVersion</key>
	<string>6.0</string>
	<key>CFBundleName</key>
	<string>$(PRODUCT_NAME)</string>
	<key>CFBundlePackageType</key>
	<string>$(PRODUCT_BUNDLE_PACKAGE_TYPE)</string>
	<key>CFBundleShortVersionString</key>
	<string>$(MARKETING_VERSION)</string>
	<key>CFBundleVersion</key>
	<string>$(CURRENT_PROJECT_VERSION)</string>
	<key>NSExtension</key>
	<dict>
		<key>NSExtensionPointIdentifier</key>
		<string>com.apple.widgetkit-extension</string>
	</dict>
</dict>
</plist>
''')
ent = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<!-- Shared with the app (lib/data/home_widget_sync.dart writes "rattil.widget" there). -->
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.org.rattil.app</string>
	</array>
</dict>
</plist>
'''
(root / 'PrayerWidget/PrayerWidget.entitlements').write_text(ent)
(root / 'PrayerWidget/PrayerWidget.xcconfig').write_text('// FLUTTER_BUILD_NAME / FLUTTER_BUILD_NUMBER: the widget carries the app\'s version.\n#include "../Flutter/Generated.xcconfig"\n')
r = root / 'Runner/Runner.entitlements'
rs = r.read_text()
if 'application-groups' not in rs:
    rs = rs.replace('</dict>\n</plist>', '''	<!-- The prayer widget reads the prayer times the app writes here. -->
	<key>com.apple.security.application-groups</key>
	<array>
		<string>group.org.rattil.app</string>
	</array>
</dict>
</plist>''')
    r.write_text(rs)
print('PrayerWidgetExtension added')
