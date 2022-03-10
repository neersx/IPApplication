-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserViewNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserViewNames') and xtype='IF')
begin
	print '**** Drop function dbo.fn_FilterUserViewNames.'
	drop function dbo.fn_FilterUserViewNames
	print '**** Creating function dbo.fn_FilterUserViewNames...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserViewNames
			(
				@pnUserIdentityId	int	-- the specific user the Names are required for
			)
RETURNS TABLE
as
-- FUNCTION :	fn_FilterUserViewNames
-- VERSION :	5
-- DESCRIPTION:	This function is for external users only.
--		It returns names that the user identified by @pnUserIdentityId parameter
--		has view access (but no management access).

-- MODIFICATION
-- Date		Who	No.	Version	Description
-- ===========  ===	======= ======= =======================
-- 10 Mar 2006	IB	RFC3325	1	Function created
-- 01 Jul 2008	LP	RFC5764	2	Filter CRM only names from result set
-- 17 Dec 2008	AT	RFC7365 3 	Comment to force function to update in CWB1
-- 15 Apr 2010	JCLG	RFC9164 4 	Correct issues with employees of the access account
-- 28 Apr 2010  LP      RFC9164 5       Remove Unrestricted Name Type from filter when selecting non-CRM-only names
		
Return		
	-- All access names for the current user’s account 
	Select 	N.NAMENO
	from 	ACCESSACCOUNTNAMES N
	join 	USERIDENTITY UI	on (UI.ACCOUNTID = N.ACCOUNTID)
	where 	UI.IDENTITYID = @pnUserIdentityId
	and exists(SELECT 1 FROM NAMETYPECLASSIFICATION NTC1
                JOIN NAMETYPE NT on (NT.NAMETYPE = NTC1.NAMETYPE)  
                WHERE NTC1.NAMENO = N.NAMENO 
                AND NT.PICKLISTFLAGS&32<>32 and NTC1.ALLOW=1)
	union
	-- Employees of the access account
	select 	AN.RELATEDNAME
	from 	ACCESSACCOUNTNAMES AAN
	join 	USERIDENTITY UI	on (UI.ACCOUNTID = AAN.ACCOUNTID)
	join	ASSOCIATEDNAME AN on (AN.NAMENO = AAN.NAMENO and
				      AN.RELATIONSHIP = 'EMP' and
				      AN.CEASEDDATE is null)
	where 	UI.IDENTITYID = @pnUserIdentityId
	and exists(SELECT 1 FROM NAMETYPECLASSIFICATION NTC1
                JOIN NAMETYPE NT on (NT.NAMETYPE = NTC1.NAMETYPE)  
                WHERE NTC1.NAMENO = AN.RELATEDNAME 
                AND NT.PICKLISTFLAGS&32<>32 and NTC1.ALLOW=1)
	union
	-- Case names that the user may view must meet the following requirements:
	--	Belong to a case that the user has access to (fn_FilterUserCases)
	--	Related to that case via a name type the user has access to (fn_FilterUserNameTypes)
	--	Are not expired
	select 	CN.NAMENO
	from 	CASENAME CN
	join 	dbo.fn_FilterUserCases(@pnUserIdentityId, 1, null) FUC on (FUC.CASEID = CN.CASEID)
	join	dbo.fn_FilterUserNameTypes(@pnUserIdentityId, null, 1, 0) FUNT on (FUNT.NAMETYPE = CN.NAMETYPE)
	where  	CN.EXPIRYDATE is null

go

grant REFERENCES, SELECT on dbo.fn_FilterUserViewNames to public
go
