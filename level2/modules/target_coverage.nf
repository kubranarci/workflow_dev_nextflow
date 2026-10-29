process TARGET_COVERAGE {
    tag "$sample"
    container 'community.wave.seqera.io/library/htslib_samtools:1.24--d697cfb9dce007cd'
    publishDir 'results/coverage', mode: 'copy'

    input:
    tuple val(sample), val(status), path(bam), path(bai)
    path targets

    output:
    path "${sample}.coverage.tsv"

    script:
    // columns: chrom, start, end, depth_sum, n_reads
    """
    samtools bedcov -c $targets $bam > ${sample}.coverage.tsv
    """
}
