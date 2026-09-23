# 多角色协作规范（嗟仙 Demo）

自学原型，3 剧情 + 美术 + 玩法并行，主控负责合版。

## 角色

- `plot` 关卡情节：只改 `data/*.json`、`novel/` 切片、`docs/plot/*.md`。定分支树、选项、好感数值，不碰脚本和图片二进制。
- `art` 素材人物UI：只改 `assets/`、`scenes/*.tscn` 样式、`docs/art/*.md`（prompt/人设）。人物同名替换，保持 600x900 PNG + 透明底。
- `gameplay` 玩法逻辑：只改 `scripts/`、`scenes/` 节点结构、`docs/gameplay/*.md`。守住数据契约，不擅自改 JSON 字段名。
- `lead` 主控整合（我）：定契约、合版、跑 Godot headless 验证、打 tag。冲突时以契约和可运行为准。

## 契约（冲突时看这个）

- 剧情 JSON：`{bg, chars[], focus, speaker, text, choice?[{label, affinity{求知/体面/因果}}]}`，`chars` 名必须对应 `assets/chars/<名>.png`，`bg` 必须对应 `assets/bg/*.png`。
- 立绘：`assets/chars/<名>.png` 600x900，透明底，半身；背景 `assets/bg/*.png` 1280x720。
- 玩法：`scripts/main.gd` 对外只读上述字段，新增字段必须先更新本契约并通知 plot。

## Skill 学习映射（各学各的）

- `gameplay` 学 `agentic-gamedev-skills` 子集：`running-headless-godot` + `scaffolding-godot-mini-games` + `maximizing-game-feel` + Godot 程序化音频。不学 web/crisp 相关。
- `art` 学 `agentic-gamedev-skills` 子集：`directing-game-visuals` + `styling-typography`。风格目标：上古史诗感，参考古剑奇谭人物肖像，不走 Q 版纸片风。
- `plot` 学 `agentic-gamedev-skills` 子集：`exploring-game-design-space` + `stress-testing-game-concepts`。另借鉴 `rpg-maker-agent` 的干跑 + 一致性校验思路，但不装它。
- `plot` 主学 `novel-to-game`：`novel-game-analyze`（整本建 SOURCE_BIBLE，每个设定标章节出处，事实标 immutable/adaptable/open/conflicted）+ `game-concept`（多方向 PK + 硬 veto 毙线）+ `game-world-design`（关键选项必须在后文复述+改态度+改结局）。`art` 学 `game-art-direction`。`gameplay` 学 `game-build`（白盒先验最大风险）+ `game-qa`（launch/render/input/coreLoop/outcome/restart 六项实跑）。注意：默认出网页版，Godot 构建以本机工具链为准；版权自理（嗟仙自学可玩，商用需授权）。
- 跨角色新增 skill 需求，先记到本节，再由 lead 批准。

## Git 工作流

- 分支：`role/plot`、`role/art`、`role/gameplay`，都从 `main` 拉。只在自己目录+文档里改。
- 合版：各角色完事推自己分支，`lead` 切到 main 逐个 merge，跑 `Godot --headless --import` + `--quit-after` 零报错才算过。
- 想让特定 AI 调人物：直接说“叫 art 改女修”，我会切 `role/art` 分支、只动 `assets/chars/nvxiu.png` 相关，改完你 F5 看，不满意继续说，满意了我再合进 main。

## 跟特定角色说话的方式

- 在本会话里直接点名：“@plot 把第一章结尾加个回溯选项”“@art 女修换高马尾+冷脸”“@gameplay 选项加倒计时 10 秒”。
- 我会起对应子任务在对应分支上改，互不踩脚。跨角色需求（比如加新角色）我会拆成 plot 出设定→art 出图→gameplay 接线三步走。
