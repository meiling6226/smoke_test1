#!/usr/bin/env python3
"""Log in to Hugging Face inside the container. Reads the token file; never prints it."""
import sys
from pathlib import Path

from huggingface_hub import login

path = Path(sys.argv[1])
token = path.read_text().strip()
if not token:
    raise SystemExit(f"token file empty: {path}")
login(token=token, add_to_git_credential=False, skip_if_logged_in=False)
print("saved")
