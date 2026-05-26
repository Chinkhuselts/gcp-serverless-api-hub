from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from datetime import datetime
# from google.cloud import datastore, bigquery

# 1. Initialize the API
app = FastAPI(
    title="Secure Serverless API Hub",
    description="A centralized API platform built for Google Cloud Deployment."
)

# 2. Add CORS Middleware (Allows your frontend to talk to this backend)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In a production environment, change "*" to your actual frontend domain
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- GCP Client Initialization (Uncomment when ready for real Database/Analytics) ---
# datastore_client = datastore.Client()
# bigquery_client = bigquery.Client()

# 3. Define the expected data structure for incoming POST requests
class DataPayload(BaseModel):
    user_id: str
    action: str
    value: int

# 4. Root Endpoint (Friendly welcome message instead of a 404 error)
@app.get("/")
async def root():
    return {
        "message": "Welcome to the Secure Serverless API Hub.",
        "documentation": "Visit /docs for the interactive API interface."
    }

# 5. Ingest Endpoint (Receives Data)
@app.post("/ingest")
async def ingest_data(payload: DataPayload):
    """
    Receives JSON data and stores it in Google Cloud Datastore.
    """
    # --- Future GCP Datastore Logic ---
    # entity_key = datastore_client.key("ApiEvent")
    # entity = datastore.Entity(key=entity_key)
    # entity.update({
    #     "user_id": payload.user_id,
    #     "action": payload.action,
    #     "value": payload.value,
    #     "timestamp": datetime.utcnow()
    # })
    # datastore_client.put(entity)
    
    return {
        "status": "success", 
        "message": f"Data for user {payload.user_id} securely processed.",
        "received_data": payload
    }

# 6. Analytics Endpoint (Returns Data for your Dashboard)
@app.get("/analytics")
async def get_analytics():
    """
    Queries Google BigQuery to return aggregated platform analytics.
    """
    # --- Future GCP BigQuery Logic ---
    # query = "SELECT action, COUNT(*) as count FROM `your_project.dataset.events` GROUP BY action"
    # query_job = bigquery_client.query(query)
    # results = [{"action": row.action, "count": row.count} for row in query_job]
    
    # Mock response so your HTML dashboard works immediately
    mock_results = [
        {"action": "login", "count": 1542}, 
        {"action": "purchase", "count": 84},
        {"action": "signup", "count": 312},
        {"action": "logout", "count": 1400}
    ]
    
    return {"status": "success", "data": mock_results}
