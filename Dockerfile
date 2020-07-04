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

# 执行
CMD ["/bin/bash"]
