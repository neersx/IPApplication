-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_NamesEthicalWall
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_NamesEthicalWall') and xtype in ('IF','TF'))
begin
	print '**** Drop function dbo.fn_NamesEthicalWall.'
	drop function dbo.fn_NamesEthicalWall
end
print '**** Creating function dbo.fn_NamesEthicalWall...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_NamesEthicalWall
			(@pnUserIdentityId	int	-- Mandatory User Identity of the logged on user
			)

RETURNS TABLE


-- FUNCTION :	fn_NamesEthicalWall
-- VERSION :	3
-- DESCRIPTION:	This function returns Names that have one or more Names associated by a RELATIONSHIP that is 
--		flagged as an Ethical Wall restriction. 
--		ETHICALWALL=1 
--		Indicates the user associated with the Name that are allowed access to the Name. Other users are NOT ALLOWED access.
--		ETHICALWALL=2
--		Indicates the user associated with the Name that are denied access to the Name. Other users are ALLOWED access.
--
--		The logic for determining if a user has access to a Name follows the following order of precedence:
--		1. No restrictions defined	Access ALLOWED
--		2. User explicitly allowed	Access ALLOWED
--		3. User explicitly denied	Access DENIED
--		4. Related user allowed		Access ALLOWED
--		5. Related user denied		Access DENIED
--		6. Allowed rule configured	Access DENIED  because user is not directly or indirectly specifed
--		7. Denied rule configured	Access ALLOWED because user is not directly or indirectly specifed

-- EXAMPLE:	The following returns all of the Names that the user linked to IDENTITYID 26 is allowed access to.
--		Select *
--		from dbo.fn_NamesEthicalWall(26)


-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 12 Apr 2016	MF	13471	1	Function created
-- 16 May 2016	MF	13471	2	Problem with access from associated name.
-- 20 May 2016	MF	61880	3	Exclude external users


as RETURN
	(
	With NameAccess (NAMENO, ALLOWEDRULE, DENIEDRULE, USERALLOWED, USERDENIED, RELATEDUSERALLOWED, RELATEDUSERDENIED)
	as (	select  AN1.NAMENO, 
			cast(SUM(CASE WHEN(NR.ETHICALWALL=1)                               THEN 1 ELSE 0 END) as bit) as ALLOWEDRULE,
			cast(SUM(CASE WHEN(NR.ETHICALWALL=2)                               THEN 1 ELSE 0 END) as bit) as DENIEDRULE,
			cast(SUM(CASE WHEN(NR.ETHICALWALL=1 AND AN1.RELATEDNAME=UI.NAMENO) THEN 1 ELSE 0 END) as bit) as USERALLOWED,
			cast(SUM(CASE WHEN(NR.ETHICALWALL=2 AND AN1.RELATEDNAME=UI.NAMENO) THEN 1 ELSE 0 END) as bit) as USERDENIED,
			cast(SUM(CASE WHEN(NR.ETHICALWALL=1 AND AN2.RELATEDNAME=UI.NAMENO) THEN 1 ELSE 0 END) as bit) as RELATEDUSERALLOWED,
			cast(SUM(CASE WHEN(NR.ETHICALWALL=2 AND AN2.RELATEDNAME=UI.NAMENO) THEN 1 ELSE 0 END) as bit) as RELATEDUSERDENIED
		from USERIDENTITY UI			
		join NAMERELATION NR         on (NR.ETHICALWALL in (1,2))
		join ASSOCIATEDNAME AN1      on (AN1.RELATIONSHIP=NR.RELATIONSHIP) -- Finds the Names that have one or more ethical wall rule
		left join ASSOCIATEDNAME AN2 on (AN2.NAMENO      =AN1.RELATEDNAME
					     and AN2.RELATEDNAME =UI.NAMENO)
		where UI.IDENTITYID = @pnUserIdentityId
		and   UI.BYPASSETHICALWALL=0
		and   UI.ISEXTERNALUSER   =0
		group by AN1.NAMENO
	   )
	Select	N.*
	From NAME N with (NOLOCK)
	left join NameAccess NA on (NA.NAMENO=N.NAMENO)
	Where  CASE WHEN(NA.NAMENO is null)        THEN 1 -- No restrictions so user allowed access
	            WHEN(NA.USERALLOWED=1)         THEN 1 -- User explicitly allowed access
	            WHEN(NA.USERDENIED =1)         THEN 0 -- User explicitly denied  access
	            WHEN(NA.RELATEDUSERALLOWED=1)  THEN 1 -- User explicitly allowed access
	            WHEN(NA.RELATEDUSERDENIED =1)  THEN 0 -- User explicitly denied  access
	            WHEN(NA.ALLOWEDRULE=1)         THEN 0 -- Allowed rule is defined and user is not included so access is denied by default
	            WHEN(NA.DENIEDRULE =1)         THEN 1 -- Denied rule is defined and user is not include so access is allowed by default
		END = 1
	)
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_NamesEthicalWall to public
GO

