@echo off
echo ========================================
echo  RCF Website Upload to S3
echo ========================================
echo.
echo Uploading all files to S3 bucket: mybibleworld.xyz
echo.

REM Upload with exclusions and proper settings
aws s3 sync . s3://mybibleworld.xyz ^--delete ^--exclude "*.bat" ^--exclude "*.ps1" ^--exclude "*.json" ^--exclude "readme.txt" ^--exclude ".git/*" ^--exclude "*.md"

if %errorlevel% neq 0 (
    echo ERROR: Upload failed!
    pause
    exit /b 1
)
echo.
echo Creating CloudFront invalidation...
for /f "tokens=*" %%i in ('aws cloudfront list-distributions --query "DistributionList.Items[0].Id" --output text') do set DIST_ID=%%i

if not "%DIST_ID%"=="" (
    aws cloudfront create-invalidation --distribution-id %DIST_ID% --paths "/index.html" "/about.html"
    echo ✓ CloudFront invalidation created
) else (
    echo ✗ CloudFront distribution not found
)

echo.
echo Done! Files updated at https://mybibleworld.xyz
pause