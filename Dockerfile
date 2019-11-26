FROM jakzal/phpqa:php7.3-alpine

LABEL "com.github.actions.name"="Guite-Zikula-Action"
LABEL "com.github.actions.description"="build and test Zikula modules"
LABEL "com.github.actions.icon"="check"
LABEL "com.github.actions.color"="orange"

LABEL "repository"="https://github.com/Guite/zikula-action"
LABEL "homepage"="https://github.com/actions"
LABEL "maintainer"="Axel Guckelsberger <info@guite.de>"

# install pcov support (faster than xdebug)
RUN apk update && apk upgrade && apk add build-base autoconf
RUN pecl install pcov && docker-php-ext-enable pcov

# php-ast is used by phan
# RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
#     && docker-php-ext-install -j$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
#     bcmath gd intl mcrypt mysqli pdo_mysql simplexml xsl zip

# install phpstan extensions
RUN composer global bin phpstan require phpstan/phpstan-doctrine phpstan/phpstan-phpunit phpstan/phpstan-symfony

COPY entrypoint.sh /entrypoint.sh

# copy config files for QA tools
COPY tool-config/ /tool-config

ENTRYPOINT ["/entrypoint.sh"]
