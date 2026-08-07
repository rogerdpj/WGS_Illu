process BUSCO {
    tag "BUSCO: ${sample_id}"
    label 'env_busco'

    publishDir "${params.outdir}/1-QC/genome_QC/1-BUSCO", mode: "copy", pattern: "${sample_id}_busco*"
    publishDir "${params.outdir}/versions", mode: "copy", pattern: "*.version.txt"

    input:
    tuple val(sample_id), path(assemble)

    output:
    tuple val(sample_id), path("${sample_id}_busco"), emit: results
    path "${task.process}.version.txt", emit: versions

    script:

    """
    echo -e "busco\t\$(busco --version 2>&1 | awk '{print \$2}')" > ${task.process}.version.txt

    busco \
        -i ${assemble} \
        -m genome \
        -l ${params.busco_lineage} \
        -o ${sample_id}_busco \
        -c ${task.cpus} 
    """
}
