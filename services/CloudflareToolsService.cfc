/**
  * @singleton
 * @presideService
 */
component {

	property name="apiWrapper" inject="CloudflareApiWrapper";
	property name="publicUrl"  inject="coldbox:setting:assetmanager.storage.publicUrl";
	property name="apiTokens"  inject="coldbox:setting:cloudflare.apiTokens";

	public any function init() {
		return this;
	}

	/**
	 * Resolves the Cloudflare zone id for a hostname, using the cloudflare_zone record when present
	 * or the Cloudflare API with parent-domain fallback. Persists lookup results (including not-found state).
	 *
	 * @param domain hostname to resolve (e.g. site apex or www)
	 * @return Cloudflare zone id, or an empty string when no zone could be resolved
	 */
	public string function getZoneId( required string domain ) {
		var zoneRecord = $getPresideObject( "cloudflare_zone" ).selectData( filter={ domain=arguments.domain } );
		if( zoneRecord.recordCount ) {
			return zoneRecord.zone_id;
		}

		var lookupDomain = arguments.domain;
		var zone         = {}

		do {
			zone = apiWrapper.getZone( domain=lookupDomain );
			if( Len( zone.id ?: "" ) ) {
				_saveZone( domain=arguments.domain, zoneId=zone.id, zoneName=zone.name );
				return zone.id;
			}
			lookupDomain = ListRest( lookupDomain, "." );
		} while( ListLen( lookupDomain, "." ) > 1 );

		_saveZone( domain=arguments.domain );

		return "";
	}

	/**
	 * Purges Cloudflare cache for public asset URL prefixes derived from each live site domain and the given asset ids.
	 * No-op when the cachePurge API token is not configured or assetIds is empty.
	 *
	 * @param assetIds Preside asset primary keys whose public paths should be purged
	 */
	public void function clearAssetCache( required array assetIds ) {
		if ( !isConfigured( "cachePurge" ) || !ArrayLen( arguments.assetIds ) ) {
			return;
		}

		var batchSize = 30;
		var sites     = $getPresideObject( "site" ).selectData(
			  filter       = { deleted=false }
			, selectFields = [ "domain" ]
			, distinct     = true
		);

		for( var site in sites ) {
			var prefixes = [];
			var zoneId   = getZoneId( site.domain );

			if ( !Len( zoneId ) ) {
				continue;
			}
			for( var assetId in arguments.assetIds ) {
				ArrayAppend( prefixes, site.domain & publicUrl & "/" & LCase( assetId ) );
			}

			// Cloudflare limits prefix purge requests to 30 prefixes per call
			var prefixCount = ArrayLen( prefixes );
			for( var start=1; start<=prefixCount; start+=batchSize ) {
				var batch = ArraySlice( prefixes, start, Min( batchSize, prefixCount - start + 1 ) );
				apiWrapper.purgeCacheByPrefixes( zoneId=zoneId, prefixes=batch );
			}
		}
	}

	/**
	 * Purges Cloudflare cache for all assets in a folder by delegating to #clearAssetCache.
	 * No-op when the cachePurge API token is not configured or folderId is empty.
	 *
	 * @param folderId Preside asset folder id whose assets should be purged
	 */
	public void function clearFolderCache( required string folderId ) {
		if ( !isConfigured( "cachePurge" ) || !Len( arguments.folderId ) ) {
			return;
		}

		var assets = $getPresideObject( "asset" ).selectData(
			  filter       = { asset_folder=arguments.folderId }
			, selectFields = [ "id" ]
		);

		clearAssetCache( assetIds=ValueArray( assets.id ) );
	}

	/**
	 * Indicates whether a named Cloudflare API token is present in application settings.
	 *
	 * @param tokenName key under cloudflare.apiTokens (e.g. cachePurge)
	 * @return true when the token value is non-empty, otherwise false
	 */
	public boolean function isConfigured( required string tokenName ) {
		return Len( apiTokens[ arguments.tokenName ] ?: "" ) ? true : false;
	}


// PRIVATE METHODS
	/**
	 * Inserts or updates the cloudflare_zone row for a domain with zone metadata and not_found flag.
	 *
	 * @param domain   hostname this row describes
	 * @param zoneId   Cloudflare zone id; empty when zone not found
	 * @param zoneName Cloudflare zone name
	 */
	private void function _saveZone( required string domain, string zoneId="", string zoneName="" ) {
		var exists = $getPresideObject( "cloudflare_zone" ).dataExists( filter={ domain=arguments.domain } );
		if ( exists ) {
			$getPresideObject( "cloudflare_zone" ).updateData(
				  filter = { domain=arguments.domain }
				, data   = {
					  zone_id   = arguments.zoneId
					, zone_name = arguments.zoneName
					, not_found = !Len( arguments.zoneId )
				  }
			);
		} else {
			$getPresideObject( "cloudflare_zone" ).insertData( data={
				  domain    = arguments.domain
				, zone_id   = arguments.zoneId
				, zone_name = arguments.zoneName
				, not_found = !Len( arguments.zoneId )
			} );
		}
	}

}