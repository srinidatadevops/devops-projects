import os
from contextlib import asynccontextmanager

from fastapi import Depends, FastAPI
from pydantic import BaseModel
from psycopg_pool import AsyncConnectionPool


class Item(BaseModel):
    id: int
    name: str
    status: str


pool: AsyncConnectionPool | None = None


def database_url() -> str:
    return os.getenv("DATABASE_URL", "")


@asynccontextmanager
async def lifespan(app: FastAPI):
    global pool
    url = database_url()
    if url:
        pool = AsyncConnectionPool(url, min_size=1, max_size=5, open=False)
        await pool.open()
    yield
    if pool:
        await pool.close()


app = FastAPI(title="Items API", version="1.0.0", lifespan=lifespan)


async def get_pool() -> AsyncConnectionPool | None:
    return pool


@app.get("/health")
async def health(db: AsyncConnectionPool | None = Depends(get_pool)):
    if not db:
        return {"status": "ok", "database": "not_configured"}

    async with db.connection() as conn:
        await conn.execute("select 1")

    return {"status": "ok", "database": "reachable"}


@app.get("/items", response_model=list[Item])
async def list_items():
    return [
        Item(id=1, name="deployment", status="ready"),
        Item(id=2, name="observability", status="ready"),
    ]
