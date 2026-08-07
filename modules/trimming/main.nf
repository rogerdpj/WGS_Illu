process TRIMMING {
    tag "Fastp: ${pair_id}"
    label 'env_trimming'

    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"
    publishDir "${params.outdir}/logs/fastp", mode: 'copy', pattern: "*.html"
    publishDir "${params.outdir}/logs/fastp", mode: 'copy', pattern: "*.json"

    input:
    tuple val(pair_id), path (reads) 

    output:
    tuple val(pair_id), path("${pair_id}_clean_{1,2}.fq.gz"), emit: trimmed_reads
    path("*.html"), emit: html_report
    path("*.json"), emit: json_report
    path("${task.process}.version.txt"), emit: versions

    script: 
    """
    echo "fastp\t\$(fastp --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+(\\.[0-9]+)?')" > ${task.process}.version.txt

    fastp \
        --thread ${task.cpus} \
        -i ${reads[0]} \
        -I ${reads[1]} \
        -o ${pair_id}_clean_1.fq.gz \
        -O ${pair_id}_clean_2.fq.gz \
        --detect_adapter_for_pe \
        --trim_poly_g \
        --trim_poly_x \
        --cut_front \
        --cut_tail \
        --cut_mean_quality ${params.fastp_quality} \
        --length_required ${params.fastp_min_length} \
        --correction \
        -h out_${pair_id}_fastp.html \
        -j out_${pair_id}_fastp.json
    """
}