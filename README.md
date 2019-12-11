# GitHub Action for Zikula modules
This repository contains a GitHub Action for building and testing Zikula modules.

For more information about Zikula visit [it's project repository](https://github.com/zikula/core/).

This action downloads and installs a specific Zikula core version in order to check and test a module.

## Inputs

### `vendor_name`
**Required** Name of vendor. Default `"Acme"`.

### `module_name`
**Required** Name of module without vendor and `Module` suffix. Default `"News"`.

### `module_version`
**Required** Version of module using SemVer notation. Default `"1.0.0"`.

### `core_version`
**Required** Specifies the Zikula version which should be used. Must be one of the following options:
  - `ZK30` - Targets the last stable Zikula 3.0.x version.
  - `ZK3DEV` - Targets the last unstable Zikula 3.x version.
  - `ZK20` - Targets the last stable Zikula 2.0.x version. This is the default value.
  - `ZK2DEV` - Targets the last unstable Zikula 2.x version and may include changes for the next upcoming 2.x core release.

### `base_dir`
**Optional** Path to the directory containing the `modules/` folder (including trailing slash). Default `""`.

### `database_host`
**Optional** Host of database. Default `"mysql"`.

Note that during a workflow's execution all containers (job, service, actions) get attached to the same user defined bridge network on the host, meaning all the containers can reach each other over that network, not via the host's localhost networking. Thus, this action connects to your database using the name of the corresponding service as hostname.

### `database_port`
**Optional** Port of database. Default `"3306"`.

Note this is the default port (read explanation for `database_host` above).

### `database_user`
**Optional** User of database. Default `"zikula"`.

### `database_pass`
**Optional** Password of database. Default `"zikula"`.

### `database_name`
**Optional** Name of database. Default `"zikula"`.

### `tools`
**Optional** Comma-separated list of desired analysis tools or `"all"` for all tools.  
Can be used to improve performance by skipping unwanted tools.  
Ensure that it also contains a comma at the start and the end.  
Default value: `",phplint,parallel-lint,lint:container,lint:yaml,lint:twig,phpcs,phpunit-bridge,psecio-parse,security-checker,churn,phploc,phpmetrics,php-coupling-detector,deprecation-detector,"`.

Currently supported tools:

* **Checks (lint):** [phplint](https://github.com/overtrue/phplint), [parallel-lint](https://github.com/JakubOnderka/PHP-Parallel-Lint), [lint:container](https://symfony.com/blog/new-in-symfony-4-4-service-container-linter), [lint:yaml](https://symfony.com/doc/current/components/yaml.html#syntax-validation), [lint:twig](https://symfony.com/doc/current/templates.html#linting-twig-templates), 
* **Checks (coding style):** [phpcs](https://github.com/squizlabs/PHP_CodeSniffer), [php-cs-fixer](https://cs.symfony.com/)
* **Tests:** [phpunit-bridge](https://symfony.com/doc/current/components/phpunit_bridge.html) (requires a file named `phpunit.xml.dist` in the module's root folder).
* **Security:** [psecio-parse](https://github.com/psecio/parse), [security-checker](https://github.com/sensiolabs/security-checker)
* **Info:** [churn](https://github.com/bmitch/churn-php), [phploc](https://github.com/sebastianbergmann/phploc), [dephpend](https://dephpend.com/), [phpmetrics](https://github.com/phpmetrics/PhpMetrics), [php-coupling-detector](https://akeneo.github.io/php-coupling-detector/)
* **Checks (other):** [deprecation-detector](https://github.com/sensiolabs-de/deprecation-detector), [phpinsights](https://phpinsights.com/), [phpmnd](https://github.com/povils/phpmnd), [phpa](https://github.com/rskuipers/php-assumptions)
* **Checks (potentially running a bit longer):** [phpcpd](https://github.com/sebastianbergmann/phpcpd), [phpmd](https://github.com/phpmd/phpmd), [phan](https://github.com/phan/phan), [phpstan](https://github.com/phpstan/phpstan), [psalm](https://github.com/vimeo/psalm)

### `create_artifacts`
**Optional** Whether to create module archives as build artifacts (set to `true`). Default `false`.

## Outputs

If `create_artifacts` is set to `true` then as a result you will have a directory named `AcmeNewsModule_v1.0.0` including vendor dependencies which can be used for a release.

## Example usage

```
uses: guite/zikula-action@master
with:
  vendor_name: Zikula
  module_name: MultiHook
  module_version: '1.0.0'
  core_version: ZK30DEV
  base_dir: 'src/'
  database_host: mysql
  database_port: 3306
  create_artifacts: true
```

A sample project using this GitHub Action can be found [here](https://github.com/Guite/test-actions).
