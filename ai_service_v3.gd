ai_service_v3.gd
const SILICONFLOW_API = "https://api.siliconflow.cn/v1/chat/completions"  # 硅基流动 API 地址 [5](@ref)
var api_key = ""  # 从外部配置读取

func _ready():
    var config = ConfigFile.new()
    var err = config.load("user://config.cfg")
    if err == OK:
        api_key = config.get_value("api", "siliconflow_key", "")
    else:
        push_warning("API配置文件未找到，请创建user://config.cfg")

# 地形解析函数（对接硅基流动 DeepSeek-V3 Pro）
func analyze_terrain(prompt: String) -> Dictionary:
    var system_prompt = """
    你是一个专业的地形生成AI，请将用户描述转换为JSON格式的地形参数：
    {
        "biome": "地形类型(如:魔法森林/沙漠/冰原)",
        "elevation": {"type": "地形特征", "intensity": 0.0-1.0},
        "water": {"type": "水域类型", "coverage": 0.0-1.0},
        "vegetation": {"density": 0.0-1.0, "color": "HEX颜色"},
        "atmosphere": {"light": "白天/夜晚/黄昏", "weather": "晴朗/雾/雨"}
    }
    """

    var request = {
        "model": "Pro/deepseek-ai/DeepSeek-V3",  # 硅基流动 Pro 版模型 [5](@ref)
        "messages": [
            {"role": "system", "content": system_prompt},
            {"role": "user", "content": prompt}
        ],
        "temperature": 0.3,
        "max_tokens": 300
    }

    # 重试机制
    var retry_count = 0
    while retry_count < 3:
        var response = await _send_siliconflow_request(request)
        if response.has("error"):
            push_warning("AI请求失败: " + response.error)
            retry_count += 1
            await get_tree().create_timer(1.0).timeout
        else:
            return JSON.parse_string(response.choices[0].message.content)

    return {}  # 失败时返回空

# 硅基流动 API 请求函数
func _send_siliconflow_request(request_data: Dictionary) -> Dictionary:
    var headers = [
        "Content-Type: application/json",
        "Authorization: Bearer " + api_key  # 从外部注入的 Key
    ]

    var http_request = HTTPRequest.new()
    add_child(http_request)

    var error = http_request.request(
        SILICONFLOW_API,
        headers,
        HTTPClient.METHOD_POST,
        JSON.stringify(request_data)
    )

    if error != OK:
        return {"error": "HTTP请求初始化失败"}

    var result = await http_request.request_completed
    http_request.queue_free()

    if result[0] != HTTPRequest.RESULT_SUCCESS:
        return {"error": "网络错误: " + str(result[0])}

    var response_body = JSON.parse_string(result[3].get_string_from_utf8())
    return response_body if "choices" in response_body else {"error": "API响应格式错误"}