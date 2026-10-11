@echo off
rem UTF-8 relaunch: switch the code page first, then run this file again so cmd reads every line as UTF-8 from the start.
rem (chcp in the middle of a running batch makes cmd re-read the file at shifted byte offsets -> stray "is not recognized" lines.)
rem Do NOT use shift here: it moves %0 and "%~dp0" would point at the wrong folder.
if "%~1"=="__u8" goto :u8
chcp 65001 >nul
cmd /c ""%~f0" __u8"
exit /b %errorlevel%
:u8
setlocal EnableExtensions

rem ============================================================
rem  [BSKang SW 공통 템플릿 코어 — 앱에서 고치지 않는다. docs/workflow.md "여러 컴퓨터에서 작업하기"]
rem  새 컴퓨터에서 처음 한 번 두 번 클릭: 도구 확인 → 저장소 받기 → (서버 앱이면) wrangler·로그인 → 검사·시험 → 원격 DB 마무리
rem  - 저장소 폴더 안에서 실행하면 pull, 밖에서 실행하면 그 옆에 clone. 이 파일 하나만 새 컴퓨터에 옮겨 실행해도 된다
rem  - 여러 번 실행해도 안전하다. 비밀값은 파일에 남기지 않는다. 매일은 sync.bat
rem  - 서버가 없는 앱(wrangler.toml 없음 — variant local-python 등)은 wrangler·DB 단계를 건너뛴다
rem ============================================================

rem ---- check.mjs --fix가 template.config.json·git 주소로 채운다 (손으로 고치지 않는다) ----
set "APP_NAME=API 키 금고"
set "REPO_URL=https://github.com/eden-0721/ManageAPI.git"
set "REPO_DIR=ManageAPI"
set "TPL_URL=https://github.com/eden-0721/pwa-template.git"
rem ---- 여기까지 ----
title %APP_NAME% - 작업 이어가기
set "BRANCH=main"
set "HERE=%~dp0"
rem 끝의 역슬래시를 뗀다. 따옴표 바로 앞에 역슬래시가 오면 git이 따옴표를 글자로 읽는다
set "HERE=%HERE:~0,-1%"
set "D1_STATE=확인 안 함"

echo.
echo ==================================================
echo    %APP_NAME% - 다른 컴퓨터에서 이어서 작업하기
echo ==================================================

rem ---------- 1. 도구 ----------
echo.
echo [1/7] 필요한 도구 확인: Git, Node.js 22.13 이상
where git >nul 2>&1
if errorlevel 1 goto :need_git
where node >nul 2>&1
if errorlevel 1 goto :need_node
node -e "const [a,b]=process.versions.node.split('.').map(Number);process.exit(a>22||(a===22&&b>=13)?0:1)"
if errorlevel 1 goto :old_node
for /f "delims=" %%v in ('node -v') do echo   Node.js %%v
for /f "delims=" %%v in ('git --version') do echo   %%v

rem ---------- 2. 저장소 ----------
echo.
echo [2/7] 저장소 준비
set "REPO="
if exist "%HERE%\template.config.json" if exist "%HERE%\.git" set "REPO=%HERE%"
if defined REPO goto :have_repo
set "REPO=%HERE%\%REPO_DIR%"
if exist "%REPO%\.git" goto :have_repo
echo   %REPO% 에 내려받는 중...
git clone "%REPO_URL%" "%REPO%"
if errorlevel 1 goto :fail_clone
:have_repo
cd /d "%REPO%"
if errorlevel 1 goto :fail_clone
echo   작업 폴더: %CD%
for /f "delims=" %%s in ('git status --porcelain') do goto :dirty
git fetch origin
if errorlevel 1 goto :fail_git
git checkout %BRANCH%
if errorlevel 1 goto :fail_git
git pull --ff-only origin %BRANCH%
if errorlevel 1 goto :fail_git
for /f "delims=" %%h in ('git log -1 --format^=%%h') do echo   최신 커밋: %%h

