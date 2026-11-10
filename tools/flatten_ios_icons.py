#!/usr/bin/env python3
"""iOS app icons must have no alpha channel (App Store rejects them): flatten to RGB."""
import pathlib
from PIL import Image
d = pathlib.Path(__file__).resolve().parents[1] / "apps/mobile/ios/Runner/Assets.xcassets/AppIcon.appiconset"
for p in d.glob("*.png"):
    Image.open(p).convert("RGB").save(p)
print("iOS icons flattened")
