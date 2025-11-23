# Upload specific updated files to S3 and invalidate CloudFront
param(
    [string[]]$Files = @("index.html", "about.html"),
    [string]$BucketName = "mybibleworld.xyz"
)

Write-Host "Uploading updated files to S3..." -ForegroundColor Yellow

foreach ($file in $Files) {
    if (Test-Path $file) {
        Write-Host "Uploading $file..." -ForegroundColor Cyan
        aws s3 cp $file "s3://$BucketName/$file" --content-type "text/html" --cache-control "public, max-age=3600"
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✓ $file uploaded" -ForegroundColor Green
        } else {
            Write-Host "✗ Failed to upload $file" -ForegroundColor Red
        }
    }
}

Write-Host "`nInvalidating CloudFront cache..." -ForegroundColor Yellow
$distributionId = aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items && contains(Aliases.Items, ``'$BucketName``')].Id" --output text

if ($distributionId) {
    $paths = $Files | ForEach-Object { "/$_" }
    aws cloudfront create-invalidation --distribution-id $distributionId --paths $paths
    Write-Host "✓ CloudFront invalidation created for: $($paths -join ', ')" -ForegroundColor Green
} else {
    Write-Host "✗ CloudFront distribution not found" -ForegroundColor Red
}

Write-Host "`nDone! Files updated at https://$BucketName" -ForegroundColor Cyan