---------------------------------------------------------------------------------------------
-- Creation of dbo.qr_ListValidExportFormats
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[qr_ListValidExportFormats]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.qr_ListValidExportFormats.'
	drop procedure [dbo].[qr_ListValidExportFormats]
	Print '**** Creating Stored Procedure dbo.qr_ListValidExportFormats...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.qr_ListValidExportFormats
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	qr_ListValidExportFormats
-- VERSION:	4
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of valid Export Formats.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 20 Apr 2004  TM	RFC919	1	Procedure created
-- 14 May 2004	JEK	RFC919	2	Only return formats in use by WorkBenches.
-- 15 Sep 2004	JEK	RFC886	3	Implement translation.
-- 15 May 2005	JEK	RFC2508	4	Extract @sLookupCulture and pass to translation instead of @psCulture

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
	Select 	R.REPORTTOOL 	as 'ReportToolKey',
		R.EXPORTFORMAT	as 'ExportFormatKey',
		"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'T',@sLookupCulture,@pbCalledFromCentura)
				+ " as 'ExportFormatDescription'
	from RPTTOOLEXPORTFMT R
	join TABLECODES T 	on (T.TABLECODE = R.EXPORTFORMAT)
	where R.USEDBYWORKBENCH = 1
	order by R.REPORTTOOL, ExportFormatDescription" 
	
	exec @nErrorCode = sp_executesql @sSQLString
	
	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant exec on dbo.qr_ListValidExportFormats to public
GO
