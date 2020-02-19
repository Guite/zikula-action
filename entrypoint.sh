#!/bin/bash

WORKSPACE_ROOT="${GITHUB_WORKSPACE}/"
VENDOR_NAME=$INPUT_VENDOR_NAME
MODULE_NAME=$INPUT_MODULE_NAME
APP_VERSION=$INPUT_MODULE_VERSION
CORE=$INPUT_CORE_VERSION
BASE_DIR=$INPUT_BASE_DIR

DB_HOST=${INPUT_DATABASE_HOST:mysql}
DB_PORT=${INPUT_DATABASE_PORT:default}
if [ "$DB_PORT" = "default" ]; then
    DB_HOST='3306'
fi
DB_USER=${INPUT_DATABASE_USER:zikula}
DB_PASS=${INPUT_DATABASE_PASS:zikula}
DB_NAME=${INPUT_DATABASE_NAME:zikula}

TOOLS=${INPUT_TOOLS:default}
if [ "$TOOLS" = "default" ]; then
    TOOLS=',phplint,parallel-lint,lint:container,lint:yaml,lint:twig,translations,doctrine-info,phpcs,php-cs-fixer,phpunit-bridge,security-checker,churn,phploc,phpmetrics,php-coupling-detector,deprecation-detector,phpinsights,'
fi
CREATE_ARTIFACTS=${INPUT_CREATE_ARTIFACTS:false}

# echo "Vendor: ${VENDOR_NAME}"
# echo "Module: ${MODULE_NAME}"
# echo "Version: ${APP_VERSION}"
# echo "Core: ${CORE}"
# echo "Base dir: ${BASE_DIR}"
# echo "DB Host: ${DB_HOST}"
# echo "DB Port: ${DB_PORT}"
# echo "DB User: ${DB_USER}"
# echo "DB Pass: ${DB_PASS}"
# echo "DB Name: ${DB_NAME}"
# echo "Tools: ${TOOLS}"
# echo "Create artifacts: ${CREATE_ARTIFACTS}"

mysqlCmd="mysql -h ${DB_HOST} --port ${DB_PORT} -u ${DB_USER} -p${DB_PASS} -e"

echo "Starting process for ${MODULE_NAME}"

APP_NAME="${VENDOR_NAME}${MODULE_NAME}Module"
MODULE_PATH="${BASE_DIR}extensions/${VENDOR_NAME}/${MODULE_NAME}Module"
if [ ! -d "$MODULE_PATH" ]; then
    MODULE_PATH="${BASE_DIR}modules/${VENDOR_NAME}/${MODULE_NAME}Module"
fi
VENDOR_PATH="${MODULE_PATH}/vendor"
LC_MODULE="$( echo "${MODULE_NAME}" | tr -s  '[:upper:]'  '[:lower:]' )"
TOOL_BIN_PATH="/tools/"
TOOL_CONFIG_PATH="/tool-config/"

echo "Install dependencies of ${APP_NAME}"
cd "${MODULE_PATH}"
composer install --no-progress --no-suggest --prefer-dist --optimize-autoloader
cd ${WORKSPACE_ROOT}
zip -qr "${APP_NAME}.zip" .
mkdir -p "work" && cd "work/"

CORE_BRANCH=""
CORE_VERSION=""
CORE_DIRECTORY=""
if [ "$CORE" = "ZK20" ] || [ "$CORE" = "ZK15" ]; then
    if [ "$CORE" = "ZK15" ]; then
        CORE_BRANCH="1.5"
        CORE_VERSION="1.5.9"
    else
        CORE_BRANCH="2.0"
        CORE_VERSION="2.0.15"
    fi
    echo "Download Zikula Core version ${CORE_VERSION} release"
    wget "https://github.com/zikula/core/releases/download/${CORE_VERSION}/${CORE_BRANCH}.tar.gz"
    CORE_DIRECTORY=${CORE_BRANCH}
