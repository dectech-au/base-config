#!/usr/bin/env bash
set -euo pipefail

target_img="target.png"
tmp_shot="/tmp/screen.png"

# Take screenshot of entire screen
grim "$tmp_shot"

# Find coordinates using Python
read -r x y < <(
  python3 <<EOF
import cv2
import numpy as np

haystack = cv2.imread("$tmp_shot", cv2.IMREAD_GRAYSCALE)
needle = cv2.imread("$target_img", cv2.IMREAD_GRAYSCALE)

res = cv2.matchTemplate(haystack, needle, cv2.TM_CCOEFF_NORMED)
min_val, max_val, min_loc, max_loc = cv2.minMaxLoc(res)

threshold = 0.85
if max_val < threshold:
    exit(1)

print(max_loc[0], max_loc[1])
EOF
)

echo "Match at $x,$y"

# Center of image
w=$(identify -format "%w" "$target_img")
h=$(identify -format "%h" "$target_img")
click_x=$((x + w / 2))
click_y=$((y + h / 2))

# Send input (simulate mouse move + click)
ydotool mousemove $click_x $click_y
sleep 0.1
ydotool click 1
