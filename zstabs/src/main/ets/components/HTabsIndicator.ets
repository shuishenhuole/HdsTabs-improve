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
} from './HTabsConstants';

@ObservedV2
export class HTabsIndicator {
  @Trace animatedBarWidth: number = BAR_RESTING_WIDTH;
  @Trace animatedBarHeight: number = BAR_RESTING_HEIGHT;
  @Trace dragOffsetX: number = 0;
  @Trace isMoving: boolean = false;
  @Trace displayIndex: number = 0;
  @Trace isNearAnchor: boolean = false;
  @Trace velocityDeformationWidth: number = 0;
  @Trace velocityDeformationHeight: number = 0;

  smoothedVelocity: number = 0;
  currentVelocity: number = 0;
  initialDragDirection: number = 0;
  lastActiveTimestamp: number = 0;
  pauseDetected: boolean = false;
  lastOffsetX: number = 0;
  isProgrammaticChange: boolean = false;

  /** 进入移动状态 */
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

  /** 进入静止状态 */
  enterResting(displayIndex: number): void {
    this.isMoving = false;
    this.displayIndex = displayIndex;
    this.animatedBarWidth = BAR_RESTING_WIDTH;
    this.animatedBarHeight = BAR_RESTING_HEIGHT;
    this.resetDeformation();
    this.dragOffsetX = 0;
  }

  /** 重置形变状态 */
  resetDeformation(): void {
    this.velocityDeformationWidth = 0;
    this.velocityDeformationHeight = 0;
    this.currentVelocity = 0;
    this.smoothedVelocity = 0;
    this.initialDragDirection = 0;
    this.lastActiveTimestamp = 0;
    this.pauseDetected = false;
  }

  /** 计算速度形变并更新尺寸 */
  updateVelocityDeformation(velocity: number): void {
    this.currentVelocity = velocity;
    const absVelocity = Math.abs(velocity);
    const now = Date.now();

    this.smoothedVelocity = this.smoothedVelocity * (1 - SMOOTHING_FACTOR) + velocity * SMOOTHING_FACTOR;
    const absSmoothed = Math.abs(this.smoothedVelocity);

    if (absSmoothed >= PAUSE_VELOCITY_THRESHOLD) {
      this.lastActiveTimestamp = now;
    }

    if (this.lastActiveTimestamp > 0 && absSmoothed < PAUSE_VELOCITY_THRESHOLD) {
      if (now - this.lastActiveTimestamp >= PAUSE_DURATION_MS) {
        this.pauseDetected = true;
        this.initialDragDirection = 0;
        this.lastActiveTimestamp = 0;
      }
    }

    if (absSmoothed < VELOCITY_THRESHOLD) {
      this.velocityDeformationWidth = 0;
      this.velocityDeformationHeight = 0;
      this.animatedBarWidth = BAR_MOVING_WIDTH;
      this.animatedBarHeight = BAR_MOVING_HEIGHT;
      return;
    }

    if (this.initialDragDirection === 0 || this.pauseDetected) {
      this.initialDragDirection = this.smoothedVelocity > 0 ? 1 : -1;
      this.pauseDetected = false;
    }

    const normalizedVelocity = Math.min(absSmoothed / VELOCITY_NORMALIZE_BASE, 1);
    const easedVelocity = Math.sqrt(normalizedVelocity);
    const deformAmount = easedVelocity * MAX_VELOCITY_DEFORM;
    const currentDirection = this.smoothedVelocity > 0 ? 1 : -1;
    const isSameDirection = currentDirection === this.initialDragDirection;

    if (isSameDirection) {
      this.velocityDeformationWidth = deformAmount;
      this.velocityDeformationHeight = -deformAmount * 0.5;
    } else {
      this.velocityDeformationWidth = -deformAmount * 0.5;
      this.velocityDeformationHeight = deformAmount;
    }

    this.animatedBarWidth = BAR_MOVING_WIDTH + this.velocityDeformationWidth;
    this.animatedBarHeight = BAR_MOVING_HEIGHT + this.velocityDeformationHeight;
  }

  /** 检测是否靠近锚点，返回是否发生变化 */
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
