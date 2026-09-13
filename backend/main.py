import os
import time
import logging
from fastapi import FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import psycopg2
from psycopg2 import pool

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = FastAPI()

# Allow frontend to access the API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

db_pool = None

class LoanCreate(BaseModel):
    borrower_name: str
    loan_amount: float
    property_city: str

def init_db_pool():
    global db_pool
    retries = 5
    backoff = 2

    # Database connection parameters from environment variables
    # Defaulting to localhost for local testing outside of Docker if needed
    db_host = os.environ.get("DB_HOST", "localhost")
    db_port = os.environ.get("DB_PORT", "5432")
    db_name = os.environ.get("DB_NAME", "postgres")
    db_user = os.environ.get("DB_USER", "postgres")
    db_password = os.environ.get("DB_PASSWORD", "postgres")

    for i in range(retries):
        try:
            logger.info(f"Attempting to connect to database... (Attempt {i+1}/{retries})")
            db_pool = psycopg2.pool.SimpleConnectionPool(
                1, 20,
                host=db_host,
                port=db_port,
                dbname=db_name,
                user=db_user,
                password=db_password
            )
            if db_pool:
                logger.info("Successfully connected to the database and initialized connection pool.")
                return
        except psycopg2.OperationalError as e:
            logger.warning(f"Database connection failed: {e}. Retrying in {backoff} seconds...")
            time.sleep(backoff)
            backoff *= 2  # Exponential backoff

    logger.error("Could not connect to the database after multiple retries. API will start but /readyz will fail.")

@app.on_event("startup")
def startup_event():
    init_db_pool()

@app.on_event("shutdown")
def shutdown_event():
    if db_pool:
        db_pool.closeall()
        logger.info("Database connection pool closed.")

@app.get("/healthz")
def healthz():
    """Liveness probe: returns 200 as long as the process is running."""
    return {"status": "ok"}

@app.get("/readyz")
def readyz():
    """Readiness probe: returns 200 only if the database is reachable."""
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database connection pool not initialized")
    
    conn = None
    try:
        conn = db_pool.getconn()
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
        return {"status": "ready"}
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        raise HTTPException(status_code=503, detail="Database is unreachable")
    finally:
        if conn:
            db_pool.putconn(conn)

@app.get("/loans")
def get_loans():
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")
        
    conn = None
    try:
        conn = db_pool.getconn()
        with conn.cursor() as cur:
            # Include pod name in the response (Assignment D4 requirement: show load balancing)
            pod_name = os.environ.get("HOSTNAME", "unknown-pod")
            
            cur.execute("SELECT id, borrower_name, loan_amount, property_city, status, created_at FROM loans ORDER BY created_at DESC")
            rows = cur.fetchall()
            loans = []
            for row in rows:
                loans.append({
                    "id": row[0],
                    "borrower_name": row[1],
                    "loan_amount": float(row[2]),
                    "property_city": row[3],
                    "status": row[4],
                    "created_at": row[5]
                })
            return {"served_by": pod_name, "loans": loans}
    except Exception as e:
        logger.error(f"Error fetching loans: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")
    finally:
        if conn:
            db_pool.putconn(conn)

@app.post("/loans")
def create_loan(loan: LoanCreate):
    if not db_pool:
        raise HTTPException(status_code=503, detail="Database not available")
        
    conn = None
    try:
        conn = db_pool.getconn()
        with conn.cursor() as cur:
            cur.execute(
                "INSERT INTO loans (borrower_name, loan_amount, property_city) VALUES (%s, %s, %s) RETURNING id",
                (loan.borrower_name, loan.loan_amount, loan.property_city)
            )
            loan_id = cur.fetchone()[0]
            conn.commit()
            return {"status": "success", "loan_id": loan_id}
    except Exception as e:
        if conn:
            conn.rollback()
        logger.error(f"Error creating loan: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")
    finally:
        if conn:
            db_pool.putconn(conn)

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
