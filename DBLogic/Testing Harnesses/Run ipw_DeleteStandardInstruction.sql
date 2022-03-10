exec ipw_DeleteStandingInstruction
	@pnUserIdentityId		= 5,		-- Mandatory
	@psCulture			= 'en-AU',
	@pbCalledFromCentura		= 0,
	@pnNameKey			= -493,		-- Mandatory
	@pnSequence			= 0,		-- Mandatory
	@pnCaseKey			= null,
	
	@pnOldCaseKey			= null,
	@pnOldRestrictedToNameKey	= null,
	@pnOldInstructionCode		= null,
	@psOldCountryCode		= null,
	@psOldPropertyTypeCode		= null,
	@pnOldPeriod1Amount		= null,
	@psOldPeriod1Type		= null,
	@pnOldPeriod2Amount		= null,
	@psOldPeriod2Type		= null,
	@pnOldPeriod3Amount		= null,
	@psOldPeriod3Type		= 'M',

	@pbIsCaseKeyInUse		= 0,
	@pbIsRestrictedToNameKeyInUse	= 0,
	@pbIsInstructionCodeInUse	= 0,
	@pbIsCountryCodeInUse		= 0,
	@pbIsPropertyTypeCodeInUse	= 0,
	@pbIsPeriod1AmountInUse		= 0,
	@pbIsPeriod1TypeInUse		= 0,
	@pbIsPeriod2AmountInUse		= 0,
	@pbIsPeriod2TypeInUse		= 0,
	@pbIsPeriod3AmountInUse		= 0,
	@pbIsPeriod3TypeInUse		= 1