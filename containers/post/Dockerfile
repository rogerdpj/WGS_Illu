FROM mambaorg/micromamba:1.5.7
LABEL authors="ROGER DE PEDRO JOVE" \
      description="Docker image containing the environment with all the tools for postassembly analysis of ONT assemblies"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Create environment
RUN micromamba create -n postassembly_env -y \
    -c bioconda -c conda-forge \
    mlst=2.33.1 \
    abricate=1.4.0 \
    ncbi-amrfinderplus=4.2.7 \
    mob_suite=3.1.9 \
    pandas \
    wget \
    && micromamba clean --all --yes


# Download and build all databases
RUN micromamba run -n postassembly_env abricate --setupdb
RUN micromamba run -n postassembly_env amrfinder -u

RUN mkdir -p /opt/conda/envs/postassembly_env/db/vfdb_full && \
    micromamba run -n postassembly_env wget -O vfdb_full.fa.gz http://www.mgc.ac.cn/VFs/Down/VFDB_setB_nt.fas.gz && \
    gunzip vfdb_full.fa.gz && \
    mv vfdb_full.fa /opt/conda/envs/postassembly_env/db/vfdb_full/sequences
RUN micromamba run -n postassembly_env abricate --setupdb

# Activate environment
ENV PATH=/opt/conda/envs/postassembly_env/bin:$PATH

# Default shell
SHELL ["/bin/bash", "-c"]
