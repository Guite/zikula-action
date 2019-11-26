#!/bin/bash

VENDOR_NAME=$1
MODULE_NAME=$2
APP_VERSION=$3
CORE=$4
CREATE_ARTIFACTS=$5

APP_NAME="${VENDOR_NAME}${MODULE_NAME}Module"
MODULE_PATH="${VENDOR_NAME}/${MODULE_NAME}Module"
LC_VENDOR="$(tr [A-Z] [a-z] <<< "${VENDOR_NAME}")"
LC_MODULE="$(tr [A-Z] [a-z] <<< "${MODULE_NAME}")"

echo "Install dependencies of ${MODULE_PATH}"
composer install --no-progress --no-suggest --prefer-dist --optimize-autoloader
zip -qr ${APP_NAME}.zip .

if [ $CORE == "ZK2DEV" || $CORE == "ZK15DEV" ]; then
    CORE_BRANCH=$(( $CORE == "ZK2DEV" ? "2.0" : "1.5" ))
    CORE_VERSION=${CORE_BRANCH}
    echo "Download Zikula Core version ${CORE_VERSION} branch"
    wget "https://github.com/zikula/core/archive/${CORE_VERSION}.tar.gz"
    tar -xpzf "${CORE_VERSION}.tar.gz" && rm "${CORE_VERSION}.tar.gz"
else
    if [ $CORE == "ZK30" || $CORE == "ZK3DEV" ]; then
        CORE_BRANCH="master"
        CORE_VERSION=${CORE_BRANCH}
    elif [ $CORE == "ZK20" || $CORE == "ZK15" ]; then
        CORE_BRANCH=$(( $CORE == "ZK20" ? "2.0" : "1.5" ))
        CORE_VERSION=$(( $CORE == "ZK20" ? "2.0.15" : "1.5.9" ))
    fi
    echo "Download Zikula Core version ${CORE_VERSION} release"
    wget "https://github.com/zikula/core/releases/download/${CORE_VERSION}/${CORE_BRANCH}.tar.gz"
    tar -xpzf "${CORE_BRANCH}.tar.gz" && rm "${CORE_BRANCH}.tar.gz"
fi

consoleCmd="bin/console"
if [ $CORE == "ZK15" || $CORE == "ZK15DEV" ]; then
    consoleCmd="app/console"
fi

echo "Install Zikula Core version ${CORE_VERSION}"
cd "${CORE_BRANCH}"
php ${consoleCmd} zikula:install:start -n --database_user=root --database_name=zk_test --password=12345678 --email=admin@example.com --router:request_context:host=localhost
php ${consoleCmd} zikula:install:finish
mkdir -p "web/imagine/cache"

echo "Install ${APP_NAME}"
cd modules
mkdir "${LC_VENDOR}" && cd "${LC_VENDOR}"
mkdir "${LC_MODULE}-module" && cd "${LC_MODULE}-module"
unzip -q ../../../../${APP_NAME}
cd  ../../..

php ${consoleCmd} bootstrap:bundles
if [ $CORE == "ZK30" || $CORE == "ZK3DEV" ]; then
    mysql -e "INSERT INTO zk_test.modules (id, name, type, displayname, url, description, version, capabilities, state, securityschema, coreCompatibility) VALUES (NULL, '${APP_NAME}', '3', '${APP_NAME}', '${LC_MODULE}', 'Test module description', '${APP_VERSION}', 'N;', '3', 'N;', '${CORE_VERSION}');"
else
    mysql -e "INSERT INTO zk_test.modules (id, name, type, displayname, url, description, version, capabilities, state, securityschema, core_min, core_max) VALUES (NULL, '${APP_NAME}', '3', '${APP_NAME}', '${LC_MODULE}', 'Test module description', '${APP_VERSION}', 'N;', '3', 'N;', '${CORE_VERSION}', '3.0.0');"
fi

php ${consoleCmd} cache:warmup --env=prod --no-debug

# dump js routes
#php ${consoleCmd} fos:js-routing:dump --env=prod --no-debug --locale=en

