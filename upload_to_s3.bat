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
echo ✓ Upload completed successfully!
echo.
echo Your website should be updated at:
echo - https://mybibleworld.xyz
echo - https://www.mybibleworld.xyz
echo.
echo Note: If you have CloudFront, run deploy.bat or deploy.ps1 for cache invalidation.
echo.
pause