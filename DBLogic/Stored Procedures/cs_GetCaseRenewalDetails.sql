-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GetCaseRenewalDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GetCaseRenewalDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GetCaseRenewalDetails.'
	Drop procedure [dbo].[cs_GetCaseRenewalDetails]
End
Print '**** Creating Stored Procedure dbo.cs_GetCaseRenewalDetails...'
Print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_GetCaseRenewalDetails
(
	@pnUserIdentityId		int,			-- the user logged on
	@psCulture			nvarchar(10)	= null,
	@pbExternalUser			bit		= 0,	-- flag to indicate if user is external. 
	@pnCaseKey			int,
	@pbCalledFromCentura		bit 		= 0,
	@psResultsetsRequired		nvarchar(4000) 	= null	-- comma seperated list to describe which resultset to return
)

AS
-- PROCEDURE :	cs_GetCaseRenewalDetails
-- VERSION :	61
-- DESCRIPTION:	Returns case details to be used in Renewal screen
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 02 Jun 2003	MF			Procedure created
-- 08 Sep 2003	MF	RFC338	2	
-- 23 Sep 2003	MF	RFC338	3	External users are to see the External Renewal Status whereas
--					internal users will see the internal status description.
-- 21 Oct 2003	MF	RFC338	4	External users are to only have access to t
-- 18-Feb-2004	TM	RFC976	5	Add the @pbCalledFromCentura  = default parameter to the calling code 
--					for relevant functions.
-- 04-Feb-2004	TM	RFC1032	6	Pass @pnCaseKey as the @pnCaseKey to the fn_FilterUserCases.
-- 10-Mar-2004	TM	RFC868	7	Modify the logic extracting the 'Email' column to use new Name.MainEmail column.
-- 26-May-2004	TM	RFC863	8	For the @psNameTypeKey in ('Z', 'D') extract the AttentionKey, Attention 
--					and Address  in the same manner as billing (SQA7355).
-- 31-May-2004	TM	RFC863	9	Improve the commenting of SQL extracting the Billing Address/Attention.
-- 02-Jul-2004	MF	RFC1509	10	Allow Standing Instructions to be returned with just the Instruction Type
--					label if no default has been defined against the HomeNameNo.
-- 18 Aug 2004	AB	8035	11	Add collate database_default syntax to temp tables
-- 03-Sep-2004	TM	RFC1768	12	Change NextRenewalDate to isnull(@dtCPARenewalDate, @dtNextRenewalDate).
--					Remove CPARenewalDate and replace it with a new IsCPARenewalDate. IsCPARenewalDate 
--					is 0 for external users when the Clients Unaware of CPA site control is on.
--					Otherwise, it is 1 if @dtCPARenewalDate is not null.
-- 09 Sep 2004	JEK	RFC886	13	Implement @psCulture and @pbCalledByCentura in FilterUser functions.
-- 10 Sep 2004	TM	RFC1158	14	Declare @pbCalledFromCentura for the sp_executesql.
-- 13 Sep 2004	TM	RFC886	15	Implement translation.
-- 29 Sep 2004	TM	RFC1806	16	Pass the new parameter and to pass the country postal name instead of the country
--					name to the fn_FormatAddress.	
-- 30 Sep 2004	TM	RFC1806	17	Fix SQL overflow problem.	
-- 13 Oct 2004	MF	10530 	18	Additional details have been requested by CPA to appear on our Renewals area
--					so as to highlight this information to the user.
-- 02 Nov 2004	TM	RFC1539	19	Pass the new @pdtCPARenewalDate parameter to pt_GetAgeOfCase.
-- 15 Dec 2004	TM	RFC2098	20	Suppress new CPA fields if the user is external.
-- 14 Jan 2005	MF	8961	21	Explicitly shorten the length of some columns being returned to 254 characters
--					to avoid problems with Centura.  These are Email, Fax and Phone.
-- 04 Mar 2005	JEK	RFC2423	22	Above change caused SQL to overflow for culture pt-BR.
-- 15 May 2005	JEK	RFC2508	23	Extract @sLookupCulture and pass to translation instead of @psCulture
-- 03 Jun 2005	MF	11449	24	Split the SELECT that gets Filing, Expiry and Renewal Start into two separate
--					SELECT statements to ensure the optimiser makes a good decision.  Some sites
--					had problems due to an Index Scan being performed instead of an Index Seek.
-- 09 Nov 2005	MF	12039	25	User the function to return Standing Instructions to ensure standardisation of
--					coding.  
-- 31 Jan 2006	MF	11942	26	Pass the Cycle number to the procedure that determines the Age Of Case as this 
--					may be required.
-- 19 May 2006	JEK	RFC3775	27	Implement Renewal Name Type Optional site control.
-- 20 Jun 2006	JEK	RFC4009	28	Change above causes SQL to overflow for translations.
--					Procedure does not return error code.
-- 26 Jun 2006	SW	RFC4038	29	Return rowkey when @pbCalledFromCentura = 0
-- 19 Jul 2006	SW	RFC3217	30	implement new param @psResultsetsRequired to optionally return resultset
-- 12 Jan 2007	LP	RFC4766	31	For external users, RenewalInstructions result set should only contain
--					instructions listed in Client Instruction Types site control
-- 17 Apr 2008	LP	RFC6335	32	Fix error when using TEMPCASEINSTRUCTIONS temp table.
-- 14 Feb 2008	SF	RFC6205	32	Return translated Instructions
-- 07 Apr 2008	SF	RFC6417	33	Fix syntax error as a result of merging
-- 22 Sep 2008  LP      RFC4087 34      Return RenewalStatusKey,RenewalTypeKey,StopPayCode columns.
-- 11 Dec 2008	MF	17136	35	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 01 Apr 2009	MF	RFC7838	36	Revisit RFC4087 to restrict these columns only when not called from Centura.
-- 21 May 2009	vql	17700	37	Renewals tab is crashing when activated due to missing columns in temporary table.
-- 21 Jul 2009	MF	17748	38	Reduce locking level to ensure other activities are not blocked.
-- 08 Oct 2009	PS	RFC8369 39	Add DebtorRestrction column in the result set for the Renewal Names. 
--					Use exec instead of the sp_executesql to overcome nvarchar length limitation of 4000. 
-- 25 Nov 2009	LP	R100109	40	Fix RenewalNames SQLString to prevent syntax error when passing foreign lookup culture.
-- 24 Mar 2010	MF	18567 	41	Revist RFC8369 to move the new column DebtorRestrictionActionKey to the end of the result set as Centura programs
--					rely on the column position.  This also corrected SQA18568.
-- 17 May 2010	MF	R9071	42	Use the highest open cycle to get the NRD 
-- 01 Jul 2010	MF	18758  	43	Increase the column size of Instruction Type to allow for expanded list.
-- 17 Sep 2010	MF	R9777	44	Found problem when testing this RFC. Solution was to change @sSQLString definition to varchar(max).
-- 19 Apr 2011	MF	R10504 	45	Revisit RFC9071 and revert to using the lowest open cycle as this is consistant across the system.
-- 24 May 2011	MF	R10691	46	Revisit of SQA18567 as a variable for Instruction Type needs to be changed to nvarchar(3)
-- 07 Jun 2011	MF	19696 	47	Order by of Names was incorrect.
-- 20 Sep 2011	MF	19912	48	Revisit of 18758 as variable had not been changed.  The variable is not required and has been removed.
-- 21 Oct 2011  MS      R11438  49      Pass Namestyle in fn_FormatName call
-- 24 Oct 2011	ASH	R11460	50	Cast integer columns as nvarchar(11) data type.
-- 09 Mar 2012	vql	R10705	51	Editable Renewals Tab in Silverlight (return logtimestamps).
-- 07 Jun 2012	vql	R12392	52	Correct syntax error.
-- 06 Sep 2012  MS      R12673	53      Added RENEWALDATES resultset for web version
-- 15 Apr 2013	DV	R13270	54	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015  MS      R54289  55	Remove Expirydate caluclation check for determing age of case
-- 02 Nov 2015  MS      R54371  56	Add @pbUseHighestCycle = 1 to cs_GetNextRenewalDate sp call to 
--					fetch next renewal date based on highest open cycle
-- 04 Nov 2015	KR	R53910	57	Adjust formatted names logic (DR-15543)
-- 04 Dec 2015  MS      R56000	58	Reverse changes for RFC54371
-- 07 Jun 2016	MF	62402	59	Return the Renewal Agent name,along with the other names.
-- 10 Jan 2018	MF	73190	60	Duplicate names were being returned where more than one Billing name was defined. Need to consider Property Type of Case.
-- 07 Sep 2018	AV	74738	61	Set isolation level to read uncommited.