#DATABASE_URL="mysql://root:zikula@127.0.0.1:${{ job.services.mysql.ports['3306'] }}/zk_test"
#echo "Run migration"
#composer require symfony/orm-pack
#php ${consoleCmd} doctrine:schema:update --force || echo "No migrations found or schema update failed"
#php ${consoleCmd} doctrine:migrations:migrate || echo "No migrations found or migration failed"

TOOL_BIN_PATH="/tools/.composer/vendor/bin/"
TOOL_CONFIG_PATH="/tool-config/"
MODULE_PATH="modules/${LC_VENDOR}/${LC_MODULE}-module"
VENDOR_PATH="${MODULE_PATH}/vendor"

# Available tools: https://github.com/jakzal/phpqa/#available-tools

echo "Checks: PHP lint"
# see https://github.com/overtrue/phplint
${TOOL_BIN_PATH}phplint "${MODULE_PATH}" --exclude="${VENDOR_PATH}" -c="${TOOL_CONFIG_PATH}phplint.yml"
# see https://github.com/JakubOnderka/PHP-Parallel-Lint
${TOOL_BIN_PATH}parallel-lint --colors --exclude "${VENDOR_PATH}" "${MODULE_PATH}"

if [ $CORE == "ZK30" || $CORE == "ZK3DEV" ]; then
    echo "Checks: Service container lint"
    php ${consoleCmd} lint:container
fi
echo "Checks: YAML lint"
php ${consoleCmd} lint:yaml "${MODULE_PATH}/Resources" --parse-tags
echo "Checks: Twig lint"
php ${consoleCmd} lint:twig "@${APP_NAME}"

echo "Checks: coding style"
# see https://github.com/squizlabs/PHP_CodeSniffer
${TOOL_BIN_PATH}phpcs --standard=${TOOL_CONFIG_PATH}phpcs.xml --extensions=php --ignore="${VENDOR_PATH}" "${MODULE_PATH}" --report=full

echo "Checks: fix coding style"
# see https://cs.symfony.com/
${TOOL_BIN_PATH}php-cs-fixer fix --diff --dry-run --config "${TOOL_CONFIG_PATH}php_cs_fixer.dist" "${MODULE_PATH}"

echo "Checks: easy coding standard"
# see https://github.com/Symplify/EasyCodingStandard
${TOOL_BIN_PATH}ecs check "${MODULE_PATH}" --config "${TOOL_CONFIG_PATH}ecs.yml"

# see https://symfony.com/doc/current/components/phpunit_bridge.html
# see https://github.com/symfony/phpunit-bridge/
TESTSUITE_PATH="${MODULE_PATH}/phpunit.xml.dist"
if [ -e "${TESTSUITE_PATH}" ]; then
    echo "Checks: Unit tests with coverage"
    php -dpcov.enabled=1 -dpcov.directory=. -dpcov.exclude="~vendor~" ${TOOL_BIN_PATH}/simple-phpunit "${MODULE_PATH}" --coverage-text

    # TODO review and cleanup
    # https://github.com/sebastianbergmann/phpcov
    # ${TOOL_BIN_PATH}/phpcov 
fi

echo "Security: Parse"
# see https://github.com/psecio/parse
${TOOL_BIN_PATH}psecio-parse scan "${MODULE_PATH}"

echo "Security: Sensiolabs"
# see https://github.com/sensiolabs/security-checker
${TOOL_BIN_PATH}security-checker security:check "${MODULE_PATH}/composer.lock"

echo "Info: churn"
# see https://github.com/bmitch/churn-php
${TOOL_BIN_PATH}churn run -c "/tool-config/churn.yml" "${MODULE_PATH}"

echo "Info: phploc"
# see https://github.com/sebastianbergmann/phploc
${TOOL_BIN_PATH}phploc "${MODULE_PATH}"

echo "Info: pdepend"
# see https://pdepend.org/ + https://github.com/pdepend/pdepend
${TOOL_BIN_PATH}pdepend "${MODULE_PATH}"

