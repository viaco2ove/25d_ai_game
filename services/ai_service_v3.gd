#ai_service_v3.gd
extends Node

const SILICONFLOW_API = "https://api.siliconflow.cn/v1/chat/completions"  # 硅基流动 API 地址 [5](@ref)
var api_key = ""  # 从外部配置读取

const MapConfig = preload("res://config/MapConfig.gd")


func _ready():
	print("user://config.cfg 实际路径为：",OS.get_user_data_dir()  + "/config.cfg")

	var config_manager = ConfigManager.new()
	var config = config_manager.load_config()

	if config:
		api_key = config.get_value("api", "siliconflow_key", "")
		if api_key == "":
			push_warning("API密钥为空，请检查配置文件")
	else:
		push_error("无法加载配置文件")

func _load_json(path: String) -> Dictionary:
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("配置文件不存在: " + path)
		return {}

	var json_text = file.get_as_text()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		var error_line = json.get_error_line()
		var error_msg = json.get_error_message()
		push_error("JSON解析失败！路径: %s, 行: %d, 错误: %s" % [path, error_line, error_msg])
		return {}

	return json.data		

#biome地形类型：biome_mapping
#elevation地形特征：elevation_mapping
#water水域类型：water_mapping
#vegetation植被：vegetation_mapping
#atmospheres时间天气：light_settings，weather_settings
#settlements建筑：settlements_mapping	
# 地形解析函数（对接硅基流动 DeepSeek-V3 Pro）
# 地形解析函数（改进版）
func analyze_terrain(prompt: String) -> Dictionary:
	# 获取地图配置
	var map_config = MapConfig.new()
	map_config.load_from_json("res://config/map_config.json")
	
	# 获取资源绑定配置
	var resource_bindings = _load_json("res://config/ResourceBindings.json")
	if resource_bindings.empty():
		push_error("无法加载ResourceBindings.json")
		return {}

	# 获取地图配置
	var category_mappings = [
							resource_bindings["biome_mapping"],
							resource_bindings["elevation_mapping"],
							resource_bindings["water_mapping"],
							resource_bindings["vegetation_mapping"],
							resource_bindings["settlements_mapping"]
							]

	var available_models = []
	for mapping in category_mappings:
		for model in mapping.values():
			if not model in available_models:
				available_models.append(model)

	
	var available_model_types=["biome","elevation","water","vegetation","settlements"]
	#首先我认为需要告诉ai 有哪些素材模型，地图有多大。
	#ai 返回的数据也要更精确需要位置，范围。
	#不在使用coverage，density 等模糊的参数。
	var system_prompt = """
		你是一个专业的地形生成AI，请将用户描述转换为JSON格式的地形参数（不要包含任何Markdown或代码块）：
		地图尺寸：{size_x}x{size_z}单位（坐标原点在中心）
		x轴范围：{x_min} 到 {x_max}
		z轴范围：{z_min} 到 {z_max}
		
		可用素材模型：
		[
			{model_list}
		]
		
		可用元素类型：
		[
			{model_type}
		]
		
		返回JSON结构：
		{
			"biome": {
				"biome_type":"地形类型(如:魔法森林/沙漠/冰原)",
				"base_color": "HEX颜色"
			},
			"elements": [
				{
					"mode_type": "元素类型(如:elevation/water)",
					"mode_name": "元素名称(如:森林/山脉)",
					"position": {"x": 精确X坐标, "z": 精确Z坐标},  // 范围: -10 到 10
					"size": {"width": 宽度, "depth": 深度},	  // 单位尺寸
					"rotation": 旋转角度(0-360)				 // 可选
				},
				// ...更多元素
			],
			"atmosphere": {
				"light": "白天/夜晚/黄昏",
				"weather": "晴朗/雾/雨"
			}
		}
		
		位置生成规则：
		- "远处" -> x/z在 ±6-10 范围内
		- "近处" -> x/z在 ±0-3 范围内
		- "左侧" -> x < 0
		- "右侧" -> x > 0
		""".format({
		"size_x": map_config.get_size().x,
		"size_z": map_config.get_size().y,
		"x_min": map_config.get_range("x").x,
		"x_max": map_config.get_range("x").y,
		"z_min": map_config.get_range("z").x,
		"z_max": map_config.get_range("z").y,
		"model_type": "\n\t\t".join(available_model_types),  # 动态生成模型类型列表
		"model_list": "\n\t\t".join(available_models),  # 动态生成模型列表
	})

	var request = {
					  "model": "Pro/deepseek-ai/DeepSeek-V3",
					  "messages": [
						  {"role": "system", "content": system_prompt},
						  {"role": "user", "content": prompt}
					  ],
					  "temperature": 0.3,
					  "max_tokens": 500  
	}

	# 重试机制
	var retry_count = 0
	while retry_count < 3:
		var response = await _send_siliconflow_request(request)
		print("response：",response)
		if response.has("error"):
			push_warning("AI请求失败: " + response.error)
			retry_count += 1
			await get_tree().create_timer(1.0).timeout
		else:
			# 提取实际的 JSON 数据（去除 Markdown 代码块）
			var raw_content = response.choices[0].message.content
			var json_content = raw_content
			
			# 尝试去除 Markdown 代码块
			if "json" in raw_content:
				json_content = raw_content.replace("json", "").replace("", "").strip_edges()
			elif "" in raw_content: 
				json_content = raw_content.replace("", "").strip_edges()
				
			print("处理后的JSON内容: ", json_content)
			# 使用新的 JSON 解析方式
			var json = JSON.new()
			var parse_error = json.parse(json_content)

			if parse_error == OK:
				# 获取解析后的数据
				var parsed_data = json.get_data()
				if parsed_data is Dictionary:
					return parsed_data
				else:
					push_error("解析结果不是字典类型: ", response.choices[0].message.content)
			else:
				push_error("JSON解析失败: ", json.get_error_message(), " at line ", json.get_error_line())

			return {}  # 失败时返回空字典

	return {}  # 失败时返回空字典


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

	# 解析响应体
	var response_text = result[3].get_string_from_utf8()
	var json = JSON.new()
	var parse_error = json.parse(response_text)

	if parse_error == OK:
		var response_body = json.get_data()
		return response_body if "choices" in response_body else {"error": "API响应格式错误"}
	else:
		return {"error": "JSON解析失败: " + json.get_error_message()}
