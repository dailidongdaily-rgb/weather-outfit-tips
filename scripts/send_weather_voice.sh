#!/bin/bash
# 智能穿衣天气提醒 - 语音发送脚本
# 用法：./send_weather_voice.sh [城市] [接收者 open_id]
# 依赖：voice-message 技能的 gen_voice.sh 脚本

set -e

CITY="${1:-北京}"
RECEIVE_ID="${2:-}"
# 默认坐标：北京（可通过环境变量覆盖）
LAT="${WEATHER_LAT:-39.9042}"
LON="${WEATHER_LON:-116.4074}"

# 自动检测脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
WORKSPACE_DIR="$(dirname "$(dirname "$SKILL_DIR")")"

# 语音文件
VOICE_FILE="/tmp/weather_$(date +%s).ogg"

# 自动查找 gen_voice.sh 脚本
GEN_VOICE_SCRIPT=""
for path in \
  "$WORKSPACE_DIR/skills/voice-message/scripts/gen_voice.sh" \
  "$WORKSPACE_DIR/skills/voice-message/gen_voice.sh" \
  "$(which gen_voice.sh 2>/dev/null)"
do
  if [ -x "$path" ]; then
    GEN_VOICE_SCRIPT="$path"
    break
  fi
done

if [ -z "$GEN_VOICE_SCRIPT" ]; then
  echo "❌ 未找到 gen_voice.sh 脚本，请确保 voice-message 技能已安装"
  exit 1
fi

echo "🎤 使用语音脚本：$GEN_VOICE_SCRIPT"

# 从环境变量或 TOOLS.md 读取飞书配置
APP_ID="${FEISHU_APP_ID:-}"
APP_SECRET="${FEISHU_APP_SECRET:-}"

# 如果环境变量未设置，尝试从 TOOLS.md 读取
if [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ]; then
  TOOLS_MD="$WORKSPACE_DIR/TOOLS.md"
  if [ -f "$TOOLS_MD" ]; then
    if [ -z "$APP_ID" ]; then
      APP_ID=$(grep -A1 "飞书语音配置\|飞书配置" "$TOOLS_MD" | grep "appId" | sed 's/.*`\(.*\)`.*/\1/' | head -1)
    fi
    if [ -z "$APP_SECRET" ]; then
      APP_SECRET=$(grep -A2 "飞书语音配置\|飞书配置" "$TOOLS_MD" | grep "appSecret" | sed 's/.*`\(.*\)`.*/\1/' | head -1)
    fi
  fi
fi

# 如果仍未设置，提示用户
if [ -z "$APP_ID" ] || [ -z "$APP_SECRET" ]; then
  echo "⚠️  未配置飞书 appId/appSecret"
  echo "请在 TOOLS.md 中添加配置，或设置环境变量："
  echo "  export FEISHU_APP_ID=\"your_app_id\""
  echo "  export FEISHU_APP_SECRET=\"your_app_secret\""
  echo ""
  echo "将仅生成天气报告和语音文件，不发送飞书消息"
  SKIP_SEND=true
else
  SKIP_SEND=false
fi

# 如果未指定接收者，尝试从环境变量读取
if [ -z "$RECEIVE_ID" ]; then
  RECEIVE_ID="${FEISHU_DEFAULT_RECEIVER:-}"
  if [ -z "$RECEIVE_ID" ] && [ "$SKIP_SEND" = false ]; then
    echo "❌ 未指定接收者 open_id"
    echo "用法：$0 [城市] [open_id]"
    echo "或设置环境变量：export FEISHU_DEFAULT_RECEIVER=\"your_open_id\""
    exit 1
  fi
fi

# 默认语音（可通过环境变量覆盖）
VOICE="${FEISHU_VOICE:-zh-CN-XiaoxiaoNeural}"

echo "🌤️ 正在获取 ${CITY} 天气..."

# 获取逐小时预报
FORECAST=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&hourly=temperature_2m,weathercode,precipitation_probability,windspeed_10m&timezone=Asia%2FShanghai&forecast_days=2")

if [ -z "$FORECAST" ]; then
  echo "❌ 获取天气数据失败"
  exit 1
fi