else
    if [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
        CORE_BRANCH="master"
        CORE_VERSION=${CORE_BRANCH}
    elif [ "$CORE" = "ZK2DEV" ]; then
        CORE_BRANCH="2.0"
    elif [ "$CORE" = "ZK15DEV" ]; then
        CORE_BRANCH="1.5"
    fi
    CORE_VERSION=${CORE_BRANCH}
    echo "Download Zikula Core from ${CORE_VERSION} branch"
    wget "https://github.com/zikula/core/archive/${CORE_VERSION}.tar.gz"
    CORE_DIRECTORY="core-${CORE_BRANCH}"
fi
tar -xpzf "${CORE_BRANCH}.tar.gz" && rm "${CORE_BRANCH}.tar.gz"
SRC_DIR=""
if [ "$CORE" = "ZK15DEV" ] || [ "$CORE" = "ZK2DEV" ] || [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
    SRC_DIR="src/"
fi

consoleCmd="bin/console"
if [ "$CORE" = "ZK20" ]; then
    consoleCmd="bin/console"
elif [ "$CORE" = "ZK15" ]; then
    consoleCmd="app/console"
elif [ "$CORE" = "ZK15DEV" ]; then
    consoleCmd="app/console"
fi

cd "${CORE_DIRECTORY}"
if [ "$SRC_DIR" != "" ]; then
    echo "Install core dependencies"
    composer install --no-progress --no-suggest --prefer-dist --optimize-autoloader

    if [ "$CORE" != "ZK30" ] && [ "$CORE" != "ZK3DEV" ]; then
        cd "${SRC_DIR}"
    fi
fi

echo "Create database"
${mysqlCmd} "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"

echo "Install Zikula Core version ${CORE_VERSION}"
php ${consoleCmd} zikula:install:start -n --database_host=${DB_HOST} --database_user=${DB_USER} --database_name=${DB_NAME} --database_password=${DB_PASS} --password=zkTest4CI --email=admin@example.com --router:request_context:host=localhost --router:request_context:base_url='/'
php ${consoleCmd} zikula:install:finish
if [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
    mkdir -p "public/media/cache"
else
    mkdir -p "web/imagine/cache"
fi

if [ "$SRC_DIR" != "" ]; then
    if [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
        cd "${SRC_DIR}"
    fi
fi
echo "Install ${APP_NAME}"
unzip -q "${WORKSPACE_ROOT}${APP_NAME}.zip"
if [ "$SRC_DIR" != "" ]; then
    if [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
        cd ..
    fi
fi

if [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
    php ${consoleCmd} zikula:extension:install "${APP_NAME}"
else
    php ${consoleCmd} bootstrap:bundles
    if [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
        ${mysqlCmd} "INSERT INTO ${DB_NAME}.modules (id, name, type, displayname, url, description, version, capabilities, state, securityschema, coreCompatibility) VALUES (NULL, '${APP_NAME}', '3', '${MODULE_NAME}', '${LC_MODULE}', 'Test module description', '${APP_VERSION}', 'N;', '3', 'N;', '${CORE_VERSION}');"
    else
        ${mysqlCmd} "INSERT INTO ${DB_NAME}.modules (id, name, type, displayname, url, description, version, capabilities, state, securityschema, core_min, core_max) VALUES (NULL, '${APP_NAME}', '3', '${APP_NAME}', '${LC_MODULE}', 'Test module description', '${APP_VERSION}', 'N;', '3', 'N;', '${CORE_VERSION}', '3.0.0');"
    fi

    php ${consoleCmd} cache:warmup --env=prod --no-debug
fi

# dump js routes
#php ${consoleCmd} fos:js-routing:dump --env=prod --no-debug --locale=en

#echo "Run migration"
#composer require symfony/orm-pack
#php ${consoleCmd} doctrine:schema:update --force || echo "No migrations found or schema update failed"
#php ${consoleCmd} doctrine:migrations:migrate || echo "No migrations found or migration failed"

# Available tools: https://github.com/jakzal/phpqa/#available-tools

echo "Running tools: $TOOLS"

# TODO LOKAL TESTEN
echo "DEBUG"
pwd
ls -l
echo "${MODULE_PATH}"

if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phplint,"* ]]; then
    echo "Checks: PHP lint"
    # see https://github.com/overtrue/phplint
    ${TOOL_BIN_PATH}phplint "${MODULE_PATH}" --exclude="${VENDOR_PATH}" --configuration="${TOOL_CONFIG_PATH}phplint.yml"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",parallel-lint,"* ]]; then
    # see https://github.com/JakubOnderka/PHP-Parallel-Lint
    ${TOOL_BIN_PATH}parallel-lint --colors --exclude "${VENDOR_PATH}" "${MODULE_PATH}"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",lint:container,"* ]]; then
    if [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
        echo "Checks: Service container lint"
        php ${consoleCmd} lint:container
    fi
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",lint:yaml,"* ]]; then
    echo "Checks: YAML lint"
    php ${consoleCmd} lint:yaml "@${APP_NAME}" --parse-tags
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",lint:twig,"* ]]; then
    echo "Checks: Twig lint"
    if [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
        php ${consoleCmd} lint:twig --show-deprecations "@${APP_NAME}"
        if [ -d "templates/" ]; then
            php ${consoleCmd} lint:twig --show-deprecations "templates/"
        fi
    else
        php ${consoleCmd} lint:twig "@${APP_NAME}"
        if [ -d "app/" ]; then
            php ${consoleCmd} lint:twig "app/"
        fi
    fi
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",translations,"* ]]; then
    if [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
        echo "Checks: Translation extraction"
        php -dmemory_limit=2G bin/console translation:extract --bundle="${APP_NAME}" extension en
    fi
fi

if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",doctrine-info,"* ]]; then
    echo "Info: Doctrine Mappings"
    php ${consoleCmd} doctrine:mapping:info
    echo "Info: Doctrine Schema"
    php ${consoleCmd} doctrine:schema:validate --skip-sync
