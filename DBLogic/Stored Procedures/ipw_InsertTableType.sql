-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_InsertTableType									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_InsertTableType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_InsertTableType.'
	Drop procedure [dbo].[ipw_InsertTableType]
End
Print '**** Creating Stored Procedure dbo.ipw_InsertTableType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_InsertTableType
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@psTableTypeName			nvarchar(80)	-- Mandatory	
)
as
-- PROCEDURE:	ipw_InsertTableType
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Insert TableType.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Feb 2010	DV		RFC8383 	1	Procedure created
-- 09 Aug 2010	DV		RFC8384 	2	Restrict duplicate table type from getting inserted

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF

Declare @nErrorCode		int
Declare @sSQLString 	nvarchar(4000)
Declare @sAlertXML		nvarchar(500)

-- Initialise variables
Set @nErrorCode = 0
Declare @pnTableType smallint

If @nErrorCode = 0
Begin	
	if (@psTableTypeName is not null and
		exists(select 1 from TABLETYPE where upper(TABLENAME) = upper(@psTableTypeName)))
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('IP120', 'List Name already exists.', null, null, null, null, null)
		RAISERROR(@sAlertXML, 12, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode = 0
Begin
	-- Generate TABLETYPE primary key
	Exec @nErrorCode = dbo.ip_GetLastInternalCode
		@pnUserIdentityId	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@psTable		= 'TABLETYPE',
		@pnLastInternalCode	= @pnTableType		OUTPUT
End

If @nErrorCode = 0
Begin
	
	Set @sSQLString = "Insert into TABLETYPE
				(TABLETYPE,TABLENAME,MODIFIABLE,ACTIVITYFLAG,DATABASETABLE)
			 values (@pnTableType,@psTableTypeName,1,0,'TABLECODES')
			"

	
	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnTableType		smallint,
			@psTableTypeName	nvarchar(80)',
			@pnTableType		= @pnTableType,
			@psTableTypeName	= @psTableTypeName
	
	Select @pnTableType as TableType

End

Return @nErrorCode
GO

Grant execute on dbo.ipw_InsertTableType to public
GO
