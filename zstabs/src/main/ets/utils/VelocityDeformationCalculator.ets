/**
 * 速度形变计算器
 * 根据滑动速度计算指示器的液态形变效果
 */
export class VelocityDeformationCalculator {
  private lastActiveTimestamp: number = 0;
  private pauseDetected: boolean = false;
  private initialDragDirection: number = 0;

  /**
   * 重置计算器状态
   */
  reset(): void {
    this.lastActiveTimestamp = 0;
    this.pauseDetected = false;
    this.initialDragDirection = 0;
  }

  /**
   * 更新速度引起的形变效果
   * @param velocity 当前滑动速度
   * @param smoothedVelocity 上次平滑速度
   * @param constants 速度常量配置
   * @returns 形变计算结果
   */
  calculateDeformation(
    velocity: number,
    smoothedVelocity: number,
    constants: {
      smoothingFactor: number;
      pauseThreshold: number;
      pauseDurationMs: number;
      threshold: number;
      normalizeBase: number;
      maxDeform: number;
      baseMovingWidth: number;
      baseMovingHeight: number;
    }
  ): {
    smoothedVelocity: number;
    widthDeformation: number;
    heightDeformation: number;
    animatedWidth: number;
    animatedHeight: number;
    pauseDetected: boolean;
    initialDragDirection: number;
  } {
    const smoothingFactor = constants.smoothingFactor;
    const newSmoothedVelocity = smoothedVelocity * (1 - smoothingFactor) + velocity * smoothingFactor;
    const absVelocity = Math.abs(newSmoothedVelocity);
    const now = Date.now();

    // 更新活跃时间戳
    if (absVelocity >= constants.pauseThreshold) {
      this.lastActiveTimestamp = now;
    }

    // 检测停顿
    if (this.lastActiveTimestamp > 0 && absVelocity < constants.pauseThreshold) {
      const elapsed = now - this.lastActiveTimestamp;
      if (elapsed >= constants.pauseDurationMs) {
        this.pauseDetected = true;
        this.initialDragDirection = 0;
        this.lastActiveTimestamp = 0;
      }
    }

    // 速度过低，重置形变
    if (absVelocity < constants.threshold) {
      return {
        smoothedVelocity: 0,
        widthDeformation: 0,
        heightDeformation: 0,
        animatedWidth: constants.baseMovingWidth,
        animatedHeight: constants.baseMovingHeight,
        pauseDetected: this.pauseDetected,
        initialDragDirection: this.initialDragDirection
      };
    }

    // 设置初始方向
    if (this.initialDragDirection === 0 || this.pauseDetected) {
      this.initialDragDirection = newSmoothedVelocity > 0 ? 1 : -1;
      this.pauseDetected = false;
    }

    // 计算形变量
    const normalizedVelocity = Math.min(absVelocity / constants.normalizeBase, 1);
    const easedVelocity = Math.sqrt(normalizedVelocity);
    const deformAmount = easedVelocity * constants.maxDeform;
    const currentDirection = newSmoothedVelocity > 0 ? 1 : -1;
    const isSameDirection = currentDirection === this.initialDragDirection;

    let widthDeformation: number;
    let heightDeformation: number;

    if (isSameDirection) {
      widthDeformation = deformAmount;
      heightDeformation = -deformAmount * 0.5;
    } else {
      widthDeformation = -deformAmount * 0.5;
      heightDeformation = deformAmount;
    }

    return {
      smoothedVelocity: newSmoothedVelocity,
      widthDeformation,
      heightDeformation,
      animatedWidth: constants.baseMovingWidth + widthDeformation,
      animatedHeight: constants.baseMovingHeight + heightDeformation,
      pauseDetected: this.pauseDetected,
      initialDragDirection: this.initialDragDirection
    };
  }
}