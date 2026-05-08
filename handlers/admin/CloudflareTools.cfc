component extends="preside.system.base.AdminHandler" {

	property name="cloudflareCacheService" inject="delayedInjector:CloudflareCacheService";

	private void function purgeAssetsInBgThread( event, rc, prc, args={} ) {
		cloudflareCacheService.purgeAssets( assetIds=args.assetIds );
	}

	private void function purgeAssetFolderInBgThread( event, rc, prc, args={} ) {
		cloudflareCacheService.purgeAssetFolder( folderId=args.folderId );
	}
}