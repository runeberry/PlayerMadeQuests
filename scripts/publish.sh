#!/bin/bash

ADDON_NAME="PlayerMadeQuests"
ADDON_DIR="src"
VERSION_FILE="PmqCore.lua"

# Specify a version in integer format, such as '11305' for 1.13.05
VERSION=$1
if [[ -z "$VERSION" ]]; then
  echo "VERSION is required"
  exit 1
fi

SEMVER=$(cut -d "-" -f 1 <<<"$VERSION")
BRANCH=$(cut -d "-" -f 2 <<<"$VERSION")
MAJOR=$(cut -d "." -f 1 <<<"$SEMVER")
MINOR=$(cut -d "." -f 2 <<<"$SEMVER")
PATCH=$(cut -d "." -f 3 <<<"$SEMVER")

VERSION_STRING="$MAJOR.$MINOR.$PATCH-$BRANCH" # Should match user input
VERSION_NUMBER="$(($MAJOR*10000 + $MINOR*100 + $PATCH))"

echo "Setting addon version to $VERSION_STRING ($VERSION_NUMBER)..."

sed -ri "s/^(addon.VERSION = ).+$/\1$VERSION_NUMBER/" "$ADDON_DIR/$VERSION_FILE"
sed -ri "s/^(addon.BRANCH = ).+$/\1\"$BRANCH\"/" "$ADDON_DIR/$VERSION_FILE"
sed -ri "s/^(## Version: ).+$/\1$VERSION_STRING/" "$ADDON_DIR/$ADDON_NAME.toc"

echo "Setting build timestamp..."

TIMESTAMP=$(date +%s)
sed -ri "s/^(addon.TIMESTAMP = ).+$/\1$TIMESTAMP/" "$ADDON_DIR/$VERSION_FILE"

echo "Compressing files..."

# Compressed folder must contain a folder called $ADDON_NAME with all the contents in it
# Copy addon contents to this folder, compress, then delete the temp folder
rm -rf $ADDON_NAME
cp -r $ADDON_DIR $ADDON_NAME
OUTFILE="${ADDON_NAME}_v${VERSION_STRING}.zip"

# Clean up old copy in case it already exists
rm -f $OUTFILE

# You must have 7zip in your PATH for this to work
7z -bso0 -bsp0 a $OUTFILE $ADDON_NAME
rm -rf $ADDON_NAME

echo "Addon published to: $OUTFILE"

git commit . -m "v$VERSION_STRING"

echo "Version bump committed to git."