#!/usr/bin/env python3
"""One-off script: insert CulinaShare extension target into project.pbxproj."""
from pathlib import Path

PBX = Path(__file__).resolve().parent.parent / "CulinaChef.xcodeproj" / "project.pbxproj"
text = PBX.read_text(encoding="utf-8")

if "CulinaShare.appex" in text:
    print("CulinaShare target already present, skipping")
    raise SystemExit(0)

# IDs (24 hex, unique)
R = {
    "swift": "F00000000000000000000001",
    "appex": "F00000000000000000000002",
    "plist": "F00000000000000000000003",
    "ent": "F00000000000000000000004",
    "grp": "F00000000000000000000005",
    "bf_src": "F00000000000000000000006",
    "bf_emb": "F00000000000000000000007",
    "src_ph": "F00000000000000000000008",
    "target": "F00000000000000000000009",
    "proxy": "F0000000000000000000000A",
    "dep": "F0000000000000000000000B",
    "cfg_dbg": "F0000000000000000000000C",
    "cfg_rel": "F0000000000000000000000D",
    "cfg_list": "F0000000000000000000000E",
}

insert_build_file = f"""\t\t{R["bf_src"]} /* ShareViewController.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {R["swift"]} /* ShareViewController.swift */; }};
\t\t{R["bf_emb"]} /* CulinaShare.appex in Embed Foundation Extensions */ = {{isa = PBXBuildFile; fileRef = {R["appex"]} /* CulinaShare.appex */; settings = {{ATTRIBUTES = (RemoveHeadersOnCopy, ); }}; }};
"""

insert_file_ref = f"""\t\t{R["swift"]} /* ShareViewController.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ShareViewController.swift; sourceTree = "<group>"; }};
\t\t{R["appex"]} /* CulinaShare.appex */ = {{isa = PBXFileReference; explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = CulinaShare.appex; sourceTree = BUILT_PRODUCTS_DIR; }};
\t\t{R["plist"]} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
\t\t{R["ent"]} /* CulinaShare.entitlements */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.entitlements; path = CulinaShare.entitlements; sourceTree = "<group>"; }};
"""

insert_group = f"""\t\t{R["grp"]} /* CulinaShare */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
\t\t\t\t{R["swift"]} /* ShareViewController.swift */,
\t\t\t\t{R["plist"]} /* Info.plist */,
\t\t\t);
\t\t\tpath = CulinaShare;
\t\t\tsourceTree = "<group>";
\t\t}};
"""

insert_native = f"""\t\t{R["target"]} /* CulinaShare */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {R["cfg_list"]} /* Build configuration list for PBXNativeTarget "CulinaShare" */;
\t\t\tbuildPhases = (
\t\t\t\t{R["src_ph"]} /* Sources */,
\t\t\t);
\t\t\tbuildRules = (
\t\t\t);
\t\t\tdependencies = (
\t\t\t);
\t\t\tname = CulinaShare;
\t\t\tpackageProductDependencies = (
\t\t\t);
\t\t\tproductName = CulinaShare;
\t\t\tproductReference = {R["appex"]} /* CulinaShare.appex */;
\t\t\tproductType = "com.apple.product-type.app-extension";
\t\t}};
"""

insert_sources_phase = f"""\t\t{R["src_ph"]} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{R["bf_src"]} /* ShareViewController.swift in Sources */,
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
"""

insert_proxy = f"""\t\t{R["proxy"]} /* PBXContainerItemProxy */ = {{
\t\t\tisa = PBXContainerItemProxy;
\t\t\tcontainerPortal = 4DF7A8FB47235C9D8D37D68C /* Project object */;
\t\t\tproxyType = 1;
\t\t\tremoteGlobalIDString = {R["target"]};
\t\t\tremoteInfo = CulinaShare;
\t\t}};
"""

insert_dep = f"""\t\t{R["dep"]} /* PBXTargetDependency */ = {{
\t\t\tisa = PBXTargetDependency;
\t\t\ttarget = {R["target"]} /* CulinaShare */;
\t\t\ttargetProxy = {R["proxy"]} /* PBXContainerItemProxy */;
\t\t}};
"""

insert_cfg_dbg = f"""\t\t{R["cfg_dbg"]} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_ENTITLEMENTS = Configs/CulinaShare.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = 4Q33QP9G7Z;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = CulinaShare/Info.plist;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = CulinaChef;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.moritzserrin.culinachef.share;
\t\t\t\tPRODUCT_NAME = CulinaShare;
\t\t\t\tSKIP_INSTALL = NO;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.9;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
"""

insert_cfg_rel = f"""\t\t{R["cfg_rel"]} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tCODE_SIGN_ENTITLEMENTS = Configs/CulinaShare.entitlements;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tDEVELOPMENT_TEAM = 4Q33QP9G7Z;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = CulinaShare/Info.plist;
\t\t\t\tINFOPLIST_KEY_CFBundleDisplayName = CulinaChef;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 17.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.moritzserrin.culinachef.share;
\t\t\t\tPRODUCT_NAME = CulinaShare;
\t\t\t\tSKIP_INSTALL = NO;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.9;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
"""

insert_cfg_list = f"""\t\t{R["cfg_list"]} /* Build configuration list for PBXNativeTarget "CulinaShare" */ = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = (
\t\t\t\t{R["cfg_dbg"]} /* Debug */,
\t\t\t\t{R["cfg_rel"]} /* Release */,
\t\t\t);
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Debug;
\t\t}};
"""

# 1) PBXBuildFile section
text = text.replace(
    "/* End PBXBuildFile section */",
    insert_build_file + "/* End PBXBuildFile section */",
    1,
)

