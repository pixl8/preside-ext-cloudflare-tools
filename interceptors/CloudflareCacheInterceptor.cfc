component extends="coldbox.system.Interceptor" {

	property name="cloudflareToolsService" inject="delayedInjector:CloudflareToolsService";

	public void function configure() {}

	public void function onClearAssetDerivatives( required any event, required struct interceptData ) {
		if ( !cloudflareToolsService.isConfigured( "cachePurge" ) ) {
			return;
		}

		var assetIds = arguments.interceptData.assetIds ?: [];

		if ( IsSimpleValue( assetIds ) ) {
			assetIds = Len( assetIds ) ? [ assetIds ] : [];
		}

		var taskId = createTask(
			  event             = "admin.CloudflareTools.clearAssetCacheInBgThread"
			, args              = { assetIds=assetIds }
			, runNow            = true
			, discardOnComplete = true
			, adminOwner        = event.getAdminUserId()
			, title             = translateResource( uri="cloudflareTools:cachePurge.task.title" )
		);
	}

	public void function onClearFolderDerivatives( required any event, required struct interceptData ) {
		if ( !cloudflareToolsService.isConfigured( "cachePurge" ) ) {
			return;
		}

		var folderId = arguments.interceptData.folderId ?: "";
		var taskId   = createTask(
			  event             = "admin.CloudflareTools.clearFolderCacheInBgThread"
			, args              = { folderId=folderId }
			, runNow            = true
			, discardOnComplete = true
			, adminOwner        = event.getAdminUserId()
			, title             = translateResource( uri="cloudflareTools:cachePurge.task.title" )
		);
	}

}