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

### `create_artifacts`
**Optional** Whether to create module archives as build artifacts (set to `true`). Default `false`.

### `database_host`
**Optional** Host of database. Default `"mysql"`.

Note that during a workflow's execution all containers (job, service, actions) get attached to the same user defined bridge network on the host, meaning all the containers can reach each other over that network, not via the host's localhost networking. Thus, this action connects to your database using the name of the corresponding service as hostname.

### `database_port`
**Optional** Port of database. Default `"3306"`.

### `database_user`
**Optional** User of database. Default `"zikula"`.

### `database_pass`
**Optional** Password of database. Default `"zikula"`.

### `database_name`
**Optional** Name of database. Default `"zikula"`.

## Outputs

### `tar_archive`
Module archive in `tar.gz` format including vendor dependencies which can be used for a release.

### `zip_archive`
Module archive in `zip` format including vendor dependencies which can be used for a release.

## Example usage

```
uses: guite/zikula-action@master
with:
  vendor_name: 'Zikula'
  module_name: 'MultiHook'
  module_version: '1.0.0'
  core_version: 'ZK30DEV'
  base_dir: 'src/'
  create_artifacts: true
```

A dummy project using this GitHub Action can be found [here](https://github.com/Guite/test-actions).
