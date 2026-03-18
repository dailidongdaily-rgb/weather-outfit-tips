---
name: weather-outfit-tips
description: 智能穿衣天气提醒 - 根据天气预报生成穿衣建议和生活提示
homepage: https://wttr.in/:help
metadata: {"clawdbot":{"emoji":"🌤️","requires":{"bins":["curl","ffprobe","python3"]}}}
---

# 智能穿衣天气提醒 (Weather Outfit Tips)

根据天气预报生成**穿衣建议**和**生活提示**，支持语音 + 文字组合推送。

## 功能特点

- 🌡️ **逐小时预报** - 未来 12 小时天气变化
- 👕 **智能穿衣** - 根据温度、温差、风力推荐穿搭
- ☂️ **降水提醒** - 下雨/降雪自动提醒带伞
- 💡 **生活提示** - 空气质量、户外活动建议
- 🎙️ **语音播报** - 简洁版语音 + 详细文字消息

## 快速使用

### 基础调用

```bash
# 获取当前天气 + 穿衣建议
./scripts/get_outfit_tips.sh "上海" 31.2222 121.4581

# 发送语音天气报告（飞书）
./scripts/send_weather_voice.sh "上海" "<receive_id>"
```

### 逐小时预报 API

```bash
curl -s "https://api.open-meteo.com/v1/forecast?latitude=31.2222&longitude=121.4581&hourly=temperature_2m,weathercode,precipitation_probability,windspeed_10m&timezone=Asia%2FShanghai&forecast_days=2"
```

## 穿衣建议规则

| 温度范围 | 穿衣建议 |
|----------|----------|
| <5°C | 羽绒服/厚棉服 + 毛衣 + 保暖内衣 |
| 5-10°C | 厚外套/大衣 + 毛衣/卫衣 |
| 10-15°C | 风衣/薄外套 + 长袖 T 恤 |
| 15-20°C | 长袖 T 恤/薄衬衫 + 单裤 |
| 20-25°C | 短袖 T 恤 + 薄裤/裙子 |
| >25°C | 短袖 + 短裤/裙子，注意防晒 |

### 特殊天气提醒

| 天气情况 | 提醒内容 |
|----------|----------|
| 降水>50% | 带伞、穿防水鞋 |
| 温差>8°C | 早晚加衣、带外套 |
| 风力>20km/h | 防风、注意高空坠物 |
| 空气质量差 | 戴口罩、减少户外 |
| 气温骤降>5°C | 注意保暖、预防感冒 |

## 定时任务设置

### 每天早上 8:00 推送

```bash
openclaw cron add --name "weather-daily" \
  --cron "0 8 * * *" \
  --tz "Asia/Shanghai" \
  --system-event "请发送<你所在城市>的当前天气、未来 12 小时逐小时预报，并根据天气给出具体生活提醒（穿衣建议、是否带伞、注意事项等），使用语音发送" \
  --session main
```

### 语音 + 文字组合

**语音内容（简洁）：**
- 当前时间 + 当前气温 + 天气状况
- 穿衣建议（重点）
- 简要提醒（降水、风力）

**文字内容（详细）：**
- 当前天气详情
- 12 小时逐小时预报表格
- 具体穿衣建议（分时段）
- 降水提醒
- 生活提示

## 示例输出

### 语音文案
```
现在是 3 月 14 日下午 6 点 3 分。<城市>当前气温 13 度，多云。
穿衣建议：建议穿风衣或薄外套加长袖，早晚温差较大，出门记得带外套。
未来 12 小时无降水，风力 2 到 3 级。
```

