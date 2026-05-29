import { Scene } from 'phaser'
import { FONT } from '../constants'
import type { SceneData } from '../types'
import { addText } from '../utils'

// 스테이지 클리어 씬
export class ClearScene extends Scene {
  private score = 0

  constructor() {
    super('ClearScene')
  }

  init(data: SceneData) {
    this.score = data.score ?? 0
  }

  create() {
    const { width, height } = this.scale

    addText(this, width / 2, height / 2 - 90, 'STAGE CLEAR', {
      fontSize: FONT.SIZE_LG,
      color: '#00ff00',
    }).setOrigin(0.5)

    addText(this, width / 2, height / 2, `SCORE: ${this.score}`, {
      fontSize: FONT.SIZE_MD,
    }).setOrigin(0.5)

    addText(this, width / 2, height / 2 + 90, 'PRESS ANY KEY', {
      fontSize: FONT.SIZE_SM,
      color: '#ffff00',
    }).setOrigin(0.5)

    // 아무 키 → 타이틀로 복귀
    this.input.keyboard?.on('keydown', () => {
      this.scene.start('TitleScene')
    })
  }
}
