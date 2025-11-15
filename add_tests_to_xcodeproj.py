#!/usr/bin/env python3
"""
Script to add new test files to CulinaChef.xcodeproj
"""

import uuid
import re

# Generate unique UUIDs for new files
def generate_uuid():
    return uuid.uuid4().hex[:24].upper()

# New test files to add
new_test_files = {
    'AppStateTests.swift': 'Tests',
    'BackendClientTests.swift': 'Tests',
    'OpenAIClientTests.swift': 'Tests',
    'SupabaseAuthClientTests.swift': 'Tests',
}

new_mock_files = {
    'MockURLProtocol.swift': 'Tests/Mocks',
    'MockSupabaseResponses.swift': 'Tests/Mocks',
}

# Read project file
pbxproj_path = '/Users/moritzserrin/CulinaChef/ios/CulinaChef.xcodeproj/project.pbxproj'
with open(pbxproj_path, 'r') as f:
    content = f.read()

# Find the test target UUID
test_target_match = re.search(r'3F0982C606E537CF58C2E853 /\* CulinaChefTests\.xctest \*/', content)
if not test_target_match:
    print("ERROR: Could not find test target")
    exit(1)

print("✅ Found test target: 3F0982C606E537CF58C2E853")

# Generate UUIDs for new files
file_refs = {}
build_files = {}

for filename in list(new_test_files.keys()) + list(new_mock_files.keys()):
    file_refs[filename] = generate_uuid()
    build_files[filename] = generate_uuid()
    print(f"Generated UUIDs for {filename}")

# 1. Add PBXFileReference entries
file_ref_section = "/* Begin PBXFileReference section */"
file_ref_additions = []

for filename, path in {**new_test_files, **new_mock_files}.items():
    file_ref_uuid = file_refs[filename]
    file_ref_additions.append(
        f"\t\t{file_ref_uuid} /* {filename} */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = {filename}; sourceTree = \"<group>\"; }};"
    )

# Find insertion point after existing test file references
insertion_point = content.find('174E397B5850F0459C63D384 /* KeychainManagerTests.swift */')
if insertion_point == -1:
    print("ERROR: Could not find insertion point")
    exit(1)

# Find end of that line
line_end = content.find('\n', insertion_point)
insertion_point = line_end + 1

# Insert new file references
new_content = content[:insertion_point]
for ref in file_ref_additions:
    new_content += ref + "\n"
new_content += content[insertion_point:]

content = new_content

# 2. Add PBXBuildFile entries
build_file_section_end = content.find('/* End PBXBuildFile section */')
build_file_additions = []

for filename in list(new_test_files.keys()) + list(new_mock_files.keys()):
    build_file_uuid = build_files[filename]
    file_ref_uuid = file_refs[filename]
    build_file_additions.append(
        f"\t\t{build_file_uuid} /* {filename} in Sources */ = {{isa = PBXBuildFile; fileRef = {file_ref_uuid} /* {filename} */; }};"
    )

insertion_point = build_file_section_end
new_content = content[:insertion_point]
for build_file in build_file_additions:
    new_content += build_file + "\n"
new_content += content[insertion_point:]

content = new_content

# 3. Add to Tests group
# Find the Tests group (0B4517B2259DC6F3B5AA8263)
tests_group_match = re.search(
    r'(0B4517B2259DC6F3B5AA8263 /\* Tests \*/ = \{[^}]+children = \()([^)]+)(\);)',
    content,
    re.DOTALL
)

if not tests_group_match:
    print("ERROR: Could not find Tests group")
    exit(1)

tests_group_children = tests_group_match.group(2)
new_children = tests_group_children

for filename in new_test_files.keys():
    file_ref_uuid = file_refs[filename]
    new_children += f"\n\t\t\t\t{file_ref_uuid} /* {filename} */,"

# Add Mocks subgroup if not exists
mocks_group_uuid = generate_uuid()
new_children += f"\n\t\t\t\t{mocks_group_uuid} /* Mocks */,"

content = content.replace(tests_group_match.group(2), new_children)

# 4. Create Mocks subgroup
mocks_group = f"""
\t\t{mocks_group_uuid} /* Mocks */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
"""

for filename in new_mock_files.keys():
    file_ref_uuid = file_refs[filename]
    mocks_group += f"\t\t\t\t{file_ref_uuid} /* {filename} */,\n"

mocks_group += """\t\t\t);
\t\t\tpath = Mocks;
\t\t\tsourceTree = "<group>";
\t\t};
"""

# Insert mocks group after Tests group
tests_group_end = content.find('\t};', tests_group_match.end())
insertion_point = content.find('\n', tests_group_end) + 1

content = content[:insertion_point] + mocks_group + content[insertion_point:]

# 5. Add to PBXSourcesBuildPhase for test target
# Find the test target's sources build phase (9FDBEB8F7DEF8F733E6E2D30)
sources_phase_pattern = r'(9FDBEB8F7DEF8F733E6E2D30 /\* Sources \*/ = \{[^}]+files = \()([^)]+)(\);)'
sources_match = re.search(sources_phase_pattern, content, re.DOTALL)

if not sources_match:
    print("ERROR: Could not find sources build phase")
    exit(1)

sources_files = sources_match.group(2)
new_sources_files = sources_files

for filename in list(new_test_files.keys()) + list(new_mock_files.keys()):
    build_file_uuid = build_files[filename]
    new_sources_files += f"\n\t\t\t\t{build_file_uuid} /* {filename} in Sources */,"

content = content.replace(sources_match.group(2), new_sources_files)

# Write modified project file
with open(pbxproj_path, 'w') as f:
    f.write(content)

print("\n✅ Successfully added all test files to Xcode project!")
print(f"\n📝 Added {len(new_test_files)} test files:")
for filename in new_test_files.keys():
    print(f"   - {filename}")

print(f"\n📝 Added {len(new_mock_files)} mock files:")
for filename in new_mock_files.keys():
    print(f"   - {filename}")

print("\n🎯 You can now build and run tests with:")
print("   xcodebuild test -project CulinaChef.xcodeproj -scheme CulinaChef -destination 'platform=iOS Simulator,name=iPhone 17'")
