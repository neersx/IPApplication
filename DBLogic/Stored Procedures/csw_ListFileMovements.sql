-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListFileMovements									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListFileMovements]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListFileMovements.'
	Drop procedure [dbo].[csw_ListFileMovements]
End
Print '**** Creating Stored Procedure dbo.csw_ListFileMovements...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO

CREATE PROCEDURE dbo.csw_ListFileMovements
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey		int 		-- Mandatory
)
as
-- PROCEDURE:	csw_ListFileMovements
-- VERSION:	9
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the File Movements window.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	-------	------		-------	-----------------------------------------------
-- 24 Jan 2011	MS	RFC8363		1	Procedure created
-- 29 Apr 2011	JCLG	RFC10537	2	Add missing join with CASES for FILEPART 
-- 29 Apr 2011  MS      RFC100502 	3       Added CASEID check for FILEPART join
-- 23 May 2011  MS      RFC100530       4       Modify RowKey to get correct datetime value
-- 06 Jun 2011  MS      RFC10734        5       Fetch file movements based on CaseKey 
-- 08 Jun 2011	SF	RFC10789	6	Where claused appended twice
-- 24 Oct 2011	ASH	R11460 		7	Cast integer columns as nvarchar(11) data type.
-- 15 Apr 2013	DV	R13270		8	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910		9	Adjust formatted names logic (DR-15543).

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_NULLS ON

Declare @nErrorCode	int
Declare @sSQLString 	nvarchar(max)
Declare @sLookupCulture	nvarchar(10)
Declare @bIsRFIDSystem  bit

-- Initialise variables
Set @nErrorCode = 0
If @psCulture is not null
Begin
        Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
End 

-- Site control RFID System
If @nErrorCode = 0
Begin
        Set @sSQLString = "SELECT @bIsRFIDSystem = COLBOOLEAN                        
                        FROM SITECONTROL
                        WHERE CONTROLID = 'RFID System'"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@bIsRFIDSystem		bit                     output',
			@bIsRFIDSystem		= @bIsRFIDSystem        output  
End

-- File Movements
If @nErrorCode = 0
Begin

	Set @sSQLString = "Select
	CAST(F.CASEID as nvarchar(11))+'^'+CAST(F.FILELOCATION as nvarchar(11)) +'^'+CONVERT(nvarchar(50), F.WHENMOVED, 121)
				as RowKey,
	F.CASEID		as CaseKey,
        C.IRN                   as CaseReference,        
	F.WHENMOVED		as WhenMoved,       
        F.FILEPARTID            as FilePartKey,
        FP.FILEPARTTITLE        as FilePart,
	dbo.fn_GetTranslation(FLD.[DESCRIPTION],null,FLD.DESCRIPTION_TID,@sLookupCulture)
				as FileLocation,	
        F.ISSUEDBY              as MovedByKey,
	dbo.fn_FormatNameUsingNameNo(S.NAMENO, NULL)
				as MovedBy,
	F.BAYNO		        as BayNo,
        FR.DATEOFREQUEST        as DateRequested
	from 		CASELOCATION F
        inner join      CASES C on (C.CASEID = F.CASEID)
	left join	TABLECODES FLD on (FLD.TABLECODE = F.FILELOCATION)
	left join	[NAME] S on (S.NAMENO = F.ISSUEDBY)
        left join       FILEPART FP on (FP.CASEID = F.CASEID and FP.FILEPART = F.FILEPARTID)"

        If ISNULL(@bIsRFIDSystem,0) = 0
        Begin
                Set @sSQLString = @sSQLString + CHAR(10) + " 
        left join       FILEREQUEST FR on (FR.CASEID = F.CASEID and FR.FILELOCATION = F.FILELOCATION 
                        and (FR.FILEPARTID = F.FILEPARTID  or (FR.FILEPARTID is null and F.FILEPARTID is null))
                        and FR.SEQUENCENO = (
                                Select max(FRQ.SEQUENCENO) 
                                from FILEREQUEST FRQ
                                where FRQ.CASEID = F.CASEID 
                                and FRQ.FILELOCATION = F.FILELOCATION 
                                and (FRQ.FILEPARTID = F.FILEPARTID  or (FRQ.FILEPARTID is null and F.FILEPARTID is null)) ))
        "
        End
        Else
        Begin
               Set @sSQLString = @sSQLString + CHAR(10) + " 
               left join       RFIDFILEREQUEST FR on (FR.CASEID = F.CASEID and FR.FILELOCATION = F.FILELOCATION 
                                and FR.REQUESTID = (
                                Select max(FR1.REQUESTID)
                                from RFIDFILEREQUEST FR1
                                left join FILEPARTREQUEST FPR on (FR1.REQUESTID = FPR.REQUESTID and FR1.CASEID = FPR.CASEID)
                                where FR1.CASEID = F.CASEID 
                                and FR1.FILELOCATION = F.FILELOCATION 
                                and (FPR.FILEPART = F.FILEPARTID  or (FPR.FILEPART is null and F.FILEPARTID is null)) ))" 
        End
        
        Set @sSQLString = @sSQLString + CHAR(10) + " where F.CASEID = @pnCaseKey
        order by WHENMOVED desc"

        exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnCaseKey		int,
			@sLookupCulture		nvarchar(10)',
			@pnCaseKey		= @pnCaseKey,
			@sLookupCulture		= @sLookupCulture
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListFileMovements to public
GO