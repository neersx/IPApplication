 
-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_FetchTableCode									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_FetchTableCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_FetchTableCode.'
	Drop procedure [dbo].[ipw_FetchTableCode]
End
Print '**** Creating Stored Procedure dbo.ipw_FetchTableCode...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_FetchTableCode
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnTableTypeKey			smallint, -- Mandatory
	@psTableCode			nvarchar(15)	= null
)
as
-- PROCEDURE:	ipw_FetchTableCode
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the TableCodes business entity.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 08 Oct 2008	SF		RFC6510	1	Procedure created
-- 15 Apr 2013	DV		R13270	2	Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sLookupCulture	nvarchar(10)
Declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
and @psTableCode is not null 
Begin
	Set @sSQLString = "Select
	Cast(T.TABLETYPE as nvarchar(10))+'^'+Cast(T.TABLECODE as nvarchar(11))			as RowKey,
	T.TABLECODE			as TableCode,
	T.TABLETYPE			as TableType,"+
			dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'TT',@sLookupCulture,@pbCalledFromCentura)+ 
			"		as TableName,
	TT.DATABASETABLE	as DatabaseTable,
	T.DESCRIPTION		as Description,
	T.USERCODE			as UserCode
	from TABLECODES T
	join TABLETYPE TT on (TT.TABLETYPE = T.TABLETYPE)
	where T.TABLETYPE = @pnTableTypeKey
	and T.TABLECODE = @psTableCode
	Order by T.TABLECODE"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnTableTypeKey		smallint,
				@psTableCode		nvarchar(15)',
				@pnTableTypeKey		= @pnTableTypeKey,
				@psTableCode		= @psTableCode


End
Else
If @nErrorCode =0
and @psTableCode is null
Begin
Set @sSQLString = "Select
	Cast(TT.TABLETYPE as nvarchar(10))+'^-1'			as RowKey,
	-1					as TableCode,
	TT.TABLETYPE		as TableType,"+
			dbo.fn_SqlTranslatedColumn('TABLETYPE','TABLENAME',null,'TT',@sLookupCulture,@pbCalledFromCentura)+ 
			"		as TableName,
	TT.DATABASETABLE	as DatabaseTable,
	null				as Description,
	null				as UserCode
	from TABLETYPE TT
	where TT.TABLETYPE = @pnTableTypeKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'	@pnTableTypeKey		smallint,
				@psTableCode		nvarchar(15)',
				@pnTableTypeKey		= @pnTableTypeKey,
				@psTableCode		= @psTableCode
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_FetchTableCode to public
GO
