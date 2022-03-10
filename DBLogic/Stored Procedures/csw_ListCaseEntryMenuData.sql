-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseEntryMenuData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseEntryMenuData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseEntryMenuData.'
	Drop procedure [dbo].[csw_ListCaseEntryMenuData]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseEntryMenuData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseEntryMenuData
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey				int,		-- Mandatory	
	@psActionKey			nvarchar(2),
	@pnActionCycle			int,
	@pnCriteriaKey			int,		-- Mandatory
	@pbIncludeAll			bit		= 0
)
as
-- PROCEDURE:	csw_ListCaseEntryMenuData
-- VERSION:	12
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists Events and Entries relevant for the currently selected action in the WorkFlow Wizard.
--		( not true anymore - The logic does not take into account USERCONTROL, as a result union is used instead of union All)

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 OCT 2008	SF	RFC3392	1	Procedure created
-- 08 DEC 2008	SF	RFC7375	2	Only return case events that belongs to the current case to determine if the specific events exists.
-- 10 SEP 2009	SF	RFC8394 3	Return HasMandatorySteps to assist in determining whether Update as today button can be displayed or not.
--					Reformatted SQL to work within the 4000 characters constraint
-- 28 Oct 2010	KR	RFC9885 4	Included USERCONTROL in the sql.
-- 23 Dec 2010	MF	10130	5	Revisit of RFC9885 as the UserControl SQL was not quite correct and as a result the details associated with
--					each Entry was not being returned to indicate when an Event is cyclic or not.
-- 21 Feb 2011  KR	10250	6	Removed the left in the join to DETAILCONTROL while getting event meta data
-- 09 Feb 2011  KR	10304	7	Fix Join to USERCONTROL to use U.LOGINID instead of using NA.ALIAS
-- 25 May 2011  DV	100533  8	Replace Join to NAMEALIAS with a left join.
-- 19 Oct 2011	MF	11386	9	Logic of what Menu Entries are available for a user has been moved into function fn_EntryMenuForUserId. This
--					has significantly simplified the code in this procedure and reduced ongoing maintenance of this code now in 
--					the function.
-- 04 May 2012	ASH	R12115	10	Return Boolean value of ExistsInCase column
-- 23 Dec 2014	MF	R41842	11	Cater for the possibility of an Event within the Entry not being configured for the selected Action. This means
--					there would be no EVENTCONTROL row found for the criteria, so fall back to the EVENTS table row.
-- 07 Sep 2018	AV	74738	12	Set isolation level to read uncommited.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)
declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode 	= 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	/* Entries population -
	   the WorkBench equivalent of the Entry table in Case Detail Entry - Entry Selection window */

	Set @sSQLString = "
		Select	cast(@pnCriteriaKey as nvarchar(15)) + '^' + 
				cast(DC.ENTRYNUMBER as nvarchar(15)) 
											as RowKey,
				@pnCaseKey					as CaseKey,
				DC.ENTRYNUMBER				as EntryNumber, 
				"+dbo.fn_SqlTranslatedColumn('DETAILCONTROL','ENTRYDESC',null,'DC',@sLookupCulture,@pbCalledFromCentura)			
								+"			as EntryDescription, 
				DC. DISPLAYSEQUENCE			as DisplaySequence,  
			EM.ISDIM				as IsDim  

		from dbo.fn_EntryMenuForUserId(@pnUserIdentityId, @pnCaseKey, @psActionKey, @pnActionCycle, @pnCriteriaKey, @pbIncludeAll) EM
		join DETAILCONTROL DC	on (DC.CRITERIANO =EM.CRITERIANO
					and DC.ENTRYNUMBER=EM.ENTRYNUMBER)		 
		order by DisplaySequence, EntryNumber, EntryDescription"	

	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnCaseKey				int,		
						@pnCriteriaKey			int,
						@psActionKey		nvarchar(2),
						@pnActionCycle		int,
						@pnUserIdentityId	int,
						@pbIncludeAll		bit',
						@pnCaseKey		= @pnCaseKey,
						@pnCriteriaKey		= @pnCriteriaKey,
						@psActionKey		= @psActionKey,
						@pnActionCycle		= @pnActionCycle,
						@pnUserIdentityId	= @pnUserIdentityId,
						@pbIncludeAll		=@pbIncludeAll
End

If @nErrorCode = 0
Begin
	---------------------------------------------
	-- Return the Events to be displayed for each
	-- Entry that the user has access to
	---------------------------------------------

	Set @sSQLString = "
		Select	cast(DD.ENTRYNUMBER as nvarchar(15)) + '^' +cast(DD.EVENTNO as nvarchar(15)) 
					as RowKey,
		@pnCaseKey		as CaseKey,
		DD.ENTRYNUMBER		as EntryNumber,
		DD.EVENTNO		as EventKey,
		DD.EVENTATTRIBUTE	as EventAttribute, 
		DD.DUEATTRIBUTE		as DueAttribute,
		isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'EC',@sLookupCulture,@pbCalledFromCentura)+","
		        +dbo.fn_SqlTranslatedColumn('EVENTS',      'EVENTDESCRIPTION',null,'E' ,@sLookupCulture,@pbCalledFromCentura)+")
					as EventDescription,
		CASE WHEN(isnull(EC.NUMCYCLESALLOWED,E.NUMCYCLESALLOWED) > 1) THEN cast(1 as bit) ELSE cast(0 as bit) END	
					as 'IsCyclic',
		CASE WHEN(CE.EVENTNO is not null)  THEN cast(1 as bit) ELSE cast(0 as bit) END	
					as 'ExistsInCase',
		DD.DISPLAYSEQUENCE	as DisplaySequence,
		CASE WHEN(SC.CRITERIANO IS NULL)   THEN cast(0 as bit) ELSE cast(1 as bit) END 
					as 'HasMandatorySteps'

		from dbo.fn_EntryMenuForUserId(@pnUserIdentityId, @pnCaseKey, @psActionKey, @pnActionCycle, @pnCriteriaKey, @pbIncludeAll) DC
		join DETAILDATES DD		on (DD.CRITERIANO=DC.CRITERIANO
						and DD.ENTRYNUMBER=DC.ENTRYNUMBER)
		left join EVENTCONTROL EC	on (EC.EVENTNO = DD.EVENTNO
						and EC.CRITERIANO = DD.CRITERIANO)
		join EVENTS E			on (E.EVENTNO = DD.EVENTNO)

		left join (	select distinct CASEID, EVENTNO 
				from CASEEVENT) CE
						on (CE.EVENTNO = DD.EVENTNO 
						and CE.CASEID = @pnCaseKey)
		
		left join (	select distinct CRITERIANO, ENTRYNUMBER 
				from SCREENCONTROL 
				where MANDATORYFLAG=1) SC	
						on (SC.CRITERIANO = @pnCriteriaKey
						and SC.ENTRYNUMBER = DD.ENTRYNUMBER)
		order by DC.DISPLAYSEQUENCE, DisplaySequence, EventKey"	

	exec @nErrorCode = sp_executesql @sSQLString,
					      N'@pnCaseKey		int,		
						@pnCriteriaKey		int,
						@psActionKey		nvarchar(2),
						@pnActionCycle		int,
						@pnUserIdentityId	int,
						@pbIncludeAll		bit',
						@pnCaseKey		= @pnCaseKey,
						@pnCriteriaKey		= @pnCriteriaKey,
						@psActionKey		= @psActionKey,
						@pnActionCycle		= @pnActionCycle,
						@pnUserIdentityId	= @pnUserIdentityId,
						@pbIncludeAll		=@pbIncludeAll
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseEntryMenuData to public
GO
