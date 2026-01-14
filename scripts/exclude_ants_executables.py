#!/usr/bin/env python3
"""
Script to exclude specific ANTs executables from the build by modifying CMakeLists.txt files.
"""
import os
import re
import sys

# List of executables to exclude
EXCLUDED_EXECUTABLES = [
    'ANTSUseLandmarkImagesToGetAffineTransform',
    'ANTSUseLandmarkImagesToGetBSplineDisplacementField',
    'ClusterImageStatistics',
    'ConvertInputImagePixelTypeToFloat',
    'ConvertScalarImageToRGB',
    'ConvertToJpg',
    'CreateDTICohort',
    'DeNrrd',
    'ExtractSliceFromImage',
    'FitBSplineToPoints',
    'KellyKapowski',
    'KellySlater',
    'NonLocalSuperResolution',
    'SuperResolution',
    'SurfaceBasedSmoothing',
    'TimeSCCAN',
    'WarpImageMultiTransform',
    'WarpTensorImageMultiTransform',
    'WarpTimeSeriesImageMultiTransform',
    'antsLandmarkBasedTransformInitializer',
    'antsMotionCorr',
    'antsMotionCorrDiffusionDirection',
    'antsMotionCorrStats',
    'antsNeuroimagingBattery',
    'antsSliceRegularizedRegistration',
    'antsUtilitiesTesting',
    'sccan',
    'simpleSynRegistration',
]

# List of scripts to exclude
EXCLUDED_SCRIPTS = [
    'antsASLProcessing.sh',
    'antsBOLDNetworkAnalysis.R',
    'antsCorticalThickness.sh',
    'antsIntermodalityIntrasubject.sh',
    'antsLongitudinalCorticalThickness.sh',
    'antsNetworkAnalysis.R',
]

EXCLUDED_ITEMS = EXCLUDED_EXECUTABLES + EXCLUDED_SCRIPTS


def process_cmake_content(content):
    """Process CMakeLists.txt content to exclude unwanted executables and scripts."""
    lines = content.split('\n')
    result_lines = []
    i = 0

    while i < len(lines):
        line = lines[i]
        should_exclude = False

        # Check if this line contains an add_executable or related macro for an excluded executable
        for exe in EXCLUDED_EXECUTABLES:
            add_patterns = [
                r'add_executable\s*\(\s*' + re.escape(exe) + r'\b',
                r'add_ants_executable\s*\(\s*' + re.escape(exe) + r'\b',
                r'DYNAMIC_ANTS_BUILD\s*\(\s*' + re.escape(exe) + r'\b',
                r'STATIC_ANTS_BUILD\s*\(\s*' + re.escape(exe) + r'\b',
                r'add_custom_target\s*\(\s*' + re.escape(exe) + r'\b',
            ]
            if any(re.search(pattern, line) for pattern in add_patterns):
                should_exclude = True
                # Comment out the add_executable line
                result_lines.append('#' + line)
                i += 1

                # Count parentheses to handle nested cases
                open_parens = line.count('(') - line.count(')')

                # Continue commenting until we find the matching closing parenthesis
                while i < len(lines) and open_parens > 0:
                    next_line = lines[i]
                    result_lines.append('#' + next_line)
                    open_parens += next_line.count('(') - next_line.count(')')
                    i += 1
                break

        if should_exclude:
            continue

        # Check for install commands for excluded executables or scripts
        for item in EXCLUDED_ITEMS:
            if re.search(r'install\s*\(.*' + re.escape(item) + r'\b', line):
                result_lines.append('#' + line)
                should_exclude = True
                break

        if should_exclude:
            continue

        # Skip or comment list entries that enumerate excluded items (e.g., set(...) blocks)
        for item in EXCLUDED_ITEMS:
            if re.search(r'\b' + re.escape(item) + r'\b', line):
                stripped = line.strip()
                # Drop lines that are solely the excluded item (with optional closing paren)
                if re.match(r'^(\$\{CMAKE_CURRENT_SOURCE_DIR\}/)?' + re.escape(item) + r'\)?\s*#?.*$', stripped):
                    should_exclude = True
                    break
                # Otherwise, comment the line to be safe
                result_lines.append('#' + line)
                should_exclude = True
                break

        if not should_exclude:
            result_lines.append(line)

        i += 1

    return '\n'.join(result_lines)


def process_cmake_file(filepath):
    """Process a single CMakeLists.txt file."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()

        original_content = content
        modified_content = process_cmake_content(content)

        # Only write if content changed
        if modified_content != original_content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(modified_content)
            return True
        return False
    except Exception as e:
        print(f"Error processing {filepath}: {e}", file=sys.stderr)
        return False


def main():
    if len(sys.argv) < 2:
        print("Usage: exclude_ants_executables.py <ants_source_directory>", file=sys.stderr)
        sys.exit(1)

    ants_source_dir = sys.argv[1]

    if not os.path.isdir(ants_source_dir):
        print(f"Error: {ants_source_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    # Find all CMakeLists.txt files
    cmake_files = []
    for root, dirs, files in os.walk(ants_source_dir):
        if 'CMakeLists.txt' in files:
            cmake_files.append(os.path.join(root, 'CMakeLists.txt'))

    modified_count = 0
    for cmake_file in cmake_files:
        if process_cmake_file(cmake_file):
            modified_count += 1

    print(f"Processed {len(cmake_files)} CMakeLists.txt files, modified {modified_count}")


if __name__ == '__main__':
    main()
