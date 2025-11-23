# RCF Website Deployment Script
param(
    [string]$BucketName = "mybibleworld.xyz"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " RCF Website Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

try {
    # Step 1: Upload to S3
    Write-Host "[1/3] Uploading files to S3 bucket: $BucketName" -ForegroundColor Yellow
    Write-Host ""
    
    $syncArgs = @(
        "s3", "sync", ".", "s3://$BucketName",
        "--delete",
        "--exclude", "*.bat",
        "--exclude", "*.ps1", 
        "--exclude", "*.json",
        "--exclude", "readme.txt",
        "--exclude", ".git/*",
        "--exclude", "*.md"
    )
    
    & aws @syncArgs
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to upload to S3"
    }
    
    Write-Host ""
    Write-Host "✓ S3 upload completed successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Step 2: Get CloudFront Distribution ID
    Write-Host "[2/3] Getting CloudFront Distribution ID..." -ForegroundColor Yellow
    
    $distributionId = aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items && contains(Aliases.Items, '`$BucketName')].Id" --output text
    
    if ([string]::IsNullOrWhiteSpace($distributionId)) {
        Write-Host "Warning: Could not find CloudFront distribution for $BucketName" -ForegroundColor Yellow
        Write-Host "Please manually invalidate CloudFront cache if needed." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Found Distribution ID: $distributionId" -ForegroundColor Green
    Write-Host ""
    
    # Step 3: Create CloudFront Invalidation
    Write-Host "[3/3] Creating CloudFront invalidation..." -ForegroundColor Yellow
    
    $invalidationResult = aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*" --output json | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create CloudFront invalidation"
    }
    
    Write-Host ""
    Write-Host "✓ CloudFront invalidation created successfully!" -ForegroundColor Green
    Write-Host "Invalidation ID: $($invalidationResult.Invalidation.Id)" -ForegroundColor Cyan
    Write-Host ""
    
    # Success message
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Deployment completed successfully!" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your website should be updated at:" -ForegroundColor White
    Write-Host "- https://$BucketName" -ForegroundColor Cyan
    Write-Host "- https://www.$BucketName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Note: CloudFront cache invalidation may take 5-15 minutes to complete." -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}