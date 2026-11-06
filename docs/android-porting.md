# Android device port investigation

This is a development workflow, not an Android installer or a declaration of supported devices. The initial investigation target is the Samsung Galaxy Tab S10 FE; its exact model variant and hardware must be measured before selecting a kernel or boot image. No device has been validated by this work yet.

## Collect a baseline

Install Android platform-tools on the development host, enable USB debugging on the tablet, connect it by USB, and approve the host on the tablet. Check `adb devices -l` locally. From this checkout run:

```sh
python3 scripts/android-device-report.py > android-device-report.json
# When several devices are connected:
python3 scripts/android-device-report.py --serial DEVICE_SELECTOR > android-device-report.json
```

The tool only queries selected properties and the kernel release. It does not invoke root, reboot, unlock, flash, or modify partitions. It omits device serials, account data, MAC addresses, and the complete property dump. Review the selected values before publishing: custom ROMs can set arbitrary property values. Missing properties become JSON null, and connection failures return a nonzero exit status without emitting a partial JSON report. A redirected file may be empty after failure; check the exit status before using it.

## Native port gates

Record evidence for each gate for the exact model variant; do not infer support from the ARM architecture or another Samsung device.

| Gate | Evidence required |
| --- | --- |
| Recovery and boot | Documented stock recovery path, bootloader policy, boot image format, partition layout, and a reproducible development boot procedure |
| Kernel | Maintained kernel source, device tree, firmware requirements and licensing, storage, USB, and input drivers |
| Graphics | Working DRM/KMS display and compatible accelerated Mesa/EGL stack, followed by an actual Hyprland session |
| Tablet input | Touch, keyboard, pointer, rotation, and S Pen behavior verified on hardware |
| Connectivity and audio | Wi-Fi, Bluetooth, audio routing, and cellular operation where applicable |
| Power | Charging, battery telemetry, thermal control, suspend/resume, and shutdown verified on hardware |
| Omarchy integration | Arch userspace and package availability, platform detection, lifecycle hooks, installation and update behavior, and recovery testing |

Keep unknown and failed checks visible. Add a runtime hardware family only when a working port needs distinct behavior, following AGENTS.md. Do not route Android boot partitions through a generic desktop bootloader installation path. Bootloader unlocking and flashing need a separate, model-specific procedure and explicit device-owner approval; this report is not authorization to perform them.

## Running a desktop inside Android

A Termux/PRoot environment shares Android's kernel and has service-management and kernel-interface limitations. Treat it as a separate experiment, not a native Omarchy port. Establish compositor, graphics, and service feasibility before attempting the Omarchy installer; package installation alone does not validate a working desktop.

## References

- [postmarketOS devices and images](https://postmarketos.org/download/): device-specific Linux enablement research; this does not establish support for the Tab S10 FE.
- [Termux PRoot-Distro limitations](https://github.com/termux/proot-distro#proot-distro-limitations): constraints for an Android-hosted experiment.
- [Omarchy lifecycle dispatch](lifecycle-dispatch.md): platform-specific boot and lifecycle integration.