fi

if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phpcs,"* ]]; then
    echo "Checks: coding style"
    # see https://github.com/squizlabs/PHP_CodeSniffer
    ${TOOL_BIN_PATH}phpcs --standard=${TOOL_CONFIG_PATH}phpcs.xml --extensions=php --ignore="${VENDOR_PATH}" "${MODULE_PATH}" --report=full
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",php-cs-fixer,"* ]]; then
    echo "Checks: fix coding style"
    # see https://cs.symfony.com/
    ${TOOL_BIN_PATH}php-cs-fixer fix --diff --dry-run --config "${TOOL_CONFIG_PATH}php_cs_fixer.dist" "${MODULE_PATH}"
fi

if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phpunit-bridge,"* ]]; then
    # see https://symfony.com/doc/current/components/phpunit_bridge.html
    TESTSUITE_PATH="${MODULE_PATH}/phpunit.xml.dist"
    if [ -e "${TESTSUITE_PATH}" ]; then
        echo "Checks: Unit tests with coverage"
        php -dpcov.enabled=1 -dpcov.directory=. -dpcov.exclude="~vendor~" ${TOOL_BIN_PATH}/simple-phpunit "${MODULE_PATH}" --coverage-text
    fi
fi

if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",psecio-parse,"* ]]; then
    echo "Security: Parse"
    # see https://github.com/psecio/parse
    ${TOOL_BIN_PATH}psecio-parse scan --ignore-paths="${VENDOR_PATH}" "${MODULE_PATH}"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",security-checker,"* ]]; then
    echo "Security: Sensiolabs"
    # see https://github.com/sensiolabs/security-checker
    ${TOOL_BIN_PATH}security-checker security:check "${MODULE_PATH}/composer.lock"
fi

if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",churn,"* ]]; then
    echo "Info: churn"
    # see https://github.com/bmitch/churn-php
    ${TOOL_BIN_PATH}churn run -c "${TOOL_CONFIG_PATH}churn.yml" "${MODULE_PATH}"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phploc,"* ]]; then
    echo "Info: phploc"
    # see https://github.com/sebastianbergmann/phploc
    ${TOOL_BIN_PATH}phploc "${MODULE_PATH}"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",dephpend,"* ]]; then
    echo "Info: dephpend metrics"
    # see https://dephpend.com/
    ${TOOL_BIN_PATH}dephpend metrics "${MODULE_PATH}"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phpmetrics,"* ]]; then
    echo "Info: PhpMetrics"
    # see https://github.com/phpmetrics/PhpMetrics
    ${TOOL_BIN_PATH}phpmetrics "${MODULE_PATH}"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",php-coupling-detector,"* ]]; then
    echo "Info: PHP Coupling Detector"
    # see https://akeneo.github.io/php-coupling-detector/
    ${TOOL_BIN_PATH}php-coupling-detector detect "${MODULE_PATH}" --config-file="${TOOL_CONFIG_PATH}phpcd.php"
