-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListFileRequests									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListFileRequests]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListFileRequests.'
	Drop procedure [dbo].[csw_ListFileRequests]
End
Print '**** Creating Stored Procedure dbo.csw_ListFileRequests...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListFileRequests
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int 		-- Mandatory
)
as
-- PROCEDURE:	csw_ListFileRequests
-- VERSION:	5
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the File Requests data.

-- MODIFICATIONS :
-- Date		Who	Change	   Version	Description
-- -----------	-------	------	   -------	-----------------------------------------------
-- 28 Mar 2011	MS	RFC100502   1	        Procedure created   
-- 04 Nov 2011	ASH	R11460	    2	        Cast integer columns as nvarchar(11) data type.
-- 04 May 2012  MS	R100634     3           Return Case Reference in the select list 
-- 15 Apr 2013	DV	R13270	    4		Increase the length of nvarchar to 11 when casting or declaring integer    
-- 10 Nov 2015	KR	R53910	    5		Adjust formatted names logic (DR-15543)     

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
If @psCulture is not null
Begin
        Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
End 


If @nErrorCode = 0
Begin

        Set @sSQLString = "Select
        CAST(F.CASEID as nvarchar(11))+'^'+CAST(F.FILELOCATION as nvarchar(11)) +'^'+CAST(F.SEQUENCENO as nvarchar(10))
				as RowKey,
	F.CASEID		as CaseKey,
	C.IRN                   as CaseReference,
        F.FILEPARTID            as FilePartKey,
        FP.FILEPARTTITLE	as FilePartDescription,
        F.SEQUENCENO            as SequenceNo,
	F.DATEOFREQUEST		as DateOfRequest,
        F.DATEREQUIRED          as DateRequired,        
	F.FILELOCATION		as FileLocationKey,
	dbo.fn_GetTranslation(FLD.[DESCRIPTION],null,FLD.DESCRIPTION_TID,@sLookupCulture)
				as FileLocationDescription,	
        F.EMPLOYEENO            as EmployeeKey,
        S.NAMECODE              as EmployeeCode,
	dbo.fn_FormatNameUsingNameNo(S.NAMENO, NULL)
				as EmployeeDescription,
        F.REMARKS               as Remarks,
        F.PRIORITY              as PriorityKey,
        dbo.fn_GetTranslation(TC1.[DESCRIPTION],null,TC1.DESCRIPTION_TID,@sLookupCulture)
				as Priority,	
        dbo.fn_GetTranslation(TC2.[DESCRIPTION],null,TC2.DESCRIPTION_TID,@sLookupCulture)
				as Status, 
        F.LOGDATETIMESTAMP      as LogDateTimeStamp
        FROM FILEREQUEST F
        join CASES C on (F.CASEID = C.CASEID)
	left join TABLECODES FLD on (FLD.TABLECODE = F.FILELOCATION)	
	left join [NAME] S on (S.NAMENO = F.EMPLOYEENO)        
        left join TABLECODES TC1 on (TC1.TABLECODE = F.PRIORITY and TC1.TABLETYPE = 407)
        left join TABLECODES TC2 on (TC2.USERCODE = F.STATUS and TC2.TABLETYPE = 404)
        left join	FILEPART FP on (FP.CASEID = F.CASEID and FP.FILEPART = F.FILEPARTID)
        WHERE F.CASEID = @pnCaseKey
        order by DATEOFREQUEST desc"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey		int,
			@sLookupCulture		nvarchar(10)',
			@pnCaseKey		= @pnCaseKey,
			@sLookupCulture		= @sLookupCulture
End 

Return @nErrorCode
GO

Grant execute on dbo.csw_ListFileRequests to public
GO