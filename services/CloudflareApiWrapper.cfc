/**
 * @singleton
 * @presideService
 */

component {

	property name="apiTokens" inject="coldbox:setting:cloudflare.apiTokens";

	public function init() {
		variables.BASE_URL = "https://api.cloudflare.com/client/v4/";
		return this;
	}

// PUBLIC API

	/**
	 * Looks up a zone by exact DNS name via GET /zones?name=<domain>
	 * Uses the cachePurge API token from application settings.
	 *
	 * @param domain exact zone name (for example the site hostname)
	 * @return the first matching zone as a struct, or an empty struct if none match
	 */
	public struct function getZone( required string domain ) {
		var result = _apiCall(
			  endpoint = "zones"
			, token    = "cachePurge"
			, params   = { name=arguments.domain }
		);

		return result.result[ 1 ] ?: {};
	}

	/**
	 * Looks up a zone by ID via GET /zones/<zone_id>
	 * Uses the cachePurge API token from application settings.
	 *
	 * @return the returned zone data as a struct, or an empty struct if not found
	 */
	public struct function getZoneById( required string zoneId ) {
		var result = _apiCall(
			  endpoint = "zones/#arguments.zoneId#"
			, token    = "cachePurge"
		);

		return result.result ?: {};
	}

	/**
	 * Purges cache for the given zone
	 * Calls POST /zones/<zone_id>/purge_cache with a JSON body
	 *
	 * @param zoneId    Cloudflare zone identifier
	 * @param purgeAll  Purge everything for the given zone
	 * @param files     Full files paths to purge (for example ["http://www.example.com/css/styles.css"] )
	 * @param prefixes  URL path prefixes to purge (for example ["example.com/assets"] )
	 * @return full JSON response struct from the Cloudflare API
	 */
	public struct function purgeCache( required string zoneId, boolean purgeAll=false, array files=[], array prefixes=[] ) {
		var body = {};
		if ( arguments.purgeAll ) {
			body.purge_everything = true;
		} else if ( ArrayLen( arguments.files ) ) {
			body.files = arguments.files;
		} else if ( ArrayLen( arguments.prefixes ) ) {
			body.prefixes = arguments.prefixes;
		}

		if ( StructCount( body ) ) {
			return _apiCall(
				  endpoint = "zones/#arguments.zoneId#/purge_cache"
				, token    = "cachePurge"
				, method   = "POST"
				, body     = body
			);
		}

		return {};
	}


// PRIVATE METHODS

	/**
	 * Performs an authenticated HTTP request to the Cloudflare v4 API and returns the parsed JSON body.
	 * Sends Authorization: Bearer using the token resolved from apiTokens by key name.
	 * Query parameters are appended as URL params; a non-empty body is sent as JSON.
	 *
	 * @param endpoint path segment(s) after the API base URL
	 * @param token    key in cloudflare.apiTokens settings used to select the bearer token
	 * @param method   HTTP verb (default get)
	 * @param params   URL query parameters as a struct
	 * @param body     request body as a struct; serialized to JSON when non-empty
	 * @return deserialized response from result.filecontent
	 */
	private any function _apiCall(
		  required string endpoint
		, required string token
		,          string method = "get"
		,          struct params = {}
		,          struct body   = {}
	) {
		var httpResult = "";
		var apiToken   = _getApiToken( arguments.token );
		var apiUrl     = _buildApiUrl( arguments.endpoint );
		var authHeader = "Bearer #apiToken#";

		try {
			http url=apiUrl method=arguments.method throwonerror=true result="httpResult" {
				httpparam type="header" name="Authorization" value=authHeader;

				for( var param in arguments.params ) {
					httpparam type="url" name="#param#" value=arguments.params[ param ];
				}
				if ( StructCount( arguments.body ) ) {
					httpparam type="header" name="Content-Type" value="application/json";
					httpparam type="body"   value="#SerializeJson( arguments.body )#";
				}
			}

			return DeserializeJson( httpResult.filecontent );
		}
		catch( any e ) {
			$raiseError( e );
		}

		return { success=false, error=e.message };
	}

	/**
	 * Builds an absolute API URL by appending the endpoint to the configured v4 base URL.
	 *
	 * @param endpoint path segment(s) relative to variables.BASE_URL
	 * @return full URL string
	 */
	private string function _buildApiUrl( required string endpoint ) {
		return "#variables.BASE_URL##arguments.endpoint#";
	}

	/**
	 * Resolves a named API token from the injected apiTokens struct.
	 *
	 * @param token setting key (for example cachePurge)
	 * @return the token string, or an empty string if the key does not exist
	 */
	private string function _getApiToken( required string token ) {
		return apiTokens[ arguments.token ] ?: "";
	}

}