import subprocess
import sys
import os

import json
import time

# --- Configuration ---
BUCKET_NAME = "rcfconnect.in"
DISTRIBUTION_ID = "E2AZR6PTEF5JFA"
AWS_PROFILE = "rcf"
# Files/Folders to exclude from upload
EXCLUDES = [
    ".git/*",
    "*.json",           # Exclude config files
    "lambda/*",         # Exclude backend code
    "readme.txt",
    "node_modules/*",
    "*.py",             # Exclude this script
    ".DS_Store",
    "task.md",
    "implementation_plan.md",
    "walkthrough.md",
    "ssl-dns-validation.md",
    "dns-setup.md",
    "seo_plan.md",
    "*.log"
]

def run_command(command):
    """Runs a shell command and prints output."""
    try:
        print(f"Running: {' '.join(command)}")
        # On Windows, shell=True is often needed for command resolution if not using full path
        is_windows = sys.platform.startswith('win')
        subprocess.check_call(command, shell=is_windows)
        return True
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        return False
    except FileNotFoundError:
        print("Error: 'aws' command not found. Please ensure AWS CLI is installed and in your PATH.")
        return False

def get_command_output(command):
    """Runs a command and returns its stdout as a string."""
    try:
        # print(f"Running (capturing output): {' '.join(command)}")
        is_windows = sys.platform.startswith('win')
        # using check=True to raise exception on failure
        result = subprocess.run(command, shell=is_windows, capture_output=True, text=True, check=True)
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        print(f"Stderr: {e.stderr}")
        return None

def deploy():
    print(f"Starting deployment to {BUCKET_NAME}...")

    # 1. Sync files to S3
    print("\n--- Step 1: Syncing files to S3 ---")
    sync_cmd = [
        "aws", "s3", "sync", ".", f"s3://{BUCKET_NAME}",
        "--profile", AWS_PROFILE,
        "--delete"  # Removes files in S3 that are no longer locally present
    ]
    
    # Add exclusions
    for exclude in EXCLUDES:
        sync_cmd.extend(["--exclude", exclude])
        
    if not run_command(sync_cmd):
        print("❌ S3 Sync failed. Aborting.")
        sys.exit(1)
        
    # 2. Invalidate CloudFront
    print("\n--- Step 2: Invalidating CloudFront Cache ---")
    invalidate_cmd = [
        "aws", "cloudfront", "create-invalidation",
        "--distribution-id", DISTRIBUTION_ID,
        "--paths", "/*",
        "--profile", AWS_PROFILE,
        "--output", "json",
        "--no-cli-pager"
    ]
    
    output = get_command_output(invalidate_cmd)
    if not output:
        print("❌ CloudFront invalidation failed.")
        sys.exit(1)
    
    print(output)
    
    try:
        invalidation_data = json.loads(output)
        invalidation_id = invalidation_data['Invalidation']['Id']
        print(f"Invalidation ID: {invalidation_id}")
    except (json.JSONDecodeError, KeyError) as e:
        print(f"❌ Failed to parse invalidation ID: {e}")
        sys.exit(1)

    # 3. Poll for completion
    print("\n--- Step 3: Waiting for Invalidation to Complete ---")
    while True:
        check_cmd = [
            "aws", "cloudfront", "get-invalidation",
            "--distribution-id", DISTRIBUTION_ID,
            "--id", invalidation_id,
            "--profile", AWS_PROFILE,
            "--output", "json",
            "--no-cli-pager"
        ]
        
        output = get_command_output(check_cmd)
        if output:
            try:
                status_data = json.loads(output)
                status = status_data['Invalidation']['Status']
                print(f"Status: {status}")
                
                if status == 'Completed':
                    break
            except (json.JSONDecodeError, KeyError):
                print("Warning: Could not parse status, retrying...")
        
        print("Waiting 15 seconds...")
        time.sleep(15)
        
    print("\n✅ Deployment Complete! Your changes are live.")

if __name__ == "__main__":
    deploy()
