// 게임 타입 정의

// ── 방향 및 플레이어 상태 ──

export enum Direction {
  LEFT = -1,
  RIGHT = 1,
}

export enum PlayerState {
  IDLE,
  MOVING,
  JUMPING,
  FALLING,
  SLAMMING,
  HIT,
}

// ── 보스 상태 및 패턴 ──

export enum BossState {
  IDLE,
  PATROL,
  CHARGE_READY,
  CHARGING,
  HIT,
  DEFEATED,
}

export enum BossPattern {
  PATROL,
  CHARGE,
}

// ── 장애물 / 아이템 타입 (constants.ts 키와 일치) ──

export enum ObstacleType {
  TUNNEL_TRAP = 'TUNNEL_TRAP',
  TRASH_CAN = 'TRASH_CAN',
  BARRICADE = 'BARRICADE',
}

export enum ItemType {
  FISH_BONE = 'FISH_BONE',
  TUNA_CAN = 'TUNA_CAN',
}

// ── 씬 전환 데이터 ──

/** 씬 간 전달 데이터 */
export interface SceneData {
  score?: number
}

/** 게임 결과 */
export type GameResult = 'clear' | 'gameover'

// ── 엔티티 설정 (스테이지 레벨 디자인용) ──

/** 장애물 배치 설정 */
export interface ObstacleConfig {
  type: ObstacleType
  x: number
  y: number
}

/** 아이템 배치 설정 */
export interface ItemConfig {
  type: ItemType
  x: number
  y: number
}

/** 스테이지 스폰 설정 */
export interface SpawnPoint {
  x: number
  y: number
}

/** 스테이지 전체 설정 */
export interface StageConfig {
  width: number
  obstacles: ObstacleConfig[]
  items: ItemConfig[]
  bossSpawn: SpawnPoint
  playerSpawn: SpawnPoint
}
