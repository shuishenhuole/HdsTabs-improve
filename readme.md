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

### ⚡ 最新API适配
- 使用 `getUIContext().animateTo()` 替代全局 `animateTo()`
- 符合HarmonyOS API最新规范
- 更好的UI上下文管理


## 安装

```bash
ohpm install @shuishenhuole/zstabs
```

## 使用示例

```typescript
import { ZSTabs } from '@shuishenhuole/zstabs'

@Builder
function HomeBuilder(){
  Stack(){
    Text("Hello world HomeBuilder")
  }
}

@Builder
function PageOneBuilder(){
  Stack(){
    Text("Hello world PageOneBuilder")
  }
}

@Builder
function PageTwoBuilder(){
  Stack(){
    Text("Hello world PageTwoBuilder")
  }
}

@Builder
function PageThreeBuilder(){
  Stack(){
    Text("Hello world PageThreeBuilder")
  }
}
@Entry
@ComponentV2
struct Index {
  @Local Index:number = 0
  build() {
    Column(){
      ZSTabs({
        currentIndex:this.Index!!,
        tabsOption:{
          tabItems:[
            {
              title:"首页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.symbol.message'),
              builder:wrapBuilder(HomeBuilder),
            },
            {
              title:"第一页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(PageOneBuilder),
            },
            {
              title:"第二页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(PageTwoBuilder)
            },
            {
              title:"第三页",
              color:$r('sys.color.icon'),
              selectColor:$r('sys.color.warning'),
              icon:$r('sys.media.ohos_ic_public_remove'),
              builder:wrapBuilder(PageThreeBuilder)
            },
          ],
          maskColor:"#8d5ce7"
        }
      })
    }
  }
}
```

## 配置项说明

### 核心组件ZSTabs
| 参数 | 类型            | 必填 | 默认值 | 说明                    |
|------|---------------|------|--------|-----------------------|
| currentIndex | number        | 是 | - | tabbar的当前页索引 使用!!双向绑定 |
| tabsOption | tabsOption    | 是 | - | tab的配置项               |
| maskColor | ResourceColor | 否 | 20 | 按压的光感颜色               |


### ZSTabsOptions

| 参数 | 类型 | 必填 | 默认值 | 说明                      |
|------|------|------|--------|-------------------------|
| tabItems | ZSTabsItem[] | 是 | - | Tab页签配置数组 目前支持的数组长度为2-4 |
| barBottomMargin | number \| Resource | 否 | 20 | TabBar底部间距              |

### ZSTabsItem

| 参数          | 类型 | 必填     | 默认值 | 说明 |
|-------------|------|--------|--------|------|
| title       | string | 是      | - | 页签标题文本 |
| icon        | Resource| string | 是 | - | 页签图标资源 支持image和symbol资源 |
| color       | ResourceColor | 是      | - | 页签未选中时的颜色 |
| selectColor | ResourceColor | 否      | - | 页签选中时的颜色 |
| builder     | WrappedBuilder<[]> | 是      | - | 页签内容构建器 |

### 兼容性
液态效果仅在api23及以上可用

如果低于版本会只用默认tabs
如果需要对tabs实现一次开发多端部署(小屏幕在低下显示在底部，在大屏幕显示在左侧边)
可以在EntryAbility.ets加入

EntryAbility.ets
```typescript
onWindowStageCreate(windowStage: window.WindowStage): void {
  ...
  ZSBreakPoint.init(windowStage)
  ...
    });
  }
```
## 致谢

本项目基于 [对沉浸光感tabbar的优化改造](https://developer.huawei.com/consumer/cn/blog/topic/03212848303315412) 进行重构和优化。

核心光感来自[hds_button](https://ohpm.openharmony.cn/#/cn/detail/hds_button) 感谢开源