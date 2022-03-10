-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListRenewalDates
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListRenewalDates]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListRenewalDates.'
	Drop procedure [dbo].[csw_ListRenewalDates]
	Print '**** Creating Stored Procedure dbo.csw_ListRenewalDates...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.csw_ListRenewalDates
(
	@pnRowCount		int		= null 	output,
	@pnUserIdentityId	int,			-- Mandatory
	@pbExternalUser	        bit		= null,	-- external user flag if already known
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int,			-- Mandatory
	@pbCalledFromCentura	bit = 0
)
as
-- PROCEDURE:	csw_ListRenewalDates
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns details of the Events the user is allowed to see that are due.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 05 Sep 2012  MS		1	Procedure created
-- 07 Sep 2018	AV	74738	2	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Create table #TEMPRESULTS (
		CaseKey			int		NOT NULL,
		EventDescription	nvarchar(100)	collate database_default NULL,
		EventDefinition         nvarchar(254)	collate database_default NULL,
		DisplayDate		datetime	NULL,
		DisplaySequence		smallint	NULL,
		RowKey			char(11)	collate database_default NULL,
		EventKey                int             NULL
		)

Declare @ErrorCode 			int

Declare @sSQLString			nvarchar(max)
Declare @sAction			nvarchar(3)
Declare @nCriteriaNo			int
Declare	@dtNextRenewalDate		datetime
Declare @dtCPARenewalDate		datetime
Declare @nProfileKey                    int
Declare @sLookupCulture		        nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@ErrorCode      = 0
Set 	@pnRowCount	= 0

-- If the IsExternalUser flag has not been passed as a parameter then determine it 
-- by looking up the USERIDENTITY table

If  @pbExternalUser is null
and @ErrorCode=0
Begin
	Set @sSQLString="
	Select	@pbExternalUser=ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID=@pnUserIdentityId"

	exec @ErrorCode=sp_executesql @sSQLString,
		N'@pbExternalUser		bit	Output,
		  @pnUserIdentityId		int',
		  @pbExternalUser               = @pbExternalUser	Output,
		  @pnUserIdentityId             = @pnUserIdentityId
End

-- Get the Site Control that will provide the Action that will identify the renewal Events
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @sAction=COLCHARACTER
	from SITECONTROL
	where CONTROLID='Renewal Display Action Code'"

	Exec @ErrorCode=sp_executesql @sSQLString,
		N'@sAction		nvarchar(3)	Output',
		  @sAction		=@sAction	Output
End

-- Get the ProfileKey for the current user
If @ErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId

        Set @ErrorCode = @@ERROR
End


-- Now get the CriteriaNo for the Action and Case
If  @ErrorCode=0
and @sAction is not null
Begin
	Select @nCriteriaNo=dbo.fn_GetCriteriaNo(@pnCaseKey, 	-- the Case
						'E', 		-- Purpose Code of the criteria
						@sAction, 	-- the Action of the Criteria
						getdate(),	-- Current date required for date of law
						@nProfileKey    -- ProfileKey of the Criteria
						)
End

-- If the Next Renewal Date is one of the Events that is required as a Renewal display Event
-- then it will be extracted separately as it has some specific processing to get it.
If @ErrorCode=0
and exists(select 1 from EVENTCONTROL where EVENTNO=-11 and CRITERIANO=@nCriteriaNo)
Begin
	Exec @ErrorCode=dbo.cs_GetNextRenewalDate
					@pnCaseKey=@pnCaseKey,
					@pdtNextRenewalDate=@dtNextRenewalDate 	output,
					@pdtCPARenewalDate=@dtCPARenewalDate	output
End

