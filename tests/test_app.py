"""Pipeline quality gate: run AFTER train.py has produced artifacts/."""
import json
from pathlib import Path

import pandas as pd
from fastapi.testclient import TestClient

from app import app

client = TestClient(app)
CONFIG = json.loads(Path("config.json").read_text())
METRICS = json.loads(Path("artifacts/metrics.json").read_text())


def test_artifacts_exist():
    assert Path("artifacts/model.joblib").exists()
    assert Path("artifacts/metrics.json").exists()


def test_metrics_endpoint_fields():
    r = client.get("/metrics")
    assert r.status_code == 200
    body = r.json()
    for key in ["student_id", "accuracy", "training_rows", "model_version", "git_sha"]:
        assert key in body
    assert body["student_id"] == CONFIG["student_id"]


def test_model_trained_on_latest_data():
    rows = len(pd.read_csv("dataset/train.csv"))
    assert METRICS["training_rows"] == rows


def test_accuracy_is_reasonable():
    # Quality gate: block deployment of a broken model
    assert METRICS["accuracy"] >= 0.60


def test_predict_endpoint():
    record = {f: 0.5 for f in CONFIG["features"]}
    r = client.post("/predict", json={"records": [record, record]})
    assert r.status_code == 200
    body = r.json()
    assert len(body["predictions"]) == 2
    assert all(p in (0, 1) for p in body["predictions"])


def test_predict_rejects_empty():
    r = client.post("/predict", json={"records": []})
    assert r.status_code == 422
