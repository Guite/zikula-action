FROM jakzal/phpqa:php7.3-alpine

LABEL "com.github.actions.name"="Guite-Zikula-Action"
LABEL "com.github.actions.description"="Build and test Zikula modules"
LABEL "com.github.actions.icon"="check"
LABEL "com.github.actions.color"="orange"

LABEL "repository"="https://github.com/Guite/zikula-action"
LABEL "homepage"="https://github.com/actions"
LABEL "maintainer"="Axel Guckelsberger <info@guite.de>"

# install phpstan extensions
RUN apk update && apk upgrade && apk --no-cache add bash build-base autoconf mysql-client zip libpng-dev libxslt-dev \
  && docker-php-ext-install pdo_mysql gd xsl
#  \
#  && composer global bin phpstan require phpstan/phpstan-doctrine phpstan/phpstan-phpunit phpstan/phpstan-symfony

# see https://github.com/fabpot/local-php-security-checker/issues/11
# and https://github.com/fabpot/local-php-security-checker/issues
RUN curl -s https://api.github.com/repos/fabpot/local-php-security-checker/releases/latest | \
  grep -E "browser_download_url(.+)linux_amd64" | \
  cut -d : -f 2,3 \
  | tr -d \" \
  | xargs -I{} wget -O local-php-security-checker {} \
  && mv local-php-security-checker /usr/bin/local-php-security-checker \
  && chmod +x /usr/bin/local-php-security-checker

COPY entrypoint.sh /entrypoint.sh

# copy config files for QA tools
COPY tool-config/ /tool-config

ENTRYPOINT ["/entrypoint.sh"]
