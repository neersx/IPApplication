-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetFileRequestDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetFileRequestDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetFileRequestDetails.'
	Drop procedure [dbo].[csw_GetFileRequestDetails]
End
Print '**** Creating Stored Procedure dbo.csw_GetFileRequestDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_GetFileRequestDetails
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnRequestId		        int,	        -- Mandatory		
	@pbCalledFromCentura		bit 		= 0
)
as
-- PROCEDURE:	csw_GetFileRequestDetails
-- VERSION:	2
-- DESCRIPTION:	Returns the file request details.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28 Nov 2011	MS	R11208	1	Procedure created
-- 04 Nov 2015	KR	R53910	2	Adjust formatted names logic (DR-15543)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sLookupCulture		nvarchar(10)
Declare @sSQLString             nvarchar(4000)
		
-- Initialise variables
Set @nErrorCode                 = 0
set @sLookupCulture             = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Get Assigned Staff
If   @nErrorCode=0 
Begin
        Set @sSQLString = "Select 
        F.REQUESTID                     as RequestKey,
	cast(F.REQUESTID as nvarchar(11)) + '^' + cast(F.NAMENO as nvarchar(11)) 
	                                as RowKey,
	F.NAMENO                        as StaffKey,
	N.NAMECODE                      as StaffCode,
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, N.NAMESTYLE) 
	                                as StaffName,
        F.LOGDATETIMESTAMP              as LastModifiedDate
        FROM FILEREQASSIGNEDEMP F
        join NAME N on (F.NAMENO = N.NAMENO)
        WHERE F.REQUESTID = @pnRequestId"
        
        exec @nErrorCode = sp_ExecuteSql @sSQLString,
                N'@pnRequestId          int',
                @pnRequestId            = @pnRequestId
End

-- Get Assigned Devices
If   @nErrorCode=0
Begin
        Set @sSQLString = "Select 
        F.REQUESTID                     as RequestKey,
	cast(F.REQUESTID as nvarchar(11)) + '^' + cast(F.RESOURCENO as nvarchar(11)) 
	                                as RowKey,
	F.RESOURCENO                    as ResourceKey,
	R.DESCRIPTION                   as ResourceDescription,
        F.LOGDATETIMESTAMP              as LastModifiedDate
        FROM FILEREQASSIGNEDDEVICE F
        join RESOURCE R on (R.RESOURCENO = F.RESOURCENO)
        WHERE F.REQUESTID = @pnRequestId"
        
        exec @nErrorCode = sp_ExecuteSql @sSQLString,
                N'@pnRequestId          int',
                @pnRequestId            = @pnRequestId
End

-- Get selected file parts
If   @nErrorCode=0
Begin
        Set @sSQLString = "Select 
        F.REQUESTID                     as RequestKey,
	cast(F.REQUESTID as nvarchar(11)) + '^' + cast(F.CASEID as nvarchar(11)) + '^' + cast(F.FILEPART as nvarchar(11))
	                                as RowKey,
        F.CASEID                        as CaseKey,
        C.IRN                           as CaseReference,
	F.FILEPART                      as FilePartKey,
	FP.FILEPARTTITLE                as FilePartDescription,
	dbo.fn_GetTranslation(PT.[DESCRIPTION],null,PT.DESCRIPTION_TID,@sLookupCulture)
				        as FilePartType,
        dbo.fn_GetTranslation(FLD.[DESCRIPTION],null,FLD.DESCRIPTION_TID,@sLookupCulture)
				        as LastLocation,
        A.WHENMOVED                     as LastLocated,
        F.SEARCHSTATUS                  as SearchStatusKey,
        dbo.fn_GetTranslation(SS.[DESCRIPTION],null,SS.DESCRIPTION_TID,@sLookupCulture)
				        as SearchStatus,
        F.LOGDATETIMESTAMP              as LastModifiedDate
        FROM FILEPARTREQUEST F
        join FILEPART FP on (FP.CASEID = F.CASEID and FP.FILEPART = F.FILEPART)
        JOIN CASES C on (C.CASEID = F.CASEID)
        LEFT JOIN CASELOCATION A on (A.FILEPARTID = F.FILEPART 
                  and A.CASEID = F.CASEID 
                  and A.WHENMOVED = (   Select MAX(WHENMOVED) 
                                        from CASELOCATION 
                                        where CASEID = F.CASEID
                                        and FILEPARTID = A.FILEPARTID))
        LEFT JOIN TABLECODES FLD on (FLD.TABLECODE = A.FILELOCATION)    
        LEFT JOIN TABLECODES PT on (PT.TABLECODE = FP.FILEPARTTYPE)
        LEFT JOIN TABLECODES SS on (SS.USERCODE = F.SEARCHSTATUS and SS.TABLETYPE=-507)
        WHERE F.REQUESTID = @pnRequestId"
        
        exec @nErrorCode = sp_ExecuteSql @sSQLString,
                N'@pnRequestId          int,
                @sLookupCulture		nvarchar(10)',
                @pnRequestId            = @pnRequestId,
                @sLookupCulture         = @sLookupCulture
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetFileRequestDetails to public
GO
