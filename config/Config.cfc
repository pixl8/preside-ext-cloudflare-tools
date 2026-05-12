component {

	public void function configure( required struct config ) {
		var conf     = arguments.config;
		var settings = conf.settings ?: {};

		settings.cloudflare.apiTokens.cachePurge = settings.env.CLOUDFLARE_API_TOKEN_CACHE_PURGE ?: "";

		ArrayAppend( conf.interceptors, { class="app.extensions.preside-ext-cloudflare-tools.interceptors.CloudflareCacheInterceptor", properties={} } );
	}

}