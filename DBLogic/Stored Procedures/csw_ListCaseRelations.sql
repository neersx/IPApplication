-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.csw_ListCaseRelations
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseRelations]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseRelations.'
	Drop procedure [dbo].[csw_ListCaseRelations]
	Print '**** Creating Stored Procedure dbo.csw_ListCaseRelations...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.csw_ListCaseRelations
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	csw_ListCaseRelations
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of case relations.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 14 Oct 2005  TM	RFC3144	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select C.RELATIONSHIP	as RelationshipCode, 
	"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as RelationshipDescription
	from CASERELATION C   
	order by 2"

	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount
End




Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseRelations to public
GO
