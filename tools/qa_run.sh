#!/bin/bash
# Local test run on the Mac (Shrikant, 2026-11-02): unit tests, then only the QA suites the change needs.
#   tools/qa_run.sh                 suites picked by tools/qa_plan.py since the last passing run. A shared-code
#                                   change runs the quick set (Kingdom1, KingdomSmoke, write it down) plus the
#                                   widgets changed, about 20 minutes (Shrikant, 2026-11-03)
#   tools/qa_run.sh all             every suite in full (always before a merge to main)
#   tools/qa_run.sh Kingdom7,Cups   just those suites; Suite/testName runs one test
# Suites are App/QATests/<name>QATests.swift; tools/qa_plan.py lists what each covers.
# When every picked suite passes, the commit is written to .qa-last-pass (not committed), so the next run
# only covers what changed after it.
set -euo pipefail
cd "$(dirname "$0")/.."

mark=yes   # a hand-picked list may skip suites the change needs, so it never moves the marker
case "${1:-}" in
  all) chapters="Kingdom1,Kingdom2,Kingdom3,Kingdom4,Kingdom5,Kingdom6,Kingdom7,HubJigsaw,Cups,Memory" ;;
  "")  chapters=$(python3 tools/qa_plan.py) ;;
  *)   chapters="$1"; mark=no ;;
esac
echo "QA suites: $chapters"

swift test
# Every on-screen instruction on a child screen must also be spoken (rule 5 escape, 2026-11-02).
python3 tools/screen_text_audit.py
[ "$chapters" = "none" ] && { [ $mark = yes ] && git rev-parse HEAD > .qa-last-pass; echo "Docs or unit tests only: no play-through needed."; exit 0; }

(cd App && xcodegen generate)
dest="platform=iOS Simulator,name=${QA_SIMULATOR:-iPad (A16)}"
# Every suite keeps its log and result bundle (screenshots, failure messages) in qa-results/ (gitignored), so a
# failure is never a guess. Open a bundle in Xcode, or: xcrun xcresulttool get test-results tests --path <bundle>
out="qa-results/$(git rev-parse --short HEAD)"
mkdir -p "$out"
failed=()
# Every test in the suite must have run: under load, xcodebuild once ran 5 of 6 and exited cleanly (2026-11-03).
all_ran() {  # $1 suite or Suite/test, $2 log
  local want got
  if [[ "$1" == */* ]]; then want=1
  else want=$(grep -cE "^[[:space:]]*func test" "App/QATests/${1}QATests.swift"); fi
  got=$(grep -oE "Executed [0-9]+ tests?" "$2" | tail -1 | grep -oE "[0-9]+")
  if [ "${got:-0}" -lt "$want" ]; then
    echo "$1 ran ${got:-0} of $want tests" >> "$2"
    return 1
  fi
}
for suite in ${chapters//,/ }; do
  start=$(date +%s)
  [ -f "App/QATests/${suite%%/*}QATests.swift" ] || { echo "No suite ${suite%%/*} (App/QATests/${suite%%/*}QATests.swift)"; exit 2; }
  target="KingdomOfNumbersQA/${suite%%/*}QATests"
  [[ "$suite" == */* ]] && target="$target/${suite#*/}"
  name="${suite//\//-}"
  bundle="$out/$name.xcresult"
  log="$out/$name.log"
  rm -rf "$bundle"
  if xcodebuild test -project App/KingdomOfNumbers.xcodeproj -scheme KingdomOfNumbers -destination "$dest" \
       -only-testing:"$target" CODE_SIGNING_ALLOWED=NO \
       -resultBundlePath "$bundle" > "$log" 2>&1 \
     && grep -qE "Executed [1-9][0-9]* tests?" "$log" \
     && all_ran "$suite" "$log"; then
    # A clean exit that ran no tests (seen once right after a rebuild) is not a pass.
    echo "$suite passed in $(( $(date +%s) - start ))s ($(grep -oE "Executed [0-9]+ tests?, with [0-9]+ failures?" "$log" | tail -1))"
  else
    echo "$suite FAILED after $(( $(date +%s) - start ))s (log: $log, results: $bundle)"
    grep -E "error:|failed|FAILED waiting|Executed 0 tests|ran [0-9]+ of [0-9]+ tests" "$log" | head -20 || true
    failed+=("$suite")
  fi
  grep -h "QA-METRIC" "$log" || true
done

if [ ${#failed[@]} -eq 0 ]; then
  [ $mark = yes ] && git rev-parse HEAD > .qa-last-pass
  echo "All picked suites passed."
else
  echo "Failed suites: ${failed[*]}"
  exit 1
fi
