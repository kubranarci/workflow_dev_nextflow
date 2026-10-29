#!/usr/bin/env bash
# Build data/genome.fa = the GRCh38 chromosomes that contain targets (chr1,2,3,5,6,7,9),
# UCSC naming ("chr1"), same as the BAM headers. Needed from Level 2 on.
# Download ~400 MB, ~1.3 GB unpacked. Run once from the project folder:  bash data/get_reference.sh
set -euo pipefail
OUT=${1:-data}
mkdir -p "$OUT"
if [ -s "$OUT/genome.fa" ]; then echo "$OUT/genome.fa already exists"; exit 0; fi
U=https://hgdownload.soe.ucsc.edu/goldenPath/hg38/chromosomes
for c in chr1 chr2 chr3 chr5 chr6 chr7 chr9; do
    echo "downloading $c"
    wget -q --show-progress -O - "$U/$c.fa.gz" | gunzip -c >> "$OUT/genome.fa.tmp"
done
mv "$OUT/genome.fa.tmp" "$OUT/genome.fa"
echo "done: $OUT/genome.fa"
