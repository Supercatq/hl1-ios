#!/usr/bin/env python3
"""Customize an Xash3D FWGS checkout for the Half-Life iOS build.

Run from the root of the engine checkout. It:
  1. ships touch/hl1_joystick.cfg inside extras.pk3 (touch_presets/),
  2. makes that layout the default whenever there is no saved touch.cfg
     (first launch, or "reset to defaults" in the touch settings),
  3. names the app "Half-Life" on the home screen.
"""
import pathlib
import shutil
import subprocess
import sys

ENGINE = pathlib.Path.cwd()
REPO = pathlib.Path(__file__).resolve().parent.parent


def die(msg):
    sys.exit("customize.py: " + msg)


# 1) joystick layout goes into extras.pk3, which the engine always mounts
presets = ENGINE / "3rdparty/extras/xash-extras/touch_presets"
if not presets.is_dir():
    die(f"{presets} not found; was the engine checked out with submodules?")
shutil.copyfile(REPO / "touch/hl1_joystick.cfg", presets / "hl1_joystick.cfg")

# 2) default touch layout -> joystick preset
src = ENGINE / "engine/client/input/in_touch.c"
text = src.read_text()
anchor = "static void Touch_LoadDefaults_f( void )\n{\n"
if text.count(anchor) != 1:
    die("Touch_LoadDefaults_f not found in in_touch.c; the engine changed, update this script")
inject = (
    "\t// hl1-ios: the joystick layout is the default touch layout\n"
    '\tif( FS_FileExists( "touch_presets/hl1_joystick.cfg", false ))\n'
    "\t{\n"
    '\t\tCbuf_AddText( "exec touch_presets/hl1_joystick.cfg\\n" );\n'
    "\t\ttouch.configchanged = true;\n"
    "\t\treturn;\n"
    "\t}\n\n"
)
src.write_text(text.replace(anchor, anchor + inject))

# 3) home-screen name
plist = ENGINE / "engine/platform/ios/bundle/Info.plist"
for key, value in (("CFBundleDisplayName", "Half-Life"), ("CFBundleName", "Half-Life")):
    subprocess.run(["plutil", "-replace", key, "-string", value, str(plist)], check=True)

print("customize.py: joystick layout installed as default, app named Half-Life")
