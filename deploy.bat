@echo off
setlocal enabledelayedexpansion

echo ========================================
echo  RCF Website Deployment Script
echo ========================================
echo.

set BUCKET_NAME=mybibleworld.xyz
set DISTRIBUTION_ID=

echo [1/3] Uploading files to S3 bucket: %BUCKET_NAME%
echo.

REM Upload with proper content types and cache control
aws s3 sync . s3://%BUCKET_NAME% ^
    --delete ^
    --exclude "*.bat" ^
    --exclude "*.json" ^
    --exclude "readme.txt" ^
    --exclude ".git/*" ^
    --exclude "*.md" ^
    --cache-control "public, max-age=31536000" ^
    --metadata-directive REPLACE

if %errorlevel% neq 0 (
    echo ERROR: Failed to upload to S3
    pause
    exit /b 1
)

echo.
echo ✓ S3 upload completed successfully!
echo.

echo [2/3] Getting CloudFront Distribution ID...

REM Get the distribution ID for the domain
for /f "tokens=2 delims= " %%i in ('aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items[0]=='%BUCKET_NAME%'].Id" --output text') do (
    set DISTRIBUTION_ID=%%i
)

if "%DISTRIBUTION_ID%"=="" (
    echo Warning: Could not find CloudFront distribution for %BUCKET_NAME%
    echo Please manually invalidate CloudFront cache if needed.
    goto :end
)

echo Found Distribution ID: %DISTRIBUTION_ID%
echo.

echo [3/3] Creating CloudFront invalidation...

aws cloudfront create-invalidation ^
    --distribution-id %DISTRIBUTION_ID% ^
    --paths "/*"

if %errorlevel% neq 0 (
    echo ERROR: Failed to create CloudFront invalidation
    pause
    exit /b 1
)

echo.
echo ✓ CloudFront invalidation created successfully!
echo.

:end
echo ========================================
echo  Deployment completed successfully!
echo ========================================
echo.
echo Your website should be updated at:
echo - https://%BUCKET_NAME%
echo - https://www.%BUCKET_NAME%
echo.
echo Note: CloudFront cache invalidation may take 5-15 minutes to complete.
echo.
pause