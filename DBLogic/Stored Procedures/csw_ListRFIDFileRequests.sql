-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListRFIDFileRequests									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListRFIDFileRequests]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListRFIDFileRequests.'
	Drop procedure [dbo].[csw_ListRFIDFileRequests]
End
Print '**** Creating Stored Procedure dbo.csw_ListRFIDFileRequests...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListRFIDFileRequests
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int 		= null,
	@psCaseKeys             nvarchar(max)   = null
)
as
-- PROCEDURE:	csw_ListRFIDFileRequests
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the File Requests data.

-- MODIFICATIONS :
-- Date		Who	Change	   Version	Description
-- -----------	-------	------	   -------	-----------------------------------------------
-- 28 Mar 2011	MS	RFC100502   1	        Procedure created
-- 20 Nov 2011  MS      RFC11208    2           Retreive file requests for multiple cases
-- 16 Jul 2012  MS      RFC100634   3           Added LOGDATETIMESTAMP in order by for sorting it in recent added order        
-- 10 Nov 2015	KR	R53910	    4		Adjust formatted names logic (DR-15543)     


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(max)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
If @psCulture is not null
Begin
        Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
End 

If @nErrorCode = 0
Begin       
        Set @sSQLString = "Select distinct
        F.REQUESTID             as RowKey,
	F.CASEID		as CaseKey,
	CASE WHEN F.CASEID is null then 'CASES' else C.IRN end as CaseReference,
        F.DATEOFREQUEST		as DateOfRequest,
        F.DATEREQUIRED          as DateRequired,        
	F.FILELOCATION		as FileLocationKey,
	dbo.fn_GetTranslation(FLD.[DESCRIPTION],null,FLD.DESCRIPTION_TID,@sLookupCulture)
				as FileLocationDescription,	
        F.EMPLOYEENO            as EmployeeKey,
        S.NAMECODE              as EmployeeCode,
	dbo.fn_FormatNameUsingNameNo(S.NAMENO, S.NAMESTYLE)
				as EmployeeDescription,
        F.REMARKS               as Remarks,
        F.PRIORITY              as PriorityKey,
        dbo.fn_GetTranslation(TC1.[DESCRIPTION],null,TC1.DESCRIPTION_TID,@sLookupCulture)
				as Priority,	
        dbo.fn_GetTranslation(TC2.[DESCRIPTION],null,TC2.DESCRIPTION_TID,@sLookupCulture)
				as Status, 
        F.LOGDATETIMESTAMP      as LogDateTimeStamp,
        ISNULL(F.ISSELFSEARCH,0) as IsSelfSearch,
        FAD.RESOURCENO          as DeviceKey,
        dbo.fn_GetTranslation(R.[DESCRIPTION],null,R.DESCRIPTION_TID,@sLookupCulture) 
                                as Device,
        dbo.fn_GetConcatenatedDataForFileRequest(F.REQUESTID, 'CASE') as CaseKeys
        FROM RFIDFILEREQUEST F
        left join RFIDFILEREQUESTCASES FC on (F.REQUESTID = FC.REQUESTID)
        left join CASES C on (F.CASEID = C.CASEID)
	left join TABLECODES FLD on (FLD.TABLECODE = F.FILELOCATION)	
	left join [NAME] S on (S.NAMENO = F.EMPLOYEENO)  
        left join TABLECODES TC1 on (TC1.TABLECODE = F.PRIORITY)
        left join TABLECODES TC2 on (TC2.USERCODE = F.STATUS and TC2.TABLETYPE = (Select TABLETYPE from TABLETYPE where TABLENAME = 'File Request Status'))
        left join FILEREQASSIGNEDDEVICE FAD on (FAD.REQUESTID = F.REQUESTID and F.ISSELFSEARCH = 1)
        left join RESOURCE R on (R.RESOURCENO = FAD.RESOURCENO)
        WHERE F.STATUS <> 3"
        
        If @pnCaseKey is not null -- single case
        Begin
                Set @sSQLString = @sSQLString + CHAR(10) +"and (F.CASEID = @pnCaseKey or FC.CASEID = @pnCaseKey)"
        End
        Else -- Multiple cases
        Begin
                Set @sSQLString = @sSQLString + CHAR(10) +"and (F.CASEID in (Select PARAMETER from fn_Tokenise (@psCaseKeys, ',')) 
                                                         or FC.CASEID in (Select PARAMETER from fn_Tokenise (@psCaseKeys, ',')))"
        End  
                
        Set @sSQLString = @sSQLString + CHAR(10) +"order by DATEOFREQUEST desc, LOGDATETIMESTAMP desc"         

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey		int,
			@psCaseKeys             nvarchar(max),
			@sLookupCulture		nvarchar(10)',
			@pnCaseKey		= @pnCaseKey,
			@psCaseKeys             = @psCaseKeys,
			@sLookupCulture		= @sLookupCulture	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListRFIDFileRequests to public
GO