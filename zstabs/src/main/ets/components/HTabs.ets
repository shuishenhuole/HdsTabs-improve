import { HdsTabs } from '@hms.hds.hdsBaseComponent';
import {
  hdsEffect,
  hdsMaterial,
  HdsTabsController
} from '@kit.UIDesignKit';
import { deviceInfo } from '@kit.BasicServicesKit'; // 设备信息工具，用于适配不同设备
import { HdsMiniBarButton } from 'hds_button'; // 液态指示器核心按钮组件
import { curves } from '@kit.ArkUI';
import { ZSTabsItem, ZSTabsOptions } from '../common/TabsOptions';
import { getBaseContainerWidth, getBasePositions } from '../utils/getBaseinfo';
import { ZSTabsConstance } from '../common/constant';

@ComponentV2
export struct HTabs {
  @Param @Require tabsOption: ZSTabsOptions
  // 当前指示器吸附位置索引（0-3，对应4个页签）
  @Param currentIndicatorIndex: number = 0
  @Event $currentIndicatorIndex: (val: number) => void = (val: number) => {
  }
  // 点光源照明类型，控制指示器高光效果，此处设为边框+内容同时照明
  @Local illuminatedType: hdsEffect.PointLightIlluminatedType = hdsEffect.PointLightIlluminatedType.BORDER_CONTENT;
  // 基础锚点位置（vp），对应4个页签的初始位置，基于基准容器宽度计算
  private readonly BASE_POSITIONS: number[] = getBasePositions(this.tabsOption.tabItems.length)
  // 基准容器宽度（vp），为tabbar的固定基础宽度
  private readonly BASE_CONTAINER_WIDTH: number = getBaseContainerWidth(this.tabsOption.tabItems.length)
  // 指示器容器实时宽度，用于适配不同设备/屏幕尺寸的动态调整
  @Local private indicatorContainerWidth: number = getBaseContainerWidth(this.tabsOption.tabItems.length)

  /**
   * 计算实时锚点位置
   * 基于当前容器宽度与基准宽度的比例，对基础锚点位置进行缩放，实现适配
   * @returns 缩放后的4个页签锚点位置数组
   */
  private getAnchorPositions(): number[] {
    const scale = this.indicatorContainerWidth / this.BASE_CONTAINER_WIDTH;
    return this.BASE_POSITIONS.map(p => p * scale);
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
    return this.indicatorContainerWidth * (90 / this.BASE_CONTAINER_WIDTH);
  }


