import { HdsMiniBarButton } from 'hds_button';
import { hdsMaterial } from '@kit.UIDesignKit';
import { curves } from '@kit.ArkUI';
import { IndicatorConstants, AnimationConstants, ColorConstants } from '../common/constant';

/**
 * 液态指示器组件
 * 实现沉浸光感和液态形变效果的指示器
 */
@ComponentV2
export struct LiquidIndicator {
  /** 指示器宽度 */
  @Param barWidth: number = IndicatorConstants.BASE_WIDTH;
  /** 指示器高度 */
  @Param barHeight: number = IndicatorConstants.BASE_HEIGHT;
  /** 是否处于移动状态 */
  @Param isMoving: boolean = false;
  /** 是否靠近锚点 */
  @Param isNearAnchor: boolean = false;
  /** 当前显示的图标 */
  @Param icon: Resource;
  /** 当前显示的标题 */
  @Param title: string;

  build() {
    Stack() {
      // 液态指示器核心组件
      HdsMiniBarButton({
        maskColor: ColorConstants.MASK_COLOR,
        barWidth: this.barWidth,
        barHeight: this.barHeight,
        materialType: hdsMaterial.MaterialType.IMMERSIVE,
        materialLevel: hdsMaterial.MaterialLevel.EXQUISITE,
      })
      {
        // 指示器内部内容：图标+文本
        Column({ space: 0 }) {
          // 页签图标
          Image(this.icon)
            .width(IndicatorConstants.ICON_SIZE)
            .height(IndicatorConstants.ICON_SIZE)
            .objectFit(ImageFit.Contain)
            .fillColor(ColorConstants.ICON_COLOR)
            .blur((this.isMoving && !this.isNearAnchor) ? AnimationConstants.BLUR_AMOUNT : 0)
            .borderRadius(IndicatorConstants.ICON_BORDER_RADIUS)
            .padding(IndicatorConstants.ICON_PADDING)
            .animation({ duration: AnimationConstants.ICON_ANIMATION_DURATION, curve: Curve.Smooth })

          // 页签文本
          Text(this.title)
            .fontSize(IndicatorConstants.TEXT_SIZE)
            .fontColor(ColorConstants.TEXT_COLOR)
            .fontWeight(FontWeight.Normal)
            .blur((this.isMoving && !this.isNearAnchor) ? AnimationConstants.BLUR_AMOUNT : 0)
            .padding(IndicatorConstants.TEXT_PADDING)
            .borderRadius(IndicatorConstants.TEXT_BORDER_RADIUS)
            .animation({ curve: curves.springMotion() })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .height('100%')
        .borderRadius(IndicatorConstants.BORDER_RADIUS)

      }

      // 半透明遮罩层
      Row() {}
        .width(IndicatorConstants.MASK_WIDTH)
        .height(IndicatorConstants.MASK_HEIGHT)
        .borderRadius(IndicatorConstants.BORDER_RADIUS)
        .backgroundColor(this.isMoving ? ColorConstants.MASK_COLOR : Color.Transparent)
        .animation({ curve: curves.springMotion() })
    }
    .borderRadius(IndicatorConstants.BORDER_RADIUS)
    .clip(false)
    .width(IndicatorConstants.CONTAINER_WIDTH)
    .height(IndicatorConstants.CONTAINER_HEIGHT)
    .animation({ curve: curves.springMotion(), duration: AnimationConstants.SWITCH_DURATION })
  }
}