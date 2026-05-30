import { hdsMaterial, HdsTabs } from '@kit.UIDesignKit';

/**
 * HdsMiniBarButton 液态玻璃浮动按钮组件
 * 使用 HdsTabs 的 systemMaterialEffect 实现液态玻璃质感
 * 通过空 tabBar + Stack 分层避免黑框问题
 */
@ComponentV2
export struct HdsMiniBarButton {
  // ==================== 尺寸参数 ====================

  /**
   * 按钮宽度
   * @default 50
   */
  @Param barWidth: number = 50;

  /**
   * 按钮高度
   * @default 50
   */
  @Param barHeight: number = 50;

  /**
   * 容器内边距
   * @default 0
   */
  @Param contentPadding: number = 0;

  /**
   * 容器尺寸，优先使用此值，未设置时自动计算
   * @default undefined
   */
  @Param containerSize: SizeOptions | undefined = undefined;

  // ==================== 图标参数 ====================

  /**
   * 图标资源
   * @default $r('sys.symbol.plus')
   */
  @Param iconResource: Resource = $r('sys.symbol.plus');

  /**
   * 图标大小
   * @default 27
   */
  @Param iconSize: number = 27;

  /**
   * 图标颜色数组
   * @default [Color.Gray]
   */
  @Param iconColor: ResourceColor[] = [Color.Gray];

  // ==================== 材质参数 ====================

  /**
   * 遮罩颜色
   * @default Color.Transparent
   */
  @Param maskColor: ResourceColor = Color.Transparent;

  /**
   * 按钮栏底部边距
   * @default 0
   */
  @Param barBottomMargin: number = 0;

  /**
   * 材质类型
   * @default hdsMaterial.MaterialType.IMMERSIVE
   */
  @Param materialType: hdsMaterial.MaterialType = hdsMaterial.MaterialType.IMMERSIVE;

  /**
   * 材质级别
   * @default hdsMaterial.MaterialLevel.EXQUISITE
   */
  @Param materialLevel: hdsMaterial.MaterialLevel = hdsMaterial.MaterialLevel.EXQUISITE;

  // ==================== 事件回调 ====================

  /**
   * 按钮点击事件回调
   * @default undefined
   */
  @Param onButtonClick: (() => void) | undefined = undefined;

  // ==================== 构建函数 ====================

  /**
   * 默认按钮图标构建函数
   */
  @Builder
  defaultButtonBuilder() {
    SymbolGlyph(this.iconResource)
      .fontSize(this.iconSize)
      .fontColor(this.iconColor)
  }

  /**
   * 自定义内容槽位
   */
  @BuilderParam buttonContent: () => void = this.defaultButtonBuilder;

  /**
   * 空 tabBar，避免 HdsTabs 渲染多余的选中态高亮块
   */
  @Builder
  emptyTabBar() {
    Row() {}
    .width(0)
    .height(0)
    .backgroundColor(Color.Transparent)
  }

  // ==================== 私有方法 ====================

  /**
   * 计算容器尺寸
   */
  private getComputedContainerSize(): SizeOptions {
    if (this.containerSize !== undefined) {
      return this.containerSize;
    }
    return {
      width: this.barWidth + this.contentPadding * 2,
      height: this.barHeight + this.contentPadding * 2
    };
  }

  // ==================== UI 构建 ====================

  /**
   * 构建组件 UI
   * 底层 HdsTabs 提供材质效果，顶层 Stack 放置自定义内容
   */
  build() {
    Stack({ alignContent: Alignment.Center }) {
      // 底层：HdsTabs 提供 systemMaterialEffect 液态玻璃材质
      HdsTabs() {
        TabContent()
          .tabBar(this.emptyTabBar())
      }
      .barWidth(this.barWidth)
      .barHeight(this.barHeight)
      .barOverlap(true)
      .barPosition(BarPosition.End)
      .barFloatingStyle({
        gradientMask: {
          maskColor: this.maskColor
        },
        barBottomMargin: this.barBottomMargin,
        systemMaterialEffect: {
          materialType: this.materialType,
          materialLevel: this.materialLevel
        }
      })
      .hitTestBehavior(HitTestMode.Transparent)
      .borderRadius(this.barHeight / 2)
      .clip(true)

      // 顶层：自定义内容悬浮在材质上方
      Row() {
        this.buttonContent()
      }
      .width(this.barWidth)
      .height(this.barHeight)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .hitTestBehavior(HitTestMode.Transparent)
    }
    .size(this.getComputedContainerSize())
    .padding(this.contentPadding)
    .onClick(() => {
      if (this.onButtonClick) {
        this.onButtonClick();
      }
    })
  }
}
