-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchFileLocation									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchFileLocation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchFileLocation.'
	Drop procedure [dbo].[csw_FetchFileLocation]
End
Print '**** Creating Stored Procedure dbo.csw_FetchFileLocation...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchFileLocation
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int 		-- Mandatory
)
as
-- PROCEDURE:	csw_FetchFileLocation
-- VERSION:	6
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the FileLocation business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 24 Jul 2006	SW	R2307	1	Procedure created
-- 12 Feb 2011  MS      R8363	2       Added MovedBy Code 
-- 24 Oct 2011	ASH	R11460 	3       Cast integer columns as nvarchar(11) data type.
-- 11 Apr 2012	SF	R11164	4	Include select statement within a @nErrorCode test block
-- 03 May 2012  MS      R100634 5       Added Case Reference field in select
-- 04 Nov 2015	KR	R53910	6	Adjust formatted names logic (DR-15543)


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0

Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, 0)

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select
		CAST(C.CASEID as nvarchar(11))+'^'+CONVERT(varchar,C.WHENMOVED,121)
					as RowKey,
		C.CASEID		as CaseKey,
		CS.IRN                  as CaseReference,
		C.WHENMOVED		as WhenMoved,
		C.FILELOCATION		as FileLocationKey,
		dbo.fn_GetTranslation(FLD.[DESCRIPTION],null,FLD.DESCRIPTION_TID,@sLookupCulture)
					as FileLocationDescription,
		C.FILEPARTID		as FilePartKey,
		FP.FILEPARTTITLE	as FilePartDescription,
		C.ISSUEDBY		as MovedByKey,
		S.NAMECODE              as MovedByCode,
		dbo.fn_FormatNameUsingNameNo(S.NAMENO, NULL)
					as MovedByDescription,
		C.BAYNO			as BayNo,
		FLD.USERCODE            as BarCode,
		C.DATESCANNED		as DateScanned,
		C.LOGDATETIMESTAMP      as LogDateTimeStamp

		from 		CASELOCATION C
		join            CASES CS on (C.CASEID = CS.CASEID)
		left join	TABLECODES FLD on (FLD.TABLECODE = C.FILELOCATION)
		left join	FILEPART FP on (FP.CASEID = C.CASEID and FP.FILEPART = C.FILEPARTID)
		left join	[NAME] S on (S.NAMENO = C.ISSUEDBY)
		where		C.CASEID = @pnCaseKey
		order by 	WHENMOVED desc"
	

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey		int,
			@sLookupCulture		nvarchar(10)',
			@pnCaseKey		= @pnCaseKey,
			@sLookupCulture		= @sLookupCulture
			
End			

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchFileLocation to public
GO