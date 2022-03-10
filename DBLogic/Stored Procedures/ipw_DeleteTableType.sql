-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteTableType									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteTableType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteTableType.'
	Drop procedure [dbo].[ipw_DeleteTableType]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteTableType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.ipw_DeleteTableType
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture				nvarchar(10) 	= null,
	@pbCalledFromCentura			bit		= 0,
	@pnTableType				smallint,	-- Mandatory
	@pdtLogDateTimeStamp			datetime	= null
)
as
-- PROCEDURE:	ipw_DeleteTableType
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete TableType if the underlying values are as expected.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Feb 2010	DV		RFC8383 	1	Procedure created

SET CONCAT_NULL_YIELDS_NULL OFF
-- Row counts required by the data adapter
SET NOCOUNT OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

Declare @nErrorCode		int
Declare @sSQLString 		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin Try
	Set @sSQLString = "Delete from TABLETYPE
					where TABLETYPE	= @pnTableType
					and   (LOGDATETIMESTAMP = @pdtLogDateTimeStamp or @pdtLogDateTimeStamp is null)"	

	exec @nErrorCode=sp_executesql @sSQLString,
			      	N'
			@pnTableType		smallint,
			@pdtLogDateTimeStamp	datetime',
			@pnTableType		= @pnTableType,
			@pdtLogDateTimeStamp	= @pdtLogDateTimeStamp

End Try
Begin Catch
	if @@Error = 547
	Begin
		Declare @sAlertXML nvarchar(400)
		Set @sAlertXML = dbo.fn_GetAlertXML('IP106', 'The requested Table Type cannot be deleted as it is essential to other existing information',
					 null, null, null,null,null)
		 RAISERROR(@sAlertXML, 12, 1)			
	End
	else
	Begin
		Declare @ErrorMessage nvarchar(4000);
		Declare @ErrorSeverity int;
		Declare @ErrorState int;

		Select  
			@ErrorMessage = ERROR_MESSAGE(),
			@ErrorSeverity = ERROR_SEVERITY()   
		
		RAISERROR (@ErrorMessage,@ErrorSeverity,1)
	End
End Catch

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteTableType to public
GO

