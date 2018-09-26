#!/bin/bash

git=$(sh /etc/profile; which git)
number_of_commits=$("$git" rev-list --first-parent --count HEAD)
git_release_version=$("$git" describe --tags --always)

target_plist="$TARGET_BUILD_DIR/$INFOPLIST_PATH"
dsym_plist="$DWARF_DSYM_FOLDER_PATH/$DWARF_DSYM_FILE_NAME/Contents/Info.plist"



private_revision_key="CFBundleVersion"

if [ "$1" != "" ]; then
	private_revision_key=$1
# hack to not try to write a custom key to a plist that doesn't have it
	dsym_plist=target_plist
fi 

for plist in "$target_plist" "$dsym_plist"; do
  if [ -f "$plist" ]; then
	echo "/usr/libexec/PlistBuddy -c \"Set :$private_revision_key $number_of_commits\"" "$plist"
    /usr/libexec/PlistBuddy -c "Set :$private_revision_key $number_of_commits" "$plist"
  fi
done