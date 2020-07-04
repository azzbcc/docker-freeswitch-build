FROM centos:8
LABEL maintainer="Clarence <xjh.azzbcc@gmail.com>"

# 系统更新
RUN \
    dnf update -y && \
    dnf clean all

# 执行
CMD ["/bin/bash"]
