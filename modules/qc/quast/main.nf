process QUAST {
    tag "QUAST: ${sample_id}"
    label 'env_quast'

    publishDir "${params.outdir}/1-QC/genome_QC/2-QUAST", mode: 'copy', pattern: "quast_result_${sample_id}*"
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    tuple val(sample_id), path(assembly_fasta), path(trimmed_reads)

    output:
    tuple val(sample_id), path("quast_result_${sample_id}/"), emit: results
    path "${task.process}.version.txt", emit: versions


    script:

    """
    echo -e "quast\t\$(quast.py --version 2>&1 | grep -i 'QUAST' | awk '{print \$2}')" > ${task.process}.version.txt

    mkdir -p quast_result_${sample_id}

    quast.py \\
    -o quast_result_${sample_id} \\
    -m 500 \\
    --threads ${task.cpus} \\
    --k-mer-size 127 \\
    --circos \\
    --pe1 ${trimmed_reads[0]} \\
    --pe2 ${trimmed_reads[1]} \\
    --gene-finding \\
    --rna-finding \\
    --contig-thresholds 0 \\
    ${assembly_fasta}

    """
}