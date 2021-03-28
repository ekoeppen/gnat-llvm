FROM alpine:3.13 as build

RUN apk add llvm git bash gcc-gnat make libc-dev \
    curl gzip texinfo g++ zlib-dev llvm-dev clang linux-headers

WORKDIR /build

RUN git clone --depth 1 git://gcc.gnu.org/git/gcc.git llvm-interface/gcc \
    && ln -s gcc/gcc/ada llvm-interface/gnat_src
RUN git clone --depth 1 --branch v21.0.0 https://github.com/AdaCore/xmlada.git && \
    git clone --depth 1 --branch v21.0.0 https://github.com/AdaCore/gprbuild.git && \
    git clone --depth 1 https://github.com/AdaCore/gprconfig_kb

RUN cd /build/gprbuild && ./bootstrap.sh --with-xmlada=../xmlada && \
    cd /build/xmlada && ./configure --prefix=/usr/local && \
    make -j4 && make install && \
    cd /build/gprbuild && export GPR_PROJECT_PATH=/usr/local/share/gpr && \
    make prefix=/usr/local setup && make -j4 all && make install && \
    make -j4 libgpr.build && make libgpr.install

RUN sed -i 's/"-DIN_RTS=1"/"-DIN_RTS=1", "-D_GNU_SOURCE"/' llvm-interface/gcc/gcc/ada/libgnat/libgnat_common.gpr

COPY llvm-interface llvm-interface
COPY llvm llvm
COPY Makefile Makefile

RUN ln -s llvm-interface/gnat_src/libgnat/system-linux-x86.ads llvm-interface/gnat_src/libgnat/system.ads
RUN make -C llvm-interface build
RUN make -C llvm-interface gnatlib-automated
RUN make -C llvm-interface zfp

RUN cp llvm-interface/bin/* /usr/local/bin
RUN cp -r llvm-interface/lib/* /usr/local/lib

FROM alpine:3.13

RUN apk add --no-cache libgcc libstdc++ libgnat llvm10 lld
COPY --from=build /usr/local /usr/local
WORKDIR /build
