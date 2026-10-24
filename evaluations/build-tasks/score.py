#!/usr/bin/env python3
"""Score an n8n workflow JSON against a build-task case.

    python3 evaluations/build-tasks/score.py <case.json> <workflow.json> [--json]

Exit code 0 when every assertion passes, 1 when any fails, 2 when the workflow
file is missing or isn't a workflow. Standard library only.

Assertion types (the "assertions" list in a case file):

  no_node         {"node_types": [...]}             none of these types present
  has_node        {"node_types": [...]}             at least one of these present
  node_param      {"node_type", "path", "op", "value"?}
                  every node of that type has the dotted parameter path;
                  op is "exists", "equals" or "truthy"
  node_note       {"node_type", "pattern"}          every node of that type has
                                                    notes matching the regex
  max_nodes       {"max"}                           node count, sticky notes excluded
  max_nodes_matching {"pattern", "max"}             at most this many nodes whose parameters
                                                    (as JSON) match the regex — e.g. a value
                                                    computed in one node, not repeated per consumer
  connected       {}                                every node is linked to a trigger
                                                    (any connection type, either direction)

A node_param / node_note assertion fails when no node of the type exists; pair
it with has_node when the node is optional.
"""

import json
import re
import sys

STICKY = "n8n-nodes-base.stickyNote"


def load_workflow(path):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    if isinstance(data, dict) and isinstance(data.get("workflow"), dict):
        data = data["workflow"]
    if not isinstance(data, dict) or not isinstance(data.get("nodes"), list):
        raise ValueError("no nodes[] array")
    data.setdefault("connections", {})
    return data


def real_nodes(wf):
    return [n for n in wf["nodes"] if isinstance(n, dict) and n.get("type") != STICKY]


def of_type(wf, node_type):
    return [n for n in real_nodes(wf) if n.get("type") == node_type]


def get_path(obj, dotted):
    cur = obj
    for part in dotted.split("."):
        if isinstance(cur, dict) and part in cur:
            cur = cur[part]
        else:
            return False, None
    return True, cur


def is_trigger(node):
    t = (node.get("type") or "").lower()
    return "trigger" in t or t.endswith(".webhook")


def connected(wf):
    nodes = real_nodes(wf)
    names = {n.get("name") for n in nodes}
    adj = {name: set() for name in names}
    for src, outputs in (wf.get("connections") or {}).items():
        if not isinstance(outputs, dict):
            continue
        for slots in outputs.values():
            for slot in slots or []:
                for edge in slot or []:
                    dst = edge.get("node") if isinstance(edge, dict) else None
                    if src in adj and dst in adj:
                        adj[src].add(dst)
                        adj[dst].add(src)
    seen = set()
    stack = [n.get("name") for n in nodes if is_trigger(n)]
    if not stack:
        return False, "no trigger node"
    while stack:
        cur = stack.pop()
        if cur in seen:
            continue
        seen.add(cur)
        stack.extend(adj.get(cur, ()))
    loose = sorted(n for n in names - seen if n)
    return (not loose), ("not linked to a trigger: " + ", ".join(loose)) if loose else "all nodes linked"


def check(wf, a):
    kind = a["type"]
    if kind == "no_node":
        found = sorted({n["type"] for n in real_nodes(wf) if n.get("type") in a["node_types"]})
        return not found, ("found " + ", ".join(found)) if found else "none present"
    if kind == "has_node":
        found = sorted({n["type"] for n in real_nodes(wf) if n.get("type") in a["node_types"]})
        return bool(found), ("found " + ", ".join(found)) if found else "missing all of " + ", ".join(a["node_types"])
    if kind == "node_param":
        nodes = of_type(wf, a["node_type"])
        if not nodes:
            return False, "no " + a["node_type"] + " node"
        bad = []
        for n in nodes:
            ok, val = get_path(n.get("parameters") or {}, a["path"])
            op = a.get("op", "exists")
            if op == "exists":
                passed = ok
            elif op == "equals":
                passed = ok and val == a["value"]
            elif op == "truthy":
                passed = ok and bool(val)
            else:
                raise ValueError("unknown op " + op)
            if not passed:
                bad.append("%s (%s)" % (n.get("name"), json.dumps(val) if ok else "absent"))
        return not bad, ("fails on " + ", ".join(bad)) if bad else "ok on %d node(s)" % len(nodes)
    if kind == "node_note":
        nodes = of_type(wf, a["node_type"])
        if not nodes:
            return False, "no " + a["node_type"] + " node"
        rx = re.compile(a["pattern"], re.I)
        bad = [n.get("name") for n in nodes if not rx.search(str(n.get("notes") or ""))]
        return not bad, ("no matching note on " + ", ".join(map(str, bad))) if bad else "ok on %d node(s)" % len(nodes)
    if kind == "max_nodes_matching":
        rx = re.compile(a["pattern"], re.I)
        hits = [n.get("name") for n in real_nodes(wf) if rx.search(json.dumps(n.get("parameters") or {}))]
        return len(hits) <= a["max"], "%d node(s) match (%s), max %d" % (len(hits), ", ".join(map(str, hits)) or "none", a["max"])
    if kind == "max_nodes":
        count = len(real_nodes(wf))
        return count <= a["max"], "%d node(s), max %d" % (count, a["max"])
    if kind == "connected":
        return connected(wf)
    raise ValueError("unknown assertion type " + kind)


def main(argv):
    if len(argv) < 3:
        print(__doc__.strip().splitlines()[2].strip())
        return 2
    with open(argv[1], encoding="utf-8") as f:
        case = json.load(f)
    try:
        wf = load_workflow(argv[2])
    except (OSError, ValueError) as e:
        result = {"case": case["id"], "passed": False, "error": str(e), "assertions": []}
        print(json.dumps(result) if "--json" in argv else "ERROR %s: %s" % (case["id"], e))
        return 2
    rows = []
    for a in case["assertions"]:
        ok, detail = check(wf, a)
        rows.append({"assertion": a.get("label") or a["type"], "passed": ok, "detail": detail})
    passed = all(r["passed"] for r in rows)
    if "--json" in argv:
        print(json.dumps({"case": case["id"], "passed": passed, "assertions": rows}))
    else:
        for r in rows:
            print("%s  %-40s %s" % ("PASS" if r["passed"] else "FAIL", r["assertion"], r["detail"]))
        print("%s %s" % ("PASSED" if passed else "FAILED", case["id"]))
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
