export namespace ResponseRegion {

  export interface Padding {
    top?: number
    bottom?: number
    left?: number
    right?: number
  }

  export function left(value: number): Rectangle[] {
    return ResponseRegion.expand({ top: 0, bottom: 0, left: value, right: 0 })
  }

  export function right(value: number): Rectangle[] {
    return ResponseRegion.expand({ top: 0, bottom: 0, left: 0, right: value })
  }

  export function top(value: number): Rectangle[] {
    return ResponseRegion.expand({ top: value, bottom: 0, left: 0, right: 0 })
  }

  export function bottom(value: number): Rectangle[] {
    return ResponseRegion.expand({ top: 0, bottom: value, left: 0, right: 0 })
  }

  export function horizontal(value: number): Rectangle[] {
    return ResponseRegion.expand({ top: 0, bottom: 0, left: value, right: value })
  }

  export function vertical(value: number): Rectangle[] {
    return ResponseRegion.expand({ top: value, bottom: value, left: 0, right: 0 })
  }

  export function edge(value: number): Rectangle[] {
    return ResponseRegion.expand({ top: value, bottom: value, left: value, right: value })
  }

  export function expand(padding: Padding): Rectangle[] {
    const top = Math.max(padding.top ?? 0, 0)
    const bottom = Math.max(padding.bottom ?? 0, 0)
    const left = Math.max(padding.left ?? 0, 0)
    const right = Math.max(padding.right ?? 0, 0)
    return [
      {},                                                     // 默认
      { x: -left, y: -top, width: left, height: top},         // 左上
      { x: 0, y: -top, width: '100%', height: top},           // 上
      { x: '100%', y: -top, width: right, height: top},       // 右上
      { x: -left, y: 0, width: left, height: '100%'},         // 左
      { x: '100%', y: 0, width: right, height: '100%'},       // 右
      { x: -left, y: '100%', width: left, height: bottom},    // 左下
      { x: 0, y: '100%', width: '100%', height: bottom},      // 下
      { x: '100%', y: '100%', width: right, height: bottom},  // 右下
    ]
  }
}