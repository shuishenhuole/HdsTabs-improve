import { HdsNavigation, HdsTabs, ScrollEffectType } from '@hms.hds.hdsBaseComponent';
import { hdsMaterial, HdsNavigationTitleMode, HdsTabsController } from '@kit.UIDesignKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { curves } from '@kit.ArkUI';
import { TabConstants, IndicatorConstants, VelocityConstants, AnimationConstants, ColorConstants, TabConfig } from '../common/constant';
import { HdsMiniBarButton } from 'hds_button';


@ComponentV2
export struct ZSTabs {
  @Local private indicatorContainerWidth: number = TabConstants.BASE_CONTAINER_WIDTH;

  /**
   * 计算实时锚点位置
   * 基于当前容器宽度与基准宽度的比例，对基础锚点位置进行缩放，实现适配
   * @returns 缩放后的4个页签锚点位置数组
   */
  private getAnchorPositions(): number[] {
    const scale = this.indicatorContainerWidth / TabConstants.BASE_CONTAINER_WIDTH;
    return TabConstants.BASE_POSITIONS.map(p => p * scale);
  }

  /**
   * 获取当前选中页签的锚点位置
   * @returns 当前选中索引对应的锚点X坐标（vp）
   */
  private getAnchorPosition(): number {
    const positions = this.getAnchorPositions();
    return positions[this.currentIndicatorIndex];
  }

  /**
   * 计算页签插槽宽度
   * 基于容器宽度缩放，确保插槽宽度与容器尺寸适配，用于判断滑动切换的页签数量
   * @returns 实时插槽宽度（vp）
   */
  private getSlotWidth(): number {
    return this.indicatorContainerWidth * (TabConstants.SLOT_WIDTH_RATIO / TabConstants.BASE_CONTAINER_WIDTH);
  }

  // 当前指示器吸附位置索引（0-3，对应4个页签）
  @Local private currentIndicatorIndex: number = 0;
  @Local private dragOffsetX: number = 0;
  @Local private isMoving: boolean = false;
  @Local private animatedBarWidth: number = IndicatorConstants.BASE_WIDTH;
  @Local private animatedBarHeight: number = IndicatorConstants.BASE_HEIGHT;
  @Local private isProgrammaticChange: boolean = false;
  @Local private lastOffsetX: number = 0;
  @Local private currentVelocity: number = 0;
  @Local private velocityDeformationWidth: number = 0;
  @Local private velocityDeformationHeight: number = 0;
  @Local private smoothedVelocity: number = 0;
  // 本次拖动/停顿后的初始方向：1=右，-1=左，0=未设置，用于控制形变方向
  private initialDragDirection: number = 0;
  // 上次有显著速度时的时间戳（ms），用于检测滑动停顿
  private lastActiveTimestamp: number = 0;
  private pauseDetected: boolean = false;
  @Local private isNearAnchor: boolean = false;
  @Local private displayIndex: number = 0;

  // HdsTabs控制器，用于控制tabbar的页签切换
  private tabsController: HdsTabsController = new HdsTabsController();
  @Local private activeTabIndex: number = 0;
  @Local currentTabIndex: number = 0;
  @Local selectedTabIndex: number = 0;

  private tabTitles: string[] = TabConfig.TITLES;
  private tabIcons: Resource[] = TabConfig.ICONS;


  /**
   * 激活页签变化监听函数
   * 当页签通过点击切换时，同步移动指示器至对应位置，触发液态动效
   */
  @Monitor('activeTabIndex')
  private onActiveTabChange(): void {
    // 若为程序控制移动，直接返回，避免重复处理
    if (this.isProgrammaticChange) return;
    // 若当前激活索引与指示器索引一致，无需处理
    if (this.activeTabIndex === this.currentIndicatorIndex) return;

    // 标记为移动状态，触发材质与尺寸变化
    this.isMoving = true;
    // 执行指示器移动动画，时长300ms，使用弹簧曲线，确保动效流畅
    this.getUIContext().animateTo({ duration: AnimationConstants.SWITCH_DURATION, curve: curves.springMotion() }, () => {
      this.currentIndicatorIndex = this.activeTabIndex; // 同步指示器索引
      this.displayIndex = this.activeTabIndex; // 同步显示的页签图标/文本
      this.dragOffsetX = 0; // 重置偏移量，回到锚点位置
    });
    // 动画结束后，重置移动状态（延迟310ms，确保动画完全执行）
    setTimeout(() => {
      this.isMoving = false;
    }, AnimationConstants.SETTLE_DELAY);
  }

