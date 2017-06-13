#!/usr/bin/env bash

# rmate
# Copyright (C) 2011-2016 by Harald Lapp <harald@octris.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

#
# This script can be found at:
# https://github.com/aurora/rmate
#

#
# This script is a pure bash compatible shell script implementing remote
# textmate functionality
#

#
# Thanks very much to all users and contributors! All bug-reports,
# feature-requests, patches, etc. are greatly appreciated! :-)
#

# init
#
version="0.9.8"
version_date="2016-04-14"
version_string="rmate-sh $version ($version_date)"

# determine hostname
function hostname_command(){
    if command -v hostname >/dev/null 2>&1; then
        echo "hostname"
    else {
        HOSTNAME_DESCRIPTOR="/proc/sys/kernel/hostname"
        if test -r "$HOSTNAME_DESCRIPTOR"; then
            echo "cat $HOSTNAME_DESCRIPTOR"
        else
            echo "hostname"
        fi
        }
    fi
}

hostname=$($(hostname_command))

# default configuration
host=localhost
port=52698
eval home=$(builtin printf "~%q" "${SUDO_USER:-$LOGNAME}")

function load_config {
    local rc_file=$1
    local row

    local host_pattern="^host(:[[:space:]]+|=)([^ ]+)"
    local port_pattern="^port(:[[:space:]]+|=)([0-9]+)"

    if [ -f "$rc_file" ]; then
        while read row; do
            if [[ "$row" =~ $host_pattern ]]; then
                host=${BASH_REMATCH[2]}
            elif [[ "$row" =~ $port_pattern ]]; then
                port=${BASH_REMATCH[2]}
            fi
        done < "$rc_file"
    fi
}

for i in "/etc/${0##*/}" $home/."${0##*/}/${0##*/}.rc" $home/."${0##*/}.rc"; do
    load_config $i
done

host="${RMATE_HOST:-$host}"
port="${RMATE_PORT:-$port}"


# misc initialization
filepath=""
selection=""
displayname=""
filetype=""
verbose=false
nowait=true
force=false

# process command-line parameters
#
function showusage {
    echo "usage: $(basename $0) [arguments] file-path  edit specified file
   or: $(basename $0) [arguments] -          read text from stdin

-H, --host HOST  Connect to HOST. Use 'auto' to detect the host from
                 SSH. Defaults to $host.
-p, --port PORT  Port number to use for connection. Defaults to $port.
-w, --[no-]wait  Wait for file to be closed by TextMate.
-l, --line LINE  Place caret on line number after loading file.
+N               Alias for --line, if N is a number (eg.: +5).
-m, --name NAME  The display name shown in TextMate.
-t, --type TYPE  Treat file as having specified type.
-n, --new        Open in a new window (Sublime Text).
-f, --force      Open even if file is not writable.
-v, --verbose    Verbose logging messages.
-h, --help       Display this usage information.
    --version    Show version and exit.
"
}

function log {
    if [[ $verbose = true ]]; then
        echo "$@" 1>&2
    fi
}

function dirpath {
    (cd `dirname $1` >/dev/null 2>/dev/null; pwd -P)
}

function canonicalize {
    filepath="$1"
    dir=`dirpath "$filepath"`
    if [ -L "$filepath" ]; then
        relativepath=`cd "$dir"; readlink \`basename "$filepath"\``
        result=`dirpath "$relativepath"`/`basename "$relativepath"`
    else
        result=`basename "$filepath"`
        if [ "$dir" = '/' ]; then
            result="$dir$result"
        else
            result="$dir/$result"
        fi
    fi
    echo $result
}

while [[ "${1:0:1}" = "-" || "$1" =~ ^\+([0-9]+)$ ]]; do
    case $1 in
        -)
            break
            ;;
        -H|--host)
            host=$2
            shift
            ;;
        -p|--port)
            port=$2
            shift
            ;;
        -w|--wait)
            nowait=false
            ;;
        --no-wait)
            nowait=true
            ;;
        -l|--line)
            selection=$2
            shift
            ;;
        -m|--name)
            displayname=$2
            shift
            ;;
        -t|--type)
            filetype=$2
            shift
            ;;
        -n|--new)
            new=true
            ;;
        -f|--force)
            force=true
            ;;
        -v|--verbose)
            verbose=true
            ;;
        --version)
            echo $version_string
            exit 1
            ;;
        -h|-\?|--help)
            showusage
            exit 1
            ;;
        +[0-9]*)
            selection=${1:1}
            ;;
        *)
            showusage
            exit 1
            ;;
    esac

    shift
done

