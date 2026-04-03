# FastAPI Test Application

Simple FastAPI application for deployment testing with OpSynth.

## Features

- RESTful API with CRUD operations
- Health check endpoint
- Auto-generated OpenAPI docs
- CORS enabled
- In-memory data storage

## Endpoints

- `GET /` - Root endpoint with API info
- `GET /health` - Health check (for load balancer)
- `GET /docs` - Interactive API documentation (Swagger UI)
- `GET /redoc` - Alternative API documentation
- `GET /items` - List all items
- `POST /items` - Create new item
- `GET /items/{id}` - Get item by ID
- `GET /users` - List all users
- `POST /users` - Create new user
- `GET /stats` - Application statistics

## Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run the application
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Access the API
curl http://localhost:8000/health

# View interactive docs
open http://localhost:8000/docs
```

## Docker Deployment

```bash
# Build image
docker build -t fastapi-app .

# Run container
docker run -p 8000:8000 fastapi-app

# Test
curl http://localhost:8000/health
```

## Environment Variables

- `PORT` - Server port (default: 8000)

## Deployment Notes

### Health Check Configuration

For AWS ECS/ALB deployments, configure the target group health check:

- **Health check path**: `/health`
- **Port**: 8000 (or value of PORT env var)
- **Success codes**: 200
- **Healthy threshold**: 2
- **Unhealthy threshold**: 2
- **Timeout**: 5 seconds
- **Interval**: 30 seconds

### Port Configuration

The application reads the `PORT` environment variable. If deploying to ECS:

1. Ensure the task definition container port matches the PORT env var
2. Ensure the target group port matches
3. Ensure security groups allow traffic on that port

### Troubleshooting 502 Bad Gateway

See [TROUBLESHOOTING_502.md](./TROUBLESHOOTING_502.md) for detailed debugging steps.

Common issues:
- Health check path not set to `/health`
- Port mismatch between container, task definition, and target group
- Security group not allowing traffic from ALB to ECS tasks
- Container not starting (check CloudWatch logs)

## Testing the Deployment

```bash
# Test health endpoint
curl https://your-domain.com/health

# Expected response:
{
  "status": "healthy",
  "timestamp": "2024-...",
  "service": "fastapi-app"
}

# Test API functionality
curl -X POST https://your-domain.com/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","price":9.99,"quantity":5}'

# View all items
curl https://your-domain.com/items
```
