# FastAPI Test Application

Simple FastAPI application for deployment testing.

## Features

- RESTful API endpoints
- In-memory data storage
- CRUD operations for items and users
- Health check endpoint
- Auto-generated API documentation

## Endpoints

- `GET /` - Root endpoint
- `GET /health` - Health check
- `GET /items` - List all items
- `POST /items` - Create item
- `GET /items/{id}` - Get item by ID
- `GET /users` - List all users
- `POST /users` - Create user
- `GET /stats` - Application statistics
- `GET /docs` - Interactive API documentation (Swagger UI)
- `GET /redoc` - Alternative API documentation

## Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run the application
python main.py

# Or with uvicorn directly
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

## Docker

```bash
# Build image
docker build -t fastapi-app .

# Run container
docker run -p 8000:8000 fastapi-app
```

## Testing

```bash
# Health check
curl http://localhost:8000/health

# Create item
curl -X POST http://localhost:8000/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Test Item","price":9.99,"quantity":5}'

# Get all items
curl http://localhost:8000/items
```

## Deployment

This application is designed to be deployed on:
- AWS ECS/Fargate
- AWS EC2
- Docker containers
- Kubernetes

Port: 8000