Set nocount on
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--------------------------------------------------
-- Using temp table instead of table variable as
-- SQL2000 does not support loading table variable
-- from the results of a stored procedure call.
--------------------------------------------------
create table #TEMPCASEINSTRUCTIONS(
				INSTRTYPEDESC		nvarchar(254)	collate database_default NULL,
				DESCRIPTION		nvarchar(254)	collate database_default NULL,
				CASEID			int		NULL,
				INSTRUCTIONCODE 	int		NULL,
				NAMENO			int		NULL,
				INTERNALSEQUENCE	int		NULL,
				INSTRUCTIONTYPE		nvarchar(3)	collate database_default NULL,
				PERIOD1AMT		smallint	NULL,
				PERIOD1TYPE		nchar(1) 	collate database_default NULL,
				PERIOD2AMT		smallint	NULL,
				PERIOD2TYPE		nchar(1) 	collate database_default NULL,
				PERIOD3AMT		smallint	NULL,
				PERIOD3TYPE		nchar(1) 	collate database_default NULL,
				DEFAULTEDFROM		nvarchar(254)	collate database_default NULL,
				ADJUSTMENT		nvarchar(4)	collate database_default NULL,
				ADJUSTDAY		tinyint		NULL,
				ADJUSTSTARTMONTH	tinyint		NULL,
				ADJUSTDAYOFWEEK		tinyint		NULL,
				ADJUSTTODATE		datetime	NULL,
				STANDINGINSTRTEXT	nvarchar(4000)	collate database_default NULL
				)

declare @tbInstructionTypes table (
				INSTRUCTIONTYPE 	nvarchar(3)	collate database_default NOT NULL,
				INSTRTYPEDESC		nvarchar(50)	collate database_default NOT NULL,
				NAMETYPE		nvarchar(3)	collate database_default NOT NULL,
				RESTRICTEDBYTYPE	nvarchar(3)	collate database_default NULL
				)

Declare	@dtNextRenewalDate 	datetime
Declare	@dtNextQuinDate 	datetime
Declare	@dtFilingDate 		datetime
Declare	@dtRenewalStartDate 	datetime
Declare	@dtExpiryDate 		datetime
Declare	@dtCPARenewalDate	datetime
Declare	@dtCPAStartPayDate	datetime
Declare	@dtCPAStopPayDate	datetime
Declare @dtCPALastExtractDate	datetime
Declare	@nYear 			smallint
Declare	@nCycle 		smallint
Declare	@sRenewalStatus		nvarchar(50)
Declare @nRenewalStatusKey      smallint
Declare	@sRenewalType		nvarchar(80)
Declare	@nRenewalTypeKey	int
Declare	@sRenewalRemarks	nvarchar(254)
Declare	@nReportToThirdParty	smallint
Declare	@sStopPay		nvarchar(80)
Declare @sStopPayCode           nvarchar(20)
Declare	@nExtendedRenewals	int
Declare @nCPAStartPayEventNo	int
Declare @nCPAStopPayEventNo	int
Declare	@nCPALastBatchNo	int
Declare @bInNextBatch		bit
Declare @bIsRenewalOptional	bit
Declare @sCaseStatus		nvarchar(50)

Declare @ErrorCode 		int
Declare @RowCount		int
Declare @nHomeNameno		int
Declare @sSQLString		nvarchar(max)
Declare	@sInstructions		nchar(7)
Declare @sInstNameType		nvarchar(3)
Declare	@sRestrictedByType	nvarchar(3)
Declare @sLookupCulture		nvarchar(10)

-- SQA17748 Reduce the locking level to avoid blocking other processes
set transaction isolation level read uncommitted

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Turn @psResultsetsRequired to '' if @psResultsetsRequired passed in as ',' or null,
-- remove spaces from @psResultsetsRequired and pad ',' to the end
Set @psResultsetsRequired = upper(replace(isnull(nullif(@psResultsetsRequired, ','), ''), ' ', '')) + ','

Set @ErrorCode = 0

-- If the user is an external user then validate that they have access to the Case
-- If they do not have access to the Case then set the CaseId to null so that empty
-- result sets are retured.

If  @ErrorCode=0
and @pbExternalUser=1
Begin
	Set @sSQLString="
	Select @pnCaseKeyOUT=max(CASEID)  -- use MAX so NULL gets returned if no row exists
	from dbo.fn_FilterUserCases(@pnUserIdentityId,1,@pnCaseKey)"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKeyOUT		int		OUTPUT,
				  @pnUserIdentityId	int,
				  @pnCaseKey		int',
				  @pnCaseKeyOUT		=@pnCaseKey	OUTPUT,
				  @pnUserIdentityId	=@pnUserIdentityId,
				  @pnCaseKey		=@pnCaseKey
End

If  @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bIsRenewalOptional	= SC.COLBOOLEAN
	from SITECONTROL SC where SC.CONTROLID='Renewal Name Type Optional'"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@bIsRenewalOptional		bit		OUTPUT',
				  @bIsRenewalOptional		= @bIsRenewalOptional	OUTPUT
End

