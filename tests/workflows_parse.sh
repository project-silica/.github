#!/usr/bin/env bash
# Test for the hosted CI definitions (component A12), with actionlint: every
# workflow under .github/workflows/ is well formed (its YAML, its keys, its
# expressions, the jobs it needs, the shell of its steps where shellcheck is
# installed), and every action under actions/ is checked against the steps
# that use it: in a scratch copy, the workflows' own references to
# project-silica/.github/actions/<name>@main point at ./actions/<name>, so a
# broken action.yml, or an input its callers give that it does not take, is
# found here before every repository's CI runs it from main. An action no
# workflow uses is an error too (nothing would check it). The checker must
# also reject, by name, a planted unparsable workflow and a planted broken
# action. One "ERROR:" line per failure.
set -uo pipefail
ROOT=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd -P)
fails=0
bad() { echo "ERROR: workflows-parse: $1"; fails=$((fails + 1)); }
command -v actionlint >/dev/null || { bad "actionlint is not installed (https://github.com/rhysd/actionlint)"; exit 1; }
BASE=${SILICA_RUN:-${TMPDIR:-/tmp}}; mkdir -p "$BASE"
TMP=$(mktemp -d "$BASE/wfparse.XXXX") || { bad "no scratch directory"; exit 1; }
trap 'rm -rf "$TMP"' EXIT

# lint <dir>: actionlint over a copy at <dir>, the shared actions made local.
lint() {
  sed -i -E 's#project-silica/\.github/(actions/[A-Za-z0-9_-]+)@[A-Za-z0-9._/-]+#./\1#' "$1"/.github/workflows/*.yml
  (cd "$1" && actionlint -no-color)
}
# copy <dir>: the workflows, their configuration and the actions, as a repository.
copy() {
  mkdir -p "$1" && cp -r "$ROOT/.github" "$1/" && cp -r "$ROOT/actions" "$1/" && git -C "$1" init -q
}

ls "$ROOT"/.github/workflows/*.yml >/dev/null 2>&1 || bad "no workflows under .github/workflows"
copy "$TMP/real"
out=$(lint "$TMP/real") || bad "actionlint: $(head -n 1 <<<"$out")"
for a in "$ROOT"/actions/*/; do
  a=$(basename "$a")
  grep -qE "uses: \\./actions/$a\$" "$TMP"/real/.github/workflows/*.yml || bad "actions/$a is used by no workflow, so nothing checks it"
done

# Planted failures, each in a fresh copy, must be rejected naming the file.
copy "$TMP/workflow"
printf 'name: x\njobs:\n  a:\n    steps:\n      - run: echo a: b\n' >"$TMP/workflow/.github/workflows/planted-bad.yml"
out=$(lint "$TMP/workflow") && bad "a planted unparsable workflow was accepted"
grep -q 'planted-bad\.yml' <<<"$out" || bad "a planted unparsable workflow was not rejected by name: $(head -n 1 <<<"$out")"
copy "$TMP/action"
printf 'name: x\nruns:\n  using: composite\n  steps:\n    - run: echo a: b\n' >"$TMP/action/actions/setup/action.yml"
out=$(lint "$TMP/action") && bad "a planted broken action was accepted"
grep -q 'actions/setup' <<<"$out" || bad "a planted broken action was not rejected by name: $(head -n 1 <<<"$out")"

[ $fails = 0 ] && echo "WORKFLOWS-PARSE: OK"
[ $fails = 0 ]
