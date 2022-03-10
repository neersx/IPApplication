-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseNameVariants
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseNameVariants]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseNameVariants.'
	Drop procedure [dbo].[csw_ListCaseNameVariants]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseNameVariants...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCaseNameVariants
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnNameKey		int,		-- Mandatory
	@pnCaseKey		int,		-- Mandatory
	@psPickListSearch	nvarchar(254)	= null,
	@pnNameVariantKey	int		= null
)
as
-- PROCEDURE:	csw_ListCaseNameVariants
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	A new stored procedure to populate the variants for a case and name combination.  

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 May 2006	SW	RFC3301	1	Procedure created
-- 10 May 2006	SW	RFC3301	2	Filter by @psPickListSearch
-- 19 May 2006	SW	RFC3301	3	Filter by @pnNameVariantKey

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = '
		Select		NV.NAMEVARIANTNO as NameVariantKey,
				dbo.fn_FormatName(NV.NAMEVARIANT, NV.FIRSTNAMEVARIANT, NULL, NULL) as NameVariant
		from		NAMEVARIANT NV
		left join	CASES C on (C.CASEID = @pnCaseKey)
		where		NV.NAMENO = @pnNameKey
		and		nullif(NV.PROPERTYTYPE, C.PROPERTYTYPE) is null'

	If @psPickListSearch is not null
	Begin
		Set @sSQLString = @sSQLString + char(10) + ' and UPPER(NV.NAMEVARIANT) like ' + dbo.fn_WrapQuotes(UPPER(@psPickListSearch)+'%',0 ,0)
		
	End

	If @pnNameVariantKey is not null
	Begin
		Set @sSQLString = @sSQLString + char(10) + ' and NV.NAMEVARIANTNO = @pnNameVariantKey'
		
	End

	Exec @nErrorCode = sp_executesql @sSQLString, 
				N'@pnNameKey		int,
				  @pnCaseKey		int,
				  @pnNameVariantKey	int',
				  @pnNameKey		= @pnNameKey,
				  @pnCaseKey		= @pnCaseKey,
				  @pnNameVariantKey	= @pnNameVariantKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseNameVariants to public
GO