  /**
   * 移动状态变化监听函数
   * 当isMoving状态改变时，调整指示器的尺寸、形变及模糊效果，实现液态静止/流动切换
   */
  @Monitor('isMoving')
  private onIsMovingChange(): void {
    // 在状态变化前启动动画，然后修改尺寸参数
    this.getUIContext().animateTo({ 
      curve: curves.springMotion(), 
      duration: AnimationConstants.SWITCH_DURATION 
    }, () => {
      if (!this.isMoving) {
        this.animatedBarWidth = IndicatorConstants.BASE_WIDTH;
        this.animatedBarHeight = IndicatorConstants.BASE_HEIGHT;
        this.velocityDeformationWidth = 0;
        this.velocityDeformationHeight = 0;
        this.currentVelocity = 0;
        this.smoothedVelocity = 0;
        this.displayIndex = this.currentIndicatorIndex;
      } else {
        this.animatedBarWidth = IndicatorConstants.MOVING_WIDTH;
        this.animatedBarHeight = IndicatorConstants.MOVING_HEIGHT;
      }
    });
    
    if (!this.isMoving) {
      this.initialDragDirection = 0;
      this.lastActiveTimestamp = 0;
      this.pauseDetected = false;
    }
  }

  /**
   * 更新速度引起的形变效果
   * 根据滑动速度，计算指示器的宽度/高度形变量，模拟液态流动的拉伸/收缩效果
   * @param velocity 当前滑动速度（vp/帧）
   */
  private updateVelocityDeformation(velocity: number): void {
    this.currentVelocity = velocity; // 更新当前速度
    const smoothingFactor = VelocityConstants.SMOOTHING_FACTOR;
    this.smoothedVelocity = this.smoothedVelocity * (1 - smoothingFactor) + velocity * smoothingFactor;
    const absVelocity = Math.abs(this.smoothedVelocity); // 速度绝对值
    const now = Date.now(); // 当前时间戳

    // 若速度大于停顿阈值，更新最后活跃时间戳
    if (absVelocity >= VelocityConstants.PAUSE_THRESHOLD) {
      this.lastActiveTimestamp = now;
    }

    if (this.lastActiveTimestamp > 0 && absVelocity < VelocityConstants.PAUSE_THRESHOLD) {
      const elapsed = now - this.lastActiveTimestamp;
      if (elapsed >= VelocityConstants.PAUSE_DURATION_MS) {
        this.pauseDetected = true; // 标记为停顿
        this.initialDragDirection = 0; // 重置初始方向
        this.lastActiveTimestamp = 0; // 重置活跃时间戳
      }
    }

    // 速度低于阈值，取消形变，重置尺寸
    if (absVelocity < VelocityConstants.THRESHOLD) {
      this.velocityDeformationWidth = 0;
      this.velocityDeformationHeight = 0;
      this.animatedBarWidth = IndicatorConstants.MOVING_WIDTH;
      this.animatedBarHeight = IndicatorConstants.MOVING_HEIGHT;
      return;
    }

    // 若未设置初始方向，或检测到停顿，重新设置初始拖动方向
    if (this.initialDragDirection === 0 || this.pauseDetected) {
      this.initialDragDirection = this.smoothedVelocity > 0 ? 1 : -1;
      this.pauseDetected = false;
    }

    // 归一化速度（映射到0-1区间），并通过开方实现缓动效果，让形变更自然
    const normalizedVelocity = Math.min(absVelocity / VelocityConstants.NORMALIZE_BASE, 1);
    const easedVelocity = Math.sqrt(normalizedVelocity);
    const deformAmount = easedVelocity * VelocityConstants.MAX_DEFORM;
    const currentDirection = this.smoothedVelocity > 0 ? 1 : -1; // 当前拖动方向
    const isSameDirection = currentDirection === this.initialDragDirection; // 是否与初始方向一致

    // 根据拖动方向调整形变方向，模拟液态流动的拉伸效果
    if (isSameDirection) {
      this.velocityDeformationWidth = deformAmount; // 同方向：宽度拉伸，高度收缩
      this.velocityDeformationHeight = -deformAmount * 0.5;
    } else {
      this.velocityDeformationWidth = -deformAmount * 0.5; // 反方向：宽度收缩，高度拉伸
      this.velocityDeformationHeight = deformAmount;
    }

    // 更新指示器最终尺寸（基础尺寸+形变量）
    this.animatedBarWidth = IndicatorConstants.MOVING_WIDTH + this.velocityDeformationWidth;
    this.animatedBarHeight = IndicatorConstants.MOVING_HEIGHT + this.velocityDeformationHeight;
  }

