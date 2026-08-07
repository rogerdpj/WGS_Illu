process MOSDEPTH {

    tag "Mosdepth: ${sample_id}"

    label 'env_mosdepth'

    publishDir "${params.outdir}/1-QC/genome_QC/3-Mosdepth", mode: 'copy', pattern: "*.txt"
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    tuple val(sample_id), path(bam), path(bai)

    output:
    tuple val(sample_id), path("${sample_id}.mosdepth.summary.txt"), emit: summary
    tuple val(sample_id), path("${sample_id}.mosdepth.global.dist.txt"), emit: dist
    path "${task.process}.version.txt", emit: versions

    script:
    """
    echo "mosdepth\t\$(mosdepth --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+(\\.[0-9]+)?')" \
        > ${task.process}.version.txt

    mosdepth \
        -n \
        --fast-mode \
        -t ${task.cpus} \
        ${sample_id} \
        ${bam} 
    """
}