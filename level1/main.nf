#!/usr/bin/env nextflow

// Day 3 · LEVEL 1 - Are the targets covered well enough?
// samplesheet -> index BAM -> coverage per target
// (one possible solution - yours may look different)

include { SAMTOOLS_INDEX  } from './modules/samtools_index.nf'
include { TARGET_COVERAGE } from './modules/target_coverage.nf'

workflow {

    // read the samplesheet: one [ sample, status, bam ] per row
    bam_ch = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, row.status, file(row.bam)) }

    // 1. index -> [ sample, status, bam, bai ]
    SAMTOOLS_INDEX(bam_ch)

    // 2. coverage per target region
    TARGET_COVERAGE(SAMTOOLS_INDEX.out, file(params.targets))
}
