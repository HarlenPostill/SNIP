from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
p = ROOT / 'sol-word-test.xcodeproj/project.pbxproj'
s = p.read_text()
if 'BBBBBBBBBBBBBBBBBBBBBB10' not in s:
    objects = '''
        BBBBBBBBBBBBBBBBBBBBBB01 = {isa = PBXFileReference; explicitFileType = wrapper.cfbundle; includeInIndex = 0; path = SNIPUITests.xctest; sourceTree = BUILT_PRODUCTS_DIR; };
        BBBBBBBBBBBBBBBBBBBBBB02 = {isa = PBXFileSystemSynchronizedRootGroup; path = SNIPUITests; sourceTree = "<group>"; };
        BBBBBBBBBBBBBBBBBBBBBB03 = {isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        BBBBBBBBBBBBBBBBBBBBBB04 = {isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        BBBBBBBBBBBBBBBBBBBBBB05 = {isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = (); runOnlyForDeploymentPostprocessing = 0; };
        BBBBBBBBBBBBBBBBBBBBBB06 = {isa = PBXContainerItemProxy; containerPortal = 000000000000000000000000; proxyType = 1; remoteGlobalIDString = 000000000000000100000000; remoteInfo = "sol-word-test"; };
        BBBBBBBBBBBBBBBBBBBBBB07 = {isa = PBXTargetDependency; target = 000000000000000100000000; targetProxy = BBBBBBBBBBBBBBBBBBBBBB06; };
        BBBBBBBBBBBBBBBBBBBBBB08 = {isa = XCBuildConfiguration; name = Debug; buildSettings = {CODE_SIGN_STYLE = Automatic; GENERATE_INFOPLIST_FILE = YES; IPHONEOS_DEPLOYMENT_TARGET = 18.0; PRODUCT_BUNDLE_IDENTIFIER = "com.hrln-interactive.snip.uitests"; PRODUCT_NAME = "$(TARGET_NAME)"; SDKROOT = iphoneos; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = 1; TEST_TARGET_NAME = "sol-word-test"; }; };
        BBBBBBBBBBBBBBBBBBBBBB09 = {isa = XCBuildConfiguration; name = Release; buildSettings = {CODE_SIGN_STYLE = Automatic; GENERATE_INFOPLIST_FILE = YES; IPHONEOS_DEPLOYMENT_TARGET = 18.0; PRODUCT_BUNDLE_IDENTIFIER = "com.hrln-interactive.snip.uitests"; PRODUCT_NAME = "$(TARGET_NAME)"; SDKROOT = iphoneos; SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"; SWIFT_VERSION = 5.0; TARGETED_DEVICE_FAMILY = 1; TEST_TARGET_NAME = "sol-word-test"; }; };
        BBBBBBBBBBBBBBBBBBBBBB11 = {isa = XCConfigurationList; buildConfigurations = (BBBBBBBBBBBBBBBBBBBBBB08, BBBBBBBBBBBBBBBBBBBBBB09); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; };
        BBBBBBBBBBBBBBBBBBBBBB10 = {isa = PBXNativeTarget; buildConfigurationList = BBBBBBBBBBBBBBBBBBBBBB11; buildPhases = (BBBBBBBBBBBBBBBBBBBBBB03, BBBBBBBBBBBBBBBBBBBBBB04, BBBBBBBBBBBBBBBBBBBBBB05); buildRules = (); dependencies = (BBBBBBBBBBBBBBBBBBBBBB07); fileSystemSynchronizedGroups = (BBBBBBBBBBBBBBBBBBBBBB02); name = SNIPUITests; productName = SNIPUITests; productReference = BBBBBBBBBBBBBBBBBBBBBB01; productType = "com.apple.product-type.bundle.ui-testing"; };
'''
    s = s.replace('objects = {', 'objects = {' + objects, 1)
    s = s.replace('000000000000000000000010 /* sol-word-test */,', '000000000000000000000010 /* sol-word-test */,\n                BBBBBBBBBBBBBBBBBBBBBB02,', 1)
    s = s.replace('000000000000000000000120 /* sol-word-test.app */,', '000000000000000000000120 /* sol-word-test.app */,\n                BBBBBBBBBBBBBBBBBBBBBB01,', 1)
    s = s.replace('000000000000000100000000 /* sol-word-test */,', '000000000000000100000000 /* sol-word-test */,\n                BBBBBBBBBBBBBBBBBBBBBB10,', 1)
    p.write_text(s)
scheme = ROOT / 'sol-word-test.xcodeproj/xcshareddata/xcschemes/SNIP.xcscheme'
scheme.parent.mkdir(parents=True, exist_ok=True)
ref = '<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="000000000000000100000000" BuildableName="sol-word-test.app" BlueprintName="sol-word-test" ReferencedContainer="container:sol-word-test.xcodeproj"/>'
testref = '<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="BBBBBBBBBBBBBBBBBBBBBB10" BuildableName="SNIPUITests.xctest" BlueprintName="SNIPUITests" ReferencedContainer="container:sol-word-test.xcodeproj"/>'
scheme.write_text(f'''<?xml version="1.0" encoding="UTF-8"?>
<Scheme LastUpgradeVersion="2700" version="1.3">
<BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">{ref}</BuildActionEntry></BuildActionEntries></BuildAction>
<TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables><TestableReference skipped="NO">{testref}</TestableReference></Testables></TestAction>
<LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES" debugServiceExtension="internal" allowLocationSimulation="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></LaunchAction>
<ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">{ref}</BuildableProductRunnable></ProfileAction>
<AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/>
</Scheme>''')
print('Shared SNIP scheme and UI test target installed')
