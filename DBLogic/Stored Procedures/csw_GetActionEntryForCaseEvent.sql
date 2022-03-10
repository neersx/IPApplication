-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetActionEntryForCaseEvent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetActionEntryForCaseEvent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetActionEntryForCaseEvent.'
	Drop procedure [dbo].[csw_GetActionEntryForCaseEvent]
End
Print '**** Creating Stored Procedure dbo.csw_GetActionEntryForCaseEvent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetActionEntryForCaseEvent
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnCaseKey			int,		-- Mandatory	
	@pnEventKey			int,		-- Mandatory
	@pnCycle			smallint,	-- Mandatory
	@psActionKey			nvarchar(2)	= null
)
as
-- PROCEDURE:	csw_GetActionEntryForCaseEvent
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists Events and Entries relevant for the currently selected action in the WorkFlow Wizard.
--		( not true anymore - The logic does not take into account USERCONTROL, as a result union is used instead of union All)
--
-- NOTE:	See also function : fn_DoesEntryExistForCaseEvent
--		Changes to this stored procedure may need to also be applied to that function.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 11 May 2011	MF	10541	1	Procedure created
-- 17 Jun 2011	MF	10860	2	Allow Entries that just display the Event to also be returned.
--					Also give precendence to the Controlling Action of the Event.
-- 04 Jul 2011	MF	10934	3	If Entry is Dimmed or Hidden then don't allow the Event to jump to the Entry.
-- 02 Nov 2011	MF	R11458	4	Allow the creation of a hyperlink against an Action to be determined by a Site Control.
-- 09 Jan 2012	MF	R11850	5	Left Join to NAMEALIAS is not serving any purpose and has been removed. See also 11786.
-- 23 Mar 2017	MF	61729	6	Cater for new ROLESCONTROL table that can be used to indicate who has access to an Entry.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	---------------------------------------------------------
	-- Identify the Action, Cycle and Entry that is the best
	-- candidate to allow an update of a specific Case Event.
	-- If the Event is only included in an Entry with the 
	-- "display only" attribute then that Entry will be used.
	---------------------------------------------------------

	Set @sSQLString = "
		with CTE_UserEntryAccess(CRITERIANO, ENTRYNUMBER, IDENTITYID)
		as   (	------------------------
			-- Used by Client/Server
			------------------------
			select UC.CRITERIANO, UC.ENTRYNUMBER, U.IDENTITYID
			from USERIDENTITY U
			JOIN USERCONTROL UC ON (UC.USERID      = U.LOGINID)
			UNION
			--------------
			-- Used by WEB
			--------------
			Select RC.CRITERIANO, RC.ENTRYNUMBER, IR.IDENTITYID
			from ROLESCONTROL RC
			join IDENTITYROLES IR on (IR.ROLEID=RC.ROLEID)
			)

		Select  TOP 1
			E.RowKey,
			E.CaseKey,
			E.ActionKey,
			E.ActionCycle,
			E.CriteriaKey,
			E.EntryKey,
			cast(E.IsHidden as bit) as IsHidden

		from (	Select	cast(OA.CASEID	  as nvarchar(15))  + '^' + 
				OA.ACTION                           + '^' +
				cast(OA.CYCLE       as nvarchar(15)) 
									as RowKey,
				OA.CASEID				as CaseKey,
				OA.ACTION				as ActionKey,
				OA.CYCLE				as ActionCycle,
				OA.CRITERIANO				as CriteriaKey,
				DC.ENTRYNUMBER				as EntryKey,

				-----------------------------------
				-- Return a flag that indicates the
				-- Entry is hidden and will require
				-- the Include All flag to be on.
				-----------------------------------
				Case When(SHOW.EVENTNO is null and DC.DISPLAYEVENTNO is not null)
						Then 1
				     When(HIDE.EVENTNO is not null)
						Then 1
						Else 0
				End					as IsHidden,
				--------------------------------
				-- Determine the preferred Entry
				-- by considering the attributes
				-- against the Event and give a
				-- weighting.
				--------------------------------

					------------------------------
					-- Show, don't dim, don't hide
					------------------------------
				Case When(SHOW.EVENTNO is not null
				      and  DIM.EVENTNO is null
				      and HIDE.EVENTNO is null) Then '0'
					------------------------------
					-- Don't dim, don't hide
					------------------------------
				     When(SHOW.EVENTNO is null and DC.DISPLAYEVENTNO is null
				      and  DIM.EVENTNO is null
				      and HIDE.EVENTNO is null) Then '1'
					------------------------------
					-- Show,  dim, don't hide
					------------------------------
				     When(SHOW.EVENTNO is not null
				      and  DIM.EVENTNO is not null
				      and HIDE.EVENTNO is null) Then '2'
					------------------------------
					-- Dim, don't hide
					------------------------------
				     When(SHOW.EVENTNO is null and DC.DISPLAYEVENTNO is null
				      and  DIM.EVENTNO is not null
				      and HIDE.EVENTNO is null) Then '3'
					------------------------------
					-- Don't Show or Hide
					------------------------------
								Else '9'
				End+
					-------------------------------------
					-- Consider the Action in determining
					-- which Entry to select
					-------------------------------------
				Case When(OA.ACTION=@psActionKey)	 Then '0'	-- Supplied action is best choice	
				     When(OA.ACTION=E.CONTROLLINGACTION) Then '1'	-- Controlling action is next best
				     When(OA.ACTION not like '~%')	 Then '2'	-- User defined actions are next best
									 Else '9'
				End+
					-------------------------------------
					-- Now look at the attributes of the
					-- Event within the Entry
					-------------------------------------
				Case When(DD.EVENTATTRIBUTE=4)	Then '0'	-- Event Date is Defaulted to System Date
				     When(DD.EVENTATTRIBUTE=1)	Then '1'	-- Event Date is Must Enter
				     When(DD.EVENTATTRIBUTE=3)	Then '2'	-- Event Date is Optional Entry
				     When(DD.EVENTATTRIBUTE=0)	Then '3'	-- Event Date is Display Only
				     When(DD.EVENTATTRIBUTE=2)	Then '4'	-- Event Date is Hidden
				     When(DD.DUEATTRIBUTE  =4)	Then '5'	-- Due Date   is Defaulted to System Date
				     When(DD.DUEATTRIBUTE  =1)	Then '6'	-- Due Date   is Must Enter
				     When(DD.DUEATTRIBUTE  =3)	Then '7'	-- Due Date   is Optional Entry
				     When(DD.DUEATTRIBUTE  =0)	Then '8'	-- Due Date   is Display Only
								Else '9'
				End +
					--------------------------------------
					-- Finally consider the position of
					-- the Event within the Entry and then
					-- the Entry within the Action
					--------------------------------------
				cast(DD.DISPLAYSEQUENCE as char(5)) +
				cast(DC.DISPLAYSEQUENCE as char(5))	as BestFit
			From	OPENACTION OA
			join	SITECONTROL SC		on (SC.CONTROLID='Event Link to Workflow Allowed'
							and SC.COLBOOLEAN=1)
			join	ACTIONS A		on (A.ACTION=OA.ACTION)
			join	DETAILCONTROL DC	on (DC.CRITERIANO =OA.CRITERIANO)
			join	DETAILDATES DD		on (DD.CRITERIANO =DC.CRITERIANO
							and DD.ENTRYNUMBER=DC.ENTRYNUMBER)
			join	EVENTS E		on (E.EVENTNO=DD.EVENTNO)
			
			-- The user is allowed explicit
			-- access to the entry
			join	CTE_UserEntryAccess UC	on (UC.CRITERIANO  = DC.CRITERIANO
							and UC.ENTRYNUMBER = DC.ENTRYNUMBER
							and UC.IDENTITYID  = @pnUserIdentityId)

			left	JOIN CASEEVENT DIM	on (DIM.EVENTNO = DC.DIMEVENTNO  				
							and DIM.EVENTDATE IS NOT NULL  				
							and DIM.OCCURREDFLAG between 1 and 8  				
							and DIM.CYCLE  = OA.CYCLE   				
							and DIM.CASEID = OA.CASEID ) 

			left	JOIN CASEEVENT SHOW	on (SHOW.EVENTNO = DC.DISPLAYEVENTNO  				
							and SHOW.EVENTDATE IS NOT NULL  				
							and SHOW.OCCURREDFLAG between 1 and 8  				
							and SHOW.CYCLE  = OA.CYCLE   				
							and SHOW.CASEID = OA.CASEID ) 

			left	JOIN CASEEVENT HIDE	on (HIDE.EVENTNO = DC.HIDEEVENTNO  				
							and HIDE.EVENTDATE IS NOT NULL  				
							and HIDE.OCCURREDFLAG between 1 and 8  				
							and HIDE.CYCLE  = OA.CYCLE   				
							and HIDE.CASEID = OA.CASEID ) 

			where 	OA.CASEID      =@pnCaseKey
			and	OA.POLICEEVENTS=1
			and	DD.EVENTNO     =@pnEventKey
				---------------------------------------------------
				-- Only allow Entries that are not dimmed or hidden
				---------------------------------------------------
			and(SHOW.EVENTNO is not null or DC.DISPLAYEVENTNO is null)
			and  DIM.EVENTNO is null
			and HIDE.EVENTNO is null

			and   ((E.NUMCYCLESALLOWED>1 and A.NUMCYCLESALLOWED>1 and OA.CYCLE=@pnCycle)
			     OR(E.NUMCYCLESALLOWED>1 and A.NUMCYCLESALLOWED=1)
			     OR(E.NUMCYCLESALLOWED=1) )
			union all
			Select	
				cast(OA.CASEID	  as nvarchar(15))  + '^' + 
				OA.ACTION                           + '^' +
				cast(OA.CYCLE       as nvarchar(15)) 
									as RowKey,
				OA.CASEID				as CaseKey,
				OA.ACTION				as ActionKey,
				OA.CYCLE				as ActionCycle,
				OA.CRITERIANO				as CriteriaKey,
				DC.ENTRYNUMBER				as EntryKey,

				-----------------------------------
				-- Return a flag that indicates the
				-- Entry is hidden and will require
				-- the Include All flag to be on.
				-----------------------------------
				Case When(SHOW.EVENTNO is null and DC.DISPLAYEVENTNO is not null)
						Then 1
				     When(HIDE.EVENTNO is not null)
						Then 1
						Else 0
				End					as IsHidden,
				--------------------------------
				-- Determine the preferred Entry
				-- by considering the attributes
				-- against the Event and give a
				-- weighting.
				--------------------------------

					------------------------------
					-- Show, don't dim, don't hide
					------------------------------
				Case When(SHOW.EVENTNO is not null
				      and  DIM.EVENTNO is null
				      and HIDE.EVENTNO is null) Then '0'
					------------------------------
					-- Don't dim, don't hide
					------------------------------
				     When(SHOW.EVENTNO is null and DC.DISPLAYEVENTNO is null
				      and  DIM.EVENTNO is null
				      and HIDE.EVENTNO is null) Then '1'
					------------------------------
					-- Show,  dim, don't hide
					------------------------------
				     When(SHOW.EVENTNO is not null
				      and  DIM.EVENTNO is not null
				      and HIDE.EVENTNO is null) Then '2'
					------------------------------
					-- Dim, don't hide
					------------------------------
				     When(SHOW.EVENTNO is null and DC.DISPLAYEVENTNO is null
				      and  DIM.EVENTNO is not null
				      and HIDE.EVENTNO is null) Then '3'
					------------------------------
					-- Don't Show or Hide
					------------------------------
								Else '9'
				End+
					-------------------------------------
					-- Consider the Action in determining
					-- which Entry to select
					-------------------------------------
				Case When(OA.ACTION=@psActionKey)	 Then '0'	-- Supplied action is best choice	
				     When(OA.ACTION=E.CONTROLLINGACTION) Then '1'	-- Controlling action is next best
				     When(OA.ACTION not like '~%')	 Then '2'	-- User defined actions are next best
									 Else '9'
				End+
					-------------------------------------
					-- Now look at the attributes of the
					-- Event within the Entry
					-------------------------------------
				Case When(DD.EVENTATTRIBUTE=4)	Then '0'	-- Event Date is Defaulted to System Date
				     When(DD.EVENTATTRIBUTE=1)	Then '1'	-- Event Date is Must Enter
				     When(DD.EVENTATTRIBUTE=3)	Then '2'	-- Event Date is Optional Entry
				     When(DD.EVENTATTRIBUTE=0)	Then '3'	-- Event Date is Display Only
				     When(DD.EVENTATTRIBUTE=2)	Then '4'	-- Event Date is Hidden
				     When(DD.DUEATTRIBUTE  =4)	Then '5'	-- Due Date   is Defaulted to System Date
				     When(DD.DUEATTRIBUTE  =1)	Then '6'	-- Due Date   is Must Enter
				     When(DD.DUEATTRIBUTE  =3)	Then '7'	-- Due Date   is Optional Entry
				     When(DD.DUEATTRIBUTE  =0)	Then '8'	-- Due Date   is Display Only
								Else '9'
				End +
					--------------------------------------
					-- Finally consider the position of
					-- the Event within the Entry and then
					-- the Entry within the Action
					--------------------------------------
				cast(DD.DISPLAYSEQUENCE as char(5)) +
				cast(DC.DISPLAYSEQUENCE as char(5))	as BestFit
			From	OPENACTION OA
			join	SITECONTROL SC		on (SC.CONTROLID='Event Link to Workflow Allowed'
							and SC.COLBOOLEAN=1)
			join	ACTIONS A		on (A.ACTION=OA.ACTION)
			join	DETAILCONTROL DC	on (DC.CRITERIANO =OA.CRITERIANO)
			join	DETAILDATES DD		on (DD.CRITERIANO =DC.CRITERIANO
							and DD.ENTRYNUMBER=DC.ENTRYNUMBER) 
			join	EVENTS E		on (E.EVENTNO=DD.EVENTNO)

			left	JOIN CASEEVENT DIM	on (DIM.EVENTNO = DC.DIMEVENTNO  				
							and DIM.EVENTDATE IS NOT NULL  				
							and DIM.OCCURREDFLAG between 1 and 8  				
							and DIM.CYCLE  = OA.CYCLE   				
							and DIM.CASEID = OA.CASEID ) 

			left	JOIN CASEEVENT SHOW	on (SHOW.EVENTNO = DC.DISPLAYEVENTNO  				
							and SHOW.EVENTDATE IS NOT NULL  				
							and SHOW.OCCURREDFLAG between 1 and 8  				
							and SHOW.CYCLE  = OA.CYCLE   				
							and SHOW.CASEID = OA.CASEID ) 

			left	JOIN CASEEVENT HIDE	on (HIDE.EVENTNO = DC.HIDEEVENTNO  				
							and HIDE.EVENTDATE IS NOT NULL  				
							and HIDE.OCCURREDFLAG between 1 and 8  				
							and HIDE.CYCLE  = OA.CYCLE   				
							and HIDE.CASEID = OA.CASEID ) 
			where 	OA.CASEID      =@pnCaseKey
			and	OA.POLICEEVENTS=1
			and	DD.EVENTNO     =@pnEventKey
				---------------------------------------------------
				-- Only allow Entries that are not dimmed or hidden
				---------------------------------------------------
			and(SHOW.EVENTNO is not null or DC.DISPLAYEVENTNO is null)
			and  DIM.EVENTNO is null
			and HIDE.EVENTNO is null

			and   ((E.NUMCYCLESALLOWED>1 and A.NUMCYCLESALLOWED>1 and OA.CYCLE=@pnCycle)
			     OR(E.NUMCYCLESALLOWED>1 and A.NUMCYCLESALLOWED=1)
			     OR(E.NUMCYCLESALLOWED=1) )
				-----------------------
				-- No user restrictions
				-----------------------
			AND NOT EXISTS
			(select 1 from CTE_UserEntryAccess UC
			 where UC.CRITERIANO=DC.CRITERIANO
			 and   UC.ENTRYNUMBER=DC.ENTRYNUMBER)
		) E		 
		order by E.BestFit"	

	exec @nErrorCode = sp_executesql @sSQLString,
				      N'@pnCaseKey			int,		
					@pnEventKey			int,
					@pnUserIdentityId		int,
					@pnCycle			smallint,
					@psActionKey			nvarchar(2)',
					@pnCaseKey			= @pnCaseKey,
					@pnEventKey			= @pnEventKey,
					@pnUserIdentityId		= @pnUserIdentityId,
					@pnCycle			= @pnCycle,
					@psActionKey			= @psActionKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetActionEntryForCaseEvent to public
GO