If @ErrorCode=0
Begin
	If @pbCalledFromCentura=1
		Set @sSQLString="
		Select	@sRenewalStatus		= CASE WHEN(@pbExternalUser=1) 
						       THEN "+dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+"
						       ELSE "+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+"
						  END,	
		@sRenewalType		= "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T1',@sLookupCulture,@pbCalledFromCentura)+",
		@sRenewalRemarks	= "+dbo.fn_SqlTranslatedColumn('PROPERTY','RENEWALNOTES',null,'P',@sLookupCulture,@pbCalledFromCentura)+",
		@nReportToThirdParty	= C.REPORTTOTHIRDPARTY,
		@sStopPay		= "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T2',@sLookupCulture,@pbCalledFromCentura)+",
		@nExtendedRenewals	= C.EXTENDEDRENEWALS
		from CASES C
		     join PROPERTY P    on (P.CASEID=C.CASEID)
		left join STATUS S      on (S.STATUSCODE=P.RENEWALSTATUS)
		left join TABLECODES T1 on (T1.TABLECODE=P.RENEWALTYPE)
		left join TABLECODES T2 on (T2.TABLETYPE=68
					and T2.USERCODE =C.STOPPAYREASON)
		where C.CASEID=@pnCaseKey"
	Else
		Set @sSQLString="
		Select	@sRenewalStatus		= CASE WHEN(@pbExternalUser=1) 
						       THEN "+dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+"
						       ELSE "+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'S',@sLookupCulture,@pbCalledFromCentura)+"
						  END,		
	        @nRenewalStatusKey      = P.RENEWALSTATUS,
		@sRenewalType		= "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T1',@sLookupCulture,@pbCalledFromCentura)+",
		@nRenewalTypeKey        = T1.TABLECODE,
		@sRenewalRemarks	= "+dbo.fn_SqlTranslatedColumn('PROPERTY','RENEWALNOTES',null,'P',@sLookupCulture,@pbCalledFromCentura)+",
		@nReportToThirdParty	= C.REPORTTOTHIRDPARTY,
		@sStopPay		= "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T2',@sLookupCulture,@pbCalledFromCentura)+",
		@sStopPayCode           = T2.USERCODE,
		@nExtendedRenewals	= C.EXTENDEDRENEWALS,
		@sCaseStatus		= CASE WHEN(@pbExternalUser=1) 
					       THEN "+dbo.fn_SqlTranslatedColumn('STATUS','EXTERNALDESC',null,'CS',@sLookupCulture,@pbCalledFromCentura)+"
					       ELSE "+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'CS',@sLookupCulture,@pbCalledFromCentura)+"
					  END
		from CASES C
		     join PROPERTY P    on (P.CASEID=C.CASEID)
		left join STATUS S      on (S.STATUSCODE=P.RENEWALSTATUS)
		left join STATUS CS	on (CS.STATUSCODE = C.STATUSCODE)
		left join TABLECODES T1 on (T1.TABLECODE=P.RENEWALTYPE)
		left join TABLECODES T2 on (T2.TABLETYPE=68
					and T2.USERCODE =C.STOPPAYREASON)
		where C.CASEID=@pnCaseKey"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @pbExternalUser	bit,
					  @sRenewalStatus	nvarchar(50) 	output,
					  @nRenewalStatusKey    smallint        output,
					  @sRenewalType		nvarchar(80)	output,	
					  @nRenewalTypeKey      int             output,
					  @sRenewalRemarks	nvarchar(254)	output,	
				  	  @nReportToThirdParty	smallint	output,
					  @sStopPay		nvarchar(80)	output,
					  @sStopPayCode         nvarchar(20)    output,
					  @nExtendedRenewals	int		output,
					  @sCaseStatus		nvarchar(50)	output',
					  @pnCaseKey		=@pnCaseKey,
					  @pbExternalUser	=@pbExternalUser,
					  @sRenewalStatus	=@sRenewalStatus	OUTPUT,
					  @nRenewalStatusKey    =@nRenewalStatusKey     OUTPUT,      
					  @sRenewalType		=@sRenewalType		OUTPUT,
					  @nRenewalTypeKey      =@nRenewalTypeKey       OUTPUT,
					  @sRenewalRemarks	=@sRenewalRemarks	OUTPUT,
					  @nReportToThirdParty	=@nReportToThirdParty	OUTPUT,
					  @sStopPay		=@sStopPay		OUTPUT,
					  @sStopPayCode         =@sStopPayCode          OUTPUT,
					  @nExtendedRenewals	=@nExtendedRenewals	OUTPUT,
					  @sCaseStatus		= @sCaseStatus		OUTPUT
End

-- Get dates
-- It is safe to hardcode the EventNos for Filing, Expiry, and Renewal Start 
-- Split the SELECTS so as to ensure the optimiser chooses an Index SEEK
If @ErrorCode=0
Begin 
	Set @sSQLString="
	select	@dtFilingDate	    = CE1.EVENTDATE,
		@dtExpiryDate	    = isnull(CE2.EVENTDATE, CE2.EVENTDUEDATE)
	from CASES C
	left join CASEEVENT CE1		on (CE1.CASEID =C.CASEID
					and CE1.CYCLE  = 1
					and CE1.EVENTNO=-4)
	left join CASEEVENT CE2		on (CE2.CASEID =C.CASEID
					and CE2.CYCLE  = 1
					and CE2.EVENTNO=-12)
	Where C.CASEID = @pnCaseKey"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@dtFilingDate		datetime OUTPUT,
					  @dtExpiryDate		datetime OUTPUT,
					  @pnCaseKey		int',
					  @dtFilingDate      =@dtFilingDate 		OUTPUT,
					  @dtExpiryDate      =@dtExpiryDate		OUTPUT,
					  @pnCaseKey         =@pnCaseKey
End

If @ErrorCode=0
Begin 
	Set @sSQLString="
	select	@dtRenewalStartDate = CE3.EVENTDATE
	from CASES C
	left join CASEEVENT CE3 	on (CE3.CASEID =C.CASEID
					and CE3.CYCLE  = 1
					and CE3.EVENTNO=-9)
	Where C.CASEID = @pnCaseKey"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@dtRenewalStartDate  		datetime	OUTPUT,
					  @pnCaseKey			int',
					  @dtRenewalStartDate=@dtRenewalStartDate 	OUTPUT,
					  @pnCaseKey         =@pnCaseKey
End

-- Get the cyclic Quinquenial date to be reported by using the lowest
-- openaction for the action that created it.
-- The EVENTNO to use is to be extracted from the Site Control 'CPA Date- Quin Tax'

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select  @dtNextQuinDate=isnull(CE.EVENTDATE,CE.EVENTDUEDATE)
	from SITECONTROL S
	join CASEEVENT CE	on (CE.EVENTNO=S.COLINTEGER)
	join OPENACTION OA	on (OA.CASEID=CE.CASEID
				and OA.ACTION=CE.CREATEDBYACTION
				and OA.CYCLE =CE.CYCLE
				and OA.CYCLE  = (select max(OA1.CYCLE)
						from  OPENACTION OA1
						where OA1.CASEID=OA.CASEID
						and   OA1.ACTION=OA.ACTION
						and   OA1.POLICEEVENTS=1))
	where CE.CASEID=@pnCaseKey
	and S.CONTROLID='CPA Date-Quin Tax'"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @dtNextQuinDate	datetime	OUTPUT',
					  @pnCaseKey		=@pnCaseKey,
					  @dtNextQuinDate	=@dtNextQuinDate OUTPUT

