@echo off
REM Cloud-Native Legal Document Processing System - Deployment Script for Windows

setlocal enabledelayedexpansion

REM Configuration
set ENVIRONMENT=%1
if "%ENVIRONMENT%"=="" set ENVIRONMENT=dev

set STACK_NAME=legal-doc-processing-%ENVIRONMENT%
set REGION=%AWS_REGION%
if "%REGION%"=="" set REGION=us-east-1

echo.
echo =========================================
echo Legal Document Processing System
echo Deployment Script (Windows)
echo =========================================
echo Environment: %ENVIRONMENT%
echo Stack Name: %STACK_NAME%
echo Region: %REGION%
echo =========================================
echo.

REM Check prerequisites
echo Checking prerequisites...

where sam >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: AWS SAM CLI is not installed
    echo Install from: https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
    exit /b 1
)

where aws >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: AWS CLI is not installed
    exit /b 1
)

echo [OK] Prerequisites check passed
echo.

REM Install Python dependencies
echo Installing Lambda dependencies...

set LAMBDA_DIRS=upload_handler summarize deviation_detection comparison_agent status

for %%d in (%LAMBDA_DIRS%) do (
    if exist "..\backend\lambdas\%%d\requirements.txt" (
        echo Installing dependencies for %%d...
        cd ..\backend\lambdas\%%d
        pip install -r requirements.txt -t . --upgrade
        cd ..\..\..\infrastructure
    )
)

echo [OK] Dependencies installed
echo.

REM Build SAM application
echo Building SAM application...
sam build --template-file template.yaml

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: SAM build failed
    exit /b 1
)

echo [OK] Build complete
echo.

REM Deploy
echo Deploying to AWS...
sam deploy ^
    --template-file .aws-sam\build\template.yaml ^
    --stack-name %STACK_NAME% ^
    --capabilities CAPABILITY_IAM ^
    --region %REGION% ^
    --parameter-overrides Environment=%ENVIRONMENT% ^
    --no-fail-on-empty-changeset ^
    --resolve-s3

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Deployment failed
    exit /b 1
)

echo [OK] Deployment complete
echo.

REM Get outputs
echo =========================================
echo Deployment Outputs
echo =========================================

aws cloudformation describe-stacks ^
    --stack-name %STACK_NAME% ^
    --region %REGION% ^
    --query "Stacks[0].Outputs[*].[OutputKey,OutputValue]" ^
    --output table

REM Run Glue crawler
echo.
echo Starting Glue crawler...
set CRAWLER_NAME=legal-doc-crawler-%ENVIRONMENT%
aws glue start-crawler --name %CRAWLER_NAME% --region %REGION% 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [OK] Glue crawler started
) else (
    echo [INFO] Crawler already running or not found
)

echo.
echo =========================================
echo Deployment Complete!
echo =========================================
echo.
echo Next steps:
echo 1. Copy the ApiEndpoint URL from above
echo 2. Update frontend\.env.production with the API endpoint
echo 3. Build and deploy frontend
echo.

endlocal
