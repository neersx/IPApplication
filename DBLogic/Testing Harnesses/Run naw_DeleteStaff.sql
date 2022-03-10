exec naw_DeleteStaff
	@pnUserIdentityId			= 26,		-- Mandatory
	@psCulture				= 'en-AU',
	@pbCalledFromCentura			= 0,
	@pnNameKey				= -488,		-- Mandatory
	
	@psOldAbbreviatedName			= N'GB',
	@pnOldStaffClassificationKey		= 2,
	@psOldSignOffTitle			= N'Patent Attorney',
	@psOldSignOffName			= N'George Grey',
	@pdtOldDateCommenced			= N'4/1/1996',
	@pdtOldDateCeased			= N'4/1/1997',
	@pnOldCapacityToSign			= 5,
	@psOldProfitCentreCode			= N'PTCHM',
	@pnOldDefaultPrinterKey			= -1,

	@pbIsAbbreviatedNameInUse		= 1,
	@pbIsStaffClassificationKeyInUse	= 1,
	@pbIsSignOffTitleInUse			= 1,
	@pbIsSignOffNameInUse			= 1,
	@pbIsDateCommencedInUse			= 1,
	@pbIsDateCeasedInUse			= 1,
	@pbIsCapacityToSignInUse		= 1,
	@pbIsProfitCentreCodeInUse		= 1,
	@pbIsDefaultPrinterKeyInUse		= 1

SELECT * FROM EMPLOYEE WHERE EMPLOYEENO = -488
