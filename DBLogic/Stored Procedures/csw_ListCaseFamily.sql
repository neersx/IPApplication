-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseFamily
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseFamily]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseFamily.'
	Drop procedure [dbo].[csw_ListCaseFamily]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseFamily...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseFamily
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_ListCaseFamily
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List Questions to be managed by the Web version software

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 FEB 2011	KR		RFC6563	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  F.FAMILY 	as FamilyKey, 
		"+dbo.fn_SqlTranslatedColumn('CASEFAMILY','FAMILYTITLE',null, 'F',@sLookupCulture,@pbCalledFromCentura)
				+ " as FamilyTitle,
			F.LOGDATETIMESTAMP as LastModifiedDate
	from CASEFAMILY F
	order by 1"

	exec @nErrorCode = sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseFamily to public
GO
