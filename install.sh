#!/usr/bin/env bash
# install.sh
#
# ----------------------------------------------------------------------------------------
# Help
# ----------------------------------------------------------------------------------------
show_help() {
cat << EOF

This scrit checks for and installs dev dependencies on a MacOS computer.
NOTEs:
  - You can optionally use macgnu or linuxify.
  - This script installs gnu versions, but DOES NOT setup aliases for them.

Use: ${0##*/} -e {-r}
    -r   REPORT         Check for dependencies and report without installing.
    -h   HELP           Show this help menu.

Examples:
    Run the script.
      ./${0##*/}
    Generate a dependnecy report.
      ./${0##*/} -r

EOF
exit 1
}

# ----------------------------------------------------------------------------------------
# Arguments
# ----------------------------------------------------------------------------------------

OPTIND=1
while getopts "hrf" opt; do
  case "$opt" in
    h)
      show_help
      ;;
    r)
      arg_r='set'
      ;;
    f)
      arg_f='set'
      # This is a hidden arg for the developer.
      # This arg permits the script to run on non-macos systems.
      ;;
    :)
      echo "ERROR: Option -$OPTARG requires an argument."
      show_help
      ;;
    *)
      echo "ERROR: Unknown option!"
      show_help
      ;;
  esac
done
shift "$((OPTIND-1))"
[ "$1" = "--" ] && shift

# ----------------------------------------------------------------------------------------
# Functions
# ----------------------------------------------------------------------------------------

case "$OSTYPE" in
  darwin*)  export OS_TYPE="OSX" ;;
  #linux*)   export OS_TYPE="LINUX" ;;
  *)
    echo -e "\e[01;31mERROR\e[0m: $OSTYPE not supported!"
    exit 1
  ;;
esac

function printHeading() {
  txt="$@"
  printf "\n\e[01;39M${txt}\e[0m "
  printf '\n%*s' "$((${COLUMNS}-$((${COLUMNS}-$(wc -c<<<$txt)+1))))" | tr ' ' -
  printf '\n'
}

function ask {
    while true; do
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        elif [ "${2:-}" = "Range" ]; then
            prompt="${3:-}"
            default=0
        else
            prompt="y/n"
            default=
        fi
        # Ask the question
        read -p $"$1 [$prompt]: " reply
        # Default?
        if [ -z "$reply" ]; then
            reply=$default
        fi
        # Check if the reply is valid
        case "$reply" in
            Y*|y*|[1-99]) return 0 ;;
            N*|n*|0*) return 1 ;;
        esac
    done
}

function log() {
  case $1 in
    0|emerg)
      level='\e[01;30;41mEMERGENCY\e[0m'
      ;;
    1|alert)
      level='\e[01;31;43mALERT\e[0m'
      ;;
    2|crit)
      level='\e[01;97;41mCRITICAL\e[0m'
      ;;
    3|err)
      level='\e[01;31mERROR\e[0m'
      ;;
    4|warn)
      level='\e[01;33mWARNING\e[0m'
      ;;
    5|notice)
      level='\e[01;30;107mNOTICE\e[0m'
      ;;
    6|info)
      level='\e[01;39mINFO\e[0m'
      ;;
    7|debug)
      level='\e[01;97;46mDEBUG\e[0m'
      ;;
    77|succ)
      level='\e[01;32mSUCCESS\e[0m'
      # Not a real severity level under RFC5425. Purely for display purposes.
      ;;
    *)
      echo -e "\e[01;31mERROR\e[00m: Invalid level argument!"
      exit 1
      ;;
  esac
  msg=${@:2}
  echo -e "$($ts) - $level: $msg" | tee -a ~/${0##*/}.log
}

function checkIsInstalled() {
  package=$(cut -d_ -f2- <<< $package)
  if [[ ! $(command -v $package) ]]; then
      confirmInstall $package
  else
    log 6 "$package - OK"
  fi
}

