FROM scottyhardy/docker-wine:latest
ARG CHANSORT_RELEASE="2021-10-24"
RUN xvfb-run winetricks -q dotnet48
RUN mkdir /app
RUN wget https://github.com/PredatH0r/ChanSort/releases/download/v${CHANSORT_RELEASE}/ChanSort_${CHANSORT_RELEASE}.zip -O /tmp/ChanSort_${CHANSORT_RELEASE}.zip
RUN unzip /tmp/ChanSort_${CHANSORT_RELEASE}.zip -d /app/
RUN rm -rf /tmp/ChanSort_*
ENV RUN_AS_ROOT=yes
WORKDIR /app/ChanSort_${CHANSORT_RELEASE}/
ENTRYPOINT ["/usr/bin/entrypoint", "wine", "ChanSort.exe"]
