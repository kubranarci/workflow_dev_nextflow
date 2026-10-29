# Nextflow for science using nf-core tools

## 1. Environment Setup

First, check your Conda environments and activate the appropriate Nextflow environment. Then, clone the training repository.

```bash
conda info --envs
conda activate nextflow-26.04.6
git clone -b master --single-branch https://github.com/nextflow-io/training.git 
```

---

## 2. Pipeline Creation & Initial Run

Use the interactive UI to create a pipeline template:

```bash
nf-core pipeline create
```

Without adding anything, run the pipeline using the `test` profile to demonstrate how `fastq` and `multiqc` already run:

```bash
nextflow run nf-rnaseq/main.nf -profile test,docker --outdir results
```

---

## 3. Exploring Pipeline Structure

*   Go through the results, `samplesheet`, and `schema_input.json`.
*   Show how `/home/ubuntu/nf-rnaseq/subworkflows/local/utils_nfcore_rnaseq_pipeline/main.nf` works:


Check  [groupTuple](https://docs.seqera.io/nextflow/reference/operator#grouptuple), [map](https://docs.seqera.io/nextflow/reference/operator#map), and [set](https://docs.seqera.io/nextflow/reference/operator#set)

```groovy
    //
    // Create channel from input file provided through params.input
    //

    channel
        .fromList(samplesheetToList(input, "${projectDir}/assets/schema_input.json"))
        .map {
            meta, fastq_1, fastq_2 ->
                if (!fastq_2) {
                    return [ meta.id, meta + [ single_end:true ], [ fastq_1 ] ]
                } else {
                    return [ meta.id, meta + [ single_end:false ], [ fastq_1, fastq_2 ] ]
                }
        }
        .groupTuple()
        .map { samplesheet ->
            validateInputSamplesheet(samplesheet)
        }
        .map {
            meta, fastqs ->
                return [ meta, fastqs.flatten() ]
        }
        .set { ch_samplesheet }
```

---

## 4. Custom Analysis Setup

Let's create a samplesheet for our analysis. 

Copy the required data:

```bash
cp -r /home/ubuntu/training/nf4-science/rnaseq/data data
```

Create or review `/home/ubuntu/training/nf4-science/rnaseq/data/paired-end.csv`:

```csv
sample,fastq_1,fastq_2
ENCSR000COQ1,data/reads/ENCSR000COQ1_1.fastq.gz,data/reads/ENCSR000COQ1_2.fastq.gz
ENCSR000COQ2,data/reads/ENCSR000COQ2_1.fastq.gz,
ENCSR000COR1,data/reads/ENCSR000COR1_1.fastq.gz,data/reads/ENCSR000COR1_2.fastq.gz
ENCSR000COR2,data/reads/ENCSR000COR2_1.fastq.gz,
ENCSR000CPO1,data/reads/ENCSR000CPO1_1.fastq.gz,data/reads/ENCSR000CPO1_2.fastq.gz
ENCSR000CPO2,data/reads/ENCSR000CPO2_1.fastq.gz,
```

Copy the test configuration and navigate to the pipeline directory:

```bash
cp conf/test.config data/
cd nf-rnaseq
```

Change the parameters to data directory in test.config

```bash
params {
    input  = 'data/samplesheet.csv'
}
```
---

## 5. Working with nf-core Modules (TrimGalore)

List all remote nf-core modules and install `trimgalore`:

Note: You have to be inside nf-rnaseq directory to be able to install modules!

```bash
nf-core modules list remote
nf-core modules install trimgalore
```

Run the pipeline with the newly added module:

```bash
nextflow run main.nf -profile docker --input data/samplesheet.csv -c data/test.config --outdir results -resume
```

---

## 6. Adding HISAT2 Alignment

First, change the fasta reference in `test.config` as well:

```groovy
fasta = 'data/genome.fa'
```

Next, install the HISAT2 build module:

```bash
nf-core module install hisat2/build
```

We need the fasta file to build the index. We need to generate restructure fasta channel to match HISAT2_BUILD. Check operator [collect](https://docs.seqera.io/nextflow/reference/stdlib-types/channel#collect):  

Add this channel creation to `rnaseq.nf`:

```groovy
    fasta   = channel.fromPath(params.fasta, checkIfExists: true)
                .map{ fasta -> tuple([id: fasta.getSimpleName()], fasta) }.collect()
```

Add the `HISAT2_BUILD` module to `rnaseq.nf`. 

```groovy
    HISAT2_BUILD(
        fasta.map{meta, file -> tuple(meta, file, [], [])},
        false
    )
```

Now we need `HISAT2_ALIGN`. Add the following block to `rnaseq.nf` to perform the alignment and mix the summary into MultiQC:

```groovy
    HISAT2_ALIGN(
        TRIMGALORE.out.reads,
        HISAT2_BUILD.out.index,
        [[],[]],
        false
    )
    ch_multiqc_files = ch_multiqc_files.mix(HISAT2_ALIGN.out.summary.map{ _meta, file -> file })
```