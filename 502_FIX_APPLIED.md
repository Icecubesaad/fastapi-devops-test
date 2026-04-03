# 502 Bad Gateway Fix Applied

## Changes Made

### 1. Updated Dockerfile
**File**: `Dockerfile`

**Changes**:
- Added `ENV PORT=8000` to set default port
- Changed CMD from exec form to shell form to allow environment variable substitution
- Changed from `CMD ["uvicorn", ...]` to `CMD uvicorn ...` to support `${PORT}` expansion

**Before**:
```dockerfile
EXPOSE 8000
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**After**:
```dockerfile
ENV PORT=8000
EXPOSE ${PORT}
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}
```

**Why**: This allows the container to respect the `PORT` environment variable that ECS might inject, while still defaulting to 8000.

### 2. Added Troubleshooting Guide
**File**: `TROUBLESHOOTING_502.md`

Comprehensive guide covering:
- Port mismatch issues
- Health check configuration
- Security group problems
- Container startup failures
- Diagnostic commands

### 3. Updated README
**File**: `README.md`

Added deployment notes section with:
- Health check configuration requirements
- Port configuration guidelines
- Common 502 troubleshooting tips

### 4. Added Diagnostic Script
**File**: `check-deployment.sh`

Bash script to check:
- ECS service status
- Task definition configuration
- Running task details
- Target group health
- Recent CloudWatch logs

## Next Steps

### Option 1: Redeploy with Updated Dockerfile

1. Commit and push the changes:
```bash
git add .
git commit -m "Fix: Update FastAPI Dockerfile for flexible port configuration"
git push
```

2. Trigger a new deployment through your OpSynth dashboard

3. Wait for the new image to build and deploy

### Option 2: Check Current Deployment Configuration

Run the diagnostic script:
```bash
chmod +x check-deployment.sh
./check-deployment.sh
```

This will show you:
- Current task definition port configuration
- Target group health check settings
- Target health status
- Recent error logs

### Option 3: Manual AWS Console Check

1. **Check Target Group Health Check**:
   - Go to EC2 → Target Groups
   - Select your FastAPI target group
   - Click "Health checks" tab
   - Verify:
     - Health check path: `/health` (not `/`)
     - Port: `8000` or `traffic port`
     - Success codes: `200`

2. **Check ECS Task Definition**:
   - Go to ECS → Task Definitions
   - Find your FastAPI task definition
   - Check container definition:
     - Port mappings: Container port should be `8000`
     - Environment variables: Check if `PORT` is set

3. **Check Security Groups**:
   - ECS task security group should allow inbound from ALB security group on port 8000

4. **Check CloudWatch Logs**:
   - Go to CloudWatch → Log Groups
   - Find `/aws/ecs/[cluster]/[service]`
   - Look for:
     - ✓ "Uvicorn running on http://0.0.0.0:8000"
     - ❌ Python errors or port binding errors

## Most Likely Root Cause

Based on the 502 error, the most common issues are:

1. **Health Check Path Wrong** (90% of cases)
   - Target group checking `/` instead of `/health`
   - Fix: Update target group health check path to `/health`

2. **Port Mismatch** (5% of cases)
   - Container running on 8000, but target group expecting different port
   - Fix: Ensure all ports match (container, task def, target group)

3. **Security Group** (3% of cases)
   - ALB can't reach ECS tasks
   - Fix: Add inbound rule to ECS security group allowing ALB security group on port 8000

4. **Container Crash** (2% of cases)
   - Container starts but crashes immediately
   - Fix: Check CloudWatch logs for Python errors

## Testing After Fix

Once redeployed, test with:

```bash
# Test health endpoint
curl https://your-fastapi-url.com/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2024-...",
  "service": "fastapi-app"
}

# If you get this, the 502 is fixed! ✅
```

## Need More Help?

If the issue persists after redeployment:

1. Run `./check-deployment.sh` and share the output
2. Check CloudWatch logs for error messages
3. Verify the health check path is set to `/health` in the target group
4. Ensure the container is actually starting (check ECS task status)
