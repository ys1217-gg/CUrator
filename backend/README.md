# CU RATOR FastAPI Backend

Run locally:

```sh
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn main:app --reload
```

Environment variables:

- `OPENAI_API_KEY`: AI category/tag/summary generation.
- `OPENAI_MODEL`: OpenAI model name. Defaults to `gpt-4o-mini`.
- `OPEN_GRAPH_API_KEY`: OpenGraph.io app id for Blog/Web metadata. If omitted, the server falls back to direct Open Graph HTML parsing.

The iOS app calls `POST http://127.0.0.1:8000/analyze` in the simulator. On a physical iPhone, change the app's API base URL to your Mac's local network IP.
