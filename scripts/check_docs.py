#!/usr/bin/env python3
"""Validate repository documentation without network or database access."""
from pathlib import Path
from urllib.parse import urlsplit, unquote
import hashlib
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors = []

def require(condition, message):
    if not condition:
        errors.append(message)

def read_json(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def anchors(path):
    return re.findall(r'<a\s+id="([^"]+)"\s*></a>', path.read_text(encoding="utf-8"))

def check_ref(ref, source, base=ROOT):
    parsed = urlsplit(ref)
    if parsed.scheme or parsed.netloc:
        return
    destination = (base / unquote(parsed.path)).resolve() if parsed.path else source.resolve()
    require(destination == ROOT or ROOT in destination.parents, f"Reference escapes repository: {source}: {ref}")
    if not destination.is_file():
        errors.append(f"Missing reference: {source}: {ref}")
        return
    if parsed.fragment:
        require(unquote(parsed.fragment) in anchors(destination),
                f"Missing explicit anchor: {source}: {ref}")

def main():
    manifest = read_json("docs/manifest.json")
    functions = read_json(manifest["catalogs"]["functions"])
    schema = read_json(manifest["catalogs"]["schema"])
    sql_manifest = read_json(manifest["source_manifest"])
    sql_functions = {(f["name"], f["identity_arguments"]): f for f in sql_manifest["functions"]}
    require(sql_manifest["snapshot_date"] == manifest["snapshot_date"], "SQL/document snapshot dates differ")
    for name, obj in [("manifest", manifest), ("functions", functions), ("schema", schema)]:
        require(obj.get("schema_version") == 1, f"Unsupported schema_version: {name}")
        require(obj.get("reference_base") == "repository_root", f"Invalid reference base: {name}")
    require(functions["snapshot_date"] == schema["snapshot_date"] == manifest["snapshot_date"],
            "Catalog snapshot dates differ")

    docs = manifest["documents"]
    paths = [d["path"] for d in docs]
    ids = [d["id"] for d in docs]
    require(len(paths) == len(set(paths)), "Duplicate document paths")
    require(len(ids) == len(set(ids)), "Duplicate document ids")
    evidence = {"observed_snapshot", "proposed_workflow", "planned", "navigation", "mixed"}
    for d in docs:
        check_ref(d["path"], ROOT / "docs/manifest.json")
        require(d["evidence_status"] in evidence, f"Unknown evidence status: {d['id']}")
        require(bool(d.get("audience")) and bool(d.get("purpose")), f"Missing metadata: {d['id']}")

    actual_documents = {str(p.relative_to(ROOT)) for p in ROOT.rglob("*")
                        if p.is_file() and not any(part in {"node_modules", ".git", "__pycache__"} for part in p.relative_to(ROOT).parts)
                        and (p.suffix == ".md" or p.name == "llms.txt"
                                            or p.parent == ROOT / "docs/reference"
                                            or p == ROOT / "docs/manifest.json")}
    require(actual_documents == set(paths),
            f"Manifest inventory mismatch: {sorted(actual_documents ^ set(paths))}")
    for rel in paths:
        p = ROOT / rel
        if p.suffix not in {".md", ".txt"}:
            continue
        text = p.read_text(encoding="utf-8")
        refs = re.findall(r"\[[^\]]*\]\(([^)]+)\)", text)
        for ref in refs:
            check_ref(ref, p, p.parent)
        aa = anchors(p)
        require(len(aa) == len(set(aa)), f"Duplicate explicit anchors: {rel}")
        fences = [line for line in text.splitlines() if line.startswith(chr(96) * 3)]
        require(len(fences) % 2 == 0, f"Unclosed code fence: {rel}")

    function_items = functions["functions"]
    by_id = {f["signature_id"]: f for f in function_items}
    require(len(by_id) == len(function_items), "Duplicate signature IDs")
    reference_text = (ROOT / "docs/functions.md").read_text(encoding="utf-8")
    for f in function_items:
        expected = f"{f['qualified_name']}({f['identity_arguments']})"
        require(f["signature"] == expected, f"Signature mismatch: {f['signature_id']}")
        expected_id = "fn-" + f["name"].replace("_", "-") + "-" + hashlib.sha256(expected.encode()).hexdigest()[:10]
        require(f["signature_id"] == expected_id, f"Unstable signature ID: {f['name']}")
        args = ", ".join(p["name"] + " " + p["sql_type"] for p in f["parameters"])
        require(args == f["identity_arguments"], f"Parameter mismatch: {f['name']}")
        require(all(type(p["has_default"]) is bool for p in f["parameters"]),
                f"Invalid default flags: {f['name']}")
        check_ref(f["doc_ref"], ROOT / "docs/reference/functions.json")
        check_ref(f["source_path"], ROOT / "docs/reference/functions.json")
        sql_function = sql_functions.get((f["name"], f["identity_arguments"]), {})
        require(sql_function.get("path") == f["source_path"], f"SQL source mismatch: {f['signature_id']}")
        require(sql_function.get("portability_changes") == f["portability_changes"], f"Portability metadata mismatch: {f['signature_id']}")
        anchor = f["doc_ref"].split("#", 1)[1]
        segment = reference_text.split(f'<a id="{anchor}"></a>', 1)[-1].split('<a id="', 1)[0]
        require(expected in segment and "RETURNS " + f["return_type"] in segment,
                f"Markdown/JSON contract mismatch: {f['signature_id']}")
        require(f["usage_class"] in {"application_entrypoint", "trigger_only", "internal_review_required"},
                f"Unknown usage class: {f['name']}")

    relations = schema["relations"]
    names = [r["name"] for r in relations]
    require(len(names) == len(set(names)), "Duplicate relation names")
    for r in relations:
        check_ref(r["doc_ref"], ROOT / "docs/reference/schema.json")
        check_ref(r["source_path"], ROOT / "docs/reference/schema.json")
        p = ROOT / r["doc_ref"].split("#", 1)[0]
        anchor = r["doc_ref"].split("#", 1)[1]
        segment = p.read_text(encoding="utf-8").split(f'<a id="{anchor}"></a>', 1)[-1].split('<a id="', 1)[0]
        column_names = [c["name"] for c in r["columns"]]
        require(len(column_names) == len(set(column_names)), f"Duplicate columns: {r['name']}")
        for c in r["columns"]:
            quote = chr(96)
            expected = f"| {quote}{c['name']}{quote} | {quote}{c['sql_type']}{quote} |"
            require(expected in segment, f"Markdown/JSON column mismatch: {r['name']}.{c['name']}")
    for t in schema["triggers"]:
        require(t["table_name"] in names, f"Trigger references unknown relation: {t['name']}")
        check_ref(t["source_path"], ROOT / "docs/reference/schema.json")

    intents = []
    for t in manifest["tasks"]:
        intents.append(t["intent"])
        for ref in t["read"]:
            check_ref(ref, ROOT / "docs/manifest.json")
        if "function_id" in t:
            require(t["function_id"] in by_id, f"Unknown function in task: {t['intent']}")
            f = by_id.get(t["function_id"], {})
            require(f.get("usage_class") == "application_entrypoint", f"Internal function routed as entrypoint: {t['intent']}")
            require(f.get("documented_effect") == t["effect"], f"Effect mismatch: {t['intent']}")
            if "command" in t:
                require(t["command"] in f.get("commands", []), f"Unknown finance command: {t['intent']}")
    require(len(intents) == len(set(intents)), "Duplicate task intents")
    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"OK: {len(docs)} documents; {len(function_items)} function signatures; "
          f"{len(relations)} relations; {len(intents)} task routes.")
    print("Local links, explicit anchors and JSON references are consistent. No SQL was executed.")
    return 0

if __name__ == "__main__":
    try:
        sys.exit(main())
    except (KeyError, ValueError, OSError) as error:
        print(f"Documentation validation failed: {error}", file=sys.stderr)
        sys.exit(1)
