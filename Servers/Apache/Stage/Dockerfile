FROM debian:11
ENV DOCUMENT_ROOT='/var/www'
ENV DEFAULT_DOCUMENT_ROOT='/var/www/html'
ENV APP_ENV='STAGE'
ENV APACHE='/etc/apache2'
ENV APACHE_SITE_AVAILABLE="${APACHE}/sites-available"
ENV VM_SHARED='/var/shared'
ENV VM_SHARED_SITE_AVAILABLE="${VM_SHARED}/sites-available"
ENV VM_SHARED_CERTIFICATES="${VM_SHARED}/certificates"
RUN mkdir -p $VM_SHARED
WORKDIR $DOCUMENT_ROOT
COPY './Shared' $VM_SHARED
RUN apt update \
    && apt -y install apache2 libapache2-mod-php7.4 php-mysql openssl \
    && rm -fr "$DEFAULT_DOCUMENT_ROOT" \
    && sed -i 's#;extension=pdo_mysql#extension=pdo_mysql#; s#display_errors = On#display_errors = Off#' '/etc/php/7.4/apache2/php.ini' \
    && a2enmod rewrite ssl \
    && a2dissite $(ls $APACHE_SITE_AVAILABLE) \
    && cp "${VM_SHARED_SITE_AVAILABLE}/"* "${APACHE_SITE_AVAILABLE}/" \
    && a2ensite $(ls $VM_SHARED_SITE_AVAILABLE) \
    && cp -R "${VM_SHARED_CERTIFICATES}" "${APACHE}"
