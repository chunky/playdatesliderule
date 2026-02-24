#!/bin/bash
set -e

cd "$(dirname "$0")"

ICONSIZE=32

# icon.png - "SlideRule" at 32x32
echo "icon.png"
magick -size ${ICONSIZE}x${ICONSIZE} xc:white \
    -fill black -font Helvetica -gravity center -pointsize 9 \
    -annotate +0-2 "Slide" -annotate +0+7 "Rule" \
    -monochrome icon.png

# icon-pressed.png - "SliiiiideRule" at 32x32
echo "icon-pressed.png"
magick -size ${ICONSIZE}x${ICONSIZE} xc:white \
    -fill black -font Helvetica -gravity center -pointsize 7 \
    -annotate +0-2 "Sliiiiide" -annotate +0+6 "Rule" \
    -monochrome icon-pressed.png

# icon-highlighted/ - animation adding i's frame by frame
mkdir -p icon-highlighted

echo "icon-highlight"
FRAMES=("Slide" "Sliide" "Sliiide" "Sliiiide" "Sliiiiide")
for i in "${!FRAMES[@]}"; do
    echo "  -> ${i}"
    n=$((i + 1))
    magick -size ${ICONSIZE}x${ICONSIZE} xc:white \
        -fill black -font Helvetica -gravity center -pointsize 7 \
        -annotate +0-2 "${FRAMES[$i]}" -annotate +0+6 "Rule" \
        -monochrome "icon-highlighted/${n}.png"
done

CARDW=350
CARDH=155

# card.png - "Slide Rule" at 350x155
echo "card.png"
magick -size ${CARDW}x${CARDH} xc:white \
    -fill black -font Helvetica -gravity center -pointsize 48 \
    -annotate +0+0 "Slide Rule" \
    -monochrome card.png

# card-pressed.png - "Sliiiiiiiiiiide Rule" at 350x155
echo "card-pressed.png"
magick -size ${CARDW}x${CARDH} xc:white \
    -fill black -font Helvetica -gravity center -pointsize 36 \
    -annotate +0+0 "Sliiiiiiiiiiide Rule" \
    -monochrome card-pressed.png

# card-highlighted/ - animation adding i's frame by frame
mkdir -p card-highlighted

echo "card-highlighted"
CARD_FRAMES=(
    "Slide Rule"
    "Sliide Rule"
    "Sliiide Rule"
    "Sliiiide Rule"
    "Sliiiiide Rule"
    "Sliiiiiide Rule"
    "Sliiiiiiide Rule"
    "Sliiiiiiiide Rule"
    "Sliiiiiiiiide Rule"
    "Sliiiiiiiiiide Rule"
    "Sliiiiiiiiiiide Rule"
)
for i in "${!CARD_FRAMES[@]}"; do
    echo "  -> ${i}"
    n=$((i + 1))
    magick -size ${CARDW}x${CARDH} xc:white \
        -fill black -font Helvetica -gravity center -pointsize 36 \
        -annotate +0+0 "${CARD_FRAMES[$i]}" \
        -monochrome "card-highlighted/${n}.png"
done
