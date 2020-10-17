FROM ubuntu:20.04
ENV LANG=C.UTF-8
ARG APT_INSTALL="apt-get install -y --no-install-recommends"

RUN rm -rf /var/lib/apt/lists/* \
           /etc/apt/sources.list.d/cuda.list \
           /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update && DEBIAN_FRONTEND=noninteractive ${APT_INSTALL} \
        build-essential \
        ca-certificates \
        cmake \
        wget \
        git \
        vim

ARG JULIA_DOWNLOAD_URL="https://julialang-s3.julialang.org/bin/linux/x64/1.5/julia-1.5.2-linux-x86_64.tar.gz"
RUN wget ${JULIA_DOWNLOAD_URL}
RUN tar -xzf julia-1.5.2-linux-x86_64.tar.gz
RUN rm julia-1.5.2-linux-x86_64.tar.gz
RUN ln -s $(pwd)/julia-1.5.2/bin/julia /usr/local/bin/julia

# Pluto
RUN julia -e 'using Pkg; Pkg.add("Pluto")'


RUN ldconfig && \
    apt-get clean && \
    apt-get autoremove && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# Pluto.jl
EXPOSE 1234
EXPOSE 1236

WORKDIR /app
CMD ["julia", "-e", "'import Pluto; Pluto.run()'"]
