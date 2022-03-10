-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_EntryMenuForUserId
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_EntryMenuForUserId') and xtype='TF')
begin
	print '**** Drop function dbo.fn_EntryMenuForUserId.'
	drop function dbo.fn_EntryMenuForUserId
	print '**** Creating function dbo.fn_EntryMenuForUserId...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_EntryMenuForUserId
			(@pnUserIdentityId		int,		-- the specific user the Events are required for
			 @pnCaseKey			int,		-- Mandatory	
			 @psActionKey			nvarchar(2),	-- Mandatory	
			 @pnActionCycle			int,		-- Mandatory	
			 @pnCriteriaKey			int		= null,
			 @pbIncludeAll			bit		= 0
			)
RETURNS @tbDetailControl TABLE
   (
	CRITERIANO		int		NOT NULL,
	ENTRYNUMBER		smallint	NOT NULL,
        ENTRYDESC		nvarchar(100)	collate database_default NULL,
        DISPLAYSEQUENCE		smallint	NOT NULL,
        ISDIM			bit		NOT NULL
   )


-- FUNCTION :	fn_EntryMenuForUserId
-- VERSION :	4
-- DESCRIPTION:	This function will return the Menu Entries associated with an Action for a given Case.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 19 Oct 2011	MF	R11386	1	Function created
-- 05 Jan 2012	MF	R11687	2	The ENTRYDESC column is allowed to be NULL.
-- 09 Jan 2012	MF	R11768	3	Left Join to NAMEALIAS is not serving any purpose and has been removed.
-- 23 Mar 2017	MF	61729	4	Cater for new ROLESCONTROL table that can be used to indicate who has access to an Entry.

as
Begin

If @pnCriteriaKey is null
Begin
	-----------------------------------------
	-- If the CriteriaKey has not been passed
	-- as a parameter then extract it from 
	-- the OpenAction table
	-----------------------------------------
	Select @pnCriteriaKey=CRITERIANO
	from OPENACTION
	where CASEID=@pnCaseKey
	and ACTION=@psActionKey
	and CYCLE =@pnActionCycle
End

