#!/system/bin/sh
#
# Enables USB ADB on an Android device and authorizes the ADB key of
# ACER-X-02. Run from a terminal with:
#   sh /sdcard/Download/enable_usb_debugging.sh
#
# Root (su) or equivalent system privileges are required.

ADB_PUBLIC_KEY='QAAAAGUprlWTH98bCqImijl3K0isd0kb94cXnwXJEj0u3ZtZLeYRVpbTazuXAFFSc0hPAMDxN7uratB8kVgppffZ7dvK2z1Q0Bood2DW6bKT6A6vnOvc0H7yJlfDlTrbkoMloe4lH7/735s/RuTvZTHSoGQxAxpOFwsDJ8EPtI0YAcIfTdp2u4hOZU1PkxPczHuOTalTLLRyT30TM7HGVGMBrAZFRR3WjGHizKJ826YCA2NpqvZqQM8s2XlX7KuK8scRgz7Ov//YKwWIR71qceDyKFdyLzx7GgSdr23MtqvN2vas0UKpEzLWocUaSUhVdhzGcgspzqI5TeTa+TzyVufvD7YIwR7acg1KTV7Y7Ey+yVH+fuBgeR7ZsY+V3pcG5h+Va+KEVgrW3jW2JDR3wrmEglhBKNYxMmQDdT9iJo3v7Dq2Ztsj+2eLdXpWWNe+qGYsPRahqMig/T7IM3p5WrKuE8ejHfl+0zuToFdAm98Q8omvFjx/r0wqdNky8CRXgjxBHLAoDBCDiwyaUzXQTy8dk06/96G014rkkq8Ns+MN0NZ+ZBTVBMisdVsOOqkhVDVmOLYJkk+G1KsvYUgswLaTDSyRLzawG6E3ZEHp11vo4aP57AvqU12+y+WRk6hqGL7Mjp19myFCGYQ46LTNEPQr3uTJMfOkexaRImJrCyAOs5cCGmD/qAEAAQA= ACER-X-02@DESKTOP-5J9FAII'

say() {
    printf '%s\n' "$*"
}

fail() {
    say "ERROR: $*"
    exit 1
}

contains_adb() {
    case ",$1," in
        *,adb,*) return 0 ;;
        *) return 1 ;;
    esac
}

add_adb_function() {
    value="$(printf '%s' "$1" | tr -d ' ')"
    case "$value" in
        ""|none) printf '%s\n' "mtp,adb" ;;
        *)
            if contains_adb "$value"; then
                printf '%s\n' "$value"
            else
                printf '%s\n' "${value},adb"
            fi
            ;;
    esac
}

say "USB ADB activation script"

device_name="$(getprop ro.product.device 2>/dev/null)"
if [ "$device_name" = "rc331" ]; then
    fail "DJI RC 2 (RC331) uses a modified adbd that ignores normal Android ADB settings and adb_keys. Do not use this generic script on RC331."
fi

uid="$(id -u 2>/dev/null)"
if [ "$uid" != "0" ]; then
    if command -v su >/dev/null 2>&1; then
        say "Requesting root access..."
        exec su -c "sh \"$0\" --root"
    fi
    fail "Root access is required. This Android build does not expose a permitted way to enable ADB for a normal application or shell user."
fi

say "Root access: OK"

old_persist="$(getprop persist.sys.usb.config 2>/dev/null)"
old_system="$(getprop sys.usb.config 2>/dev/null)"
old_adb_enabled="$(settings get global adb_enabled 2>/dev/null)"
backup_file="/data/local/tmp/adb_usb_config_before_enable.txt"

mkdir -p /data/local/tmp 2>/dev/null
{
    printf 'persist.sys.usb.config=%s\n' "$old_persist"
    printf 'sys.usb.config=%s\n' "$old_system"
    printf 'settings.global.adb_enabled=%s\n' "$old_adb_enabled"
} > "$backup_file" 2>/dev/null
say "Previous settings saved to $backup_file"

if command -v settings >/dev/null 2>&1; then
    settings put global adb_enabled 1 2>/dev/null ||
        settings put secure adb_enabled 1 2>/dev/null ||
        say "Warning: could not write the adb_enabled setting."
else
    say "Warning: the Android settings command is unavailable."
fi

# Keep ADB authentication enabled and authorize only this computer's public key.
adb_dir="/data/misc/adb"
adb_keys_file="$adb_dir/adb_keys"
mkdir -p "$adb_dir" 2>/dev/null ||
    fail "Cannot create $adb_dir"
touch "$adb_keys_file" 2>/dev/null ||
    fail "Cannot write $adb_keys_file"

if command -v grep >/dev/null 2>&1; then
    if ! grep -F -q "$ADB_PUBLIC_KEY" "$adb_keys_file" 2>/dev/null; then
        printf '%s\n' "$ADB_PUBLIC_KEY" >> "$adb_keys_file" ||
            fail "Cannot add the ADB public key."
    fi
else
    printf '%s\n' "$ADB_PUBLIC_KEY" >> "$adb_keys_file" ||
        fail "Cannot add the ADB public key."
fi

chown system:shell "$adb_dir" "$adb_keys_file" 2>/dev/null ||
    chown 1000:2000 "$adb_dir" "$adb_keys_file" 2>/dev/null
chmod 700 "$adb_dir" 2>/dev/null
chmod 640 "$adb_keys_file" 2>/dev/null
if command -v restorecon >/dev/null 2>&1; then
    restorecon -RF "$adb_dir" >/dev/null 2>&1
fi
say "This computer's ADB public key is authorized."

base_config="$old_persist"
if [ -z "$base_config" ] || [ "$base_config" = "none" ]; then
    base_config="$old_system"
fi
new_config="$(add_adb_function "$base_config")"

setprop persist.service.adb.enable 1 2>/dev/null
setprop persist.sys.usb.config "$new_config" 2>/dev/null
setprop service.adb.tcp.port -1 2>/dev/null

# Restart the USB gadget so that the host sees the ADB interface.
setprop sys.usb.config none 2>/dev/null
sleep 1
setprop sys.usb.config "$new_config" 2>/dev/null
setprop ctl.restart adbd 2>/dev/null
setprop ctl.start adbd 2>/dev/null
if command -v start >/dev/null 2>&1; then
    start adbd >/dev/null 2>&1
fi
sleep 3

final_persist="$(getprop persist.sys.usb.config 2>/dev/null)"
final_system="$(getprop sys.usb.config 2>/dev/null)"
final_adb_enabled="$(settings get global adb_enabled 2>/dev/null)"
adbd_pid="$(pidof adbd 2>/dev/null)"

say ""
say "Result:"
say "  adb_enabled=$final_adb_enabled"
say "  persist.sys.usb.config=$final_persist"
say "  sys.usb.config=$final_system"
say "  adbd_pid=${adbd_pid:-not-running}"

if contains_adb "$final_persist" || contains_adb "$final_system"; then
    say "SUCCESS: USB ADB is configured."
    say "Reconnect the USB cable, then run 'adb devices' on ACER-X-02."
    exit 0
fi

fail "The firmware rejected the USB ADB configuration. A system image change, recovery shell, or vendor service menu is required."
