$BucketName = "mybibleworld.xyz"
$Files = @("index.html", "about.html")

Write-Host "Uploading updated files to S3..." -ForegroundColor Yellow

foreach ($file in $Files) {
    if (Test-Path $file) {
        Write-Host "Uploading $file..." -ForegroundColor Cyan
        & aws s3 cp $file "s3://$BucketName/$file" --content-type "text/html" --cache-control "public, max-age=3600"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ $file uploaded" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to upload $file" -ForegroundColor Red
        }
    }
}

Write-Host ""
Write-Host "Invalidating CloudFront cache..." -ForegroundColor Yellow
$distributionId = & aws cloudfront list-distributions --query "DistributionList.Items[0].Id" --output text

if ($distributionId) {
    & aws cloudfront create-invalidation --distribution-id $distributionId --paths "/index.html" "/about.html"
    Write-Host "✓ CloudFront invalidation created" -ForegroundColor Green
} else {
    Write-Host "✗ CloudFront distribution not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "Done! Files updated at https://$BucketName" -ForegroundColor Cyan