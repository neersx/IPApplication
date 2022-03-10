exec naw_InsertOrganisation
	@pnUserIdentityId		= 26,		-- Mandatory
	@psCulture			= N'EN-AU',
	@pbCalledFromCentura		= 0,
	@pnNameKey			= -487,
	@psRegistrationNo		= N'A.C.N. 487 487 487',
	@psTaxNo			= N'487',
	@psIncorporated			= N'an Australian company incorporated in the state of New South Wales',
	@pnParentNameKey		= 42,
	@pbIsRegistrationNoInUse	= 1,
	@pbIsTaxNoInUse			= 1,
	@pbIsIncorporatedInUse		= 1,
	@pbIsParentNameKeyInUse		= 1

exec naw_FetchOrganisation
	@pnUserIdentityId		= 26,		-- Mandatory
	@psCulture			= N'eN-AU', --ZH-CHS'
	@pbCalledFromCentura		= 0,
	@pnNameKey			= -487		-- Mandatory

exec naw_DeleteOrganisation
	@pnUserIdentityId		= 26,		-- Mandatory
	@psCulture			= 'en-AU',
	@pbCalledFromCentura		= 0,
	@pnNameKey			= -487,		-- Mandatory
	
	@psOldRegistrationNo		= N'A.C.N. 487 487 487',
	@psOldTaxNo			= N'487',
	@psOldIncorporated		= N'an Australian company incorporated in the state of New South Wales',
	@pnOldParentNameKey		= 42,

	@pbIsRegistrationNoInUse	= 1,
	@pbIsTaxNoInUse			= 1,
	@pbIsIncorporatedInUse		= 1,
	@pbIsParentNameKeyInUse		= 1

exec naw_FetchOrganisation
	@pnUserIdentityId		= 26,		-- Mandatory
	@psCulture			= N'eN-AU', --ZH-CHS'
	@pbCalledFromCentura		= 0,
	@pnNameKey			= -487		-- Mandatory

