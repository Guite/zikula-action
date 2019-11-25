#!/bin/sh -l

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

php -d memory_limit=512M -d date.timezone="Europe/Berlin" ${consoleCmd} cache:warmup --env=prod --no-debug

# dump js routes
#php -d memory_limit=512M -d date.timezone="Europe/Berlin" ${consoleCmd} fos:js-routing:dump --env=prod --no-debug --locale=en

#DATABASE_URL="mysql://root:zikula@127.0.0.1:${{ job.services.mysql.ports['3306'] }}/zk_test"
#echo "Run migration"
#composer require symfony/orm-pack
#php ${consoleCmd} doctrine:schema:update --force || echo "No migrations found or schema update failed"
#php ${consoleCmd} doctrine:migrations:migrate || echo "No migrations found or migration failed"

MODULE_PATH="modules/${LC_VENDOR}/${LC_MODULE}-module"
if [ $CORE == "ZK30" || $CORE == "ZK3DEV" ]; then
    echo "Checks: Service Container Linter"
    php ${consoleCmd} lint:container
fi
echo "Checks: YAML Linter"
php ${consoleCmd} lint:yaml "${MODULE_PATH}/Resources" --parse-tags
echo "Checks: Twig Linter"
php ${consoleCmd} lint:twig @${APP_NAME}

echo "Checks: Phan"
./vendor/bin/phan --config-file .phan.php --directory "${MODULE_PATH}"

# not possible yet because "consolidation/robo" (used by phpqa) requires an old version of "league/container"
#echo "Checks: PHP Insights"
#cp ./vendor/nunomaduro/phpinsights/stubs/symfony.php phpinsights.php
#./vendor/bin/phpinsights analyse ./src -v --no-interaction --min-quality=80 --min-complexity=80 --min-architecture=80 --min-style=80

echo "Checks: PHPQA"
# see https://github.com/macfja/phpqa-extensions#usage
php ./vendor/bin/phpqa-extensions.php --add phpa phpca phpmnd
./vendor/bin/phpqa --no-interaction --analyzedDirs "${MODULE_PATH}"

# TODO use this or included in PHPQA?
#TESTSUITE_PATH="modules/${LC_VENDOR}/${LC_MODULE}-module/phpunit.xml.dist"
#if [ -e "${TESTSUITE_PATH}" ]; then
#    echo "Checks: Unit Tests"
    #phpunit --configuration "${TESTSUITE_PATH}" --coverage-text --coverage-clover=coverage.clover -v
#    ./vendor/bin/simple-phpunit "modules/${LC_VENDOR}/${LC_MODULE}-module/"
#fi

if [ ${CREATE_ARTIFACTS} = true ]; then
    echo "Create build artifacts"
    cd ..
    mkdir release
    cd release
    unzip -q "../${APP_NAME}.zip"
    rm -Rf vendor
    rm -Rf .git
    composer install --no-dev --no-progress --no-suggest --prefer-dist --optimize-autoloader
    zip -qr ${APP_NAME}.zip .
    tar cfz ${APP_NAME}.tar.gz .
    # TODO publish both artifacts
fi
