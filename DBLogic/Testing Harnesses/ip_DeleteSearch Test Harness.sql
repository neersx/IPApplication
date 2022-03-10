Declare @nErr int

exec @nErr = dbo.ip_GetSearch
	@pnUserIdentityId	= 1,
	@psCulture		= null,
	@pnSearchId		= null
Select @nErr

exec @nErr = dbo.ip_DeleteSearch
	@pnUserIdentityId	= 1,		-- Mandatory
	@psCulture		= null,  	-- the language in which output is to be expressed
	@pnSearchId		= 2
Select @nErr

exec @nErr = dbo.ip_GetSearch
	@pnUserIdentityId	= 1,
	@psCulture		= null,
	@pnSearchId		= null
Select @nErr