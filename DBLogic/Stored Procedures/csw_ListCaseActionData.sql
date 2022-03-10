-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseActionData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseActionData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseActionData.'
	Drop procedure [dbo].[csw_ListCaseActionData]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseActionData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseActionData
(
	@pnRowCount				int		= null output,	
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnCaseKey				int,
	@psActionKey				nvarchar(2)	= null,
	@pbIsActionTab				bit		= 0,
	@pnScreenCriteriaKey			int		= null,
	@pnImportanceLevel			int		= null	-- the Action importance level, if null then default for user will be found.
)
as
-- PROCEDURE:	csw_ListCaseActionData
-- VERSION:	15
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populates CaseActionData dataset.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 04 Jan 2006	TM	R3279	1	Procedure created
-- 23 Oct 2008	SF	R3392	2	Indicate whether the action is cyclic or otherwise.
-- 02 Sep 2009	KR	R6950	3	Modified to handle actions not yet created.
-- 21 Sep 2009	KR	R6950	4	added new parameter @pbIsActionTab
-- 21 Sep 2009  LP      R8047	5	Pass ProfileKey parameter to fn_GetCriteriaNo 
-- 30 Dec 2009	MS	R8649	6	Add IsDefault column in result and parameter @pnScreenCriteriaKey 
--					and added policing if default action already not policed for the case	     
-- 28 Jun 2010	LP	R9310	7	Return IsDefault as bit column
-- 09 Jul 2010	MF	R9310	8	Return a column to indicate that a CaseEvent for the Action has Text against it.
-- 12 Jul 2010	LP	R9310	9	Change order by to POLICEEVENTS, DISPLAYSEQUENCE then CYCLE
-- 19 Oct 2011	MF	R11386	10	If no Entries are to be displayed for the user then do not display the Action. 
-- 24 Oct 2011	ASH	R11460  11	Cast integer columns as nvarchar(11) data type.
-- 03 Nov 2011	LP	R11386	12	Do not suppress Actions for Actions topic.
-- 08 Nov 2011	MF	R11397	13	Only show Actions whose IMPORTANCELEVEL is greater than or equal to that of the user.
-- 16 Aug 2016	MF	65506	14	Unexplained performance issue on first execution of this stored procedure after restoration
--					of database. Addressed by recoding the problem SELECT using a CTE.
-- 07 Sep 2018	AV	74738	15	Set isolation level to read uncommited.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

Declare	@nErrorCode		int
Declare @nProfileKey		int
Declare @sSQLString 		nvarchar(max)
Declare @sLookupCulture		nvarchar(10)
Declare @sDefaultAction		nvarchar(2)

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

---------------------------------------
-- Now get the importance level used
-- to determine which Actions should be
-- displayed as well as the ProfileKey
---------------------------------------
If @nErrorCode=0
Begin
        Set @sSQLString = "
		select	@nProfileKey      = U.PROFILEID,
			@pnImportanceLevel = coalesce(@pnImportanceLevel, convert(int,PA.ATTRIBUTEVALUE), isnull(S.COLINTEGER,0))
		from USERIDENTITY U
		left join SITECONTROL S		on (S.CONTROLID=CASE WHEN(U.ISEXTERNALUSER=1) THEN 'Client Importance' ELSE 'Events Displayed' END )
		left join PROFILEATTRIBUTES PA	on (PA.PROFILEID = U.PROFILEID 
						and PA.ATTRIBUTEID = 1)
		where U.IDENTITYID = @pnUserIdentityId"

        exec @nErrorCode = sp_executesql @sSQLString,
				N'@nProfileKey		int	OUTPUT,
				  @pnImportanceLevel	int	OUTPUT,
				  @pnUserIdentityId	int',
				  @nProfileKey		= @nProfileKey		OUTPUT,
				  @pnImportanceLevel	= @pnImportanceLevel	OUTPUT,
				  @pnUserIdentityId	= @pnUserIdentityId
End

-- Get the Default Action from given Crieteria
If  @nErrorCode = 0
and @pnScreenCriteriaKey is not null
Begin
        Set @sSQLString = "
		Select @sDefaultAction = FILTERVALUE
		from TOPICDEFAULTSETTINGS
		where CRITERIANO = @pnScreenCriteriaKey
		and FILTERNAME = 'CaseAction'"

	exec @nErrorCode = sp_executesql @sSQLString,
			N'@sDefaultAction	nvarchar(2)	OUTPUT,
			  @pnScreenCriteriaKey	int',
			  @sDefaultAction	= @sDefaultAction OUTPUT,
			  @pnScreenCriteriaKey	= @pnScreenCriteriaKey       
        
End

