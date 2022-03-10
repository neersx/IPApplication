-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListExpiringLicenses
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListExpiringLicenses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListExpiringLicenses.'
	Drop procedure [dbo].[ip_ListExpiringLicenses]
End
Print '**** Creating Stored Procedure dbo.ip_ListExpiringLicenses...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_ListExpiringLicenses
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,		-- The language in which output is to be expressed.
	@pnModuleFlag			int		= null,		-- A bitwise flag used to filter the modules to be checked. It contains the following possible values: Bit 0 – client/server; Bit 1 – CPA Inprostart; Bit 2 – WorkBenches
	@pdtAsAtDate			datetime	= null		-- Defaults to today
)
With ENCRYPTION
as
-- PROCEDURE:	ip_ListExpiringLicenses
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns a list of the licensed modules that are approaching
--		expiry and will block users once expiry is reached.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Aug 2006	JEK	R3828	1	Procedure created
-- 03 Jul 2013	MF	R13625	2	Performance improvement.  Move the fn_PermissionsGrantedAll into an
--					EXISTS clause instead of being in a JOIN.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nRowCount	int

-- Initialise variables
Set @nErrorCode = 0
Set @pdtAsAtDate = isnull(@pdtAsAtDate,getdate())

If @nErrorCode = 0
Begin
	select 	LM.MODULENAME, L.EXPIRYDATE
	from dbo.fn_LicenseData() L
	join LICENSEMODULE LM		on (LM.MODULEID=L.MODULEID)
	join dbo.fn_ModuleDetails() MD 	on (MD.ModuleID = L.MODULEID)
	join VALIDOBJECT V ON (cast(substring(dbo.fn_Clarify(V.OBJECTDATA),1,3)as int)=L.MODULEID)
	-- License relates to appropriate module
	where MD.ModuleFlag&@pnModuleFlag > 0
	-- License is not yet expired
	and L.EXPIRYDATE > @pdtAsAtDate
	-- License blocks access
	AND L.EXPIRYACTION=1
	-- License is within warning period
	and (L.EXPIRYDATE-L.EXPIRYWARNINGDAYS) < @pdtAsAtDate
	-- Only examine web parts/tasks/subjects implemented for a user
	AND EXISTS(
		select 1
		from dbo.fn_PermissionsGrantedAll(null,null,null, @pdtAsAtDate) P
		where P.ObjectTable collate database_default =
						case V.TYPE
							 when 10
								then N'MODULE'
							 when 20
								then N'TASK'
							 when 30
								then N'DATATOPIC'
							 end
		and (P.ObjectIntegerKey = substring(dbo.fn_Clarify(V.OBJECTDATA),4,10) or
		     P.ObjectStringKey collate database_default = substring(dbo.fn_Clarify(V.OBJECTDATA), 15, 30))
		 )
	-- Web parts/tasks/subjects are not available via another license
	AND NOT EXISTS(
		select 1
		from dbo.fn_Modules(@pdtAsAtDate) M
		join VALIDOBJECT V2	on (cast(substring(dbo.fn_Clarify(V2.OBJECTDATA),1,3)as int)=M.MODULEID)
		-- Belongs to license that isn't expiring
		where M.MODULEID <> L.MODULEID
		-- Types are the same (web part/task/subject)
		and V2.TYPE=V.TYPE
		-- Identifiers of web part/task/subject are the same
		and substring(dbo.fn_Clarify(V2.OBJECTDATA),4,40)=substring(dbo.fn_Clarify(V.OBJECTDATA),4,40)
		)
	group by LM.MODULEID, LM.MODULENAME, L.EXPIRYDATE
	order by L.EXPIRYDATE, LM.MODULENAME

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_ListExpiringLicenses to public
GO