fi

if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",deprecation-detector,"* ]]; then
    echo "Checks: Deprecation Detector"
    # see https://github.com/sensiolabs-de/deprecation-detector
    ${TOOL_BIN_PATH}deprecation-detector check "${MODULE_PATH}" "${VENDOR_PATH}"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phpcpd,"* ]]; then
    echo "Checks: phpcpd / Copy paste detection"
    # see https://github.com/sebastianbergmann/phpcpd
    ${TOOL_BIN_PATH}phpcpd --exclude "${VENDOR_PATH}" "${MODULE_PATH}"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phpmd,"* ]]; then
    echo "Checks: phpmd / Mess detection"
    # see https://github.com/phpmd/phpmd
    ${TOOL_BIN_PATH}phpmd "${MODULE_PATH}" text "${TOOL_CONFIG_PATH}phpmd.xml" --exclude "${VENDOR_PATH}"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phan,"* ]]; then
    echo "Checks: Phan"
    # see https://github.com/phan/phan
    ${TOOL_BIN_PATH}phan --config-file "${TOOL_CONFIG_PATH}phan.php" --directory "${MODULE_PATH}"
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phpstan,"* ]]; then
    echo "Checks: PHPStan"
    # see https://github.com/phpstan/phpstan
    # level: (0 = loosest - 7 = "max" = strictest), default level is 0
    if [ "$CORE" = "ZK30" ] || [ "$CORE" = "ZK3DEV" ]; then
        ${TOOL_BIN_PATH}phpstan analyse -l=0 -c "${TOOL_CONFIG_PATH}phpstan_zk3.neon" "${MODULE_PATH}"
    elif [ "$CORE" = "ZK20" ] || [ "$CORE" = "ZK2DEV" ]; then
        ${TOOL_BIN_PATH}phpstan analyse -l=0 -c "${TOOL_CONFIG_PATH}phpstan_zk2.neon" "${MODULE_PATH}"
    else
        ${TOOL_BIN_PATH}phpstan analyse -l=0 -c "${TOOL_CONFIG_PATH}phpstan_zk1.neon" "${MODULE_PATH}"
    fi
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phpinsights,"* ]]; then
    echo "Checks: PHP Insights"
    # see https://phpinsights.com/
    ${TOOL_BIN_PATH}phpinsights analyse ./src -v --config-path="${TOOL_CONFIG_PATH}phpinsights.php" --no-interaction --min-quality=80 --min-complexity=80 --min-architecture=80 --min-style=80
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",psalm,"* ]]; then
    echo "Checks: Psalm"
    # see https://github.com/vimeo/psalm
    ${TOOL_BIN_PATH}psalm --init "${MODULE_PATH}"
    ${TOOL_BIN_PATH}psalm "${MODULE_PATH}" --find-dead-code --threads=8 --diff --diff-methods --show-info=1
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phpmnd,"* ]]; then
    echo "Checks: PHP Magic Number Detector"
    # see https://github.com/povils/phpmnd
    ${TOOL_BIN_PATH}phpmnd "${MODULE_PATH}" --ignore-funcs=round,sleep --exclude="${VENDOR_PATH}" \
    --extensions=argument,array,assign,condition,default_parameter,operation,property,return,switch_case
fi
if [ "$TOOLS" = "all" ] || [[ "$TOOLS" == *",phpa,"* ]]; then
    echo "Checks: PHP Assumptions"
    # see https://github.com/rskuipers/php-assumptions
    ${TOOL_BIN_PATH}phpa "${MODULE_PATH}" --exclude="${VENDOR_PATH}"
fi

cd ${WORKSPACE_ROOT} && rm -rf "work/"

if [ "$CREATE_ARTIFACTS" = true ]; then
    echo "Create build artifacts"
    cd "${WORKSPACE_ROOT}"
    RELEASE_NAME="${APP_NAME}_v${APP_VERSION}"
    mkdir "${RELEASE_NAME}" && cd "${RELEASE_NAME}"
    unzip -q "${WORKSPACE_ROOT}${APP_NAME}.zip"
    rm -Rf .git
    rm -Rf .github

    cd "${MODULE_PATH}"
    rm -Rf "vendor"
    composer install --no-dev --no-progress --no-suggest --prefer-dist --optimize-autoloader
fi
