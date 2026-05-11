component extends="coldbox.system.Interceptor" {

	property name="cloudflareCacheService" inject="delayedInjector:CloudflareCacheService";

	public void function configure() {}

	public void function onClearAssetDerivatives( required any event, required struct interceptData ) {
		if ( !cloudflareCacheService.isConfigured( "cachePurge" ) ) {
			return;
		}

		var assetIds = arguments.interceptData.assetIds ?: [];

		if ( IsSimpleValue( assetIds ) ) {
			assetIds = Len( assetIds ) ? [ assetIds ] : [];
		}

		createTask(
			  event             = "admin.CloudflareTools.purgeAssetsInBgThread"
			, args              = { assetIds=assetIds }
			, runNow            = true
			, discardOnComplete = true
			, adminOwner        = event.getAdminUserId()
			, title             = translateResource( uri="cloudflareTools:cachePurge.task.title" )
		);
	}

	public void function onClearFolderDerivatives( required any event, required struct interceptData ) {
		if ( !cloudflareCacheService.isConfigured( "cachePurge" ) ) {
			return;
		}

		var folderId = arguments.interceptData.folderId ?: "";

		createTask(
			  event             = "admin.CloudflareTools.purgeAssetFolderInBgThread"
			, args              = { folderId=folderId }
			, runNow            = true
			, discardOnComplete = true
			, adminOwner        = event.getAdminUserId()
			, title             = translateResource( uri="cloudflareTools:cachePurge.task.title" )
		);
	}

}