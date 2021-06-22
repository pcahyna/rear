# Describe LUKS devices
# We use /etc/crypttab and cryptsetup for information

if ! has_binary cryptsetup; then
    return
fi

Log "Saving Encrypted volumes."
REQUIRED_PROGS+=( cryptsetup dmsetup )
COPY_AS_IS+=( /usr/share/cracklib/\* /etc/security/pwquality.conf )

while read target_name junk ; do
    # find the target device we're mapping
    if ! [ -e /dev/mapper/$target_name ] ; then
        Log "Device Mapper name $target_name not found in /dev/mapper."
        continue
    fi

    sysfs_device=$(get_sysfs_name /dev/mapper/$target_name)
    if [ -z "$sysfs_device" ] ; then
        Log "Could not find device $target_name in sysfs."
        continue
    fi

    source_device=""
    for slave in /sys/block/$sysfs_device/slaves/* ; do
        if ! [ -z "$source_device" ] ; then
            BugError "Multiple Device Mapper slaves for crypt $target_name detected."
        fi
        source_device="$(get_device_name ${slave##*/})"
    done

    if ! blkid -p -o export $source_device >$TMP_DIR/blkid.output ; then
        LogPrintError "Error: Cannot get attributes for $target_name ('blkid -p -o export $source_device' failed)"
        continue
    fi

    if ! grep -q "TYPE=crypto_LUKS" $TMP_DIR/blkid.output ; then
        Log "Skipping $target_name (no 'TYPE=crypto_LUKS' in 'blkid -p -o export $source_device' output)"
        continue
    fi

    # Detect LUKS version
    version=$( grep "" $TMP_DIR/blkid.output | cut -d= -f2 )
    if ! test "$version" = "1" -o "$version" = "2" ; then
        LogPrintError "Error: Unsupported LUKS version for $target_name ('blkid -p -o export $source_device' shows 'VERSION $version')"
        continue
    fi
    luks_type=luks$version

    # Gather crypt information:
    if ! cryptsetup luksDump $source_device >$TMP_DIR/cryptsetup.luksDump ; then
        LogPrintError "Error: Cannot get LUKS values for $target_name ('cryptsetup luksDump $source_device' failed)"
        continue
    fi
    uuid=$( grep "UUID" $TMP_DIR/cryptsetup.luksDump | sed -r 's/^.+:\s*(.+)$/\1/' )
    keyfile_option=$( [ -f /etc/crypttab ] && awk '$1 == "'"$target_name"'" && $3 != "none" && $3 != "-" && $3 != "" { print "keyfile=" $3; }' /etc/crypttab )
    if test $luks_type = "luks1" ; then
        cipher_name=$( grep "Cipher name" $TMP_DIR/cryptsetup.luksDump | sed -r 's/^.+:\s*(.+)$/\1/' )
        cipher_mode=$( grep "Cipher mode" $TMP_DIR/cryptsetup.luksDump | cut -d: -f2- | awk '{printf("%s",$1)};' )
        cipher=$cipher_name-$cipher_mode
        key_size=$( grep "MK bits" $TMP_DIR/cryptsetup.luksDump | sed -r 's/^.+:\s*(.+)$/\1/' )
        hash=$( grep "Hash spec" $TMP_DIR/cryptsetup.luksDump | sed -r 's/^.+:\s*(.+)$/\1/' )
    elif test $luks_type = "luks2" ; then
        cipher=$( grep "cipher:" $TMP_DIR/cryptsetup.luksDump | sed -r 's/^.+:\s*(.+)$/\1/' )
        key_size=$( grep "Cipher key" $TMP_DIR/cryptsetup.luksDump | sed -r 's/^.+:\s*(.+) bits$/\1/' )
        hash=$( grep "Hash" $TMP_DIR/cryptsetup.luksDump | sed -r 's/^.+:\s*(.+)$/\1/' )
    fi

    echo "crypt /dev/mapper/$target_name $source_device type=$luks_type cipher=$cipher key_size=$key_size hash=$hash uuid=$uuid $keyfile_option" >> $DISKLAYOUT_FILE

done < <( dmsetup ls --target crypt )

# cryptsetup is required in the recovery system if disklayout.conf contains at least one 'crypt' entry
# see the create_crypt function in layout/prepare/GNU/Linux/160_include_luks_code.sh
# what program calls are written to diskrestore.sh
# cf. https://github.com/rear/rear/issues/1963
grep -q '^crypt ' $DISKLAYOUT_FILE && REQUIRED_PROGS+=( cryptsetup ) || true

