process BAKTA {
    tag "BAKTA annotation: ${sample_id}"
    label 'env_bakta'

    publishDir "${params.outdir}/2-Assembly/2-Annotations", mode: 'copy', pattern: "annotations_${sample_id}/*"
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    tuple val(sample_id), path(assembly_file)

    output:
    path "annotations_${sample_id}/*", emit: bakta_results
    tuple val(sample_id), path("annotations_${sample_id}/${sample_id}.gff3"), path("annotations_${sample_id}/${sample_id}.fna"), emit: conv_gff
    path "${task.process}.version.txt", emit: versions
    
    script:

    """
    set -euo pipefail

    export MPLCONFIGDIR="\$PWD/.mplconfig"
    mkdir -p "\$MPLCONFIGDIR"
    
    echo -e "bakta\t\$(bakta --version 2>&1 | grep -i bakta | head -n 1 | awk '{print \$2}')" > ${task.process}.version.txt

    bakta \
        --threads ${task.cpus} \
        --keep-contig-headers \
        --skip-sorf \
        --prefix ${sample_id} \
        --output annotations_${sample_id} \
        ${assembly_file}
    """
}