If @nErrorCode = 0
Begin
	if (@psActionKey ='' or @psActionKey is null)
	Begin
		Set @sSQLString = "
		With CTE_EventText (CASEID, CRITERIANO)
		as (	select distinct CET.CASEID, EC.CRITERIANO
			from CASEEVENTTEXT CET
			join EVENTCONTROL EC on (EC.EVENTNO=CET.EVENTNO)
		   )
		Select 
		CAST(O.CASEID as nvarchar(11))+'^'+ 
		O.ACTION+'^'+
		CAST(CYCLE as nvarchar(5))
				as 'RowKey',
		O.CASEID	as 'CaseKey',
		O.ACTION	as 'ActionKey',
		isnull("+dbo.fn_SqlTranslatedColumn('VALIDACTION','ACTIONNAME',null,'VA',@sLookupCulture,@pbCalledFromCentura)+",
			   "+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,@pbCalledFromCentura)+")
	     			as 'ActionName',
		O.CYCLE		as 'Cycle', 
		CASE	WHEN O.POLICEEVENTS = 1
			THEN CAST(1 as bit)
			ELSE CAST(0 as bit)
		END		as 'IsOpen',
		CASE WHEN A.NUMCYCLESALLOWED > 1 THEN cast(1 as bit) ELSE cast(0 as bit) END as 'IsCyclic',
		CASE WHEN ISNULL(@sDefaultAction,'') = O.ACTION THEN cast(1 as bit) ELSE cast(0 as bit) END as 'IsDefault',"

		if (@pbIsActionTab=1)
			Set @sSQLString = @sSQLString + " CASE WHEN O.POLICEEVENTS = 0 THEN '(closed action) ' ELSE '' END + O.STATUSDESC	as 'StatusDescription',"
		else
			Set @sSQLString = @sSQLString + "O.STATUSDESC	as 'StatusDescription',"

		Set @sSQLString = @sSQLString + " 				
		O.CRITERIANO	as 'CriteriaKey',
		CAST(isnull(ET.CRITERIANO,0) as bit) as 'EventTextExists'
		from OPENACTION O
		join CASES C		on (C.CASEID = O.CASEID)
		join ACTIONS A		on (A.ACTION = O.ACTION
					and A.IMPORTANCELEVEL>=@pnImportanceLevel)
		join VALIDACTION VA	on (VA.ACTION = O.ACTION
					and VA.CASETYPE = C.CASETYPE
					and VA.PROPERTYTYPE = C.PROPERTYTYPE
					and VA.COUNTRYCODE = (	select min(VA1.COUNTRYCODE)
								from VALIDACTION VA1
								where VA1.CASETYPE = VA.CASETYPE
								and VA1.PROPERTYTYPE = VA.PROPERTYTYPE
								and VA1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
		left join CTE_EventText	ET on (ET.CASEID    =O.CASEID
					   and ET.CRITERIANO=O.CRITERIANO)					
		where O.CASEID = @pnCaseKey" +char(10)+
		CASE WHEN @pbIsActionTab<>1 THEN
		-----------------------------------------------
		-- RFC11386 Workflow Wizard only
		-- Only return an Action if the user is allowed
		-- to select menu entries for that Action.
		-----------------------------------------------
		"and exists (	select 1
				from  dbo.fn_EntryMenuForUserId(@pnUserIdentityId, @pnCaseKey, O.ACTION, O.CYCLE, O.CRITERIANO, 1))" ELSE NULL END 
		+char(10)+
		"order by  "
		
		if (@pbIsActionTab=1)
			Set @sSQLString = @sSQLString + "O.POLICEEVENTS  DESC, VA.DISPLAYSEQUENCE, CYCLE"

		else
			Set @sSQLString = @sSQLString + "VA.COUNTRYCODE ASC, ActionName ASC"
		
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnUserIdentityId	int,
					  @pnCaseKey		int,
					  @pnImportanceLevel	int,
					  @sDefaultAction	nvarchar(2)',
					  @pnUserIdentityId	= @pnUserIdentityId,
					  @pnCaseKey		= @pnCaseKey,
					  @pnImportanceLevel	= @pnImportanceLevel,
					  @sDefaultAction	= @sDefaultAction
	End
	Else Begin
		Set @sSQLString = "
		Select 
		CAST(@pnCaseKey as nvarchar(11))+'^'+ 
		@psActionKey+'^'+
		CAST(1 as nvarchar(5))
				as 'RowKey',
		@pnCaseKey	as 'CaseKey',
		@psActionKey	as 'ActionKey',
		"+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'A',@sLookupCulture,@pbCalledFromCentura)+"
	     			as 'ActionName',
		1		as 'Cycle', 
		0		as 'IsOpen',
		CASE WHEN A.NUMCYCLESALLOWED > 1 THEN cast(1 as bit) ELSE cast(0 as bit) END as 'IsCyclic',
		CASE WHEN ISNULL(@sDefaultAction,'') = @psActionKey THEN cast(1 as bit) ELSE cast(0 as bit) END as 'IsDefault',
		NULL	as 'StatusDescription',	
		dbo.fn_GetCriteriaNo(@pnCaseKey,'E',@psActionKey, getdate(), @nProfileKey)	as 'CriteriaKey',
		0		as 'EventTextExists'
		from  ACTIONS A
		where A.ACTION = @psActionKey
		and   A.IMPORTANCELEVEL >= @pnImportanceLevel)"
		
		exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnCaseKey		int,
					  @psActionKey		nvarchar(2),
					  @nProfileKey		int,
					  @pnImportanceLevel	int,
					  @sDefaultAction	nvarchar(2)',
					  @pnCaseKey		= @pnCaseKey,
					  @psActionKey		= @psActionKey,
					  @nProfileKey		= @nProfileKey,
					  @pnImportanceLevel	= @pnImportanceLevel,
					  @sDefaultAction	= @sDefaultAction
	End

	Set @pnRowCount = @@RowCount
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseActionData to public
GO