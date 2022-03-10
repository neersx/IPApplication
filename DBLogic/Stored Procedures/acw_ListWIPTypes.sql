-----------------------------------------------------------------------------------------------------------------------------
-- Creation of acw_ListWIPTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[acw_ListWIPTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.acw_ListWIPTypes.'
	Drop procedure [dbo].[acw_ListWIPTypes]
	Print '**** Creating Stored Procedure dbo.acw_ListWIPTypes...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.acw_ListWIPTypes
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	acw_ListWIPTypes
-- VERSION:	1
-- SCOPE:	InPro.net
-- DESCRIPTION:	Returns list of WIP Types

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Nov-2011	KR	R10454	1	Procedure created.
-- 04-Aug-2015  SW      R50665  2       Removed redundant check on TableType = -508

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare	@nErrorCode		int
Declare	@sSQLString		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nErrorCode      = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	select 	WT.WIPTYPEID  as 'WIPTypeCode',
		"+dbo.fn_SqlTranslatedColumn('WT','DESCRIPTION',null,null,@sLookupCulture,@pbCalledFromCentura)
			+ " as 'WIPTypeDescription',
		WC.CATEGORYCODE as 'WIPCategoryCode',
		WC.DESCRIPTION as 'WIPCategoryDescription',
		isnull(cast(WT.CONSOLIDATE as bit),0) as 'IsConslidate',
		isnull(WT.RECORDASSOCDETAILS, 0) as 'IsAssociateDetails',
		WT.WRITEDOWNPRIORITY as 'WriteDownPriorityKey',
		T.DESCRIPTION as 'WriteDownPriorityDescription',
		isnull(WT.WRITEUPALLOWED, 0) as 'IsWriteUpAllowed',
		E.EXCHSCHEDULEID as'ExchRateScheduleKey',
		E.DESCRIPTION as 'ExchRateScheudleDescription',
		WT.LOGDATETIMESTAMP as 'LastModifiedDate',
		WT.WIPTYPESORT as 'WIPSort'
	from	WIPTYPE WT
	Left Join WIPCATEGORY WC on (WC.CATEGORYCODE = WT.CATEGORYCODE)
	Left Join EXCHRATESCHEDULE E on (WT.EXCHSCHEDULEID = E.EXCHSCHEDULEID)
	Left Join TABLECODES T on (T.TABLECODE = WT.WRITEDOWNPRIORITY)
	order by 2"

	exec @nErrorCode = sp_executesql @sSQLString
	
	--Set @pnRowCount = @@Rowcount

End

RETURN @nErrorCode
GO

Grant execute on dbo.acw_ListWIPTypes to public
GO
