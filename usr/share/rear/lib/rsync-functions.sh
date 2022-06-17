# Functions for manipulation of rsync URLs (both OUTPUT_URL and BACKUP_URL)

#### OLD STYLE:
# BACKUP_URL=[USER@]HOST:PATH           # using ssh (no rsh)
#
# with rsync protocol PATH is a MODULE name defined in remote /etc/rsyncd.conf file
# BACKUP_URL=[USER@]HOST::PATH          # using rsync
# BACKUP_URL=rsync://[USER@]HOST[:PORT]/PATH    # using rsync (is not compatible with new style!!!)

#### NEW STYLE:
# BACKUP_URL=rsync://[USER@]HOST[:PORT]/PATH    # using ssh
# BACKUP_URL=rsync://[USER@]HOST[:PORT]::/PATH  # using rsync

function rsync_validate () {
    local url="$1"

    if [[ "$(url_scheme "$url")" != "rsync" ]]; then # url_scheme still recognizes old style
        Error "Non-rsync URL $url !"
    fi
}

function rsync_proto () {
    local url="$1"

    rsync_validate "$url"
    if egrep -q '(::)' <<< $url ; then # new style '::' means rsync protocol
        echo rsync
    else
        echo ssh
    fi
}

function rsync_user () {
    local url="$1"
    local host

    host=$(url_host "$url")

    if grep -q '@' <<< $host ; then
        echo "${host%%@*}"    # grab user name
    else
        echo root
    fi
}

function rsync_host () {
    local url="$1"
    local host
    local path

    host=$(url_host "$url")
    path=$(url_path "$url")
    # remove USER@ if present
    local tmp2="${host#*@}"

    case "$(rsync_proto "$url")" in
        (rsync)
            # tmp2=witsbebelnx02::backup or tmp2=witsbebelnx02::
            echo "${tmp2%%::*}"
            ;;
        (ssh)
            # tmp2=host or tmp2=host:
            echo "${tmp2%%:*}"
            ;;
    esac
}

function rsync_path () {
    local url="$1"
    local host
    local path

    host=$(url_host "$url")
    path=$(url_path "$url")
    local tmp2="${host#*@}"

    case "$(rsync_proto "$url")" in

        (rsync)
            # path=/gdhaese1@witsbebelnx02::backup or path=/backup
            if grep -q '::' <<< $path ; then
                echo "${path##*::}"
            else
                # XXX what if path=/backup/sub/directory ? Should we remove
                # longest prefix?
                echo "${path##*/}"
            fi
            ;;
        (ssh)
            echo "$path"
            ;;

    esac
}

function rsync_port () {
    # XXX changing port not implemented yet
    echo 873
}

function rsync_path_full () {
    local url="$1"

    echo "$(rsync_path "$url")/${RSYNC_PREFIX}"
}

function rsync_remote_ssh () {
    local url="$1"

    local user host

    user="$(rsync_user "$url")"
    host="$(rsync_host "$url")"

    echo "${user}@${host}"
}

function rsync_remote_base () {
    local url="$1"

    local user host port

    user="$(rsync_user "$url")"
    host="$(rsync_host "$url")"
    port="$(rsync_port "$url")"

    case "$(rsync_proto "$url")" in

        (rsync)
            echo "rsync://${user}@${host}:${port}/"
            ;;
        (ssh)
            echo "$(rsync_remote_ssh "$url"):"
            ;;

    esac
}

function rsync_remote () {
    local url="$1"

    echo "$(rsync_remote_base "$url")$(rsync_path "$url")"
}

function rsync_remote_full () {
    local url="$1"

    echo "$(rsync_remote_base "$url")$(rsync_path_full "$url")"
}
