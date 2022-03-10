-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListCaseCategoryWithCaseType
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListCaseCategoryWithCaseType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListCaseCategoryWithCaseType.'
	Drop procedure [dbo].[ipw_ListCaseCategoryWithCaseType]
End
Print '**** Creating Stored Procedure dbo.ipw_ListCaseCategoryWithCaseType...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListCaseCategoryWithCaseType
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListCaseCategoryWithCaseType
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	To get Case Category along with Case Type

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Mar 2009	NG		RFC6921	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

Declare @sSQLString	nvarchar(500)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0
Set 	@pnRowCount	 = 0

If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select 	
		C.CASECATEGORY		as 'CaseCategoryKey',
		"+dbo.fn_SqlTranslatedColumn('CASECATEGORY','CASECATEGORYDESC',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'CaseCategoryDescription',
		C.CASETYPE			as 'CaseTypeKey'
	from 	CASECATEGORY C
	order by 2"

	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListCaseCategoryWithCaseType to public
GO
