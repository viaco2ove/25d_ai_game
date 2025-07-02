# TerrainParameters.json 使用说明
改進方案：
1，完全數據庫化，不再使用json 文件,直接保存在資源庫中
2，分爲系統biome配置和用户biome配置,都有多個生物群系（biome）配置方案
3.每個故事都可以配置自己的生物群系（biome）

## 文件作用
定义地图生成中生物群系（biome）的核心参数，包括：
- 地形特征（高程、水体、植被）
- 环境效果（光照、天气）
- 群系间关系（位置规则）

現在精簡為只有base_color 屬性，其他的由ai 生成為
地圖數據services/ai_service_v3.gd。

## 配置文件结构

### 1. 生物群系定义 (`biomes`)
### 2. 地形特征配置
#### 高程 (`elevation`)
- **type**：允许的地形类型数组
- **intensity_range**：地形强度变化范围 [最小值, 最大值]

#### 水体 (`water`)
- **type**：允许的水体类型数组
- **coverage_range**：水体覆盖率范围 [最小值, 最大值]

#### 植被 (`vegetation`)
- **density_range**：植被密度范围 [最小值, 最大值]
- **base_color**：基础颜色（RGB数组或十六进制）

### 3. 环境效果 (`atmosphere`)
- **light**：允许的光照类型数组
- **weather**：允许的天气类型数组

### 4. 位置规则 (`position_rules`)
- **reference_points**：参考点类型数组
- **distance_range**：与参考点的距离范围 [最小值, 最大值]

### 5. 定居点配置 (`settlements`)
- **type**：允许的定居点类型数组
- **density_range**：定居点密度范围 [最小值, 最大值]

## 配置示例
## 使用建议
1. **颜色格式**：
    - RGB数组：`[R, G, B]` (值范围0.0-1.0)
    - 十六进制：`"#3a5f0b"`

2. **范围定义**：
    - 使用双元素数组表示最小/最大值
    - 例如 `"intensity_range": [0.3, 0.8]`

3. **类型引用**：
    - 所有类型需与 `ResourceBindings.json` 中的定义一致
    - 如 `"火山"` 需在资源绑定中有对应模型

4. **简化配置**：
    - 当前生成器仅使用 `base_color`
    - 其他配置项为未来扩展保留

> 修改后需在Godot编辑器中重新加载资源，通过 `MapGenerator.gd` 测试生成效果
