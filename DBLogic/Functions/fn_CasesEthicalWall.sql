-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_CasesEthicalWall
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_CasesEthicalWall') and xtype in ('IF','TF'))
begin
	print '**** Drop function dbo.fn_CasesEthicalWall.'
	drop function dbo.fn_CasesEthicalWall
end
print '**** Creating function dbo.fn_CasesEthicalWall...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_CasesEthicalWall
			(@pnUserIdentityId	int	-- Mandatory User Identity of the logged on user
			)

RETURNS TABLE


-- FUNCTION :	fn_CasesEthicalWall
-- VERSION :	3
-- DESCRIPTION:	This function returns Cases that have one or more Names associated by a NAMETYPE that is 
--		flagged as an Ethical Wall restriction. 
--		ETHICALWALL=1 
--		Indicates the Names associated with the Case that are allowed access to the Case. Other names are NOT ALLOWED access.
--		ETHICALWALL=2
--		Indicates the Names associated with the Case that are denied access to the Case. Other names are ALLOWED access.
--
--		The logic for determining if a user has access to a Case follows the following order of precedence:
--		1. No restrictions defined	Access ALLOWED
--		2. User explicitly allowed	Access ALLOWED
--		3. User explicitly denied	Access DENIED
--		4. Related user allowed		Access ALLOWED
--		5. Related user denied		Access DENIED
--		6. Allowed rule configured	Access DENIED  because user is not directly or indirectly specifed
--		7. Denied rule configured	Access ALLOWED because user is not directly or indirectly specifed

-- EXAMPLE:	The following returns all of the columns from Cases that the user linked to IDENTITYID 26 is allowed access to.
--		Select *
--		from  dbo.fn_CasesEthicalWall(26)


-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 12 Apr 2016	MF	13471	1	Function created
-- 16 May 2016	MF	13471	2	Problem with access from associated name.
-- 20 May 2016	MF	61880	3	Exclude external users


as RETURN
	(
	With CaseAccess (CASEID, ALLOWEDRULE, DENIEDRULE, USERALLOWED, USERDENIED, RELATEDUSERALLOWED, RELATEDUSERDENIED)
	as (	select  CN.CASEID, 
			cast(SUM(CASE WHEN(NT.ETHICALWALL=1)                              THEN 1 ELSE 0 END) as bit) as ALLOWEDRULE,
			cast(SUM(CASE WHEN(NT.ETHICALWALL=2)                              THEN 1 ELSE 0 END) as bit) as DENIEDRULE,
			cast(SUM(CASE WHEN(NT.ETHICALWALL=1 AND CN.NAMENO     =UI.NAMENO) THEN 1 ELSE 0 END) as bit) as USERALLOWED,
			cast(SUM(CASE WHEN(NT.ETHICALWALL=2 AND CN.NAMENO     =UI.NAMENO) THEN 1 ELSE 0 END) as bit) as USERDENIED,
			cast(SUM(CASE WHEN(NT.ETHICALWALL=1 AND AN.RELATEDNAME=UI.NAMENO) THEN 1 ELSE 0 END) as bit) as RELATEDUSERALLOWED,
			cast(SUM(CASE WHEN(NT.ETHICALWALL=2 AND AN.RELATEDNAME=UI.NAMENO) THEN 1 ELSE 0 END) as bit) as RELATEDUSERDENIED
		from USERIDENTITY UI			
		join NAMETYPE NT on (NT.ETHICALWALL in (1,2))
		join CASENAME CN on (CN.NAMETYPE=NT.NAMETYPE)
		left join ASSOCIATEDNAME AN on (AN.NAMENO     =CN.NAMENO
					    and AN.RELATEDNAME=UI.NAMENO)
		where UI.IDENTITYID = @pnUserIdentityId
		and   UI.BYPASSETHICALWALL=0
		and   UI.ISEXTERNALUSER   =0
		group by CN.CASEID
	   )
	Select	C.*
	From CASES C with (NOLOCK)
	left join CaseAccess CA on (CA.CASEID=C.CASEID)
	Where  CASE WHEN(CA.CASEID is null)        THEN 1 -- No restrictions so user allowed access
	            WHEN(CA.USERALLOWED=1)         THEN 1 -- User explicitly allowed access
	            WHEN(CA.USERDENIED =1)         THEN 0 -- User explicitly denied  access
	            WHEN(CA.RELATEDUSERALLOWED=1)  THEN 1 -- User explicitly allowed access
	            WHEN(CA.RELATEDUSERDENIED =1)  THEN 0 -- User explicitly denied  access
	            WHEN(CA.ALLOWEDRULE=1)         THEN 0 -- Allowed rule is defined and user is not included so access is denied by default
	            WHEN(CA.DENIEDRULE =1)         THEN 1 -- Denied rule is defined and user is not include so access is allowed by default
		END = 1
	)
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_CasesEthicalWall to public
GO

