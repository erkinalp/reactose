#!/usr/bin/env bash
set -Eeuo pipefail

: "${KEY:=""}"
: "${WIDTH:=""}"
: "${HEIGHT:=""}"
: "${VERIFY:=""}"
: "${REGION:=""}"
: "${EDITION:=""}"
: "${MANUAL:=""}"
: "${REMOVE:=""}"
: "${VERSION:=""}"
: "${DETECTED:=""}"
: "${KEYBOARD:=""}"
: "${LANGUAGE:=""}"
: "${USERNAME:=""}"
: "${PASSWORD:=""}"

MIRRORS=0

parseVersion() {

  if [[ "${VERSION}" == \"*\" || "${VERSION}" == \'*\' ]]; then
    VERSION="${VERSION:1:-1}"
  fi

  VERSION=$(expr "$VERSION" : "^\ *\(.*[^ ]\)\ *$")
  [ -z "$VERSION" ] && VERSION="0.4.15"

  case "${VERSION,,}" in
    "latest" | "0.4.15" | "reactos" | "reactos-0.4.15" )
      VERSION="reactos-0.4.15"
      ;;
    "0.4.14" | "reactos-0.4.14" )
      VERSION="reactos-0.4.14"
      ;;
    "0.4.13" | "reactos-0.4.13" )
      VERSION="reactos-0.4.13"
      ;;
    "live" | "livecd" | "live-cd" | "0.4.15-live" )
      VERSION="reactos-0.4.15-live"
      ;;
    "0.4.14-live" )
      VERSION="reactos-0.4.14-live"
      ;;
    "nightly" | "nightly-bootcd" | "reactos-nightly" )
      VERSION="reactos-nightly"
      ;;
    "nightly-live" | "nightly-livecd" | "reactos-nightly-live" )
      VERSION="reactos-nightly-live"
      ;;
  esac

  return 0
}

getLanguage() {

  local id="$1"
  local ret="$2"
  local lang=""
  local desc=""
  local short=""
  local culture=""

  # ReactOS is primarily English, but we keep the structure for compatibility
  case "${id,,}" in
    "en" | "en-"* )
      short="en"
      lang="English"
      desc="English"
      culture="en-US" ;;
    *)
      short="en"
      lang="English"
      desc="English"
      culture="en-US" ;;
  esac

  case "${ret,,}" in
    "short" ) echo "$short" ;;
    "desc" ) echo "$desc" ;;
    "culture" ) echo "$culture" ;;
    *) echo "$lang";;
  esac

  return 0
}

parseLanguage() {

  LANGUAGE="${LANGUAGE//_/-}"

  case "${LANGUAGE,,}" in
    "arabic" | "arab" ) LANGUAGE="ar" ;;
    "bulgarian" | "bulgaria" ) LANGUAGE="bg" ;;
    "chinese" | "chinese-tw" ) LANGUAGE="zh-cn" ;;
    "croatian" | "croatia" | "hrvatski" ) LANGUAGE="hr" ;;
    "czech" | "czechia" | "cesky" ) LANGUAGE="cs" ;;
    "danish" | "denmark" | "dansk" ) LANGUAGE="da" ;;
    "dutch" | "nederlands" ) LANGUAGE="nl" ;;
    "english" | "gb" | "british" ) LANGUAGE="en" ;;
    "estonian" | "estonia" | "eesti" ) LANGUAGE="et" ;;
    "finnish" | "finland" | "suomi" ) LANGUAGE="fi" ;;
    "french" | "france" | "francais" ) LANGUAGE="fr" ;;
    "german" | "germany" | "deutsch" ) LANGUAGE="de" ;;
    "greek" | "greece" ) LANGUAGE="el" ;;
    "hebrew" | "israel" ) LANGUAGE="iw" ;;
    "hungarian" | "hungary" | "magyar" ) LANGUAGE="hu" ;;
    "italian" | "italy" | "italiano" ) LANGUAGE="it" ;;
    "japanese" | "japan" ) LANGUAGE="ja" ;;
    "korean" | "korea" ) LANGUAGE="ko" ;;
    "latvian" | "latvia" | "latvijas" ) LANGUAGE="lv" ;;
    "lithuanian" | "lithuania" | "lietuvos" ) LANGUAGE="lt" ;;
    "norwegian" | "norway" | "norsk" ) LANGUAGE="nb-no" ;;
    "polish" | "poland" | "polski" ) LANGUAGE="pl" ;;
    "portuguese" | "portugues" ) LANGUAGE="pt-br" ;;
    "portugal" ) LANGUAGE="pt-pt" ;;
    "romanian" | "romania" ) LANGUAGE="ro" ;;
    "russian" | "russia" ) LANGUAGE="ru" ;;
    "serbian" | "serbia" | "srpski" ) LANGUAGE="sr-latn-rs" ;;
    "slovak" | "slovakia" | "slovensky" ) LANGUAGE="sk" ;;
    "slovenian" | "slovenia" | "slovenija" ) LANGUAGE="sl" ;;
    "spanish" | "espanol" ) LANGUAGE="es" ;;
    "swedish" | "sweden" | "svenska" ) LANGUAGE="sv" ;;
    "thai" | "thailand" ) LANGUAGE="th" ;;
    "turkish" | "turkey" | "turkce" ) LANGUAGE="tr" ;;
    "ukrainian" | "ukraine" ) LANGUAGE="uk" ;;
  esac

  return 0
}

