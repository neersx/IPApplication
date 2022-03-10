exec naw_InsertStaff
	@pnUserIdentityId			= 26,		-- Mandatory
	@psCulture				= N'EN-AU',
	@pbCalledFromCentura			= 0,
	@pnNameKey				= -488,		-- Mandatory.
	@psAbbreviatedName			= N'GB',
	@pnStaffClassificationKey		= 2,
	@psSignOffTitle				= N'Patent Attorney',
	@psSignOffName				= N'George Grey',
	@pdtDateCommenced			= N'4/1/1996',
	@pdtDateCeased				= N'4/1/1997',
	@pnCapacityToSign			= 5,
	@psProfitCentreCode			= N'PTCHM',
	@pnDefaultPrinterKey			= -1,
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

DELETE FROM EMPLOYEE WHERE EMPLOYEENO = -488