End

-- Get Next Renewal Date by calling a standard stored procedure.  This will return both 
-- the InProma Next Renewal Date as well as the CPA Renewal Date.

If @ErrorCode=0
Begin 
	Exec @ErrorCode= dbo.cs_GetNextRenewalDate
				@pnCaseKey		=@pnCaseKey,
				@pbCallFromCentura	=0,
				@pdtNextRenewalDate 	=@dtNextRenewalDate	output,
				@pdtCPARenewalDate	=@dtCPARenewalDate	output,
				@pnCycle		=@nCycle		output
End

-- Get the Renewal Year - Age Of Case

If  @ErrorCode=0
Begin
	Exec @ErrorCode = 
		dbo.pt_GetAgeOfCase 
			@pnCaseId           =@pnCaseKey, 
			@pnCycle            =@nCycle, 
			@pdtRenewalStartDate=@dtRenewalStartDate,
			@pdtNextRenewalDate =@dtNextRenewalDate,
			@pnAgeOfCase        =@nYear output,
			@pdtCPARenewalDate  =@dtCPARenewalDate
end

-- Get the different types of Instructions to be extracted for this case
-- that apply to Renewal rules.

Set @RowCount=0

If  @ErrorCode=0
and @pnCaseKey is not null  -- in case the user does not have access to the Case.
Begin
	-- Is a translation required?
	If @ErrorCode=0
	and @sLookupCulture is not null
	and dbo.fn_GetTranslatedTIDColumn('INSTRUCTIONTYPE','INSTRTYPEDESC') is not null
	Begin
		If @pbCalledFromCentura = 1
		Begin
			insert into @tbInstructionTypes (INSTRUCTIONTYPE, INSTRTYPEDESC, NAMETYPE, RESTRICTEDBYTYPE)
			select distinct I.INSTRUCTIONTYPE, dbo.fn_GetTranslationLimited(I.INSTRTYPEDESC,null,I.INSTRTYPEDESC_TID,@sLookupCulture), I.NAMETYPE, I.RESTRICTEDBYTYPE
			from EVENTCONTROL EC
			join CRITERIA C		on (C.CRITERIANO=EC.CRITERIANO)
			join ACTIONS A		on (A.ACTION=C.ACTION
						and A.ACTIONTYPEFLAG=1)
			join INSTRUCTIONTYPE I	on (I.INSTRUCTIONTYPE=EC.INSTRUCTIONTYPE)
		
			Set @ErrorCode=@@Error
		End
		Else
		Begin
			insert into @tbInstructionTypes (INSTRUCTIONTYPE, INSTRTYPEDESC, NAMETYPE, RESTRICTEDBYTYPE)
			select DISTINCT I.INSTRUCTIONTYPE, dbo.fn_GetTranslation(I.INSTRTYPEDESC,null,I.INSTRTYPEDESC_TID,@sLookupCulture), I.NAMETYPE, I.RESTRICTEDBYTYPE
			from EVENTCONTROL EC
			join CRITERIA C		on (C.CRITERIANO=EC.CRITERIANO)
			join ACTIONS A		on (A.ACTION=C.ACTION
						and A.ACTIONTYPEFLAG=1)
			join INSTRUCTIONTYPE I	on (I.INSTRUCTIONTYPE=EC.INSTRUCTIONTYPE)
			
			Set @ErrorCode=@@Error	
		End
	End
	-- No translation is required
	Else
	Begin
		insert into @tbInstructionTypes (INSTRUCTIONTYPE, INSTRTYPEDESC, NAMETYPE, RESTRICTEDBYTYPE)
		select DISTINCT I.INSTRUCTIONTYPE, I.INSTRTYPEDESC, I.NAMETYPE, I.RESTRICTEDBYTYPE
		from EVENTCONTROL EC
		join CRITERIA C		on (C.CRITERIANO=EC.CRITERIANO)
		join ACTIONS A		on (A.ACTION=C.ACTION
					and A.ACTIONTYPEFLAG=1)
		join INSTRUCTIONTYPE I	on (I.INSTRUCTIONTYPE=EC.INSTRUCTIONTYPE)
	
		Set @ErrorCode=@@Error
	End
End

 -- RenewalInstructions result set
If  @ErrorCode=0
and (@psResultsetsRequired = ',' or CHARINDEX('RENEWALINSTRUCTIONS,', @psResultsetsRequired) <> 0)
Begin
	If @pnCaseKey is not null  -- in case the user does not have access to the Case.
	Begin

		-- The most efficient method of getting standing instructions for the
		-- case is to call the stored procedure cs_GetStandingInstructions
		-- and load into a temporary table for further filtering.
		-- Note : this is more efficient than fn_StandingInstruction
		insert into #TEMPCASEINSTRUCTIONS
			(INSTRTYPEDESC,DESCRIPTION,CASEID,INSTRUCTIONCODE,NAMENO,INTERNALSEQUENCE,INSTRUCTIONTYPE,
			 PERIOD1AMT,PERIOD1TYPE,PERIOD2AMT,PERIOD2TYPE,PERIOD3AMT,PERIOD3TYPE,DEFAULTEDFROM,
			 ADJUSTMENT,ADJUSTDAY,ADJUSTSTARTMONTH,ADJUSTDAYOFWEEK,ADJUSTTODATE,STANDINGINSTRTEXT)
		Exec @ErrorCode=dbo.cs_GetStandingInstructions 
				@pnCaseKey			=@pnCaseKey,
				@psCulture			=@psCulture,
				@pbCalledFromCentura 		= 1,	
				@pbIsExternalUser 		= 0,
				@pbCalledFromBusinessEntity	= 0,
				@pnUserIdentityId		=@pnUserIdentityId

		-- SQA12039
		-- Return the best Standing Instruction for each of the renewal related instruction types.
	
		-- RFC4038, RFC3721
		-- Only apply changes to @pbCalledFromCentura = 0
		If @pbCalledFromCentura = 1
		and @ErrorCode=0
		Begin
			Select	@pnCaseKey				as CaseKey,
				cast(IT.INSTRTYPEDESC+':'+T.[DESCRIPTION] as nvarchar(100))
									as FormattedInstruction, 
				IT.INSTRUCTIONTYPE			as InstructionType
			FROM @tbInstructionTypes  IT
			join #TEMPCASEINSTRUCTIONS T on (T.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
			order by IT.INSTRUCTIONTYPE
		End
		Else If @ErrorCode=0
		Begin
			If @pbExternalUser = 1
			Begin
				Select	cast(T.INSTRUCTIONCODE as nvarchar(11))	as RowKey,
					@pnCaseKey				as CaseKey,
					IT.INSTRTYPEDESC			as InstructionTypeDescription, 
					T.[DESCRIPTION]				as Instruction, 
					IT.INSTRUCTIONTYPE			as InstructionType
				FROM @tbInstructionTypes  IT
				join #TEMPCASEINSTRUCTIONS T on (T.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
				join SITECONTROL S on (S.CONTROLID = 'Client Instruction Types')
				where patindex('%'+','+upper(IT.INSTRUCTIONTYPE)+','+'%',',' + replace(upper(S.COLCHARACTER), ' ', '') + ',')>0
				order by IT.INSTRUCTIONTYPE
			End
			Else
			Begin
				Select	cast(T.INSTRUCTIONCODE as nvarchar(11))	as RowKey,
					@pnCaseKey				as CaseKey,
					IT.INSTRTYPEDESC			as InstructionTypeDescription, 
					T.[DESCRIPTION]				as Instruction, 
					IT.INSTRUCTIONTYPE			as InstructionType
				FROM @tbInstructionTypes  IT
				join #TEMPCASEINSTRUCTIONS T on (T.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
				order by IT.INSTRUCTIONTYPE
			End
		End
	End
	Else
	Begin
		-- Only return Rowkey when @pbCalledFromCentura = 0
		If @pbCalledFromCentura = 1
		Begin
			Select	null	as CaseKey,
				null	as FormattedInstruction,
				null	as InstructionType
			where 1 = 0
		End
		Else
		Begin
			Select	null	as RowKey,
				null	as CaseKey,
				null	as InstructionTypeDescription,
				null	as Instruction, 
				null	as InstructionType
			where 1 = 0
		End
	End
