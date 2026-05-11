/**
 * @singleton
 * @presideService
 */
component {

	property name="apiWrapper"  inject="CloudflareApiWrapper";
	property name="zoneService" inject="CloudflareZoneService";
	property name="publicUrl"   inject="coldbox:setting:assetmanager.storage.publicUrl";
	property name="apiTokens"   inject="coldbox:setting:cloudflare.apiTokens";

	public any function init() {
		// Cloudflare limits purge requests for URL and prefix to 100 items per request
		variables.batchSize = 100;

		return this;
	}

	/**
	 * Purges Cloudflare cache for public asset URL prefixes derived from each live site domain and the given asset ids.
	 * No-op when the cachePurge API token is not configured or assetIds is empty.
	 *
	 * @param assetIds Preside asset primary keys whose public paths should be purged
	 */
	public void function purgeAssets( required array assetIds ) {
		if ( !isConfigured( "cachePurge" ) || !ArrayLen( arguments.assetIds ) ) {
			return;
		}

		var sites = $getPresideObject( "site" ).selectData(
			  filter       = { deleted=false }
			, selectFields = [ "domain" ]
			, distinct     = true
		);

		for( var site in sites ) {
			var prefixes = [];
			var zoneId   = zoneService.getZoneId( site.domain );

			if ( !Len( zoneId ) ) {
				continue;
			}
			for( var assetId in arguments.assetIds ) {
				ArrayAppend( prefixes, site.domain & publicUrl & "/" & LCase( assetId ) );
			}

			// Split into batches to comply with Cloudflare's per-request limit
			var prefixCount = ArrayLen( prefixes );
			for( var start=1; start<=prefixCount; start+=variables.batchSize ) {
				var batch = ArraySlice( prefixes, start, Min( variables.batchSize, prefixCount - start + 1 ) );
				apiWrapper.purgeCache( zoneId=zoneId, prefixes=batch );
			}
		}
	}

	/**
	 * Purges Cloudflare cache for all assets in a folder by delegating to #purgeAssets.
	 * No-op when the cachePurge API token is not configured or folderId is empty.
	 *
	 * @param folderId Preside asset folder id whose assets should be purged
	 */
	public void function purgeAssetFolder( required string folderId ) {
		if ( !isConfigured( "cachePurge" ) || !Len( arguments.folderId ) ) {
			return;
		}

		var assets = $getPresideObject( "asset" ).selectData(
			  filter       = { asset_folder=arguments.folderId }
			, selectFields = [ "id" ]
		);

		purgeAssets( assetIds=ValueArray( assets.id ) );
	}

	/**
	 * Indicates whether a named Cloudflare API token is present in application settings.
	 *
	 * @param tokenName key under cloudflare.apiTokens (e.g. cachePurge)
	 * @return true when the token value is non-empty, otherwise false
	 */
	public boolean function isConfigured( required string tokenName ) {
		return Len( apiTokens[ arguments.tokenName ] ?: "" ) > 0;
	}


}