function verifyInstall() {
  package=$(cut -d_ -f2- <<< $package)
  if [[ $(command -v $package) ]]; then
    log 77 "$package installed."
  else
    log 3 "$package failed to install!"
  fi
}

function confirmInstall() {
  if [[ -z ${arg_r+x} ]]; then
    if ask "Confirm: Install $package?" Y; then
      answer="yes"
    else
      answer="no"
    fi
  else
    log 6 "$package is NOT installed."
  fi
}

function doInstall() {
    if [[ $answer == "yes" ]]; then
      log 5 "Installing $package..."
      install$package
      verifyInstall
      unset answer
    fi
}

function doBrewInstall() {
    if [[ $answer == "yes" ]]; then
      log 5 "Installing $package..."
      brew install $package
      verifyInstall
      unset answer
    fi
}

function installbrew() {
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}
function installdocker() {
  if [[ $(uname -m) == 'arm64' ]]; then
    log 6 "Installing for Apple M1 CPU."
    log 5 "Installing Rosetta 2..."
    softwareupdate --install-rosetta
    wget https://desktop.docker.com/mac/main/arm64/Docker.dmg
  else
    log 6 "Installing for Intel CPU."
    wget https://desktop.docker.com/mac/main/amd64/Docker.dmg
  fi
    sudo hdiutil attach Docker.dmg
    sudo /Volumes/Docker/Docker.app/Contents/MacOS/install --accept-license
    sudo hdiutil detach /Volumes/Docker
}

installasdf() {
  # https://www.wiserfirst.com/blog/how-to-use-asdf-on-macos/
  # https://www.youtube.com/watch?v=RTaqWRj-6Lg
  artifact='v0.10.2.zip'
  md5sum='ebb76713bf2388d096d603d21f0f6de3'
  wget https://github.com/asdf-vm/asdf/archive/refs/tags/"$artifact"
  # Update resources/checkmd5.md5 with: 'md5sum vX.X.X.zip > resources/checkmd5.md5' as needed.
  if [[ $(md5sum --quiet -c resources/checkmd5.md5) ]]; then
    rm -rf ~/.asdf/ /tmp/asdf/
    unzip -q "$artifact" -d /tmp/asdf
    rm -f "$artifact"
    mkdir ~/.asdf
    mv /tmp/asdf/"$artifact"/* ~/.asdf/
    rm -rf /tmp/asdf/
  else
    log 4 "asdf NOT installed!"
    log 4 "MD5 checksum for $artifact FAILED!"
}

# ----------------------------------------------------------------------------------------
# Variables
# ----------------------------------------------------------------------------------------

# brew must be first.
# coreutils contents: http://www.maizure.org/projects/decoded-gnu-coreutils/
packages=()
packages+=( brew
            brew_bash
            brew_coreutils
            brew_vim
            brew_bc
            brew_less
            brew_git
            brew_mutagen
            brew_wget
            brew_curl
            brew_gnu-sed
            brew_gawk
            brew_gnu-tar
            brew_gzip
            brew_unzip
            brew_jq
            brew_yq
            brew_gnu-getopt
            brew_findutils
            brew_gnu-which
            brew_grep
            brew_md5sha1sum
            brew_glibc
            brew_glib
            brew_gcc
            brew_binutils
            brew_openssl
            brew_gnutls
            brew_ca-certificates
            docker
            asdf
          )

# ----------------------------------------------------------------------------------------
# Main Operations
# ----------------------------------------------------------------------------------------

if [[ -n ${arg_r+x} ]]; then
  printHeading "Generating dependencies report..."
else
l printHeading "Checking for dependencies..."
fi

for package in ${packages[@]}; do
  if [[ ! $package =~ "brew_" ]]; then
    checkIsInstalled
    [[ ! -n ${arg_r+x} ]] && doInstall
  else
    checkIsInstalled
    [[ ! -n ${arg_r+x} ]] && doBrewInstall
  fi
done

