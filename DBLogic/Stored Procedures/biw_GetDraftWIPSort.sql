-----------------------------------------------------------------------------------------------------------------------------
-- Creation of [biw_GetDraftWIPSort] 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[biw_GetDraftWIPSort]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.[biw_GetDraftWIPSort].'
	drop procedure dbo.[biw_GetDraftWIPSort]
end
print '**** Creating procedure dbo.[biw_GetDraftWIPSort]...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.[biw_GetDraftWIPSort]
		@pnUserIdentityId		int,		-- Mandatory
		@psCulture			nvarchar(10) 	= null,
		@pbCalledFromCentura		bit		= 0,
		@psWIPCode			nvarchar(6) -- Mandatory
				
as
-- PROCEDURE :	biw_GetDraftWIPSort
-- VERSION :	1
-- DESCRIPTION:	A procedure that additional details required for draft WIP sorting.
--
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	RFC		Version Description
-- -----------	-------	------		------- ----------------------------------------------- 
-- 14-Feb-2011	AT	RFC10040	1	Procedure created.

set nocount on
Set CONCAT_NULL_YIELDS_NULL off

Declare		@ErrorCode	int
Declare		@nRowCount	int
Declare		@sSQLString	nvarchar(max)

Declare		@sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @ErrorCode = 0

if (@ErrorCode = 0)
Begin
	Set @sSQLString = "select ISNULL(WT.WIPCODESORT,0) AS 'WIPCodeSort', 
	WTP.WIPTYPESORT as 'WIPTypeSort',
	WC.CATEGORYSORT as 'WIPCategorySort'
	FROM WIPTEMPLATE WT
	JOIN WIPTYPE WTP ON WTP.WIPTYPEID = WT.WIPTYPEID
	JOIN WIPCATEGORY WC ON WC.CATEGORYCODE = WTP.CATEGORYCODE
	WHERE WIPCODE = @psWIPCode"
	
	exec @ErrorCode=sp_executesql @sSQLString,
				N'@psWIPCode	nvarchar(6)',
				  @psWIPCode=@psWIPCode
End

return @ErrorCode
go

grant execute on dbo.[biw_GetDraftWIPSort]  to public
go
