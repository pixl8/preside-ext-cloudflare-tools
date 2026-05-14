# Cloudflare Tools extension

An extension to provide Cloudflare API functionality from within a Preside application.

Initially, this is limited to purging assets from the Cloudflare cache.


## Requirements

For cache purging, you will need a *Cloudflare API token*. The token you need is user-based, not account-based.

* Go to *My Profile*, and select *API Tokens*
* Click on *Create Token*, then *Create Custom Token: Get started*
* Give the token a name
* Add permission *Zone > Cache Purge > Purge*
* Add permission *Zone > Zone > Read*
* *Continue to summary* then *Create Token*
* Make a record of your token, which will start with `cfut_`

The functionality depends on newly-added interception points in Preside, so you will need a minimum of one of the following versions of Preside:

* 10.30.23
* 10.29.40
* 10.28.62
* 10.27.98
* 10.26.127


## Setup

You can provide your application with the token in one of two ways:

* Set `CLOUDFLARE_API_TOKEN_CACHE_PURGE` environment variable (recommended)
* Set `settings.cloudflare.apiTokens.cachePurge` in your _Config.cfc_

## Usage

In the Asset Manager, whenever you *Reset derivatives* for a single asset, multiple assets or an entire folder, those assets will automatically also be purged from the Cloudflare cache.
