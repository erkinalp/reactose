#!/usr/bin/env bash
set -Eeuo pipefail

handle_curl_error() {

  local error_code="$1"
  local server_name="$2"

  case "$error_code" in
    1) error "Unsupported protocol!" ;;
    2) error "Failed to initialize curl!" ;;
    3) error "The URL format is malformed!" ;;
    5) error "Failed to resolve address of proxy host!" ;;
    6) error "Failed to resolve $server_name servers! Is there an Internet connection?" ;;
    7) error "Failed to contact $server_name servers! Is there an Internet connection or is the server down?" ;;
    8) error "$server_name servers returned a malformed HTTP response!" ;;
    16) error "A problem was detected in the HTTP2 framing layer!" ;;
    22) error "$server_name servers returned a failing HTTP status code!" ;;
    23) error "Failed at writing ReactOS media to disk! Out of disk space or permission error?" ;;
    26) error "Failed to read ReactOS media from disk!" ;;
    27) error "Ran out of memory during download!" ;;
    28) error "Connection timed out to $server_name server!" ;;
    35) error "SSL connection error from $server_name server!" ;;
    36) error "Failed to continue earlier download!" ;;
    52) error "Received no data from the $server_name server!" ;;
    63) error "$server_name servers returned an unexpectedly large response!" ;;
    $((error_code <= 125)))
      error "Miscellaneous server or network error, reason: $error_code"
      ;;
    126 | 127 ) error "Curl command not found!" ;;
    *)
      case "$(kill -l "$error_code")" in
        INT) error "Curl was interrupted!" ;;
        SEGV | ABRT ) error "Curl crashed! Please report any core dumps to curl developers." ;;
        *) error "Curl terminated due to fatal signal $error_code !" ;;
      esac
  esac

  return 1
}

get_agent() {

  local user_agent

  # Determine approximate latest Firefox release
  browser_version="$((124 + ($(date +%s) - 1710892800) / 2419200))"
  echo "Mozilla/5.0 (X11; Linux x86_64; rv:${browser_version}.0) Gecko/20100101 Firefox/${browser_version}.0"

  return 0
}

download_reactos() {

  local id="$1"
  local desc="$2"
  local iso_url=""
  local base_url="https://sourceforge.net/projects/reactos/files/ReactOS"

  case "${id,,}" in
    "reactos-0.4.15" )
      iso_url="${base_url}/0.4.15/ReactOS-0.4.15-release-29-g67c2f3f-iso.zip/download"
      ;;
    "reactos-0.4.14" )
      iso_url="${base_url}/0.4.14/ReactOS-0.4.14-release-16-gc6bf6c7-iso.zip/download"
      ;;
    "reactos-0.4.13" )
      iso_url="${base_url}/0.4.13/ReactOS-0.4.13-release-40-g67b426e-iso.zip/download"
      ;;
    "reactos-0.4.15-live" )
      iso_url="${base_url}/0.4.15/ReactOS-0.4.15-release-29-g67c2f3f-live.zip/download"
      ;;
    "reactos-0.4.14-live" )
      iso_url="${base_url}/0.4.14/ReactOS-0.4.14-release-16-gc6bf6c7-live.zip/download"
      ;;
    * ) error "Invalid VERSION specified, value \"$id\" is not recognized!" && return 1 ;;
  esac

  MIDO_URL="$iso_url"
  return 0
}

isCompressed() {

  local url="$1"

  [[ "${url,,}" == *".zip" ]] && return 0
  [[ "${url,,}" == *".7z" ]] && return 0
  [[ "${url,,}" == *".rar" ]] && return 0
  [[ "${url,,}" == *".cab" ]] && return 0

  return 1
}

verifyFile() {

  local iso="$1"
  local size="$2"
  local total="$3"
  local check="$4"
  local hash=""
  local algorithm

  [ -z "$check" ] && return 0
  [ -z "$total" ] && return 0
  [[ "$total" == "0" ]] && return 0

  if [ -n "$size" ] && [[ "$size" != "0" ]] && [[ "$size" != "$total" ]]; then
    error "The downloaded file has an invalid size: $total bytes, while expected value was: $size bytes. Please report this at $SUPPORT/issues" && return 1
  fi

  local msg="Verifying downloaded ISO..."
  info "$msg" && html "$msg"

  if [[ "${#check}" == "40" ]]; then
    algorithm="SHA1"
  elif [[ "${#check}" == "64" ]]; then
    algorithm="SHA256"
  else
    error "Unknown checksum algorithm: ${#check} characters" && return 1
  fi

  if [[ "$algorithm" == "SHA256" ]]; then
    hash=$(sha256sum "$iso" | cut -f1 -d' ')
  else
    hash=$(sha1sum "$iso" | cut -f1 -d' ')
  fi

  if [[ "$hash" == "$check" ]]; then
    info "Succesfully verified ISO!" && return 0
  fi

  error "The downloaded file has an invalid $algorithm checksum: $hash , while expected value was: $check. Please report this at $SUPPORT/issues" && return 1
}

