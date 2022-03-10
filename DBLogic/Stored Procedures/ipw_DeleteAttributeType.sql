-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteAttributeType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteAttributeType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteAttributeType.'
	Drop procedure [dbo].[ipw_DeleteAttributeType]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteAttributeType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE PROCEDURE [dbo].[ipw_DeleteAttributeType]
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psParentTable		nvarchar(100),	-- Mandatory
	@pnTableType		int,         	-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE :	ipw_DeleteAttributeType
-- VERSION :	2
-- DESCRIPTION:	Procedure to delete Attribute type
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Aug 2009	DV	RFC8016	1	Procedure created 
-- 04 Feb 2010	DL	18430	2	Grant stored procedure to public


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF		

Declare @nErrorCode 		int
Declare @sDeleteString		nvarchar(4000)

Set @nErrorCode = 0
If @nErrorCode = 0
BEGIN
	Set @sDeleteString = "DELETE FROM SELECTIONTYPES 
						Where PARENTTABLE = @psParentTable 
						and TABLETYPE = @pnTableType"

	exec @nErrorCode=sp_executesql @sDeleteString,
		   N'@psParentTable			nvarchar(100),
			@pnTableType			int',
			@psParentTable	 		= @psParentTable,
			@pnTableType	 		= @pnTableType			
END

RETURN @nErrorCode
go

grant execute on dbo.ipw_DeleteAttributeType to public
go
