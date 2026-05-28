from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.routers import device

app = FastAPI(
    title="DeviceInspector API",
    description="Backend API for DeviceInspector - Second-hand device inspection tool",
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

# Include routers
app.include_router(device.router)


@app.get("/")
async def root():
    return {"message": "DeviceInspector API", "version": "1.0.0"}


@app.get("/health")
async def health_check():
    return {"status": "healthy"}


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)