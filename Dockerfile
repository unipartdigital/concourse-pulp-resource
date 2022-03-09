FROM debian/latest

COPY scripts/ /opt/resource/
RUN chmod +x /opt/resource/*