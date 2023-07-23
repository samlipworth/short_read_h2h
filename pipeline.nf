#!/usr/bin/env nextflow

params.input_folder = "./"
params.output_folder = "./"
params.coverage = 30
params.genome_size = "5M"

Channel
    .fromFilePairs("${params.input_folder}/*_{1,2}.fastq.gz", size: 2)
    .set { reads_ch }

process Rasusa {
    publishDir "${params.output_folder}/rasusa", mode: 'copy'

    input:
    set val(sample_id), file(reads) from reads_ch

    output:
    set val(sample_id), file("*_downsampled.fq") into rasusa_ch

    script:
    """
    module load GSL/2.6-GCC-8.3.0
    rasusa -i ${reads[0]} -i ${reads[1]} --coverage ${params.coverage} --genome-size ${params.genome_size} -o ${reads[0].simpleName}_downsampled.fq -o ${reads[1].simpleName}_downsampled.fq
    """
}

rasusa_ch.into { rasusa_ch1; rasusa_ch2; rasusa_ch3 }

process SeqkitStats {
    publishDir "${params.output_folder}/seqkitStats", mode: 'copy'

    input:
    set val(sample_id), file(reads) from rasusa_ch1

    output:
    file("${sample_id}_stats.txt") into stats_ch

    script:
    """
    seqkit stats -a ${reads} > ${sample_id}_stats.txt
    """
}

process Shovill {
    publishDir "${params.output_folder}/shovill", mode: 'copy'

    input:
    set val(sample_id), file(reads) from rasusa_ch2

    output:
    file("${sample_id}_assembly") into assembly_ch

    script:
    """
    module load GSL/2.6-GCC-8.3.0
    shovill --outdir ${sample_id}_assembly --R1 ${reads[0]} --R2 ${reads[1]} --cpus 4
    """
}

process Skesa {
    publishDir "${params.output_folder}/skesa", mode: 'copy'

    input:
    set val(sample_id), file(reads) from rasusa_ch3

    output:
    file("${sample_id}.skesa.fa") into skesa_ch

    script:
    """
    
    skesa  --reads ${reads[0]},${reads[1]} --cores 4 > ${sample_id}.skesa.fa
    """
}
