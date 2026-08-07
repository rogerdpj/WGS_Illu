FROM mambaorg/micromamba:1.5.7
LABEL authors="ROGER DE PEDRO JOVE" \
      description="Docker image containing the environment with tools for the QC of Illumina assemblies"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Create environment
RUN micromamba create -n qc_env -y \
    -c bioconda -c conda-forge \
    fastqc=0.12.1 \
    fastp=1.3.6 \
    mosdepth=0.3.14 \
    quast=5.3.0 \
    busco=6.1.0 \
    multiqc=1.35 \
    && micromamba clean --all --yes

# Activate environment
ENV PATH=/opt/conda/envs/qc_env/bin:$PATH

# Default shell
SHELL ["/bin/bash", "-c"]