  // 拖动时的实时X轴偏移量（vp），控制指示器滑动位置
  @Local private dragOffsetX: number = 0;
  // 控制材质切换（拖动/程序移动时为true，静止时为false），绑定监听函数onIsMovingChange
  @Local private isMoving: boolean = false;
  // 指示器动态宽度（vp），随滑动状态变化，实现液态拉伸/收缩效果
  @Local private animatedBarWidth: number = 92;
  // 指示器动态高度（vp），与宽度联动，同步实现液态形变
  @Local private animatedBarHeight: number = 54;
  // 标记是否为程序控制的指示器移动（非用户拖动），用于避免重复触发事件
  @Local private isProgrammaticChange: boolean = false;
  // 上一帧的偏移量，用于计算滑动速度
  @Local private lastOffsetX: number = 0;
  // 当前滑动速度（vp/帧），用于控制液态形变程度
  @Local private currentVelocity: number = 0;
  // 速度引起的宽度形变量（vp），随速度变化，模拟液态流动拉伸
  @Local private velocityDeformationWidth: number = 0;
  // 速度引起的高度形变量（vp），与宽度形变反向，增强液态真实感
  @Local private velocityDeformationHeight: number = 0;
  // 移动时指示器的基础宽度（vp）
  private readonly BASE_MOVING_WIDTH: number = 110;
  // 移动时指示器的基础高度（vp）
  private readonly BASE_MOVING_HEIGHT: number = 74.5;
  // 最大速度形变量（vp），限制形变范围，避免过度拉伸/收缩
  private readonly MAX_VELOCITY_DEFORM: number = 45;
  // 速度阈值（vp/帧），低于此值不产生形变，避免微小滑动触发不必要的动画
  private readonly VELOCITY_THRESHOLD: number = 0.1;
  // 速度归一化基准值（vp/帧），用于将实际速度映射到0-1区间，控制形变程度
  private readonly VELOCITY_NORMALIZE_BASE: number = 25;
  // 平滑后的速度值，用于减少速度波动，让液态形变更流畅
  @Local private smoothedVelocity: number = 0;
  // 本次拖动/停顿后的初始方向：1=右，-1=左，0=未设置，用于控制形变方向
  private initialDragDirection: number = 0;
  // 上次有显著速度时的时间戳（ms），用于检测滑动停顿
  private lastActiveTimestamp: number = 0;
  // 是否检测到停顿（停顿后视为新的拖动开始）
  private pauseDetected: boolean = false;
  // 停顿判定时长（ms），超过该时长无显著速度则视为停顿
  private readonly PAUSE_DURATION_MS: number = 80;
  // 停顿判定的速度阈值（vp/帧），低于此值视为静止
  private readonly PAUSE_VELOCITY_THRESHOLD: number = 0.3;
  // 是否靠近锚点（用于控制图标/文本的模糊效果，靠近时取消模糊）
  @Local private isNearAnchor: boolean = false;
  // 实时显示的锚点索引（滑动过程中动态更新，用于同步显示当前靠近的页签图标/文本）
  @Local private displayIndex: number = 0;
  // 锚点接近阈值（vp），距离锚点小于该值则视为靠近锚点
  private readonly ANCHOR_PROXIMITY_THRESHOLD: number = 28;
  // HdsTabs控制器，用于控制tabbar的页签切换
  private tabsController: HdsTabsController = new HdsTabsController();
  // 当前激活的tab索引，绑定监听函数onActiveTabChange，同步指示器位置
  @Local private activeTabIndex: number = 0;
  // 控制TabContent页面显示的索引，与选中页签同步
  @Local currentTabIndex: number = 0;
  // 选中的tab索引，用于控制页签图标/文本的样式切换（填充/镂空、颜色变化）
  @Local selectedTabIndex: number = 0;
  // 页签标题数组，对应4个页签的文本
  private tabTitles: string[] = this.tabsOption.tabItems.map((item: ZSTabsItem) => item.title)
  // 页签图标数组，对应4个页签的图标资源
  private tabIcons: Resource[] = this.tabsOption.tabItems.map((item: ZSTabsItem) => item.icon)

  /**
   * 激活页签变化监听函数
   * 当页签通过点击切换时，同步移动指示器至对应位置，触发液态动效
   */
  @SyncMonitor("activeTabIndex")
  private onActiveTabChange(): void {
    // 若为程序控制移动，直接返回，避免重复处理
    if (this.isProgrammaticChange) {
      return;
    }
    // 若当前激活索引与指示器索引一致，无需处理
    if (this.activeTabIndex === this.currentIndicatorIndex) {
      return;
    }

    // 标记为移动状态，触发材质与尺寸变化
    this.isMoving = true;
    // 执行指示器移动动画，时长300ms，使用弹簧曲线，确保动效流畅
    curves.springMotion()
    this.getUIContext().animateTo({ duration: 300, curve: curves.springMotion() }, () => {
      this.$currentIndicatorIndex(this.activeTabIndex) // 同步指示器索引
      this.displayIndex = this.activeTabIndex; // 同步显示的页签图标/文本
      this.dragOffsetX = 0; // 重置偏移量，回到锚点位置
    });
    // 动画结束后，重置移动状态（延迟310ms，确保动画完全执行）
    setTimeout(() => {
      this.isMoving = false;
    }, 310);
  }

