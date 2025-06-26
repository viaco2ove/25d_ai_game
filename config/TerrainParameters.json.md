{
  "biomes": {
	"火山": {
	  "base_color": [0.8, 0.7, 0.4],
	  "elevation": {
		"type": ["活火山"],
		"intensity_range": [0.7, 1.0]
	  }
	},
	"魔法森林": {
	  "base_color": [0.8, 0.7, 0.4],
	  "elevation": {
		"type": ["火山", "积雪火山", "丘陵"],
		"intensity_range": [0.3, 0.8]
	  },
	  "water": {
		"type": ["河流", "湖泊"],
		"coverage_range": [0.0, 0.5]
	  },
	  "vegetation": {
		"density_range": [0.5, 1.0],
		"base_color": "#3a5f0b"
	  },
	  "atmosphere": {
		"light": ["白天", "黄昏", "夜晚"],
		"weather": ["晴朗", "雾", "雨"]
	  }
	},
	"沙漠": {
	  "base_color": [0.8, 0.7, 0.4],
	  "elevation": {
		"type": ["沙丘", "平顶山"],
		"intensity_range": [0.0, 0.3]
	  },
	  "water": {
		"type": ["绿洲"],
		"coverage_range": [0.0, 0.1]
	  },
	  "vegetation": {
		"density_range": [0.0, 0.2],
		"base_color": "#d8ca9d"
	  },
	  "atmosphere": {
		"light": ["白天"],
		"weather": ["晴朗", "沙尘暴"]
	  }
	}, 
	"冰原": {
	  "base_color": [0.95, 0.95, 0.98],
	  "elevation": {
		"type": ["冰川", "冰丘"],
		"intensity_range": [0.5, 1.0]
	  },
	  "water": {
		"type": ["冰湖"],
		"coverage_range": [0.1, 0.4]
	  },
	  "vegetation": {
		"density_range": [0.0, 0.1],
		"base_color": "#e0f7fa"
	  }
	}
  }
}
