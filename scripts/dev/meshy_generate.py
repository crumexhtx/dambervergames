#!/usr/bin/env python3
"""Generate a rig-friendly GLB from an image with Meshy's Image-to-3D API."""

from __future__ import annotations

import argparse
import base64
import json
import mimetypes
import os
from pathlib import Path
import sys
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen


API_ROOT = "https://api.meshy.ai/openapi/v1"
TERMINAL_STATUSES = {"SUCCEEDED", "FAILED", "CANCELED"}


def load_local_env(path: Path) -> None:
    if not path.exists():
        return
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip().strip("\"'")
        if key:
            os.environ.setdefault(key, value)


def request_json(method: str, url: str, api_key: str, payload: dict | None = None) -> dict:
    body = json.dumps(payload).encode("utf-8") if payload is not None else None
    request = Request(
        url,
        data=body,
        method=method,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
    )
    try:
        with urlopen(request, timeout=120) as response:
            return json.load(response)
    except HTTPError as error:
        detail = error.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Meshy API returned HTTP {error.code}: {detail}") from error
    except URLError as error:
        raise RuntimeError(f"Could not reach Meshy API: {error.reason}") from error


def image_data_uri(path: Path) -> str:
    mime, _ = mimetypes.guess_type(path.name)
    if mime not in {"image/png", "image/jpeg"}:
        raise ValueError("Input image must be PNG or JPEG.")
    encoded = base64.b64encode(path.read_bytes()).decode("ascii")
    return f"data:{mime};base64,{encoded}"


def download(url: str, destination: Path) -> None:
    destination.parent.mkdir(parents=True, exist_ok=True)
    request = Request(url, headers={"User-Agent": "BeaverSurvivor-MeshyPipeline/1.0"})
    with urlopen(request, timeout=180) as response:
        destination.write_bytes(response.read())


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--image", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--polycount", type=int, default=3500)
    parser.add_argument("--poll-seconds", type=float, default=10.0)
    parser.add_argument("--timeout-minutes", type=float, default=30.0)
    parser.add_argument("--env-file", type=Path, default=Path(".env.local"))
    args = parser.parse_args()

    load_local_env(args.env_file)
    api_key = os.environ.get("MESHY_API_KEY", "").strip()
    if not api_key:
        print("MESHY_API_KEY was not found in the environment or .env.local.", file=sys.stderr)
        return 2
    if not args.image.is_file():
        print(f"Input image does not exist: {args.image}", file=sys.stderr)
        return 2
    if not 100 <= args.polycount <= 15000:
        print("--polycount must be between 100 and 15000.", file=sys.stderr)
        return 2

    payload = {
        "image_url": image_data_uri(args.image),
        "model_type": "smart-topology",
        "ai_model": "meshy-t2",
        "target_polycount": args.polycount,
        "should_texture": True,
        "enable_pbr": False,
        "pose_mode": "a-pose",
        "target_formats": ["glb"],
        "alpha_thumbnail": True,
        "multi_view_thumbnails": True,
        "moderation": True,
    }

    created = request_json("POST", f"{API_ROOT}/image-to-3d", api_key, payload)
    task_id = str(created.get("result", ""))
    if not task_id:
        raise RuntimeError(f"Meshy did not return a task ID: {created}")
    print(f"Meshy task created: {task_id}", flush=True)

    deadline = time.monotonic() + args.timeout_minutes * 60.0
    last_progress = None
    task: dict = {}
    while time.monotonic() < deadline:
        task = request_json("GET", f"{API_ROOT}/image-to-3d/{task_id}", api_key)
        status = str(task.get("status", "UNKNOWN"))
        progress = task.get("progress")
        if progress != last_progress or status in TERMINAL_STATUSES:
            print(f"Meshy status: {status} ({progress}%)", flush=True)
            last_progress = progress
        if status in TERMINAL_STATUSES:
            break
        time.sleep(args.poll_seconds)
    else:
        print(f"Timed out waiting for task {task_id}; it may still be running.", file=sys.stderr)
        return 3

    if task.get("status") != "SUCCEEDED":
        message = task.get("task_error", {}).get("message", "Unknown Meshy error")
        print(f"Meshy generation failed: {message}", file=sys.stderr)
        return 4

    glb_url = task.get("model_urls", {}).get("glb")
    if not glb_url:
        print("Meshy succeeded but returned no GLB URL.", file=sys.stderr)
        return 5

    output = args.output.resolve()
    download(str(glb_url), output)

    preview_dir = output.parent / "previews"
    for view, url in task.get("thumbnail_urls", {}).items():
        if url:
            download(str(url), preview_dir / f"{view}.png")
    alpha_url = task.get("alpha_thumbnail_url")
    if alpha_url:
        download(str(alpha_url), preview_dir / "alpha.png")

    metadata = {
        "task_id": task_id,
        "consumed_credits": task.get("consumed_credits"),
        "target_polycount": args.polycount,
        "source_image": args.image.name,
        "output": output.name,
    }
    output.with_suffix(".meshy.json").write_text(
        json.dumps(metadata, indent=2) + "\n", encoding="utf-8"
    )
    print(f"Downloaded GLB: {output}", flush=True)
    print(f"Credits consumed: {task.get('consumed_credits', 'unknown')}", flush=True)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        raise SystemExit(1)
