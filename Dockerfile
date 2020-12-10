FROM centos:8
LABEL maintainer="Clarence <xjh.azzbcc@gmail.com>"

ENV \
    LANGUAGE="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LC_ALL=C \
    SOFIA_SIP_VERSION=v1.13.2 \
    SPANDSP_VERSION=e08c74d \
    FS_VERSION=v1.10.5

# 启用PowerTools源
RUN \
    dnf install 'dnf-command(config-manager)' -y && \
    dnf config-manager --enable powertools

# 系统更新以及依赖安装
RUN \
    dnf update -y && \
    dnf install -y which autoconf automake libtool make gcc-c++ diffutils file && \
    dnf install -y zlib-devel libjpeg-devel sqlite-devel libcurl-devel pcre-devel libtiff-devel speex-devel speexdsp-devel libedit-devel openssl-devel

# 添加freeswitch相关源码
ADD https://github.com/freeswitch/sofia-sip/archive/${SOFIA_SIP_VERSION}.tar.gz /usr/src/sofia-sip.tar.gz
ADD https://github.com/freeswitch/spandsp/archive/${SPANDSP_VERSION}.tar.gz /usr/src/spandsp.tar.gz
ADD https://github.com/signalwire/freeswitch/archive/${FS_VERSION}.tar.gz /usr/src/freeswitch.tar.gz

# 解压并删除源文件
RUN \
    mkdir -p /usr/src/{freeswitch,sofia-sip,spandsp} && \
    tar -xf /usr/src/freeswitch.tar.gz -C /usr/src/freeswitch --strip-components=1 && \
    tar -xf /usr/src/sofia-sip.tar.gz -C /usr/src/sofia-sip --strip-components=1 && \
    tar -xf /usr/src/spandsp.tar.gz -C /usr/src/spandsp --strip-components=1 && \
    rm /usr/src/{freeswitch,sofia-sip,spandsp}.tar.gz

# 依赖sofia-sip
RUN \
    cd /usr/src/sofia-sip && \
    # 引导
    ./bootstrap.sh -j && \
    # 配置
    ./configure --prefix=/usr --enable-static=no && \
    # 安装
    make install

# 依赖spandsp
RUN \
    cd /usr/src/spandsp && \
    # 引导
    ./bootstrap.sh -j && \
    # 配置
    ./configure --prefix=/usr --enable-static=no && \
    # 安装
    make install


# 配置工作目录
WORKDIR /usr/src/freeswitch

# 配置
RUN \
    # 引导
    ./bootstrap.sh -j && \
    # 排除所有模块
    echo > modules.conf && \
    # 配置
    ./configure --prefix=/usr --enable-static=no

# 编译
RUN \
    # 依赖
    dnf install -y yasm && \
    # 编译
    make

# 安装
RUN \
    # 下载音乐文件
    make cd-sounds cd-moh && \
    # 执行文件以及核心库
    make install-binPROGRAMS && \
    # 头文件以及pc文件
    make install-library_includeHEADERS install-library_includetestHEADERS install-pkgconfigDATA

# 安装 mod_commands
RUN \
    cd src/mod/applications/mod_commands && \
    make install

# 安装 mod_dptools
RUN \
    cd src/mod/applications/mod_dptools && \
    make install

# 安装 mod_sms
RUN \
    cd src/mod/applications/mod_sms && \
    make install

# 安装 mod_curl
RUN \
    cd src/mod/applications/mod_curl && \
    make install

# 安装 mod_opus
RUN \
    # 安装依赖
    dnf install -y opus-devel && \
    # 重新生成Makefile
    ./config.status --recheck && \
    cd src/mod/codecs/mod_opus && \
    make install

# 安装 mod_mariadb
RUN \
    # 安装依赖
    dnf install -y mariadb-devel && \
    # 重新生成Makefile
    ./config.status --recheck && \
    cd src/mod/databases/mod_mariadb && \
    make install

# 安装 mod_dialplan_xml
RUN \
    cd src/mod/dialplans/mod_dialplan_xml && \
    make install

# 安装 mod_sofia
RUN \
    cd src/mod/endpoints/mod_sofia && \
    make install

# 安装 mod_event_socket
RUN \
    cd src/mod/event_handlers/mod_event_socket && \
    make install

# 安装 mod_local_stream
RUN \
    cd src/mod/formats/mod_local_stream && \
    make install

# 安装 mod_native_file
RUN \
    cd src/mod/formats/mod_native_file && \
    make install

# 安装 mod_sndfile
RUN \
    # 安装依赖
    dnf install -y libsndfile-devel && \
    # 重新生成Makefile
    ./config.status --recheck && \
    cd src/mod/formats/mod_sndfile && \
    make install

# 安装 mod_tone_stream
RUN \
    cd src/mod/formats/mod_tone_stream && \
    make install

# 安装 mod_lua
RUN \
    # 安装依赖
    dnf install -y lua-devel && \
    # 重新生成Makefile
    ./config.status --recheck && \
    cd src/mod/languages/mod_lua && \
    make install

# 安装 mod_logfile
RUN \
    cd src/mod/loggers/mod_logfile && \
    make install

# 执行
CMD ["/bin/bash"]
