nextflow.enable.dsl=2

log.info """\
              WGS - ASSEMBLY

            P A R A M E T E R S
==============================================
Configuration environment:
    Organism name:             $params.organism
    Out directory:             $params.outdir
    MRSA analysis:             $params.mrsa

""".stripIndent()

//Call all the sub-work
include { PREPARE_KRAKEN_DB                                   }     from '../modules/kraken/db_set'

include { FASTQC as FASTQC_PRE                                }     from '../modules/qc/fastqc/main'
include { TRIMMING                                            }     from '../modules/trimming/main'
include { FASTQC as FASTQC_POST                               }     from '../modules/qc/fastqc/main'
include { KRAKEN;SEQTK_PRUNE                                  }     from '../modules/kraken/main'
include { MULTIQC                                             }     from '../modules/qc/multiqc/main'

include { ASSEMBLY                                            }     from '../modules/assembly/main'
include { FILTER                                              }     from '../modules/qc/filter/main'
include { ALIGNMENT_PILON;PILON_POLISH                        }     from '../modules/qc/polish/main'

include { BAKTA                                               }     from '../modules/anotations/bakta/main'

include { QUAST                                               }     from '../modules/qc/quast/main'
include { BUSCO                                               }     from '../modules/qc/busco/main'
include { MOSDEPTH                                            }     from '../modules/qc/mosdepth/main'
include { GENOME_MULTIQC                                      }     from '../modules/qc/multiqc/main_2' 

include { MLST                                                }     from '../modules/mlst/main_2'
include { ARIBA                                               }     from '../modules/mlst/main'
include { ABRICATE                                            }     from '../modules/AMR/abricate/main'
include { AMRFINDER                                           }     from '../modules/AMR/amrfinder/main'

include { MRSA                                                }     from '../modules/mrsa/main'
include { SCCMEC                                              }     from '../modules/mrsa/main'

include { COLLECT                                             }     from '../modules/collect/main'

//MAIN WORKFLOW

workflow assembly {
    def target_db_dir = file("${params.kraken_db_dir}/${params.db_select}")
    def db_check_file = file("${target_db_dir}/hash.k2d")

    def kraken_db_ch = Channel.empty()
    if ( db_check_file.exists() ) {
        log.info "Kraken2 database found locally! Skipping setup step."
        kraken_db_ch = Channel.value( target_db_dir )
    } else {
        log.info "Kraken2 database not found. Triggering download/build process..."
        kraken_db_ch = PREPARE_KRAKEN_DB().db_ready.first()
    }

    pre     = pre_process(kraken_db_ch)
    asm     = assembly_process(pre.pruned_reads, pre.trimmed_reads)
    amr     = amr_process(asm.polished_fasta, pre.pruned_reads)

    version_channels = [
    pre.versions,
    asm.versions,
    amr.versions,
    ]

    if (params.mrsa) {
        mrsa    = mrsa_process(asm.polished_fasta)
        version_channels << mrsa.versions
    }
    
    collect(version_channels, amr.mlst_channel, amr.abricate_channel)

}

//PREPROCESSING

workflow pre_process {
    take:
    kraken_db

    main:
    // Input reads
    reads = Channel.fromFilePairs(params.input, size: 2, checkIfExists: true)

    fastqc_before= FASTQC_PRE(reads.map{it -> it[1]})

    // Trimming process
    trimming = TRIMMING(reads)
    trimmed_reads = trimming.trimmed_reads

    //KRAKEN
    reads_db = trimmed_reads.combine(kraken_db)
                .map { sample_id, reads_pair, db_dir ->
                def (r1, r2) = reads_pair
                tuple (sample_id, [r1, r2], db_dir)
    }

    kraken = KRAKEN(reads_db)

    //Final QC
    fastqc_after = FASTQC_POST(trimmed_reads.map{it -> it[1]})

    //MULTIQC
    multiqc = MULTIQC(fastqc_before.qc_zip.collect(), fastqc_after.qc_zip.collect())

    //PRUNNING
    pruning_input = trimmed_reads
        .join(kraken.keep_ids)
        .map {sample_id,reads_pair, keep_ids ->
            def (r1, r2) = reads_pair
            tuple (sample_id, [r1, r2], keep_ids)
        }
    
    pruning  = SEQTK_PRUNE(pruning_input)
    
    emit:
    pruned_reads = pruning.pruned_reads
    trimmed_reads = trimmed_reads

    versions = fastqc_before.versions
        .mix(fastqc_after.versions)
        .mix(trimming.versions)
        .mix(kraken.versions)
        .mix(pruning.versions)
        .mix(multiqc.versions)
}

