# BSKang_SW — 프로그램 설치 파일 선반

이 저장소에는 **설치 파일만** 있습니다. 소스 코드는 각 프로그램의 비공개 저장소에 있고, 그쪽에서 태그를 올리면
GitHub Actions 가 여기 Release 에 Setup.exe · ZIP 을 올리고 `<프로그램>/latest.json` 을 갱신합니다.

- 다운로드 페이지: https://eden-0721.github.io/BSkang_SW/
- 각 프로그램은 설치 후 자기 `latest.json` 을 읽어 "업데이트 있음"을 표시하고, 프로그램 안에서 조용히 업데이트합니다.

| 파일 | 역할 |
|---|---|
| `index.html` | 다운로드 페이지 (programs.json 을 읽어 목록 표시) |
| `programs.json` | 프로그램 목록 (자동 갱신) |
| `<app>/latest.json` | 정식 최신 버전 (설치 파일 주소·SHA-256·변경 노트) |
| `<app>/prerelease.json` | 시험판 (개발본에만 보임) |
| `<app>/notes.json` | 변경 노트 전체 |

손으로 고칠 일은 없습니다. 새 프로그램은 그 프로그램의 Actions 가 알아서 항목을 추가합니다.
