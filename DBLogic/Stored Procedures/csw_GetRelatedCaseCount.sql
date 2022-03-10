-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetRelatedCaseCount
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetRelatedCaseCount]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_GetRelatedCaseCount.'
	drop procedure [dbo].[csw_GetRelatedCaseCount]
	print '**** Creating Stored Procedure dbo.csw_GetRelatedCaseCount...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_GetRelatedCaseCount
(
	@pnRelatedCaseCount	int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey  		int		-- Mandatory
	
)
-- PROCEDURE:	csw_GetRelatedCaseCount
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns the number of RELATEDCASE rows where RELATEDCASEID equals @pnCaseKey.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Jul 2006  AU	RFC3394	1	Procedure created
AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString		nvarchar(500)
Declare @nErrorCode		int

-- Initialise variables
Set @nErrorCode = 0
	
If @nErrorCode = 0
Begin
	Set @sSQLString="
	Select @pnRelatedCaseCount = COUNT(*)
	from RELATEDCASE
	where RELATEDCASEID = @pnCaseKey"

	exec @nErrorCode = sp_executesql @sSQLString,
					N'@pnRelatedCaseCount	int			OUTPUT,
					  @pnCaseKey		int',
					  @pnRelatedCaseCount	= @pnRelatedCaseCount	OUTPUT,
					  @pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
go

grant execute on dbo.csw_GetRelatedCaseCount  to public
go
