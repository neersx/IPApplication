----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_VerifyLicenses
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ip_VerifyLicenses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_VerifyLicenses.'
	Drop procedure dbo.ip_VerifyLicenses
End
Print '**** Creating Stored Procedure dbo.ip_VerifyLicenses...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ip_VerifyLicenses
(
	@pbBlockUser			bit 		= null output, 	-- Indicates that the user should not be allowed to continue
	@pnFailReason			tinyint		= null output,	-- The result of the license verification: 0 = License check succeeded; 1 = Total number of live cases is greater than the allowed amount (warning); 3 = Total number of users is greater than the allowed number (block)
        @psModule			nvarchar(100)	= null output, 	-- The name of the licensed module where the failure occurred (if any)
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,		-- The language in which output is to be expressed.
	@pnModuleFlag			int		= null		-- A bitwise flag used to filter the modules to be checked. It contains the following possible values: Bit 0 – client/server; Bit 1 – CPA Inprostart; Bit 2 – WorkBenches
)
with ENCRYPTION
AS

-- PROCEDURE:	ip_VerifyLicenses
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the result of the Licensing check. Only perform the tests if the user is internal.
--		External users are not to receive messages about the firm's licensing problems.
-- NOTES:
--		As a result of the license verification Fail Reason can be set to:
--		0  = License check succeeded
--		1  = Total number of live cases is greater than the allowed amount (warning)
--		3  = Total number of users is greater than the allowed number (block)
--		20 = No license found (block)

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 12 Nov 2004	TM	9758	1	Procedure created 
-- 19 Nov 2004	TM	RFC869	2	Use '...&@pnModuleFlag' to filter on the @pnModuleFlag.
-- 23 Nov 2004	TM	RFC869	3	Return a failure if there is no license found.
-- 23 Nov 2004	TM	RFC869	4	Remove the max cases test for external users.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(4000)
Declare	@TranCountStart int

Declare @bExternalUser	bit
Declare @nLiveCases 	int
Declare @nMaxCases 	int
Declare @bLicenseFound  bit

-- Initialise variables
Set @nErrorCode 	= 0
Set @pbBlockUser	= 0
Set @pnFailReason 	= 0
Set @bLicenseFound	= 0

-- Only perform the tests if the user is internal. External users are not to receive messages about the firm’s licensing problems.

-- Determine if the user is internal or external
If @nErrorCode = 0
Begin		
	Set @sSQLString = "
	Select	@bExternalUser = ISEXTERNALUSER
	from USERIDENTITY
	where IDENTITYID = @pnUserIdentityId"

	Exec  @nErrorCode = sp_executesql @sSQLString,
				N'@bExternalUser	bit			OUTPUT,
				  @pnUserIdentityId	int',
				  @bExternalUser	= @bExternalUser	OUTPUT,
				  @pnUserIdentityId	= @pnUserIdentityId
End

If @bExternalUser = 0
and @nErrorCode = 0
Begin
	-- Is there license?
	Set @sSQLString = "
	Select  @bLicenseFound = 1	
	from dbo.fn_LicenseData() L
	join dbo.fn_ModuleDetails() M 	on (M.ModuleID = L.MODULEID)
	where M.ModuleFlag&@pnModuleFlag > 0"

	Exec @nErrorCode = sp_executesql @sSQLString,
					N'@bLicenseFound	bit			OUTPUT,
					  @pnModuleFlag		int',
					  @bLicenseFound	= @bLicenseFound 	OUTPUT,					  
					  @pnModuleFlag		= @pnModuleFlag

	-- If no license found then set the fail reason to 20 (block the user):
	If @nErrorCode = 0
	and @bLicenseFound = 0
	Begin
		Set @pbBlockUser 	= 1
		Set @pnFailReason	= 20			
	End
	Else
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select  @psModule	= LM.MODULENAME,
			@pbBlockUser	= 1,
			@pnFailReason	= 3		
		from dbo.fn_LicenseData() L
		join dbo.fn_ModuleDetails() M 	on (M.ModuleID = L.MODULEID)
		join LICENSEMODULE LM 		on (LM.MODULEID = L.MODULEID)
		-- Suppress rows with global licensing, i.e. where PRICINGMODEL <> 1 
		-- and L.MODULEUSERS <> -1
		where PRICINGMODEL <> 1
		and L.MODULEUSERS <> -1
		-- Maximum licensed users is less then there are configured users 
		-- for this internal module in the database
		and ((L.MODULEUSERS < ( Select COUNT(*) 
					from LICENSEDUSER U 
					where U.MODULEID = L.MODULEID)
		and   M.InternalUse = 1)
		-- Maximum licensed AccessAccounts is less then there are configured AccessAccounts 
		-- for this external module in the database
		or (L.MODULEUSERS < ( 	Select COUNT(*) 
					from LICENSEDACCOUNT A 
					where A.MODULEID = L.MODULEID) 
		and M.ExternalUse = 1))
		and M.ModuleFlag&@pnModuleFlag > 0"
	
		Exec @nErrorCode = sp_executesql @sSQLString,
						N'@psModule		nvarchar(100)	OUTPUT,
						  @pbBlockUser		bit		OUTPUT,
						  @pnFailReason		tinyint		OUTPUT,
						  @pnModuleFlag		int',
						  @psModule		= @psModule 	OUTPUT,
						  @pbBlockUser		= @pbBlockUser	OUTPUT,
						  @pnFailReason		= @pnFailReason OUTPUT,
						  @pnModuleFlag		= @pnModuleFlag
	End

	-- Is number of live property cases exceeded the number licensed?
	-- If it is, set fail reason to 1 without blocking the user.
	If @nErrorCode = 0 
	and @pbBlockUser = 0
	Begin
		-- Find out the maximum number of cases
		Set @sSQLString = 
		"Select	@nMaxCases = MAXCASES		
		from dbo.fn_LicenseData()"
		
		Exec @nErrorCode = sp_executesql @sSQLString,
					      N'@nMaxCases		int			OUTPUT',
						@nMaxCases		= @nMaxCases		OUTPUT
						
		If @nMaxCases <> -1	-- if unlimited cases dont check
		Begin
			-- lower the locking level to the lowest level.  This will ensure
			-- the Select will not be blocked by other database activity	
			set transaction isolation level read uncommitted
		
			Set @sSQLString = "
				Select @nLiveCases = COUNT(*)
				from CASES C
				left join STATUS ST     on ST.STATUSCODE = C.STATUSCODE
				join PROPERTY P     	on P.CASEID = C.CASEID
				left join STATUS RS 	on RS.STATUSCODE = P.RENEWALSTATUS
				where isnull(ST.LIVEFLAG,1)<>0 
				and   isnull(RS.LIVEFLAG,1)<>0
				and   C.CASETYPE = 'A'"
			
			Exec @nErrorCode = sp_executesql @sSQLString,
						      N'@nLiveCases	int OUTPUT',
							@nLiveCases 	= @nLiveCases OUTPUT
		
			-- Reset the locking level	
			set transaction isolation level read committed
		
			If @nLiveCases > @nMaxCases
			Begin
				Set @pbBlockUser = 0
				Set @pnFailReason = 1
			End
		End
	End
End

Return @nErrorCode
GO

Grant execute on dbo.ip_VerifyLicenses to public
GO

