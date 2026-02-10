@echo off
setlocal

echo.
echo =========================================================
echo   VERIFY STACK (site-a)  -  quick health checks
echo =========================================================
echo.

REM ---- 0) Docker running? ----
docker version >nul 2>&1
if errorlevel 1 goto DOCKER_FAIL
echo [PASS] Docker CLI available
echo.

REM ---- 1) Containers up? ----
echo ---- Containers (running) ----
docker ps
echo.

REM ---- Helper: curl with a short timeout ----
set "CURL=curl -sS -f --max-time 5"

call :CHECK "Grafana" "http://localhost:3000/api/health" FAIL
call :CHECK "Trino" "http://localhost:18080/v1/info" FAIL
call :CHECK "Kafka Connect" "http://localhost:8083/connectors" FAIL

REM ---- 7) Kafka Connect connector/task status ----
call :CONNECTOR_CHECK "iceberg-sink"

call :CHECK "MinIO" "http://localhost:9000/minio/health/live" FAIL
call :CHECK "MinIO Console" "http://localhost:9001" WARN

echo =========================================================
echo Done.
echo If something FAILs, run:
echo   docker compose -f merged.yml -f docker-compose.phase3.yml -f docker-compose.connect.yml ps
echo   docker compose -f merged.yml -f docker-compose.phase3.yml -f docker-compose.connect.yml logs --tail 200 ^<service^>
echo =========================================================
echo.
exit /b 0

:DOCKER_FAIL
echo [FAIL] Docker Desktop not running (docker version failed).
echo        Start Docker Desktop and retry.
exit /b 1

:CHECK
REM Args: %1=Name  %2=URL  %3=FAIL|WARN
echo ---- %~1 (%~2) ----
%CURL% "%~2" >nul 2>&1
if errorlevel 1 goto CHECK_BAD
echo [PASS] %~1 responding
echo.
exit /b 0

:CHECK_BAD
if /I "%~3"=="WARN" goto CHECK_WARN
echo [FAIL] %~1 not responding
echo.
exit /b 0

:CHECK_WARN
echo [WARN] %~1 not responding (may be disabled or different port)
echo.
exit /b 0

:CONNECTOR_CHECK
REM %1 = connector name
set "CONN=%~1"
echo ---- Connect status (%CONN%) ----

%CURL% "http://localhost:8083/connectors/%CONN%/status" > "%TEMP%\connect_status.json" 2>nul
if errorlevel 1 goto CONNECTOR_WARN

findstr /I /C:"\"state\":\"FAILED\"" "%TEMP%\connect_status.json" >nul
if not errorlevel 1 goto CONNECTOR_FAIL

echo [PASS] Kafka Connect connector %CONN% shows no FAILED tasks
echo.
exit /b 0

:CONNECTOR_WARN
echo [WARN] Could not fetch connector status for %CONN% (check name or Connect auth)
echo        Tip: run curl http://localhost:8083/connectors to list connector names
echo.
exit /b 0

:CONNECTOR_FAIL
echo [FAIL] Kafka Connect connector %CONN% has FAILED state/task(s)
echo        Run: curl http://localhost:8083/connectors/%CONN%/status
echo.
exit /b 0
