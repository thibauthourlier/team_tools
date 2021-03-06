#!/bin/bash

set -e # bail out on error

BUILD_DIR="$PWD"
APP_NAME="otterlace"
CODEBASE="$HOME/enscode"
OTTER_DIR="$CODEBASE/ensembl-otter"
TEAMTOOLS_DIR="$CODEBASE/team_tools"
MACOSSCRIPTS_DIR="$TEAMTOOLS_DIR/otterlace/release/scripts/MacOS"
USAGE=0
# cros_match has a license which means we cannot package it to anyone
# Only people working in Ensembl can have it
CROSS_MATCH=0
DO_ARCHIVE=""
DO_ACE=0
STATUS=0
STOP_SCRIPT=0

while getopts ":a:Ab:c:mo:r:sS:t:x:y:" o; do
    case $o in
        a ) APP_NAME=$OPTARG;;
        A ) DO_ACE=1;;
        b ) BUILD_DIR=$OPTARG;;
        c ) CODEBASE=$OPTARG;;
        m ) CROSS_MATCH=1;;
        o ) OTTER_DIR=$OPTARG;;
        r ) DO_ARCHIVE=$OPTARG;;
        s ) STOP_SCRIPT=1;;
        S ) STATUS=$OPTARG;;
        t ) TEAMTOOLS_DIR=$OPTARG;;
        x ) export MACOSX_XCODE_PATH=$OPTARG;;
        y ) export MACOSX_DEPLOYMENT_TARGET=$OPTARG;;
        * ) USAGE=1;;
    esac
done

if [ $USAGE -eq 1 ];then
  cat <<EOF

    The script will initialise the creation of an ${APP_NAME} application to connect to a Loutre database.
    It will create three directory in ${BUILD_DIR}:
     - _macports_src
     - _non_dist
     - ${APP_NAME}.app
    It will use scripts in ${TEAMTOOLS_DIR} and ${OTTER_DIR}
    It will expect to find the archive for ZMap and Seqtools in ${CODEBASE}
    Available options are:
       -a Name of the application, current value is ${APP_NAME}
       -A Use AceDB, this should not be used anymore
       -b Working directory, default is ${BUILD_DIR}
       -c Directory containing the archives for ZMap and Seqtools, current is ${CODEBASE}
       -m Flag to compile cross_match, the phrap archive should be in ${CODEBASE}
       -o ensembl-otter directory, current is ${OTTER_DIR}
       -r create an archive of the three directory in ${BUILD_DIR}, the directory/(filename) needs to be specified, default is 'build_${APP_NAME}.tar.gz'
       -s Stop the script after the first step started
       -S Specify at which step you want to start. Default is all
            1 Cpan modules
            2 Zmap, otter,...
            3 Create the dmg
       -t team_tools directory, current is ${TEAMTOOLS_DIR}
       -x Path to the OS X SDK, use only if the SDK is not in a default location
       -y Minimum deployment target, the default is the current OS X version

EOF
  exit 42
fi

if [ $STATUS -lt 1 ]; then
  if [ -n "$DO_ARCHIVE" ]; then
    if [ -d "$DO_ARCHIVE" ]; then
      if [ -w "$DO_ARCHIVE" ]; then
        DO_ARCHIVE="$DO_ARCHIVE/build_${APP_NAME}.tar.gz"
      else
        echo "Cannot write to $DO_ARCHIVE"
        exit 1
      fi
    fi
    if [ -e "$DO_ARCHIVE" ];then
      echo "File '$DO_ARCHIVE' already exists"
      exit 2
    fi
  fi

  if [ -d "${APP_NAME}.app" ]; then
    echo "setup_app_skeleton.sh has already been run"
  else
    $MACOSSCRIPTS_DIR/setup_app_skeleton.sh "${APP_NAME}.app"
    if [ $? -ne 0 ];then
      echo "Failed on setup_app_skeleton.sh"
      exit 1
    fi
  fi

  cd "${BUILD_DIR}/${APP_NAME}.app"

  if [ -e "Contents/Resources/bin/port" ]; then
    echo "MacPort has already been installed"
  else
    $MACOSSCRIPTS_DIR/install_macports.sh
    if [ $? -ne 0 ];then
      echo "Failed on install_macports.sh"
      exit 1
    fi
  fi

  $MACOSSCRIPTS_DIR/install_ports.sh
  if [ $? -ne 0 ];then
    echo "Failed on install_ports.sh"
    exit 1
  fi

  if [ -e "Contents/Resources/lib/kent/src/lib/x86_64/jkweb.a" ]; then
    echo "Kent libraries have been compiled"
  else
    $MACOSSCRIPTS_DIR/install_kent.sh
    if [ $? -ne 0 ];then
      echo "Failed on install_kent.sh"
      exit 1
    fi
  fi

  if [ $CROSS_MATCH -eq 1 ]; then
    $MACOSSCRIPTS_DIR/install_crossmatch.sh $CODEBASE
    if [ $? -ne 0 ];then
      echo "Failed on install_crossmatch.sh"
      exit 1
    fi
  fi

  if [ -n "$DO_ARCHIVE" ]; then
    cd ${BUILD_DIR}
    tar -czvf "${DO_ARCHIVE}" ${APP_NAME}.app _macports_src _non_dist
    cd "${APP_NAME}.app"
  fi
  STATUS=1
  if [ $STOP_SCRIPT -eq 1 ];then
    echo "You want to stop now"
    exit 0
  fi
