-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_FilterUserChargeTypes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_FilterUserChargeTypes') and xtype='IF')
begin
	print '**** Drop function dbo.fn_FilterUserChargeTypes.'
	drop function dbo.fn_FilterUserChargeTypes
	print '**** Creating function dbo.fn_FilterUserChargeTypes...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_FilterUserChargeTypes
			(@pnUserIdentityId		int,		-- the specific user the AliasTypes are required for
			 @pbIsExternalUser		bit,		-- External user flag which should already be known
			 @psLookupCulture		nvarchar(10), 	-- the culture the output is required in
			 @pbCalledFromCentura  		bit = 0)	-- if true, the function should provide access to all data		
RETURNS TABLE
AS
-- FUNCTION :	fn_FilterUserChargeTypes
-- VERSION :	2
-- DESCRIPTION:	This function is used to return a list of Charge Types that the currently logged on
--		external user identified by @pnUserIdentityId is allowed to have access to.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 14 Dec 2006	JEK	RFC3218	1	Function created
-- 20 Dec 2006	JEK	RFC3218	2	Implement Public column now its available.

RETURN

	Select 	C.CHARGETYPENO	as CHARGETYPENO,
		dbo.fn_GetTranslationLimited(C.CHARGEDESC,null,C.CHARGEDESC_TID,@psLookupCulture) as CHARGEDESC
	from CHARGETYPE C
	where PUBLICFLAG=1

GO

grant REFERENCES, SELECT on dbo.fn_FilterUserChargeTypes to public
GO
