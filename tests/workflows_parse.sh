#!/usr/bin/env bash
# Test for feature A12.03: every file under .github/workflows/ and actions/
# parses as YAML (python3 yaml.safe_load) to a mapping. Also proves the checker
# fails, naming the file, on a planted unparsable copy (made and cleaned up by
# Python's tempfile). One "ERROR:" line per failure.
set -uo pipefail
ROOT=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd -P)
python3 -I - "$ROOT" <<'PY'
import os, sys, shutil, tempfile
try:
    import yaml
except ImportError:
    print("ERROR: workflows-parse: python3 yaml module not available")
    sys.exit(1)

def check(root):
    """Return (list of error lines, number of files seen)."""
    files = []
    for sub in (".github/workflows", "actions"):
        for d, _, names in os.walk(os.path.join(root, sub)):
            for n in names:
                if n.endswith((".yml", ".yaml")):
                    files.append(os.path.join(d, n))
    files.sort()
    errs = []
    for f in files:
        rel = os.path.relpath(f, root)
        try:
            with open(f, encoding="utf-8") as fh:
                doc = yaml.safe_load(fh)
        except Exception as e:
            errs.append(f"ERROR: workflows-parse: {rel}: {str(e)!s}".replace("\n", " "))
            continue
        if not isinstance(doc, dict):
            errs.append(f"ERROR: workflows-parse: {rel}: not a mapping")
    return errs, len(files)

root = sys.argv[1]
fails = 0
errs, n = check(root)
if n == 0:
    print("ERROR: workflows-parse: no YAML files found under .github/workflows or actions")
    fails += 1
for e in errs:
    print(e)
    fails += 1

# Planted failures: a copy of the real files plus one bad file must be rejected by name.
plants = {
    "planted-bad.yml": "name: x\njobs:\n  a:\n    steps:\n      - run: echo a: b\n",
    "planted-list.yml": "- a\n- b\n",
}
for name, text in plants.items():
    with tempfile.TemporaryDirectory(prefix="wfparse.") as tmp:
        shutil.copytree(os.path.join(root, ".github"), os.path.join(tmp, ".github"))
        if os.path.isdir(os.path.join(root, "actions")):
            shutil.copytree(os.path.join(root, "actions"), os.path.join(tmp, "actions"))
        with open(os.path.join(tmp, ".github", "workflows", name), "w") as fh:
            fh.write(text)
        perrs, _ = check(tmp)
        named = [e for e in perrs if name in e]
        if not named:
            print(f"ERROR: workflows-parse: planted {name} was not rejected by name")
            fails += 1
if fails == 0:
    print("WORKFLOWS-PARSE: OK")
sys.exit(1 if fails else 0)
PY
