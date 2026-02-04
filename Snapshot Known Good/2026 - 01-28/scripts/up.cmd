@echo off
setlocal

cd /d %~dp0\..

docker compose --project-directory . ^
  -f core-platform\docker-compose.yml ^
  -f ops\docker-compose.ops.yml ^
  --env-file .env.dev ^
  up -d

echo.
echo Stack is up.
echo Redpanda Console: http://localhost:8080
echo Grafana:          http://localhost:3000
echo Prometheus:       http://localhost:9090
echo MinIO Console:    http://localhost:9001
echo.
pause
