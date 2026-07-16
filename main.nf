/*
  ============================================================
      N F   P I P E L I N E - WGS_ANALYSIS_VARIANT_CALLING

  Illumina sequencing data WGS/Variant Calling Pipeline - Nextflow
  ============================================================

  Author:        Jimmy Lucas and Roger de Pedro Jové
  Description:   Nextflow pipeline for whole-genome sequencing (WGS)
                 analysis and variant calling in bacterial genomes 
                 using Illumina data, supporting de novo assembly and 
                 reference-based analysis.
  Version:       3.0.0

  ============================================================
*/

nextflow.enable.dsl = 2

if (params.help) {
    printHelp()
    exit 0
}

checkInputParams()

reference = file("${params.reference}")

log.info """
 __        ______ ____        _                _           _        
 \\ \\      / / ___/ ___|      / \\   _ __   __ _| |_   _ ___(_)___    
  \\ \\ /\\ / / |  _\\___ \\     / _ \\ | '_ \\ / _` | | | | / __| / __|   
   \\ V  V /| |_| |___) |   / ___ \\| | | | (_| | | |_| \\__ \\ \\__ \\   
    \\_/\\_/  \\____|____/   /_/   \\_\\_| |_|\\__,_|_|\\__, |___/_|___/   
 __     __         _             _      ____     |___/_             
 \\ \\   / /_ _ _ __(_) __ _ _ __ | |_   / ___|__ _| | (_)_ __   __ _ 
  \\ \\ / / _` | '__| |/ _` | '_ \\| __| | |   / _` | | | | '_ \\ / _` |
   \\ V / (_| | |  | | (_| | | | | |_  | |__| (_| | | | | | | | (_| |
    \\_/ \\__,_|_|  |_|\\__,_|_| |_|\\__|  \\____\\__,_|_|_|_|_| |_|\\__, |
                                                              |___/ 

==============================================
N F   P I P E L I N E - WGS_ANALYSIS_VARIANT  
==============================================
Configuration environment:
    Pipeline mode:             ${params.mode}
    Fastq directory:           ${params.input}
    Profile:                   ${workflow.profile}
""".stripIndent()

// Subworkflow import

include { assembly } from "$projectDir/subworkflow/assembly"
//include { reference } from "$projectDir/subworkflow/reference"
//include { novo } from "$projectDir/subworkflow/novo"

// Main workflow
workflow {

    switch (params.mode) {

        case 'assembly':
            assembly()
            break
        case 'reference':
            reference()
            break
        case 'novo':
            novo()
            break
        default:
            error "Invalid mode: ${params.mode}. Valid options: assembly, reference, novo"
    }
}

// FUNCTIONS                                                            
def printHelp() {
    def readmeFile = file("${projectDir}/README.md")
    def printSection = false

    if (readmeFile.exists()) {
        log.info "\n"
        readmeFile.eachLine { line ->
            // Start printing when we hit the Usage header
            if (line.contains("Usage:")) {
                printSection = true
            }
            // Stop printing when we hit the next major header (Output)
            if (line.contains("## Output")) {
                printSection = false
            }
            if (printSection) {
                log.info line
            }
        }
        log.info "\n"
    } else {
        log.warn "README.md not found in ${projectDir}"
    }
}

def checkInputParams() {

    boolean fatal_error = false

    if (!params.input) {
        log.warn("You need to provide a valid input directory with --input")
        fatal_error = true
    }

    if (!params.mode) {
        log.warn("Missing --mode (assembly | reference | novo)")
        fatal_error = true
    }

    if( params.mode == 'assembly' && !params.organism ) {
        log.warn "You need to provide a valid organism with --organism when using assembly mode"
        fatal_error = true
    }

    if( params.mode == 'reference' && !params.personal_ref ) {
        log.warn "You need to provide a valid personal reference with --personal_ref when using reference mode"
        fatal_error = true
    }

    def valid_profiles = ['docker','singularity','conda']
    if (!workflow.profile || !valid_profiles.any { workflow.profile.tokenize(',').contains(it) }) {
        log.warn("Invalid profile: use docker, singularity or conda")
        fatal_error = true
    }

    if (fatal_error) {
        error "Missing or invalid parameters"
    }
}