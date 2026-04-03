#!/bin/bash
# FastAPI Deployment Health Check Script

echo "🔍 FastAPI Deployment Diagnostics"
echo "=================================="
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI not found. Please install it first."
    exit 1
fi

# Get cluster and service names
echo "📋 Enter your deployment details:"
read -p "Cluster name: " CLUSTER_NAME
read -p "Service name: " SERVICE_NAME

echo ""
echo "1️⃣ Checking ECS Service Status..."
echo "-----------------------------------"
aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --query 'services[0].{Status:status,Running:runningCount,Desired:desiredCount,Deployments:deployments[0].{Status:rolloutState,Running:runningCount}}' \
  --output table

echo ""
echo "2️⃣ Checking Task Definition..."
echo "-----------------------------------"
TASK_DEF=$(aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --query 'services[0].taskDefinition' \
  --output text)

echo "Task Definition: $TASK_DEF"

aws ecs describe-task-definition \
  --task-definition "$TASK_DEF" \
  --query 'taskDefinition.containerDefinitions[0].{Name:name,Image:image,Port:portMappings[0].containerPort,Environment:environment}' \
  --output table

echo ""
echo "3️⃣ Checking Running Tasks..."
echo "-----------------------------------"
TASK_ARNS=$(aws ecs list-tasks \
  --cluster "$CLUSTER_NAME" \
  --service-name "$SERVICE_NAME" \
  --query 'taskArns[0]' \
  --output text)

if [ "$TASK_ARNS" != "None" ] && [ -n "$TASK_ARNS" ]; then
    echo "Task ARN: $TASK_ARNS"
    
    # Get task details
    aws ecs describe-tasks \
      --cluster "$CLUSTER_NAME" \
      --tasks "$TASK_ARNS" \
      --query 'tasks[0].{Status:lastStatus,Health:healthStatus,IP:containers[0].networkInterfaces[0].privateIpv4Address}' \
      --output table
    
    # Get task IP for direct testing
    TASK_IP=$(aws ecs describe-tasks \
      --cluster "$CLUSTER_NAME" \
      --tasks "$TASK_ARNS" \
      --query 'tasks[0].containers[0].networkInterfaces[0].privateIpv4Address' \
      --output text)
    
    echo ""
    echo "Task Private IP: $TASK_IP"
    echo "To test directly: curl http://$TASK_IP:8000/health"
else
    echo "❌ No running tasks found!"
fi

echo ""
echo "4️⃣ Checking Target Group Health..."
echo "-----------------------------------"
# Get target group ARN from service
TG_ARN=$(aws ecs describe-services \
  --cluster "$CLUSTER_NAME" \
  --services "$SERVICE_NAME" \
  --query 'services[0].loadBalancers[0].targetGroupArn' \
  --output text)

if [ "$TG_ARN" != "None" ] && [ -n "$TG_ARN" ]; then
    echo "Target Group: $TG_ARN"
    
    # Check health check configuration
    echo ""
    echo "Health Check Configuration:"
    aws elbv2 describe-target-groups \
      --target-group-arns "$TG_ARN" \
      --query 'TargetGroups[0].{Port:Port,Protocol:Protocol,HealthCheckPath:HealthCheckPath,HealthCheckPort:HealthCheckPort,HealthCheckProtocol:HealthCheckProtocol,HealthyThreshold:HealthyThresholdCount,UnhealthyThreshold:UnhealthyThresholdCount,Timeout:HealthCheckTimeoutSeconds,Interval:HealthCheckIntervalSeconds}' \
      --output table
    
    # Check target health
    echo ""
    echo "Target Health Status:"
    aws elbv2 describe-target-health \
      --target-group-arn "$TG_ARN" \
      --query 'TargetHealthDescriptions[*].{Target:Target.Id,Port:Target.Port,State:TargetHealth.State,Reason:TargetHealth.Reason,Description:TargetHealth.Description}' \
      --output table
else
    echo "⚠️  No target group found (might be EC2 deployment)"
fi

echo ""
echo "5️⃣ Checking Recent Logs..."
echo "-----------------------------------"
LOG_GROUP="/aws/ecs/$CLUSTER_NAME/$SERVICE_NAME"
echo "Log Group: $LOG_GROUP"
echo ""
echo "Recent logs (last 20 lines):"
aws logs tail "$LOG_GROUP" --since 5m --format short 2>/dev/null || echo "⚠️  Could not fetch logs. Check log group name."

echo ""
echo "=================================="
echo "✅ Diagnostics Complete"
echo ""
echo "Common 502 Fixes:"
echo "1. Health check path should be: /health"
echo "2. Container port should be: 8000"
echo "3. Target group port should be: 8000"
echo "4. Security group should allow ALB → ECS on port 8000"
echo "5. Check logs for startup errors"
