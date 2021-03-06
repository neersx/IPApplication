exec ipw_InsertStandingInstruction
	@pnUserIdentityId		= 5,		-- Mandatory
	@psCulture			= 'EN-AU', --ZH-CHS'
	@pbCalledFromCentura		= 0,
	@pnNameKey			= -496,		-- Mandatory
	@pnSequence			= null,
	@pnCaseKey			= null,--487,126(No CaseName with NameType of Instruction),
	@pnRestrictedToNameKey		= null,
	@pnInstructionCode		= 10,
	@psCountryCode			= null,
	@psPropertyTypeCode		= null,
	@pnPeriod1Amount		= null,
	@psPeriod1Type			= null,
	@pnPeriod2Amount		= null,
	@psPeriod2Type			= null,
	@pnPeriod3Amount		= null,
	@psPeriod3Type			= null,
	@pbIsCaseKeyInUse		= 1,
	@pbIsRestrictedToNameKeyInUse	= 0,
	@pbIsInstructionCodeInUse	= 0,
	@pbIsCountryCodeInUse		= 0,
	@pbIsPropertyTypeCodeInUse	= 0,
	@pbIsPeriod1AmountInUse		= 0,
	@pbIsPeriod1TypeInUse		= 0,
	@pbIsPeriod2AmountInUse		= 0,
	@pbIsPeriod2TypeInUse		= 0,
	@pbIsPeriod3AmountInUse		= 0,
	@pbIsPeriod3TypeInUse		= 0