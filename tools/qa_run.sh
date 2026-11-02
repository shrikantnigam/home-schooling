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
  all) chapters="1,2,3,4,5,6,7,8" ;;
  "")  chapters=$(python3 tools/qa_plan.py) ;;
  *)   chapters="$1"; mark=no ;;
esac
echo "QA chapters: $chapters"

swift test
[ "$chapters" = "none" ] && { [ $mark = yes ] && git rev-parse HEAD > .qa-last-pass; echo "Docs or unit tests only: no play-through needed."; exit 0; }

(cd App && xcodegen generate)
dest="platform=iOS Simulator,name=${QA_SIMULATOR:-iPad (A16)}"
failed=()
for ch in ${chapters//,/ }; do
  start=$(date +%s)
  if xcodebuild test -project App/KingdomOfNumbers.xcodeproj -scheme KingdomOfNumbers -destination "$dest" \
       -only-testing:"KingdomOfNumbersQA/Chapter${ch}PlaythroughTests" CODE_SIGNING_ALLOWED=NO -quiet; then
    echo "Chapter $ch passed in $(( $(date +%s) - start ))s"
  else
    echo "Chapter $ch FAILED after $(( $(date +%s) - start ))s"
    failed+=("$ch")
  fi
done

if [ ${#failed[@]} -eq 0 ]; then
  [ $mark = yes ] && git rev-parse HEAD > .qa-last-pass
  echo "All picked chapters passed."
else
  echo "Failed chapters: ${failed[*]}"
  exit 1
fi
