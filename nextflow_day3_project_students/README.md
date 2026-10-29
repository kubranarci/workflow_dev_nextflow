# Day 3 project – Which mutations are only in the tumor?

## The case

A patient's **tumor** and **blood (normal)** were sequenced with a small targeted panel:
**15 sites** in genes of interest. The molecular tumor board wants to know which of these sites
carry mutations that are **only in the tumor**. Somatic mutations can guide the treatment.

Remember: the normal carries the **germline** variants. The tumor carries germline **+ somatic** variants.

> **Your question:** Which of the 15 target sites carry tumor-only (somatic) mutations?

Build a Nextflow pipeline that answers it. The project has **three levels**. Each level adds one
or two steps to the previous one. Get each level running before you start the next. Wherever you
are at 15:00, you present what you have.

| level | question | time |
|---|---|---|
| 1 | Are the targets covered well enough? | ~2 h |
| 2 | Which variants are in the targets? | +1 h |
| 3 | Which variants are only in the tumor? | +1 h |

---

## Data (all in `data/`)

| file | what |
|---|---|
| `WES_LL_T_1_test.bam` (+ `.bai`) | tumor, ~3,900 reads, GRCh38 |
| `WES_LL_N_1_test.bam` (+ `.bai`) | normal, ~3,200 reads, GRCh38 |
| `targets.bed` | the 15 target regions (chr1–chr9) |
| `samplesheet.csv` | `sample,status,bam,bai`: one row per sample, paths relative to the project folder |
| `get_reference.sh` | builds `genome.fa`: GRCh38 chr1, 2, 3, 5, 6, 7, 9 (needed from Level 2 on) |

Test data: [GHGA nf-snvcalling](https://github.com/ghga-de/nf-snvcalling/tree/main/testdata).

## Setup on the de.NBI VM

```bash
cd day3_project_students       # always start Nextflow from this folder
nextflow -version              # 25.10.2 or later
docker run --rm hello-world    # Docker works?
bash data/get_reference.sh     # data/genome.fa (~400 MB download), needed from Level 2 on
```

Containers that work for every command below:

| tools | container |
|---|---|
| samtools | `community.wave.seqera.io/library/htslib_samtools:1.24--d697cfb9dce007cd` |
| bcftools | `community.wave.seqera.io/library/bcftools_htslib:1.23.1--9f08ec665533d64a` |

> **Tip:** run each command by hand on one BAM first. When you know what it does, put it in a process.

---

## Level 1 · Are the targets covered well enough?

Before calling variants, check that every target has enough reads in **both** samples.

```bash
# 1  index the BAM (skip if the .bai exists)
samtools index WES_LL_T_1_test.bam

# 2  depth per target region
samtools bedcov -c targets.bed WES_LL_T_1_test.bam
#    chrom  start  end  depth_sum  n_reads

# 3  mean depth = depth_sum / (end - start)
samtools bedcov -c targets.bed WES_LL_T_1_test.bam \
  | awk -v OFS=',' '{print $1":"$2"-"$3, $5, $4/($3-$2)}'
```

**In Nextflow**

* samplesheet → `[ meta, bam, bai ]` tuples, with `meta = [id: ..., status: ...]`
* one coverage process per sample
* `collectFile` → one table: `sample, status, region, n_reads, mean_depth`
* a parameter for the cut-off, `--min_depth 20`. A target **passes** when both samples reach it.

**Result:** `target_coverage.csv`, plus `target_qc.csv` (region, lowest depth, PASS/LOW).

---

## Level 2 · Which variants are in the targets?

```bash
# 4  index the reference (once)
samtools faidx genome.fa

# 5  call variants inside the target regions
bcftools mpileup -f genome.fa -R targets.bed -a AD,DP -Ou WES_LL_T_1_test.bam \
  | bcftools call -mv -Oz -o WES_LL_T_1.vcf.gz
bcftools index -t WES_LL_T_1.vcf.gz

# 6  count SNVs and indels
bcftools view -H -v snps   WES_LL_T_1.vcf.gz | wc -l
bcftools view -H -v indels WES_LL_T_1.vcf.gz | wc -l
```

**In Nextflow**

* `samtools faidx` runs **once**, but every sample needs its output. What kind of channel is that?
* each sample's calling task needs the BAM **and** its BAI, plus `genome.fa` **and** `genome.fa.fai`

**Result:** one VCF per sample, plus `variant_counts.csv` (sample, status, n_snvs, n_indels).

---

## Level 3 · Which variants are only in the tumor?

```bash
# 7  compare tumor with normal
bcftools isec -p isec_out WES_LL_T_1.vcf.gz WES_LL_N_1.vcf.gz
#    isec_out/0000.vcf  tumor-only   -> somatic candidates
#    isec_out/0001.vcf  normal-only  -> noise, or lost in the tumor
#    isec_out/0002.vcf  shared       -> germline

# 8  count each set
grep -vc '^#' isec_out/0000.vcf
grep -vc '^#' isec_out/0002.vcf

# 9  list the somatic candidates
bcftools query -f '%CHROM\t%POS\t%REF\t%ALT\n' isec_out/0000.vcf
```

**In Nextflow**

* split the VCF channel into tumor and normal by `meta.status` (`branch`)
* pair the tumor with the normal (`combine`) → one `isec` task
* careful: `grep -c` exits with an error when it counts 0 lines. Use `|| true`.

**Result:** `tumor_vs_normal.csv` (tumor_only, normal_only, shared) and a list of the tumor-only sites.

---

## Ground rules

1. One folder or Git repository per group with `main.nf`, `nextflow.config`, `modules/`.
2. One process per step, each with a `container`.
3. Inputs come from the samplesheet and `params`. No hard-coded paths in processes.
4. A `docker` profile.
5. Results published to `results/`.
6. The pipeline still works when a third sample is added to the samplesheet.
7. Show that `-resume` skips finished tasks.

## Schedule

| time | |
|---|---|
| 09:00 | Kick-off: story, groups, setup |
| 09:30 | Level 1 · coverage check |
| 12:30 | Lunch |
| 13:30 | Level 2 & 3 · variants, tumor vs normal, prepare slides |
| 15:00 | Presentations · 10 min + 5 min questions |

## Presentation (10 min)

Show us:

1. your pipeline: the DAG (`results/pipeline_info/dag.html`)
2. your result tables
3. the answer for the tumor board, with your numbers:
   *"In __ well-covered targets we found __ variants: __ tumor-only (somatic candidates: …) and __ shared (germline)."*
4. what went wrong and how you fixed it
5. how far you got and what you would add next

## If you finish early

* Skip targets that fail the coverage QC before calling variants.
* Add a `patient` column to the samplesheet and pair tumor and normal **by patient** (`combine(by: ...)`).
* Filter the calls (`bcftools view -i 'QUAL>20 && DP>10'`) and make the thresholds `params`.
* Add `samtools flagstat` + `bcftools stats` and one MultiQC report.
* Discuss: why is `bcftools isec` not a real somatic caller? What would you use instead?

## Help

* <https://training.nextflow.io> · <https://www.nextflow.io/docs/latest/>
* Ask your tutors, and ask the other groups.
