process AMRFINDER {
    tag "AMRFinder: ${sample_id}"
    label 'env_amrfinder'
        
    publishDir "${params.outdir}/3-AMR/AMRFinder", mode: 'copy', pattern: "*.tsv"
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    tuple val(sample_id), path(assembly_file)

    output:
    path("${sample_id}_amrfinder_report.tsv"), emit: amrfinder_report
    tuple val(sample_id), path("${sample_id}_amrfinder_report.tsv"), emit: amrfinder_tuple 
    path "${task.process}.version.txt", emit: versions

    script:
    """
    echo -e "amrfinder\t\$(amrfinder --version 2>&1 | head -n 1)" > ${task.process}.version.txt

    amrfinder -n ${assembly_file} -o ${sample_id}_amrfinder_report.tsv
    """
}