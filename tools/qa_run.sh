#!/bin/bash
# Local test run on the Mac (Shrikant, 2026-11-02): unit tests, then only the QA chapters the change needs.
#   tools/qa_run.sh            chapters picked by tools/qa_plan.py since the last passing run
#   tools/qa_run.sh all        every chapter (always before a merge to main)
#   tools/qa_run.sh 7,8        just those chapters
# When every picked chapter passes, the commit is written to .qa-last-pass (not committed), so the next run
# only covers what changed after it.
set -euo pipefail
cd "$(dirname "$0")/.."

mark=yes   # a hand-picked list may skip chapters the change needs, so it never moves the marker
case "${1:-}" in
  all) chapters="1,2,3,4,5,6,7,8,9,10" ;;
  "")  chapters=$(python3 tools/qa_plan.py) ;;
  *)   chapters="$1"; mark=no ;;
esac
echo "QA chapters: $chapters"

swift test
# Every on-screen instruction on a child screen must also be spoken (rule 5 escape, 2026-11-02).
python3 tools/screen_text_audit.py
[ "$chapters" = "none" ] && { [ $mark = yes ] && git rev-parse HEAD > .qa-last-pass; echo "Docs or unit tests only: no play-through needed."; exit 0; }

(cd App && xcodegen generate)
dest="platform=iOS Simulator,name=${QA_SIMULATOR:-iPad (A16)}"
# Every chapter keeps its log and result bundle (screenshots, failure messages) in qa-results/ (gitignored), so a
# failure is never a guess. Open a bundle in Xcode, or: xcrun xcresulttool get test-results tests --path <bundle>
out="qa-results/$(git rev-parse --short HEAD)"
mkdir -p "$out"
failed=()
for ch in ${chapters//,/ }; do
  start=$(date +%s)
  bundle="$out/chapter$ch.xcresult"
  rm -rf "$bundle"
  if xcodebuild test -project App/KingdomOfNumbers.xcodeproj -scheme KingdomOfNumbers -destination "$dest" \
       -only-testing:"KingdomOfNumbersQA/Chapter${ch}PlaythroughTests" CODE_SIGNING_ALLOWED=NO \
       -resultBundlePath "$bundle" > "$out/chapter$ch.log" 2>&1 \
     && grep -qE "Executed [1-9][0-9]* tests?" "$out/chapter$ch.log"; then
    # A clean exit that ran no tests (seen once right after a rebuild) is not a pass.
    echo "Chapter $ch passed in $(( $(date +%s) - start ))s ($(grep -oE "Executed [0-9]+ tests?, with [0-9]+ failures?" "$out/chapter$ch.log" | tail -1))"
  else
    echo "Chapter $ch FAILED after $(( $(date +%s) - start ))s (log: $out/chapter$ch.log, results: $bundle)"
    grep -E "error:|failed|FAILED waiting|Executed 0 tests" "$out/chapter$ch.log" | head -20 || true
    failed+=("$ch")
  fi
  grep -h "QA-METRIC" "$out/chapter$ch.log" || true
done

if [ ${#failed[@]} -eq 0 ]; then
  [ $mark = yes ] && git rev-parse HEAD > .qa-last-pass
  echo "All picked chapters passed."
else
  echo "Failed chapters: ${failed[*]}"
  exit 1
fi
