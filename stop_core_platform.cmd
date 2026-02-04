@echo off
echo Stopping core-platform containers...
docker compose -p core-platform -f merged.yml -f docker-compose.phase3.yml -f docker-compose.connect.yml down
echo Done.
pause