rem 참고용 템플릿 저장소를 옆 폴더에 (실패해도 계속)
for %%p in ("%CD%\..") do set "PARENT=%%~fp"
if exist "%PARENT%\pwa-template\.git" (
  git -C "%PARENT%\pwa-template" pull --ff-only >nul 2>&1 || echo   참고: pwa-template 최신으로 받지 못했어요. 작업에는 지장 없어요.
) else (
  git clone "%TPL_URL%" "%PARENT%\pwa-template" >nul 2>&1 || echo   참고: pwa-template을 받지 못했어요. 작업에는 지장 없어요.
)

rem 서버(Cloudflare)가 없는 앱이면 wrangler·Cloudflare 로그인·원격 DB 단계를 건너뛴다
set "HAS_CF="
if exist "wrangler.toml" set "HAS_CF=1"
if defined HAS_CF goto :wrangler_check
echo.
echo [3/7] [4/7] 서버가 없는 앱이라 wrangler와 Cloudflare 로그인은 건너뛰어요
goto :gh_login

rem ---------- 3. wrangler ----------
:wrangler_check
echo.
echo [3/7] wrangler 설치 확인
call wrangler --version >nul 2>&1
if not errorlevel 1 goto :wrangler_ok
echo   wrangler를 설치하는 중... 1~2분 걸려요
call npm install -g wrangler
if errorlevel 1 goto :fail_wrangler
call wrangler --version >nul 2>&1
if errorlevel 1 goto :fail_wrangler
:wrangler_ok
for /f "delims=" %%v in ('call wrangler --version 2^>nul') do echo   wrangler %%v

rem ---------- 4. 로그인 ----------
echo.
echo [4/7] 로그인 확인
call wrangler whoami 2>nul | findstr /c:"You are logged in" >nul
if not errorlevel 1 goto :cf_ok
echo   Cloudflare 로그인이 필요해요. 브라우저가 열리면 이 앱을 배포하는 Cloudflare 계정으로 로그인하고 허용을 눌러 주세요.
call wrangler login
if errorlevel 1 goto :fail_login
:cf_ok
echo   Cloudflare: 로그인됨
:gh_login
where gh >nul 2>&1
if errorlevel 1 goto :no_gh
gh auth status >nul 2>&1
if errorlevel 1 gh auth login
goto :gh_done
:no_gh
echo   GitHub: 처음 git push 할 때 로그인 창이 뜨면 eden-0721 저장소 권한이 있는 계정으로 로그인하세요.
:gh_done

rem ---------- 5. 검사·시험 ----------
echo.
echo [5/7] 검사와 시험
node scripts\check.mjs
if errorlevel 1 goto :fail_check
node --no-warnings scripts\test.mjs
if errorlevel 1 goto :fail_test

rem ---------- 6. 원격 DB: 아직 적용 안 된 마이그레이션만 (이미 적용된 것은 건너뛴다) ----------
echo.
echo [6/7] 원격 DB 마무리 - 여러 번 실행해도 안전해요
set "LOCK_CHANGED="
if not defined HAS_CF (
  set "D1_STATE=해당 없음 - 서버가 없는 앱"
  goto :summary
)
call wrangler d1 migrations apply DB --remote
if errorlevel 1 goto :d1_fail
node scripts\check.mjs --lock >nul
set "D1_STATE=완료"
git diff --quiet -- template.lock.json
if errorlevel 1 set "LOCK_CHANGED=1"
goto :summary

:d1_fail
set "D1_STATE=실패 - 위 메시지를 확인하세요. 쓰기 한도 초과면 한국시간 오전 9시 이후, esbuild 오류면 npm install -g wrangler --force 후 다시 실행"
goto :summary

