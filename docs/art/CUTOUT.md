# art 抠图工作流（抠抠图 koukoutu）

手搓 GrabCut/色键已废弃（白衣 halo 抠不干净），统一走抠抠图 API。

## 领取 key

https://www.koukoutu.com/user/dev 领 API Key，价格见 https://www.koukoutu.com/api-pricing。

## 用法

```bash
export KOUKOUTU_API_KEY='你的key'
python3 tools/koukoutu_cutout.py --all   # 重抠4张：nvxiu/xiaosuo/laohuang/huoji
```

- 输入：`/tmp/guo2/` 白底/绿幕原图（保留底，勿删）
- 输出：`assets/chars/*.png` 600x900 真透明
- 参数：`border=1` 标准边缘增强，`crop=0` 不裁切
- 验：`Godot --headless --import` + `--quit-after` 零报错，F5 看人物无框无 halo

## 人设 prompt 存档（下次换图直接用）

- nvxiu：高马尾+红绳，冷脸凤眼，深青汉服红绣，持剑，国风精致
- xiaosuo：发髻+玉簪，温和坚定，宝蓝汉服金边
- laohuang：白发白须，慈祥眯眼，深褐汉服（深衣好抠）
- huoji：头巾，憨笑，深灰汉服+棕围裙（深衣好抠）

白衣慎用：AI 抠像必吃衣服，必须深衣。
