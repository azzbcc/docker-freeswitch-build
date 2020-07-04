FROM centos:8
LABEL maintainer="Clarence <xjh.azzbcc@gmail.com>"

ENV \
    LANGUAGE="en_US.UTF-8" \
    LANG="en_US.UTF-8" \
    LC_ALL=C \
    FS_VERSION=1.10.3

# 启用PowerTools源
RUN sed -i 's|^enabled=0|enabled=1|' /etc/yum.repos.d/CentOS-PowerTools.repo

# 系统更新
RUN dnf update -y

# 添加freeswitch源码
ADD https://github.com/signalwire/freeswitch/archive/v${FS_VERSION}.tar.gz /usr/src/freeswitch.tar.gz

# 解压并删除旧目录
RUN \
    tar xvf /usr/src/freeswitch.tar.gz -C /usr/src && \
    rm /usr/src/freeswitch.tar.gz

# 配置工作目录
WORKDIR /usr/src/freeswitch-${FS_VERSION}

# 引导
RUN \
    # 依赖软件
    dnf install -y which autoconf automake libtool make && \
    # 引导
    ./bootstrap.sh -j

# 配置
RUN \
    # 依赖软件
    dnf install -y gcc-c++ diffutils file zlib-devel libjpeg-devel sqlite-devel libcurl-devel pcre-devel libtiff-devel speex-devel speexdsp-devel libedit-devel openssl-devel && \
    # 排除所有模块
    echo > modules.conf && \
    # 配置
    ./configure --prefix=

# 编译
RUN \
    # 依赖
    dnf install -y yasm && \
    # 编译
    make

# 安装
RUN \
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

# 执行
CMD ["/bin/bash"]
