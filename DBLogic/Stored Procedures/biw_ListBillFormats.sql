-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ListBillFormats
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListBillFormats]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListBillFormats.'
	Drop procedure [dbo].[biw_ListBillFormats]
	Print '**** Creating Stored Procedure dbo.biw_ListBillFormats...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.biw_ListBillFormats
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
	--@pnNameKey		int		= null
)
AS
-- PROCEDURE:	biw_ListBillFormats
-- VERSION:	2
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of available actions.

-- MODIFICATIONS :
-- Date		Who	Change Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 26-10-2009	AT	RFC3605	1	Procedure created.
-- 07-05-2010	AT	RFC9135	2	Return FORMATPROFILEID.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int

Declare @sSQLString	nvarchar(1000)

Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set	@nErrorCode      = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
			select
			cast(BILLFORMATID as int)	as 'BillFormatKey',
			FORMATNAME		as 'BillFormatDescription',
			FORMATPROFILEID		as 'BillFormatProfileKey'
			from BILLFORMAT
			where UPPER(RIGHT(BILLFORMATREPORT, 3)) = 'RDL'
			order by FORMATNAME"

	exec @nErrorCode = sp_executesql @sSQLString

End


Return @nErrorCode
GO

Grant execute on dbo.biw_ListBillFormats to public
GO
