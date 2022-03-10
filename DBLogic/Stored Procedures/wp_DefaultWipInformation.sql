-----------------------------------------------------------------------------------------------------------------------------
-- Creation of wp_DefaultWipInformation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[wp_DefaultWipInformation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.wp_DefaultWipInformation.'
	Drop procedure [dbo].[wp_DefaultWipInformation]
End
Print '**** Creating Stored Procedure dbo.wp_DefaultWipInformation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.wp_DefaultWipInformation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	-- The language in which output is to be expressed.
	@psDefaultStaffFrom	nchar(1)	= null, -- Indicates that the staff information should be extracted. The following requests are supported:U - extract the staff information from the current user.
	@pnStaffKey		int		= null,	-- The key of the staff member the WIP is being recorded against.
	@pnCaseKey		int		= null, -- The key of the case selected.
	@pbDefaultWIPTemplate	bit		= null, -- Indicates that the WIP Template should be defaulted if possible.
	@ptWIPTemplateFilter	ntext		= null, -- Filter criteria to be used when extracting the WIP Template default. This is the wp_ListWipTemplate filter XML. Only necessary if @pbDefaultWIPTemplate = 1.
	@psOldWIPTemplateKey	nvarchar(6) 	= null,  -- For an existing entry, this is the WIP Code that is already recorded on the entry (if any).
	@pnDebtorKey			int=null,--The selected Debtor/Instructor(if any).
	@pnProfitCentreStaffKey	int		= null	-- The key of the staff member whose Profit Centre will be use as default
)
as
-- PROCEDURE:	wp_DefaultWipInformation
-- VERSION:	30
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure defaults the fundamental WIP Information such as Staff, Name, Case, 
--		WIP Code and Narrative.  It can be used to extract information for a new entry, 
--		or to extract the new values when the case for an existing entry is modified.

-- MODIFICATIONS :
-- Date			Who	Change		Version	Description
-- -----------	---	----------- -------	----------------------------------------------- 
-- 20 Jun 2005	TM	RFC2575		1		Procedure created
-- 21 Jun 2005	TM	RFC2575		2		Improve efficiency of logic extracting the default WIP Template.
-- 29 Jun 2005	TM	RFC2766		3		Choose action in a similar manner to client/server.
-- 01 Jun 2005	TM	RFC2778		4		Correct the WIPTEmplate extraction logic.
-- 01 Jul 2005	TM	RFC2778		5		Add POLICEEVENTS=1 to the Action selection.
-- 04 Jul 2005	TM	RFC2777		6		Extract the highest best fit score for the narrative similar to the 
--										extraction of the default WIP template. 
-- 05 Jul 2005	TM	RFC2777		7		Correct the Narrative defaulting logic.
-- 06 Jul 2006	SW	RFC4024		8		Remove duplicated best fit filtering logic.
-- 06 Nov 2007	LP	RFC5059		9		Return LocalCurrencyCode in result set.
-- 21 Apr 2008	AT	RFC6415		10		Fix truncation of Case Reference.
-- 15 Dec 2008	MF	17136		11		Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 18 Mar 2008	MS	RFC6478		12		Fetch StaffKey from Case if @psDefaultStaffFrom not equal to 'U' and 
--										fetch Agent of the Case.
-- 16 Dec 2009	KR	RFC8169		13		Get name details for new time entry when the staffkey is not null and @psDefaultStaffFrom is null.  
--										as it is possible to access other staff members time sheet, the timesheet is not just applicable to the logged in user.
-- 11 Mar 2010	MS	RFC7279		14		Add Debtor in the best fit logic for selecting Narrative Rule.
-- 23 Jun 2010	MS	RFC7269		15		Add SeparateMarginFlag in the select list
-- 07 Mar 2011	SF	RFC9871		16		Add FileLocation details
-- 19 May 2011	SF	RFC10651 	17		Add Case Short Title
-- 09 Jun 2011	SF	RFC10543 	18		Add Country, Local Country and Foreign Country in the best fit logic for selecting Narrative Rule.
-- 13 Sep 2011	ASH	R11175 		19		Maintain Narrative Text in foreign languages.
-- 04 Nov 2011	ASH	R11460		20		Cast integer columns as nvarchar(11) data type.     
-- 08 May 2012	AK	RF100583 	21		Add DebtorKey as procedure input parameter to fetch narrative for selected debtor(if any).
-- 06 Dec 2012  MS  R12680		22		Get default Staff and Agent where sequence is lowest in case there are multiple staff members and agents
-- 15 Jan 2013	LP	R11614		23		Return default ProfitCentre
--										Allow ProfitCentre to be defaulted from a specific staff member.
-- 05 Jul 2013	AT	SDR9995		24		Return IsSplitDebtorWip flag.
-- 13 Oct 2014  SS	RFC40053	25		Return default staff details only if IsManualStaff entry site control is not set and @psDefaultStaffFrom is not set to 'U' 
-- 02 Nov 2015	vql	R53910		26		Adjust formatted names logic (DR-15543).
-- 18 Aug 2017	MF	72184		27		The defaulting of the WIP Code for a Case if there are more than 1 possibilities, is to be controlled by a site control.
-- 24 Aug 2017	AK	72173		28		picking value of sitecontrol 'Staff Manual Entry For WIP' from COLINTEGER
-- 30 oct 2018	AK	R74809		29		returns OfficeEntityNo from case office
-- 31 Oct 2018	DL	DR-45102	30	Replace control character (word hyphen) with normal sql editor hyphen


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)

Declare @sWipTemplateWhere	nvarchar(4000)
Declare	@bIsOldWIPTemplateValid	bit 
Declare @nBestFitScore		int
Declare @nBestFitCount		int

Declare @sWIPTemplateKey	nvarchar(6)
Declare @sWIPTemplateDesc	nvarchar(30) 

Declare @sCaseReference		nvarchar(30)
Declare @sCaseShortTitle	nvarchar(256)
	
Declare @nDefaultedStaffKey	int
Declare @sDefaultedStaffCode	nvarchar(10)
Declare @sDefaultedStaffName	nvarchar(254)

Declare @nNameKey		int
Declare @sNameCode		nvarchar(10)
Declare @sName			nvarchar(254)

