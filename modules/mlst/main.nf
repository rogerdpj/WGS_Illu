process ARIBA {
    tag "ARIBA MLST: ${sample_id}/${scheme}"
    label 'env_ariba'
    
    publishDir "${params.outdir}/4-MLST/ARIBA", mode: 'copy', pattern: "outdirectresults/${sample_id}_*"
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    tuple val(sample_id), path(trimmed_reads), val(organism), val(scheme)

    output:
    tuple val(sample_id), val(organism), val(scheme), path("outdirectresults/${sample_id}_results_${scheme.replaceAll(/[^a-zA-Z0-9]/, '_')}"), emit: results
    path "${task.process}.version.txt", emit: versions

    script:
    """
    echo -e "ariba\t\$(ariba version 2>&1 | head -n 1 | awk '{print \$2}')" > ${task.process}.version.txt
    
    safe_scheme=\$(echo "${scheme}" | sed 's/ /_/g; s/#/_/g')

    mkdir -p out

    ariba pubmlstget --verbose "${scheme}" "out/\${safe_scheme}" || { echo "Error: Failure downloading ${scheme}"; exit 1; }

    mkdir -p "outdirectresults/${sample_id}_results_\${safe_scheme}"

    ariba run \
        --force \
        "out/\${safe_scheme}/ref_db" \
        "${trimmed_reads[0]}" \
        "${trimmed_reads[1]}" \
        "outdirectresults/${sample_id}_results_\${safe_scheme}" || { echo "Error: Failure in executing ARIBA for ${scheme}"; exit 1; }
    """
}