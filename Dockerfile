FROM bitnami/wordpress:latest
RUN echo "GitOps Pipeline Automated Build" > /opt/bitnami/wordpress/build-info.txt
