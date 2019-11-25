FROM php:7.3-alpine

# Use the default development configuration
RUN mv "$PHP_INI_DIR/php.ini-development" "$PHP_INI_DIR/php.ini"
# Use the default production configuration
#RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# install php extensions and composer
# xml is required by phpunit, php-ast is used by phan
# note we do not install phpunit, since composer installs Symfony's phpunit-bridge providing simple-phpunit
# note pcov is much faster than xdebug
RUN apk add php7 php7-ctype php7-gd php7-iconv php7-json php7-mbstring php7-mysqli php7-mysqlnd php7-session php7-simplexml php7-tokenizer php7-xml php-pecl-ast php7-pecl-pcov composer

# install required additional releng tools
RUN composer require jakub-onderka/php-parallel-lint:^1
RUN composer require jakub-onderka/php-console-highlighter:^0
RUN composer require phpunit/phpunit:^8
RUN composer require friendsofphp/php-cs-fixer:^2
RUN composer require consolidation/robo:^1
RUN composer require phan/phan:^2
RUN composer require phpstan/phpstan:^0
RUN composer require phpstan/phpstan-doctrine:^0
RUN composer require phpstan/phpstan-phpunit:^0
RUN composer require phpstan/phpstan-symfony:^0
RUN composer require sensiolabs/security-checker:^6
RUN composer require vimeo/psalm:^3
RUN composer require edgedesign/phpqa:^1
RUN composer require macfja/phpqa-extensions:dev-master
RUN composer require povils/phpmnd:^2
RUN composer require rskuipers/php-assumptions:^0
RUN composer require wapmorgan/php-code-analyzer:^1

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