If @pnCriteriaKey is not null
Begin
	If @pbIncludeAll=1
	Begin
		-----------------------------------------
		-- When all Menu Entry items are required
		-- then ignore the rules that check for 
		-- the existence of other Events.
		-----------------------------------------
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
		Insert into @tbDetailControl(CRITERIANO, ENTRYNUMBER, ENTRYDESC, DISPLAYSEQUENCE, ISDIM)
		Select	DC.CRITERIANO,
			DC.ENTRYNUMBER,
			DC.ENTRYDESC,
			DC.DISPLAYSEQUENCE,
			CASE WHEN (DIM.EVENTDATE is not null) THEN 1 ELSE 0 END

		from DETAILCONTROL DC  
		-------------------------------
		-- The user is allowed explicit
		-- access to the entry
		-------------------------------
		join	CTE_UserEntryAccess UC	on (UC.CRITERIANO  = DC.CRITERIANO
						and UC.ENTRYNUMBER = DC.ENTRYNUMBER
						and UC.IDENTITYID  = @pnUserIdentityId)	
				
		left	JOIN CASEEVENT DIM	on (DIM.EVENTNO = DC.DIMEVENTNO  				
						and DIM.EVENTDATE IS NOT NULL  				
						and DIM.OCCURREDFLAG between 1 and 8  				
						and DIM.CYCLE  = @pnActionCycle   				
						and DIM.CASEID = @pnCaseKey )  
		where 	DC.CRITERIANO = @pnCriteriaKey
		UNION
		Select	DC.CRITERIANO,
			DC.ENTRYNUMBER,
			DC.ENTRYDESC,
			DC.DISPLAYSEQUENCE,
			CASE WHEN (DIM.EVENTDATE is not null) THEN 1 ELSE 0 END
		from 	DETAILCONTROL DC  
		left	join CASEEVENT DIM	on (DIM.EVENTNO = DC.DIMEVENTNO  				
						and DIM.EVENTDATE IS NOT NULL  				
						and DIM.OCCURREDFLAG between 1 and 8  				
						and DIM.CYCLE  = @pnActionCycle   				
						and DIM.CASEID = @pnCaseKey )

		left	join CASEEVENT SHOW	on (SHOW.EVENTNO = DC.DISPLAYEVENTNO   				
						and SHOW.EVENTDATE IS NOT NULL  				
						and SHOW.OCCURREDFLAG between 1 and 8  				
						and SHOW.CYCLE  = @pnActionCycle   				
						and SHOW.CASEID = @pnCaseKey )  
		where 	DC.CRITERIANO = @pnCriteriaKey
		AND NOT EXISTS
		(select 1 from CTE_UserEntryAccess UC
		 where UC.CRITERIANO =DC.CRITERIANO
		 and   UC.ENTRYNUMBER=DC.ENTRYNUMBER)
	End
	Else Begin
		-----------------------------------------
		-- Only display those Menu Entries that
		-- are eligible to show based on the  
		-- the existence or non existence of 
		-- specific Events.
		-----------------------------------------
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
		Insert into @tbDetailControl(CRITERIANO, ENTRYNUMBER, ENTRYDESC, DISPLAYSEQUENCE, ISDIM)
		Select	DC.CRITERIANO,
			DC.ENTRYNUMBER,
			DC.ENTRYDESC,
			DC.DISPLAYSEQUENCE,
			CASE WHEN (DIM.EVENTDATE is not null) THEN 1 ELSE 0 END
		from DETAILCONTROL DC  
		-------------------------------
		-- The user is allowed explicit
		-- access to the entry
		-------------------------------
		join	CTE_UserEntryAccess UC	on (UC.CRITERIANO  = DC.CRITERIANO
						and UC.ENTRYNUMBER = DC.ENTRYNUMBER
						and UC.IDENTITYID  = @pnUserIdentityId)	
				
		left	JOIN CASEEVENT DIM	on (DIM.EVENTNO = DC.DIMEVENTNO  				
						and DIM.EVENTDATE IS NOT NULL  				
						and DIM.OCCURREDFLAG between 1 and 8  				
						and DIM.CYCLE  = @pnActionCycle   				
						and DIM.CASEID = @pnCaseKey )  
		where 	DC.CRITERIANO = @pnCriteriaKey
		and		(exists (	Select	1  		
						from	CASEEVENT SHOW  		
						where	SHOW.EVENTNO = DC.DISPLAYEVENTNO  		
						and		SHOW.EVENTDATE IS NOT NULL  		
						and		SHOW.OCCURREDFLAG between 1 and 8  		
						and		SHOW.CYCLE  = @pnActionCycle  		
						and		SHOW.CASEID = @pnCaseKey )  
				or	DC.DISPLAYEVENTNO is null)  
		and		(not exists (	Select 1  		
						from	CASEEVENT HIDE  		
						where	HIDE.EVENTNO = DC.HIDEEVENTNO  		
						and		HIDE.EVENTDATE IS NOT NULL  		
						and		HIDE.OCCURREDFLAG between 1 and 8  		
						and		HIDE.CYCLE  = @pnActionCycle   		
						and		HIDE.CASEID = @pnCaseKey)  	
				or DIM.EVENTDATE is not null)
		UNION    
		Select	DC.CRITERIANO,
			DC.ENTRYNUMBER,
			DC.ENTRYDESC,
			DC.DISPLAYSEQUENCE,
			CASE WHEN (DIM.EVENTDATE is not null) THEN 1 ELSE 0 END 
		from 	DETAILCONTROL DC  
		left	join CASEEVENT DIM	on (DIM.EVENTNO = DC.DIMEVENTNO  				
						and DIM.EVENTDATE IS NOT NULL  				
						and DIM.OCCURREDFLAG between 1 and 8  				
						and DIM.CYCLE  = @pnActionCycle   				
						and DIM.CASEID = @pnCaseKey )  
		left	join CASEEVENT SHOW	on (SHOW.EVENTNO = DC.DISPLAYEVENTNO   				
						and SHOW.EVENTDATE IS NOT NULL  				
						and SHOW.OCCURREDFLAG between 1 and 8  				
						and SHOW.CYCLE  = @pnActionCycle   				
						and SHOW.CASEID = @pnCaseKey )  
		where 	DC.CRITERIANO = @pnCriteriaKey
		and	(SHOW.EVENTNO is not null or DC.DISPLAYEVENTNO is null)  
		and	(not exists (	Select	1  		
					from	CASEEVENT HIDE  		
					where	HIDE.EVENTNO = DC.HIDEEVENTNO  		
					and		HIDE.EVENTDATE IS NOT NULL  		
					and		HIDE.OCCURREDFLAG between 1 and 8  		
					and		HIDE.CYCLE  = @pnActionCycle  		
					and		HIDE.CASEID = @pnCaseKey)  	
				or DIM.EVENTDATE is not null)
		AND NOT EXISTS
		(select 1 from CTE_UserEntryAccess UC
		 where UC.CRITERIANO =DC.CRITERIANO
		 and   UC.ENTRYNUMBER=DC.ENTRYNUMBER)
	End 
End
		
Return

End
go

grant REFERENCES, SELECT on dbo.fn_EntryMenuForUserId to public
GO
