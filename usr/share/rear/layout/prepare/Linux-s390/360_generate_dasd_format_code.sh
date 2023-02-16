# LAYOUT_CODE is the script to recreate the dasd formatting (dasdformat.sh).

local component disk size label junk
local blocksize layout dasdtype dasdcyls junk2


save_original_file "$DASD_FORMAT_CODE"

# Initialize
cat <<EOF >"$DASD_FORMAT_CODE"
#!/bin/bash

LogPrint "Start DASD format restoration."

set -e
set -x

EOF

while read component disk size label junk; do
    if [ "$label" == dasd ]; then
        # dasd has more fields - junk is not junk anymore
        read blocksize layout dasdtype dasdcyls junk2 <<<$junk
        dasd_format_code "$disk" "$size" "$blocksize" "$layout" "$dasdtype" "$dasdcyls" >> "$DASD_FORMAT_CODE" || \
            LogPrintError "Error producing DASD format code for $disk"
    fi
done < <(grep "^disk " "$DASD_FORMAT_FILE")
