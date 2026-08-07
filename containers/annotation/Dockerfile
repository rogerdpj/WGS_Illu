FROM mambaorg/micromamba:1.5.7
LABEL authors="JIMM LUCAS, adapted by ROGER DE PEDRO JOVE" \
      description="Docker image containing the environment with for DB setup"

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive

# Create environment
RUN micromamba create -n bakta_env -y \
    -c bioconda -c conda-forge \
    bakta=1.12.0 \
    wget \
    xz \
    && micromamba clean --all --yes

WORKDIR /opt/conda

# Download and build all databases
RUN mkdir -p /opt/conda/bakta_db && \
    micromamba run -n bakta_env wget -O db-light.tar.xz \
      https://zenodo.org/record/14916843/files/db-light.tar.xz && \
    micromamba run -n bakta_env tar -xf db-light.tar.xz -C /opt/conda/bakta_db/ && \
    rm db-light.tar.xz


RUN micromamba run -n bakta_env amrfinder_update \
    --force_update \
    --database /opt/conda/bakta_db/db-light/amrfinderplus-db


ENV BAKTA_DB=/opt/conda/bakta_db/db-light

# Activate environment
ENV PATH="/opt/conda/envs/bakta_env/bin:${PATH}"

# Default shell
SHELL ["/bin/bash", "-c"]
