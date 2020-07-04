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
RUN \
    dnf update -y && \
    dnf clean all

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
    # 清理缓存
    dnf clean all && \
    # 引导
    ./bootstrap.sh -j

# 配置
RUN \
    # 依赖软件
    dnf install -y gcc-c++ diffutils file zlib-devel libjpeg-devel sqlite-devel libcurl-devel pcre-devel libtiff-devel speex-devel speexdsp-devel libedit-devel openssl-devel && \
    # 清理缓存
    dnf clean all && \
    # 排除所有模块
    echo > modules.conf && \
    # 配置
    ./configure --prefix=

# 编译
RUN \
    # 依赖
    dnf install -y yasm && \
    # 清理缓存
    dnf clean all && \
    # 编译
    make

# 执行
CMD ["/bin/bash"]
