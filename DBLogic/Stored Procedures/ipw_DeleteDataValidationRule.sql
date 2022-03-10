-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteDataValidationRule
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteDataValidationRule]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteDataValidationRule.'
	Drop procedure [dbo].[ipw_DeleteDataValidationRule]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteDataValidationRule...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_DeleteDataValidationRule
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,			
	@pbCalledFromCentura		bit		= 0,
	@pnDataValidationID			int,	-- Mandatory
	@pdtLastUpdatedDate			datetime = null
)
as
-- PROCEDURE:	ipw_DeleteDataValidationRule
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to delete Data Validation
-- MODIFICATIONS :
-- Date			Who		Number	Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 29 Sep 2010  DV		RFC9387		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sDeleteString	nvarchar(500)

Set	@nErrorCode      = 0

Set @nErrorCode = 0
If @nErrorCode = 0
BEGIN
	If not exists (Select 1 from DATAVALIDATION 
			   where VALIDATIONID = @pnDataValidationID 
			   and (LOGDATETIMESTAMP = @pdtLastUpdatedDate or LOGDATETIMESTAMP is null))
	Begin
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Concurrency violation: The Delete command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin
		Set @sDeleteString = "DELETE FROM DATAVALIDATION 
							Where VALIDATIONID = @pnDataValidationID 
							and (LOGDATETIMESTAMP = @pdtLastUpdatedDate or LOGDATETIMESTAMP is null)"

		exec @nErrorCode=sp_executesql @sDeleteString,
				   N'@pnDataValidationID		int,
					@pdtLastUpdatedDate		datetime',
					@pnDataValidationID	 	= @pnDataValidationID,
					@pdtLastUpdatedDate	 	= @pdtLastUpdatedDate
	End			
END
Return @nErrorCode
go

Grant exec on dbo.ipw_DeleteDataValidationRule to Public
go