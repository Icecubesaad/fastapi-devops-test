from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional
import uvicorn
from datetime import datetime

app = FastAPI(
    title="FastAPI Test App",
    description="Simple FastAPI application for deployment testing",
    version="1.0.0"
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Models
class Item(BaseModel):
    name: str
    description: Optional[str] = None
    price: float
    quantity: int = 1

class User(BaseModel):
    username: str
    email: str
    full_name: Optional[str] = None

# In-memory storage
items_db = []
users_db = []

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "FastAPI Test Application",
        "status": "running",
        "timestamp": datetime.now().isoformat(),
        "endpoints": {
            "health": "/health",
            "items": "/items",
            "users": "/users",
            "docs": "/docs"
        }
    }

@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now().isoformat(),
        "service": "fastapi-app"
    }

@app.get("/items")
async def get_items():
    """Get all items"""
    return {
        "items": items_db,
        "count": len(items_db)
    }

@app.post("/items")
async def create_item(item: Item):
    """Create a new item"""
    item_dict = item.dict()
    item_dict["id"] = len(items_db) + 1
    item_dict["created_at"] = datetime.now().isoformat()
    items_db.append(item_dict)
    return {
        "message": "Item created successfully",
        "item": item_dict
    }

@app.get("/items/{item_id}")
async def get_item(item_id: int):
    """Get item by ID"""
    for item in items_db:
        if item["id"] == item_id:
            return item
    raise HTTPException(status_code=404, detail="Item not found")

@app.get("/users")
async def get_users():
    """Get all users"""
    return {
        "users": users_db,
        "count": len(users_db)
    }

@app.post("/users")
async def create_user(user: User):
    """Create a new user"""
    user_dict = user.dict()
    user_dict["id"] = len(users_db) + 1
    user_dict["created_at"] = datetime.now().isoformat()
    users_db.append(user_dict)
    return {
        "message": "User created successfully",
        "user": user_dict
    }

@app.get("/stats")
async def get_stats():
    """Get application statistics"""
    return {
        "total_items": len(items_db),
        "total_users": len(users_db),
        "timestamp": datetime.now().isoformat()
    }

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
