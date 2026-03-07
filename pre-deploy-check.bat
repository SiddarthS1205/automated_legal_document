@echo off
REM Pre-Deployment Verification Script for Windows
REM Checks if all prerequisites are met before AWS deployment

echo.
echo ================================================================
echo.
echo      AWS Deployment Pre-Flight Check
echo.
echo ================================================================
echo.

set ERRORS=0
set WARNINGS=0

REM Check Node.js
echo Checking Node.js...
where node >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Node.js installed
    node --version
) else (
    echo [ERROR] Node.js NOT installed
    echo Install from: https://nodejs.org/
    set /a ERRORS+=1
)
echo.

REM Check Python
echo Checking Python...
where python >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Python installed
    python --version
) else (
    echo [ERROR] Python NOT installed
    echo Install from: https://www.python.org/
    set /a ERRORS+=1
)
echo.

REM Check pip
echo Checking pip...
where pip >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] pip installed
    pip --version
) else (
    echo [ERROR] pip NOT installed
    set /a ERRORS+=1
)
echo.

REM Check AWS CLI
echo Checking AWS CLI...
where aws >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] AWS CLI installed
    aws --version
) else (
    echo [ERROR] AWS CLI NOT installed
    echo Install from: https://aws.amazon.com/cli/
    set /a ERRORS+=1
)
echo.

REM Check AWS SAM CLI
echo Checking AWS SAM CLI...
where sam >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] AWS SAM CLI installed
    sam --version
) else (
    echo [ERROR] AWS SAM CLI NOT installed
    echo Install from: https://aws.amazon.com/serverless/sam/
    set /a ERRORS+=1
)
echo.

REM Check Git
echo Checking Git...
where git >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Git installed
    git --version
) else (
    echo [WARNING] Git NOT installed
    echo Install from: https://git-scm.com/
    set /a WARNINGS+=1
)
echo.

REM Check AWS Credentials
echo Checking AWS Credentials...
aws sts get-caller-identity >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] AWS credentials configured
    aws sts get-caller-identity --query Account --output text
) else (
    echo [ERROR] AWS credentials NOT configured
    echo Run: aws configure
    set /a ERRORS+=1
)
echo.

REM Check SAM Template
echo Checking SAM Template...
if exist "infrastructure\template.yaml" (
    echo [OK] infrastructure\template.yaml found
) else (
    echo [ERROR] infrastructure\template.yaml NOT found
    set /a ERRORS+=1
)
echo.

REM Check Frontend
echo Checking Frontend...
if exist "frontend\package.json" (
    echo [OK] frontend\package.json found
    if exist "frontend\node_modules" (
        echo [OK] frontend dependencies installed
    ) else (
        echo [WARNING] frontend dependencies not installed
        echo Run: cd frontend ^&^& npm install
        set /a WARNINGS+=1
    )
) else (
    echo [ERROR] frontend\package.json NOT found
    set /a ERRORS+=1
)
echo.

REM Summary
echo ================================================================
echo.
echo      Pre-Flight Check Summary
echo.
echo ================================================================
echo.

if %ERRORS% EQU 0 (
    if %WARNINGS% EQU 0 (
        echo [SUCCESS] All checks passed! You're ready to deploy.
        echo.
        echo Next steps:
        echo 1. cd infrastructure
        echo 2. deploy.bat dev
        echo.
    ) else (
        echo [WARNING] %WARNINGS% warning(s) found, but you can proceed.
        echo.
        echo Next steps:
        echo 1. cd infrastructure
        echo 2. deploy.bat dev
        echo.
    )
) else (
    echo [ERROR] %ERRORS% error(s) and %WARNINGS% warning(s) found.
    echo.
    echo Please fix the errors above before deploying.
    echo.
)

pause
