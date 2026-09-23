# art 即梦生图工作流（Seedream 4.x/4.6/5.0）

免费 pollinations 已退役（水印+不稳），国风立绘/背景统一走即梦。

## 开通

1. 火山控制台开通“即梦AI-图片生成4.6”（产品介绍见需求链接），拿到方舟 API Key
2. `export VOLC_API_KEY='你的key'`
3. 模型 ID 看控制台实际开通：`doubao-seedream-4-0-250828` 最稳（1K/2K/4K）；
   开了 4.6/4.5/5.0 就用 `--model` 切，`--size` 用像素如 `880x1320`（立绘2:3）/`1280x720`（背景16:9）

## 出图 -> 抠图 -> 进游戏

```bash
# 1. 单张试
python3 tools/jimeng_generate.py --prompt "见下：女修prompt" --size 880x1320 --output /tmp/jm_nvxiu.jpg
# 2. 批量（4立绘+3背景）
python3 tools/jimeng_generate.py --batch docs/art/JIMENG_JOBS.json
# 3. 抠图（白底直出一般不用抠；已有杂色底才走 koukoutu）
export KOUKOUTU_API_KEY='...'
python3 tools/koukoutu_cutout.py --all
# 4. 进游戏验证
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --import
```

## 国风 prompt 存档（直接用）

- 女修：`中国古风仙侠美女修士，高马尾黑发配红绳，冷艳凤眼，黛青汉服红线刺绣，持剑，半身像，古剑奇谭游戏立绘风格，端庄华贵，纯白背景`
- 萧索：`中国古风青年书生修士，发髻配玉簪，温和坚定，宝蓝汉服金边，半身像，古剑奇谭风格，纯白背景`
- 老黄头：`中国古风慈祥老者，白发白须，眯眼微笑，深褐色粗布汉服，半身像，纯白背景`
- 伙计：`中国古风青年店伙计，头巾，憨厚笑，深灰汉服配棕色围裙，半身像，纯白背景`
- 背景：见 JIMENG_JOBS.json（黄狗县暮色街/小黑屋夜读/雾竹林）

白衣慎用：抠像必吃衣服，一律深衣+纯白/纯绿底。
