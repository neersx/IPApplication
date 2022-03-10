-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserNames') and xtype in ('IF','TF'))
begin
	print '**** Drop function dbo.fn_FilterUserNames.'
	drop function dbo.fn_FilterUserNames
	print '**** Creating function dbo.fn_FilterUserNames...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserNames
			(@pnUserIdentityId		int,	-- the specific user the Names are required for
			 @pbIsExternalUser		bit	-- external user flag if already known
			)
RETURNS TABLE


-- FUNCTION :	fn_FilterUserNames
-- VERSION :	6
-- DESCRIPTION:	This function is used to return all of the Names that the
--		user identified by @pnUserIdentityId is linked to.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 20 Aug 2003	MF		1	Function created
-- 21 Aug 2003	JEK		2	Use hard coded NameNos until an appropriate
--					implementation is agreed.
-- 10-Oct-2003	MF	RFC519	3	Remove most of the "client" information as it causes performance problems.
-- 19 Nov 2003	JEK	RFC407	4	Implement AccessAccount for external users.
-- 30 Nov 2006	JEK	RFC4755	5	Include primary key index.
-- 13 Dec 2006	MF	14002	6	Change to In-line function to improve performance.

as RETURN
	(
	-- If the Names are required for an external user then get those Names 
	-- that have been linked to the @pnUserIdentityId otherwise return all Names

	Select 	N.NAMENO
	From 	ACCESSACCOUNTNAMES N
	join 	USERIDENTITY UI	ON (UI.ACCOUNTID = N.ACCOUNTID)
	where 	UI.IDENTITYID = @pnUserIdentityId
	)
go

grant REFERENCES, SELECT on dbo.fn_FilterUserNames to public
GO
