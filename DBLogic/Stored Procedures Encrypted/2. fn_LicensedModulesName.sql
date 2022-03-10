-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_LicensedModulesName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_LicensedModulesName') and xtype='IF')
begin
	print '**** Drop function dbo.fn_LicensedModulesName.'
	drop function dbo.fn_LicensedModulesName
	print '**** Creating function dbo.fn_LicensedModulesName...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Create Function dbo.fn_LicensedModulesName
(
	@pnNameKey	int,	-- The key of the name whose user licensing is to be checked.
	@pdtToday	datetime
)
RETURNS  TABLE
 
With ENCRYPTION
AS
-- FUNCTION :	fn_LicensedModulesName
-- VERSION :	2
-- DESCRIPTION:	A user defined function that returns a list of licensed modules, 
--		for all the users for a given name.

-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 Sep 2005	TM	RFC2952	1	Function created
-- 12 Jul 2006	SW	RFC3828	2	Add new param @pdtToday

-- NOTE: If the function is changed, the corresponding fn_LicensedModules function needs to be changed.

Return	
		Select  UI.IDENTITYID		as IDENTITYID,
			L.MODULEID		as MODULEID, 
			L.INTERNALUSE 		as INTERNALUSE, 
			L.EXTERNALUSE		as EXTERNALUSE
		from dbo.fn_Modules(@pdtToday) L
		left join USERIDENTITY UI	on (UI.NAMENO = @pnNameKey)		
		left join LICENSEDUSER LU	on (LU.MODULEID = L.MODULEID
						and LU.USERIDENTITYID = UI.IDENTITYID)
		left join LICENSEDACCOUNT LA	on (LA.MODULEID = L.MODULEID
						and LA.ACCOUNTID = UI.ACCOUNTID)
		-- If @pnIdentityKey was not supplied, 
		-- the firm-wide licenses are checked:
		where (UI.IDENTITYID is null
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

grant REFERENCES, SELECT on dbo.fn_LicensedModulesName to public
GO
