-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListFilePart
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListFilePart]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListFilePart.'
	Drop procedure [dbo].[csw_ListFilePart]
End
Print '**** Creating Stored Procedure dbo.csw_ListFilePart...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[csw_ListFilePart]
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		-- Mandatory
)
as
-- PROCEDURE:	csw_ListFilePart
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List all file parts for the CaseKey

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Oct 2010	PA	RFC9021	1	Procedure created
-- 12 Feb 2011  MS      RFC8363 2       Added RFID Code
-- 24 Mar 2011  MS      RFC100502 3     Added FILEPARTTYPE, FILERECORDSTATUS, ISMAINFILE

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)


If @nErrorCode = 0
Begin
	Set @sSQLString = "SELECT F.FILEPART as 'FilePartKey', 
        F.FILEPARTTITLE as 'FilePartTitle', 
        F.RFID as 'RFIDCode',
        F.FILEPARTTYPE as 'FilePartType',
        "+dbo.fn_SqlTranslatedColumn('TABLECODES','TABLECODE',null,'T1',@sLookupCulture,@pbCalledFromCentura)+"
                as 'FilePartTypeDesc',
        F.FILERECORDSTATUS as 'FileRecordStatus',
        "+dbo.fn_SqlTranslatedColumn('TABLECODES','TABLECODE',null,'T2',@sLookupCulture,@pbCalledFromCentura)+"
                as 'FileRecordStatusDesc',
        ISNULL(F.ISMAINFILE,0) as 'IsMainFile',
        F.LOGDATETIMESTAMP as 'LogDateTimeStamp' 
        FROM FILEPART F
        LEFT JOIN TABLECODES T1 on (T1.TABLECODE = F.FILEPARTTYPE and T1.TABLETYPE = 406)
        LEFT JOIN TABLECODES T2 on (T2.TABLECODE = F.FILEPARTTYPE and T2.TABLETYPE = 405)
	where	CASEID = @pnCaseKey"

	Exec @nErrorCode = sp_executesql @sSQLString,
			N'@pnCaseKey		int',            
			  @pnCaseKey		= @pnCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListFilePart to public
GO
