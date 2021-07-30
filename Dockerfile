FROM continuumio/miniconda
MAINTAINER Lukas Forer <lukas.forer@i-med.ac.at>

COPY environment.yml .
RUN \
   conda env update -n root -f environment.yml \
&& conda clean -a

RUN apt-get update && apt-get install -y procps unzip

# Install jbang (not as conda package available)
WORKDIR "/opt"
RUN wget https://github.com/jbangdev/jbang/releases/download/v0.59.0/jbang.zip && \
    unzip -q jbang.zip && \
    rm jbang.zip
ENV PATH="/opt/jbang/bin:${PATH}"