# 生成天气报告和语音文案
RESULT=$(python3 << PYEOF
import json
from datetime import datetime

CITY = "$CITY"
data = json.loads('''$FORECAST''')
hourly = data['hourly']
current_hour = datetime.now().hour

weather_map = {0:'晴朗',1:'多云',2:'多云',3:'阴',45:'雾',61:'小雨',63:'中雨',80:'阵雨',95:'雷雨'}
get_weather = lambda code: weather_map.get(code, '多云')

current_temp = int(hourly['temperature_2m'][current_hour])
current_weather = get_weather(hourly['weathercode'][current_hour])
current_wind = round(hourly['windspeed_10m'][current_hour], 1)
current_precip = hourly['precipitation_probability'][current_hour]

# 从 18:00（下午 6 点）开始报告，报告 12 个小时（到第二天早上 6 点）
start_hour = 18 if current_hour < 18 else 18
forecast_12h = []
for i in range(start_hour, min(start_hour + 12, len(hourly['time']))):
  forecast_12h.append({
    'time': hourly['time'][i][11:16],
    'temp': int(hourly['temperature_2m'][i]),
    'precip': hourly['precipitation_probability'][i]
  })

temps = [f['temp'] for f in forecast_12h]
temp_diff = max(temps) - min(temps) if temps else 0
max_precip = max([f['precip'] for f in forecast_12h], default=0)

if current_temp < 5: outfit = "羽绒服加厚棉服加毛衣"
elif current_temp < 10: outfit = "厚外套加大衣加毛衣"
elif current_temp < 15: outfit = "风衣或薄外套加长袖 T 恤"
elif current_temp < 20: outfit = "长袖 T 恤加薄衬衫"
elif current_temp < 25: outfit = "短袖 T 恤加薄裤"
else: outfit = "短袖加短裤，注意防晒"

# 语音文案（简洁）
voice_text = f"现在是{datetime.now().strftime('%m月%d日%H点%M分')}。{CITY}当前气温{current_temp}度，{current_weather}。穿衣建议：{outfit}。"
if max_precip > 30:
  voice_text += "今天有降水可能，记得带伞。"
if temp_diff > 8:
  voice_text += f"昼夜温差{temp_diff}度，早晚注意添衣。"
else:
  voice_text += "气温平稳，体感舒适。"

# 文字报告（详细）
text_report = f"""🌤️ {CITY}天气预报
📍 {datetime.now().strftime('%Y-%m-%d %H:%M')}

【当前天气】
- 温度：{current_temp}°C
- 天气：{current_weather}
- 风力：{current_wind}km/h
- 降水概率：{current_precip}%

【晚间预报（18:00-次日 06:00）】"""

for f in forecast_12h:
  text_report += f"\n{f['time']}  {f['temp']}°C  降水{f['precip']}%"

text_report += f"""

【穿衣建议】
- 当前：{outfit}
- 温差：{temp_diff}°C

【降水提醒】"""
if max_precip > 50:
  text_report += f"\n- 最高降水概率{max_precip}%，建议带伞☔"
else:
  text_report += "\n- 未来 12 小时无降水，无需带伞"

# 输出变量
print(f"VOICE_TEXT={voice_text}")
print(f"TEXT_REPORT={text_report}")
print(f"CURRENT_TEMP={current_temp}")
print(f"CURRENT_WEATHER={current_weather}")
PYEOF
)

# 解析 Python 输出
eval "$RESULT"

echo ""
echo "=== 天气数据 ==="
echo "温度：$CURRENT_TEMP°C"
echo "天气：$CURRENT_WEATHER"
echo ""

# 生成语音
echo "🎙️ 正在生成语音..."
"$GEN_VOICE_SCRIPT" "$VOICE_TEXT" "$VOICE_FILE" "$VOICE" 2>&1 | tail -1

if [ ! -f "$VOICE_FILE" ]; then
  echo "❌ 语音生成失败"
  exit 1
fi

echo "✅ 语音生成成功：$VOICE_FILE"

# 如果需要发送飞书
if [ "$SKIP_SEND" = false ]; then
  # 获取飞书 token
  echo "📱 正在获取飞书 token..."
  TOKEN=$(curl -s -X POST "https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal" \
    -H "Content-Type: application/json" \
    -d "{\"app_id\":\"$APP_ID\",\"app_secret\":\"$APP_SECRET\"}" | \
    python3 -c "import json,sys; print(json.load(sys.stdin).get('tenant_access_token',''))")

  if [ -z "$TOKEN" ]; then
    echo "❌ 获取飞书 token 失败"
    exit 1
  fi

  # 上传语音文件
  echo "📤 正在上传语音..."
  DURATION_MS=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$VOICE_FILE" | python3 -c "import sys; print(int(float(sys.stdin.read().strip()) * 1000))")

  UPLOAD_RESP=$(curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/files" \
    -H "Authorization: Bearer $TOKEN" \
    -F "file_type=opus" \
    -F "file_name=voice.ogg" \
    -F "duration=$DURATION_MS" \
    -F "file=@$VOICE_FILE")

  FILE_KEY=$(echo "$UPLOAD_RESP" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('data',{}).get('file_key',''))")

  if [ -z "$FILE_KEY" ]; then
    echo "❌ 上传失败：$UPLOAD_RESP"
    exit 1
  fi

  echo "✅ 上传成功：file_key=$FILE_KEY"

  # 发送语音消息
  echo "📮 正在发送语音..."
  SEND_RESP=$(curl -s -X POST "https://open.feishu.cn/open-apis/im/v1/messages?receive_id_type=open_id" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"receive_id\":\"$RECEIVE_ID\",\"msg_type\":\"audio\",\"content\":\"{\\\"file_key\\\":\\\"$FILE_KEY\\\"}\"}")

  echo "📬 发送结果：$SEND_RESP"
fi

# 清理
rm -f "$VOICE_FILE"

echo ""
echo "✅ 天气报告生成完成！"
echo ""
echo "=== 详细报告 ==="
echo "$TEXT_REPORT"