End

-- RenewalNames result set
-- Get the various Names and their details that are to be displayed with Renewal Details
-- Sort these in a particular order depending upoin the NameType.
If @ErrorCode=0
and (@psResultsetsRequired = ',' or CHARINDEX('RENEWALNAMES,', @psResultsetsRequired) <> 0)
Begin

	Set @sSQLString= 
	"Select  distinct"+char(10)+
	CASE WHEN @pbCalledFromCentura = 0
	THEN 	"cast(CN.CASEID as nvarchar(11)) + '^' +"+char(10)+
		"cast(CN.NAMETYPE as nvarchar(10)) + '^' +"+char(10)+
		"cast(CN.NAMENO as nvarchar(11)) + '^' +"+char(10)+
		"cast(CN.SEQUENCE as nvarchar(10)) as RowKey,"+char(10)
	ELSE	""
	END +
	"CN.CASEID as CaseKey,"+char(10)+
	"CN.NAMETYPE as NameTypeKey,"+char(10)+
	"CN.NAMENO as NameKey,"+char(10)+
	"CN.SEQUENCE as NameSequence,"+char(10)+
	"CASE WHEN (NT.COLUMNFLAGS&1=1)"+char(10)+
	"THEN CASE WHEN CN.NAMETYPE in ('Z','D') THEN N2.NAMENO ELSE N1.NAMENO END"+char(10)+	
	"END as AttentionKey,"+char(10)+
	"CASE WHEN (NT.COLUMNFLAGS&1=1)"+char(10)+
	-- Specific logic is required to retrieve the Debtor/Renewal Debtor Attention (name types 'D' and 'Z')
	"THEN CASE WHEN CN.NAMETYPE in ('Z','D')"+char(10)+
	"THEN dbo.fn_FormatNameUsingNameNo(N2.NAMENO,coalesce(N2.NAMESTYLE,NAT2.NAMESTYLE,7101))"+char(10)+
	"ELSE dbo.fn_FormatNameUsingNameNo(N1.NAMENO,coalesce(N1.NAMESTYLE,NAT1.NAMESTYLE,7101))"+char(10)+
	"END"+char(10)+
	"END as Attention,"+char(10)+
	"NT.DESCRIPTION as NameTypeDescription,"+char(10)+  	
	"dbo.fn_FormatNameUsingNameNo(N.NAMENO,"+
		CASE WHEN(@pbExternalUser=1) 
		THEN "coalesce(N1.NAMESTYLE,NAT1.NAMESTYLE,7101)"
		ELSE "NULL"
		END
		+") as Name,"+char(10)+  	
	-- Specific logic is required to retrieve the Debtor/Renewal Debtor Address (name types 'D' and 'Z')
	"CASE WHEN CN.NAMETYPE in ('Z','D')"+char(10)+
	"THEN dbo.fn_FormatAddress(BA.STREET1,BA.STREET2,BA.CITY,BA.STATE,BS.STATENAME,BA.POSTCODE,BC.POSTALNAME,BC.POSTCODEFIRST,BC.STATEABBREVIATED,BC.POSTCODELITERAL,BC.ADDRESSSTYLE)"+char(10)+	
	"ELSE dbo.fn_FormatAddress(A.STREET1,A.STREET2,A.CITY,A.STATE,S.STATENAME,A.POSTCODE,C.POSTALNAME,C.POSTCODEFIRST,C.STATEABBREVIATED,C.POSTCODELITERAL,C.ADDRESSSTYLE)"+char(10)+	
	"END as Address,"+char(10)+	
	"CN.REFERENCENO as ReferenceNo,"+char(10)+
	"CASE WHEN(" + CAST(@pbExternalUser AS CHAR(1)) + "=0)"+char(10)+ 
	"THEN N.NAMECODE"+char(10)+
	"END as NameCode,"+char(10)+
	"CASE WHEN (NT.COLUMNFLAGS&64=64 AND " + CAST(@pbExternalUser AS CHAR(1)) + "=0)"+char(10)+
	"THEN IP.CURRENCY"+char(10)+
	"END as BillingCurrency,"+char(10)+
	"CASE WHEN (NT.COLUMNFLAGS&64=64 AND " + CAST(@pbExternalUser AS CHAR(1)) + "=0)"+char(10)+
	"THEN substring("+dbo.fn_SqlTranslatedColumn('DEBTORSTATUS','DEBTORSTATUS',null,'D',@sLookupCulture,@pbCalledFromCentura)+",1,254)"+char(10)+
	"END as DebtorRestriction,"+char(10)+
	"CASE WHEN (NT.COLUMNFLAGS&64=64 AND " + CAST(@pbExternalUser AS CHAR(1)) + "=0)"+char(10)+
	"THEN D.ACTIONFLAG"+char(10)+
	"END as DebtorRestrictionActionKey,"+char(10)+
	CASE WHEN (@pbExternalUser=0)
	THEN "substring(dbo.fn_FormatTelecom(TEL.TELECOMTYPE,TEL.ISD,TEL.AREACODE,TEL.TELECOMNUMBER,TEL.EXTENSION),1,254)"
	ELSE "NULL"
	END + " as Phone,"+char(10)+
	"CASE WHEN (" + CAST(@pbExternalUser AS CHAR(1)) + "=0)"+char(10)+
	"THEN substring(dbo.fn_FormatTelecom(FAX.TELECOMTYPE,FAX.ISD,FAX.AREACODE,FAX.TELECOMNUMBER,FAX.EXTENSION),1,254)"+char(10)+
	"END as Fax,"+char(10)+
	"CASE WHEN (" + CAST(@pbExternalUser AS CHAR(1)) + "=0)"+char(10)+
	"THEN substring(dbo.fn_FormatTelecom(EML.TELECOMTYPE,EML.ISD,EML.AREACODE,EML.TELECOMNUMBER,EML.EXTENSION),1,254)"+char(10)+						
	"END as Email,"+char(10)+
	"CASE CN.NAMETYPE"+char(10)+	
		"WHEN 'R' THEN 10000000"+char(10)+  
		"WHEN 'Z' THEN 1000000"+char(10)+  
		"WHEN '&' THEN 100000"+char(10)+ 
		"WHEN 'O' THEN 10000"+char(10)+  
		"WHEN 'I' THEN 1000"+char(10)+  
		"WHEN 'A' THEN 100"+char(10)+  
		"WHEN 'EMP' THEN 10"+char(10)+  
		"WHEN 'SIG' THEN 1"+char(10)+ 
		"ELSE 50"+char(10)+  
	"END as SORTORDER,"+char(10)+
	"CASE WHEN (NT.COLUMNFLAGS&64=64 AND " + CAST(@pbExternalUser AS CHAR(1)) + "=0)"+char(10)+
	"THEN D.ACTIONFLAG"+char(10)+
	"END as DebtorRestrictionActionKey"+char(10) +
	"FROM CASENAME CN"+char(10)+
	"join CASES CS on (CS.CASEID=CN.CASEID)"+char(10)+
	"join NAME N on (N.NAMENO=CN.NAMENO)"+char(10)+
	"join fn_FilterUserNameTypes(" + cast(@pnUserIdentityId as nvarchar(11)) + ", " +
		CASE WHEN(@sLookupCulture <> '') 
		THEN "'"+@sLookupCulture+"'"
		ELSE "NULL" 
		END + ", " +
	CAST(@pbExternalUser AS CHAR(1)) + "," + CAST(@pbCalledFromCentura AS CHAR(1)) + ") NT"+char(10)+
	"on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
	"left join COUNTRY NAT	on (NAT.COUNTRYCODE=N.NATIONALITY)"+char(10)+	
	-- Renewal Debtor/Debtor Attention
	"left join ASSOCIATEDNAME AN2 on (AN2.NAMENO=CN.INHERITEDNAMENO"+char(10)+
    	"and AN2.RELATIONSHIP=CN.INHERITEDRELATIONS"+char(10)+
    	"and AN2.RELATEDNAME=CN.NAMENO"+char(10)+
	"and AN2.SEQUENCE=CN.INHERITEDSEQUENCE)"+char(10)+

	"left join ASSOCIATEDNAME AN3 on (AN3.NAMENO=CN.NAMENO"+char(10)+
	"and AN3.RELATIONSHIP=N'BIL'"+char(10)+
	"and AN3.NAMENO=AN3.RELATEDNAME"+char(10)+
	"and AN3.PROPERTYTYPE=CS.PROPERTYTYPE"+char(10)+
	"and AN2.NAMENO is null)"+char(10)+
	
	"left join ASSOCIATEDNAME AN4 on (AN4.NAMENO=CN.NAMENO"+char(10)+
	"and AN4.RELATIONSHIP=N'BIL'"+char(10)+
	"and AN4.NAMENO=AN4.RELATEDNAME"+char(10)+
	"and AN4.PROPERTYTYPE is null"+char(10)+
	"and AN3.NAMENO is null)"+char(10)+

	-- For Debtor and Renewal Debtor (name types 'D' and 'Z') Attention and Address should be 
	-- extracted in the same manner as billing (SQA7355):
	-- 1)	Details recorded on the CaseName table; if no information is found then step 2 will be performed;
	-- 2)	If the debtor was inherited from the associated name then the details recorded against this 
	--      associated name will be returned; if the debtor was not inherited then go to the step 3;
	-- 3)	Check if the Address/Attention has been overridden on the AssociatedName table with 
	--	Relationship = 'BIL' and NameNo = RelatedName; if no information was found then go to the step 4; 
	-- 4)	Extract the Attention and Address details stored against the Name as the PostalAddress 
	--	and MainContact.
	"left join NAME N2 on (N2.NAMENO=COALESCE(CN.CORRESPONDNAME,AN2.CONTACT,AN3.CONTACT,AN4.CONTACT, N.MAINCONTACT))"+char(10)+
	"left join COUNTRY NAT2	on (NAT2.COUNTRYCODE=N2.NATIONALITY)"+char(10)+
	-- Renewal Debtor/Debtor Address
	"left join ADDRESS BA on (BA.ADDRESSCODE=COALESCE(CN.ADDRESSCODE,AN2.POSTALADDRESS,AN3.POSTALADDRESS,AN4.POSTALADDRESS,N.POSTALADDRESS))"+char(10)+
	"left join COUNTRY BC on (BC.COUNTRYCODE=BA.COUNTRYCODE)"+char(10)+
	"left join STATE   BS on (BS.COUNTRYCODE=BA.COUNTRYCODE"+char(10)+
	"and BS.STATE=BA.STATE)"+char(10)+
	"left join IPNAME IP on (IP.NAMENO=N.NAMENO)"+char(10)+
	"left join DEBTORSTATUS D on (D.BADDEBTOR=IP.BADDEBTOR)"+char(10)+
	-- For name types that are not Debtor (Name type = 'D') or Renewal Debtor ('Z')
	-- Attention and Address are obtained as the following:
	-- 1)	Details recorded on the CaseName table; if no information is found then step 2 will be performed; 
	-- 2)	Extract the Attention and Address details stored against the Name as the PostalAddress 
	--	and MainContact.
	-- Address
	"left join ADDRESS A on (A.ADDRESSCODE=isnull(CN.ADDRESSCODE, N.POSTALADDRESS))"+char(10)+
	"left join COUNTRY C on (C.COUNTRYCODE=A.COUNTRYCODE)"+char(10)+
	"left join STATE S on (S.COUNTRYCODE=A.COUNTRYCODE"+char(10)+
	"and S.STATE=A.STATE)"+char(10)+
	-- Attention
	"left join NAME N1 on (N1.NAMENO=isnull(CN.CORRESPONDNAME, N.MAINCONTACT))"+char(10)+
	"left join COUNTRY NAT1	on (NAT1.COUNTRYCODE=N1.NATIONALITY)"+char(10)+
	"left join TELECOMMUNICATION TEL on (TEL.TELECODE=isnull(N1.MAINPHONE, N.MAINPHONE))"+char(10)+
	"left join TELECOMMUNICATION FAX on (FAX.TELECODE=isnull(N1.FAX, N.FAX))"+char(10)+
	"left join TELECOMMUNICATION EML on (EML.TELECODE=isnull(N1.MAINEMAIL, N.MAINEMAIL))"+char(10)+	
	"WHERE CN.CASEID=@pnCaseKey"+char(10)+
	"and CN.EXPIRYDATE is null"+char(10)+    
	-- RFC3775 For WorkBenches, we are only interested in Instructor/Renewal Instructor/Debtor/Renewal/Debtor/Renewal Agent
	-- and we only want the Instructor/Debtor/Agent if the Renewal Name Type Optional site control is on.
	"and ( CN.NAMETYPE in ('R','Z','&')"+char(10)+
	"or   (CN.NAMETYPE in ('I','D', 'A') and " + CAST(@bIsRenewalOptional AS CHAR(1)) +  "=1)"+char(10)+
	"or   "+ CAST(@pbCalledFromCentura AS CHAR(1)) +"=1)"+char(10)+
	"ORDER BY SORTORDER DESC, NT.DESCRIPTION, CN.SEQUENCE"

	exec @ErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey	int',
				  @pnCaseKey=@pnCaseKey

