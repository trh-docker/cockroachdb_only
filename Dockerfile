FROM quay.io/spivegin/gitonly:latest AS source

FROM quay.io/spivegin/cockroachdb_builder AS build
WORKDIR /opt/src/github.com/cockroachdb/
ENV CGO_ENABLED=1 \
    XGOOS=linux \
    XGOARCH=amd64 \
    XCMAKE_SYSTEM_NAME=Linux \
    TARGET_TRIPLE=x86_64-unknown-linux-gnu \
    LDFLAGS="-static-libgcc -static-libstdc++" \
    SUFFIX=-linux-2.6.32-gnu-amd64 
RUN ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa && git config --global user.name "quadtone" && git config --global user.email "quadtone@txtsme.com" 
COPY --from=source /root/.ssh /root/.ssh
RUN git config --global url.git@github.com:.insteadOf https://github.com/
RUN git clone git@github.com:cockroachdb/cockroach.git &&\
    go get github.com/pkg/errors 
RUN cd /opt/src/github.com/cockroachdb/cockroach && make 
RUN cd /opt/src/github.com/cockroachdb/cockroach && make buildshort
RUN cd /opt/src/github.com/cockroachdb/cockroach && make buildoss
RUN cd /opt/src/github.com/cockroachdb/cockroach && make build

FROM quay.io/spivegin/tlmbasedebian
WORKDIR /opt/cockroach
COPY --from=build /opt/src/github.com/cockroachdb/cockroach/cockroachoss /opt/bin/
COPY --from=build /opt/src/github.com/cockroachdb/cockroach/cockroachshort /opt/bin/
COPY --from=build /opt/src/github.com/cockroachdb/cockroach/cockroach /opt/bin/
RUN cd /opt/bin/ &&\
    chmod +x cockroachoss &&\
    chmod +x cockroachshort &&\
    chmod +x cockroach &&\
    ln -s /opt/bin/cockroach /bin/cockroach