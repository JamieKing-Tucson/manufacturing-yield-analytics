@echo off
setlocal enabledelayedexpansion

REM ============================================================
REM restore_snapshot.cmd
REM Restores MinIO + Iceberg catalog + Grafana volumes from tar.gz
REM
REM Usage:
REM   restore_snapshot.cmd              (uses default prefix: site-a)
REM   restore_snapshot.cmd <prefix>     (e.g., core-platform)
REM
REM Expected files in .\backups\ :
REM   minio-data.tar.gz
REM   iceberg-catalog.tar.gz
REM   grafana-data.tar.gz
REM ============================================================

set PREFIX=%1
if "%PREFIX%"=="" set PREFIX=site-a

set BACKUP_DIR=%cd%\backups
set MINIO_TAR=%BACKUP_DIR%\minio-data.tar.gz
set CATALOG_TAR=%BACKUP_DIR%\iceberg-catalog.tar.gz
set GRAFANA_TAR=%BACKUP_DIR%\grafana-data.tar.gz

set MINIO_VOL=%PREFIX%_minio-data
set CATALOG_VOL=%PREFIX%_iceberg_rest_db
set GRAFANA_VOL=%PREFIX%_grafana-data

echo.
echo === Restore Snapshot ===
echo Prefix      : %PREFIX%
echo Backup dir  : %BACKUP_DIR%
echo Volumes     : %MINIO_VOL%, %CATALOG_VOL%, %GRAFANA_VOL%
echo.

REM ---- File checks ----
if not exist "%MINIO_TAR%" (
  echo ERROR: Missing "%MINIO_TAR%"
  exit /b 1
)
if not exist "%CATALOG_TAR%" (
  echo ERROR: Missing "%CATALOG_TAR%"
  exit /b 1
)
if not exist "%GRAFANA_TAR%" (
  echo ERROR: Missing "%GRAFANA_TAR%"
  exit /b 1
)

echo Checking Docker is available...
docker version >nul 2>&1
if errorlevel 1 (
  echo ERROR: Docker is not running or not installed. Start Docker Desktop and retry.
  exit /b 1
)

REM ---- Verify volumes exist ----
for %%V in ("%MINIO_VOL%" "%CATALOG_VOL%" "%GRAFANA_VOL%") do (
  docker volume inspect %%~V >nul 2>&1
  if errorlevel 1 (
    echo ERROR: Volume not found: %%~V
    echo Run:
    echo   docker compose -f merged.yml -f docker-compose.phase3.yml -f docker-compose.connect.yml up -d
    echo   docker compose -f merged.yml -f docker-compose.phase3.yml -f docker-compose.connect.yml down
    echo Then re-run this script.
    exit /b 1
  )
)

echo.
echo Restoring MinIO volume: %MINIO_VOL%
docker run --rm ^
  -v %MINIO_VOL%:/v ^
  -v "%BACKUP_DIR%":/backup ^
  alpine sh -c "rm -rf /v/* && cd /v && tar -xzf /backup/minio-data.tar.gz"
if errorlevel 1 exit /b 1

echo.
echo Restoring Iceberg catalog volume: %CATALOG_VOL%
docker run --rm ^
  -v %CATALOG_VOL%:/v ^
  -v "%BACKUP_DIR%":/backup ^
  alpine sh -c "rm -rf /v/* && cd /v && tar -xzf /backup/iceberg-catalog.tar.gz"
if errorlevel 1 exit /b 1

echo.
echo Restoring Grafana volume: %GRAFANA_VOL%
docker run --rm ^
  -v %GRAFANA_VOL%:/v ^
  -v "%BACKUP_DIR%":/backup ^
  alpine sh -c "rm -rf /v/* && cd /v && tar -xzf /backup/grafana-data.tar.gz"
if errorlevel 1 exit /b 1

echo.
echo SUCCESS: Snapshot restored.
echo Next, start the stack:
echo   docker compose -f merged.yml -f docker-compose.phase3.yml -f docker-compose.connect.yml up -d
echo.
endlocal
