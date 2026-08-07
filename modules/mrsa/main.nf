process MRSA {
    tag "spaTyper: ${sample_id}"
    label 'env_mrsa'

    publishDir "${params.outdir}/5-MRSA/spaTyper" , mode:"copy"
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    input:
    tuple val (sample_id), path(assembly)

    output:
    tuple val (sample_id), path ("${sample_id}_spatype.txt"), emit: report
    path "${task.process}.version.txt", emit: versions

    script:
    
    """
    echo "spaTyper\t\$(spaTyper --version | awk '{print \$2}')" > ${task.process}.version.txt
 
    spaTyper \
        -d /opt/conda/envs/env/share/spatyper-0.3.3 \
        -f ${assembly} \
        --output ${sample_id}_spatype.txt 
    """
}

process SCCMEC {
    tag "SCCmec: ${sample_id}"
    label 'env_mrsa'

    publishDir "${params.outdir}/5-MRSA/SCCMEC" , mode: "copy"
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*.version.txt"

    
    input:

    tuple val (sample_id), path(contigs)


    output:

    tuple val(sample_id), path("${sample_id}*.tsv"), emit: report
    path "${task.process}.version.txt", emit: versions



    script:
    
    """
    echo "sccmec\t\$(sccmec --version)" > ${task.process}.version.txt

    sccmec --input ${contigs} --prefix ${sample_id}

    """
}