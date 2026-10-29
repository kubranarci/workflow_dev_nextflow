process COUNT_VARIANTS {
    tag "$sample"
    container 'community.wave.seqera.io/library/bcftools_htslib:1.23.1--9f08ec665533d64a'
    publishDir 'results/stats', mode: 'copy'

    input:
    tuple val(sample), val(status), path(vcf), path(tbi)

    output:
    path "${sample}.stats.txt"

    script:
    // look for the lines "number of SNPs" and "number of indels"
    """
    bcftools stats $vcf > ${sample}.stats.txt
    """
}
