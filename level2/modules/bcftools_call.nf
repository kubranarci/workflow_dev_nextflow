process BCFTOOLS_CALL {
    tag "$sample"
    container 'community.wave.seqera.io/library/bcftools_htslib:1.23.1--9f08ec665533d64a'
    publishDir 'results/vcf', mode: 'copy'

    input:
    tuple val(sample), val(status), path(bam), path(bai)
    path fasta
    path fai
    path targets

    output:
    tuple val(sample), val(status), path("${sample}.vcf.gz"), path("${sample}.vcf.gz.tbi")

    script:
    """
    bcftools mpileup -f $fasta -R $targets -a AD,DP -Ou $bam \\
        | bcftools call -mv -Oz -o ${sample}.vcf.gz
    bcftools index -t ${sample}.vcf.gz
    """
}
