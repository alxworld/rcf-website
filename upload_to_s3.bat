@echo off
echo Uploading all files to S3 bucket: mybibleworld.xyz
aws s3 sync . s3://mybibleworld.xyz --delete
echo Upload complete!
pause