End
-- Get a range of CPA related information
If  @ErrorCode=0
Begin
	Set @sSQLString="
	Select	@dtCPAStartPayDate	= isnull(CE1.EVENTDATE,CE1.EVENTDUEDATE),
		@dtCPAStopPayDate	= isnull(CE2.EVENTDATE,CE2.EVENTDUEDATE),
		@dtCPALastExtractDate	= SN.BATCHDATE,
		@nCPALastBatchNo	= SN.BATCHNO,
		@nCPAStartPayEventNo	= S1.COLINTEGER,
		@nCPAStopPayEventNo	= S2.COLINTEGER,
		@bInNextBatch		= CASE WHEN(CPA.CASEID is null) THEN 0 ELSE 1 END
	from SITECONTROL S1
	left join CASEEVENT CE1	 on (CE1.CASEID=@pnCaseKey
				and  CE1.EVENTNO=S1.COLINTEGER
				and  CE1.CYCLE=1)
	left join SITECONTROL S2 on (S2.CONTROLID='CPA Date-Stop')
	left join CASEEVENT CE2	 on (CE2.CASEID=@pnCaseKey
				and  CE2.EVENTNO=S2.COLINTEGER
				and  CE2.CYCLE=1)
	left join (select distinct CASEID
		   from CPAUPDATE) CPA	on (CPA.CASEID=@pnCaseKey)
	left join CPASEND SN	on (SN.CASEID=@pnCaseKey
				and SN.BATCHNO=(select max(SN1.BATCHNO)
						from CPASEND SN1
						where SN1.CASEID=SN.CASEID))
	Where S1.CONTROLID='CPA Date-Start'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@dtCPAStartPayDate	datetime	OUTPUT,
				  @dtCPAStopPayDate	datetime	OUTPUT,
				  @dtCPALastExtractDate	datetime	OUTPUT,
				  @nCPALastBatchNo	int		OUTPUT,
				  @nCPAStartPayEventNo	int		OUTPUT,
				  @nCPAStopPayEventNo	int		OUTPUT,
				  @bInNextBatch		bit		OUTPUT,
				  @pnCaseKey		int',
				  @dtCPAStartPayDate	=@dtCPAStartPayDate	OUTPUT,
				  @dtCPAStopPayDate	=@dtCPAStopPayDate	OUTPUT,
				  @dtCPALastExtractDate	=@dtCPALastExtractDate	OUTPUT,
				  @nCPALastBatchNo	=@nCPALastBatchNo	OUTPUT,
				  @nCPAStartPayEventNo	=@nCPAStartPayEventNo	OUTPUT,
				  @nCPAStopPayEventNo	=@nCPAStopPayEventNo	OUTPUT,
				  @bInNextBatch		=@bInNextBatch		OUTPUT,
				  @pnCaseKey		=@pnCaseKey
