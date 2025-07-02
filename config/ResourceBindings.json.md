# ResourceBindings.json 使用说明
改進方案：
1，完全數據庫化，不再使用json 文件,模型文件也需保存在資源庫中
2，分爲系統配置和用户配置,都有多個資源綁定方案
3.每個故事都可以配置自己的資源绑定

## 文件作用
`ResourceBindings.json` 是地图生成系统的核心配置文件，用于定义：
1. **模型资源路径** - 将抽象元素类型映射到具体模型文件
2. **材质属性** - 定义不同元素的视觉表现
3. **光照设置** - 控制场景光照效果
4. **天气效果** - 配置雾效、粒子系统等环境效果

## 配置文件结构

### 1. 模型绑定 (`model_bindings`)
```
 "model_bindings": { "森林": "res://kenney_pirate-kit/Models/OBJ format/grass-patch.obj", "山脉": "res://kenney_pirate-kit/Models/OBJ format/rocks-sand-a.obj", "河流": "res://kenney_nature-kit/Models/OBJ format/ground_pathBend.obj" }
````

- **键值对结构**：`"元素类型": "模型文件路径"`
- **支持类型**：植被、地形、水体等地图元素
- **路径要求**：使用Godot支持的资源路径格式（如`.obj`）

### 2. 材质配置 (`material_cache`)

- **材质属性**：
	- `albedo_color`：基础颜色 (RGB数组或十六进制)
	- `roughness`：粗糙度 (0.0-1.0)
	- `metallic`：金属感 (0.0-1.0)
- **支持类型**：按元素类型或生物群系配置

### 3. 光照设置 (`light_settings`)
- **参数说明**：
	- `rotation`：光源旋转角度 (X,Y,Z)
	- `color`：光照颜色 (RGB)
	- `energy`：光照强度
- **预设类型**：白天、黄昏、夜晚等

### 4. 天气效果 (`weather_settings`)
- **雾效参数**：
	- `fog_enabled`：是否启用
	- `fog_color`：雾颜色
	- `fog_start/fog_end`：雾效范围
- **粒子系统**：
	- `particles_enabled`：是否启用
	- `particle_material`：粒子材质路径
	- `particle_amount`：粒子数量

## 使用建议

### 1. 路径管理
- 所有路径使用 `res://` 开头的相对路径
- 模型文件建议放在 `kenney_pirate-kit/Models/` 目录
- 天气材质放在 `addons/GodotWeatherSystem/weather/`

### 2. 配置更新流程
1. 修改 `ResourceBindings.json`
2. 在Godot编辑器中重新加载资源
3. 运行 `MapGenerator.gd` 测试效果
4. 调试不匹配的资源绑定

### 3. 版本控制
- 使用带下划线前缀的字段(`_back`)备份旧配置
- 注释掉暂时不用的配置项（使用`//`）

> 完整配置示例见项目中的 `ResourceBindings.json` 文件，调试工具在 `MapGenerator.gd` 中实现
