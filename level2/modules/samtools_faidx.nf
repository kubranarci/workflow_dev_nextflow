process SAMTOOLS_FAIDX {
    container 'community.wave.seqera.io/library/htslib_samtools:1.24--d697cfb9dce007cd'

    input:
    path fasta

    output:
    path "${fasta}.fai"

    script:
    """
    samtools faidx $fasta
    """
}
