#!/usr/bin/env python3
"""Collect selected Android properties for port investigation; never flash a device."""

import argparse
import json
import subprocess
import sys


PROPERTIES = {
  "manufacturer": "ro.product.manufacturer",
  "model": "ro.product.model",
  "device": "ro.product.device",
  "board": "ro.product.board",
  "soc": "ro.soc.model",
  "abis": "ro.product.cpu.abilist",
  "android_release": "ro.build.version.release",
  "security_patch": "ro.build.version.security_patch",
  "verified_boot_state": "ro.boot.verifiedbootstate",
  "flash_locked": "ro.boot.flash.locked",
  "slot_suffix": "ro.boot.slot_suffix",
}


def collect(serial=None, run=subprocess.run):
  prefix = ["adb"]
  if serial:
    prefix += ["-s", serial]
  # Let adb reject missing, unauthorized, or ambiguous devices. Never choose one
  # automatically when several are attached.
  def query(*args):
    result = run(prefix + list(args), capture_output=True, text=True,
                 check=True, timeout=15)
    value = result.stdout.strip()
    return value or None

  properties = {name: query("shell", "getprop", key)
                for name, key in PROPERTIES.items()}
  return {
    "schema_version": 1,
    "properties": properties,
    "kernel_release": query("shell", "uname", "-r"),
    "native_omarchy_support": "unverified",
    "note": "Property detection is not proof of bootloader unlockability or Linux support.",
  }


def main():
  parser = argparse.ArgumentParser(description=__doc__)
  parser.add_argument("--serial", help="ADB device selector (not included in the report)")
  args = parser.parse_args()
  try:
    report = collect(args.serial)
  except (OSError, subprocess.SubprocessError):
    # ADB diagnostics can contain transport identifiers; keep public output
    # limited and leave detailed troubleshooting to `adb devices -l` locally.
    print("Cannot read device. Check adb devices -l, authorize USB debugging, "
          "and use --serial when multiple devices are connected.", file=sys.stderr)
    return 1
  print(json.dumps(report, indent=2))
  return 0


if __name__ == "__main__":
  sys.exit(main())