  /**
   * 移动状态变化监听函数
   * 当isMoving状态改变时，调整指示器的尺寸、形变及模糊效果，实现液态静止/流动切换
   */
  @SyncMonitor("isMoving")
  private onIsMovingChange(): void {
    // 静止状态：重置指示器尺寸、形变和速度，取消模糊效果
    this.getUIContext().animateTo({ curve: curves.springMotion() }, () => {
      if (!this.isMoving) {
        this.animatedBarWidth = 92; // 重置为静止时的宽度
        this.animatedBarHeight = 54; // 重置为静止时的高度
        this.velocityDeformationWidth = 0; // 重置宽度形变
        this.velocityDeformationHeight = 0; // 重置高度形变
        this.currentVelocity = 0; // 重置速度
        this.smoothedVelocity = 0; // 重置平滑速度
        this.displayIndex = this.currentIndicatorIndex; // 同步显示当前选中页签
        // 重置拖动相关参数，为下一次拖动做准备
        this.initialDragDirection = 0;
        this.lastActiveTimestamp = 0;
        this.pauseDetected = false;
      } else {
        // 移动状态：调整指示器为基础移动尺寸，准备形变
        this.animatedBarWidth = this.BASE_MOVING_WIDTH;
        this.animatedBarHeight = this.BASE_MOVING_HEIGHT;
      }
    });
  }

