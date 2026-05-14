import { HdsTabs } from '@hms.hds.hdsBaseComponent';
import {
  hdsMaterial, HdsTabsController
} from '@kit.UIDesignKit';
import { curves } from '@kit.ArkUI';
import { ZSTabsItem, ZSTabsOptions } from '../common/TabsOptions';
import { getBaseContainerWidth, getBasePositions } from '../utils/getBaseinfo';
import { ZSTabsConstance } from '../common/constant';
import { HdsMiniBarButton } from './HdsMiniBarButton';
import { resourceType } from '../utils/tabtype';
import {
  ANIM_DURATION_ICON,
  ANIM_DURATION_NEAR_ANCHOR,
  ANIM_DURATION_RESET,
  ANIM_DURATION_SWITCH,
  BAR_BORDER_RADIUS,
  BAR_MOVING_HEIGHT,
  BAR_MOVING_WIDTH,
  BAR_RESTING_HEIGHT,
  BAR_RESTING_WIDTH,
  BLUR_AMOUNT,
  EDGE_DRAG_DAMPING,
  INDICATOR_CONTAINER_WIDTH,
  TAB_BAR_HEIGHT
} from '../constant/HTabsConstants';
import { calcAnchorPositions, calcSlotWidth } from '../utils/HTabsUtils';
import { HTabsIndicator } from '../utils/HTabsIndicator';

@ComponentV2
export struct HTabs {
  // ==================== 外部参数 ====================

  /** 页签配置项（标题、图标、颜色、内容构建器） */
  @Param @Require tabsOption: ZSTabsOptions
  /** 当前选中页签索引，通过 !! 双向绑定 */
  @Param currentIndex: number = 0
  /** 索引变化事件回调，通知父组件更新 currentIndex */
  @Event onCurrentIndexChange: (val: number) => void = (val: number) => {
  }

  // ==================== 布局常量 ====================

  /** 基础锚点位置数组（vp），根据页签数量计算 */
  private readonly BASE_POSITIONS: number[] = getBasePositions(this.tabsOption.tabItems.length)
  /** 基准容器宽度（vp），tabbar 的固定基础宽度 */
  private readonly BASE_CONTAINER_WIDTH: number = getBaseContainerWidth(this.tabsOption.tabItems.length)

  // ==================== 组件状态 ====================

  /** 指示器容器实时宽度，通过 onAreaChange 动态更新以适配不同屏幕 */
  @Local private indicatorContainerWidth: number = getBaseContainerWidth(this.tabsOption.tabItems.length)
  /** 指示器状态实例（@ObservedV2 类，@Trace 属性变化自动触发 UI 刷新） */
  private indicator: HTabsIndicator = new HTabsIndicator()
  /** HdsTabs 控制器，用于程序化切换页签 */
  private tabsController: HdsTabsController = new HdsTabsController()
  /** 当前激活的 tab 索引（由 HdsTabs onChange 更新） */
  @Local private activeTabIndex: number = 0
  /** 当前选中的 tab 索引（控制页签样式切换） */
  @Local selectedTabIndex: number = 0
  /** 页签标题数组 */
  private tabTitles: string[] = this.tabsOption.tabItems.map((item: ZSTabsItem) => item.title)
  /** 页签图标数组 */
  private tabIcons: Resource[] = this.tabsOption.tabItems.map((item: ZSTabsItem) => item.icon)

  // ==================== 布局计算 ====================

  /**
   * 计算实时锚点位置（基于容器宽度缩放）
   * @returns 缩放后的各页签锚点 X 坐标数组
   */
  private getAnchorPositions(): number[] {
    return calcAnchorPositions(this.indicatorContainerWidth, this.BASE_CONTAINER_WIDTH, this.BASE_POSITIONS);
  }

  /**
   * 获取当前选中页签的锚点 X 坐标
   */
  private getAnchorPosition(): number {
    return this.getAnchorPositions()[this.currentIndex];
  }

  /**
   * 计算页签插槽宽度（用于判断拖动切换的页签数量）
   */
  private getSlotWidth(): number {
    return calcSlotWidth(this.indicatorContainerWidth, this.BASE_CONTAINER_WIDTH);
  }

  // ==================== Tab 点击切换逻辑 ====================

