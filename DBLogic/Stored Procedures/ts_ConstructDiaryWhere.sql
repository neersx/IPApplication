-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ts_ConstructDiaryWhere
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ts_ConstructDiaryWhere]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ts_ConstructDiaryWhere.'
	Drop procedure [dbo].[ts_ConstructDiaryWhere]
End
Print '**** Creating Stored Procedure dbo.ts_ConstructDiaryWhere...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ts_ConstructDiaryWhere
(
	@psDiaryWhere			nvarchar(4000)	= null	OUTPUT,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbExternalUser			bit,			-- Mandatory. Flag to indicate if user is external.  Default on as this is the lowest security level
	@pnQueryContextKey		int		= 240, 	-- The key for the context of the query (default output requests).
	@ptXMLFilterCriteria		ntext		= null,	-- The filtering to be performed on the result set.		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	ts_ConstructDiaryWhere
-- VERSION:	14
-- DESCRIPTION:	This stored procedure accepts the variables that may be used to filter Diary information 
--		and constructs a Where clause.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Jun 2005	TM	RFC2575	1	Procedure created
-- 30 Jun 2005	TM	RFC2768	2	Correct the IsIncomplete filter criteria logic.
-- 11 Jul 2005	TM	RFC2768	3	Correct the IsIncomplete and IsContinued filter criteria logic.
-- 18 Nov 2008	MF	SQA17136 4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 30 Nov 2009  NG	RFC8582 5	Extend the filter criteria to get only continuable task. 
-- 02 Feb 2010	LP	RFC8859	6	Sanitise special characters when comparing SHORTNARRATIVE and NOTES fields.
-- 15 Feb 2010	LP	RFC3130	7	Extend to filter by Entity and Responsible Name.
-- 08 Mar 2010  LP      RFC7267 8       Filter by multiple Entry Numbers.
-- 27 Apr 2012	KR	R11414	9	Modified the IsComplete Logic
-- 17 Dec 2012  MS      R12778  10      Correct the IsIncomplete logic
-- 05 Jul 2013	vql	R13629	11	Remove string length restriction and use nvarchar on datetime conversions using 106 format.
-- 23 May 2018	MF	74200	12	Extend filter to allow the DIARY entry to be filtered by ACTIVITY (WIPCode).
-- 31 Oct 2018	DL	DR-45102	13	Replace control character (word hyphen) with normal sql editor hyphen
-- 14 Nov 2018  AV  75198/DR-45358	14   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode				int

Declare @sSQLString				nvarchar(4000)

Declare @sLookupCulture				nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Declare Filter Variables
Declare @nStaffKey 				int		-- The staff member whose time is to be returned.
Declare @nStaffKeyOperator			tinyint		
Declare @bIsCurrentUser				bit		-- Indicates that the StaffKey should be derived from @pnUserIdentityId.
Declare @sWIPCodes				nvarchar(max)	-- A comma-separated list of WIP Codes.
Declare @nWIPCodesOperator			tinyint
Declare @nEntryNo				int		-- The identifier for a particular row of a Staff member's time. StaffKey and EntryNo together uniquely identify a time entry.
Declare @nEntryNoOperator			tinyint
Declare @sEntryNumbers                          nvarchar(max)   -- A comma-separated list of Entry Numbers
		
Declare @nDateRangeOperator			tinyint		-- Return entries with the date portion of their StartTime between these dates. From and/or To value must be provided.
Declare @dtDateRangeFrom			datetime	
Declare @dtDateRangeTo				datetime		
Declare @nPeriodRangeOperator			tinyint		-- A period range is converted to a date range by subtracting the from/to period from the current date. Returns the entries with dates in the past over the resulting date range.
Declare @sPeriodRangeType			nvarchar(2)	-- D - Days, W - Weeks, M - Months, Y - Years.
Declare @nPeriodRangeFrom			smallint	-- Must be zero or above. Always supplied in conjunction with Type.
Declare @nPeriodRangeTo				smallint	-- Must be zero or above. Always supplied in conjunction with Type.

-- Entry Type
Declare @bIsUnposted				bit		-- Indicates that rows that are available for posting should be returned.
Declare @bIsContinued				bit		-- Indicates that rows that contribute to a continued chain, but do not represent the final total row should be returned.
Declare @bIsIncomplete				bit		-- Indicates that entered rows that are missing details should be returned.
Declare @bIsPosted				bit		-- Indicates that rows that have been posted to the Work In Progress ledger should be returned.
Declare @bIsTimer				bit		-- Indicates that rows that entries that have been started but are unfinished should be returned.

Declare @sActivityKey				nvarchar(6)
Declare @nActivityOperator			tinyint
Declare @nCaseKey				int
Declare @nCaseOperator				tinyint
Declare @sNarrative				nvarchar(254)
Declare	@sNotes					nvarchar(254)
Declare	@bGetContinuableTaskOnly		bit
Declare @nNameKey				int
Declare @nNameOperator				tinyint
Declare @nEntityKey				int
Declare @nEntityOperator			tinyint

Declare @nCount					int		-- Current table row being processed.
Declare @sSelect				nvarchar(4000)
Declare @sFrom					nvarchar(4000)
Declare @sWhere					nvarchar(4000)
Declare @sOrder					nvarchar(4000)

Declare @idoc 					int 		-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.		
		
-- Declare some constants
Declare @String					nchar(1)
Declare @Date					nchar(2)
Declare @Numeric				nchar(1)
Declare @Text					nchar(1)
Declare @CommaString				nchar(2)	-- New DataType(CS) to indicate a Comma Delimited String.
Declare @sOr					nchar(4)

Set	@String 				='S'
Set	@Date   				='DT'
Set	@Numeric				='N'
Set	@Text   				='T'
Set	@CommaString				='CS'

-- Initialise variables
Set 	@nErrorCode = 0
set 	@sFrom					= char(10)+"From DIARY XD"
set 	@sWhere 				= char(10)+"	WHERE 1=1"


-- If filter criteria was passed, extract details from the XML
If (datalength(@ptXMLFilterCriteria) > 0)
and @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
		
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLFilterCriteria

	-- 1) Retrieve the AnySearch element using element-centric mapping (implement 
	--    Case Insensitive searching)   
	Set @sSQLString = 	
	"Select @nStaffKey			= StaffKey,"+CHAR(10)+
	"	@nStaffKeyOperator		= StaffKeyOperator,"+CHAR(10)+
	"	@bIsCurrentUser			= IsCurrentUser,"+CHAR(10)+
	"	@sWIPCodes			= WIPCodes,"+CHAR(10)+
	"	@nWIPCodesOperator		= WIPCodesOperator,"+CHAR(10)+
	"	@nEntryNo			= EntryNo,"+CHAR(10)+
	"	@nEntryNoOperator		= EntryNoOperator,"+CHAR(10)+	
	"	@sEntryNumbers			= EntryNumbers,"+CHAR(10)+			
	"	@nDateRangeOperator		= DateRangeOperator,"+CHAR(10)+
	"	@dtDateRangeFrom		= DateRangeFrom,"+CHAR(10)+
	"	@dtDateRangeTo			= DateRangeTo,"+CHAR(10)+
	"	@nPeriodRangeOperator		= PeriodRangeOperator,"+CHAR(10)+
	"	@sPeriodRangeType		= CASE  WHEN PeriodRangeType='D' THEN 'dd'"+CHAR(10)+
						       "WHEN PeriodRangeType='W' THEN 'wk'"+CHAR(10)+
						       "WHEN PeriodRangeType='M' THEN 'mm'"+CHAR(10)+
						       "WHEN PeriodRangeType='Y' THEN 'yy'"+CHAR(10)+
					          "END,"+CHAR(10)+
	"	@nPeriodRangeFrom		= -PeriodRangeFrom,"+CHAR(10)+
	"	@nPeriodRangeTo			= -PeriodRangeTo,"+CHAR(10)+
	"	@bIsUnposted			= IsUnposted,"+CHAR(10)+
	"	@bIsContinued			= IsContinued,"+CHAR(10)+
	"	@bIsIncomplete			= IsIncomplete,"+CHAR(10)+
	"	@bIsPosted			= IsPosted,"+CHAR(10)+
	"	@bIsTimer			= IsTimer,"+CHAR(10)+
	"	@sActivityKey			= ActivityKey,"+CHAR(10)+
	"	@nActivityOperator		= ISNULL(ActivityOperator,0),"+CHAR(10)+
	"	@nCaseKey			= CaseKey,"+CHAR(10)+
	"	@nCaseOperator			= ISNULL(CaseOperator,0),"+CHAR(10)+
	"	@sNarrative			= Narrative,"+CHAR(10)+
	"	@sNotes				= Notes,"+CHAR(10)+
	"	@nNameKey			= NameKey,"+CHAR(10)+
	"	@nNameOperator			= ISNULL(NameOperator,0),"+CHAR(10)+
	"	@nEntityKey			= EntityKey,"+CHAR(10)+
	"	@nEntityOperator		= ISNULL(EntityOperator,0),"+CHAR(10)+
	"	@bGetContinuableTaskOnly	= GetContinuableTaskOnly"+CHAR(10)+
	"from	OPENXML (@idoc, '//ts_ListDiary/FilterCriteria',2)"+CHAR(10)+
	"	WITH ("+CHAR(10)+
	"	      StaffKey			int		'StaffKey/text()',"+CHAR(10)+
	"	      StaffKeyOperator		tinyint		'StaffKey/@Operator/text()',"+CHAR(10)+
	"	      IsCurrentUser		bit		'StaffKey/@IsCurrentUser/text()',"+CHAR(10)+	
	"	      WIPCodes			nvarchar(1000)	'WIPCodes/text()',"+CHAR(10)+
	"	      WIPCodesOperator		tinyint		'WIPCodes/@Operator/text()',"+CHAR(10)+	
	"	      EntryNo			int		'EntryNo/text()',"+CHAR(10)+
 	"	      EntryNoOperator		tinyint		'EntryNo/@Operator/text()',"+CHAR(10)+	
 	"	      EntryNumbers		nvarchar(max)	'EntryNumbers/text()',"+CHAR(10)+
	"	      DateRangeOperator		tinyint		'EntryDate/DateRange/@Operator/text()',"+CHAR(10)+	
	"	      DateRangeFrom		datetime	'EntryDate/DateRange/From/text()',"+CHAR(10)+	
	"	      DateRangeTo		datetime	'EntryDate/DateRange/To/text()',"+CHAR(10)+	
	"	      PeriodRangeOperator	tinyint		'EntryDate/PeriodRange/@Operator/text()',"+CHAR(10)+	
	"	      PeriodRangeType		nvarchar(2)	'EntryDate/PeriodRange/Type/text()',"+CHAR(10)+	
	"	      PeriodRangeFrom		smallint	'EntryDate/PeriodRange/From/text()',"+CHAR(10)+	
	"	      PeriodRangeTo		smallint	'EntryDate/PeriodRange/To/text()',"+CHAR(10)+	
	"	      IsUnposted		bit		'EntryType/IsUnposted/text()',"+CHAR(10)+	
	"	      IsContinued		bit		'EntryType/IsContinued/text()',"+CHAR(10)+	
	"	      IsIncomplete		bit		'EntryType/IsIncomplete/text()',"+CHAR(10)+	
	"	      IsPosted			bit		'EntryType/IsPosted/text()',"+CHAR(10)+	
	"	      IsTimer			bit		'EntryType/IsTimer/text()',"+CHAR(10)+
	"	      ActivityKey		nvarchar(6)	'ActivityKey/text()',"+CHAR(10)+
	"	      ActivityOperator		tinyint		'ActivityKey/@Operator/text()',"+CHAR(10)+
	"	      CaseKey			int		'CaseKey/text()',"+CHAR(10)+
	"	      CaseOperator		tinyint		'CaseKey/@Operator/text()',"+CHAR(10)+
	"	      NameKey			int		'NameKey/text()',"+CHAR(10)+
	"	      NameOperator		tinyint		'NameKey/@Operator/text()',"+CHAR(10)+
	"	      EntityKey			int		'EntityKey/text()',"+CHAR(10)+
	"	      EntityOperator		tinyint		'EntityKey/@Operator/text()',"+CHAR(10)+
	"	      Narrative			nvarchar(254)	'Narrative/text()',"+CHAR(10)+
	"	      Notes			nvarchar(254)	'Notes/text()',"+CHAR(10)+	
	"	      GetContinuableTaskOnly	bit		'GetContinuableTaskOnly/text()'"+CHAR(10)+	
     	"     		)"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@idoc				int,
				  @nStaffKey 			int			output,
				  @nStaffKeyOperator		tinyint			output,
				  @bIsCurrentUser		bit			output,
				  @sWIPCodes			nvarchar(max)		output,
				  @nWIPCodesOperator		tinyint			output,
				  @nEntryNo			int			output,	
				  @nEntryNoOperator		tinyint			output,	
				  @sEntryNumbers		nvarchar(max)           output,			
				  @nDateRangeOperator		tinyint			output,
				  @dtDateRangeFrom		datetime		output,		
				  @dtDateRangeTo		datetime		output,		
				  @nPeriodRangeOperator		tinyint			output,		
				  @sPeriodRangeType		nvarchar(2)		output,		
				  @nPeriodRangeFrom		smallint		output,
				  @nPeriodRangeTo		smallint		output,
				  @bIsUnposted			bit			output,
				  @bIsContinued			bit			output,
				  @bIsIncomplete		bit			output,
				  @bIsPosted			bit			output,
				  @bIsTimer			bit			output,
				  @sActivityKey			nvarchar(6)		output,
				  @nActivityOperator		tinyint			output,
				  @nCaseKey			int			output,
				  @nCaseOperator		tinyint			output,
				  @nNameKey			int			output,
				  @nNameOperator		tinyint			output,
				  @nEntityKey			int			output,
				  @nEntityOperator		tinyint			output,
				  @sNarrative			nvarchar(254)		output,
				  @sNotes			nvarchar(254)		output,
				  @bGetContinuableTaskOnly	bit			output',
				  @idoc				= @idoc,
				  @nStaffKey 			= @nStaffKey		output,
				  @nStaffKeyOperator		= @nStaffKeyOperator	output,
				  @bIsCurrentUser		= @bIsCurrentUser	output,
				  @sWIPCodes			= @sWIPCodes		output,
				  @nWIPCodesOperator		= @nWIPCodesOperator	output,
				  @nEntryNo			= @nEntryNo		output,
				  @nEntryNoOperator		= @nEntryNoOperator	output,				
				  @sEntryNumbers		= @sEntryNumbers	output,
				  @nDateRangeOperator		= @nDateRangeOperator	output,
				  @dtDateRangeFrom 		= @dtDateRangeFrom	output,
				  @dtDateRangeTo		= @dtDateRangeTo	output,
				  @nPeriodRangeOperator		= @nPeriodRangeOperator	output,
				  @sPeriodRangeType		= @sPeriodRangeType	output,
				  @nPeriodRangeFrom		= @nPeriodRangeFrom	output,
				  @nPeriodRangeTo		= @nPeriodRangeTo	output,
				  @bIsUnposted			= @bIsUnposted		output,
				  @bIsContinued			= @bIsContinued		output,
				  @bIsIncomplete		= @bIsIncomplete	output,
				  @bIsPosted			= @bIsPosted		output,
				  @bIsTimer			= @bIsTimer		output,
				  @sActivityKey			= @sActivityKey		output,
				  @nActivityOperator		= @nActivityOperator	output,
				  @nCaseKey			= @nCaseKey		output,
				  @nCaseOperator		= @nCaseOperator	output,
				  @nNameKey			= @nNameKey		output,
				  @nNameOperator		= @nNameOperator	output,
				  @nEntityKey			= @nEntityKey		output,
				  @nEntityOperator		= @nEntityOperator	output,
				  @sNarrative			= @sNarrative		output,
				  @sNotes			= @sNotes		output,
				  @bGetContinuableTaskOnly = @bGetContinuableTaskOnly	output					
				
	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	
	Set @nErrorCode=@@Error

	-- Reduce the number of joins in the main statement.
	If @nErrorCode = 0
	and @bIsCurrentUser = 1
	Begin
		Set @sSQLString = "
		Select  @nStaffKey = U.NAMENO
		from USERIDENTITY U
		where U.IDENTITYID = @pnUserIdentityId"
	
		exec @nErrorCode=sp_executesql @sSQLString,
						      N'@nStaffKey		int		OUTPUT,
							@pnUserIdentityId	int',
							@nStaffKey 		= @nStaffKey 	OUTPUT,
							@pnUserIdentityId	= @pnUserIdentityId						
	End	
		
	If @nStaffKey is not NULL
	or @nStaffKeyOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and XD.EMPLOYEENO " + dbo.fn_ConstructOperator(@nStaffKeyOperator,@Numeric,@nStaffKey, null,0)
	End

	if @sWIPCodes is not NULL
	Begin
		If @nWIPCodesOperator is NULL
			set @nWIPCodesOperator=0

		Set @sWhere = @sWhere+char(10)+"and XD.ACTIVITY " + dbo.fn_ConstructOperator(@nWIPCodesOperator,@CommaString,@sWIPCodes, null,0)
	End

	If @nEntryNo is not NULL
	or @nEntryNoOperator between 2 and 6
	Begin
		Set @sWhere = @sWhere+char(10)+"and XD.ENTRYNO " + dbo.fn_ConstructOperator(@nEntryNoOperator,@Numeric,@nEntryNo, null,0)
	End
	
	If @sEntryNumbers is not NULL
	Begin
		Set @sWhere = @sWhere+char(10)+"and XD.ENTRYNO in (" + @sEntryNumbers + ")"
	End

	If @nErrorCode = 0
	Begin
		-- A period range is converted to a date range by adding the from/to period to the 
		-- current date. 
		If   @sPeriodRangeType is not null
		and (@nPeriodRangeFrom is not null or
		     @nPeriodRangeTo is not null)			 
		Begin
			If @nPeriodRangeFrom is not null
			Begin
				Set @sSQLString = "Set @dtDateRangeFrom = dateadd("+@sPeriodRangeType+", @nPeriodRangeFrom, '" + convert(nvarchar(25),getdate()) + "')"
	
				execute sp_executesql @sSQLString,
						N'@dtDateRangeFrom	datetime 		output,
		 				  @sPeriodRangeType	nvarchar(2),
						  @nPeriodRangeFrom	smallint',
		  				  @dtDateRangeFrom	= @dtDateRangeFrom 	output,
						  @sPeriodRangeType	= @sPeriodRangeType,
						  @nPeriodRangeFrom	= @nPeriodRangeFrom				  
			End
		
			If @nPeriodRangeTo is not null
			Begin
				Set @sSQLString = "Set @dtDateRangeTo = dateadd("+@sPeriodRangeType+", @nPeriodRangeTo, '" + convert(nvarchar(25),getdate()) + "')"
	
				execute sp_executesql @sSQLString,
						N'@dtDateRangeTo	datetime 		output,
		 				  @sPeriodRangeType	nvarchar(2),
						  @nPeriodRangeTo	smallint',
		  				  @dtDateRangeTo	= @dtDateRangeTo 	output,
						  @sPeriodRangeType	= @sPeriodRangeType,
						  @nPeriodRangeTo	= @nPeriodRangeTo				
			End	
		End		
	
		If @dtDateRangeFrom is not null
		or @dtDateRangeTo   is not null
		Begin
			Set @sWhere =  @sWhere+char(10)+"and XD.STARTTIME"+dbo.fn_ConstructOperator(ISNULL(@nDateRangeOperator, @nPeriodRangeOperator),@Date,convert(nvarchar,@dtDateRangeFrom,112), convert(nvarchar,@dtDateRangeTo,112),@pbCalledFromCentura)
		End

		If  @bIsUnposted = 1
		and @bIsContinued = 1
		and @bIsIncomplete = 1
		and @bIsPosted = 1
		and @bIsTimer = 1
		Begin 
			-- No filtering required
			Set @sWhere = @sWhere+char(10)+"and 2=2"
		End
		Else
		If @bIsUnposted = 1
		or @bIsContinued = 1
		or @bIsIncomplete = 1
		or @bIsPosted = 1
		or @bIsTimer = 1
		Begin
			Set @sWhere = @sWhere+char(10)+"and ("
			Set @sOr    = NULL

			If @bIsContinued = 1
			Begin
				Set @sWhere = @sWhere+@sOr+char(10)+"	(XD.STARTTIME is not null and XD.FINISHTIME is not null and XD.TOTALTIME is null and XD.ISTIMER = 0)" 
				Set @sOr    =' OR '
			End
	
			If @bIsIncomplete = 1
			Begin
				If charindex('left join SITECONTROL CSC',@sFrom)=0
				Begin
					Set @sFrom = CHAR(10) + @sFrom 
						   + CHAR(10) + "left join SITECONTROL CSC 	on (CSC.CONTROLID = 'CASEONLY_TIME')"					
				End				

				If charindex('left join SITECONTROL CSC1',@sFrom)=0
				Begin
					Set @sFrom = CHAR(10) + @sFrom 
						   + CHAR(10) + "left join SITECONTROL CSC1 	on (CSC1.CONTROLID = 'Rate mandatory on time items')"					
				End
				
				If charindex('left join DIARY XD1',@sFrom)=0
				Begin
					Set @sFrom = CHAR(10) + @sFrom 
						   + CHAR(10) + "left join DIARY XD1 on (XD1.PARENTENTRYNO = XD.ENTRYNO and XD1.EMPLOYEENO = XD.EMPLOYEENO)"					
				End
				
				Set @sWhere = @sWhere+@sOr+char(10)+" (( isnull(CSC.COLBOOLEAN, 0) = 1 OR XD.NAMENO is null) and XD.CASEID is null) or XD.ACTIVITY is null OR 
									(( XD.TOTALTIME is null or XD.TOTALUNITS is null or XD.TOTALUNITS = 0 or XD.TIMEVALUE is null ) AND (XD1.PARENTENTRYNO is null or XD.ENTRYNO != XD1.PARENTENTRYNO))
									OR (XD.CHARGEOUTRATE is null and isnull(CSC1.COLBOOLEAN,0) = 1)"

				--Set @sWhere = @sWhere+@sOr+char(10)+"(	XD.ISTIMER = 0 and XD.TOTALTIME is not null and ((XD.CASEID is null and XD.NAMENO is null) or (XD.CASEID is null and CSC.COLBOOLEAN = 1)))" 
				Set @sOr    =' OR '
			End
	
			If @bIsPosted = 1
			Begin
				Set @sWhere = @sWhere+@sOr+char(10)+"	XD.TRANSNO is not null" 
				Set @sOr    =' OR '
			End

			If @bIsTimer = 1
			Begin
				Set @sWhere = @sWhere+@sOr+char(10)+"	XD.ISTIMER = 1" 
				Set @sOr    =' OR '
			End	

			-- Any remaining rows
			If @bIsUnposted = 1
			Begin
				Set @sWhere = @sWhere+@sOr
						     +char(10)+"not exists(Select 1"
					     	     +char(10)+"from DIARY XD2"			
						     +char(10)+"left join SITECONTROL CSC1 	on (CSC1.CONTROLID = 'CASEONLY_TIME')"
						     +char(10)+"where (XD2.EMPLOYEENO = XD.EMPLOYEENO and XD2.ENTRYNO = XD.ENTRYNO)"
						     +char(10)+"and ("
						     +char(10)+"(XD2.STARTTIME is not null and XD2.FINISHTIME is not null and XD2.TOTALTIME is null and XD2.ISTIMER = 0)" 
						     +char(10)+"or  (XD.ISTIMER = 0 and XD.TOTALTIME is not null and ((XD2.CASEID is null and XD2.NAMENO is null) or (XD2.CASEID is null and CSC1.COLBOOLEAN = 1)))" 
						     +char(10)+"or  (XD2.TRANSNO is not null)" 
						     +char(10)+"or  (XD2.ISTIMER = 1)))"								
			End

			Set @sWhere = @sWhere+")"
		End

		If @sActivityKey is not null
		or @nActivityOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XD.ACTIVITY" + dbo.fn_ConstructOperator(@nActivityOperator,@String,@sActivityKey, null,0)
		End
		
		If @nCaseKey is not null
		or @nCaseOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XD.CASEID" + dbo.fn_ConstructOperator(@nCaseOperator,@Numeric,@nCaseKey, null,0)
		End
		Else
		Begin
			If @nNameKey is not null
			or @nNameOperator between 2 and 6
			Begin
				Set @sWhere = @sWhere+char(10)+"and XD.NAMENO" + dbo.fn_ConstructOperator(@nNameOperator,@Numeric,@nNameKey, null,0)
			End			
		End
		
		If @nEntityKey is not null
		or @nEntityOperator between 2 and 6
		Begin
			Set @sWhere = @sWhere+char(10)+"and XD.WIPENTITYNO" + dbo.fn_ConstructOperator(@nEntityOperator,@Numeric,@nEntityKey, null,0)
		End

		If @sNarrative is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and dbo.fn_RemoveNoiseCharacters(UPPER(XD.SHORTNARRATIVE)) = '"+dbo.fn_RemoveNoiseCharacters(@sNarrative)+"'"
		End

		If @sNotes is not null
		Begin
			Set @sWhere = @sWhere+char(10)+"and dbo.fn_RemoveNoiseCharacters(UPPER(XD.NOTES)) = '"+dbo.fn_RemoveNoiseCharacters(@sNotes)+"'"
		End
	End

	Set @psDiaryWhere = ltrim(rtrim(@sFrom+char(10)+@sWhere))	
End

Return @nErrorCode
GO

Grant execute on dbo.ts_ConstructDiaryWhere to public
GO
