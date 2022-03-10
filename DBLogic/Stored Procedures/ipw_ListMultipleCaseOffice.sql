-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListMultipleCaseOffice
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListMultipleCaseOffice]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListMultipleCaseOffice.'
	Drop procedure [dbo].[ipw_ListMultipleCaseOffice]
End
Print '**** Creating Stored Procedure dbo.ipw_ListMultipleCaseOffice...'
Print ''
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO


CREATE PROCEDURE [dbo].[ipw_ListMultipleCaseOffice]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psOfficeKeys		nvarchar(4000)
)
as
-- PROCEDURE:	ipw_ListMultipleCaseOffice
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given a list of comma delimited OfficeKeys, return matching Case Office as a result set.

-- MODIFICATIONS :
-- Date			Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 JUN 2013	SW	DR115	1	Procedure created




SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sSQLString nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @CommaString				nchar(2)	-- DataType(CS) to indicate a Comma Delimited String
Set	@CommaString				='CS'

Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @nErrorCode = 0

Set @sSQLString='
Select	O.OFFICEID 						as OfficeKey,'+char(10)+
	dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,@pbCalledFromCentura)+' as Office'+char(10)+
'from	OFFICE O
where	O.OFFICEID' + dbo.fn_ConstructOperator(0,@CommaString,@psOfficeKeys, null,@pbCalledFromCentura)



exec @nErrorCode=sp_executesql @sSQLString,
				N'@psOfficeKeys		nvarchar(4000)',
				  @psOfficeKeys		= @psOfficeKeys


RETURN @nErrorCode

GO

GRANT EXECUTE ON dbo.[ipw_ListMultipleCaseOffice]  TO PUBLIC

GO