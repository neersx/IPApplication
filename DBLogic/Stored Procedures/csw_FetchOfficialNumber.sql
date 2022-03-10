-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchOfficialNumber
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchOfficialNumber]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchOfficialNumber.'
	Drop procedure [dbo].[csw_FetchOfficialNumber]
End
Print '**** Creating Stored Procedure dbo.csw_FetchOfficialNumber...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchOfficialNumber
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_FetchOfficialNumber
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Lists all modifiable columns from the OfficialNumbers table

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Sep 2005	TM			1	Procedure created
-- 29 Nov 2005 	TM	RFC3193	2	Implement new columns accordingly to OfficalNumber.doc.
-- 04 Mar 2010	MS	RFC7594	3	Add checksum on RowKey for encoding
-- 24 Oct 2011	ASH	R11460 	4	Cast integer columns as nvarchar(11) data type.
-- 17 Oct 2011	SF	R10553	5	Return LastModifiedDate
-- 26 May 2020	vql	D60784	6	Editing Official Numbers causes an record not available error.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "  
	Select  cast (O.OFFICIALNUMBERID as nvarchar(13))	as RowKey,
		O.CASEID			as CaseKey,
		O.NUMBERTYPE			as NumberTypeCode,
		"+dbo.fn_SqlTranslatedColumn('NUMBERTYPES','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura)+"	
				  		as NumberTypeDescription,
		O.OFFICIALNUMBER 		as OfficialNumber,		
		CAST(O.ISCURRENT as bit)	as IsCurrent,
		O.DATEENTERED			as DateEntered,
		O.LOGDATETIMESTAMP		as LastModifiedDate
	from OFFICIALNUMBERS O
	join NUMBERTYPES NT		on (NT.NUMBERTYPE = O.NUMBERTYPE)
	where O.CASEID = @pnCaseKey
	order by CaseKey, NT.DISPLAYPRIORITY DESC, NumberTypeDescription, IsCurrent DESC, OfficialNumber"
	
	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseKey		int',
				  @pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchOfficialNumber to public
GO
