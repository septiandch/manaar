#!/usr/bin/env bash
set -Eeuo pipefail
source /etc/manaar.conf
exec 9>/opt/manaar/update.lock
flock -n 9 || exit 0
export PATH=/usr/local/bin:/usr/bin:/bin
export GIT_TERMINAL_PROMPT=0
root=/opt/manaar
run() { runuser -u manaar -- "$@"; }
if [[ ! -d $root/repo.git ]]; then
  run git clone --bare "$REPOSITORY" "$root/repo.git"
fi
run git --git-dir="$root/repo.git" fetch --prune origin '+refs/heads/*:refs/heads/*'
branch=${BRANCH:-$(run git --git-dir="$root/repo.git" symbolic-ref --short HEAD)}
commit=$(run git --git-dir="$root/repo.git" rev-parse "refs/heads/$branch^{commit}")
old=
if [[ -L $root/current ]]; then old=$(readlink -f "$root/current"); fi
if [[ -n $old && -f $old/.release-commit && $(cat "$old/.release-commit") == "$commit" ]]; then
  echo "Already running $commit"
  exit 0
fi
release=$(run mktemp -d "$root/releases/${commit:0:12}.XXXXXX")
candidate_pid=
activated=0
cleanup() {
  status=$?
  trap - EXIT
  if [[ -n $candidate_pid ]]; then
    kill "$candidate_pid" 2>/dev/null || true
    wait "$candidate_pid" 2>/dev/null || true
  fi
  if (( status != 0 && activated )); then
    if [[ -n $old ]]; then
      ln -sfn "$old" "$root/current.next"
      mv -Tf "$root/current.next" "$root/current"
      systemctl restart manaar.service || true
    else
      systemctl stop manaar.service || true
      rm -f "$root/current"
    fi
  fi
  if (( status != 0 )); then echo "Update failed; previous release retained. Candidate: $release" >&2; fi
  exit "$status"
}
trap cleanup EXIT
run git --git-dir="$root/repo.git" archive "$commit" | run tar -x -C "$release"
cd "$release"
run pnpm install --frozen-lockfile
run pnpm build
test -f build/index.js
printf '%s\n' "$commit" > .release-commit
# Smoke-test with isolated storage, never against the live writable data.
run node --input-type=module -e 'import net from "node:net"; const s=net.createServer(); s.on("error",()=>process.exit(1)); s.listen(3001,"127.0.0.1",()=>s.close());'
run env HOST=127.0.0.1 PORT=3001 ORIGIN=http://localhost:5000 node build/index.js &
candidate_pid=$!
healthy() {
  local port=$1
  for ((i=0; i<60; i++)); do
    if curl --fail --silent --max-time 2 "http://127.0.0.1:$port/" >/dev/null; then return 0; fi
    sleep 1
  done
  return 1
}
healthy 3001
kill -0 "$candidate_pid"
kill "$candidate_pid"
wait "$candidate_pid" || true
candidate_pid=
# Keep runtime files outside all release directories.
for path in data static/uploads; do
  if [[ -e $path || -L $path ]]; then mv "$path" "${path}.release-default"; fi
  mkdir -p "$(dirname "$path")"
  ln -s "$root/shared/$path" "$path"
done
ln -sfn "$release" "$root/current.next"
activated=1
mv -Tf "$root/current.next" "$root/current"
systemctl restart manaar.service
healthy 3000
systemctl is-active --quiet manaar.service
# The kiosk watches this marker and reloads only after a successful activation.
printf '%s\n' "$commit" > "$root/shared/version"
echo "Activated $commit"