Declare @nNarrativeKey		int
Declare @bIsTranslateNarrative	bit
Declare @nLanguageKey		int
Declare @sLookupCulture		nvarchar(10)

Declare @sLocalCurrencyCode	nvarchar(3)
Declare @nLocalDecimalPlaces 	tinyint

Declare @nAgentNameKey		int
Declare @sAgentNameCode		nvarchar(10)
Declare @sAgentName		nvarchar(254)

Declare @nDebtorKey		int
Declare @bHasCountryAttributes	bit
Declare @bTreatAsLocal	bit
Declare @bTreatAsForeign	bit
Declare @bSeparateMarginFlag	bit

Declare @bIsSplitDebtorWip bit

Declare @nFileLocationKey int
Declare @sFileLocation	nvarchar(80)

Declare @nWipProfitCentreSource	int
Declare @sProfitCentreCode	nvarchar(6)
Declare @sProfitCentre		nvarchar(50)

Declare @nOfficeEntityNo int

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
Set @bHasCountryAttributes = 0
set @sWIPTemplateKey=@psOldWIPTemplateKey


-- Retrieve Local Currency information
If @nErrorCode=0
Begin
	exec @nErrorCode = ac_GetLocalCurrencyDetails 	@psCurrencyCode		= @sLocalCurrencyCode	OUTPUT,
							@pnDecimalPlaces 	= @nLocalDecimalPlaces	OUTPUT,
							@pnUserIdentityId 	= @pnUserIdentityId,
							@pbCalledFromCentura	= 0
End

If @nErrorCode=0
and Exists (Select * 
	from	TABLEATTRIBUTES TA	
	where	TA.PARENTTABLE = 'COUNTRY' 
	AND	TA.TABLECODE = 5002 
	AND	TA.TABLETYPE = 50)
Begin
	Set @bHasCountryAttributes = 1
End

If (@nErrorCode = 0
	and @pnCaseKey is not null
	and exists(select * from SITECONTROL WHERE CONTROLID = 'WIP Split Multi Debtor' and COLBOOLEAN = 1))
Begin
	Set @bIsSplitDebtorWip = 
				Case When exists(Select * From CASENAME
								Where CASEID = @pnCaseKey
								and NAMETYPE = 'D'
								and BILLPERCENTAGE > 0
								and BILLPERCENTAGE < 100.0
								and (EXPIRYDATE is null or EXPIRYDATE > getdate()))
				Then 1 Else 0 End
End

-- Extract name, staff and case details:
If @nErrorCode = 0
Begin
	Set @sSQLString = "	
	Select  @nDefaultedStaffKey  = CASE WHEN @psDefaultStaffFrom = 'U' THEN UI.NAMENO ELSE NE.NAMENO END,
		@sDefaultedStaffCode = CASE WHEN @psDefaultStaffFrom = 'U' THEN NS.NAMECODE ELSE NE.NAMECODE END,
		@sDefaultedStaffName = CASE WHEN @psDefaultStaffFrom = 'U' THEN dbo.fn_FormatNameUsingNameNo(NS.NAMENO, null) 
					ELSE dbo.fn_FormatNameUsingNameNo(NE.NAMENO, null) END,	
		@nNameKey = N.NAMENO,
		@sNameCode = N.NAMECODE,
		@sName = dbo.fn_FormatNameUsingNameNo(N.NAMENO, null),
		@nAgentNameKey = AN.NAMENO,
		@sAgentNameCode = AN.NAMECODE,
		@sAgentName = dbo.fn_FormatNameUsingNameNo(AN.NAMENO, null),
		@sCaseReference = C.IRN,
		@sCaseShortTitle = C.TITLE,
		@nDebtorKey = DN.NAMENO,
		@bSeparateMarginFlag = ISNULL(IP.SEPARATEMARGINFLAG, 0),
		@bTreatAsLocal =	CASE	WHEN @bHasCountryAttributes = 0 THEN NULL
						WHEN @bHasCountryAttributes = 1 and TA.GENERICKEY IS NOT NULL THEN 1 ELSE 0 END,
		@bTreatAsForeign =	CASE	WHEN @bHasCountryAttributes = 0 THEN NULL
						WHEN @bHasCountryAttributes = 1 and TA.GENERICKEY IS NULL THEN 1 ELSE 0 END,
		@nOfficeEntityNo = COE.NAMENO
	from USERIDENTITY UI 
	join NAME NS			on (NS.NAMENO = UI.NAMENO)
	left join CASES C		on (C.CASEID = @pnCaseKey)
	left join OFFICE CO on (CO.OFFICEID = C.OFFICEID)
	left join SPECIALNAME COE on (COE.NAMENO = CO.ORGNAMENO and COE.ENTITYFLAG = 1)	
	left join CASENAME CN		on (CN.CASEID = C.CASEID
					and CN.NAMETYPE = 'I'
					and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))							
	left join NAME N 		on (N.NAMENO = CN.NAMENO)	
	left join CASENAME CNE		on (CNE.CASEID = C.CASEID
					and CNE.NAMETYPE = 'EMP'
					and (CNE.EXPIRYDATE is null or CNE.EXPIRYDATE>getdate())
					and CNE.SEQUENCE = (select min(SEQUENCE) from CASENAME XCN
					      where XCN.CASEID = @pnCaseKey
					      and XCN.NAMETYPE = 'EMP'
					      and(XCN.EXPIRYDATE is null or XCN.EXPIRYDATE>getdate())))
	left join NAME NE		on (NE.NAMENO = CNE.NAMENO)
        left join CASENAME ACN		on (ACN.CASEID = C.CASEID
					and ACN.NAMETYPE = 'A'
					and (ACN.EXPIRYDATE is null or ACN.EXPIRYDATE>getdate())
					and ACN.SEQUENCE = (select min(SEQUENCE) from CASENAME XCN
					      where XCN.CASEID = @pnCaseKey
					      and XCN.NAMETYPE = 'A'
					      and(XCN.EXPIRYDATE is null or XCN.EXPIRYDATE>getdate())))							
	left join NAME AN 		on (AN.NAMENO = ACN.NAMENO)
	left join CASENAME DCN		on (DCN.CASEID = C.CASEID
					and DCN.NAMETYPE = 'D'
					and (DCN.EXPIRYDATE is null or DCN.EXPIRYDATE>getdate())
					and DCN.SEQUENCE = (select min(SEQUENCE) from CASENAME XCN
					      where XCN.CASEID = @pnCaseKey
					      and XCN.NAMETYPE = 'D'
					      and(XCN.EXPIRYDATE is null or XCN.EXPIRYDATE>getdate())))
        left join NAME DN 		on (DN.NAMENO = DCN.NAMENO)
        left join IPNAME IP		on (IP.NAMENO = DN.NAMENO)
	left join TABLEATTRIBUTES TA	on (TA.PARENTTABLE = 'COUNTRY' 
						and TA.TABLECODE = 5002 
						and TA.TABLETYPE = 50
						and TA.GENERICKEY = C.COUNTRYCODE)
	where UI.IDENTITYID = @pnUserIdentityId"

	exec @nErrorCode = sp_executesql @sSQLString,
						N'@nDefaultedStaffKey 	int			output,
						  @sDefaultedStaffCode	nvarchar(10)		output,
					          @sDefaultedStaffName	nvarchar(254)		output,
						  @nNameKey		int			output,
						  @sNameCode		nvarchar(10)		output,
						  @sName		nvarchar(254)		output,
						  @sCaseReference	nvarchar(30)		output,
						  @sCaseShortTitle	nvarchar(256)		output,
						  @bTreatAsLocal	bit			output,
						  @bTreatAsForeign	bit			output,
						  @nAgentNameKey	int			output,
						  @sAgentNameCode	nvarchar(10)		output,
						  @sAgentName		nvarchar(254)		output,
						  @nDebtorKey		int			output,
						  @bSeparateMarginFlag	bit			output,
						  @nOfficeEntityNo	int output,						 
						  @pnUserIdentityId	int,
						  @pnCaseKey		int,
						  @psDefaultStaffFrom	nchar(1),
						  
						  @bHasCountryAttributes bit',
						  @nDefaultedStaffKey	= @nDefaultedStaffKey	output,
						  @sDefaultedStaffCode	= @sDefaultedStaffCode	output,
						  @sDefaultedStaffName	= @sDefaultedStaffName	output, 
						  @nOfficeEntityNo		= @nOfficeEntityNo		output,						  
						  @nNameKey		= @nNameKey		output,
						  @sNameCode		= @sNameCode		output,
						  @sName		= @sName		output,
						  @sCaseReference	= @sCaseReference	output,
						  @bTreatAsLocal	= @bTreatAsLocal	output,
						  @bTreatAsForeign	= @bTreatAsForeign	output,
						  @sCaseShortTitle	= @sCaseShortTitle	output,
						  @nAgentNameKey	= @nAgentNameKey	output,
						  @sAgentNameCode	= @sAgentNameCode	output,
						  @sAgentName		= @sAgentName		output,
						  @nDebtorKey		= @nDebtorKey		output,
						  @bSeparateMarginFlag	= @bSeparateMarginFlag	output,
						  @pnUserIdentityId	= @pnUserIdentityId,
						  @pnCaseKey		= @pnCaseKey,
						  @psDefaultStaffFrom	= @psDefaultStaffFrom,
						  @bHasCountryAttributes = @bHasCountryAttributes 
