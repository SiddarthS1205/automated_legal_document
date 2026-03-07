@echo off
echo ========================================
echo AWS SAM Deployment - No Prompts
echo ========================================
echo.

REM Clean up invalid config file if it exists
if exist "infrastructure\y" (
    echo Removing invalid config file...
    del /f /q "infrastructure\y"
)

REM Navigate to infrastructure directory
cd infrastructure

echo Step 1: Building Lambda functions...
sam build --template-file template.yaml
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo.
echo Step 2: Deploying to AWS...
sam deploy --stack-name legal-doc-processing-dev --capabilities CAPABILITY_IAM --region us-east-1 --parameter-overrides Environment=dev --resolve-s3 --no-confirm-changeset

if %ERRORLEVEL% NEQ 0 (
    echo Deployment failed!
    pause
    exit /b 1
)

echo.
echo ========================================
echo Deployment Complete!
echo ========================================
echo.
echo Getting API endpoint...
aws cloudformation describe-stacks --stack-name legal-doc-processing-dev --query "Stacks[0].Outputs[?OutputKey=='ApiEndpoint'].OutputValue" --output text

echo.
echo Next steps:
echo 1. Copy the API endpoint URL above
echo 2. Update frontend/.env with: REACT_APP_API_URL=<your-api-endpoint>
echo 3. Run: cd frontend
echo 4. Run: npm start
echo.
pause
