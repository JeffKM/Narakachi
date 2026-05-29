import { Scene } from 'phaser'
import { FONT } from '../constants'
import type { SceneData } from '../types'
import { addText } from '../utils'

// 게임 오버 씬
export class GameOverScene extends Scene {
  private score = 0

  constructor() {
    super('GameOverScene')
  }

  init(data: SceneData) {
    this.score = data.score ?? 0
  }

  create() {
    const { width, height } = this.scale

    addText(this, width / 2, height / 2 - 90, 'GAME OVER', {
      fontSize: FONT.SIZE_LG,
      color: '#ff0000',
    }).setOrigin(0.5)

    addText(this, width / 2, height / 2, `SCORE: ${this.score}`, {
      fontSize: FONT.SIZE_MD,
    }).setOrigin(0.5)

    addText(this, width / 2, height / 2 + 90, 'PRESS ANY KEY TO RETURN', {
      fontSize: FONT.SIZE_XS,
      color: '#ffff00',
    }).setOrigin(0.5)

    // 아무 키 → 타이틀로 복귀
    this.input.keyboard?.on('keydown', () => {
      this.scene.start('TitleScene')
    })
  }
}
