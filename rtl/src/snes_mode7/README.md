# SNES Mode 7 Image Processor

Project demo recreating SNES [mode 7](https://en.wikipedia.org/wiki/Mode_7) image processing

## Image specs
 - Color format: 16-bit per pixel / 5-bit color depth / 0rrrrrgggggbbbbb
 - Size: 256 cols x 224 lines
 - Data per image: 917 504 bits / 114 688 bytes / 112 kB
 - Data per line: 4 096 bits / 512 bytes / 0.5 kB

## Math
x' = a * (x - x0) + b * (y - y0) + x0
y' = c * (x - x0) + d * (y - y0) + y0
