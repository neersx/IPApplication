-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListFilePartsForRequest
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListFilePartsForRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListFilePartsForRequest.'
	Drop procedure [dbo].[csw_ListFilePartsForRequest]
End
Print '**** Creating Stored Procedure dbo.csw_ListFilePartsForRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListFilePartsForRequest
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnRequestId		        int,	        -- Mandatory		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	csw_ListFilePartsForRequest
-- VERSION:	1
-- DESCRIPTION:	Returns the file request details.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 Dec 2011	MS	R11208	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sLookupCulture		nvarchar(10)
Declare @sSQLString             nvarchar(4000)
		
-- Initialise variables
Set @nErrorCode                 = 0
set @sLookupCulture             = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Get selected file parts
If   @nErrorCode=0
Begin
        Set @sSQLString = "Select 
        RF.REQUESTID            as RequestKey,
        CAST(RF.REQUESTID  as nvarchar(11)) + '^' + cast(FP.CASEID as nvarchar(11)) + '^' + cast(FP.FILEPART as nvarchar(10))       as RowKey,
        FP.FILEPART                     as FilePartKey,
        FP.FILEPARTTITLE                as FilePartDescription,
        FP.CASEID                       as CaseKey,
        C.IRN                           as CaseReference,
	dbo.fn_GetTranslation(PT.[DESCRIPTION],null,PT.DESCRIPTION_TID,@sLookupCulture)
				        as FilePartType,
        dbo.fn_GetTranslation(FLD.[DESCRIPTION],null,FLD.DESCRIPTION_TID,@sLookupCulture)
				        as LastLocation,
        A.WHENMOVED                     as LastLocated,
        0                               as SearchStatusKey,
        dbo.fn_GetTranslation(SS.[DESCRIPTION],null,SS.DESCRIPTION_TID,@sLookupCulture)
                                        as SearchStatus
        FROM RFIDFILEREQUEST RF
        LEFT JOIN RFIDFILEREQUESTCASES RFC on (RFC.REQUESTID = RF.REQUESTID) 
        JOIN FILEPART FP on (FP.CASEID = RFC.CASEID or FP.CASEID = RF.CASEID)
        JOIN CASES C on (C.CASEID = FP.CASEID)  
        LEFT JOIN CASELOCATION A on (A.FILEPARTID = FP.FILEPART 
                                and A.CASEID = FP.CASEID 
                                and A.WHENMOVED = (
                                        Select MAX(WHENMOVED) 
                                        from CASELOCATION 
                                        where CASEID = FP.CASEID
                                        and FILEPARTID = A.FILEPARTID))
        LEFT JOIN TABLECODES FLD on (FLD.TABLECODE = A.FILELOCATION)    
        LEFT JOIN TABLECODES PT on (PT.TABLECODE = FP.FILEPARTTYPE)        
        LEFT JOIN TABLECODES SS on (SS.USERCODE = 0 and SS.TABLETYPE=-507)
        WHERE RF.REQUESTID = @pnRequestId"
        
        exec @nErrorCode = sp_ExecuteSql @sSQLString,
                N'@pnRequestId          int,
                @sLookupCulture		nvarchar(10)',
                @pnRequestId            = @pnRequestId,
                @sLookupCulture         = @sLookupCulture
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListFilePartsForRequest to public
GO
