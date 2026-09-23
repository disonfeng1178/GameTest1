#!/usr/bin/env python3
"""plot 一致性校验：角色/背景名/选项引用（借鉴 rpg-maker-agent dry-run 思路）"""
import json, pathlib, sys
root = pathlib.Path(__file__).resolve().parents[2]
data = json.loads((root/"data/ch1.json").read_text(encoding="utf-8"))
chars = {p.stem for p in (root/"assets/chars").glob("*.png")}
bgs = {p.name for p in (root/"assets/bg").glob("*.png")}
errs = []
for i, s in enumerate(data["scenes"]):
    for c in s.get("chars", []):
        if c not in chars:
            errs.append(f"scene {i}: char '{c}' 缺 assets/chars/{c}.png")
    bg = s.get("bg", "").split("/")[-1]
    if bg not in bgs:
        errs.append(f"scene {i}: bg '{bg}' 缺 assets/bg/{bg}")
    if "choice" in s:
        for opt in s["choice"]:
            aff = opt.get("affinity", {})
            if set(aff) - {"求知", "体面", "因果"}:
                errs.append(f"scene {i}: 非法 affinity {aff}")
if errs:
    print("FAIL:")
    print("\n".join(errs))
    sys.exit(1)
print(f"OK: {len(data['scenes'])} scenes, chars={sorted(chars)}, bgs={sorted(bgs)}")