If @ErrorCode=0
Begin
	Set @sSQLString="insert into #TEMPRESULTS (CaseKey,EventDescription,EventDefinition,DisplayDate,DisplaySequence,RowKey,EventKey)"

	Set @sSQLString=@sSQLString+char(10)+
	"Select "+char(10)+
	"@pnCaseKey 	as CaseKey,"+char(10)+
	dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"		as EventDescription,"+char(10)+
	dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura)+char(10)+
	"		as EventDefinition,"+char(10)+
	"CASE When(EC.EVENTNO=-11)"+char(10)+
	"	Then isnull(@dtCPARenewalDate,@dtNextRenewalDate)"+char(10)+
	--"     When(EC.EVENTNO=@nPriorityEventNo)"+char(10)+
	--"	Then @dtEarliestPriorityDate"+char(10)+
	"	Else ISNULL(CE.EVENTDATE, CE.EVENTDUEDATE)"+char(10)+
	"END		as [Date],"+char(10)+
	"EC.DISPLAYSEQUENCE as DisplaySequence,"+char(10)+
	"convert(char(11),EC.EVENTNO) as RowKey,"+char(10)+
	"EC.EVENTNO as EventKey"+char(10)+
	"from EVENTCONTROL EC"+
	-- If the user is an External User then require an additional join to the Filtered Events to
	-- ensure the user has access
	CASE WHEN @pbExternalUser = 1 
	     THEN CHAR(10)+"	join dbo.fn_FilterUserEvents(@pnUserIdentityId,@sLookupCulture,1,@pbCalledFromCentura) FE"+CHAR(10)+
			   "			on (FE.EVENTNO = EC.EVENTNO)"+CHAR(10)			   
	END+	
	"     join EVENTS E	on (E.EVENTNO=EC.EVENTNO)"+char(10)+
	"left join CASEEVENT CE	on (CE.CASEID=@pnCaseKey"+char(10)+
	"	and CE.EVENTNO=EC.EVENTNO"+char(10)+
	"	and CE.CYCLE=1)"+char(10)+
	"where EC.CRITERIANO=@nCriteriaNo"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@dtCPARenewalDate		datetime,
				  @dtNextRenewalDate		datetime,
				  @pnUserIdentityId		int,				 
				  @sLookupCulture		nvarchar(10),
				  @pbCalledFromCentura		bit,				  
				  @nCriteriaNo			int,
				  @pnCaseKey			int',
				  @dtCPARenewalDate		=@dtCPARenewalDate,
				  @dtNextRenewalDate		=@dtNextRenewalDate,
				  @pnUserIdentityId		=@pnUserIdentityId,				
				  @sLookupCulture		=@sLookupCulture,
				  @pbCalledFromCentura	   	=@pbCalledFromCentura,		  
				  @nCriteriaNo			=@nCriteriaNo,
				  @pnCaseKey			=@pnCaseKey

End

If @ErrorCode=0
Begin
	Set @sSQLString="
		select	top 6
		        T1.CaseKey		as CaseKey,
			T1.EventDescription 	as EventDescription,
			T1.EventDefinition      as EventDefinition,
			T1.DisplayDate      	as [Date],
			T1.RowKey           	as RowKey,
			T1.EventKey             as EventKey
		from #TEMPRESULTS T1
		left join #TEMPRESULTS T2 on (T2.CaseKey =T1.CaseKey
					  and T2.EventKey=T1.EventKey
					  and T2.DisplaySequence<T1.DisplaySequence)
		where T2.CaseKey is null
		and T1.DisplayDate is not null
		order by T1.DisplaySequence"

	Exec @ErrorCode=sp_executesql @sSQLString

	Set @pnRowCount=@@Rowcount
End

-- Return an empty result set if the ErrorCode was set to -1 which indicates the
-- user does not have access to the Case.

If @ErrorCode=-1
Begin
	Select	null	as CaseKey,
		null	as EventDescription,
		null    as EventDefinition,
		null	as [Date],
		null	as RowKey,
		null    as EventKey
	where 1=0

	Set @ErrorCode=0
End


Return @ErrorCode
GO

Grant execute on dbo.csw_ListRenewalDates to public
GO
