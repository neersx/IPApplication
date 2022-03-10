-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListFileParts
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListFileParts]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListFileParts.'
	Drop procedure [dbo].[csw_ListFileParts]
End
Print '**** Creating Stored Procedure dbo.csw_ListFileParts...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListFileParts
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_ListFileParts
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns a list of file parts for the CaseKey

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Jul 2006	SW	RFC2307	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = '
		Select	FILEPART	as FilePartKey,
			FILEPARTTITLE	as FilePartDescription
		from	FILEPART
		where	CASEID = @pnCaseKey'

	Exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCaseKey		int',
			  @pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListFileParts to public
GO
