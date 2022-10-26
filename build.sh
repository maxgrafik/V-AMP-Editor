#!/bin/sh

# Exit this script immediately if any of the commands fails
set -e


APP_NAME="V-AMP Editor"


#############################################################
# Prepare Folders
#############################################################

# This will be the final app bundle
APP_BUNDLE="${APP_NAME}".app

# The root directory of the project sources
SOURCE_DIR=Sources

# The build directory
BUILD_DIR=.build/release

# Delete app bundle from previous build
rm -rf ${BUILD_DIR}/"${APP_BUNDLE}"

# Create bundle structure
mkdir -p ${BUILD_DIR}/"${APP_BUNDLE}"
mkdir ${BUILD_DIR}/"${APP_BUNDLE}"/Contents
mkdir ${BUILD_DIR}/"${APP_BUNDLE}"/Contents/MacOS


#############################################################
# Compile Swift Files
#############################################################

# Compile all Swift files in the source directory
swiftc ${SOURCE_DIR}/"${APP_NAME}"/*.swift -o ${BUILD_DIR}/"${APP_BUNDLE}"/Contents/MacOS/"${APP_NAME}"


#############################################################
# Copy Info.plist
#############################################################

cp ${SOURCE_DIR}/Info.plist ${BUILD_DIR}/"${APP_BUNDLE}"/Contents/Info.plist


#############################################################
# Create AppIcon.icns
#############################################################

# Convert .iconset to .icns file
iconutil -c icns Assets/AppIcon.iconset

# Move AppIcon.icns to Resources folder
mv Assets/AppIcon.icns ${SOURCE_DIR}/"${APP_NAME}"/Resources/AppIcon.icns


#############################################################
# Copy Resources folder to app bundle
#############################################################

cp -a ${SOURCE_DIR}/"${APP_NAME}"/Resources ${BUILD_DIR}/"${APP_BUNDLE}"/Contents


#############################################################
# Create PkgInfo file
#############################################################

echo "APPL????\c" > ${BUILD_DIR}/"${APP_BUNDLE}"/Contents/PkgInfo


#############################################################
# Move app bundle to Desktop
#############################################################

mv ${BUILD_DIR}/"${APP_BUNDLE}" ~/Desktop
