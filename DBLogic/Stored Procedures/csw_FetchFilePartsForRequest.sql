-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchFilePartsForRequest									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchFilePartsForRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_FetchFilePartsForRequest.'
	Drop procedure [dbo].[csw_FetchFilePartsForRequest]
End
Print '**** Creating Stored Procedure dbo.csw_FetchFilePartsForRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_FetchFilePartsForRequest
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int 		= null,
	@psCaseKeys             nvarchar(max)   = null,
        @pnRequestId            int             = null
)
as
-- PROCEDURE:	csw_FetchFilePartsForRequest
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Fetch file parts for given File Request.

-- MODIFICATIONS :
-- Date		Who	Change	   Version	Description
-- -----------	-------	------	   -------	-----------------------------------------------
-- 28 Mar 2011	MS	RFC100502   1	        Procedure created    
-- 20 Nov 2011  MS      RFC11208    2           Retreive file parts for multiple cases    
-- 05 Jul 2012  MS      RFC100634   3           Return RequestKey and IsMain in the output for handling multiple file requests
-- 10 Jul 2012  MS      RFC100714   4           Return HasFurtherSearchStats in the select list for finding out 
--                                              whether the search status id FURTHER SEARCH or not
-- 15 Apr 2013	DV		R13270		5			Increase the length of nvarchar to 11 when casting or declaring integer

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0) 

If @nErrorCode = 0
Begin
        Set @sSQLString = "SELECT 
                        cast(FP.CASEID as nvarchar(11)) + '^' + cast(FP.FILEPART as nvarchar(10)) + '^' + cast(@pnRequestId as nvarchar(11))      as RowKey,
                        FP.FILEPART             as FilePartKey,
                        FP.FILEPARTTITLE        as FilePartDescription,
                        FP.CASEID               as CaseKey,
                        C.IRN                   as CaseReference,
                        @pnRequestId            as RequestKey,
                        dbo.fn_GetTranslation(PT.[DESCRIPTION],null,PT.DESCRIPTION_TID,@sLookupCulture)
				                as FilePartType,
                        dbo.fn_GetTranslation(FLD.[DESCRIPTION],null,FLD.DESCRIPTION_TID,@sLookupCulture)
				                as LastLocation,
                        A.WHENMOVED             as LastLocated,
                        CASE WHEN EXISTS (Select 1 from FILEPARTREQUEST where 
                                                REQUESTID = @pnRequestId 
                                                and FILEPART = FP.FILEPART 
                                                and CASEID = FP.CASEID)
                             THEN 1
                             ELSE 0 
                        END                     as IsSelected,
                        FP.ISMAINFILE           as IsMain,
                        CASE WHEN EXISTS (Select 1 from FILEPARTREQUEST FPR 
                                                JOIN RFIDFILEREQUEST RF on (RF.REQUESTID = FPR.REQUESTID)
                                                Where 
                                                FP.FILEPART = FPR.FILEPART 
                                                and FP.CASEID = FPR.CASEID
                                                and RF.STATUS in (0,1)
                                                and FPR.SEARCHSTATUS = 3)
                             THEN 1
                             ELSE 0 
                             END                as HasFurtherSearchStatus
                        FROM FILEPART FP
                        JOIN CASES C on (C.CASEID = FP.CASEID)
                        LEFT JOIN CASELOCATION A on (A.FILEPARTID = FP.FILEPART 
                                and A.CASEID = FP.CASEID 
                                and A.WHENMOVED = (
                                        Select MAX(WHENMOVED) 
                                        from CASELOCATION 
                                        where CASEID = FP.CASEID
                                        and FILEPARTID = A.FILEPARTID))
                        LEFT JOIN TABLECODES FLD on (FLD.TABLECODE = A.FILELOCATION)    
                        LEFT JOIN TABLECODES PT on (PT.TABLECODE = FP.FILEPARTTYPE)"
                        
                        If @psCaseKeys is not null and @psCaseKeys <> '' -- Multiple cases
                        Begin
                                Set @sSQLString = @sSQLString + CHAR(10) +"where FP.CASEID in (Select PARAMETER from fn_Tokenise (@psCaseKeys, ','))"
                        End   
                        ELSE If @pnCaseKey is not null -- single case
                        Begin
                                Set @sSQLString = @sSQLString + CHAR(10) +"where FP.CASEID = @pnCaseKey"
                        End

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey              int,
                        @pnRequestId            int,  
                        @psCaseKeys             nvarchar(max),
                        @sLookupCulture		nvarchar(10)',
			@pnCaseKey		= @pnCaseKey,
                        @pnRequestId            = @pnRequestId,
                        @psCaseKeys             = @psCaseKeys,
                        @sLookupCulture         = @sLookupCulture
       
End    

Return @nErrorCode
GO

Grant execute on dbo.csw_FetchFilePartsForRequest to public
GO