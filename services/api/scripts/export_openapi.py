"""Write packages/api-contracts/openapi.json from the app. `--check` fails if it differs."""

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from app.config import Settings  # noqa: E402
from app.main import create_app  # noqa: E402

out = Path(__file__).resolve().parents[3] / "packages/api-contracts/openapi.json"
spec = json.dumps(create_app(Settings(database_url="sqlite://")).openapi(), indent=1, sort_keys=True, ensure_ascii=False) + "\n"
if "--check" in sys.argv:
    if not out.exists() or out.read_text() != spec:
        sys.exit("openapi.json is out of date: run python services/api/scripts/export_openapi.py")
    print("openapi.json up to date")
else:
    out.write_text(spec)
    print("wrote", out)