  /**
   * 更新速度引起的形变效果
   * 根据滑动速度，计算指示器的宽度/高度形变量，模拟液态流动的拉伸/收缩效果
   * @param velocity 当前滑动速度（vp/帧）
   */
  private updateVelocityDeformation(velocity: number): void {
    this.currentVelocity = velocity; // 更新当前速度
    const smoothingFactor = 0.3; // 速度平滑因子，减少波动
    // 平滑速度计算，避免速度突变导致形变生硬
    this.smoothedVelocity = this.smoothedVelocity * (1 - smoothingFactor) + velocity * smoothingFactor;
    const absVelocity = Math.abs(this.smoothedVelocity); // 速度绝对值
    const now = Date.now(); // 当前时间戳

    // 若速度大于停顿阈值，更新最后活跃时间戳
    if (absVelocity >= this.PAUSE_VELOCITY_THRESHOLD) {
      this.lastActiveTimestamp = now;
    }

    // 检测是否出现停顿（长时间无显著速度）
    if (this.lastActiveTimestamp > 0 && absVelocity < this.PAUSE_VELOCITY_THRESHOLD) {
      const elapsed = now - this.lastActiveTimestamp;
      if (elapsed >= this.PAUSE_DURATION_MS) {
        this.pauseDetected = true; // 标记为停顿
        this.initialDragDirection = 0; // 重置初始方向
        this.lastActiveTimestamp = 0; // 重置活跃时间戳
      }
    }

    // 速度低于阈值，取消形变，重置尺寸
    if (absVelocity < this.VELOCITY_THRESHOLD) {
      this.velocityDeformationWidth = 0;
      this.velocityDeformationHeight = 0;
      this.animatedBarWidth = this.BASE_MOVING_WIDTH;
      this.animatedBarHeight = this.BASE_MOVING_HEIGHT;
      return;
    }

    // 若未设置初始方向，或检测到停顿，重新设置初始拖动方向
    if (this.initialDragDirection === 0 || this.pauseDetected) {
      this.initialDragDirection = this.smoothedVelocity > 0 ? 1 : -1;
      this.pauseDetected = false;
    }

    // 归一化速度（映射到0-1区间），并通过开方实现缓动效果，让形变更自然
    const normalizedVelocity = Math.min(absVelocity / this.VELOCITY_NORMALIZE_BASE, 1);
    const easedVelocity = Math.sqrt(normalizedVelocity);
    // 计算形变量，不超过最大形变量限制
    const deformAmount = easedVelocity * this.MAX_VELOCITY_DEFORM;
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
    this.animatedBarWidth = this.BASE_MOVING_WIDTH + this.velocityDeformationWidth;
    this.animatedBarHeight = this.BASE_MOVING_HEIGHT + this.velocityDeformationHeight;
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
    this.isNearAnchor = nearestDistance <= this.ANCHOR_PROXIMITY_THRESHOLD;
    this.displayIndex = nearestIndex;

    // 若靠近状态发生变化且非移动状态，执行轻微动画，提升过渡流畅度
    if (wasNearAnchor !== this.isNearAnchor && !this.isMoving) {
      this.getUIContext().animateTo({ duration: 150, curve: Curve.EaseInOut }, () => {
      });
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
    Stack({ alignContent: Alignment.Bottom }) {
      // 适配HarmonyOS 6.1及以上版本（API 60100+），使用HdsNavigation和HdsTabs构建基础导航
      if (deviceInfo.distributionOSApiVersion >= 60100) {
        // HdsTabs组件，作为页签容器，绑定控制器和当前激活索引
        HdsTabs({
          controller: this.tabsController,
          index: this.activeTabIndex  // 绑定当前激活的页签索引
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
        // 页签切换事件监听，同步选中索引和激活索引
        .onChange((index: number) => {
          this.selectedTabIndex = index;
          this.activeTabIndex = index;
        })
        .barHeight(59) // tabbar高度（vp）
        .animationDuration(0) // 禁用默认动画，使用自定义液态动效
        .scrollable(false) // 禁用tabbar自身滚动，使用自定义拖动逻辑
        .vertical(false) // 横向排列页签
        .barPosition(BarPosition.End) // 页签位于底部
        .barOverlap(true) // 允许tabbar与内容重叠，实现沉浸效果
        // 悬浮样式配置，设置tabbar的宽度、间距、颜色及沉浸材质
        .barFloatingStyle({
          barWidth: {
            smallWidth: this.BASE_CONTAINER_WIDTH,
            mediumWidth: this.BASE_CONTAINER_WIDTH,
            largeWidth: this.BASE_CONTAINER_WIDTH
          }, // 固定宽度，适配不同屏幕尺寸
          adaptToHandedness: true, // 适配左右手操作习惯
          lightColor: this.tabsOption.maskColor, // 浅色模式下的颜色
          barBottomMargin: this.tabsOption.barBottomMargin ?? ZSTabsConstance.barBottomMargin, // 底部间距，避免被系统导航栏遮挡
          // 系统材质效果，设置为沉浸光感，精致级别，贴合HarmonyOS 6设计语言
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
          }
        })
      }
      // 液态指示器容器，用于承载指示器和拖动手势
      Column() {
        Row() {
          Stack() {
            // 液态指示器核心组件（HdsMiniBarButton），实现沉浸光感和液态样式
            HdsMiniBarButton({
              maskColor: '#00ffffff', // 遮罩颜色（透明），不影响底层高光
              barWidth: this.animatedBarWidth, // 动态宽度，随滑动状态变化
              barHeight: this.animatedBarHeight, // 动态高度，随滑动状态变化
              // 材质类型和级别，移动与静止状态保持一致，确保沉浸质感统一
              materialType: this.isMoving
                ? hdsMaterial.MaterialType.IMMERSIVE
                : hdsMaterial.MaterialType.IMMERSIVE,
              materialLevel: this.isMoving
                ? hdsMaterial.MaterialLevel.EXQUISITE
                : hdsMaterial.MaterialLevel.EXQUISITE,
            }) {
              // 指示器内部内容：图标+文本，与当前显示索引同步
              Column({ space: 0 }) {
                // 页签图标，根据显示索引切换，滑动时（未靠近锚点）添加模糊效果
                Image(this.tabIcons[this.displayIndex])
                  .width(30)
                  .height(30)
                  .objectFit(ImageFit.Contain)
                  .fillColor(this.tabsOption.tabItems[0].selectColor ??
                    this.tabsOption.tabItems[0].color) // 图标颜色，与指示器形成对比度
                  .blur((this.isMoving && !this.isNearAnchor) ? 20 : 0) // 滑动时模糊，增强液态动效
                  .borderRadius(12)
                  .padding(2)
                  .animation({ duration: 400, curve: Curve.Smooth }) // 图标切换动画

                // 页签文本，与图标同步，滑动时添加模糊效果
                Text(this.tabTitles[this.displayIndex])
                  .fontSize(9)
                  .fontColor(this.tabsOption.tabItems[0].selectColor ??
                    this.tabsOption.tabItems[0].color) // 文本颜色，与图标一致，确保可读性
                  .fontWeight(FontWeight.Normal)
                  .blur((this.isMoving && !this.isNearAnchor) ? 20 : 0) // 滑动时模糊
                  .padding(2)
                  .borderRadius(15)
                  .animation({ curve: curves.springMotion() }) // 文本切换动画
              }
              .justifyContent(FlexAlign.Center) // 垂直居中
              .alignItems(HorizontalAlign.Center) // 水平居中
              .width('100%')
              .height('100%')
              .borderRadius(30) // 圆角，贴合液态指示器的圆润风格
            }

            // 半透明遮罩，用于增强指示器的层次感，静止时显示，移动时透明
            Row() {
            }
            .width(92)
            .height(54)
            .borderRadius(30)
            .backgroundColor(Color.Transparent) // 移动时透明，静止时显示指定颜色
            .animation({ curve: curves.springMotion() }) // 遮罩切换动画
          }
          .borderRadius(30)
          .clip(false) // 不裁剪，允许指示器轻微溢出，增强液态质感
          .width(80)
          .height(80)
        }
        .borderRadius(30)
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
                this.dragOffsetX = event.offsetX * 0.3;
              } else if (this.currentIndicatorIndex === 3 && event.offsetX > 0) {
                this.dragOffsetX = event.offsetX * 0.3;
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
              newIndex = Math.max(0, Math.min(3, newIndex));

              // 若索引发生变化，执行页签切换动画
              if (newIndex !== this.currentIndicatorIndex) {
                this.isProgrammaticChange = true; // 标记为程序控制移动
                this.isMoving = true;
                // 指示器移动到新锚点位置，动画时长300ms
                this.getUIContext().animateTo({ duration: 300, curve: curves.springMotion() }, () => {
                  this.$currentIndicatorIndex(newIndex)
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
                this.getUIContext().animateTo({ duration: 200, curve: curves.springMotion() }, () => {
                  this.dragOffsetX = 0;
                });
              }
            })
        )
        // 指示器的初始位置，绑定当前锚点位置
        .position({
          x: this.getAnchorPosition()
        })
        .animation({ curve: curves.springMotion() }) // 位置变化动画，确保流畅
      }
      .margin({ bottom: this.tabsOption.barBottomMargin ?? ZSTabsConstance.barBottomMargin })
      .width(330) // 与tabbar宽度一致
      .height(59) // 与tabbar高度一致
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
  TabItemBuilder(title: string, icon: string | Resource, index: number, color: ResourceColor,
    selectColor: ResourceColor) {
    Column() {
      // 处理图标类型（字符串图标/资源图标），根据选中状态切换颜色
      if (typeof icon === 'string') {
        Text(icon)
          .fontSize(24)
          .fontColor(index === this.selectedTabIndex ? selectColor : color)
          .margin({ bottom: 2 })
      } else {
        Image(icon)
          .width(25)
          .height(25)
          .objectFit(ImageFit.Contain)
          .margin({ bottom: 2 })
          .fillColor(index === this.selectedTabIndex ? selectColor : color)
      }
      // 页签文本，根据选中状态切换颜色和字体粗细
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
