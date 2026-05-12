/**
 * 页签项构建器
 * 用于生成每个页签的图标+文本样式
 */
@Builder
export function TabItemBuilder(title: string, icon: string | Resource) {
  Column() {
    if (typeof icon === 'string') {
      Text(icon)
        .fontSize(24)
        .fontColor($r('sys.color.icon'))
        .margin({ bottom: 2 })
    } else {
      Image(icon)
        .width(25)
        .height(25)
        .objectFit(ImageFit.Contain)
        .margin({ bottom: 2 })
        .fillColor($r('sys.color.icon'))
    }
    Text(title)
      .fontSize(10)
      .fontColor($r('sys.color.icon'))
      .fontWeight(FontWeight.Bold)
  }
  .width('100%')
  .height('100%')
  .alignItems(HorizontalAlign.Center)
  .justifyContent(FlexAlign.Center)
}