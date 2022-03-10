-----------------------------------------------------------------------------------------------------------------------------
-- Creation of sc_ListUserLicenses
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[sc_ListUserLicenses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.sc_ListUserLicenses.'
	Drop procedure [dbo].[sc_ListUserLicenses]
End
Print '**** Creating Stored Procedure dbo.sc_ListUserLicenses...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.sc_ListUserLicenses
(
	@pnIdentityKey		int,		-- the user for whom the data is required
	@pnModuleFlag 		smallint	-- a bitwise flag used to filter the modules to be checked. Bit 0 – client/server; Bit 1 – CPA Inprostart; Bit 2 - WorkBenches; ListUserLicenses.
)
With ENCRYPTION
AS
-- PROCEDURE:	sc_ListUserLicenses
-- VERSION:	6
-- DESCRIPTION:	Returns a list of the licensed modules for the user.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 Nov 2004	TM	RFC869	1	Procedure created
-- 19 Nov 2004	TM	RFC869	2	Use '...&@pnModuleFlag' to filter on the @pnModuleFlag.
-- 01 Dec 2004	JEK	RFC2079 3	Implement description for implied Client WorkBench Administration
-- 21 Jul 2006	SW	RFC3828 4	Return expiry date of the license (if any)
-- 30 Sep 2008	SF	RFC7125 5	Return implied license keys
-- 03 Oct 2014	LP	R40007	6	Only return distinct license rows.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)
Declare @dtToday	datetime

-- Initialise variables
Set @nErrorCode = 0
Set @dtToday = getdate()

If @nErrorCode = 0
Begin
	Set @sSQLString = " 
	Select  LM.MODULEID	as 'LicenseModuleKey',
		LM.MODULENAME	as 'LicenseModuleName',
		CASE WHEN FLM.MODULEID is not null
		     THEN CAST(1 as bit)
		     ELSE CAST(0 as bit)
		END		as 'IsLicensed',
		LD.EXPIRYDATE	as 'ExpiryDate'
	from LICENSEMODULE LM
	join USERIDENTITY UI 	on (UI.IDENTITYID = @pnIdentityKey)
	left join dbo.fn_LicensedModules(@pnIdentityKey, @dtToday) FLM
				on (FLM.MODULEID = LM.MODULEID)	
	left join dbo.fn_LicenseData() LD on (LD.MODULEID = LM.MODULEID)
	where LM.MODULEFLAG&@pnModuleFlag > 0
	and  ((UI.ISEXTERNALUSER = 0
	and    LM.INTERNALUSE = 1)
	or    (UI.ISEXTERNALUSER = 1
	and    LM.EXTERNALUSE = 1))

	union
	-- Allow for an implied administration module for each external module
	-- Implied ModuleKeys are 500 above the original external module keys
	Select  ISNULL(FLM.MODULEID,LM.MODULEID+500)	as 'LicenseModuleKey',
		LM.MODULENAME+' Administration'
				as 'LicenseModuleName',
		CASE WHEN FLM.MODULEID is not null
		     THEN CAST(1 as bit)
		     ELSE CAST(0 as bit)
		END		as 'IsLicensed',
		LD.EXPIRYDATE	as 'ExpiryDate'
	from LICENSEMODULE LM
	join USERIDENTITY UI 	on (UI.IDENTITYID = @pnIdentityKey)
	left join dbo.fn_LicensedModules(@pnIdentityKey, @dtToday) FLM
				on (FLM.MODULEID = LM.MODULEID+500)	
	left join dbo.fn_LicenseData() LD on (LD.MODULEID = LM.MODULEID)
	where LM.MODULEFLAG&@pnModuleFlag > 0
	and  LM.EXTERNALUSE = 1	
	and  UI.ISEXTERNALUSER = 0
	
	order by 'LicenseModuleName'"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnIdentityKey	int,
					  @pnModuleFlag		smallint,
					  @dtToday		datetime',
					  @pnIdentityKey	= @pnIdentityKey,	
					  @pnModuleFlag		= @pnModuleFlag,
					  @dtToday		= @dtToday
End

Return @nErrorCode
GO

Grant execute on dbo.sc_ListUserLicenses to public
GO
