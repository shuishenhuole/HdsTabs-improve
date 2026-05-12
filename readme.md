# ZSTabs - 沉浸式液态指示器TabBar


## 特性

### 🎨 沉浸式光感效果
- 使用HarmonyOS Design System的沉浸材质（IMMERSIVE + EXQUISITE）
- 实现玻璃质感的液态指示器
- 支持点光源照明效果

### 💧 液态交互体验
- 拖动时指示器产生液态拉伸/收缩效果
- 根据滑动速度动态调整形变程度
- 滑动时图标/文本模糊效果，增强液态感
- 智能吸附到最近页签锚点

### 🏗️ 状态管理V2
- 使用最新的 `@ComponentV2` 装饰器
- `@Local` 替代传统 `@State` 状态管理
- `@Monitor` 替代 `@Watch` 监听器
- 符合HarmonyOS最新规范

### 📦 常量化管理
- 所有配置参数集中管理在 `constant.ets`
- 6个常量类分类管理：
  - `TabConstants`: TabBar基础配置
  - `IndicatorConstants`: 指示器尺寸参数
  - `VelocityConstants`: 速度与形变参数
  - `AnimationConstants`: 动画时长配置
  - `ColorConstants`: 颜色配置
  - `TabConfig`: 页签标题和图标
- 便于修改和维护

### ⚡ 最新API适配
- 使用 `getUIContext().animateTo()` 替代全局 `animateTo()`
- 符合HarmonyOS API最新规范
- 更好的UI上下文管理


## 致谢

本项目基于 [对沉浸光感tabbar的优化改造](https://developer.huawei.com/consumer/cn/blog/topic/03212848303315412) 进行重构和优化。
