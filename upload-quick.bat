@echo off
echo Uploading updated files to S3...
echo.

echo Uploading index.html...
aws s3 cp index.html s3://mybibleworld.xyz/index.html --content-type "text/html" --cache-control "public, max-age=3600"

echo Uploading about.html...
aws s3 cp about.html s3://mybibleworld.xyz/about.html --content-type "text/html" --cache-control "public, max-age=3600"

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