import {
  ANCHOR_PROXIMITY_THRESHOLD,
  BAR_MOVING_HEIGHT,
  BAR_MOVING_WIDTH,
  BAR_RESTING_HEIGHT,
  BAR_RESTING_WIDTH,
  MAX_VELOCITY_DEFORM,
  PAUSE_DURATION_MS,
  PAUSE_VELOCITY_THRESHOLD,
  SMOOTHING_FACTOR,
  VELOCITY_NORMALIZE_BASE,
  VELOCITY_THRESHOLD
} from '../constant/HTabsConstants';

/**
 * 液态指示器状态管理类
 *
 * 使用 @ObservedV2 装饰器实现属性级响应式：
 * - @Trace 标记的属性变化时，引用该实例的 UI 组件会自动刷新
 * - 非 @Trace 属性为内部计算状态，不影响 UI
 */
@ObservedV2
export class HTabsIndicator {
  // ==================== @Trace 响应式属性（变化触发 UI 刷新） ====================

  /** 指示器当前宽度（vp），静止 92 / 移动 110 / 形变时动态变化 */
  @Trace animatedBarWidth: number = BAR_RESTING_WIDTH;
  /** 指示器当前高度（vp），与宽度联动实现液态形变 */
  @Trace animatedBarHeight: number = BAR_RESTING_HEIGHT;
  /** 拖动时的 X 轴偏移量（vp），控制指示器水平位移 */
  @Trace dragOffsetX: number = 0;
  /** 是否处于移动/拖动状态 */
  @Trace isMoving: boolean = false;
  /** 当前显示的页签索引（滑动过程中动态更新，用于同步图标/文本） */
  @Trace displayIndex: number = 0;
  /** 是否靠近某个锚点（靠近时取消图标/文本模糊效果） */
  @Trace isNearAnchor: boolean = false;
  /** 速度引起的宽度形变量（vp） */
  @Trace velocityDeformationWidth: number = 0;
  /** 速度引起的高度形变量（vp），与宽度形变反向 */
  @Trace velocityDeformationHeight: number = 0;

  // ==================== 内部计算状态（不影响 UI） ====================

  /** 平滑后的速度值（vp/帧），减少速度波动 */
  smoothedVelocity: number = 0;
  /** 当前帧速度（vp/帧） */
  currentVelocity: number = 0;
  /** 本次拖动的初始方向：1=右，-1=左，0=未设置 */
  initialDragDirection: number = 0;
  /** 上次有显著速度时的时间戳（ms），用于检测停顿 */
  lastActiveTimestamp: number = 0;
  /** 是否检测到拖动停顿 */
  pauseDetected: boolean = false;
  /** 上一帧的偏移量，用于计算速度 */
  lastOffsetX: number = 0;
  /** 是否为程序控制的切换（非用户拖动），避免重复触发事件 */
  isProgrammaticChange: boolean = false;

  // ==================== 状态切换方法 ====================

  /**
   * 进入移动状态
   * 重置所有拖动相关参数，设置移动态尺寸
   * @param displayIndex 初始显示的页签索引
   */
  enterMoving(displayIndex: number): void {
    this.isMoving = true;
    this.displayIndex = displayIndex;
    this.animatedBarWidth = BAR_MOVING_WIDTH;
    this.animatedBarHeight = BAR_MOVING_HEIGHT;
    this.lastOffsetX = 0;
    this.currentVelocity = 0;
    this.smoothedVelocity = 0;
    this.initialDragDirection = 0;
    this.lastActiveTimestamp = 0;
    this.pauseDetected = false;
  }

  /**
   * 进入静止状态
   * 重置形变和偏移量，恢复静止态尺寸
   * @param displayIndex 最终显示的页签索引
   */
  enterResting(displayIndex: number): void {
    this.isMoving = false;
    this.displayIndex = displayIndex;
    this.animatedBarWidth = BAR_RESTING_WIDTH;
    this.animatedBarHeight = BAR_RESTING_HEIGHT;
    this.resetDeformation();
    this.dragOffsetX = 0;
  }

  /**
   * 重置形变相关状态（不改变尺寸和偏移量）
   */
  resetDeformation(): void {
    this.velocityDeformationWidth = 0;
    this.velocityDeformationHeight = 0;
    this.currentVelocity = 0;
    this.smoothedVelocity = 0;
    this.initialDragDirection = 0;
    this.lastActiveTimestamp = 0;
    this.pauseDetected = false;
  }

