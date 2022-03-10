-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_DoesEntryExistForCaseEvent
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_DoesEntryExistForCaseEvent') and xtype='FN')
begin
	print '**** Drop function dbo.fn_DoesEntryExistForCaseEvent.'
	drop function dbo.fn_DoesEntryExistForCaseEvent
	print '**** Creating function dbo.fn_DoesEntryExistForCaseEvent...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_DoesEntryExistForCaseEvent
		      (	@pnUserIdentityId		int,		-- Mandatory
			@pnCaseKey			int,		-- Mandatory	
			@pnEventKey			int,		-- Mandatory
			@pnCycle			smallint	-- Mandatory
			)		
RETURNS BIT
-- FUNCTION :	fn_DoesEntryExistForCaseEvent
-- VERSION :	5
-- DESCRIPTION:	For a given CaseEvent row and a specific user, the function will indicate
--		whether a Workflow Wizard Entry exists that will allow the Event to be updated.
--		Details of the actual Action and Entry can  then be provided by calling the
--		stored procedure csw_GetActionEntryForCaseEvent.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 May 2011	MF	10541	1	Function created
-- 17 Jun 2011	MF	10860	2	Allow Entries that just display the Event to also be returned.
-- 04 Jul 2011	MF	10934	3	If Entry is Dimmed or Hidden then don't allow the Event to jump to the Entry.
-- 09 Jan 2012	MF	R11768	4	Left Join to NAMEALIAS is not serving any purpose and has been removed.
-- 23 Mar 2017	MF	61729	5	Cater for new ROLESCONTROL table that can be used to indicate who has access to an Entry.

as
Begin
	Declare @bEntryExists	bit

	Set @bEntryExists=0

	----------------------------------------
	-- Check if the CaseEvent can be updated
	-- through an Entry with no security
	----------------------------------------
	;with CTE_UserEntryAccess(CRITERIANO, ENTRYNUMBER, IDENTITYID)
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
	Select	@bEntryExists=cast(1 as bit)
	From	OPENACTION OA
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

	If @bEntryExists=0
	Begin
		----------------------------------------
		-- Check if the CaseEvent can be updated
		-- through an Entry that is restricted
		-- but the user has access to it.
		----------------------------------------
		;with CTE_UserEntryAccess(CRITERIANO, ENTRYNUMBER, IDENTITYID)
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
		Select	@bEntryExists=cast(1 as bit)
		From	OPENACTION OA
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
		-------------------------------
		-- The user is allowed explicit
		-- access to the entry
		-------------------------------
		join	CTE_UserEntryAccess UC	on (UC.CRITERIANO  = DC.CRITERIANO
						and UC.ENTRYNUMBER = DC.ENTRYNUMBER
						and UC.IDENTITYID  = @pnUserIdentityId)	

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
	End

	Return @bEntryExists
End
go

grant execute on dbo.fn_DoesEntryExistForCaseEvent to public
go