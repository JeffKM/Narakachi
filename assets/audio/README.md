# 효과음 자리 (T18 "사운드 자리" → S3에서 채움)

`Sfx` 오토로드(`scripts/systems/sfx.gd`)가 아래 파일명을 찾는다. **파일이 없으면 무음**(no-op)이라
지금은 비어 있어도 게임이 돈다. S3(8비트 효과음)에서 아래 이름 그대로 `.wav`/`.ogg`를 떨궈 넣으면
코드 수정 없이 자동으로 울린다.

| 큐 키 | 파일 | 트리거 |
|---|---|---|
| `order`      | `sfx_order.wav`      | 체키/음료 주문 (딸랑) |
| `cheki_get`  | `sfx_cheki_get.wav`  | 오늘의 체키 획득 언박싱 (팡) |
| `butterfly`  | `sfx_butterfly.wav`  | 나비 승급 (반짝 상승음) |
| `flip`       | `sfx_flip.wav`       | 카드 뒤집기 (촤락) |
| `tap`        | `sfx_tap.wav`        | UI 버튼/선택 (틱) |
| `gauge_full` | `sfx_gauge_full.wav` | 호감도 게이지 가득 (차오름 완료) |
| `book`       | `sfx_book.wav`       | 체키북 열기 (책장) |
| `shutter`    | `sfx_shutter.wav`    | 공유 이미지 저장 (찰칵) |

- 규격 권장: 8비트/칩튠 톤, 모노, 짧게(≤1s), 피크 −6dB 여유. 도트 룩과 결 맞춤.
- 음량은 `SFX` 버스(런타임 생성)에서 일괄 조절 가능.
