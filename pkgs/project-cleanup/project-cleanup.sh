set -Eeuo pipefail
shopt -s nullglob

# One directory per project: `project` holds the delay and the path, `state`
# the last time a process was inside it and pending | cleaned | failed.
root="${XDG_STATE_HOME:-$HOME/.local/state}/project-cleanup"
cleanup_timeout=15m
# A missing project may sit on a disk that isn't mounted, so it is only
# unregistered after being gone this long.
missing_ttl=$((30 * 86400))

declare -A paths=() delays=() lasts=() statuses=() by_path=() active=()

usage() {
  cat >&2 <<'USAGE'
usage:
  project-cleanup status         list projects, their last activity and cleanup state
  project-cleanup now [DIR]      run the cleanup of the project containing DIR (default .)
  project-cleanup forget [DIR]   unregister the project containing DIR (default .)
  project-cleanup docker-stop    stop Compose containers whose working_dir is inside .
  project-cleanup scan           record activity and run due cleanups (the timer runs this)

A project opts in from its .envrc:
  cleanup_on_idle 1h 'project-cleanup docker-stop; cargo clean'
The command runs once no process has had its working directory inside the
project for the delay.
USAGE
}

die() {
  printf 'project-cleanup: %s\n' "$*" >&2
  exit 1
}

# Sets REPLY to the seconds in a delay such as 30m, 2h, 1d or 1h30m.
parse_delay() {
  local rest=$1 n
  REPLY=0
  [[ $rest =~ ^([0-9]+[smhd])+$ ]] || return 1
  while [[ $rest =~ ^([0-9]+)([smhd])(.*)$ ]]; do
    n=$((10#${BASH_REMATCH[1]}))
    case ${BASH_REMATCH[2]} in
      m) n=$((n * 60)) ;;
      h) n=$((n * 3600)) ;;
      d) n=$((n * 86400)) ;;
    esac
    REPLY=$((REPLY + n))
    rest=${BASH_REMATCH[3]}
  done
}

# Sets REPLY to a short duration: 45s, 40m, 3h12m, 2d5h.
format_duration() {
  local s=$(($1 < 0 ? 0 : $1))
  if ((s < 60)); then
    REPLY="${s}s"
  elif ((s < 3600)); then
    REPLY="$((s / 60))m"
  elif ((s < 86400)); then
    REPLY="$((s / 3600))h"
    ((s % 3600 < 60)) || REPLY+="$((s % 3600 / 60))m"
  else
    REPLY="$((s / 86400))d"
    ((s % 86400 < 3600)) || REPLY+="$((s % 86400 / 3600))h"
  fi
}

read_state() {
  local last='' status=''
  if [ -f "$root/$1/state" ]; then
    read -r last status <"$root/$1/state" || true
  fi
  # A damaged state file counts as activity now: that delays a cleanup
  # instead of running one early.
  [[ $last =~ ^[0-9]+$ ]] || last=$EPOCHSECONDS
  case $status in pending | cleaned | failed) ;; *) status=pending ;; esac
  lasts[$1]=$last
  statuses[$1]=$status
}

write_state() {
  printf '%s %s\n' "$2" "$3" >"$root/$1/state"
  lasts[$1]=$2
  statuses[$1]=$3
}

load_projects() {
  local dir key delay path
  for dir in "$root"/*/; do
    key=${dir%/}
    key=${key##*/}
    delay='' path=''
    if [ -f "$dir/project" ]; then
      { read -r delay && read -r path; } <"$dir/project" || true
    fi
    [ -n "$path" ] || continue
    paths[$key]=$path
    delays[$key]=$delay
    by_path[$path]=$key
    read_state "$key"
  done
}

# Fills `active` with the projects that contain the working directory of a
# running process. Other users' processes are unreadable and print nothing.
scan_processes() {
  local cwd dir
  local -A seen=()
  active=()
  while IFS= read -r -d '' cwd; do
    [ -n "$cwd" ] && [ -z "${seen[$cwd]-}" ] || continue
    seen[$cwd]=1
    dir=$cwd
    while [ -n "$dir" ]; do
      [ -z "${by_path[$dir]-}" ] || active[${by_path[$dir]}]=1
      dir=${dir%/*}
    done
  done < <(find /proc/[0-9]*/cwd -maxdepth 0 -printf '%l\0' 2>/dev/null)
}

