component extends="preside.system.base.AdminHandler" {

	property name="cloudflareToolsService" inject="delayedInjector:CloudflareToolsService";

	private void function clearAssetCacheInBgThread( event, rc, prc, args={} ) {
		cloudflareToolsService.clearAssetCache( assetIds=args.assetIds );
	}

	private void function clearFolderCacheInBgThread( event, rc, prc, args={} ) {
		cloudflareToolsService.clearFolderCache( folderId=args.folderId );
	}
}