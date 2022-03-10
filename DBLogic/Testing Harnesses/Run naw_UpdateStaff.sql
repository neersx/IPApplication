exec naw_UpdateStaff
	@pnUserIdentityId			= 26,		-- Mandatory
	@psCulture				= N'en-AU',
	@pbCalledFromCentura			= 0,
	@pnNameKey				= -487,		-- Mandatory
	@psAbbreviatedName			= N'gb',
	@pnStaffClassificationKey		= 3,
	@psSignOffTitle				= N'SOT',
	@psSignOffName				= N'GG',
	@pdtDateCommenced			= N'1/1/2000',
	@pdtDateCeased				= N'1/1/2001',
	@pnCapacityToSign			= 6,
	@psProfitCentreCode			= N'TM',
	@pnDefaultPrinterKey			= -1,

	@psOldAbbreviatedName			= N'GB',
	@pnOldStaffClassificationKey		= 2,
	@psOldSignOffTitle			= N'Patent Attorney',
	@psOldSignOffName			= N'George Grey',
	@pdtOldDateCommenced			= N'4/1/1996',
	@pdtOldDateCeased			= null,
	@pnOldCapacityToSign			= 5,
	@psOldProfitCentreCode			= N'PTCHM',
	@pnOldDefaultPrinterKey			= null,
	
	@pbIsAbbreviatedNameInUse		= 1,
	@pbIsStaffClassificationKeyInUse	= 1,
	@pbIsSignOffTitleInUse			= 1,
	@pbIsSignOffNameInUse			= 1,
	@pbIsDateCommencedInUse			= 1,
	@pbIsDateCeasedInUse			= 1,
	@pbIsCapacityToSignInUse		= 1,
	@pbIsProfitCentreCodeInUse		= 1,
	@pbIsDefaultPrinterKeyInUse		= 1

SELECT * FROM EMPLOYEE WHERE EMPLOYEENO = -487


exec naw_UpdateStaff
	@pnUserIdentityId			= 26,		-- Mandatory
	@psCulture				= N'en-AU',
	@pbCalledFromCentura			= 0,
	@pnNameKey				= -487,		-- Mandatory
	@psAbbreviatedName			= N'GB',
	@pnStaffClassificationKey		= 2,
	@psSignOffTitle				= N'Patent Attorney',
	@psSignOffName				= N'George Grey',
	@pdtDateCommenced			= N'4/1/1996',
	@pdtDateCeased				= null,
	@pnCapacityToSign			= 5,
	@psProfitCentreCode			= N'PTCHM',
	@pnDefaultPrinterKey			= null,

	@psOldAbbreviatedName			= N'gb',
	@pnOldStaffClassificationKey		= 3,
	@psOldSignOffTitle			= N'SOT',
	@psOldSignOffName			= N'GG',
	@pdtOldDateCommenced			= N'1/1/2000',
	@pdtOldDateCeased			= N'1/1/2001',
	@pnOldCapacityToSign			= 6,
	@psOldProfitCentreCode			= N'TM',
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

SELECT * FROM EMPLOYEE WHERE EMPLOYEENO = -487