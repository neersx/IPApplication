exec naw_UpdateOrganisation
	@pnUserIdentityId			= 26,		-- Mandatory
	@psCulture				= N'en-AU',
	@pbCalledFromCentura			= 0,
	@pnNameKey				= 45,		-- Mandatory
	@psRegistrationNo			= N'Dummy RegistrationNo',
	@psTaxNo				= N'Dummy TaxNo',
	@psIncorporated				= N'Dummy Incorporated',
	@pnParentNameKey			= -492,

	@psOldRegistrationNo			= N'A.C.N. 057 872 776',
	@psOldTaxNo				= null,
	@psOldIncorporated			= N'an Australian company',
	@pnOldParentNameKey			= 42,
	
	@pbIsRegistrationNoInUse		= 1,
	@pbIsTaxNoInUse				= 1,
	@pbIsIncorporatedInUse			= 1,
	@pbIsParentNameKeyInUse			= 1

exec naw_FetchOrganisation
	@pnUserIdentityId		= 26,		-- Mandatory
	@psCulture			= N'EN-AU', --ZH-CHS'
	@pbCalledFromCentura		= 0,
	@pnNameKey			= 45		-- Mandatory

exec naw_UpdateOrganisation
	@pnUserIdentityId			= 26,		-- Mandatory
	@psCulture				= N'en-AU',
	@pbCalledFromCentura			= 0,
	@pnNameKey				= 45,		-- Mandatory
	
	@psRegistrationNo			= N'A.C.N. 057 872 776',
	@psTaxNo				= null,
	@psIncorporated				= N'an Australian company',
	@pnParentNameKey			= 42,

	@psOldRegistrationNo			= N'Dummy RegistrationNo',
	@psOldTaxNo				= N'Dummy TaxNo',
	@psOldIncorporated			= N'Dummy Incorporated',
	@pnOldParentNameKey			= -492,
	
	@pbIsRegistrationNoInUse		= 1,
	@pbIsTaxNoInUse				= 1,
	@pbIsIncorporatedInUse			= 1,
	@pbIsParentNameKeyInUse			= 1

exec naw_FetchOrganisation
	@pnUserIdentityId		= 26,		-- Mandatory
	@psCulture			= N'EN-AU', --ZH-CHS'
	@pbCalledFromCentura		= 0,
	@pnNameKey			= 45		-- Mandatory