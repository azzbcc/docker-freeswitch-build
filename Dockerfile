FROM centos:8
LABEL maintainer="Clarence <xjh.azzbcc@gmail.com>"

# 启用PowerTools源
RUN sed -i 's|^enabled=0|enabled=1|' /etc/yum.repos.d/CentOS-PowerTools.repo

# 系统更新
RUN \
    dnf update -y && \
    dnf clean all

# 执行
CMD ["/bin/bash"]
