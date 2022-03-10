-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_UpdateTableType									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_UpdateTableType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_UpdateTableType.'
	Drop procedure [dbo].[ipw_UpdateTableType]
End
Print '**** Creating Stored Procedure dbo.ipw_UpdateTableType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_UpdateTableType
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnTableType				smallint,	-- Mandatory
	@psTableTypeName			nvarchar(80),   -- Mandatory
	@pdtLogDateTimeStamp			datetime	= null				
)
as
-- PROCEDURE:	ipw_UpdateTableType
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update TableType if the underlying values are as expected.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Feb 2010	DV		RFC8383 	1	Procedure created
-- 09 Aug 2010	DV		RFC8384 	2	Restrict duplicate table type from getting inserted

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)
Declare @sAlertXML		nvarchar(500)


-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin	
	if (@psTableTypeName is not null and
		exists(select 1 from TABLETYPE where upper(TABLENAME) = upper(@psTableTypeName) and TABLETYPE <> @pnTableType))
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP120', 'List Name already exists.', null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Update TABLETYPE
			   set	TABLENAME = @psTableTypeName
		where	TABLETYPE = @pnTableType
		and	(LOGDATETIMESTAMP = @pdtLogDateTimeStamp or @pdtLogDateTimeStamp is null)"		

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnTableType		smallint,
			@psTableTypeName	nvarchar(80),
			@pdtLogDateTimeStamp	datetime',
			@pnTableType		= @pnTableType,
			@psTableTypeName	= @psTableTypeName,
			@pdtLogDateTimeStamp	= @pdtLogDateTimeStamp

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_UpdateTableType to public
GO
