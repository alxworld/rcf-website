# Advanced RCF Website Deployment Script with Content-Type optimization
param(
    [string]$BucketName = "mybibleworld.xyz"
)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host " RCF Advanced Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Content type mappings for better caching and performance
$contentTypes = @{
    ".html" = "text/html"
    ".css"  = "text/css"
    ".js"   = "application/javascript"
    ".json" = "application/json"
    ".jpg"  = "image/jpeg"
    ".jpeg" = "image/jpeg"
    ".jfif" = "image/jpeg"
    ".png"  = "image/png"
    ".svg"  = "image/svg+xml"
    ".ico"  = "image/x-icon"
    ".webmanifest" = "application/manifest+json"
}

try {
    Write-Host "[1/4] Uploading files with optimized content types..." -ForegroundColor Yellow
    Write-Host ""
    
    # Get all files to upload
    $files = Get-ChildItem -Recurse -File | Where-Object { 
        $_.Name -notmatch '\.(bat|ps1|md)$' -and 
        $_.Name -ne 'readme.txt' -and
        $_.DirectoryName -notmatch '\.git'
    }
    
    $totalFiles = $files.Count
    $current = 0
    
    foreach ($file in $files) {
        $current++
        $relativePath = $file.FullName.Substring((Get-Location).Path.Length + 1).Replace('\', '/')
        $extension = $file.Extension.ToLower()
        
        Write-Progress -Activity "Uploading files" -Status "Processing $($file.Name)" -PercentComplete (($current / $totalFiles) * 100)
        
        $uploadArgs = @("s3", "cp", $file.FullName, "s3://$BucketName/$relativePath")
        
        # Set content type if we have a mapping
        if ($contentTypes.ContainsKey($extension)) {
            $uploadArgs += "--content-type"
            $uploadArgs += $contentTypes[$extension]
        }
        
        # Set cache control based on file type
        if ($extension -in @('.css', '.js', '.jpg', '.jpeg', '.png', '.svg', '.ico', '.jfif')) {
            $uploadArgs += "--cache-control"
            $uploadArgs += "public, max-age=31536000"  # 1 year for static assets
        } elseif ($extension -eq '.html') {
            $uploadArgs += "--cache-control"
            $uploadArgs += "public, max-age=3600"  # 1 hour for HTML files
        }
        
        & aws @uploadArgs
        
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to upload $($file.Name)"
        }
    }
    
    Write-Progress -Activity "Uploading files" -Completed
    Write-Host ""
    Write-Host "✓ Uploaded $totalFiles files successfully!" -ForegroundColor Green
    Write-Host ""
    
    # Step 2: Clean up old files
    Write-Host "[2/4] Syncing and cleaning up old files..." -ForegroundColor Yellow
    
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
        throw "Failed to sync with S3"
    }
    
    Write-Host "✓ S3 sync completed!" -ForegroundColor Green
    Write-Host ""
    
    # Step 3: Get CloudFront Distribution ID
    Write-Host "[3/4] Getting CloudFront Distribution ID..." -ForegroundColor Yellow
    
    $distributionId = aws cloudfront list-distributions --query "DistributionList.Items[?Aliases.Items && contains(Aliases.Items, '$BucketName')].Id" --output text
    
    if ([string]::IsNullOrWhiteSpace($distributionId)) {
        Write-Host "Warning: Could not find CloudFront distribution for $BucketName" -ForegroundColor Yellow
        Write-Host "Please manually invalidate CloudFront cache if needed." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Found Distribution ID: $distributionId" -ForegroundColor Green
    Write-Host ""
    
    # Step 4: Create CloudFront Invalidation
    Write-Host "[4/4] Creating CloudFront invalidation..." -ForegroundColor Yellow
    
    $invalidationResult = aws cloudfront create-invalidation --distribution-id $distributionId --paths "/*" --output json | ConvertFrom-Json
    
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create CloudFront invalidation"
    }
    
    Write-Host ""
    Write-Host "✓ CloudFront invalidation created successfully!" -ForegroundColor Green
    Write-Host "Invalidation ID: $($invalidationResult.Invalidation.Id)" -ForegroundColor Cyan
    Write-Host ""
    
    # Success message with performance tips
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " Deployment completed successfully!" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Your website is now updated at:" -ForegroundColor White
    Write-Host "- https://$BucketName" -ForegroundColor Cyan
    Write-Host "- https://www.$BucketName" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Performance optimizations applied:" -ForegroundColor Green
    Write-Host "✓ Proper content types set for all files" -ForegroundColor White
    Write-Host "✓ Long-term caching for static assets (CSS, JS, images)" -ForegroundColor White
    Write-Host "✓ Short-term caching for HTML files" -ForegroundColor White
    Write-Host "✓ CloudFront cache invalidated" -ForegroundColor White
    Write-Host ""
    Write-Host "Note: CloudFront cache invalidation may take 5-15 minutes to complete." -ForegroundColor Yellow
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    exit 1
}