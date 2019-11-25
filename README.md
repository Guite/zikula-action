# GitHub Action for Zikula modules
This repository contains a GitHub Action for building and testing Zikula modules.

For more information about Zikula visit [it's project repository](https://github.com/zikula/core/).

This action downloads and installs a specific Zikula core version in order to check and test a module.

## Inputs

### `vendor-name`
**Required** Name of vendor. Default `"Acme"`.

### `module-name`
**Required** Name of module without vendor and `Module` suffix. Default `"News"`.

### `module-version`
**Required** Version of module using SemVer notation. Default `"1.0.0"`.

### `core-version`
**Required** Specifies the Zikula version which should be used. Must be one of the following options:
  - `ZK30` - Targets the last stable Zikula 3.0.x version.
  - `ZK3DEV` - Targets the last unstable Zikula 3.x version.
  - `ZK20` - Targets the last stable Zikula 2.0.x version. This is the default value.
  - `ZK2DEV` - Targets the last unstable Zikula 2.x version and may include changes for the next upcoming 2.x core release.

### `create-artifacts`
**Optional** Whether to create module archives as build artifacts. Default `false`.

## Outputs

### `results`
Module artifacts including vendor dependencies (zip and tar.gz archives) which can be used for a release.

## Example usage

```
uses: guite/zikula-action@master
with:
  vendor-name: 'Zikula'
  module-name: 'MultiHook'
  module-version: '1.0.0'
  core-version: 'ZK30DEV'
  create-artifacts: true
```

A dummy project using this GitHub Action can be found [here](https://github.com/Guite/test-actions).