  /**
   * 监听 activeTabIndex 变化（由 HdsTabs onChange 触发）
   * 实现指示器从旧锚点滑动到新锚点的完整动画序列：
   * 1. 指示器膨胀为移动态尺寸
   * 2. 通过 dragOffsetX 偏移量实现位置滑动
   * 3. 收缩回静止态尺寸
   */
  @Monitor("activeTabIndex")
  private onActiveTabChange(): void {
    // 手势拖动触发的切换由 onActionEnd 处理，此处跳过
    if (this.indicator.isProgrammaticChange) {
      return;
    }
    // 索引未变化，无需处理
    if (this.activeTabIndex === this.currentIndex) {
      return;
    }

    // 计算旧锚点到新锚点的偏移量
    const positions = this.getAnchorPositions();
    const oldAnchor = positions[this.currentIndex];
    const newAnchor = positions[this.activeTabIndex];
    const offset = oldAnchor - newAnchor;

    // 将指示器视觉位置固定在旧锚点处（通过偏移量补偿）
    this.indicator.dragOffsetX = offset;
    this.indicator.enterMoving(this.activeTabIndex);

    // 阶段1：膨胀 + 滑动到新锚点位置
    this.getUIContext().animateTo({ duration: ANIM_DURATION_SWITCH, curve: curves.springMotion() }, () => {
      this.indicator.animatedBarWidth = BAR_MOVING_WIDTH;
      this.indicator.animatedBarHeight = BAR_MOVING_HEIGHT;
      this.indicator.dragOffsetX = 0; // 偏移量归零 = 指示器到达新锚点
      this.indicator.displayIndex = this.activeTabIndex;
      this.onCurrentIndexChange(this.activeTabIndex); // 通知父组件更新 currentIndex
    });

    // 阶段2：收缩回静止态
    setTimeout(() => {
      this.indicator.isMoving = false;
      this.getUIContext().animateTo({ curve: curves.springMotion() }, () => {
        this.indicator.animatedBarWidth = BAR_RESTING_WIDTH;
        this.indicator.animatedBarHeight = BAR_RESTING_HEIGHT;
        this.indicator.resetDeformation();
        this.indicator.displayIndex = this.activeTabIndex;
      });
    }, ANIM_DURATION_SWITCH + 10);
  }

  // ==================== 生命周期 ====================

  aboutToAppear() {
  }

  aboutToDisappear() {
  }

