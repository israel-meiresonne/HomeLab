FROM debian:11
ENV DIR_DOCUMENT_ROOT='/var/www'
ENV DIR_DEFAULT_DOCUMENT_ROOT='/var/www/html'
ENV DOMAIN='israelmeiresonne.cloud'
ENV APP_ENV='STAGE'
ENV DIR_APACHE='/etc/apache2'
ENV DIR_APACHE_SITE_AVAILABLE="${DIR_APACHE}/sites-available"
ENV DIR_APACHE_CERTIFICATES="${DIR_APACHE}/certificates"
ENV DIR_LETSENCRYPT='/etc/letsencrypt'
ENV FILE_LETSENCRYPT_PRIVKEY="${DIR_LETSENCRYPT}/live/${DOMAIN}/privkey.pem"
ENV FILE_LETSENCRYPT_CERTIFICATE="${DIR_LETSENCRYPT}/live/${DOMAIN}/fullchain.pem"
ENV DIR_CTNR_SHARED='/var/shared'
ENV DIR_CTNR_SHARED_SITE_AVAILABLE="${DIR_CTNR_SHARED}/sites-available"
ENV DIR_ROOT='/root'
ENV DIR_ROOT_SCRIPT="${DIR_ROOT}/scripts"
ENV DIR_CERTBOT_SCRIPT="${DIR_ROOT_SCRIPT}/letsencrypt"
RUN mkdir -p $DIR_CTNR_SHARED $DIR_LETSENCRYPT $DIR_APACHE_CERTIFICATES
WORKDIR $DIR_DOCUMENT_ROOT
COPY './Shared/var/shared' $DIR_CTNR_SHARED
COPY './Shared/etc/letsencrypt' $DIR_LETSENCRYPT
COPY './Shared/root' $DIR_ROOT
RUN apt update \
    && apt -y install apache2 libapache2-mod-php7.4 php-mysql openssl certbot cron rsyslog systemctl \
    && bash "${DIR_ROOT_SCRIPT}/setup/docker.sh" "$DIR_DOCUMENT_ROOT" "$DIR_CERTBOT_SCRIPT"  \
    && rm -fr "$DIR_DEFAULT_DOCUMENT_ROOT" \
    && a2enmod rewrite ssl \
    && a2dissite $(ls $DIR_APACHE_SITE_AVAILABLE) \
    && cp "${DIR_CTNR_SHARED_SITE_AVAILABLE}/"* "${DIR_APACHE_SITE_AVAILABLE}/" \
    && a2ensite $(ls $DIR_CTNR_SHARED_SITE_AVAILABLE) \
    && ln -s $FILE_LETSENCRYPT_CERTIFICATE "${DIR_APACHE_CERTIFICATES}/${DOMAIN}.crt.pem" \
    && ln -s $FILE_LETSENCRYPT_PRIVKEY "${DIR_APACHE_CERTIFICATES}/${DOMAIN}.key.pem"
