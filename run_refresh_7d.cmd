@echo off
setlocal
cd /d "%~dp0"

REM 1) Docker running?
docker info >nul 2>&1
if errorlevel 1 goto DOCKER_FAIL

REM 2) Find Trino container id (simple match)
set "TRINO_ID="
for /f %%i in ('docker ps -q -f "name=trino"') do set "TRINO_ID=%%i"
if "%TRINO_ID%"=="" goto TRINO_FAIL

echo Running 7-day refresh...

REM 3) Run the SQL in Trino
docker exec -i %TRINO_ID% trino --server http://localhost:8080 --catalog iceberg --schema raw < refresh_7d.sql
if errorlevel 1 goto RUN_FAIL

echo Refresh OK.
exit /b 0

:DOCKER_FAIL
echo ERROR: Docker is not running.
exit /b 1

:TRINO_FAIL
echo ERROR: Trino container not found/running (expected name contains "trino").
exit /b 2

:RUN_FAIL
echo ERROR: Refresh failed (Trino returned non-zero).
exit /b 3