End


-- Extract name, staff and case details:
If @nErrorCode = 0 and @psDefaultStaffFrom is null
Begin
	-- Check if manual staff entry option is set
	If (@pnCaseKey is not null and @pnStaffKey is null
		and exists(select * from SITECONTROL WHERE CONTROLID = 'Staff Manual Entry For WIP' and COLINTEGER = 1))
	Begin
		Set @nDefaultedStaffKey = null
		Set @sDefaultedStaffName = null
		Set @sDefaultedStaffCode = null
	End
ELSE 
	Begin
		Set @sSQLString = "	
		Select  @nDefaultedStaffKey  = NAMENO,
			@sDefaultedStaffCode = NAMECODE,
			@sDefaultedStaffName = dbo.fn_FormatNameUsingNameNo(NAMENO, null)
		from NAME 
		where NAMENO = @pnStaffKey"

		exec @nErrorCode = sp_executesql @sSQLString,
							N'@nDefaultedStaffKey 	int			output,
							  @sDefaultedStaffCode	nvarchar(10)		output,
							  @sDefaultedStaffName	nvarchar(254)		output,
							  @pnStaffKey int',
							  @nDefaultedStaffKey	= @nDefaultedStaffKey	output,
							  @sDefaultedStaffCode	= @sDefaultedStaffCode	output,
							  @sDefaultedStaffName	= @sDefaultedStaffName	output,
							  @pnStaffKey   = @pnStaffKey
	End					  
End

-- Extract name from Debtor if Case Key is null
If @nErrorCode = 0 and @pnCaseKey is null and @pnDebtorKey is not null
Begin
	Set @sSQLString = "	
	Select  @nNameKey   = NAMENO,
		@sNameCode = NAMECODE,
		@sName = dbo.fn_FormatNameUsingNameNo(NAMENO, null)
	from NAME 
	where NAMENO = @pnDebtorKey"

	exec @nErrorCode = sp_executesql @sSQLString,
						N'@nNameKey 	int			output,
						  @sNameCode	nvarchar(10)		output,
					      @sName	nvarchar(254)		output,
						  @pnDebtorKey int',
						  @nNameKey	= @nNameKey	output,
						  @sNameCode	= @sNameCode	output,
						  @sName	= @sName	output,
						  @pnDebtorKey   = @pnDebtorKey
End


----------------------------------------
-- Find out if the Site Control to block 
-- defaulting of the WIPTemplate is on
----------------------------------------
If @pbDefaultWIPTemplate = 1
and @pnCaseKey is not null
and @nErrorCode = 0 
and exists(select 1 from SITECONTROL 
	   where CONTROLID = 'WIP Defaulting Suppressed'
	   and COLBOOLEAN  = 1)
Begin
	Set @pbDefaultWIPTemplate = 0
End

