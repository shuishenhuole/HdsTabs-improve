import { WidthBreakPoint } from "@shuishenhuole/breakpoint"
import { ZSTabsItem, ZSTabsOptions } from "../common/TabsOptions"

@ComponentV2
export struct DTabs {
  @Param @Require tabsOption: ZSTabsOptions
  // 当前指示器吸附位置索引（0-3，对应4个页签）
  @Param currentIndex: number = 0
  @Event onCurrentIndexChange: (val: number) => void = (val: number) => {
  }

  build() {
    Tabs({
      barPosition: new WidthBreakPoint<BarPosition>({
        lg: BarPosition.Start,
        xl: BarPosition.Start,
        default:BarPosition.End
      }).getValue(),
      index: this.currentIndex!!
    }) {
      ForEach(this.tabsOption.tabItems, (item: ZSTabsItem, index: number) => {
        TabContent() {
          Column(){
            item.builder.builder()
            Text(this.currentIndex.toString())
          }
        }
        .tabBar(this.TabItemBuilder(
          item.title,
          item.icon,
          index,
          item.color,
          item.selectColor ?? item.color
        ))
      })
    }
    .vertical(new WidthBreakPoint<boolean>({
      lg:true,
      xl:true,
      default:false
    }).getValue())
    .onChange((val:number)=>{
      this.onCurrentIndexChange(val)
    })
  }

  /**
   * 页签样式构建器（@Builder装饰器，复用页签样式）
   * 用于生成每个页签的图标+文本样式，根据选中状态切换样式（颜色、字体粗细）
   * @param title 页签文本
   * @param icon 页签图标（资源或字符串）
   * @param index 页签索引
   */
  @Builder
  TabItemBuilder(title: string, icon: string | Resource, index: number, color: ResourceColor,
    selectColor: ResourceColor) {
    Column() {
      // 处理图标类型（字符串图标/资源图标），根据选中状态切换颜色
      if (typeof icon === 'string') {
        Text(icon)
          .fontSize(24)
          .fontColor(index === this.currentIndex ? selectColor : color)
          .margin({ bottom: 2 })
      } else {
        Image(icon)
          .width(25)
          .height(25)
          .objectFit(ImageFit.Contain)
          .margin({ bottom: 2 })
          .fillColor(index === this.currentIndex ? selectColor : color)
      }
      // 页签文本，根据选中状态切换颜色和字体粗细
      Text(title)
        .fontSize(10)
        .fontColor(index === this.currentIndex ? selectColor : color)
        .fontWeight(this.currentIndex === index ? FontWeight.Bold : FontWeight.Regular)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}