  /**
   * 检测是否靠近锚点
   * 实时计算当前指示器位置与所有锚点的距离，判断是否靠近某个锚点，同步更新显示索引和模糊效果
   */
  private checkIfNearAnchor(): void {
    const currentX = this.getAnchorPosition() + this.dragOffsetX; // 当前指示器实时X坐标
    const positions = this.getAnchorPositions(); // 所有锚点位置

    let nearestDistance = Infinity; // 最近距离，初始设为无穷大
    let nearestIndex: number = this.currentIndicatorIndex; // 最近锚点索引，初始为当前索引

    // 遍历所有锚点，找到距离当前位置最近的锚点
    for (let i = 0; i < positions.length; i++) {
      const distance = Math.abs(currentX - positions[i]);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    const wasNearAnchor = this.isNearAnchor; // 上一次的靠近状态
    const wasDisplayIndex = this.displayIndex; // 上一次的显示索引
    // 更新靠近状态（距离小于阈值则视为靠近）和显示索引（最近锚点索引）
    this.isNearAnchor = nearestDistance <= VelocityConstants.ANCHOR_THRESHOLD;
    this.displayIndex = nearestIndex;

    // 若靠近状态发生变化且非移动状态，执行轻微动画，提升过渡流畅度
    if (wasNearAnchor !== this.isNearAnchor && !this.isMoving) {
      this.getUIContext().animateTo({ duration: AnimationConstants.PROXIMITY_DURATION, curve: Curve.EaseInOut }, () => {});
    }
  }

  /**
   * 组件即将显示时触发
   * 可在此处添加初始化逻辑（如获取设备尺寸、初始化参数等）
   */
  aboutToAppear() {

  }

  /**
   * 组件即将消失时触发
   * 可在此处添加资源释放、状态重置等逻辑
   */
  aboutToDisappear() {

  }

  /**
   * 组件构建函数，渲染tabbar整体布局、指示器及页签内容
   */
  build() {
    // 外层Stack，将内容对齐到底部，贴合tabbar的底部导航定位
    Stack({alignContent:Alignment.Bottom}){
      // 适配HarmonyOS 6.1及以上版本（API 60100+），使用HdsNavigation和HdsTabs构建基础导航
      if (deviceInfo.distributionOSApiVersion >= 60100) {
        HdsNavigation() {
          // HdsTabs组件，作为页签容器，绑定控制器和当前激活索引
          HdsTabs({
            controller: this.tabsController,
            index: this.activeTabIndex  // 绑定当前激活的页签索引
          }) {
            // 第1个页签内容（可根据实际需求填充页面内容）
            TabContent() {

            }
            .tabBar(this.TabItemBuilder('首页', $r('sys.media.ohos_ic_public_remove'), 0)) // 绑定页签样式构建器

            // 第2个页签内容
            TabContent() {

            }
            .tabBar(this.TabItemBuilder('二页', $r('sys.media.ohos_ic_public_remove'), 1))

            // 第3个页签内容
            TabContent() {

            }
            .tabBar(this.TabItemBuilder('三页', $r('sys.media.ohos_ic_public_remove'), 2))

            // 第4个页签内容
            TabContent() {

            }
            .tabBar(this.TabItemBuilder('四页', $r('sys.media.ohos_ic_public_remove'), 3))

          }
          // 页签切换事件监听，同步选中索引和激活索引
          .onSelected((index: number) => {
            this.selectedTabIndex = index;
            this.activeTabIndex = index;
          })
          .barHeight(TabConstants.BAR_HEIGHT)
          .animationDuration(0) // 禁用默认动画，使用自定义液态动效
          .scrollable(false) // 禁用tabbar自身滚动，使用自定义拖动逻辑
          .vertical(false) // 横向排列页签
          .barPosition(BarPosition.End) // 页签位于底部
          .barOverlap(true) // 允许tabbar与内容重叠，实现沉浸效果
          // 悬浮样式配置，设置tabbar的宽度、间距、颜色及沉浸材质
          .barFloatingStyle({
            barWidth: {
              smallWidth: TabConstants.BAR_WIDTH_SMALL,
              mediumWidth: TabConstants.BAR_WIDTH_MEDIUM,
              largeWidth: TabConstants.BAR_WIDTH_LARGE
            },
            adaptToHandedness: true,
            lightColor: ColorConstants.LIGHT_COLOR,
            barBottomMargin: TabConstants.BAR_BOTTOM_MARGIN,
            // 系统材质效果，设置为沉浸光感，精致级别，贴合HarmonyOS 6设计语言
            systemMaterialEffect: {
              materialType: hdsMaterial.MaterialType.IMMERSIVE,
              materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
            }
          })
        }
        .height('100%')
        .width('100%')
        .mode(NavigationMode.Stack) // 导航模式为栈模式
        .hideBackButton(false) // 显示返回按钮（可根据需求调整）
        .titleMode(HdsNavigationTitleMode.MODAL) // 标题模式为模态
        // 标题栏配置，设置滚动效果和沉浸材质，与tabbar风格统一
        .titleBar({
          content: {
            title: {
              mainTitle: '', // 标题为空，可根据实际需求设置
            },
          },
          style: {
            scrollEffectOpts: {
              enableScrollEffect: true,
              scrollEffectType: ScrollEffectType.IMMERSIVE_GRADIENT_BLUR, // 沉浸式渐变模糊效果
            },
            systemMaterialEffect: {
              materialType: hdsMaterial.MaterialType.IMMERSIVE,
              materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
            },
          },
          avoidLayoutSafeArea: false, // 不避开布局安全区，实现全屏沉浸
          enableComponentSafeArea: false
        })
        // 忽略系统安全区（顶部和底部），让导航栏和tabbar完全贴合屏幕
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
      }


      // 液态指示器容器，用于承载指示器和拖动手势
      Column() {
        Row() {
          Stack() {
            // 液态指示器核心组件（HdsMiniBarButton），实现沉浸光感和液态样式
            HdsMiniBarButton({
              maskColor: ColorConstants.MASK_COLOR,
              barWidth: this.animatedBarWidth, // 动态宽度，随滑动状态变化
              barHeight: this.animatedBarHeight, // 动态高度，随滑动状态变化
              // 材质类型和级别，移动与静止状态保持一致，确保沉浸质感统一
              materialType: this.isMoving
                ? hdsMaterial.MaterialType.IMMERSIVE
                : hdsMaterial.MaterialType.IMMERSIVE,
              materialLevel: this.isMoving
                ? hdsMaterial.MaterialLevel.EXQUISITE
                : hdsMaterial.MaterialLevel.EXQUISITE,
            })
            {
              // 指示器内部内容：图标+文本，与当前显示索引同步
              Column({ space: 0 }) {
                // 页签图标，根据显示索引切换，滑动时（未靠近锚点）添加模糊效果
                Image(this.tabIcons[this.displayIndex])
                  .width(IndicatorConstants.ICON_SIZE)
                  .height(IndicatorConstants.ICON_SIZE)
                  .objectFit(ImageFit.Contain)
                  .fillColor(ColorConstants.ICON_COLOR)
                  .blur((this.isMoving && !this.isNearAnchor) ? AnimationConstants.BLUR_AMOUNT : 0)
                  .borderRadius(IndicatorConstants.ICON_BORDER_RADIUS)
                  .padding(IndicatorConstants.ICON_PADDING)
                  .animation({ duration: AnimationConstants.ICON_ANIMATION_DURATION, curve: Curve.Smooth })

                // 页签文本，与图标同步，滑动时添加模糊效果
                Text(this.tabTitles[this.displayIndex])
                  .fontSize(IndicatorConstants.TEXT_SIZE)
                  .fontColor(ColorConstants.TEXT_COLOR)
                  .fontWeight(FontWeight.Normal)
                  .blur((this.isMoving && !this.isNearAnchor) ? AnimationConstants.BLUR_AMOUNT : 0)
                  .padding(IndicatorConstants.TEXT_PADDING)
                  .borderRadius(IndicatorConstants.TEXT_BORDER_RADIUS)
                  .animation({curve:curves.springMotion()}) // 文本切换动画
              }
              .justifyContent(FlexAlign.Center) // 垂直居中
              .alignItems(HorizontalAlign.Center) // 水平居中
              .width('100%')
              .height('100%')
              .borderRadius(IndicatorConstants.BORDER_RADIUS)


            }

            // 半透明遮罩，用于增强指示器的层次感，静止时显示，移动时透明
            Row() {}
            .width(IndicatorConstants.MASK_WIDTH)
            .height(IndicatorConstants.MASK_HEIGHT)
            .borderRadius(IndicatorConstants.BORDER_RADIUS)
            .backgroundColor(this.isMoving ? ColorConstants.MASK_COLOR : Color.Transparent)
            .animation({curve:curves.springMotion()}) // 遮罩切换动画
          }
          .borderRadius(IndicatorConstants.BORDER_RADIUS)
          .clip(false)
          .width(IndicatorConstants.CONTAINER_WIDTH)
          .height(IndicatorConstants.CONTAINER_HEIGHT)
        }
        .clip(false)
        .translate({ x: this.dragOffsetX }) // 跟随拖动偏移量移动
        .gesture(
          // 水平拖动手势，用于控制指示器滑动
          PanGesture({ direction: PanDirection.Horizontal })
          // 拖动开始：初始化移动状态和相关参数
            .onActionStart(() => {
              this.isMoving = true;
              this.lastOffsetX = 0;
              this.currentVelocity = 0;
              this.smoothedVelocity = 0;
              this.displayIndex = this.currentIndicatorIndex;
              this.initialDragDirection = 0;
              this.lastActiveTimestamp = 0;
              this.pauseDetected = false;
            })
            // 拖动更新：实时计算速度、更新形变、调整偏移量、检测锚点
            .onActionUpdate((event: GestureEvent) => {
              const velocity = event.offsetX - this.lastOffsetX; // 计算当前速度
              this.lastOffsetX = event.offsetX; // 更新上一帧偏移量

              // 移动状态下，更新速度形变
              if (this.isMoving) {
                this.updateVelocityDeformation(velocity);
              }

              // 边界处理：第一个页签向左拖动、最后一个页签向右拖动时，偏移量衰减（增强手感）
              if (this.currentIndicatorIndex === 0 && event.offsetX < 0) {
                this.dragOffsetX = event.offsetX * VelocityConstants.BOUNDARY_DECAY;
              } else if (this.currentIndicatorIndex === TabConstants.TAB_COUNT - 1 && event.offsetX > 0) {
                this.dragOffsetX = event.offsetX * VelocityConstants.BOUNDARY_DECAY;
              } else {
                this.dragOffsetX = event.offsetX; // 正常拖动，直接赋值偏移量
              }

              // 移动状态下，检测是否靠近锚点
              if (this.isMoving) {
                this.checkIfNearAnchor();
              }
            })
            // 拖动结束：根据拖动距离判断是否切换页签，复位指示器位置
            .onActionEnd(() => {
              this.isMoving = false;
              const slotWidth = this.getSlotWidth(); // 获取页签插槽宽度
              // 计算拖动的页签数量（四舍五入，超过半格则切换页签）
              const movedSlots = Math.round(this.dragOffsetX / slotWidth);
              // 计算新的页签索引，限制在0-3之间（避免越界）
              let newIndex = this.currentIndicatorIndex + movedSlots;
              newIndex = Math.max(0, Math.min(TabConstants.TAB_COUNT - 1, newIndex));

              // 若索引发生变化，执行页签切换动画
              if (newIndex !== this.currentIndicatorIndex) {
                this.isProgrammaticChange = true; // 标记为程序控制移动
                this.isMoving = true;
                // 指示器移动到新锚点位置，动画时长300ms
                this.getUIContext().animateTo({ duration: AnimationConstants.SWITCH_DURATION, curve: curves.springMotion() }, () => {
                  this.currentIndicatorIndex = newIndex;
                  this.displayIndex = newIndex;
                  this.dragOffsetX = 0; // 复位偏移量
                });
                // 动画结束后，重置状态，同步tab控制器和选中索引
                setTimeout(() => {
                  this.isMoving = false;
                  this.isProgrammaticChange = false;
                  this.tabsController.changeIndex(newIndex); // 切换tab页
                  this.selectedTabIndex = newIndex;
                  this.activeTabIndex = newIndex;
                }, 310);
              } else {
                // 索引未变化，仅复位偏移量，回到当前锚点
                this.getUIContext().animateTo({ duration: AnimationConstants.RESET_DURATION, curve: curves.springMotion() }, () => {
                  this.dragOffsetX = 0;
                });
              }
            })
        )
        // 指示器的初始位置，绑定当前锚点位置
        .position({
          x: this.getAnchorPosition()
        })
        .animation({curve:curves.springMotion()}) // 位置变化动画，确保流畅
      }
      .margin({ bottom: 0 })
      .width(TabConstants.BASE_CONTAINER_WIDTH)
      .height(TabConstants.BAR_HEIGHT)
      .clip(false) // 不裁剪，允许指示器溢出
      .hitTestBehavior(HitTestMode.Transparent) // 透明点击，不影响底层tabbar点击
      .backgroundColor(Color.Transparent) // 透明背景，实现沉浸效果
      // 扩展系统安全区（底部），避免被系统导航栏遮挡
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
      // 容器尺寸变化监听，动态调整指示器容器宽度，适配不同设备
      .onAreaChange((_oldValue: Area, newValue: Area) => {
        const newWidth = Number(newValue.width);
        if (newWidth > 0 && Math.abs(newWidth - this.indicatorContainerWidth) > 0.5) {
          this.indicatorContainerWidth = newWidth;
        }
      })
    }
    .width('100%')
    .height('100%')
    // 扩展系统安全区（底部），确保整个布局不被遮挡
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }

  /**
   * 页签样式构建器（@Builder装饰器，复用页签样式）
   * 用于生成每个页签的图标+文本样式，根据选中状态切换样式（颜色、字体粗细）
   * @param title 页签文本
   * @param icon 页签图标（资源或字符串）
   * @param index 页签索引
   */
  @Builder
  TabItemBuilder(title: string, icon: string | Resource, index: number) {
    Column() {
      // 处理图标类型（字符串图标/资源图标），根据选中状态切换颜色
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
      // 页签文本，根据选中状态切换颜色和字体粗细
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

}