----------------------------------------
-- Default the WIP Template if possible:
----------------------------------------
If @pbDefaultWIPTemplate = 1
and @pnCaseKey is not null
and @nErrorCode = 0 
Begin 
	-- Determine whether @psOldWIPTemplateKey is still valid for the context:
	If  @nErrorCode = 0
	and @psOldWIPTemplateKey is not null
	Begin 
		Set @sSQLString = "	
		Select  @sWIPTemplateKey = WIP.WIPCODE,
			@sWIPTemplateDesc = "+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WIP',@sLookupCulture,0)+char(10)+
		"From WIPTEMPLATE WIP
		left join CASES C		on (C.CASEID = @pnCaseKey)
		where 	
		    (	WIP.CASETYPE		= C.CASETYPE		OR WIP.CASETYPE		IS NULL )
		AND (	WIP.COUNTRYCODE 	= C.COUNTRYCODE 	OR WIP.COUNTRYCODE 	IS NULL )
		AND (	WIP.PROPERTYTYPE 	= C.PROPERTYTYPE 	OR WIP.PROPERTYTYPE 	IS NULL )		
		AND (	WIP.ACTION 		in (Select OA.ACTION
						    from OPENACTION OA
						    where OA.CASEID = @pnCaseKey
						    and   OA.POLICEEVENTS = 1)
									OR WIP.ACTION 		IS NULL )
		and WIP.WIPCODE = @psOldWIPTemplateKey"

		exec @nErrorCode = sp_executesql @sSQLString,
							N'@sWIPTemplateKey 		nvarchar(6)			output,
							  @sWIPTemplateDesc		nvarchar(30)			output,
							  @pnCaseKey			int,
							  @psOldWIPTemplateKey		nvarchar(6)',
							  @sWIPTemplateKey		= @sWIPTemplateKey		output,
							  @sWIPTemplateDesc		= @sWIPTemplateDesc		output,	
							  @pnCaseKey			= @pnCaseKey,
							  @psOldWIPTemplateKey		= @psOldWIPTemplateKey
	End
	Else
	-- If there is no @psOldWIPTemplateKey, the processing is to return the best single 
	-- WIPTEMPLATE entry that matches the context. The filter criteria implemented on WIPTEMPLATE 
	-- does not produce a single 'best' entry. Consequently, a WipTemplateKey and corresponding 
	-- WIPTemplateDescription should only be defaulted if there is only a single row with the maximum 
	-- best fit score.  
	If  @nErrorCode = 0
	Begin
		If   @nErrorCode=0
		and (datalength(@ptWIPTemplateFilter) <> 0
		or   datalength(@ptWIPTemplateFilter) is not null)
		Begin
			exec @nErrorCode=dbo.wp_ConstructWipTemplateWhere
						@psWipTemplateWhere	= @sWipTemplateWhere	OUTPUT, 
						@pnUserIdentityId	= @pnUserIdentityId,
						@psCulture		= @psCulture,		
						@ptXMLFilterCriteria	= @ptWIPTemplateFilter	
		End
		
		If @nErrorCode = 0
		Begin	
			--------------------------------------------------
			-- Get the highest best fit score (@nBestFitScore)
			--------------------------------------------------
			Set @sSQLString = "	
			Select 
			@nBestFitScore = 
			max(
			CASE WHEN (WIP.CASETYPE 	IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (WIP.COUNTRYCODE 	IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (WIP.PROPERTYTYPE 	IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (WIP.ACTION  		IS NULL)	THEN '0' ELSE '1' END)
			From WIPTEMPLATE WIP
			where exists (Select 1"
			+@sWipTemplateWhere+
			+char(10)+" and XWIP.WIPCODE = WIP.WIPCODE)"

			exec @nErrorCode = sp_executesql @sSQLString,
							N'@nBestFitScore 	int		output,
							  @pnCaseKey		int',
							  @nBestFitScore	= @nBestFitScore output,
							  @pnCaseKey		= @pnCaseKey

		End	
		
		If @nErrorCode = 0		
		Begin	
			---------------------------------------------------------
			-- Get the number of rows with the highest Best Fit Score
			---------------------------------------------------------
			Set @sSQLString = "
			Select @sWIPTemplateKey = WIPCODE,
			       @sWIPTemplateDesc = "+dbo.fn_SqlTranslatedColumn('WIPTEMPLATE','DESCRIPTION',null,'WIP',@sLookupCulture,0)+char(10)+	
			"from WIPTEMPLATE WIP
			 where 
			CONVERT(int,
			CASE WHEN (WIP.CASETYPE 	IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (WIP.COUNTRYCODE 	IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (WIP.PROPERTYTYPE 	IS NULL)	THEN '0' ELSE '1' END +
			CASE WHEN (WIP.ACTION 		IS NULL)	THEN '0' ELSE '1' END) = @nBestFitScore
			and exists (Select 1"
			+@sWipTemplateWhere+
			+char(10)+" and XWIP.WIPCODE = WIP.WIPCODE)"
	
			exec @nErrorCode = sp_executesql @sSQLString,
							N'@sWIPTemplateKey 	nvarchar(6)	output,
							  @sWIPTemplateDesc	nvarchar(30)	output,
							  @nBestFitScore	int,
							  @pnCaseKey		int',
							  @sWIPTemplateKey	= @sWIPTemplateKey output,
							  @sWIPTemplateDesc	= @sWIPTemplateDesc output,
							  @nBestFitScore	= @nBestFitScore,
							  @pnCaseKey		= @pnCaseKey

			Set @nBestFitCount = @@RowCount
		End	

		If @nErrorCode = 0	
		-- A WipTemplateKey and corresponding WIPTemplateDescription should only be defaulted 
		-- if there is only a single row with the maximum best fit score (i.e. @nBestFitCount = 1),
		-- otherwise set the WIP Template Key and Description to null:
		and  @nBestFitCount > 1
		Begin		
			Set @sWIPTemplateKey = null
			Set @sWIPTemplateDesc = null
		End

	End
End

If  @nErrorCode = 0	
and @pnCaseKey is not null
Begin
-- find the most recent CASE LOCATION for the current case.

	Set @sSQLString = "
	Select  
		@nFileLocationKey = CL.FILELOCATION,
		@sFileLocation = 
				"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'FLD',@sLookupCulture,0)			
								+"			
		from CASELOCATION CL
		left join (	select	CASEID, 
					MAX( convert(nvarchar(24),WHENMOVED, 21)+cast(CASEID as nvarchar(11)) ) as [DATE]
					from CASELOCATION CLMAX
					group by CASEID	
					) LASTMODIFIED	on (LASTMODIFIED.CASEID = @pnCaseKey)
		left join	TABLECODES FLD on (FLD.TABLECODE = CL.FILELOCATION)					
		where CL.CASEID = @pnCaseKey
			and ( (convert(nvarchar(24),CL.WHENMOVED, 21)+cast(CL.CASEID as nvarchar(11))) = LASTMODIFIED.[DATE]
															or LASTMODIFIED.[DATE] is null )
		"
		
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nFileLocationKey 	int				output,
						  @sFileLocation		nvarchar(80)	output,
						  @pnCaseKey			int',
						  @nFileLocationKey		= @nFileLocationKey output,
						  @sFileLocation		= @sFileLocation output,
						  @pnCaseKey			= @pnCaseKey
End

If  @nErrorCode = 0	
and @pnCaseKey is not null
and @sWIPTemplateKey is not null
Begin 
	-- Get the NarrativeKey using best fit score.:
	Set @sSQLString = "
	Select  
	@nNarrativeKey = 
	convert(int,
	substring(
	max (
	CASE WHEN (NRL.DEBTORNO IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.EMPLOYEENO IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.CASETYPE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.COUNTRYCODE IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (NRL.LOCALCOUNTRYFLAG IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.FOREIGNCOUNTRYFLAG IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (NRL.TYPEOFMARK is NULL)	THEN '0' ELSE '1' END +
	CAST(NRL.NARRATIVENO as varchar(5))), 11, 5))
	from NARRATIVERULE NRL
	left join CASES C 		on (C.CASEID = @pnCaseKey)
	where NRL.WIPCODE		= @sWIPTemplateKey" +char(10)+
	CASE WHEN @nDebtorKey is null then " AND NRL.DEBTORNO IS NULL "
		ELSE " AND ( NRL.DEBTORNO = "+ CAST(@nDebtorKey as varchar(11))+ " OR NRL.DEBTORNO IS NULL )" END +char(10)+ 	
	"AND (	NRL.EMPLOYEENO 		= ISNULL(@nDefaultedStaffKey, @pnStaffKey) OR NRL.EMPLOYEENO IS NULL ) 			
	AND (	NRL.CASETYPE		= C.CASETYPE		OR NRL.CASETYPE		is NULL )
	AND (	NRL.COUNTRYCODE		= C.COUNTRYCODE		OR NRL.COUNTRYCODE	is NULL )
	AND (	NRL.LOCALCOUNTRYFLAG	= @bTreatAsLocal	OR NRL.LOCALCOUNTRYFLAG	is NULL )
	AND (	NRL.FOREIGNCOUNTRYFLAG	= @bTreatAsForeign	OR NRL.FOREIGNCOUNTRYFLAG is NULL )
	AND (	NRL.PROPERTYTYPE 	= C.PROPERTYTYPE 	OR NRL.PROPERTYTYPE 	IS NULL )
	AND (	NRL.CASECATEGORY 	= C.CASECATEGORY 	OR NRL.CASECATEGORY 	IS NULL )
	AND (	NRL.SUBTYPE 		= C.SUBTYPE 		OR NRL.SUBTYPE	 	IS NULL )
	AND (	NRL.TYPEOFMARK		= C.TYPEOFMARK		OR NRL.TYPEOFMARK	IS NULL )
	-- As there could be multiple Narrative rules for a WIP Code with the same best fit score, 
	-- a NarrativeKey and other Narrative columns should only be defaulted if there is only 
	-- a single row with the maximum best fit score.
	and not exists (Select 1
			from NARRATIVERULE NRL2
			where   NRL2.WIPCODE		= @sWIPTemplateKey
			AND (	NRL2.DEBTORNO 		= NRL.DEBTORNO		OR (NRL2.DEBTORNO 	IS NULL AND NRL.DEBTORNO 	IS NULL) )
			AND (	NRL2.EMPLOYEENO 	= NRL.EMPLOYEENO	OR (NRL2.EMPLOYEENO 	IS NULL AND NRL.EMPLOYEENO 	IS NULL) )
			AND (	NRL2.CASETYPE		= NRL.CASETYPE		OR (NRL2.CASETYPE 	IS NULL AND NRL.CASETYPE	IS NULL) )
			AND (	NRL2.COUNTRYCODE	= NRL.COUNTRYCODE		OR (NRL2.COUNTRYCODE 		IS NULL AND NRL.COUNTRYCODE		IS NULL) )
			AND (	NRL2.LOCALCOUNTRYFLAG	= NRL.LOCALCOUNTRYFLAG		OR (NRL2.LOCALCOUNTRYFLAG 	IS NULL AND NRL.LOCALCOUNTRYFLAG	IS NULL) )
			AND (	NRL2.FOREIGNCOUNTRYFLAG	= NRL.FOREIGNCOUNTRYFLAG	OR (NRL2.FOREIGNCOUNTRYFLAG 	IS NULL AND NRL.FOREIGNCOUNTRYFLAG	IS NULL) )
			AND (	NRL2.PROPERTYTYPE 	= NRL.PROPERTYTYPE 	OR (NRL2.PROPERTYTYPE 	IS NULL AND NRL.PROPERTYTYPE 	IS NULL) )
			AND (	NRL2.CASECATEGORY 	= NRL.CASECATEGORY 	OR (NRL2.CASECATEGORY 	IS NULL AND NRL.CASECATEGORY 	IS NULL) )
			AND (	NRL2.SUBTYPE 		= NRL.SUBTYPE 		OR (NRL2.SUBTYPE 	IS NULL AND NRL.SUBTYPE	 	IS NULL) )
			AND (	NRL2.TYPEOFMARK		= NRL.TYPEOFMARK	OR (NRL2.TYPEOFMARK	IS NULL AND NRL.TYPEOFMARK	IS NULL) )
			AND NRL2.NARRATIVERULENO <> NRL.NARRATIVERULENO)"

	exec @nErrorCode = sp_executesql @sSQLString,
						N'@nNarrativeKey 	smallint	 output,
						  @pnCaseKey		int,
						  @nNameKey		int,
						  @sWIPTemplateKey	nvarchar(6),
						  @nDefaultedStaffKey	int,
						  @pnStaffKey		int,
						  @nDebtorKey		int,
						  @bTreatAsLocal	bit,
						  @bTreatAsForeign	bit',
						  @nNarrativeKey	= @nNarrativeKey output,
						  @pnCaseKey		= @pnCaseKey,
						  @nNameKey		= @nNameKey,
						  @sWIPTemplateKey	= @sWIPTemplateKey,
						  @nDefaultedStaffKey	= @nDefaultedStaffKey,
						  @pnStaffKey		= @pnStaffKey,
						  @nDebtorKey		= @nDebtorKey,
						  @bTreatAsLocal	= @bTreatAsLocal,
						  @bTreatAsForeign	= @bTreatAsForeign

	-- Find out if the narrative text needs to be translated 
	-- and which language to use:
	If @nNarrativeKey is not null
	Begin		
		Set @sSQLString = "
		Select @bIsTranslateNarrative = COLBOOLEAN
		from SITECONTROL where CONTROLID = 'Narrative Translate'"

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@bIsTranslateNarrative	bit			 OUTPUT',
			  @bIsTranslateNarrative	= @bIsTranslateNarrative OUTPUT

		If   @bIsTranslateNarrative = 1
		Begin
			exec @nErrorCode=dbo.bi_GetBillingLanguage
				@pnLanguageKey		= @nLanguageKey output,	
				@pnUserIdentityId	= @pnUserIdentityId,
				@pnDebtorKey		= @nNameKey,	
				@pnCaseKey		= @pnCaseKey, 
				@pbDeriveAction		= 1					
		End					
	End
End		


If  @nErrorCode = 0	
and @pnCaseKey is null
and @psOldWIPTemplateKey is not null
and @pnDebtorKey is not null
Begin 
	set @nDebtorKey=@pnDebtorKey
	-- Get the NarrativeKey using best fit score.:
	Set @sSQLString = "
	Select  
	@nNarrativeKey = 
	convert(int,
	substring(
	max (
	CASE WHEN (NRL.DEBTORNO IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.EMPLOYEENO IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.CASETYPE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (NRL.TYPEOFMARK is NULL)	THEN '0' ELSE '1' END +
	CAST(NRL.NARRATIVENO as varchar(5))), 8, 5))
	from NARRATIVERULE NRL	
	where NRL.WIPCODE		= @sWIPTemplateKey" +char(10)+
	" AND ( NRL.DEBTORNO = "+ CAST(@nDebtorKey as varchar(11))+ " OR NRL.DEBTORNO IS NULL )"  +char(10)+ 	
	"AND (	NRL.EMPLOYEENO 		= ISNULL(@pnStaffKey, null) OR NRL.EMPLOYEENO IS NULL ) 			
	AND (	NRL.CASETYPE		is NULL )
	AND (	NRL.PROPERTYTYPE 	IS NULL )
	AND (	NRL.CASECATEGORY 	IS NULL )
	AND (	NRL.SUBTYPE	 	IS NULL )
	AND (	NRL.TYPEOFMARK	IS NULL )
	-- As there could be multiple Narrative rules for a WIP Code with the same best fit score, 
	-- a NarrativeKey and other Narrative columns should only be defaulted if there is only 
	-- a single row with the maximum best fit score.
	and not exists (Select 1
			from NARRATIVERULE NRL2
			where   NRL2.WIPCODE		= @sWIPTemplateKey
			AND (	NRL2.DEBTORNO 		= NRL.DEBTORNO		OR (NRL2.DEBTORNO 	IS NULL AND NRL.DEBTORNO 	IS NULL) )
			AND (	NRL2.EMPLOYEENO 	= NRL.EMPLOYEENO	OR (NRL2.EMPLOYEENO 	IS NULL AND NRL.EMPLOYEENO 	IS NULL) )
			AND (	NRL2.CASETYPE		= NRL.CASETYPE		OR (NRL2.CASETYPE 	IS NULL AND NRL.CASETYPE	IS NULL) )
			AND (	NRL2.PROPERTYTYPE 	= NRL.PROPERTYTYPE 	OR (NRL2.PROPERTYTYPE 	IS NULL AND NRL.PROPERTYTYPE 	IS NULL) )
			AND (	NRL2.CASECATEGORY 	= NRL.CASECATEGORY 	OR (NRL2.CASECATEGORY 	IS NULL AND NRL.CASECATEGORY 	IS NULL) )
			AND (	NRL2.SUBTYPE 		= NRL.SUBTYPE 		OR (NRL2.SUBTYPE 	IS NULL AND NRL.SUBTYPE	 	IS NULL) )
			AND (	NRL2.TYPEOFMARK		= NRL.TYPEOFMARK	OR (NRL2.TYPEOFMARK	IS NULL AND NRL.TYPEOFMARK	IS NULL) )
			AND NRL2.NARRATIVERULENO <> NRL.NARRATIVERULENO)"


	exec @nErrorCode = sp_executesql @sSQLString,
						N'@nNarrativeKey 	smallint	 output,
						  @sWIPTemplateKey	nvarchar(6),
						  @pnStaffKey		int,
						  @nDebtorKey		int',
						  @nNarrativeKey	= @nNarrativeKey output,
						  @sWIPTemplateKey	= @sWIPTemplateKey,
						  @pnStaffKey		= @pnStaffKey,
						  @nDebtorKey		= @nDebtorKey					  

	-- Find out if the narrative text needs to be translated 
	-- and which language to use:
	If @nNarrativeKey is not null
	Begin		
		Set @sSQLString = "
		Select @bIsTranslateNarrative = COLBOOLEAN
		from SITECONTROL where CONTROLID = 'Narrative Translate'"

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@bIsTranslateNarrative	bit			 OUTPUT',
			  @bIsTranslateNarrative	= @bIsTranslateNarrative OUTPUT

		If   @bIsTranslateNarrative = 1
		Begin
			exec @nErrorCode=dbo.bi_GetBillingLanguage
				@pnLanguageKey		= @nLanguageKey output,	
				@pnUserIdentityId	= @pnUserIdentityId,
				@pnDebtorKey		= @nNameKey,	
				@pnCaseKey		= @pnCaseKey, 
				@pbDeriveAction		= 1					
		End					
	End
End	


-- Extract narratative when Debtorkey and Casekey  is null and @pnStaffKey is not null
If  @nErrorCode = 0	
and @pnCaseKey is null
and @pnStaffKey is not null
and @nDebtorKey is null
Begin 


	-- Get the NarrativeKey using best fit score.:
	Set @sSQLString = "
	Select  
	@nNarrativeKey = 
	convert(int,
	substring(
	max (
	CASE WHEN (NRL.DEBTORNO IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.EMPLOYEENO IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.CASETYPE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (NRL.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +
	CASE WHEN (NRL.TYPEOFMARK is NULL)	THEN '0' ELSE '1' END +
	CAST(NRL.NARRATIVENO as varchar(5))), 8, 5))
	from NARRATIVERULE NRL	
	where NRL.WIPCODE		= @sWIPTemplateKey" +char(10)+
	 " AND NRL.DEBTORNO IS NULL " +char(10)+ 	
	"AND (	NRL.EMPLOYEENO 		= ISNULL(@pnStaffKey, null) OR NRL.EMPLOYEENO IS NULL ) 			
	AND (	NRL.CASETYPE		is NULL )
	AND (	NRL.PROPERTYTYPE 	IS NULL )
	AND (	NRL.CASECATEGORY 	IS NULL )
	AND (	NRL.SUBTYPE	 	IS NULL )
	AND (	NRL.TYPEOFMARK	IS NULL )
	-- As there could be multiple Narrative rules for a WIP Code with the same best fit score, 
	-- a NarrativeKey and other Narrative columns should only be defaulted if there is only 
	-- a single row with the maximum best fit score.
	and not exists (Select 1
			from NARRATIVERULE NRL2
			where   NRL2.WIPCODE		= @sWIPTemplateKey
			AND (	NRL2.DEBTORNO 		= NRL.DEBTORNO		OR (NRL2.DEBTORNO 	IS NULL AND NRL.DEBTORNO 	IS NULL) )
			AND (	NRL2.EMPLOYEENO 	= NRL.EMPLOYEENO	OR (NRL2.EMPLOYEENO 	IS NULL AND NRL.EMPLOYEENO 	IS NULL) )
			AND (	NRL2.CASETYPE		= NRL.CASETYPE		OR (NRL2.CASETYPE 	IS NULL AND NRL.CASETYPE	IS NULL) )
			AND (	NRL2.PROPERTYTYPE 	= NRL.PROPERTYTYPE 	OR (NRL2.PROPERTYTYPE 	IS NULL AND NRL.PROPERTYTYPE 	IS NULL) )
			AND (	NRL2.CASECATEGORY 	= NRL.CASECATEGORY 	OR (NRL2.CASECATEGORY 	IS NULL AND NRL.CASECATEGORY 	IS NULL) )
			AND (	NRL2.SUBTYPE 		= NRL.SUBTYPE 		OR (NRL2.SUBTYPE 	IS NULL AND NRL.SUBTYPE	 	IS NULL) )
			AND (	NRL2.TYPEOFMARK		= NRL.TYPEOFMARK	OR (NRL2.TYPEOFMARK	IS NULL AND NRL.TYPEOFMARK	IS NULL) )
			AND NRL2.NARRATIVERULENO <> NRL.NARRATIVERULENO)"

						  
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@nNarrativeKey 	smallint	 output,						  
						  @sWIPTemplateKey	nvarchar(6),						  
						  @pnStaffKey		int',						  
						  @nNarrativeKey	= @nNarrativeKey output,						 
						  @sWIPTemplateKey	= @sWIPTemplateKey,						  
						  @pnStaffKey		= @pnStaffKey
						  						  
						  

	-- Find out if the narrative text needs to be translated 
	-- and which language to use:
	If @nNarrativeKey is not null
	Begin		
		Set @sSQLString = "
		Select @bIsTranslateNarrative = COLBOOLEAN
		from SITECONTROL where CONTROLID = 'Narrative Translate'"

		exec @nErrorCode=sp_executesql @sSQLString,
			N'@bIsTranslateNarrative	bit			 OUTPUT',
			  @bIsTranslateNarrative	= @bIsTranslateNarrative OUTPUT

		If   @bIsTranslateNarrative = 1
		Begin
			exec @nErrorCode=dbo.bi_GetBillingLanguage
				@pnLanguageKey		= @nLanguageKey output,	
				@pnUserIdentityId	= @pnUserIdentityId,
				@pnDebtorKey		= @nNameKey,	
				@pnCaseKey		= @pnCaseKey, 
				@pbDeriveAction		= 1					
		End					
	End
End	

-- Retrieve the default Profit Centre
If @nErrorCode = 0
Begin
	Select @nWipProfitCentreSource = COLINTEGER
	from SITECONTROL
	where CONTROLID = 'WIP Profit Centre Source'	
	
	Set @sSQLString = "
	select @sProfitCentreCode = E.PROFITCENTRECODE,
	@sProfitCentre = " + dbo.fn_SqlTranslatedColumn('PROFITCENTRE','DESCRIPTION',null,'P',@sLookupCulture,0) + char(10) +
	"from EMPLOYEE E
	left join PROFITCENTRE P on (P.PROFITCENTRECODE = E.PROFITCENTRECODE)"+char(10)+
	CASE WHEN @nWipProfitCentreSource = 1 THEN 
	"left join USERIDENTITY U on (U.IDENTITYID = @pnUserIdentityId) where E.EMPLOYEENO = isnull(@pnProfitCentreStaffKey, U.NAMENO)" ELSE 
	"where E.EMPLOYEENO = isnull(@pnStaffKey,@nDefaultedStaffKey)" END
	
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@sProfitCentreCode	nvarchar(6) output,
		  @sProfitCentre	nvarchar(50) output,
		  @pnUserIdentityId	int,
		  @pnStaffKey		int,
		  @pnProfitCentreStaffKey int,
		  @nDefaultedStaffKey	int',

		  @sProfitCentreCode	= @sProfitCentreCode output,
		  @sProfitCentre	= @sProfitCentre output,
		  @pnUserIdentityId	= @pnUserIdentityId,
		  @pnStaffKey		= @pnStaffKey,
		  @pnProfitCentreStaffKey = @pnProfitCentreStaffKey,
		  @nDefaultedStaffKey	= @nDefaultedStaffKey

End	

-- Return the result set:
If  @nErrorCode = 0	
Begin
	Set @sSQLString = "
	Select 
	@nDefaultedStaffKey 	as 'StaffKey',
	@sDefaultedStaffName    as 'StaffName',
	@sDefaultedStaffCode	as 'StaffCode',
	@nNameKey   		as 'NameKey',
	@sName			as 'Name',
	@sNameCode		as 'NameCode',
	@pnCaseKey		as 'CaseKey',
	@sCaseReference		as 'CaseReference',
	@sCaseShortTitle	as 'CaseShortTitle',
	@nFileLocationKey	as 'FileLocationKey',
	@sFileLocation		as 'FileLocation',
	@nAgentNameKey   	as 'AssociateKey',
	@sAgentName		as 'AssociateName',
	@sAgentNameCode		as 'AssociateCode',
	@sLocalCurrencyCode	as 'LocalCurrencyCode',
	@nLocalDecimalPlaces	as 'LocalDecimalPlaces',
	@sWIPTemplateKey	as 'WipTemplateKey',
	@sWIPTemplateDesc	as 'WIPTemplateDescription',
	@bSeparateMarginFlag	as 'SeparateMarginFlag',
	@nOfficeEntityNo	as 'OfficeEntityKey',
	@sProfitCentreCode	as 'ProfitCentreCode',
	@sProfitCentre		as 'ProfitCentre',
	@bIsSplitDebtorWip as 'IsSplitDebtorWip',"+char(10)+
	CASE 	WHEN @nNarrativeKey IS NOT NULL 
		THEN "@nNarrativeKey	as 'NarrativeKey',
		      N.NARRATIVECODE	as 'NarrativeCode',
		      "+dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETITLE',null,'N',@sLookupCulture,0)+" as 'NarrativeTitle',"+char(10)+
		      -- If the Narrative Translate site control is on, the text is obtained 
		      -- in the language in which the bill will be raised. 			      
		      CASE WHEN @nLanguageKey is not null
			   THEN "ISNULL(NTR.TRANSLATEDTEXT,  "+dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETEXT',null,'N',@sLookupCulture,0)+")"	
			   -- If a translation is not required, or cannot be located, 
			   -- the Narrative.NarrativeText is returned:
			   ELSE dbo.fn_SqlTranslatedColumn('NARRATIVE','NARRATIVETEXT',null,'N',@sLookupCulture,0)
		      END+"	as 'NarrativeText'
		from NARRATIVE N"+char(10)+
			CASE 	WHEN @nLanguageKey is not null
				THEN char(10) + "left join NARRATIVETRANSLATE NTR	on (NTR.NARRATIVENO = N.NARRATIVENO"
				   + char(10) + "					and NTR.LANGUAGE = @nLanguageKey)"				  
			END+char(10)+
			"where N.NARRATIVENO = @nNarrativeKey"
		ELSE  "NULL	as 'NarrativeKey',
		       NULL 	as 'NarrativeCode',
		       NULL	as 'NarrativeTitle',
		       NULL	as 'NarrativeText'
		       where 1=1"
	END

	exec @nErrorCode = sp_executesql @sSQLString,
						N'@nDefaultedStaffKey 	int,
						  @sDefaultedStaffCode	nvarchar(10),
					      @sDefaultedStaffName	nvarchar(254),
						  @nNameKey		int,
						  @sNameCode		nvarchar(10),
						  @sName		nvarchar(254),
						  @sCaseReference	nvarchar(30),
						  @sCaseShortTitle	nvarchar(256),
						  @nFileLocationKey int,
						  @sFileLocation	nvarchar(80),
						  @nAgentNameKey	int,
						  @sAgentNameCode	nvarchar(10),
						  @sAgentName		nvarchar(254),
						  @sWIPTemplateKey	nvarchar(6),
						  @sWIPTemplateDesc	nvarchar(30),
						  @nNarrativeKey	smallint,
						  @nLanguageKey		int,
						  @pnCaseKey		int,
						  @sLocalCurrencyCode	nvarchar(3),
						  @nLocalDecimalPlaces	tinyint,
						  @bSeparateMarginFlag	bit,
						  @bIsSplitDebtorWip bit,
						  @sProfitCentreCode	nvarchar(6),
						  @nOfficeEntityNo	int,						  
						  @sProfitCentre	nvarchar(50)',
						  @nDefaultedStaffKey	= @nDefaultedStaffKey,
						  @sDefaultedStaffCode	= @sDefaultedStaffCode,
						  @sDefaultedStaffName	= @sDefaultedStaffName, 
						  @nNameKey		= @nNameKey,
						  @sNameCode		= @sNameCode,
						  @sName		= @sName,
						  @sCaseReference	= @sCaseReference,
						  @sCaseShortTitle	= @sCaseShortTitle,
						  @nFileLocationKey	= @nFileLocationKey,
						  @sFileLocation	= @sFileLocation,
						  @nAgentNameKey	= @nAgentNameKey,
						  @sAgentNameCode	= @sAgentNameCode,
						  @sAgentName		= @sAgentName,
						  @sWIPTemplateKey	= @sWIPTemplateKey,
						  @sWIPTemplateDesc	= @sWIPTemplateDesc,
						  @nNarrativeKey	= @nNarrativeKey,
						  @nLanguageKey		= @nLanguageKey,
						  @pnCaseKey		= @pnCaseKey,
						  @sLocalCurrencyCode   = @sLocalCurrencyCode,
						  @nLocalDecimalPlaces  = @nLocalDecimalPlaces,
						  @bSeparateMarginFlag	= @bSeparateMarginFlag,
						  @bIsSplitDebtorWip	= @bIsSplitDebtorWip,
						  @sProfitCentreCode	= @sProfitCentreCode,
						  @nOfficeEntityNo		= @nOfficeEntityNo,						 
						  @sProfitCentre	= @sProfitCentre
End

Return @nErrorCode
GO

Grant execute on dbo.wp_DefaultWipInformation to public
GO
