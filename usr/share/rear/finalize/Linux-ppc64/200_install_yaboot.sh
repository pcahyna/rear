
# skip if yaboot conf is not found
test -f $TARGET_FS_ROOT/etc/yaboot.conf || return

# Reinstall yaboot boot loader
LogPrint "Installing PPC PReP Boot partition."

# Find PPC PReP Boot partitions
part=$( awk -F '=' '/^boot=/ {print $2}' $TARGET_FS_ROOT/etc/yaboot.conf )

if test "$part" ; then
    LogPrint "Boot partion found: $part"
    # Run mkofboot directly in chroot without a login shell in between, see https://github.com/rear/rear/issues/862
    chroot $TARGET_FS_ROOT /sbin/mkofboot -b $part --filesystem raw -f
    bootdev=$( echo $part | sed -e 's/[0-9]*$//' )
    LogPrint "Boot device is $bootdev."
    bootlist -m normal $bootdev
    NOBOOTLOADER=
else
    bootparts=$( sfdisk -l 2>&1 | awk '/PPC PReP Boot/ {print $1}' )
    LogPrint "Boot partitions found: $bootparts."
    for part in $bootparts ; do
        LogPrint "Initializing boot partition $part."
        # Run mkofboot directly in chroot without a login shell in between, see https://github.com/rear/rear/issues/862
        chroot $TARGET_FS_ROOT /sbin/mkofboot -b $part --filesystem raw -f
    done
    bootdev=$( for part in $bootparts ; do echo $part | sed -e 's/[0-9]*$//' ; done | sort | uniq )
    LogPrint "Boot device list is $bootdev."
    bootlist -m normal $bootdev
    NOBOOTLOADER=
fi

