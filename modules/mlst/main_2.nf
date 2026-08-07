process MLST {
    tag "MLST: ${sample_id}"
    label 'env_mlst'
    
    publishDir "${params.outdir}/4-MLST/mlst", mode: 'copy', pattern: "*.mlst.tab"
    publishDir "${params.outdir}/4-MLST/mlst", mode: 'copy', pattern: "*.mlst.json"
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    tuple val(sample_id), path(assembly)

    output:
    tuple val(sample_id), path("*.mlst.tab"), emit: tab
    tuple val(sample_id), path("*.mlst.json"), emit: json
    path "${task.process}.version.txt", emit: versions

    script:
    """
    echo -e "mlst\t\$(mlst --version 2>&1 | head -n 1 | awk '{print \$2}')" > ${task.process}.version.txt

    mlst \
        --threads ${task.cpus} \
        --json ${sample_id}.mlst.json \
        ${assembly} > ${sample_id}.mlst.tab
    """
}