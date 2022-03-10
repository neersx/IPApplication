-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_InsertDebtorStatementRequest
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_InsertDebtorStatementRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_InsertDebtorStatementRequest.'
	Drop procedure [dbo].[acw_InsertDebtorStatementRequest]
End
Print '**** Creating Stored Procedure dbo.acw_InsertDebtorStatementRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_InsertDebtorStatementRequest
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	=NULL,			
	@pbCalledFromCentura		bit		= 0,
	@psRequestId				nvarchar(50),	-- Mandatory
	@pnReportId					int,			-- Mandatory
	@pnPeriod					int,			-- Mandatory
	@pnEntityNo					int,			-- Mandatory
	@pnDebtorNo					int		=NULL,
	@pnSortBy					int    = 0,
	@psFromDebtor				nvarchar(10)	=NULL,
	@psToDebtor					nvarchar(10)	=NULL,
	@pbPrintPositiveBal			bit		= 0,
	@pbPrintNegativeBal			bit		= 0,
	@pbPrintZeroBalance			bit		= 0,
	@pbPrintZeroBalWOAct		bit		= 0,
	@psDebtorRestrictions		NVARCHAR(4000)	= null,
	@pbLocalDebtor			bit = 1,
	@pbForeignDebtor		bit = 1
)
as
-- PROCEDURE:	acw_InsertDebtorStatementRequest
-- VERSION:	3
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to insert into the SUBSCRIPTIONFILTER table, the filter criteria 
--				to be used by Reporting Services when running the Debtors Statement (Item and Movements) 
--				report via a data-driven subscription.
--				The procedure also loads the REPORTRECIPIENT table with the debtors who require the report
--				and the required delivery method for each debtor.
				
