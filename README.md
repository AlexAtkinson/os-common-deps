# os-common-deps (WIP)

Ensures common utilities and dependencies are installed for MacOS (and soon linux distros with apt-get/dnf package managers.)

## Motivation

As a DevOps engineer writing scripts to facilitate local dev environments, I would like it if everyone had the same set of utilities available.
Note that while this is commonly facilitated by an MDM solution in larger organizations this is often a point of frustration for startups.

Tools such as [linuxify](https://github.com/fabiomaia/linuxify) and [macgnu](https://github.com/shinokada/macgnu) exist, but they only address MacOS. As mentioned, this script will facilitate a few popular Linux distros as well.

## Usage

This script can be run at any time, but ideally it is run as step one of an onboarding laptop setup guide.

*Run:*
```
bash <(curl -s <THE URL OF THIS SCRIPT (UPDATE LATER - GET RAW URL FOR NOW)>)
```

## Dependencies

### MacOS

The majority of these dependencies are up to date versions of common gnu kit, which MacOS has been deprived of updates for... Is it decades? It feels like decades. Licensing is rough.

Note that brew installs packages in '/usr/local/Cellar/' and creates symlinks in '/usr/opt/local' and '/usr/local/bin'.

| MacOS Packages                                           |
| ----------- | ----------- | ---------- | --------------- |
| brew        | curl        | gnu-which  | ca-certificates |
| bash        | gnu-sed     | grep       |                 |
| coreutils   | gnu-tar     | md5sha1sum |                 |
| vim         | gzip        | glibc      |                 |
| bc          | unzip       | glib       |                 |
| less        | jq          | gcc        |                 |
| git         | yq          | binutils   |                 |
| mutagen     | findutils   | openssl    | docker          |
| wget        | gnu-getopt  | gnutls     | asdf            |
| ----------- | ----------- | ---------- | --------------- |

### Linux

Linux will get the usual suspects, vim, bc, curl, wget, etc.

## Maintenance

Packages to be installed by this script are facilitated by both the 'packages' array and the 'installFoo' functions associated with it.
TODO: Separate array by OS/Flavor.

When adding/removing dependencies, make the necessary changes in both places.
EXCEPTION: brew packages iterate a common brew install function.

