#!/usr/bin/env python3
"""Summarises tests/evidence/mobile/flutter_test_machine.jsonl and lcov.info
into tests/evidence/mobile/SUMMARY.json (test counts per category, coverage)."""
import json
import pathlib
from collections import defaultdict

EV = pathlib.Path(__file__).resolve().parents[3] / "tests/evidence/mobile"
suites, tests, results = {}, {}, {}
for line in (EV / "flutter_test_machine.jsonl").read_text().splitlines():
    try:
        e = json.loads(line)
    except json.JSONDecodeError:
        continue
    if not isinstance(e, dict):
        continue
    t = e.get("type")
    if t == "suite":
        suites[e["suite"]["id"]] = e["suite"]["path"]
    elif t == "testStart":
        tests[e["test"]["id"]] = e["test"]
    elif t == "testDone":
        results[e["testID"]] = e

def category(path):
    p = path.split("/test/", 1)[-1]
    return p.split("/")[0] if "/" in p else p

counts = defaultdict(lambda: {"passed": 0, "failed": 0, "skipped": 0})
for tid, r in results.items():
    t = tests[tid]
    if r.get("hidden"):
        continue  # setUpAll/tearDownAll/loading pseudo-tests
    c = category(suites[t["suiteID"]])
    if r.get("skipped"):
        counts[c]["skipped"] += 1
    elif r["result"] == "success":
        counts[c]["passed"] += 1
    else:
        counts[c]["failed"] += 1
total = {k: sum(v[k] for v in counts.values()) for k in ("passed", "failed", "skipped")}

cov = defaultdict(lambda: [0, 0])
f = None
for line in (EV / "lcov.info").read_text().splitlines():
    if line.startswith("SF:"):
        f = line[3:]
    elif line.startswith("LF:"):
        cov[f][0] += int(line[3:])
    elif line.startswith("LH:"):
        cov[f][1] += int(line[3:])

def pct(prefix, exclude=()):
    lf = sum(v[0] for k, v in cov.items() if k.startswith(prefix) and not any(x in k for x in exclude))
    lh = sum(v[1] for k, v in cov.items() if k.startswith(prefix) and not any(x in k for x in exclude))
    return {"linesFound": lf, "linesHit": lh, "percent": round(100 * lh / lf, 2) if lf else None}

summary = {
    "tests": {"byCategory": dict(counts), "total": total},
    "coverage": {
        "lib/domain": pct("lib/domain/"),
        "lib/data": pct("lib/data/"),
        "lib/ui": pct("lib/ui/"),
        "lib (excluding generated l10n)": pct("lib/", exclude=("lib/l10n/",)),
        "perFile": {k: {"lines": v[0], "hit": v[1], "percent": round(100 * v[1] / v[0], 1) if v[0] else None}
                    for k, v in sorted(cov.items())},
    },
}
(EV / "SUMMARY.json").write_text(json.dumps(summary, indent=1) + "\n")
print(json.dumps({"tests": summary["tests"], "coverage": {k: v for k, v in summary["coverage"].items() if k != "perFile"}}, indent=1))