printVersion() {

  local id="$1"
  local desc="$2"

  case "${id,,}" in
    "reactos-0.4.15" )
      desc="ReactOS 0.4.15"
      ;;
    "reactos-0.4.14" )
      desc="ReactOS 0.4.14"
      ;;
    "reactos-0.4.13" )
      desc="ReactOS 0.4.13"
      ;;
    "reactos-0.4.15-live" )
      desc="ReactOS 0.4.15 Live CD"
      ;;
    "reactos-0.4.14-live" )
      desc="ReactOS 0.4.14 Live CD"
      ;;
    "reactos-nightly" )
      desc="ReactOS Nightly Build"
      ;;
    "reactos-nightly-live" )
      desc="ReactOS Nightly Live CD"
      ;;
    *)
      desc="ReactOS"
      ;;
  esac

  if [ -z "$desc" ]; then
    desc="ReactOS"
    if [[ "${id,,}" != "http"* ]]; then
      desc+=" (${id,})"
    fi
  fi

  echo "$desc"
  return 0
}

printEdition() {

  local id="$1"
  local desc="$2"

  # ReactOS doesn't have editions like Windows
  echo "$desc"
  return 0
}

fromFile() {

  local id=""
  local desc="$1"
  local file="${1,,}"
  file="${file%.*}"

  case "${file// /-}" in
    *"reactos-0.4.15"* ) id="reactos-0.4.15" ;;
    *"reactos-0.4.14"* ) id="reactos-0.4.14" ;;
    *"reactos-0.4.13"* ) id="reactos-0.4.13" ;;
    *"reactos"* ) id="reactos-0.4.15" ;;
  esac

  if [ -n "$id" ]; then
    desc=$(printVersion "$id" "$desc")
  fi

  echo "$desc"
  return 0
}

fromName() {

  local id=""
  local name="$1"
  local arch="x64"

  # ReactOS detection
  case "${name,,}" in
    *"reactos"* )
      id="reactos-0.4.15"
      ;;
  esac

  echo "$id"
  return 0
}

getVersion() {

  local name="$1"
  local arch="$2"

  case "${name,,}" in
    *"reactos"* )
      echo "reactos-0.4.15"
      ;;
    * )
      echo ""
      ;;
  esac

  return 0
}

switchEdition() {
  # No-op for ReactOS, kept for compatibility
  return 0
}

getMido() {
  # No-op for ReactOS, kept for compatibility
  return 0
}

getLink() {
  # No links needed, ReactOS downloads directly from SourceForge
  return 0
}

getHash() {
  # No hash verification needed for SourceForge downloads
  return 0
}

getSize() {
  # No size checking needed for SourceForge downloads
  return 0
}

isMido() {

  local id="$1"
  local lang="$2"

  # All ReactOS versions use direct SourceForge downloads
  case "${id,,}" in
    "reactos-"* )
      return 0
      ;;
  esac

  return 1
}

isESD() {
  # ReactOS doesn't use ESD files
  return 1
}

validVersion() {

  local id="$1"
  local lang="$2"

  case "${id,,}" in
    "reactos-0.4.15" | "reactos-0.4.14" | "reactos-0.4.13" | "reactos-0.4.15-live" | "reactos-0.4.14-live" | "reactos-nightly" | "reactos-nightly-live" )
      return 0
      ;;
  esac

  return 1
}

addFolder() {

  local src="$1"
  local folder="/mnt/oem"
  local msg="Adding OEM folder to image..."

  html "$msg"

  if [ ! -f "$STORAGE/$src" ] || [ ! -s "$STORAGE/$src" ]; then
    return 0
  fi

  rm -rf "$folder"
  mkdir -p "$folder"

  if ! tar -xf "/storage/$src" -C "$folder" --warning=no-timestamp; then
    rm -rf "$folder"
    error "Failed to extract OEM folder from $src file!" && return 1
  fi

  CUSTOM="$folder"
  return 0
}

prepareInstall() {

  local dir="$2"
  local desc="$3"
  local unattend=""

  if [[ "$MANUAL" == [Yy1]* ]]; then
    info "Proceeding with manual installation as requested..."
    return 0
  fi

  # ReactOS doesn't support automated installation in the same way Windows does
  info "ReactOS installation requires manual interaction..."
  return 0
}

prepareLegacy() {
  # ReactOS doesn't need legacy preparation
  return 1
}

detectLegacy() {
  # ReactOS is not a legacy OS in this context
  return 1
}

skipVersion() {

  local id="$1"

  # Don't skip any ReactOS versions
  return 1
}

isCompatible() {

  local desc="$1"
  local platform="$2"
  local tpm="$3"
  local secure="$4"

  # ReactOS is compatible with all configurations
  return 0
}

setMachine() {

  local id="$1"
  local iso="$2"
  local dir="$3"
  local desc="$4"
  local arch="x86_64"

  MACHINE="q35"

  case "${id,,}" in
    "reactos"* )
      BOOT_MODE="reactos"
      MACHINE="pc"
      ;;
  esac

  return 0
}

return 0
