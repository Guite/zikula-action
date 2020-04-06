# GitHub Action for Zikula modules

This repository contains a GitHub Action for building and testing Zikula modules.

For more information about Zikula visit [it's project repository](https://github.com/zikula/core/).

This action downloads and installs a specific Zikula core version in order to check and test a module.

## Inputs

1. Name of vendor. Example: `Acme`.
2. Name of module without vendor and `Module` suffix. Example: `News`.
3. Version of module using SemVer notation. Example: `1.0.0`.
4. The Zikula version which should be used. Must be one of the following options:
  - `ZK30` - Targets the last stable Zikula 3.0.x version.
  - `ZK3DEV` - Targets the last unstable Zikula 3.x version (Git branch).
  - `ZK20` - Targets the last stable Zikula 2.0.x version.
  - `ZK2DEV` - Targets the last unstable Zikula 2.x version (Git branch).
  - `ZK15` - Targets the last stable Zikula 1.5.x version.
  - `ZK15DEV` - Targets the last unstable Zikula 1.5.x version (Git branch).
5. Path to the directory containing the `extensions/` folder (including trailing slash). Default `""`.
6. Whether to create module archives as build artifacts (set to `true`). Default `false`.
7. Host of database. Default `"mysql"`.
  - Note that during a workflow's execution all containers (job, service, actions) get attached to the same user defined bridge network on the host, meaning all the containers can reach each other over that network, not via the host's localhost networking. Thus, this action connects to your database using the name of the corresponding service as hostname.
8. Port of database. Default `"3306"`.
  - Note this is the default port (read explanation for `database_host` above).
9. User of database. Default `"zikula"`.
10. Password of database. Default `"zikula"`.
11. Name of database. Default `"zikula"`.
12. Comma-separated list of desired analysis tools or `"all"` for all tools.
  - Can be used to improve performance by skipping unwanted tools.
  - Ensure that it also contains a comma at the start and the end.
  - Default value: `",phplint,parallel-lint,lint:container,lint:yaml,lint:twig,translations,doctrine-info,phpcs,phpunit-bridge,security-checker,phploc,phpmetrics,php-coupling-detector,deprecation-detector,"`.

### Currently supported tools

- **Checks (lint):** [phplint](https://github.com/overtrue/phplint), [parallel-lint](https://github.com/JakubOnderka/PHP-Parallel-Lint), [lint:container](https://symfony.com/blog/new-in-symfony-4-4-service-container-linter), [lint:yaml](https://symfony.com/doc/current/components/yaml.html#syntax-validation), [lint:twig](https://symfony.com/doc/current/templates.html#linting-twig-templates)
- **Translations:** translations executes the `translation:extract` command
- **Checks (coding style):** [phpcs](https://github.com/squizlabs/PHP_CodeSniffer), [php-cs-fixer](https://cs.symfony.com/)
- **Tests:** [phpunit-bridge](https://symfony.com/doc/current/components/phpunit_bridge.html) (requires a file named `phpunit.xml.dist` in the module's root folder).
- **Security:** [psecio-parse](https://github.com/psecio/parse), [security-checker](https://github.com/sensiolabs/security-checker)
- **Info:** [churn](https://github.com/bmitch/churn-php), [phploc](https://github.com/sebastianbergmann/phploc), [dephpend](https://dephpend.com/), [phpmetrics](https://github.com/phpmetrics/PhpMetrics), [php-coupling-detector](https://akeneo.github.io/php-coupling-detector/)
- **Checks (other):** [deprecation-detector](https://github.com/sensiolabs-de/deprecation-detector), [phpinsights](https://phpinsights.com/), [phpmnd](https://github.com/povils/phpmnd), [phpa](https://github.com/rskuipers/php-assumptions)
- **Checks (potentially running a bit longer):** [phpcpd](https://github.com/sebastianbergmann/phpcpd), [phpmd](https://github.com/phpmd/phpmd), [phan](https://github.com/phan/phan), [phpstan](https://github.com/phpstan/phpstan), [psalm](https://github.com/vimeo/psalm)

## Outputs

If `create_artifacts` is set to `true` then as a result you will have a directory named `AcmeNewsModule_v1.0.0` including vendor dependencies which can be used for a release.

## Example usage

```
uses: docker://guite/zikula-action:latest
with:
  args: Zikula MultiHook 1.0.0 ZK3DEV src/ true
```

A sample project using this GitHub Action can be found [here](https://github.com/Guite/test-actions).

## Usage without GitHub Actions

The Docker image for this action is built automatically and located here: <https://hub.docker.com/r/guite/zikula-action>.

You can run it in any given directory like this:

```
docker run --rm -it -w=/app -v ${PWD}:/app guite/zikula-action:latest Zikula MultiHook 1.0.0 ZK3DEV src/ true
```
