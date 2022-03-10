-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchCaseImage									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchCaseImage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchCaseImage.'
	Drop procedure [dbo].[csw_FetchCaseImage]
End
Print '**** Creating Stored Procedure dbo.csw_FetchCaseImage...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchCaseImage
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int -- Mandatory
)
as
-- PROCEDURE:	csw_FetchCaseImage
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the CaseImage business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 11 Nov 2005	TM	RFC3203	1	Procedure created
-- 24 Oct 2011	ASH	R11460 2	Cast integer columns as nvarchar(11) data type.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select

	CAST(C.CASEID as nvarchar(11))+'^'+
	CAST(C.IMAGEID as nvarchar(11))		
				as RowKey,
	C.CASEID		as CaseKey,
	C.IMAGEID		as ImageKey,
	C.IMAGETYPE		as ImageTypeKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'D',@sLookupCulture,@pbCalledFromCentura)+"
				as ImageTypeDescription,
	C.IMAGESEQUENCE		as ImageSequence,
	I.IMAGEDESC		as ImageDescription,
	C.CASEIMAGEDESC		as CaseImageDescription,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'DS',@sLookupCulture,@pbCalledFromCentura)+"
				as ImageStatusDescription,
	C.FIRMELEMENTID		as DesignElementID,
	"+dbo.fn_SqlTranslatedColumn('DESIGNELEMENT','ELEMENTDESC',null,'DE',@sLookupCulture,@pbCalledFromCentura)+"
				as ElementDescription							
	from CASEIMAGE C
	left join TABLECODES D 	on (D.TABLECODE = C.IMAGETYPE)
	left join IMAGEDETAIL I	on (I.IMAGEID = C.IMAGEID)	
	left join TABLECODES DS on (DS.TABLECODE = I.IMAGESTATUS)
	left join DESIGNELEMENT DE on (DE.FIRMELEMENTID = C.FIRMELEMENTID
				and DE.CASEID = C.CASEID)
	where C.CASEID = @pnCaseKey
	order by CaseKey, ImageSequence"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCaseKey	 int',
			  @pnCaseKey	 = @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchCaseImage to public
GO