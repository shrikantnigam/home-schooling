"""Prints each QA screenshot as a small base64 JPEG between markers in the job log.

The cloud agent that reviews QA runs can read job logs but not artifact downloads,
so this is how screenshots reach the review. Artifacts are still uploaded for people.
"""
import base64, json, os, re, subprocess, sys, tempfile

root = sys.argv[1]
manifest = os.path.join(root, "manifest.json")
if not os.path.exists(manifest):
    print("no manifest"); sys.exit(0)
entries = json.load(open(manifest))
print("manifest sample:", json.dumps(entries[:1])[:600])
tmp = tempfile.mkdtemp()
count = 0
for test in entries:
    tname = test.get("testIdentifier", "?")
    for a in test.get("attachments", []):
        name = a.get("suggestedHumanReadableName", "")
        fn = a.get("exportedFileName", "")
        path = os.path.join(root, fn)
        if not re.match(r"^(c\d-)?\d\d-\d\d ", name) or not os.path.exists(path):
            continue
        out = os.path.join(tmp, f"{count}.jpg")
        subprocess.run(["sips", "-s", "format", "jpeg", "-s", "formatOptions", "55", "-Z", "700", path, "--out", out],
                       capture_output=True)
        if not os.path.exists(out):
            continue
        data = base64.b64encode(open(out, "rb").read()).decode()
        print(f"QASHOT-BEGIN {tname} | {name}")
        for i in range(0, len(data), 4000):
            print("QASHOT " + data[i:i + 4000])
        print("QASHOT-END")
        count += 1
print(f"printed {count} screenshots")
