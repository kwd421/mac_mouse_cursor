# CapeForge

macOS에서 사용자 커서 세트를 불러와 비교, 매핑하고 Mousecape 호환 `.cape` 파일로 내보내는 Swift 기반 도구입니다.

현재 기본 실행 경로는 일반 macOS 앱입니다.

- 사용자가 선택한 폴더에서 `.ani` 또는 `.cur` 파일을 읽습니다.
- 폴더 안의 커서 파일을 역할별로 자동 매핑합니다.
- 기본 커서와 적용 커서를 설정창에서 비교할 수 있습니다.
- 역할별로 커서 파일을 수동 재지정할 수 있습니다.
- `ani` 내부의 PNG 프레임과 핫스팟을 직접 파싱합니다.
- Mousecape가 읽을 수 있는 `.cape` 파일로 내보낼 수 있습니다.

한계:

- 이 앱은 커서 변환과 `.cape` 내보내기에 집중합니다.
- 내보낸 `.cape` 파일의 실제 적용은 Mousecape 같은 별도 앱에서 진행해야 합니다.

## 실행

```bash
./run_mac_mouse_cursor.command
```

## 패키징

```bash
./package_mac_mouse_cursor.command
open "./dist/CapeForge.app"
```

## 참고

현재 기준 실행 경로와 배포 경로는 모두 Swift 앱입니다.
