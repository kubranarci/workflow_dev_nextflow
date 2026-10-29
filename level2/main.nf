#!/usr/bin/env nextflow

// Day 3 · LEVEL 2 - Which variants are in the targets?
// Level 1 + index reference -> call variants in the targets -> variant statistics
// (one possible solution - yours may look different)

include { SAMTOOLS_INDEX  } from './modules/samtools_index.nf'
include { TARGET_COVERAGE } from './modules/target_coverage.nf'
include { SAMTOOLS_FAIDX  } from './modules/samtools_faidx.nf'
include { BCFTOOLS_CALL   } from './modules/bcftools_call.nf'
include { COUNT_VARIANTS  } from './modules/count_variants.nf'

workflow {

    bam_ch = channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { row -> tuple(row.sample, row.status, file(row.bam)) }

    // Level 1
    SAMTOOLS_INDEX(bam_ch)
    TARGET_COVERAGE(SAMTOOLS_INDEX.out, file(params.targets))

    // Level 2
    // the reference is indexed once and reused for every sample
    SAMTOOLS_FAIDX(file(params.fasta))
    BCFTOOLS_CALL(SAMTOOLS_INDEX.out, file(params.fasta), SAMTOOLS_FAIDX.out, file(params.targets))
    COUNT_VARIANTS(BCFTOOLS_CALL.out)
}
