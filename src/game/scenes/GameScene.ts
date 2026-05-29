import { Scene } from 'phaser'
import { FONT } from '../constants'
import type { SceneData } from '../types'
import { addText } from '../utils'

// 메인 게임 플레이 씬
export class GameScene extends Scene {
  constructor() {
    super('GameScene')
  }

  create() {
    const { width, height } = this.scale

    // 임시 안내 텍스트
    addText(this, width / 2, height / 2 - 30, 'Game Scene', {
      fontSize: FONT.SIZE_MD,
    }).setOrigin(0.5)

    addText(this, width / 2, height / 2 + 45, '개발 중', {
      fontSize: FONT.SIZE_SM,
    }).setOrigin(0.5)

    // 테스트용 씬 전환 안내
    addText(this, width / 2, height - 60, 'C: Clear / G: GameOver', {
      fontSize: FONT.SIZE_XS,
      color: '#cccccc',
    }).setOrigin(0.5)

    // 임시 테스트용 키 바인딩
    this.input.keyboard?.on('keydown-C', () => {
      this.scene.start('ClearScene', { score: 1000 } satisfies SceneData)
    })
    this.input.keyboard?.on('keydown-G', () => {
      this.scene.start('GameOverScene', { score: 500 } satisfies SceneData)
    })
  }
}