-- MODIFICATIONS :
-- Date		Who	Number	Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Oct 2010  Dw	RFC9820	1	Procedure created
-- 12 Jul 2011	DL	SQA19795 2	Specify collate database default for temp table.
-- 28 Mar 2014	MS	R31038	3	Added parameters for debtor restrictions, local and foreign debtors for filter

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString		nvarchar(500)
Declare @sLookupCulture		nvarchar(10)
Declare @sParameterName		nvarchar(128)   -- name of parameter whose value is being stored
Declare @sDataType			nvarchar(1)     -- datatype of parameter
Declare @nColInteger		int			    -- parameter value if integer
Declare @nColDecimal		decimal (12,2)  -- parameter value if decimal
Declare @sColCharacter		nvarchar(256)   -- parameter value if string
Declare @dtColDate			datetime        -- parameter value if date
Declare @nBracket0Days		int			-- first ageing bracket (number of days from base date)
Declare @nBracket1Days		int			-- second ageing bracket (number of days from base date)
Declare @nBracket2Days		int			-- third ageing bracket (number of days from base date)
Declare @nAge0Days			int			-- number of days in the first ageing bracket
Declare @nAge1Days			int			-- number of days in the second ageing bracket
Declare @nAge2Days			int			-- number of days in the third ageing bracket
Declare @dtBaseDate			datetime    -- the base date for calculation of ageing
Declare @dtItemDateTo		datetime    -- restricts report to transactions entered prior to this date

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	If exists (Select 1 from SUBSCRIPTIONFILTER 
			   where REQUESTID = @psRequestId)
	OR exists (Select 1 from REPORTRECIPIENT 
			   where REQUESTID = @psRequestId)
	Begin		
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Cannot insert duplicate report request.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin	
		-- determine the base date and ageing brackets
		If (@nErrorCode =0) and (@pnPeriod is not null)
		Begin
			exec @nErrorCode = dbo.acw_GetAgeingBrackets         
			@pnUserIdentityId,
			@psCulture,
			@pbCalledFromCentura,
			@pnPeriod,
			@dtBaseDate output,
			@nBracket0Days output,
			@nBracket1Days output,
			@nBracket2Days output
		
			Set @nAge0Days = @nBracket0Days
			Set @nAge1Days = (@nBracket1Days - @nBracket0Days)
			Set @nAge2Days = (@nBracket2Days - @nBracket1Days)
			-- report based on period so both these dates will be the same (end of specified period)
			Set @dtItemDateTo = @dtBaseDate
		End
		
		-- store base date as parameter
		If (@nErrorCode =0) and (@dtBaseDate is not null)
		Begin
			Set	@sParameterName     = 'pdtBaseDate'
			Set	@sDataType		    = 'T'
			Set @nColInteger		= NULL
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= @dtBaseDate
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store Item Date To as parameter
		if (@nErrorCode =0) and (@dtItemDateTo is not null)
		Begin
			Set	@sParameterName     = 'pdtItemDateTo'
			Set	@sDataType		    = 'T'
			Set @nColInteger		= NULL
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= @dtItemDateTo
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store @nAge0Days as parameter
		if (@nErrorCode =0) and (@nAge0Days is not null)
		Begin
			Set	@sParameterName     = 'pnAge0Days'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @nAge0Days
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store @nAge1Days as parameter
		If (@nErrorCode =0) and (@nAge1Days is not null)
		Begin
			Set	@sParameterName     = 'pnAge1Days'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @nAge1Days
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store @nAge2Days as parameter
		if (@nErrorCode =0) and (@nAge2Days is not null)
		Begin
			Set	@sParameterName     = 'pnAge2Days'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @nAge2Days
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
				
		-- Store Period as parameter
		If (@nErrorCode =0) and (@pnPeriod is not null)
		Begin
			Set	@sParameterName     = 'pnPeriod'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @pnPeriod
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store Entity as parameter
		if (@nErrorCode =0) and (@pnEntityNo is not null)
		Begin
			Set	@sParameterName     = 'pnEntityNo'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @pnEntityNo
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store Debtor as parameter
		if (@nErrorCode =0) and (@pnDebtorNo is not null)
		Begin
			Set	@sParameterName     = 'pnDebtorNo'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @pnDebtorNo
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store Sort By as parameter
		if (@nErrorCode =0) and (@pnSortBy is not null)
		Begin
			Set	@sParameterName     = 'pnSortBy'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @pnSortBy
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store 'From Debtor Code' as parameter
		if (@nErrorCode =0) and (@psFromDebtor is not null)
		Begin
			Set	@sParameterName     = 'psFromDebtor'
			Set	@sDataType		    = 'C'
			Set @nColInteger		= NULL
			Set @nColDecimal		= NULL
			Set @sColCharacter		= @psFromDebtor
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store 'To Debtor Code' as parameter
		if (@nErrorCode =0) and (@psToDebtor is not null)
		Begin
			Set	@sParameterName     = 'psToDebtor'
			Set	@sDataType		    = 'C'
			Set @nColInteger		= NULL
			Set @nColDecimal		= NULL
			Set @sColCharacter		= @psToDebtor
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store Positive Balance flag as parameter
		if (@nErrorCode =0) and (@pbPrintPositiveBal is not null)
		Begin
			Set	@sParameterName     = 'pbPrintPositiveBal'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @pbPrintPositiveBal
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store Negative Balance flag as parameter
		if (@nErrorCode =0) and (@pbPrintNegativeBal is not null)
		Begin
			Set	@sParameterName     = 'pbPrintNegativeBal'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @pbPrintNegativeBal
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store 'Zero Balance with accounting activity flag' as parameter
		if (@nErrorCode =0) and (@pbPrintZeroBalance is not null)
		Begin
			Set	@sParameterName     = 'pbPrintZeroBalance'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @pbPrintZeroBalance
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End
		
		-- Store 'Zero Balance with no accounting activity flag' as parameter
		if (@nErrorCode =0) and (@pbPrintZeroBalWOAct is not null)
		Begin
			Set	@sParameterName     = 'pbPrintZeroBalWOAct'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @pbPrintZeroBalWOAct
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId				int,
						@sParameterName			nvarchar(128), 
						@sDataType				nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate				datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 			= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 			= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate				= @dtColDate	
		End

		-- Store 'Local Debtor' as parameter
		if (@nErrorCode =0) and (@pbLocalDebtor is not null)
		Begin
			Set	@sParameterName     = 'pbLocalDebtor'
			Set	@sDataType		    = 'I'
			Set @nColInteger		= @pbLocalDebtor
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId			int,
						@sParameterName			nvarchar(128), 
						@sDataType			nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate			datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 		= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 		= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate			= @dtColDate	
		End

		-- Store 'Foreign Debtor' as parameter
		if (@nErrorCode =0) and (@pbForeignDebtor is not null)
		Begin
			Set @sParameterName		= 'pbForeignDebtor'
			Set @sDataType			= 'I'
			Set @nColInteger		= @pbForeignDebtor
			Set @nColDecimal		= NULL
			Set @sColCharacter		= NULL
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId			int,
						@sParameterName			nvarchar(128), 
						@sDataType			nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate			datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 		= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 		= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate			= @dtColDate	
		End

		-- Store 'Debtor Restriction' as parameter
		if (@nErrorCode =0) and (@psDebtorRestrictions is not null)
		Begin
			Set @sParameterName		= 'psDebtorRestrictions'
			Set @sDataType			= 'C'
			Set @nColInteger		= NULL
			Set @nColDecimal		= NULL
			Set @sColCharacter		= @psDebtorRestrictions
			Set @dtColDate			= NULL
			
			Set @sSQLString = "
				Insert into SUBSCRIPTIONFILTER 
					(REQUESTID, REPORTID, PARAMETERNAME, DATATYPE,
					COLINTEGER, COLDECIMAL, COLCHARACTER, COLDATE)
				values 
					(@psRequestId, @pnReportId, @sParameterName, @sDataType, 
					@nColInteger, @nColDecimal, @sColCharacter, @dtColDate)"
		
			exec @nErrorCode=sp_executesql @sSQLString,
						N'@psRequestId			nvarchar(50),
						@pnReportId			int,
						@sParameterName			nvarchar(128), 
						@sDataType			nvarchar(1),
						@nColInteger			int, 
						@nColDecimal			decimal (12,2), 
						@sColCharacter			nvarchar(256),
						@dtColDate			datetime',					
						@psRequestId	 		= @psRequestId,
						@pnReportId	 		= @pnReportId,
						@sParameterName	 		= @sParameterName,
						@sDataType	 		= @sDataType,
						@nColInteger	 		= @nColInteger,
						@nColDecimal	 		= @nColDecimal,
						@sColCharacter	 		= @sColCharacter,
						@dtColDate			= @dtColDate	
		End
		

		-- determine which debtors will be included in the report and store then in the REPORTRECIPIENT table
		
		If  exists (select * from sys.objects where object_id = OBJECT_ID(N'[dbo].#DEBTORSTATEMENT') AND type in (N'U'))       
		Begin
			Drop table [dbo].#DEBTORSTATEMENT
		End

		if (@nErrorCode =0)
		Begin
		
			create table #DEBTORSTATEMENT          
			(MAILINGLABEL varchar(254) collate database_default NULL,        
			ACCTENTITYNO   INT NULL ,     
			NAMECODE   varchar(10) collate database_default NULL,     
			ACCTDEBTORNO   INT NULL,     
			CURRENCY   varchar(3)  collate database_default NULL,     
			CURRENCYDESCRIPTION  varchar(40)  collate database_default NULL,     
			ITEMDATE   DATETIME NULL,     
			ITEMNO    varchar(12)  collate database_default NULL,    
			ITEMDESCRIPTION  varchar(254)  collate database_default,     
			OPENINGBALANCE   decimal(11,2),    
			CLOSINGBALANCE   decimal(11,2) ,     
			TRANSDATE   DATETIME      NULL,    
			TRANSNO   INT       NULL,     
			TRANSDESCRIPTION  varchar(254)  collate database_default NULL,     
			TRANSAMOUNT   decimal(11,2)     NULL,       
			AGE0    decimal(11,2),     
			AGE1    decimal(11,2),     
			AGE2    decimal(11,2),     
			AGE3    decimal(11,2),     
			UNALLOCATEDCASH  decimal(11,2),         
			TOTALPAYMENTS decimal(11,2),    
			NAMECATEGORY  NVARCHAR(80)  collate database_default,    
			TRADINGTERMS  INT,    
			ITEMDUEDATE  DATETIME)     

			-- run the report sp and load the data into a temporary table
			insert   into #DEBTORSTATEMENT        
			exec @nErrorCode = dbo.arb_OpenItemStatement         
			@pnPeriod,        
			@dtBaseDate,           
			@dtItemDateTo,           
			@nAge0Days,          
			@nAge1Days,          
			@nAge2Days,    
			@pnEntityNo,         
			@pbPrintZeroBalance,        
			@pnDebtorNo,          
			@psFromDebtor,          
			@psToDebtor,          
			@pbPrintPositiveBal,        
			@pbPrintNegativeBal,        
			@pbPrintZeroBalWOAct,        
			@pnSortBy,
			@psDebtorRestrictions,
			@pbLocalDebtor,
			@pbForeignDebtor
		End        


		-- determine the debtors based on the report data and load REPORTRECIPIENT table
		-- if there is no specified delivery method then default to 'Print'
		if (@nErrorCode =0)
		Begin			
			
			Insert into REPORTRECIPIENT 
			(NAMENO, REQUESTID, REPORTID, DELIVERYMETHOD)
			Select distinct	DS.ACCTDEBTORNO, @psRequestId, @pnReportId, isnull(TA.TABLECODE, -42846977)
			From #DEBTORSTATEMENT DS
			left join TABLEATTRIBUTES TA on (TA.GENERICKEY = DS.ACCTDEBTORNO
											AND TA.PARENTTABLE = 'NAME'
											AND TA.TABLETYPE = -505)
			-- exclude debtors with Report Delivery Method = 'None'								
			where (TA.TABLECODE != -42846978) OR (TA.TABLECODE is null)				
				
		End

		Drop table [dbo].#DEBTORSTATEMENT
	End
End


Return @nErrorCode
go

Grant exec on dbo.acw_InsertDebtorStatementRequest to Public
go