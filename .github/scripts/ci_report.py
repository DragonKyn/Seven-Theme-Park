"""Turns Gradle logs into GitHub annotations, so build results can be read
without downloading logs. Never fails the job."""
import os
import re
import sys


def annotate(level, title, lines):
    if not lines:
        return
    text = "\n".join(lines)
    text = text.replace("%", "%25").replace("\r", "").replace("\n", "%0A")
    # Annotation messages are capped, so keep it well under the limit.
    print("::%s title=%s::%s" % (level, title, text[:60000]))


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            return handle.read().splitlines()
    except OSError:
        return []


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else ".."
    for name in ("core-test.log", "app-build.log"):
        lines = read(os.path.join(root, name))
        if not lines:
            continue

        errors = []
        for index, line in enumerate(lines):
            if re.match(r"^e: ", line) or "error:" in line or "FAILED" in line \
                    or "What went wrong" in line or "Execution failed" in line \
                    or "AssertionError" in line or "Exception" in line and "at " not in line[:6]:
                errors.append(line.strip())
                if "What went wrong" in line or "Execution failed" in line:
                    errors.extend(l.strip() for l in lines[index + 1:index + 4])
            if len(errors) > 150:
                break
        annotate("error", name + " problems", errors[:150])

        info = [l.strip() for l in lines if re.match(r"^\s*(days=|BUILD |.*tests completed)", l)]
        annotate("notice", name + " summary", info[:20])


main()