lock() {
  mkdir -p -- "$root"
  exec {lock_fd}>"$root/lock"
  flock "$@" "$lock_fd"
}

notify() {
  notify-send --app-name=project-cleanup "$@" 2>/dev/null || true
}

# Runs the cleanup command of project $1. $2 is `auto` (from scan: report by
# notification) or `manual` (from `now`: report on the terminal).
clean() {
  local key=$1 mode=$2 path=${paths[$1]} rc=0 reason=''
  printf 'project-cleanup: cleaning %s\n' "$path"
  # direnv exec refuses an .envrc that isn't allowed, so only approved
  # commands run. PROJECT_CLEANUP_RUNNING keeps this load from counting as
  # activity; the lock fd is closed so a daemonizing command can't hold it.
  # shellcheck disable=SC2016
  (
    exec {lock_fd}>&-
    cd -- "$path"
    exec env -u PROJECT_CLEANUP PROJECT_CLEANUP_RUNNING=1 DIRENV_LOG_FORMAT='' \
      timeout --kill-after=30s "$cleanup_timeout" \
      direnv exec . bash -c '[ -n "${PROJECT_CLEANUP-}" ] || exit 64; eval "$PROJECT_CLEANUP"'
  ) || rc=$?

  case $rc in
    0) write_state "$key" "${lasts[$key]}" cleaned ;;
    64)
      rm -rf -- "${root:?}/$key"
      printf 'project-cleanup: %s no longer calls cleanup_on_idle; unregistered it\n' "$path"
      return 0
      ;;
    124) reason="timed out after $cleanup_timeout" ;;
    *) reason="exit code $rc" ;;
  esac

  if [ -n "$reason" ]; then
    write_state "$key" "${lasts[$key]}" failed
    [ "$mode" = auto ] || die "cleanup of $path failed: $reason"
    printf 'project-cleanup: cleanup of %s failed: %s\n' "$path" "$reason" >&2
    notify --urgency=critical "Cleanup of ${path##*/} failed" "$reason. See journalctl --user -u project-cleanup"
  elif [ "$mode" = auto ]; then
    notify "Cleaned up ${path##*/}" "$path"
  fi
}

