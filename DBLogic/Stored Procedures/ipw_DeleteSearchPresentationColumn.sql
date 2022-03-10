-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteSearchPresentationColumn
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteSearchPresentationColumn]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteSearchPresentationColumn.'
	Drop procedure [dbo].[ipw_DeleteSearchPresentationColumn]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteSearchPresentationColumn...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_DeleteSearchPresentationColumn
(
	@pnUserIdentityId			int,			-- Mandatory
	@psCulture					nvarchar(10) 	= null,			
	@pbCalledFromCentura		bit		= 0,
	@pnColumnID					int,	-- Mandatory
	@pdtLastUpdatedDate			datetime = null
)
as
-- PROCEDURE:	ipw_DeleteSearchPresentationColumn
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Procedure to delete Currency
-- MODIFICATIONS :
-- Date			Who		Number	Version		Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 13 OCt 2010  DV		RFC9437		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sDeleteString	nvarchar(500)

Set	@nErrorCode      = 0

Set @nErrorCode = 0
If @nErrorCode = 0
BEGIN
	If not exists (Select * from QUERYCOLUMN 
			   where COLUMNID = @pnColumnID and (LOGDATETIMESTAMP = @pdtLastUpdatedDate or @pdtLastUpdatedDate is null))
	Begin
		DECLARE @message_string VARCHAR(255)  
		SET @message_string = 'Concurrency violation: The Delete command affected 0 records.'  
		RAISERROR(@message_string, 16, 1)
	End
	Else
	Begin
		Set @sDeleteString = "DELETE FROM QUERYCOLUMN 
							Where COLUMNID = @pnColumnID
							and (LOGDATETIMESTAMP = @pdtLastUpdatedDate
							or @pdtLastUpdatedDate is null)"

		exec @nErrorCode=sp_executesql @sDeleteString,
				   N'@pnColumnID		int,
					@pdtLastUpdatedDate		datetime',
					@pnColumnID	 		= @pnColumnID,
					@pdtLastUpdatedDate = @pdtLastUpdatedDate	

	End		
END
Return @nErrorCode
go

Grant exec on dbo.ipw_DeleteSearchPresentationColumn to Public
go