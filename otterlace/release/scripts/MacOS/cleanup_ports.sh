#!/bin/bash

set -e # bail out on error

. "$( dirname "$0" )/_macos.sh" || exit 1
port_sanity_check || exit 3

ports_list="${etc_macos}/cleanup_ports.list"

port_cmd="${install_base}/bin/port"

# special case: force uninstall python

"${port_cmd}" -f uninstall python27 || true # ok to fail if already removed

# source file is at the end of the while...
while read entry; do

    [[ $entry =~ ^# ]]             && continue # skip comment lines
    [[ $entry =~ ^[[:space:]]*$ ]] && continue # skip blank lines

    "${port_cmd}" uninstall "$entry" || true # ok to fail if already removed

done < "${ports_list}"

exit 0