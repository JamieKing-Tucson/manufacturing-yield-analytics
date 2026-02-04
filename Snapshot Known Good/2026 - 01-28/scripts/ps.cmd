@echo off
setlocal
cd /d %~dp0\..

docker compose --project-directory . ^
  -f core-platform\docker-compose.yml ^
  -f ops\docker-compose.ops.yml ^
  --env-file .env.dev ^
  ps

echo.
pause
