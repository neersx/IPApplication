-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListMultipleFileLocations
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListMultipleFileLocations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListMultipleFileLocations.'
	Drop procedure [dbo].[ipw_ListMultipleFileLocations]
End
Print '**** Creating Stored Procedure dbo.ipw_ListMultipleFileLocations...'
Print ''
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[ipw_ListMultipleFileLocations]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psFileLocationKeys		nvarchar(max)
)
as
-- PROCEDURE:	ipw_ListMultipleFileLocations
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given a list of comma delimited OfficeKeys, return matching Case Office as a result set.

-- MODIFICATIONS :
-- Date			Who	Change		Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 04 JUN 2014	AK	RFC33301	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int
Declare @sSQLString			nvarchar(max)
Declare @sLookupCulture		nvarchar(10)
Declare @CommaString		nchar(2)	-- DataType(CS) to indicate a Comma Delimited String

Set	@CommaString			='CS'
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @nErrorCode = 0

Set @sSQLString='SELECT FL.TABLECODE AS FILELOCATIONKEY	, DESCRIPTION AS FILELOCATION
						FROM TABLECODES FL 
						WHERE TABLETYPE=10 
						AND FL.TABLECODE' + dbo.fn_ConstructOperator(0,@CommaString,@psFileLocationKeys, null,@pbCalledFromCentura)

exec @nErrorCode=sp_executesql @sSQLString,
								N'@psFileLocationKeys		nvarchar(max)',
								@psFileLocationKeys		= @psFileLocationKeys

RETURN @nErrorCode
GO

GRANT EXECUTE ON dbo.[ipw_ListMultipleFileLocations]  TO PUBLIC

GO