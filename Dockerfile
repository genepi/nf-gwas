FROM continuumio/miniconda
MAINTAINER Lukas Forer <lukas.forer@i-med.ac.at> / Sebastian Schönherr <sebastian.schoenherr@i-med.ac.at>
COPY environment.yml .
RUN \
   conda env update -n root -f environment.yml \
&& conda clean -a

RUN apt-get --allow-releaseinfo-change update && apt-get install -y procps unzip libgomp1

# Install jbang (not as conda package available)
WORKDIR "/opt"
RUN wget https://github.com/jbangdev/jbang/releases/download/v0.79.0/jbang-0.79.0.zip && \
    unzip -q jbang-*.zip && \
    mv jbang-0.79.0 jbang  && \
    rm jbang*.zip
ENV PATH="/opt/jbang/bin:${PATH}"

# Install regenie (not as conda package available)
WORKDIR "/opt"
RUN mkdir regenie && cd regenie && \
    wget https://github.com/rgcgithub/regenie/releases/download/v2.2.4/regenie_v2.2.4.gz_x86_64_Linux.zip && \
    unzip -q regenie_v2.*.gz_x86_64_Linux.zip && \
    rm regenie_v2.*.gz_x86_64_Linux.zip && \
    mv regenie_v2.*.gz_x86_64_Linux regenie && \
    chmod +x regenie
ENV PATH="/opt/regenie/:${PATH}"

