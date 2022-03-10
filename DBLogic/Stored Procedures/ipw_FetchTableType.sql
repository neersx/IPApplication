 
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_FetchTableType									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_FetchTableType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_FetchTableType.'
	Drop procedure [dbo].[ipw_FetchTableType]
End
Print '**** Creating Stored Procedure dbo.ipw_FetchTableType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_FetchTableType
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnTableTypeKey			smallint -- Mandatory
)
as
-- PROCEDURE:	ipw_FetchTableType
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the TableType business entity.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Feb 2010	DV		RFC8383 	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
	Cast(T.TABLETYPE as nvarchar(10))+'^'+Cast(T.TABLENAME as nvarchar(10))			as RowKey,
	T.TABLETYPE			as TableType,"+
			dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'T',@sLookupCulture,@pbCalledFromCentura)+ 
			"		as TableTypeName,
	T.LOGDATETIMESTAMP as LogDateTimeStamp
	from TABLETYPE T
	where T.TABLETYPE = @pnTableTypeKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnTableTypeKey		smallint',
				@pnTableTypeKey		= @pnTableTypeKey


End

Return @nErrorCode
GO

Grant execute on dbo.ipw_FetchTableType to public
GO
