Declare @nErr int
exec ip_AddSearch
	@pnUserIdentityId	= 1,
	@psCulture		= null,
	@pbUseAsDefault		= 0,		
	@psDescription		= 'This is a search I saved',
	@psCriteria		= 'X=12',
	@psColumns		= 'CASEID, CASENAME, IRN, ACTUTALLY IN XML!',
	@psSortOrder		= 'CASEID, XML'
Select @nErr

SELECT * FROM SEARCHES