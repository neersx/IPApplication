-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_ListBillFormatProfileContent
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_ListBillFormatProfileContent]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_ListBillFormatProfileContent.'
	Drop procedure [dbo].[biw_ListBillFormatProfileContent]
End
Print '**** Creating Stored Procedure dbo.biw_ListBillFormatProfileContent...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_ListBillFormatProfileContent
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnContextKey			int,
	@pnPresentationKey		int		= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	biw_ListBillFormatProfileContent
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return the list of query columns for use in bill format profiles

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10 Jul 2010	LP		RFC9289	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Set @sSQLString = "
		select 
			QC1.COLUMNID as ColumnKey,
			QC1.COLUMNLABEL as ColumnName,
			QC1.DESCRIPTION as ColumnDescription,
			CASE when QC3.PRESENTATIONID <> QC4.PRESENTATIONID then QC3.PRESENTATIONID else NULL END as PresentationKey,
			CASE when QC3.PRESENTATIONID IS NOT NULL and QC3.PRESENTATIONID <> QC4.PRESENTATIONID then convert(bit,1) 
				when QC3.PRESENTATIONID = QC4.PRESENTATIONID then convert(bit,1)
				else convert(bit,0) END as IsSelected,
			CASE when QC3.PRESENTATIONID = QC4.PRESENTATIONID then convert(bit,1) else convert(bit,0) END as IsDefault	
		from QUERYCOLUMN QC1
		join QUERYCONTEXTCOLUMN QC2 on (QC1.COLUMNID = QC2.COLUMNID)
		left join QUERYCONTENT QC3 on (QC2.COLUMNID = QC3.COLUMNID)
		left join QUERYPRESENTATION QC4 on (QC4.ISDEFAULT = 1 and QC4.CONTEXTID = @pnContextKey)
		where QC2.CONTEXTID = @pnContextKey
		and (QC3.PRESENTATIONID IS NULL or 
			QC3.PRESENTATIONID = @pnPresentationKey or 
			QC3.PRESENTATIONID = QC4.PRESENTATIONID)
		order by IsDefault desc, QC3.DISPLAYSEQUENCE"
		
		exec @nErrorCode = sp_executesql @sSQLString,
						N'@pnContextKey			int,
						@pnPresentationKey		int',
						@pnContextKey			= @pnContextKey,
						@pnPresentationKey		= @pnPresentationKey			
End

Return @nErrorCode
GO

Grant execute on dbo.biw_ListBillFormatProfileContent to public
GO
