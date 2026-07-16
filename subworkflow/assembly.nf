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

include { FASTQC_QUALITY as FASTQC_QUALITY_ORIGINAL           }     from '../modules/qc/fastqc/main'
include { TRIMMING                                            }     from '../modules/trimming/main'
include { FASTQC_QUALITY as FASTQC_QUALITY_FINAL              }     from '../modules/qc/fastqc/main'
include { KRAKEN;SEQTK_PRUNE                                  }     from '../modules/kraken/main'
include { MULTIQC                                             }     from '../modules/qc/multiqc/main'

include { ASSEMBLY                                            }     from '../modules/assembly/main'
include { FILTER_CONTIGS                                      }     from '../modules/qc/polish/filter'
include { ALIGMENT_PILON;PILON_POLISH                         }     from '../modules/qc/polish/main'

include { PROKKA                                              }     from '../modules/anotations/prokka/main_2'
include { BAKTA                                               }     from '../modules/anotations/bakta/main'

include { QUAST                                               }     from '../modules/qc/quast/main'
include { BUSCO                                               }     from '../modules/qc/busco/main'
include { MULTIQC_2 as POST_MULTIQC                           }     from '../modules/qc/multiqc/main_2' 

include { AMR as POST_ANALYSIS_ABRICATE                       }     from '../modules/AMR/abricate/main'
include { AMR_2 as POST_ANALYSIS_AMRFINDER                    }     from '../modules/AMR/AMRFinder/main'

include { ARIBA                                               }     from '../modules/mlst/main'
include { MLST                                                }     from '../modules/mlst/main_2'
include { MRSA                                                }     from '../modules/mrsa/main'
include { SCCMEC                                              }     from '../modules/mrsa/main'

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
    asm     = assembly_process(pre.prune_ch, pre.fastqc_ch_original, pre.fastq_ch_after)
    amr     = amr_process(asm.accurance_fasta_ch, asm.prune_ch)
    post    = post_process(asm.busco_ch, asm.quast_ch)

    version_channels = [
    pre.versions,
    asm.versions,
    amr.versions,
    post.versions
    ]

    if (params.mrsa) {
        mrsa    = mrsa_process(asm.accurance_fasta_ch)
        version_channels << mrsa.versions
    }
}

//PREPROCESSING

workflow pre_process {
    take:
    kraken_db

    main:
    // Input reads
    read_ch = Channel.fromFilePairs(params.input, size: 2)

    fastqc_before= FASTQC_QUALITY_ORIGINAL(read_ch.map{it -> it[1]})

    // Trimming process
    trimmed_reads = TRIMMING(read_ch).trimmed_reads

    //KRAKEN
    reads_db = fq_gz_reads_ch.combine(kraken_db)
                .map { sample_id, reads_pair, db_dir ->
                def (r1, r2) = reads_pair
                tuple (sample_id, [r1, r2], db_dir)
    }

    kraken = KRAKEN (reads_db)

    //Final Quality control after trimming
    fastqc_after = FASTQC_QUALITY_FINAL(trimmed_reads.map{it -> it[1]})

    //PRUNNING
    prunning_input = trimmed_reads
        .join(kraken_ch.keep_ids)
        .map {sample_id,reads_pair, keep_ids ->
            def (r1, r2) = reads_pair
            tuple (sample_id, [r1, r2], keep_ids)
        }
    
    prune = SEQTK_PRUNE(prunning_input)
    
    emit:
    pruned_reads = prune
    trimmed_reads = trimmed_reads
    fastqc_before = fastqc_before
    fastqc_after = fastqc_after
}

workflow assembly_process {
    take:

    main:
    //de novo assembly
    assembly_denovo_ch = ASSEMBLY(prune_ch)
    contigs_ch = assembly_denovo_ch.contigs
    scaffolds_ch = assembly_denovo_ch.scaffolds
    
    //Filter seq low quality contigs
    filtered_contigs_ch = FILTER_CONTIGS(contigs_ch)
 
    //Polishing Illumina SEQ
    polish_data_ch = filtered_contigs_ch
        .join(trimmed_reads.trimmed_reads)
        .map { sample_id, contigs, reads_clean_pair -> 
        def (r1, r2) = reads_clean_pair
        tuple (sample_id, contigs , [r1, r2])
    }

    polishing_illumina_ch = ALIGMENT_PILON(polish_data_ch)
    
    polish_data_index_ch = filtered_contigs_ch
        .join(polishing_illumina_ch.aln_bam)
        .map { sample_id, contigs, index_bam -> 
        tuple (sample_id, contigs , index_bam)
    }

    pilon_polish_ch = PILON_POLISH(polish_data_index_ch)
    accurance_fasta_ch = pilon_polish_ch.pilon_fa
    
    //PROKKA
    prokka_ch = PROKKA(accurance_fasta_ch)
    

    //BAKTA
    bakta_annotation_ch = BAKTA(accurance_fasta_ch)

    //BUSCO
    busco_ch = BUSCO(accurance_fasta_ch)

    //QUAST

    quast_input_ch = accurance_fasta_ch.join(trimmed_reads.trimmed_reads)
        .map { sample_id, contigs, reads_clean_pair ->
        def (r1, r2) = reads_clean_pair
        tuple (sample_id, contigs, [r1, r2])
    }

    quast_ch = QUAST(quast_input_ch)

    //MULTIQC
    multiqc_ch = MULTIQC(fastqc_before.qc_zip.collect(), fastq_ch_after.qc_zip.collect())

    emit:
    accurance_fasta_ch
    prune_ch
    busco_ch
    quast_ch
}

workflow amr_process {
    take:
    accurance_fasta_ch
    prune_ch
    
    
    main:
   //AMR
    //AMR1-ABRIcate
    abricate_ch = POST_ANALYSIS_ABRICATE(accurance_fasta_ch, params.organism)
    
    //AMR2-RESFINDER
    resfinder_ch = POST_ANALYSIS_AMRFINDER(accurance_fasta_ch)
   
    //MLST FAST RAW DATA- ARIBA

    def organism_schemes_ch = Channel.fromPath('organisms_list.txt')
        .splitText()
        .map { line -> line.trim() }
        .filter { it.startsWith(params.organism) }
        .map { scheme -> tuple(params.organism, scheme) }
        .unique()

    def combined_ch = prune_ch.combine(organism_schemes_ch)

    ariba_ch = ARIBA(combined_ch)
    
    //MLST
    MLST(accurance_fasta_ch)
}
 
workflow post_process {

    take:
    busco_ch
    quast_ch

    main:
    multiqc_2_ch = POST_MULTIQC(quast_ch.map{ it -> it[1] }.collect(), busco_ch.map{ it -> it[1] }.collect())

}

workflow mrsa_process {
    take:
    accurance_fasta_ch

    main:
    
    //MRSA

    mrsa_ch = MRSA (accurance_fasta_ch)
    sccmec_ch = SCCMEC(accurance_fasta_ch)

}
