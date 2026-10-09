"""Turns Gradle logs into GitHub annotations, so build results can be read
without downloading logs. Never fails the job."""
import os
import re
import sys

PREFIX = re.compile(
    r"file:///home/runner/work/[^/]+/[^/]+/android/(core|app)/src/(main|test)/kotlin/com/wickedstudios/wonderlot/")
NEWLINE = chr(10)


def annotate(level, title, lines):
    """Annotation messages are cut off at a few KB, so a long list is split."""
    if not lines:
        return
    chunk, size, part = [], 0, 1
    for line in lines + [None]:
        if line is None or size + len(line) > 3200:
            if chunk:
                text = NEWLINE.join(chunk).replace("%", "%25").replace(NEWLINE, "%0A")
                print("::%s title=%s (%d)::%s" % (level, title, part, text))
                part += 1
            chunk, size = [], 0
            if line is None:
                break
        short = PREFIX.sub("", line)[:300]
        chunk.append(short)
        size += len(short) + 1


def read(path):
    try:
        with open(path, encoding="utf-8", errors="replace") as handle:
            return handle.read().splitlines()
    except OSError:
        return []


def interesting(line):
    if re.match(r"^e: ", line):
        return True
    return ("FAILED" in line or "What went wrong" in line or "Execution failed" in line
            or "AssertionError" in line)


def main():
    root = sys.argv[1] if len(sys.argv) > 1 else ".."
    for name in ("core-test.log", "app-build.log"):
        lines = read(os.path.join(root, name))
        if not lines:
            continue

        errors = []
        for index, line in enumerate(lines):
            if interesting(line):
                errors.append(line.strip())
                if "What went wrong" in line or "Execution failed" in line:
                    errors.extend(item.strip() for item in lines[index + 1:index + 4])
                elif "FAILED" in line and ">" in line:
                    errors.extend(item.strip() for item in lines[index + 1:index + 4])
            if len(errors) > 200:
                break
        annotate("error", name + " problems", errors[:200])

        info = [item.strip() for item in lines if re.match(r"^\s*(days=|BUILD |.*tests completed)", item)]
        annotate("notice", name + " summary", info[:20])


main()