### 文字消息
```
🌤️ <城市>天气预报
📍 2026-03-14 18:03

【当前天气】
- 温度：13°C
- 天气：多云
- 风力：西北风 10km/h
- 湿度：55%

【未来 12 小时逐小时预报】
| 时间 | 天气 | 温度 | 降水 | 风力 |
|------|------|------|------|------|
| 18:00 | ⛅️ | 14°C | 0% | 12km/h |
| 19:00 | ⛅️ | 12°C | 0% | 10km/h |
...

【穿衣建议】
- 当前：风衣/薄外套 + 长袖 T 恤
- 晚间：气温降至 7-9°C，建议加一件毛衣或厚外套
- 温差：7°C（14°C→7°C），早晚注意保暖

【降水提醒】
- 未来 12 小时降水概率：0%
- 无需带伞

【生活提示】
- 空气质量：良好，适合户外活动
- 风力：2-3 级，体感舒适
- 夜间较冷，晚归注意添衣
```

（注：示例中的城市和坐标仅用于演示，实际使用时请替换为你自己的位置）

## 依赖服务

- **wttr.in** - 天气数据（备用）
- **Open-Meteo** - 逐小时预报（主推，免费无需 API Key）
- **edge-tts** - 语音生成（通过 voice-message 技能）
- **飞书 API** - 消息推送（可选）

## 相关技能

- `voice-message` - 语音消息发送（必需）
- `alarm-memo-assistant-pro` - 定时提醒（可选）

## 配置说明

### 自动适配配置

本技能设计为**开箱即用**，自动适配任何 OpenClaw 安装环境：

1. **语音生成**：自动调用 `voice-message` 技能的 `gen_voice.sh` 脚本
2. **飞书推送**：通过环境变量或 TOOLS.md 配置获取凭证
3. **城市位置**：通过脚本参数或默认配置指定

### 飞书语音配置（可选）

如需发送飞书语音消息，需在 **TOOLS.md** 或环境变量中配置：

```markdown
### 飞书语音配置

- appId: `your_app_id`
- appSecret: `your_app_secret`
- 默认语音：`zh-CN-XiaoxiaoNeural`（温柔女声）
- 默认接收者 open_id: `your_open_id`
```

**环境变量方式：**
```bash
export FEISHU_APP_ID="your_app_id"
export FEISHU_APP_SECRET="your_app_secret"
export FEISHU_DEFAULT_RECEIVER="your_open_id"
```

### 默认配置

- 默认城市：北京（示例，可通过脚本参数或环境变量修改）
- 默认坐标：39.9042, 116.4074（北京）
- 默认时间：每天 8:00
- 默认语音：使用 `voice-message` 技能的默认配置

**环境变量覆盖：**
```bash
export WEATHER_LAT="31.2222"      # 纬度
export WEATHER_LON="121.4581"     # 经度
export FEISHU_VOICE="zh-CN-XiaoxiaoNeural"  # 语音
```

## 脚本说明

### get_outfit_tips.sh

获取天气数据并生成穿衣建议。

**用法：**
```bash
./scripts/get_outfit_tips.sh [城市] [纬度] [经度]
```

**示例：**
```bash
./scripts/get_outfit_tips.sh "北京" 39.9042 116.4074
```

### send_weather_voice.sh

生成语音并发送到飞书。

**用法：**
```bash
./scripts/send_weather_voice.sh [城市] [接收者 open_id]
```

**示例：**
```bash
./scripts/send_weather_voice.sh "上海" "ou_xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

**依赖：**
- `voice-message` 技能的 `gen_voice.sh` 脚本
- 飞书 appId/appSecret（通过环境变量或 TOOLS.md 获取）

## 扩展建议

1. **多城市支持** - 添加城市坐标配置文件
2. **周预报** - 扩展至 7 天预报
3. **过敏提醒** - 花粉/紫外线指数
4. **运动建议** - 根据天气推荐户外活动

## 故障排除

### 天气数据获取失败

1. 检查网络连接
2. 尝试备用 API（wttr.in）
3. 验证坐标是否正确

### 语音发送失败

1. 确认 `voice-message` 技能已安装
2. 检查飞书 appId/appSecret 配置
3. 验证接收者 open_id 是否正确

### 飞书 token 获取失败

1. 检查 appId/appSecret 是否正确
2. 确认飞书应用权限配置
3. 查看 API 响应错误信息
