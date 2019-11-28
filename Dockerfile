FROM jakzal/phpqa:php7.3-alpine

LABEL "com.github.actions.name"="Guite-Zikula-Action"
LABEL "com.github.actions.description"="Build and test Zikula modules"
LABEL "com.github.actions.icon"="check"
LABEL "com.github.actions.color"="orange"

LABEL "repository"="https://github.com/Guite/zikula-action"
LABEL "homepage"="https://github.com/actions"
LABEL "maintainer"="Axel Guckelsberger <info@guite.de>"

# install pcov support (faster than xdebug)
# install phpstan extensions
RUN apk update && apk upgrade && apk --no-cache add bash build-base autoconf mysql-client zip \
  && pecl install pcov && docker-php-ext-enable pcov \
  && composer global bin phpstan require phpstan/phpstan-doctrine phpstan/phpstan-phpunit phpstan/phpstan-symfony

COPY entrypoint.sh /entrypoint.sh

# copy config files for QA tools
COPY tool-config/ /tool-config

ENTRYPOINT ["/entrypoint.sh"]