workflow assembly_process {
    take:
    pruned_reads
    trimmed_reads

    main:
    //de novo assembly
    assembly = ASSEMBLY(pruned_reads)
    assembly_fasta = assembly.scaffolds
    
    //Filter seq low quality contigs
    filtered_assembly = FILTER(assembly_fasta).assembly
 
    //Polishing Illumina SEQ
    polishing_input = filtered_assembly
        .join(trimmed_reads)

    alignment = ALIGNMENT_PILON(polishing_input)
    
    pilon_input = filtered_assembly
        .join(alignment.aln_bam)

    pilon = PILON_POLISH(pilon_input)

    polished_fasta = pilon.pilon_fa
    
    //BAKTA
    bakta = BAKTA(polished_fasta)

    //QC
    busco = BUSCO(polished_fasta)

    quast_input = polished_fasta.join(trimmed_reads)
    quast = QUAST(quast_input)

    mosdepth_input = alignment.aln_bam
        .join(alignment.aln_bai)
    mosdepth = MOSDEPTH(mosdepth_input)

    multiqc_input = busco.results.map{ it[1] }
        .mix(quast.results.map{ it[1] })
        .mix(mosdepth.summary.map{ it[1] })
        .mix(mosdepth.dist.map{ it[1] })
        .collect()

    genome_multiqc = GENOME_MULTIQC(multiqc_input)

    emit:
    polished_fasta = polished_fasta
    versions = assembly.versions
        .mix(alignment.versions)
        .mix(pilon.versions)
        .mix(bakta.versions)
        .mix(busco.versions)
        .mix(quast.versions)
        .mix(mosdepth.versions)
}

workflow amr_process {
    take:
    polished_fasta
    pruned_reads
            
    main:

    mlst = MLST(polished_fasta)

    organism_schemes = Channel.fromPath('organisms_list.txt')
        .splitText()
        .map { line -> line.trim() }
        .filter { it.startsWith(params.organism) }
        .map { scheme -> tuple(params.organism, scheme) }
        .unique()

    ariba_input = pruned_reads
        .combine(organism_schemes)

    ariba = ARIBA(ariba_input)

    mlst_organism = mlst.tab
            .map { sample_id, tab_file ->
                def line = tab_file.text.trim()
                def parts = line.tokenize() // splits by spaces/tabs
                def organism = parts.size() > 1 ? parts[1] : "default"
                return tuple(sample_id, organism)
            }
        
    abricate_input = polished_fasta.join(mlst_organism, by: 0)

    abricate = ABRICATE(abricate_input)
    amrfinder = AMRFINDER(polished_fasta)

    emit:
    mlst_channel = mlst.tab.map { sample_id, file -> file }
    abricate_channel = abricate.abricate_report

    versions = mlst.versions
        .mix(ariba.versions)
        .mix(amrfinder.versions)
        .mix(abricate.versions)

}
 
workflow mrsa_process {
    take:
    polished_fasta

    main:
    
    mrsa = MRSA (polished_fasta)
    sccmec = SCCMEC(polished_fasta)

    emit:
    versions = mrsa.versions
        .mix(sccmec.versions)

}

workflow collect {

    take:
    version_channels
    mlst_channel
    abricate_channel

    main:

    all_versions = Channel.empty()

    version_channels.each { ch ->
        all_versions = all_versions.mix(ch)
    }
    
    unique_versions = all_versions
        .unique { it.name }
        .toSortedList { a, b -> a.name <=> b.name }

    sorted_mlst = mlst_channel
        .toSortedList { a, b -> a.name <=> b.name }

    sorted_abricate = abricate_channel
        .toSortedList { a, b -> a.name <=> b.name }

    COLLECT(
        unique_versions,
        sorted_mlst,
        sorted_abricate
    )
}
