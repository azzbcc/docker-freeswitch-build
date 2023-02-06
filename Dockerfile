FROM rockylinux:8
LABEL maintainer="Clarence <xjh.azzbcc@gmail.com>"

ENV \
    LANGUAGE="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LC_ALL=C \
    SOFIA_SIP_VERSION=v1.13.12 \
    SPANDSP_VERSION=e59ca8f \
    FS_VERSION=v1.10.9 \
    FS_MOH_VERSION=1.0.52 \
    FS_SOUNDS_VERSION=1.0.53

# 启用PowerTools源
RUN \
    dnf install 'dnf-command(config-manager)' -y && \
    dnf config-manager --enable powertools

# 系统更新以及依赖安装
RUN \
    dnf update -y && \
    dnf install -y which autoconf automake libtool make gcc-c++ diffutils file && \
    dnf install -y zlib-devel libjpeg-devel sqlite-devel libcurl-devel pcre-devel libtiff-devel speex-devel speexdsp-devel libedit-devel openssl-devel libuuid-devel

# 添加freeswitch相关源码
ADD https://github.com/freeswitch/sofia-sip/archive/${SOFIA_SIP_VERSION}.tar.gz /usr/src/sofia-sip.tar.gz
ADD https://github.com/freeswitch/spandsp/archive/${SPANDSP_VERSION}.tar.gz /usr/src/spandsp.tar.gz
ADD https://github.com/signalwire/freeswitch/archive/${FS_VERSION}.tar.gz /usr/src/freeswitch.tar.gz

# 下载freeswitche音乐文件
ADD https://files.freeswitch.org/freeswitch-sounds-music-8000-${FS_MOH_VERSION}.tar.gz /usr/src/freeswitch/
ADD https://files.freeswitch.org/freeswitch-sounds-music-16000-${FS_MOH_VERSION}.tar.gz /usr/src/freeswitch/
ADD https://files.freeswitch.org/freeswitch-sounds-music-32000-${FS_MOH_VERSION}.tar.gz /usr/src/freeswitch/
ADD https://files.freeswitch.org/freeswitch-sounds-music-48000-${FS_MOH_VERSION}.tar.gz /usr/src/freeswitch/
ADD https://files.freeswitch.org/freeswitch-sounds-en-us-callie-8000-${FS_SOUNDS_VERSION}.tar.gz /usr/src/freeswitch/
ADD https://files.freeswitch.org/freeswitch-sounds-en-us-callie-16000-${FS_SOUNDS_VERSION}.tar.gz /usr/src/freeswitch/
ADD https://files.freeswitch.org/freeswitch-sounds-en-us-callie-32000-${FS_SOUNDS_VERSION}.tar.gz /usr/src/freeswitch/
ADD https://files.freeswitch.org/freeswitch-sounds-en-us-callie-48000-${FS_SOUNDS_VERSION}.tar.gz /usr/src/freeswitch/

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

# 安装必要模块以及模块依赖库
RUN \
    # 排除所有模块
    echo > modules.conf && \
    # 安装 mod_commands
    echo applications/mod_commands >> modules.conf && \
    # 安装 mod_dptools
    echo applications/mod_dptools >> modules.conf && \
    # 安装 mod_sms
    echo applications/mod_sms >> modules.conf && \
    # 安装 mod_curl
    echo applications/mod_curl >> modules.conf && \
    # 安装 mod_opus
    # 安装依赖
    dnf install -y opus-devel && \
    echo codecs/mod_opus >> modules.conf && \
    # 安装 mod_mariadb
    # 安装依赖
    dnf install -y mariadb-devel && \
    echo databases/mod_mariadb >> modules.conf && \
    # 安装 mod_dialplan_xml
    echo dialplans/mod_dialplan_xml >> modules.conf && \
    # 安装 mod_sofia
    echo endpoints/mod_sofia >> modules.conf && \
    # 安装 mod_event_socket
    echo event_handlers/mod_event_socket >> modules.conf && \
    # 安装 mod_local_stream
    echo formats/mod_local_stream >> modules.conf && \
    # 安装 mod_native_file
    echo formats/mod_native_file >> modules.conf && \
    # 安装 mod_sndfile
    # 安装依赖
    dnf install -y libsndfile-devel && \
    echo formats/mod_sndfile >> modules.conf && \
    # 安装 mod_tone_stream
    echo formats/mod_tone_stream >> modules.conf && \
    # 安装 mod_lua
    # 安装依赖
    dnf install -y lua-devel && \
    echo languages/mod_lua >> modules.conf && \
    # 安装 mod_logfile
    echo loggers/mod_logfile >> modules.conf

# 编译
RUN \
    # 依赖
    dnf install -y yasm && \
    # 引导
    ./bootstrap.sh -j && \
    # 配置
    ./configure --prefix=/usr --enable-static=no && \
    # 编译
    make

# 安装
RUN \
    # 执行文件以及核心库
    make install-binPROGRAMS && \
    # 安装常用模块
    make install_mod && \
    # 头文件以及pc文件
    make install-library_includeHEADERS install-library_includetestHEADERS install-pkgconfigDATA

# 执行
CMD ["/bin/bash"]