downloadFile() {

  local iso="$1"
  local url="$2"
  local sum="$3"
  local size="$4"
  local lang="$5"
  local desc="$6"
  local msg="Downloading $desc"
  local rc total total_gb progress domain dots agent space folder

  agent=$(get_agent)

  if [ -n "$size" ] && [[ "$size" != "0" ]]; then
    folder=$(dirname -- "$iso")
    space=$(df --output=avail -B 1 "$folder" | tail -n 1)
    total_gb=$(formatBytes "$space")
    (( size > space )) && error "Not enough free space to download file, only $total_gb left!" && return 1
  fi

  # Check if running with interactive TTY or redirected to docker log
  if [ -t 1 ]; then
    progress="--progress=bar:noscroll"
  else
    progress="--progress=dot:giga"
  fi

  html "$msg..."
  /run/progress.sh "$iso" "$size" "$msg ([P])..." &

  domain=$(echo "$url" | awk -F/ '{print $3}')
  dots=$(echo "$domain" | tr -cd '.' | wc -c)
  (( dots > 1 )) && domain=$(expr "$domain" : '.*\.\(.*\..*\)')

  if [ -n "$domain" ] && [[ "${domain,,}" != *"sourceforge.net" ]]; then
    msg="Downloading $desc from $domain"
  fi

  info "$msg..."
  [[ "$DEBUG" == [Yy1]* ]] && echo "Downloading: $url"

  { wget "$url" -O "$iso" --continue -q --timeout=30 --no-http-keep-alive --user-agent "$agent" --show-progress "$progress"; rc=$?; } || :

  fKill "progress.sh"

  if (( rc == 0 )) && [ -f "$iso" ]; then
    total=$(stat -c%s "$iso")
    total_gb=$(formatBytes "$total")
    if [ "$total" -lt 10000000 ]; then
      error "Invalid download link: $url (is only $total_gb ?). Please report this at $SUPPORT/issues" && return 1
    fi
    verifyFile "$iso" "$size" "$total" "$sum" || return 1
    isCompressed "$url" && UNPACK="Y"
    html "Download finished successfully..." && return 0
  fi

  msg="Failed to download $url"
  (( rc == 3 )) && error "$msg , cannot write file (disk full?)" && return 1
  (( rc == 4 )) && error "$msg , network failure!" && return 1
  (( rc == 8 )) && error "$msg , server issued an error response! Please report this at $SUPPORT/issues" && return 1

  error "$msg , reason: $rc"
  return 1
}

delay() {

  local i
  local delay="$1"
  local msg="Will retry in X seconds..."

  info "${msg/X/$delay}"

  for i in $(seq "$delay" -1 1); do
    html "${msg/X/$i}"
    sleep 1
  done

  return 0
}

downloadImage() {

  local iso="$1"
  local version="$2"
  local lang="$3"
  local tried="n"
  local success="n"
  local seconds="5"
  local url sum size base desc language

  if [[ "${version,,}" == "http"* ]]; then

    base=$(basename "$iso")
    desc=$(fromFile "$base")

    rm -f "$iso"
    downloadFile "$iso" "$version" "" "" "" "$desc" && return 0
    delay "$seconds"
    downloadFile "$iso" "$version" "" "" "" "$desc" && return 0
    rm -f "$iso"

    return 1
  fi

  # Check if this is a ReactOS version
  case "${version,,}" in
    "reactos-"* )
      desc=$(printVersion "$version" "")
      local msg="Requesting $desc from SourceForge..."
      info "$msg" && html "$msg"
      
      if download_reactos "$version" "$desc"; then
        success="y"
      else
        delay "$seconds"
        download_reactos "$version" "$desc" && success="y"
      fi

      if [[ "$success" == "y" ]]; then
        rm -f "$iso"
        downloadFile "$iso" "$MIDO_URL" "" "" "$lang" "$desc" && return 0
        delay "$seconds"
        downloadFile "$iso" "$MIDO_URL" "" "" "$lang" "$desc" && return 0
        rm -f "$iso"
      fi
      ;;
    * )
      error "Invalid VERSION specified, value \"$version\" is not recognized!" && return 1
      ;;
  esac

  return 1
}

return 0