# Sets REPLY to the innermost registered project containing directory $1.
find_project() {
  local dir
  cd -P -- "$1" 2>/dev/null || die "no such directory: $1"
  dir=$PWD
  load_projects
  while [ -n "$dir" ]; do
    if [ -n "${by_path[$dir]-}" ]; then
      REPLY=${by_path[$dir]}
      return 0
    fi
    dir=${dir%/*}
  done
  die "no registered project contains $1"
}

cmd_scan() {
  [ -d "$root" ] || return 0
  lock -n || return 0 # a scan or a manual cleanup is running
  load_projects
  [ "${#paths[@]}" -gt 0 ] || return 0
  scan_processes

  local key now=$EPOCHSECONDS ran=0
  local -a due=()
  for key in "${!paths[@]}"; do
    if [ -n "${active[$key]-}" ]; then
      write_state "$key" "$now" pending
    elif [ ! -d "${paths[$key]}" ]; then
      if ((now - ${lasts[$key]} > missing_ttl)); then
        rm -rf -- "${root:?}/$key"
      fi
    elif [ "${statuses[$key]}" = pending ] && parse_delay "${delays[$key]}" && ((now - ${lasts[$key]} >= REPLY)); then
      due+=("$key")
    fi
  done

  for key in "${due[@]}"; do
    # Cleanups take time and direnv loads don't take the lock: check again.
    if ((ran)); then
      scan_processes
      now=$EPOCHSECONDS
    fi
    read_state "$key"
    if [ -n "${active[$key]-}" ]; then
      write_state "$key" "$now" pending
    elif [ "${statuses[$key]}" = pending ] && parse_delay "${delays[$key]}" && ((now - ${lasts[$key]} >= REPLY)); then
      clean "$key" auto
      ran=1
    fi
  done
}

cmd_status() {
  [ -d "$root" ] && load_projects
  if [ "${#paths[@]}" -eq 0 ]; then
    printf 'No registered projects. Add "cleanup_on_idle <delay> <command>" to an .envrc.\n'
    return 0
  fi
  scan_processes

  local path key state seen now=$EPOCHSECONDS
  printf '%-12s  %-6s  %-9s  %s\n' STATE DELAY 'LAST SEEN' PROJECT
  while IFS= read -r -d '' path; do
    key=${by_path[$path]}
    if [ -n "${active[$key]-}" ]; then
      state='in use' seen=now
    else
      format_duration $((now - ${lasts[$key]}))
      seen="$REPLY ago"
      if [ ! -d "$path" ]; then
        state=missing
      elif [ "${statuses[$key]}" != pending ]; then
        state=${statuses[$key]}
      elif parse_delay "${delays[$key]}" && ((${lasts[$key]} + REPLY > now)); then
        format_duration $((${lasts[$key]} + REPLY - now))
        state="due in $REPLY"
      else
        state=due
      fi
    fi
    printf '%-12s  %-6s  %-9s  %s\n' "$state" "${delays[$key]}" "$seen" "$path"
  done < <(printf '%s\0' "${!by_path[@]}" | sort -z)
}

cmd_now() {
  [ "$#" -le 1 ] || die "usage: project-cleanup now [DIR]"
  find_project "${1:-.}"
  local key=$REPLY
  if ! lock -n; then
    printf 'project-cleanup: waiting for a running cleanup\n' >&2
    lock
  fi
  clean "$key" manual
}

cmd_forget() {
  [ "$#" -le 1 ] || die "usage: project-cleanup forget [DIR]"
  find_project "${1:-.}"
  rm -rf -- "${root:?}/$REPLY"
  printf 'project-cleanup: forgot %s (its .envrc registers it again if it still calls cleanup_on_idle)\n' "${paths[$REPLY]}"
}

# Called by cleanup_on_idle (direnvrc) on every load of the .envrc.
cmd_register() {
  [ "$#" -eq 2 ] || die "usage: project-cleanup register DIR DELAY"
  # The cleanup itself loads the .envrc; that isn't activity.
  [ -z "${PROJECT_CLEANUP_RUNNING-}" ] || return 0
  parse_delay "$2" || die "invalid delay '$2', expected e.g. 30m, 2h, 1d or 1h30m"
  cd -P -- "$1" 2>/dev/null || die "no such directory: $1"
  local path=$PWD key delay='' old=''
  [[ $path != *$'\n'* ]] || die "paths containing newlines are not supported"
  key=$(sha256sum <<<"$path")
  key=${key:0:16}

  if [ -f "$root/$key/project" ]; then
    { read -r delay && read -r old; } <"$root/$key/project" || true
  fi
  if [ "$delay" != "$2" ] || [ "$old" != "$path" ]; then
    mkdir -p -- "$root/$key"
    printf '%s\n%s\n' "$2" "$path" >"$root/$key/project.tmp"
    mv -f -- "$root/$key/project.tmp" "$root/$key/project"
  fi
  write_state "$key" "$EPOCHSECONDS" pending
}

cmd_docker_stop() {
  [ "$#" -eq 0 ] || die "usage: project-cleanup docker-stop"
  local logical=$PWD physical id dir out
  local -a ids=()
  physical=$(pwd -P)
  # Docker is socket-activated: asking an idle daemon would start it only to
  # find nothing running.
  systemctl is-active --quiet docker.service || return 0
  out=$(docker ps --format '{{.ID}}\t{{.Label "com.docker.compose.project.working_dir"}}')
  while IFS=$'\t' read -r id dir; do
    case $dir in
      "$logical" | "$logical"/* | "$physical" | "$physical"/*) ids+=("$id") ;;
    esac
  done <<<"$out"
  [ "${#ids[@]}" -gt 0 ] || return 0
  docker stop "${ids[@]}" >/dev/null
  printf 'project-cleanup: stopped %d container(s)\n' "${#ids[@]}"
}

command="${1:-}"
[ "$#" -eq 0 ] || shift
case "$command" in
  scan) cmd_scan "$@" ;;
  status) cmd_status "$@" ;;
  now) cmd_now "$@" ;;
  forget) cmd_forget "$@" ;;
  docker-stop) cmd_docker_stop "$@" ;;
  register) cmd_register "$@" ;;
  help | --help | -h) usage ;;
  *)
    usage
    exit 2
    ;;
esac
