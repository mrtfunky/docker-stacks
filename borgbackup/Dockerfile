# Use openSUSE Tumbleweed as the base image
FROM opensuse/tumbleweed

# Set environment variables
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install BorgBackup and necessary dependencies
RUN zypper --non-interactive refresh && \
    zypper --non-interactive install borgbackup && \
    zypper clean --all

# Set the default command to display BorgBackup version
CMD ["bash"]
ENTRYPOINT ["borg"]