End

-- RenewalDetails result set.  Include the CASES table so that an empty result set is 
-- returned if the user does not have access to the Case.
If  @ErrorCode=0
and (@psResultsetsRequired = ',' or CHARINDEX('RENEWALDETAILS,', @psResultsetsRequired) <> 0)
Begin
	If @pbCalledFromCentura=1
		Set @sSQLString="		
		Select	" +
		CASE WHEN @pbCalledFromCentura = 0
		THEN 	"cast(@pnCaseKey	as nvarchar(11))			as RowKey,"
		ELSE 	""
		END + char(10) + "
		@pnCaseKey		as CaseKey,
		isnull(@dtCPARenewalDate, @dtNextRenewalDate)
				 	as NextRenewalDate,
		@dtNextQuinDate 	as NextQuinDate,
		@dtFilingDate 		as FilingDate,
		@dtRenewalStartDate 	as RenewalStartDate,
		@dtExpiryDate 		as ExpiryDate,
		-- For external users, set the IsCPARenewalDate to false if  
		-- the Clients Unaware of CPA site control is on:
		CASE When(SC.COLBOOLEAN = 1 and @pbExternalUser = 1) 
			Then 0
		     When(@dtCPARenewalDate is not null)			 
			Then 1
		     Else 0
		END			as IsCPARenewalDate,		
		@nYear 			as RenewalYear,
		@nCycle 		as Cycle,
		@sRenewalStatus		as RenewalStatus,
		@sRenewalType		as RenewalType,	
		CASE WHEN (@pbExternalUser=0) THEN @sRenewalRemarks END	
					as RenewalRemarks,	
		CASE WHEN (@pbExternalUser=0) THEN @nReportToThirdParty	END
					as ReportToThirdParty,
		CASE WHEN (@pbExternalUser=0) THEN @sStopPay END
					as StopPay,
		CASE WHEN (@pbExternalUser=0) THEN @nExtendedRenewals END
					as ExtendedRenewals,
		@dtNextRenewalDate	as InternalRenewalDate,
		@dtCPARenewalDate	as CPARenewalDate,"+char(10)+
		CASE WHEN (@pbExternalUser=0) THEN "@dtCPAStartPayDate as CPAStartPayDate," END+char(10)+					
		CASE WHEN (@pbExternalUser=0) THEN "@dtCPAStopPayDate as CPAStopPayDate," END+char(10)+						
		CASE WHEN (@pbExternalUser=0) THEN "@dtCPALastExtractDate as CPALastExtractDate," END+char(10)+							
		CASE WHEN (@pbExternalUser=0) THEN "@nCPALastBatchNo as CPALastBatchNo," END+char(10)+					
		"@nCPAStartPayEventNo	as CPAStartPayEventNo,
		@nCPAStopPayEventNo	as CPAStopPayEventNo,"+char(10)+
		CASE WHEN (@pbExternalUser=0) THEN "@bInNextBatch as InNextBatch" END+char(10)+					
		"From CASES
		left join SITECONTROL SC on (SC.CONTROLID='Clients Unaware of CPA')
		Where CASEID=@pnCaseKey"
	Else
		Set @sSQLString="		
		Select	" +
		CASE WHEN @pbCalledFromCentura = 0
		THEN 	"cast(@pnCaseKey	as nvarchar(11))			as RowKey,"
		ELSE 	""
		END + char(10) + "
		@pnCaseKey		as CaseKey,
		@sCaseStatus		as CaseStatus,
		@dtNextRenewalDate	as NextRenewalDate,
		@dtCPARenewalDate       as CPARenewalDate,
		@dtNextQuinDate 	as NextQuinDate,
		@dtFilingDate 		as FilingDate,
		@dtRenewalStartDate 	as RenewalStartDate,
		@dtExpiryDate 		as ExpiryDate,
		-- For external users, set the IsCPARenewalDate to false if  
		-- the Clients Unaware of CPA site control is on:
		CASE When(SC.COLBOOLEAN = 1 and @pbExternalUser = 1) 
			Then 0
		     When(@dtCPARenewalDate is not null)			 
			Then 1
		     Else 0
		END			as IsCPARenewalDate,		
		@nYear 			as RenewalYear,
		@nCycle 		as Cycle,
		@sRenewalStatus		as RenewalStatus,
		@nRenewalStatusKey      as RenewalStatusKey,
		@sRenewalType		as RenewalType,	
		@nRenewalTypeKey        as RenewalTypeKey,
		CASE WHEN (@pbExternalUser=0) THEN @sRenewalRemarks END	
					as RenewalRemarks,	
		CASE WHEN (@pbExternalUser=0) THEN @nReportToThirdParty	END
					as ReportToThirdParty,
		CASE WHEN (@pbExternalUser=0) THEN @sStopPay END
					as StopPay,
		CASE WHEN (@pbExternalUser=0) THEN @sStopPayCode END
					as StopPayCode,
		CASE WHEN (@pbExternalUser=0) THEN @nExtendedRenewals END
					as ExtendedRenewals,
		@dtNextRenewalDate	as InternalRenewalDate,
		@dtCPARenewalDate	as CPARenewalDate,"+char(10)+
		CASE WHEN (@pbExternalUser=0) THEN "@dtCPAStartPayDate as CPAStartPayDate," END+char(10)+					
		CASE WHEN (@pbExternalUser=0) THEN "@dtCPAStopPayDate as CPAStopPayDate," END+char(10)+						
		CASE WHEN (@pbExternalUser=0) THEN "@dtCPALastExtractDate as CPALastExtractDate," END+char(10)+							
		CASE WHEN (@pbExternalUser=0) THEN "@nCPALastBatchNo as CPALastBatchNo," END+char(10)+					
		"@nCPAStartPayEventNo	as CPAStartPayEventNo,
		@nCPAStopPayEventNo	as CPAStopPayEventNo,"+char(10)+
		CASE WHEN (@pbExternalUser=0) THEN "@bInNextBatch as InNextBatch," END+char(10)+	
		"C.LOGDATETIMESTAMP	as CaseLastModified,"+char(10)+
		"P.LOGDATETIMESTAMP	as PropertyLastModified"+char(10)+
		"From CASES C
		left join PROPERTY P on (P.CASEID = C.CASEID)
		left join SITECONTROL SC on (SC.CONTROLID='Clients Unaware of CPA')
		Where C.CASEID=@pnCaseKey"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey		int,
				  @sCaseStatus		nvarchar(50),
			 	  @dtNextRenewalDate 	datetime,
				  @dtNextQuinDate 	datetime,
			 	  @dtFilingDate 	datetime,
				  @dtRenewalStartDate 	datetime,
				  @dtExpiryDate 	datetime,
				  @dtCPARenewalDate	datetime,
				  @dtCPAStartPayDate	datetime,
				  @dtCPAStopPayDate	datetime,
				  @dtCPALastExtractDate	datetime,
				  @nYear 		smallint,
				  @nCycle 		smallint,
				  @sRenewalStatus	nvarchar(50),
				  @nRenewalStatusKey    smallint,
				  @sRenewalType		nvarchar(80),
				  @nRenewalTypeKey      int,
				  @sRenewalRemarks	nvarchar(254),
				  @nReportToThirdParty	smallint,
				  @sStopPay		nvarchar(80),
				  @sStopPayCode         nvarchar(20),
				  @nExtendedRenewals	int,
				  @pbExternalUser	bit,
				  @nCPALastBatchNo	int,
				  @nCPAStartPayEventNo	int,
				  @nCPAStopPayEventNo	int,
				  @bInNextBatch		bit',
				  @pnCaseKey		=@pnCaseKey,
				  @sCaseStatus		=@sCaseStatus,
			 	  @dtNextRenewalDate 	=@dtNextRenewalDate,
				  @dtNextQuinDate 	=@dtNextQuinDate,
			 	  @dtFilingDate 	=@dtFilingDate,
				  @dtRenewalStartDate 	=@dtRenewalStartDate,
				  @dtExpiryDate 	=@dtExpiryDate,
				  @dtCPARenewalDate	=@dtCPARenewalDate,
				  @dtCPAStartPayDate	=@dtCPAStartPayDate,
				  @dtCPAStopPayDate	=@dtCPAStopPayDate,
				  @dtCPALastExtractDate	=@dtCPALastExtractDate,
				  @nYear 		=@nYear,
				  @nCycle 		=@nCycle,
				  @sRenewalStatus	=@sRenewalStatus,
				  @nRenewalStatusKey    =@nRenewalStatusKey,
				  @sRenewalType		=@sRenewalType,
				  @nRenewalTypeKey      =@nRenewalTypeKey,
				  @sRenewalRemarks	=@sRenewalRemarks,
				  @nReportToThirdParty	=@nReportToThirdParty,
				  @sStopPay		=@sStopPay,
				  @sStopPayCode         =@sStopPayCode,
				  @nExtendedRenewals	=@nExtendedRenewals,
				  @pbExternalUser	=@pbExternalUser,
				  @nCPALastBatchNo	=@nCPALastBatchNo,
				  @nCPAStartPayEventNo	=@nCPAStartPayEventNo,
				  @nCPAStopPayEventNo	=@nCPAStopPayEventNo,
				  @bInNextBatch		=@bInNextBatch
End	

If  @ErrorCode=0 and @pbCalledFromCentura = 0
and (@psResultsetsRequired = ',' or CHARINDEX('RENEWALDATES,', @psResultsetsRequired) <> 0)
Begin
        Exec @ErrorCode = dbo.csw_ListRenewalDates 
			@pnUserIdentityId           = @pnUserIdentityId, 
			@pbExternalUser             = @pbExternalUser, 
			@psCulture                  = @psCulture, 
			@pnCaseKey                  = @pnCaseKey,
			@pbCalledFromCentura        = @pbCalledFromCentura
End

Return @ErrorCode

go

grant execute on dbo.cs_GetCaseRenewalDetails to public
go
