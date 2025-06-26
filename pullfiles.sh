#!/bin/bash

set -e

DEVICE_DIR="$(pwd)"
INFO_DIR="$DEVICE_DIR/infos"
PULLED_DIR="$DEVICE_DIR/pulled-images"

mkdir -p "$INFO_DIR" "$PULLED_DIR"

echo "[*] Checking ADB device..."
adb wait-for-device
adb root && sleep 1
adb remount

echo "[*] Pulling CPU info..."
adb shell cat /proc/cpuinfo > "$INFO_DIR/cpuinfo.txt"

echo "[*] Pulling hardware info..."
adb shell getprop > "$INFO_DIR/hardware_info.txt"

echo "[*] Pulling lshal output..."
adb shell lshal > "$INFO_DIR/lshal.txt" || echo "[!] 'lshal' not available on this device"

echo "[*] Pulling kernel config (if available)..."
adb shell zcat /proc/config.gz > "$INFO_DIR/kernel.config" || echo "[!] No /proc/config.gz found"

echo "[*] Pulling partition images..."
for PART in boot dtbo vendor logo; do
    echo "[*] Pulling $PART..."
    adb shell su -c "dd if=/dev/block/by-name/$PART of=/sdcard/$PART.img"
    adb pull /sdcard/$PART.img "$PULLED_DIR/$PART.img"
    adb shell rm /sdcard/$PART.img
done

echo "[*] Pulling DTB if separately available..."
adb shell su -c "find / -name '*.dtb' 2>/dev/null" | tee "$PULLED_DIR/dtb_paths.txt"

echo "[*] Pulling dmesg output..."
adb shell dmesg > "$DEVICE_DIR/dmesg.txt"

echo "[*] Done. All files are saved in:"
echo " - $INFO_DIR"
echo " - $PULLED_DIR"
