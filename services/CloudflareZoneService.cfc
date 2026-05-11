/**
 * @singleton
 * @presideService
 */
component {

	property name="apiWrapper" inject="CloudflareApiWrapper";

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
		var zone         = {};

		do {
			zone = apiWrapper.getZone( domain=lookupDomain );
			if( Len( zone.id ?: "" ) ) {
				_saveZone( domain=arguments.domain, zoneId=zone.id, zoneName=zone.name );
				return zone.id;
			}
			lookupDomain = ListRest( lookupDomain, "." );
		} while( ListLen( lookupDomain, "." ) > 1 );

		// Save the zone as not found
		_saveZone( domain=arguments.domain );

		return "";
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