# 2) PBXFileReference - before End PBXFileReference
text = text.replace(
    "/* End PBXFileReference section */",
    insert_file_ref + "/* End PBXFileReference section */",
    1,
)

# 3) Main group children - add CulinaShare group
text = text.replace(
    "\t\t\t\tDB8C1F848D9255B8F1A42A68 /* Products */,\n",
    f"\t\t\t\t{R['grp']} /* CulinaShare */,\n\t\t\t\tDB8C1F848D9255B8F1A42A68 /* Products */,\n",
    1,
)

# 4) Insert PBXGroup CulinaShare before End PBXGroup
text = text.replace(
    "/* End PBXGroup section */",
    insert_group + "/* End PBXGroup section */",
    1,
)

# 5) Configs group - add entitlements
text = text.replace(
    "\t\t\t\t4F800ACD7DA8C23D84AF197D /* Secrets.xcconfig */,\n",
    f"\t\t\t\t4F800ACD7DA8C23D84AF197D /* Secrets.xcconfig */,\n\t\t\t\t{R['ent']} /* CulinaShare.entitlements */,\n",
    1,
)

# 6) Products - add appex
text = text.replace(
    "\t\t\t\t92133B524A6E41594887E31B /* CulinaChefTimerWidget.appex */,\n",
    f"\t\t\t\t{R['appex']} /* CulinaShare.appex */,\n\t\t\t\t92133B524A6E41594887E31B /* CulinaChefTimerWidget.appex */,\n",
    1,
)

# 7) PBXNativeTarget section - before End
text = text.replace(
    "/* End PBXNativeTarget section */",
    insert_native + "/* End PBXNativeTarget section */",
    1,
)

# 8) PBXSourcesBuildPhase - before End
text = text.replace(
    "/* End PBXSourcesBuildPhase section */",
    insert_sources_phase + "/* End PBXSourcesBuildPhase section */",
    1,
)

# 9) Embed Foundation Extensions - add build file
text = text.replace(
    "\t\t\tfiles = (\n\t\t\t\tB49FC98E18188BF38E08E720 /* CulinaChefTimerWidget.appex in Embed Foundation Extensions */,\n\t\t\t\t);",
    "\t\t\tfiles = (\n\t\t\t\tB49FC98E18188BF38E08E720 /* CulinaChefTimerWidget.appex in Embed Foundation Extensions */,\n\t\t\t\t"
    + R["bf_emb"]
    + " /* CulinaShare.appex in Embed Foundation Extensions */,\n\t\t\t);",
    1,
)

# 10) CulinaChef target dependencies
text = text.replace(
    "\t\t\tdependencies = (\n\t\t\t\tBF5CFEA92EDB946F000A4330 /* PBXTargetDependency */,\n\t\t\t\t0BB5974317FF8A3FC9E60BA0 /* PBXTargetDependency */,\n\t\t\t);",
    "\t\t\tdependencies = (\n\t\t\t\tBF5CFEA92EDB946F000A4330 /* PBXTargetDependency */,\n\t\t\t\t0BB5974317FF8A3FC9E60BA0 /* PBXTargetDependency */,\n\t\t\t\t"
    + R["dep"]
    + " /* PBXTargetDependency */,\n\t\t\t);",
    1,
)

# 11) PBXContainerItemProxy section
text = text.replace(
    "/* End PBXContainerItemProxy section */",
    insert_proxy + "/* End PBXContainerItemProxy section */",
    1,
)

# 12) PBXTargetDependency section
text = text.replace(
    "/* End PBXTargetDependency section */",
    insert_dep + "/* End PBXTargetDependency section */",
    1,
)

# 13) XCBuildConfiguration section - before End
text = text.replace(
    "/* End XCBuildConfiguration section */",
    insert_cfg_dbg + insert_cfg_rel + "/* End XCBuildConfiguration section */",
    1,
)

# 14) XCConfigurationList - before End
text = text.replace(
    "/* End XCConfigurationList section */",
    insert_cfg_list + "/* End XCConfigurationList section */",
    1,
)

# 15) Project targets
text = text.replace(
    "\t\t\ttargets = (\n\t\t\t\tFFADC5FD5D5C094834C6F95E /* CulinaChef */,\n\t\t\t\t04E5CB28410783D7A485F9BF /* CulinaChefTests */,\n\t\t\t\tCC1691148AD5DAFF0660DAA0 /* CulinaChefTimerWidget */,\n\t\t\t);",
    "\t\t\ttargets = (\n\t\t\t\tFFADC5FD5D5C094834C6F95E /* CulinaChef */,\n\t\t\t\t04E5CB28410783D7A485F9BF /* CulinaChefTests */,\n\t\t\t\tCC1691148AD5DAFF0660DAA0 /* CulinaChefTimerWidget */,\n\t\t\t\t"
    + R["target"]
    + " /* CulinaShare */,\n\t\t\t);",
    1,
)

# 16) TargetAttributes for new target
text = text.replace(
    "\t\t\t\tFFADC5FD5D5C094834C6F95E = {\n\t\t\t\t\tDevelopmentTeam = 4Q33QP9G7Z;\n\t\t\t\t\tProvisioningStyle = Automatic;\n\t\t\t\t};",
    "\t\t\t\tFFADC5FD5D5C094834C6F95E = {\n\t\t\t\t\tDevelopmentTeam = 4Q33QP9G7Z;\n\t\t\t\t\tProvisioningStyle = Automatic;\n\t\t\t\t};\n\t\t\t\t"
    + R["target"]
    + " = {\n\t\t\t\t\tDevelopmentTeam = 4Q33QP9G7Z;\n\t\t\t\t\tProvisioningStyle = Automatic;\n\t\t\t\t};",
    1,
)

PBX.write_text(text, encoding="utf-8")
print("Patched", PBX)
