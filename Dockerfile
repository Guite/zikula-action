FROM php:7.3-alpine

LABEL "com.github.actions.name"="Guite-Zikula-Action"
LABEL "com.github.actions.description"="build and test Zikula modules"
LABEL "com.github.actions.icon"="check"
LABEL "com.github.actions.color"="blue"

LABEL "repository"="https://github.com/Guite/zikula-action"
LABEL "homepage"="https://github.com/actions"
LABEL "maintainer"="Axel Guckelsberger <info@guite.de>"

# Use the default development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
# Use the default production configuration
#RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# install php extensions and composer
# xml is required by phpunit, xsl is required by phpqa, php-ast is used by phan
# note we do not install phpunit, since composer installs Symfony's phpunit-bridge providing simple-phpunit
RUN apk update && apk add \
    php7 php7-ctype php7-gd php7-iconv php7-intl php7-json php7-mbstring php7-mysqli php7-mysqlnd \
    php7-session php7-simplexml php7-tokenizer php7-xml php7-xsl php7-pecl-ast \
    composer

# note pcov is much faster than xdebug
# TODO php7-pecl-pcov package is not available in alpine 3.10 yet though (only in edge)
# see https://pkgs.alpinelinux.org/packages?name=*php*pcov*

# install required additional releng tools
RUN composer require --dev \
    jakub-onderka/php-parallel-lint:^1 \
    jakub-onderka/php-console-highlighter:^0 \
    phpunit/phpunit:^8 \
    friendsofphp/php-cs-fixer:^2 \
    consolidation/robo:^1 \
    phan/phan:^2 \
    phpstan/phpstan:^0 \
    phpstan/phpstan-doctrine:^0 \
    phpstan/phpstan-phpunit:^0 \
    phpstan/phpstan-symfony:^0 \
    sensiolabs/security-checker:^6 \
    vimeo/psalm:^3 \
    edgedesign/phpqa:^1 \
    macfja/phpqa-extensions:dev-master \
    povils/phpmnd:^2 \
    rskuipers/php-assumptions:^0 \
    wapmorgan/php-code-analyzer:^1

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
