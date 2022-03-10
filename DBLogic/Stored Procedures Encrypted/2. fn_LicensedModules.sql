-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_LicensedModules
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_LicensedModules') and xtype='IF')
begin
	print '**** Drop function dbo.fn_LicensedModules.'
	drop function dbo.fn_LicensedModules
	print '**** Creating function dbo.fn_LicensedModules...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Create Function dbo.fn_LicensedModules
(
	@pnIdentityKey	int,	-- The user for whom licenses are to be checked. If not supplied, 
				-- the firm-wide licenses are checked.
	@pdtToday	datetime
)
RETURNS  TABLE
 
With ENCRYPTION
AS
-- FUNCTION :	fn_LicensedModules
-- VERSION :	8
-- DESCRIPTION:	A user defined function that returns a list of licensed modules, 
--		either for the firm or a particular user.

-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Nov 2004	TM	RFC869	1	Function created
-- 18 Nov 2004	TM	RFC869	2	Replace 'exists' with the 'left joins'.
-- 19 Nov 2004	TM	RFC869	3	Correct the user-specific filtering for unlimited users.
-- 30 Nov 2004	JEK	RFC2079	4	Internal users must be able to access external modules for administration.
-- 01 Dec 2004	JEK	RFC2079 5	Implement new implied Administration module for Client WorkBench
--					Re-instate check that internal users must only access internal modules
--					Replace references to LICENSEMODULE to fn_ModuleDetails.
--					Return INTERNALUSE and EXTERNALUSE flags.
-- 14 May 2005	JEK	RFC2594	6	Implement fn_Modules() for performance.
--					Also move implied Administrative license to fn_Modules to reduce accesses.
-- 02 Sep 2005	TM	RFC2952	7	Update the comments.
-- 12 Jul 2006	SW	RFC3828	8	Add new param @pdtToday

-- NOTE: If the function is changed, the corresponding fn_LicensedModulesName function needs to be changed.

Return	
		Select  L.MODULEID		as MODULEID, 
			L.INTERNALUSE 		as INTERNALUSE, 
			L.EXTERNALUSE		as EXTERNALUSE
		from dbo.fn_Modules(@pdtToday) L
		left join USERIDENTITY UI	on (UI.IDENTITYID = @pnIdentityKey)		
		left join LICENSEDUSER LU	on (LU.MODULEID = L.MODULEID
						and LU.USERIDENTITYID = @pnIdentityKey)
		left join LICENSEDACCOUNT LA	on (LA.MODULEID = L.MODULEID
						and LA.ACCOUNTID = UI.ACCOUNTID)
		-- If @pnIdentityKey was not supplied, 
		-- the firm-wide licenses are checked:
		where (@pnIdentityKey is null
		and   (L.PRICINGMODEL = 1		-- unlimited users
		 or    L.MODULEUSERS > 0))
		-- User-Specific Licenses
		OR (  (L.PRICINGMODEL = 1		-- unlimited users
		       -- For an internal user, the module
		       -- is for internal use
		       and ((UI.ISEXTERNALUSER = 0 and 
			     L.INTERNALUSE = 1)
		       -- For an external user, the module 
		       -- is for external use
		        or  (UI.ISEXTERNALUSER = 1 and 
			     L.EXTERNALUSE = 1))))		
		 or   ((L.MODULEUSERS > 0 
		 and   ( -- For internal users 
		        (UI.ISEXTERNALUSER = 0 and 
		         LU.USERIDENTITYID is not null)
		         -- For external users 
		 or     (UI.ISEXTERNALUSER = 1 and 
		         LA.ACCOUNTID is not null)
		       ))
		    )

GO

grant REFERENCES, SELECT on dbo.fn_LicensedModules to public
GO
