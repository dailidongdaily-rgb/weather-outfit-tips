# 天气 API 参考

## Open-Meteo (推荐)

免费、无需 API Key、支持逐小时预报

### 逐小时预报
```
https://api.open-meteo.com/v1/forecast?latitude=31.2222&longitude=121.4581&hourly=temperature_2m,weathercode,precipitation_probability,windspeed_10m&timezone=Asia%2FShanghai&forecast_days=2
```

### 参数说明
- `latitude` - 纬度
- `longitude` - 经度
- `hourly` - 逐小时数据字段（逗号分隔）
- `timezone` - 时区
- `forecast_days` - 预报天数（最多 16 天）

### 天气代码 (weathercode)
| 代码 | 含义 |
|------|------|
| 0 | 晴朗 |
| 1-3 | 多云 |
| 45-48 | 雾 |
| 51-55 | 毛毛雨 |
| 61-65 | 雨 |
| 71-77 | 雪 |
| 80-82 | 阵雨 |
| 95-99 | 雷雨 |

文档：https://open-meteo.com/en/docs

## wttr.in (备用)

### 快速查询
```bash
curl -s "wttr.in/Shanghai?format=3"
# 输出：Shanghai: ☀️ +16°C
```

### 详细预报
```bash
curl -s "wttr.in/Shanghai?0"
```

文档：https://wttr.in/:help
