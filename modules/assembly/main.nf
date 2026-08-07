process ASSEMBLY {
    tag "Spades assembly: ${sample_id}"
    label 'env_spades'

    publishDir "${params.outdir}/2-Assembly/contigs", mode: 'copy', pattern: "*_contigs.fasta"
    publishDir "${params.outdir}/2-Assembly/graph", mode: 'copy', pattern: "*.gfa"
    publishDir "${params.outdir}/logs/spades", mode: 'copy', pattern: "*.spades.log"
    publishDir "${params.outdir}/versions", mode: 'copy', pattern: "*version.txt"
    
    input:

    tuple val(sample_id), path(reads)

    output:

    tuple val(sample_id), path("${sample_id}_contigs.fasta"), emit: contigs
    tuple val(sample_id), path ("${sample_id}.fasta"), emit: scaffolds
    tuple val(sample_id), path("${sample_id}.gfa"), emit: graph
    path "${task.process}.version.txt", emit: versions
    path("${sample_id}.spades.log"), emit: log

    script:

    """
    
    echo "spades\t\$(spades.py --version 2>&1 | grep -oE '[0-9]+\\.[0-9]+(\\.[0-9]+)?')" > ${task.process}.version.txt

    spades.py \
        --isolate \
        -1 ${reads[0]} \
        -2 ${reads[1]}  \
        -t ${task.cpus} \
        -o ${sample_id}_spades_out 
    
    mv ${sample_id}_spades_out/contigs.fasta ${sample_id}_contigs.fasta 
    mv ${sample_id}_spades_out/scaffolds.fasta ${sample_id}.fasta
    mv ${sample_id}_spades_out/assembly_graph_with_scaffolds.gfa ${sample_id}.gfa
    mv ${sample_id}_spades_out/spades.log ${sample_id}.spades.log
    """
}
