/**
 * 手势处理器
 * 处理指示器的拖动手势逻辑
 */
export class GestureHandler {
  /**
   * 处理拖动更新
   * @param eventOffsetX 事件偏移量
   * @param currentIndicatorIndex 当前索引
   * @returns 处理后的偏移量
   */
  static handleDragUpdate(eventOffsetX: number, currentIndicatorIndex: number, boundaryDecay: number, tabCount: number): number {
    let dragOffsetX = eventOffsetX;

    // 边界处理
    if (currentIndicatorIndex === 0 && eventOffsetX < 0) {
      dragOffsetX = eventOffsetX * boundaryDecay;
    } else if (currentIndicatorIndex === tabCount - 1 && eventOffsetX > 0) {
      dragOffsetX = eventOffsetX * boundaryDecay;
    }

    return dragOffsetX;
  }

  /**
   * 处理拖动结束
   * @param dragOffsetX 最终偏移量
   * @param currentIndicatorIndex 当前索引
   * @param slotWidth 插槽宽度
   * @param tabCount 页签总数
   * @returns 新索引和是否改变
   */
  static handleDragEnd(
    dragOffsetX: number,
    currentIndicatorIndex: number,
    slotWidth: number,
    tabCount: number
  ): { newIndex: number; hasChanged: boolean } {
    const movedSlots = Math.round(dragOffsetX / slotWidth);
    let newIndex = currentIndicatorIndex + movedSlots;
    newIndex = Math.max(0, Math.min(tabCount - 1, newIndex));

    return {
      newIndex,
      hasChanged: newIndex !== currentIndicatorIndex
    };
  }

  /**
   * 初始化拖动状态
   * @returns 初始化参数对象
   */
  static initDragState(): { lastOffsetX: number; currentVelocity: number; smoothedVelocity: number; initialDragDirection: number; lastActiveTimestamp: number; pauseDetected: boolean } {
    return {
      lastOffsetX: 0,
      currentVelocity: 0,
      smoothedVelocity: 0,
      initialDragDirection: 0,
      lastActiveTimestamp: 0,
      pauseDetected: false
    };
  }
}