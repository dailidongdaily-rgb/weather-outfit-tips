#!/bin/bash
# 智能穿衣天气提醒脚本
# 用法：./get_outfit_tips.sh [城市] [纬度] [经度]

CITY="${1:-北京}"
LAT="${2:-39.9042}"
LON="${3:-116.4074}"

# 获取逐小时预报
FORECAST=$(curl -s "https://api.open-meteo.com/v1/forecast?latitude=${LAT}&longitude=${LON}&hourly=temperature_2m,weathercode,precipitation_probability,windspeed_10m&timezone=Asia%2FShanghai&forecast_days=2")

# 获取当前小时
CURRENT_HOUR=$(date +%H)

# 解析当前天气
CURRENT_TEMP=$(echo "$FORECAST" | python3 -c "
import json, sys
data = json.load(sys.stdin)
hour = int('${CURRENT_HOUR}')
temps = data['hourly']['temperature_2m']
print(int(temps[hour]))
")

CURRENT_WEATHER=$(echo "$FORECAST" | python3 -c "
import json, sys
data = json.load(sys.stdin)
hour = int('${CURRENT_HOUR}')
codes = data['hourly']['weathercode']
code = codes[hour]
if code == 0: print('晴朗')
elif code <= 3: print('多云')
elif code <= 61: print('小雨')
else: print('雷雨')
")

# 生成穿衣建议
if [ "$CURRENT_TEMP" -lt 5 ]; then
    OUTFIT="羽绒服/厚棉服 + 毛衣 + 保暖内衣"
elif [ "$CURRENT_TEMP" -lt 10 ]; then
    OUTFIT="厚外套/大衣 + 毛衣/卫衣"
elif [ "$CURRENT_TEMP" -lt 15 ]; then
    OUTFIT="风衣/薄外套 + 长袖 T 恤"
elif [ "$CURRENT_TEMP" -lt 20 ]; then
    OUTFIT="长袖 T 恤/薄衬衫 + 单裤"
elif [ "$CURRENT_TEMP" -lt 25 ]; then
    OUTFIT="短袖 T 恤 + 薄裤/裙子"
else
    OUTFIT="短袖 + 短裤/裙子，注意防晒"
fi

echo "城市：${CITY}"
echo "当前温度：${CURRENT_TEMP}°C"
echo "天气：${CURRENT_WEATHER}"
echo "穿衣建议：${OUTFIT}"