echo "Info: dephpend"
# see https://dephpend.com/
${TOOL_BIN_PATH}dephpend dsm "${MODULE_PATH}"
${TOOL_BIN_PATH}dephpend metrics "${MODULE_PATH}"

echo "Info: PhpMetrics"
# see https://github.com/phpmetrics/PhpMetrics + https://www.phpmetrics.org
${TOOL_BIN_PATH}phpmetrics "${MODULE_PATH}"

echo "Info: PHP Coupling Detector"
# see https://akeneo.github.io/php-coupling-detector/
${TOOL_BIN_PATH}php-coupling-detector detect "${MODULE_PATH}" #--config-file="${TOOL_CONFIG_PATH}php_cd.php"

echo "Checks: Deprecation Detector"
# see https://github.com/sensiolabs-de/deprecation-detector
${TOOL_BIN_PATH}deprecation-detector check "${MODULE_PATH}" "${VENDOR_PATH}"

echo "Checks: Copy paste detection"
# see https://github.com/sebastianbergmann/phpcpd
${TOOL_BIN_PATH}phpcpd --exclude "${VENDOR_PATH}" "${MODULE_PATH}"

echo "Checks: Mess detection"
# see https://phpmd.org/ + https://github.com/phpmd/phpmd
${TOOL_BIN_PATH}phpmd "${MODULE_PATH}" text "${TOOL_CONFIG_PATH}phpmd.xml" --exclude "${VENDOR_PATH}"

echo "Checks: Phan"
# see https://github.com/phan/phan
${TOOL_BIN_PATH}phan --config-file "${TOOL_CONFIG_PATH}phan.php" --directory "${MODULE_PATH}"

echo "Checks: PHPStan"
# see https://github.com/phpstan/phpstan
# level: (0 = loosest - 7 = "max" = strictest), default level is 0
${TOOL_BIN_PATH}phpstan analyse -l=0 -c phpstan.neon "${MODULE_PATH}" --ignoredDirs=vendor

echo "Checks: PHP Insights"
# see https://phpinsights.com/
${TOOL_BIN_PATH}phpinsights analyse ./src -v --config-path="${TOOL_CONFIG_PATH}phpinsights.php" --no-interaction --min-quality=80 --min-complexity=80 --min-architecture=80 --min-style=80

echo "Checks: Psalm"
# see https://psalm.dev/ + https://github.com/vimeo/psalm
${TOOL_BIN_PATH}psalm --init
${TOOL_BIN_PATH}psalm "${MODULE_PATH}" -c="${TOOL_CONFIG_PATH}psalm.xml" --find-dead-code --threads=8 --diff --diff-methods --show-info=1

echo "Checks: PHP Magic Number Detector"
# see https://github.com/povils/phpmnd
${TOOL_BIN_PATH}phpmnd "${MODULE_PATH}" --ignore-funcs=round,sleep --exclude="${VENDOR_PATH}" \
 --extensions=argument,array,assign,condition,default_parameter,operation,property,return,switch_case

echo "Checks: PHP Assumptions"
# see https://github.com/rskuipers/php-assumptions
${TOOL_BIN_PATH}phpa "${MODULE_PATH}" --exclude="${VENDOR_PATH}"

if [ ${CREATE_ARTIFACTS} = true ]; then
    echo "Create build artifacts"
    cd ..
    mkdir release
    cd release
    unzip -q "../${APP_NAME}.zip"
    rm -Rf vendor
    rm -Rf .git
    composer install --no-dev --no-progress --no-suggest --prefer-dist --optimize-autoloader
    zip -qr "${APP_NAME}_v${APP_VERSION}.zip" .
    tar cfz "${APP_NAME}_v${APP_VERSION}.tar.gz" .

    echo ::set-output name=tar-archive::${APP_NAME}_v${APP_VERSION}.tar.gz
    echo ::set-output name=zip-archive::${APP_NAME}_v${APP_VERSION}.zip
fi