  // ==================== UI 构建 ====================

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // HdsTabs 页签容器
      HdsTabs({
        controller: this.tabsController,
        index: this.activeTabIndex
      }) {
        ForEach(this.tabsOption.tabItems, (item: ZSTabsItem, index: number) => {
          TabContent() {
            item.builder.builder()
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
      // 页签点击切换事件
      .onChange((index: number) => {
        this.selectedTabIndex = index;
        this.activeTabIndex = index;
      })
      .barHeight(TAB_BAR_HEIGHT)
      .animationDuration(0) // 禁用默认动画，使用自定义液态动效
      .scrollable(false) // 禁用 tabbar 自身滚动，使用自定义拖动逻辑
      .vertical(false)
      .barPosition(BarPosition.End) // 页签位于底部
      .barOverlap(true) // 允许 tabbar 与内容重叠，实现沉浸效果
      // 悬浮样式：沉浸材质
      .barFloatingStyle({
        barWidth: {
          smallWidth: this.BASE_CONTAINER_WIDTH,
          mediumWidth: this.BASE_CONTAINER_WIDTH,
          largeWidth: this.BASE_CONTAINER_WIDTH
        },
        adaptToHandedness: true,
        lightColor: this.tabsOption.maskColor,
        barBottomMargin: this.tabsOption.barBottomMargin ?? ZSTabsConstance.barBottomMargin,
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        }
      })

      // 液态指示器容器（叠加在 tabbar 上方）
      Column() {
        Row() {
          Stack() {
            // 液态指示器按钮（HdsMiniBarButton 提供沉浸光感）
            HdsMiniBarButton({
              maskColor: '#00ffffff',
              barWidth: this.indicator.animatedBarWidth,
              barHeight: this.indicator.animatedBarHeight,
              materialType: hdsMaterial.MaterialType.IMMERSIVE,
              materialLevel: hdsMaterial.MaterialLevel.EXQUISITE,
            }) {
              // 指示器内部内容：图标 + 标题
              Column({ space: 0 }) {
                // 图标（支持 symbol 和 image 两种资源类型）
                if (this.tabIcons[this.indicator.displayIndex].type === resourceType.symbol) {
                  SymbolGlyph(this.tabIcons[this.indicator.displayIndex])
                    .fontSize(30)
                    .fontColor([this.tabsOption.tabItems[0].selectColor ??
                      this.tabsOption.tabItems[0].color])
                    .blur((this.indicator.isMoving && !this.indicator.isNearAnchor) ? BLUR_AMOUNT : 0)
                    .borderRadius(12)
                    .padding(2)
                    .animation({ duration: ANIM_DURATION_ICON, curve: Curve.Smooth })
                } else if (this.tabIcons[this.indicator.displayIndex].type === resourceType.image) {
                  Image(this.tabIcons[this.indicator.displayIndex])
                    .width(30)
                    .height(30)
                    .objectFit(ImageFit.Contain)
                    .fillColor(this.tabsOption.tabItems[0].selectColor ??
                      this.tabsOption.tabItems[0].color)
                    .blur((this.indicator.isMoving && !this.indicator.isNearAnchor) ? BLUR_AMOUNT : 0)
                    .borderRadius(12)
                    .padding(2)
                    .animation({ duration: ANIM_DURATION_ICON, curve: Curve.Smooth })
                }

                // 标题文本
                Text(this.tabTitles[this.indicator.displayIndex])
                  .fontSize(9)
                  .fontColor(this.tabsOption.tabItems[0].selectColor ??
                    this.tabsOption.tabItems[0].color)
                  .fontWeight(FontWeight.Normal)
                  .blur((this.indicator.isMoving && !this.indicator.isNearAnchor) ? BLUR_AMOUNT : 0)
                  .padding(2)
                  .borderRadius(15)
                  .animation({ curve: curves.springMotion() })
              }
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .width('100%')
              .height('100%')
              .borderRadius(BAR_BORDER_RADIUS)
            }

            // 半透明遮罩层（增强指示器层次感）
            Row() {
            }
            .width(BAR_RESTING_WIDTH)
            .height(BAR_RESTING_HEIGHT)
            .borderRadius(BAR_BORDER_RADIUS)
            .backgroundColor(Color.Transparent)
            .animation({ curve: curves.springMotion() })
          }
          .borderRadius(BAR_BORDER_RADIUS)
          .clip(false) // 不裁剪，允许指示器溢出以增强液态质感
          .width(80)
          .height(80)
        }
        .borderRadius(BAR_BORDER_RADIUS)
        .clip(false)
        .translate({ x: this.indicator.dragOffsetX }) // 拖动偏移量控制指示器水平位移
        // 水平拖动手势
        .gesture(
          PanGesture({ direction: PanDirection.Horizontal })
            // 拖动开始：进入移动态
            .onActionStart(() => {
              this.indicator.enterMoving(this.currentIndex);
              this.getUIContext().animateTo({ curve: curves.springMotion() }, () => {
                this.indicator.animatedBarWidth = BAR_MOVING_WIDTH;
                this.indicator.animatedBarHeight = BAR_MOVING_HEIGHT;
              });
            })
            // 拖动更新：实时计算形变、偏移、锚点检测
            .onActionUpdate((event: GestureEvent) => {
              const velocity = event.offsetX - this.indicator.lastOffsetX;
              this.indicator.lastOffsetX = event.offsetX;

              // 速度形变（液态拉伸/收缩效果）
              if (this.indicator.isMoving) {
                this.indicator.updateVelocityDeformation(velocity);
              }

              // 边界衰减（首尾页签拖动时增加阻尼感）
              if (this.currentIndex === 0 && event.offsetX < 0) {
                this.indicator.dragOffsetX = event.offsetX * EDGE_DRAG_DAMPING;
              } else if (this.currentIndex === 3 && event.offsetX > 0) {
                this.indicator.dragOffsetX = event.offsetX * EDGE_DRAG_DAMPING;
              } else {
                this.indicator.dragOffsetX = event.offsetX;
              }

              // 检测是否靠近锚点（控制图标/文本模糊效果）
              if (this.indicator.isMoving) {
                const currentX = this.getAnchorPosition() + this.indicator.dragOffsetX;
                const changed = this.indicator.checkNearAnchor(currentX, this.getAnchorPositions());
                if (changed && !this.indicator.isMoving) {
                  this.getUIContext().animateTo({ duration: ANIM_DURATION_NEAR_ANCHOR, curve: Curve.EaseInOut }, () => {
                  });
                }
              }
            })
            // 拖动结束：判断是否切换页签
            .onActionEnd(() => {
              const slotWidth = this.getSlotWidth();
              const movedSlots = Math.round(this.indicator.dragOffsetX / slotWidth);
              let newIndex = this.currentIndex + movedSlots;
              newIndex = Math.max(0, Math.min(3, newIndex));

              if (newIndex !== this.currentIndex) {
                // 切换页签：滑动到新锚点 → 收缩 → 同步状态
                this.indicator.isProgrammaticChange = true;
                this.indicator.isMoving = true;
                this.getUIContext().animateTo({ duration: ANIM_DURATION_SWITCH, curve: curves.springMotion() }, () => {
                  this.onCurrentIndexChange(newIndex);
                  this.indicator.displayIndex = newIndex;
                  this.indicator.dragOffsetX = 0;
                });
                setTimeout(() => {
                  this.indicator.enterResting(newIndex);
                  this.tabsController.changeIndex(newIndex);
                  this.selectedTabIndex = newIndex;
                  this.activeTabIndex = newIndex;
                  this.getUIContext().animateTo({ curve: curves.springMotion() }, () => {
                    this.indicator.animatedBarWidth = BAR_RESTING_WIDTH;
                    this.indicator.animatedBarHeight = BAR_RESTING_HEIGHT;
                    this.indicator.resetDeformation();
                    this.indicator.displayIndex = newIndex;
                  });
                }, ANIM_DURATION_SWITCH + 10);
              } else {
                // 未切换：回弹到当前锚点
                this.indicator.isMoving = false;
                this.getUIContext().animateTo({ duration: ANIM_DURATION_RESET, curve: curves.springMotion() }, () => {
                  this.indicator.animatedBarWidth = BAR_RESTING_WIDTH;
                  this.indicator.animatedBarHeight = BAR_RESTING_HEIGHT;
                  this.indicator.resetDeformation();
                  this.indicator.dragOffsetX = 0;
                });
              }
            })
        )
        // 指示器位置绑定当前锚点
        .position({
          x: this.getAnchorPosition()
        })
        .animation({ curve: curves.springMotion() })
      }
      .margin({ bottom: this.tabsOption.barBottomMargin ?? ZSTabsConstance.barBottomMargin })
      .width(INDICATOR_CONTAINER_WIDTH)
      .height(TAB_BAR_HEIGHT)
      .clip(false)
      .hitTestBehavior(HitTestMode.Transparent) // 透明点击，不影响底层 tabbar
      .backgroundColor(Color.Transparent)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      // 容器尺寸变化时更新宽度，用于动态适配
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        const newWidth = Number(newValue.width);
        if (newWidth > 0 && Math.abs(newWidth - this.indicatorContainerWidth) > 0.5) {
          this.indicatorContainerWidth = newWidth;
        }
      })
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  // ==================== 页签样式构建器 ====================

  /**
   * 单个页签的图标 + 文本样式
   * 根据选中状态切换颜色和字体粗细
   */
  @Builder
  TabItemBuilder(title: string, icon: string | Resource, index: number, color: ResourceColor,
    selectColor: ResourceColor) {
    Column() {
      // 图标（字符串 / symbol / image）
      if (typeof icon === 'string') {
        Text(icon)
          .fontSize(24)
          .fontColor(index === this.selectedTabIndex ? selectColor : color)
          .margin({ bottom: 2 })
      } else {
        if (icon.type === resourceType.symbol) {
          SymbolGlyph(icon)
            .fontSize(25)
            .fontColor([index === this.selectedTabIndex ? selectColor : color])
        } else if (icon.type === resourceType.image) {
          Image(icon)
            .width(25)
            .height(25)
            .objectFit(ImageFit.Contain)
            .margin({ bottom: 2 })
            .fillColor(index === this.selectedTabIndex ? selectColor : color)
        }
      }
      // 标题
      Text(title)
        .fontSize(10)
        .fontColor(index === this.selectedTabIndex ? selectColor : color)
        .fontWeight(this.selectedTabIndex === index ? FontWeight.Bold : FontWeight.Regular)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
  }
}
