-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetCopyToContactDetails] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetCopyToContactDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetCopyToContactDetails].'
	drop procedure dbo.[biw_GetCopyToContactDetails]
end
print '**** Creating procedure dbo.[biw_GetCopyToContactDetails]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetCopyToContactDetails]
				@pnUserIdentityId	int,		-- Mandatory
				@psCulture		nvarchar(10) 	= null,
				@pbCalledFromCentura	bit		= 0,
				@pnCopyToKey		int
as
-- PROCEDURE :	biw_GetCopyToContactDetails
-- VERSION :	2
-- DESCRIPTION:	A procedure that returns Copy To name contact details.
--
-- COPYRIGHT:	Copyright 1993 - 2010 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- -----------------------------------------------------------
-- 12-Oct-2010	AT	RFC89982	1	Procedure created
-- 02 Nov 2015	vql	R53910		2	Adjust formatted names logic (DR-15543).

set concat_null_yields_null off

set nocount on

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(4000)
Declare		@sLookupCulture	nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

If (@ErrorCode = 0)
Begin
	-- Return copies to name contact information
	Set @sSQLString = "Select
		NULL as 'DebtorNo',
		N.NAMENO as 'RelatedNameNo',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'CopyToName', 
		CN.NAMENO as 'ContactNameKey',
		dbo.fn_FormatNameUsingNameNo(CN.NAMENO, 7101) as 'ContactName',
		N.POSTALADDRESS as 'AddressKey',
		dbo.fn_GetFormattedAddress(N.POSTALADDRESS, null, null, null, 0) as 'Address',
		null as 'AddressChangeReason'
		From NAME N
		left join NAME CN on (CN.NAMENO = N.MAINCONTACT)
		Where N.NAMENO = @pnCopyToKey"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnCopyToKey	int',
				  @pnCopyToKey=@pnCopyToKey
End

return @ErrorCode
go

grant execute on dbo.[biw_GetCopyToContactDetails]  to public
go
