@echo off
REM Start Local Development Script for Windows
REM This script starts both the mock server and frontend

echo.
echo ========================================
echo Starting Legal Document Processing System (Local Mode)
echo ========================================
echo.

REM Check if Node.js is installed
where node >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Node.js is not installed!
    echo Please install Node.js 18+ from https://nodejs.org/
    pause
    exit /b 1
)

echo Node.js version:
node --version
echo.

REM Install mock server dependencies if needed
if not exist "mock-server\node_modules" (
    echo Installing mock server dependencies...
    cd mock-server
    call npm install
    cd ..
    echo Mock server dependencies installed
    echo.
)

REM Install frontend dependencies if needed
if not exist "frontend\node_modules" (
    echo Installing frontend dependencies...
    cd frontend
    call npm install
    cd ..
    echo Frontend dependencies installed
    echo.
)

REM Create .env.development if it doesn't exist
if not exist "frontend\.env.development" (
    echo Creating frontend .env.development...
    echo REACT_APP_API_ENDPOINT=http://localhost:3001 > frontend\.env.development
    echo Frontend environment configured
    echo.
)

echo ========================================
echo Starting servers...
echo ========================================
echo.
echo Mock Server will run on: http://localhost:3001
echo Frontend will run on: http://localhost:3000
echo.
echo Press Ctrl+C to stop both servers
echo.

REM Start mock server in new window
start "Mock Server" cmd /k "cd mock-server && npm start"

REM Wait a bit for mock server to start
timeout /t 3 /nobreak >nul

REM Start frontend in new window
start "Frontend" cmd /k "cd frontend && npm start"

echo.
echo Both servers started in separate windows!
echo Close the windows to stop the servers.
echo.
pause
