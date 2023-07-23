#!/usr/bin/env nextflow

params.input_folder = "./"
params.output_folder = "./"

Channel
    .fromPath("${params.input_folder}/*.fasta")
    .into { fasta_ch; fasta_ch_clone }

fasta_ch
    .combine(fasta_ch_clone)
    .map { it.sort() } // Sorts the pair to ensure [file1, file2] and [file2, file1] become the same
    .unique() // Filters out duplicate pairs
    .filter { it[0] != it[1] } // Filters out pairs of a file with itself
    .set { pairs_ch }

process dnadiff {
    publishDir "${params.output_folder}/dnadiff", mode: 'copy'

    input:
    tuple path(file1), path(file2) from pairs_ch

    output:
    file("${file1.baseName}_${file2.baseName}_out.report") 

    script:
    """
    dnadiff ${file1} ${file2} -p ${file1.baseName}_${file2.baseName}_out
    """
}







