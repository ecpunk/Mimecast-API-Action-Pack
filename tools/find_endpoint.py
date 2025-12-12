#!/usr/bin/env python3
import argparse
import json
import re
from pathlib import Path
from typing import List, Dict


def load_endpoints(api_ref_path: Path) -> List[Dict]:
    data = json.loads(api_ref_path.read_text())
    return data.get("endpoints", [])


def score_endpoint(ep: Dict, query_terms: List[str]) -> int:
    text = " ".join([
        ep.get("name", ""),
        ep.get("category", ""),
        ep.get("method", ""),
        ep.get("path", ""),
        ep.get("description", ""),
    ]).lower()
    score = 0
    for term in query_terms:
        if term in text:
            # weight exact term presence
            score += 3
        # slight weight for regex word match
        if re.search(rf"\b{re.escape(term)}\b", text):
            score += 2
    return score


def main():
    p = argparse.ArgumentParser(description="Search Mimecast API endpoints by keywords")
    p.add_argument("query", nargs="+", help="Keywords to search for (e.g. blocked senders list)")
    p.add_argument("--api-ref", default="api-reference.json", help="Path to api-reference.json")
    p.add_argument("--category", help="Filter by category name (optional)")
    p.add_argument("--limit", type=int, default=10, help="Number of results to show")
    args = p.parse_args()

    api_ref = Path(args.api_ref)
    if not api_ref.exists():
        raise SystemExit(f"api-reference not found: {api_ref}")

    eps = load_endpoints(api_ref)
    terms = [t.lower() for t in args.query]

    if args.category:
        eps = [e for e in eps if e.get("category", "").lower() == args.category.lower()]

    scored = sorted(
        ((score_endpoint(e, terms), e) for e in eps),
        key=lambda x: x[0],
        reverse=True,
    )

    count = 0
    for sc, e in scored:
        if sc <= 0:
            break
        print(f"[{e.get('category')}] {e.get('method')} {e.get('path')}  -- {e.get('name')}")
        if e.get("description"):
            print(f"  desc: {e['description'][:120]}{'...' if len(e['description'])>120 else ''}")
        if e.get("parameters"):
            print(f"  params: {len(e['parameters'])}")
        print(f"  url: {e.get('url')}")
        count += 1
        if count >= args.limit:
            break

    if count == 0:
        print("No results. Try different keywords or remove filters.")


if __name__ == "__main__":
    main()
