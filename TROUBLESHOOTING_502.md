# FastAPI 502 Bad Gateway Troubleshooting

## Common Causes of 502 Bad Gateway

### 1. Port Mismatch
**Issue**: Container running on different port than load balancer expects

**Check**:
- Container is running on port 8000 ✓ (Dockerfile exposes 8000)
- ECS task definition container port should be 8000
- Target group should point to port 8000
- Load balancer listener should forward to target group

**Fix**: Verify in AWS Console:
```
ECS → Clusters → [your-cluster] → Services → [your-service] → Task Definition
→ Check containerDefinitions[0].portMappings[0].containerPort = 8000
```

### 2. Health Check Failure
**Issue**: Load balancer health checks failing, marking targets unhealthy

**Check**:
```bash
# Test health endpoint locally
curl http://[container-ip]:8000/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2024-...",
  "service": "fastapi-app"
}
```

**Fix in AWS Console**:
```
EC2 → Target Groups → [your-tg] → Health checks tab
- Health check path: /health
- Port: 8000
- Success codes: 200
- Healthy threshold: 2
- Unhealthy threshold: 2
- Timeout: 5 seconds
- Interval: 30 seconds
```

### 3. Security Group Configuration
**Issue**: Security groups blocking traffic between ALB and ECS tasks

**Check**:
- ALB security group allows inbound 80/443
- ECS task security group allows inbound from ALB security group on port 8000

**Fix**:
```
ECS Task Security Group Inbound Rules:
- Type: Custom TCP
- Port: 8000
- Source: [ALB Security Group ID]
```

### 4. Container Not Starting
**Issue**: Container crashes on startup

**Check ECS Logs**:
```
ECS → Clusters → [cluster] → Services → [service] → Logs tab
```

**Common FastAPI startup issues**:
- Missing dependencies in requirements.txt
- Python version mismatch
- Import errors in main.py

### 5. Wrong Start Command
**Issue**: Container starts but doesn't listen on correct port

**Verify Dockerfile CMD**:
```dockerfile
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
```

**NOT**:
```dockerfile
# ❌ Wrong - only listens on localhost
CMD ["uvicorn", "main:app", "--port", "8000"]

# ❌ Wrong - different port
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "80"]
```

## Quick Diagnostic Steps

### Step 1: Check ECS Task Status
```bash
aws ecs describe-services \
  --cluster [cluster-name] \
  --services [service-name] \
  --query 'services[0].{runningCount:runningCount,desiredCount:desiredCount}'
```

Expected: `runningCount` = `desiredCount`

### Step 2: Check Target Health
```bash
aws elbv2 describe-target-health \
  --target-group-arn [tg-arn]
```

Expected: `TargetHealth.State` = "healthy"

If "unhealthy", check `TargetHealth.Reason`

### Step 3: Check Container Logs
```bash
aws logs tail /aws/ecs/[cluster]/[service] --follow
```

Look for:
- ✓ "Uvicorn running on http://0.0.0.0:8000"
- ✓ "Application startup complete"
- ❌ Python errors
- ❌ Port binding errors

### Step 4: Test Container Directly
```bash
# Get task private IP
aws ecs describe-tasks \
  --cluster [cluster] \
  --tasks [task-arn] \
  --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address'

# SSH to bastion or use Session Manager, then:
curl http://[task-ip]:8000/health
```

## Most Likely Issues for FastAPI

### Issue: Port Environment Variable Override
Some deployment systems inject `PORT` env var that overrides the hardcoded port.

**Check**: Does your ECS task definition have a `PORT` environment variable?

**Fix**: Modify main.py to read from environment:
```python
import os

if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
```

But also update the CMD in Dockerfile:
```dockerfile
CMD ["sh", "-c", "uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}"]
```

### Issue: Health Check Path Wrong
Load balancer might be checking `/` instead of `/health`

**Fix**: Update target group health check path to `/health` or make root endpoint simpler:
```python
@app.get("/")
async def root():
    return {"status": "ok"}
```

## Recommended Fix

Based on the FastAPI app code, the most likely issue is:

1. **Health check configuration** - Target group health check might be timing out
2. **Port environment variable** - ECS might be injecting PORT env var

### Quick Fix:
Update the Dockerfile to be more flexible:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

# Use PORT env var if provided, default to 8000
ENV PORT=8000
EXPOSE ${PORT}

# Use shell form to allow env var substitution
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT}
```

Then redeploy the application.
