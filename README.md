# BSKang_SW — 프로그램 설치 파일 선반

이 저장소에는 **버전 정보(JSON)와 다운로드 페이지만** 있습니다. 설치 파일(Setup.exe · ZIP)은 비공개 저장소
`BSkang_SW_files` 의 Release 에 있고, 소스는 각 프로그램의 비공개 저장소에 있습니다. 그쪽에서 태그를 올리면
GitHub Actions 가 `BSkang_SW_files` 에 Release 를 만들고 여기 `<프로그램>/latest.json` 을 갱신합니다.

- 다운로드 페이지: https://eden-0721.github.io/BSkang_SW/
- 각 프로그램은 설치 후 자기 `latest.json` 을 읽어 "업데이트 있음"을 표시합니다. 프로그램 안에 읽기 전용 "업데이트 키"를 넣은 PC 는 조용히 자동 업데이트되고, 없는 PC 는 알림만 받습니다.

| 파일 | 역할 |
|---|---|
| `index.html` | 다운로드 페이지 (programs.json 을 읽어 목록 표시) |
| `programs.json` | 프로그램 목록 (자동 갱신) |
| `<app>/latest.json` | 정식 최신 버전 (설치 파일 주소·SHA-256·변경 노트) |
| `<app>/prerelease.json` | 시험판 (개발본에만 보임) |
| `<app>/notes.json` | 변경 노트 전체 |

손으로 고칠 일은 없습니다. 새 프로그램은 그 프로그램의 Actions 가 알아서 항목을 추가합니다.