rem ---------- 7. 안내 ----------
:summary
echo.
echo [7/7] 준비 끝
echo ==================================================
echo  원격 DB: %D1_STATE%
if not defined LOCK_CHANGED goto :lock_msg_done
echo    적용한 마이그레이션을 잠갔어요. 이 파일을 커밋해 주세요:
echo    git add template.lock.json
echo    git commit -m "chore: 원격 D1 마이그레이션 잠금"
echo    git push
:lock_msg_done
echo.
echo  손으로 옮길 파일: 없음
echo    .gitignore로 빠지는 것은 .wrangler\ 뿐이고 새로 만들어져요.
echo    비밀값 ENCRYPTION_KEY는 배포할 때 넣어요. 파일에 적지 마세요.
echo.
echo  매일 쓰는 것: 이 폴더의 sync.bat 두 번 클릭
echo    작업 시작 전에는 GitHub 새것 받기, 작업 끝에는 커밋하고 올리기 - 알아서 판단해요.
echo  화면 미리보기: node --no-warnings scripts\dev.mjs 실행 후 http://localhost:8787
echo.
echo  다음에 AI에게 할 말 - 새 대화 첫 메시지:
echo    AGENTS.md, SPEC.md, HANDOFF.md 있으면, docs\notes.json 맨 위를 읽어 줘.
echo    읽고 나서 지금 상태와 남은 일을 3줄로 요약하고, 애매한 점이 있으면 물어봐.
echo    코드는 내가 "시작해"라고 하면 써 줘.
echo ==================================================
echo.
pause
exit /b 0

rem ---------- 도구 설치 ----------
:need_git
echo   Git이 없어요.
call :offer_install Git.Git Git
goto :restart_needed
:need_node
echo   Node.js가 없어요.
call :offer_install OpenJS.NodeJS.LTS Node.js
goto :restart_needed
:old_node
for /f "delims=" %%v in ('node -v') do echo   지금 Node.js %%v - 22.13 이상이 필요해요.
call :offer_install OpenJS.NodeJS.LTS Node.js
goto :restart_needed

:offer_install
where winget >nul 2>&1
if errorlevel 1 (
  echo   winget이 없어요. %~2를 직접 설치해 주세요.
  exit /b 1
)
choice /c YN /m "  winget으로 %~2를 설치할까요"
if errorlevel 2 exit /b 1
winget install -e --id %~1 --accept-package-agreements --accept-source-agreements
exit /b %errorlevel%

:restart_needed
echo.
echo   설치가 끝났거나 직접 설치해야 해요. 새 도구가 보이도록 이 창을 닫고 install.bat을 다시 실행해 주세요.
pause
exit /b 1

rem ---------- 실패 ----------
:dirty
echo.
echo [실패] 커밋하지 않은 변경이 있어요. 덮어쓰지 않도록 여기서 멈춰요.
git status --short
echo   변경을 커밋하거나 정리한 뒤 다시 실행해 주세요.
pause
exit /b 1
:fail_clone
echo.
echo [실패] 저장소를 내려받지 못했어요: %REPO_URL%
echo   인터넷 연결과 GitHub 로그인, eden-0721 저장소 권한을 확인해 주세요.
pause
exit /b 1
:fail_git
echo.
echo [실패] %BRANCH% 브랜치를 최신으로 맞추지 못했어요. 위 git 메시지를 확인해 주세요.
pause
exit /b 1
:fail_wrangler
echo.
echo [실패] wrangler 설치 또는 실행에 실패했어요. 관리자 권한 없이 npm install -g wrangler --force 를 직접 실행해 보세요.
pause
exit /b 1
:fail_login
echo.
echo [실패] Cloudflare 로그인이 끝나지 않았어요. 다시 실행해 주세요.
pause
exit /b 1
:fail_check
echo.
echo [실패] 규칙 검사 node scripts\check.mjs 가 실패했어요. 위 "실패:" 줄을 AI에게 보여 주세요.
pause
exit /b 1
:fail_test
echo.
echo [실패] 시험 node scripts\test.mjs 가 실패했어요. 위 "실패" 줄을 AI에게 보여 주세요.
pause
exit /b 1
