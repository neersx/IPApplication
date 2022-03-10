



 ------------------------ TESTING cs_InsertPolicing ---------------

declare @err int
declare @nSeq int


exec @err = dbo.cs_InsertPolicing
	@pnUserIdentityId 	= 1,
	@psCulture		= null,
	@psCaseKey		= '-484',
	@pdtDateEntered		= null, -- will default
	@pnPolicingSeqNo	= @nSeq output,
	@psPolicingName		= null, -- will default
	@psSysGeneratedFlag	= 1, 
	@bOnHoldFlag		= 0,
	@psAction		= 'AL',
	@psEventKey		= '-55', 
	-- I think this is wrong:
	@pdtEventDate		= null,	
	@pnCycle		= null,
	@CriteriaNo		= null,
	@psSQLUser		= null, -- will default
	@pnTypeOfRequest	= null  -- will default

select @nSeq
select @err

select * from POLICING where POLICINGSEQNO = @nSeq