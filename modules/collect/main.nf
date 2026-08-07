process COLLECT {
    tag "Collect information"
    label 'env_abricate'
    cache 'deep'

    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "software_versions.txt"
    publishDir "${params.outdir}/4-MLST", mode: 'copy', pattern: "mlst_results.tab"
    publishDir "${params.outdir}/3-AMR/ABRICATE", mode: 'copy', pattern: "abricate_summary.tsv"

    input:
    path version_files
    path mlst_files
    path abricate_files

    output:
    path "software_versions.txt"
    path "mlst_results.tab"
    path "abricate_summary.tsv"

    script:
    """
    set -euo pipefail

    echo -e "tool\tversion" > software_versions.txt
    cat ${version_files} | sort | uniq >> software_versions.txt

    for f in ${mlst_files}; do
        cat "\$f"
    done > mlst_results.tab

    abricate --summary ${abricate_files} > abricate_summary.tsv

    """
}