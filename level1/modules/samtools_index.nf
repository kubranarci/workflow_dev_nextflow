process SAMTOOLS_INDEX {
    tag "$sample"
    container 'community.wave.seqera.io/library/htslib_samtools:1.24--d697cfb9dce007cd'

    input:
    tuple val(sample), val(status), path(bam)

    output:
    tuple val(sample), val(status), path(bam), path("${bam}.bai")

    script:
    """
    samtools index $bam
    """
}
