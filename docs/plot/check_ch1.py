#!/usr/bin/env python3
"""plot 一致性校验：角色/背景名/选项引用（借鉴 rpg-maker-agent dry-run 思路）"""
import json, pathlib, sys
root = pathlib.Path(__file__).resolve().parents[2]
for name in ["data/story.json", "data/ch1.json"]:
    p = root / name
    if not p.exists():
        continue
    data = json.loads(p.read_text(encoding="utf-8"))
    chars = {x.stem for x in (root/"assets/chars").glob("*.png")}
    bgs = {x.name for x in (root/"assets/bg").glob("*.png")}
    errs = []
    for i, s in enumerate(data["scenes"]):
        if s.get("mono"):
            if "choice" in s:
                for opt in s["choice"]:
                    for k in ("death", "restart", "ending", "affinity"):
                        if k in opt and k == "affinity" and set(opt[k]) - {"求知", "体面", "因果"}:
                            errs.append(f"{name} scene {i}: 非法 affinity {opt[k]}")
            continue
        for c in s.get("chars", []):
            if c not in chars:
                errs.append(f"{name} scene {i}: char '{c}' 缺 assets/chars/{c}.png")
        bg = s.get("bg", "").split("/")[-1]
        if bg not in bgs:
            errs.append(f"{name} scene {i}: bg '{bg}' 缺 assets/bg/{bg}")
        if "choice" in s:
            for opt in s["choice"]:
                aff = opt.get("affinity", {})
                if set(aff) - {"求知", "体面", "因果"}:
                    errs.append(f"{name} scene {i}: 非法 affinity {aff}")
    if errs:
        print(f"FAIL {name}:")
        print("\n".join(errs))
        sys.exit(1)
    deaths = sum(1 for s in data["scenes"] for o in s.get("choice", []) if "death" in o)
    mono = sum(1 for s in data["scenes"] if s.get("mono"))
    print(f"OK {name}: {len(data['scenes'])} scenes, mono={mono}, deaths={deaths}")