  // ==================== 液态形变计算 ====================

  /**
   * 根据滑动速度更新指示器形变效果
   *
   * 实现液态拉伸/收缩的核心逻辑：
   * 1. 平滑速度（减少帧间波动）
   * 2. 检测拖动停顿（重置方向判定）
   * 3. 归一化速度 → 开方缓动 → 计算形变量
   * 4. 同方向拉伸/反方向收缩，增强液态真实感
   *
   * @param velocity 当前帧速度（px/帧）
   */
  updateVelocityDeformation(velocity: number): void {
    this.currentVelocity = velocity;
    const absVelocity = Math.abs(velocity);
    const now = Date.now();

    // 指数移动平均平滑速度
    this.smoothedVelocity = this.smoothedVelocity * (1 - SMOOTHING_FACTOR) + velocity * SMOOTHING_FACTOR;
    const absSmoothed = Math.abs(this.smoothedVelocity);

    // 速度大于停顿阈值时，更新最后活跃时间戳
    if (absSmoothed >= PAUSE_VELOCITY_THRESHOLD) {
      this.lastActiveTimestamp = now;
    }

    // 检测停顿：长时间无显著速度 → 视为新的拖动开始
    if (this.lastActiveTimestamp > 0 && absSmoothed < PAUSE_VELOCITY_THRESHOLD) {
      if (now - this.lastActiveTimestamp >= PAUSE_DURATION_MS) {
        this.pauseDetected = true;
        this.initialDragDirection = 0;
        this.lastActiveTimestamp = 0;
      }
    }

    // 速度低于阈值，取消形变
    if (absSmoothed < VELOCITY_THRESHOLD) {
      this.velocityDeformationWidth = 0;
      this.velocityDeformationHeight = 0;
      this.animatedBarWidth = BAR_MOVING_WIDTH;
      this.animatedBarHeight = BAR_MOVING_HEIGHT;
      return;
    }

    // 首次有速度或停顿后，记录初始拖动方向
    if (this.initialDragDirection === 0 || this.pauseDetected) {
      this.initialDragDirection = this.smoothedVelocity > 0 ? 1 : -1;
      this.pauseDetected = false;
    }

    // 归一化速度 → 开方缓动（低速区更敏感，高速区更平缓）
    const normalizedVelocity = Math.min(absSmoothed / VELOCITY_NORMALIZE_BASE, 1);
    const easedVelocity = Math.sqrt(normalizedVelocity);
    const deformAmount = easedVelocity * MAX_VELOCITY_DEFORM;
    const currentDirection = this.smoothedVelocity > 0 ? 1 : -1;
    const isSameDirection = currentDirection === this.initialDragDirection;

    // 同方向：宽度拉伸 + 高度收缩 / 反方向：宽度收缩 + 高度拉伸
    if (isSameDirection) {
      this.velocityDeformationWidth = deformAmount;
      this.velocityDeformationHeight = -deformAmount * 0.5;
    } else {
      this.velocityDeformationWidth = -deformAmount * 0.5;
      this.velocityDeformationHeight = deformAmount;
    }

    // 最终尺寸 = 移动基础尺寸 + 形变量
    this.animatedBarWidth = BAR_MOVING_WIDTH + this.velocityDeformationWidth;
    this.animatedBarHeight = BAR_MOVING_HEIGHT + this.velocityDeformationHeight;
  }

  // ==================== 锚点检测 ====================

  /**
   * 检测指示器是否靠近某个页签锚点
   *
   * 实时计算当前位置与所有锚点的距离，更新 displayIndex 和 isNearAnchor。
   * 靠近锚点时取消图标/文本模糊，增强交互反馈。
   *
   * @param currentX 指示器当前 X 坐标（锚点位置 + 拖动偏移量）
   * @param anchorPositions 所有页签的锚点 X 坐标数组
   * @returns isNearAnchor 状态是否发生变化（用于触发过渡动画）
   */
  checkNearAnchor(currentX: number, anchorPositions: number[]): boolean {
    let nearestDistance = Infinity;
    let nearestIndex = 0;

    for (let i = 0; i < anchorPositions.length; i++) {
      const distance = Math.abs(currentX - anchorPositions[i]);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    const wasNearAnchor = this.isNearAnchor;
    this.isNearAnchor = nearestDistance <= ANCHOR_PROXIMITY_THRESHOLD;
    this.displayIndex = nearestIndex;

    return wasNearAnchor !== this.isNearAnchor;
  }
}
