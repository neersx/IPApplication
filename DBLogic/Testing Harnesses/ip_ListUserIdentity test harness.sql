exec ip_ListUserIdentity
	@psColumnIds = 'IdentityKey^LoginID^IdentityNameKey^DisplayName^NameCode^IsInternalUser^IsExternalUser^IsAdministrator',
	@psPublishColumnNames = 'IdentityKey^LoginID^IdentityNameKey^DisplayName^NameCode^IsInternalUser^IsExternalUser^IsAdministrator',
	@pnUserIdentityId = 18,
--	@pnIdentityKey = 18
--	@psLoginID = 'Demo'
--	@pnNameKey = -283747172
	@pbIsExternalUser = 0,
	@pbIsAdministrator = 1

SELECT * FROM USERIDENTITY