if [[ "$host" = "auto" && "$SSH_CONNECTION" != "" ]]; then
    host=${SSH_CONNECTION%% *}
fi

filepath="$1"

if [ "$filepath" = "" ]; then
    if [[ $nowait = false ]]; then
        filepath='-'
    else
        case "$-" in
            *i*)
                showusage
                exit 1
                ;;
            *)
                filepath='-'
                ;;
        esac
    fi
fi

shift
if [ ! "${#@}" -eq 0 ]; then
    echo "There is more than one file specified. Opening only $filepath and ignoring other."
fi

if [ "$filepath" != "-" ]; then
    realpath=`canonicalize "$filepath"`
    log $realpath

    if [ -d "$filepath" ]; then
        echo "$filepath is a directory and rmate is unable to handle directories."
        exit 1
    fi

    if [ -f "$realpath" ] && [ ! -w "$realpath" ]; then
        if [[ $force = false ]]; then
            echo "File $filepath is not writable! Use -f to open anyway."
            exit 1
        elif [[ $verbose = true ]]; then
            log "File $filepath is not writable! Opening anyway."
        fi
    fi

    if [ "$displayname" = "" ]; then
        displayname="$hostname:$filepath"
    fi
else
    displayname="$hostname:untitled"
fi

#------------------------------------------------------------
# main
#------------------------------------------------------------
function handle_connection {
    local cmd
    local name
    local value
    local token
    local tmp

    while read 0<&3; do
        REPLY="${REPLY#"${REPLY%%[![:space:]]*}"}"
        REPLY="${REPLY%"${REPLY##*[![:space:]]}"}"

        cmd=$REPLY

        token=""
        tmp=""

        while read 0<&3; do
            REPLY="${REPLY#"${REPLY%%[![:space:]]*}"}"
            REPLY="${REPLY%"${REPLY##*[![:space:]]}"}"

            if [ "$REPLY" = "" ]; then
                break
            fi

            name="${REPLY%%:*}"
            value="${REPLY##*:}"
            value="${value#"${value%%[![:space:]]*}"}"      # fix textmate syntax highlighting: "

            case $name in
                "token")
                    token=$value
                    ;;
                "data")
                    if [ "$tmp" = "" ]; then
                        tmp="/tmp/rmate.$RANDOM.$$"
                        touch "$tmp"
                    fi

                    dd bs=1 count=$value <&3 >>"$tmp" 2>/dev/null
                    ;;
                *)
                    ;;
            esac
        done

        if [[ "$cmd" = "close" ]]; then
            log "Closing $token"
            if [[ "$token" == "-" ]]; then
                echo -n "$CONTENT"
            fi
        elif [[ "$cmd" = "save" ]]; then
            log "Saving $token"
            if [ "$token" != "-" ]; then
                cat "$tmp" > "$token"
            else
                CONTENT=`cat "$tmp"`
            fi
            rm "$tmp"
        fi
    done

    log "Done"
}

# connect to textmate and send command
#
exec 3<> /dev/tcp/$host/$port

if [ $? -gt 0 ]; then
    echo "Unable to connect to TextMate on $host:$port"
    exit 1
fi

read server_info 0<&3

log $server_info

echo "open" 1>&3
echo "display-name: $displayname" 1>&3
echo "real-path: $realpath" 1>&3
echo "data-on-save: yes" 1>&3
echo "re-activate: yes" 1>&3
echo "token: $filepath" 1>&3

if [[ $new = true ]]; then
    echo "new: yes"  1>&3
fi

if [ "$selection" != "" ]; then
    echo "selection: $selection" 1>&3
fi

if [ "$filetype" != "" ]; then
    echo "file-type: $filetype" 1>&3
fi

if [ "$filepath" != "-" ] && [ -f "$filepath" ]; then
    filesize=`ls -lLn "$realpath" | awk '{print $5}'`
    echo "data: $filesize" 1>&3
    cat "$realpath" 1>&3
elif [ "$filepath" = "-" ]; then
    if [ -t 0 ]; then
        echo "Reading from stdin, press ^D to stop"
    else
        log "Reading from stdin"
    fi

    # preserve trailing newlines
    data=`cat; echo x`
    data=${data%x}
    filesize=$(echo -ne "$data" | wc -c)
    echo "data: $filesize" 1>&3
    echo -n "$data" 1>&3
else
    echo "data: 0" 1>&3
fi

echo 1>&3
echo "." 1>&3

if [[ $nowait = true ]]; then
    exec </dev/null >/dev/null 2>/dev/null
    ( (handle_connection &) &)
else
    handle_connection
fi