fi

if [ $STATUS -lt 2 ];then
  cd "${BUILD_DIR}/${APP_NAME}.app"

  $MACOSSCRIPTS_DIR/install_cpan_bundle.sh
  if [ $? -ne 0 ];then
    echo "Failed on install_cpan_bundle.sh"
    exit 1
  fi

  $MACOSSCRIPTS_DIR/cleanup_ports.sh
  if [ $? -ne 0 ];then
    echo "Failed on cleanup_ports.sh"
    exit 1
  fi
  STATUS=2
  if [ $STOP_SCRIPT -eq 1 ];then
    echo "You want to stop now"
    exit 0
  fi
fi

if [ $STATUS -lt 3 ];then
  cd "${BUILD_DIR}/${APP_NAME}.app"

  $MACOSSCRIPTS_DIR/import_dist_extras.sh
  if [ $? -ne 0 ];then
    echo "Failed on import_dist_extras.sh"
    exit 1
  fi

# This should not be needed anymore as to my knowledge AceDB is not used in Havana
# If it is needed, the archive can be found at ftp://ftp.sanger.ac.uk/pub/acedb/
# but it will need some work
  if [ $DO_ACE -eq 1 ]; then
    $MACOSSCRIPTS_DIR/install_annotools_prereqs.sh $CODEBASE
    if [ $? -ne 0 ];then
      echo "Failed on install_annotools_prereqs.sh"
      exit 1
    fi
  fi

  $MACOSSCRIPTS_DIR/install_annotools.sh $CODEBASE
  if [ $? -ne 0 ];then
    echo "Failed on install_annotools.sh"
    exit 1
  fi

  $MACOSSCRIPTS_DIR/install_otterlace.sh $CODEBASE/ensembl-otter
  if [ $? -ne 0 ];then
    echo "Failed on install_otterlace.sh"
    exit 1
  fi

  $MACOSSCRIPTS_DIR/cleanup_unused.sh
  if [ $? -ne 0 ];then
    echo "Failed on cleanup_unused.sh"
    exit 1
  fi
  STATUS=3
  if [ $STOP_SCRIPT -eq 1 ];then
    echo "You want to stop now"
    exit 0
  fi
fi

if [ $STATUS -lt 4 ];then
  cd "${BUILD_DIR}/${APP_NAME}.app"

  . "${MACOSSCRIPTS_DIR}/_macos_in_app.sh" || exit 7
  . "${MACOSSCRIPTS_DIR}/_annotools_env.sh" || exit 8
  OTTER_VERSION=`basename $(find ./ -type d -name "otter_rel*" | sed 's/otter_rel//')`

  cd "${BUILD_DIR}"
  $MACOSSCRIPTS_DIR/build_sparse_image.sh --detach -r "${APP_NAME}_mac_intel-${MACOSX_DEPLOYMENT_TARGET}-${OTTER_VERSION}" -M "${APP_NAME}.app"
  if [ $? -ne 0 ];then
    echo "Failed on build_sparse_image.sh"
    exit 1
  fi

  $MACOSSCRIPTS_DIR/compress_image.sh "${APP_NAME}_mac_intel-${MACOSX_DEPLOYMENT_TARGET}-${OTTER_VERSION}.sparseimage"
  if [ $? -ne 0 ];then
    echo "Failed on compress_image.sh"
    exit 1
  fi

  rm "${APP_NAME}_mac_intel-${MACOSX_DEPLOYMENT_TARGET}-${OTTER_VERSION}.sparseimage"
fi
