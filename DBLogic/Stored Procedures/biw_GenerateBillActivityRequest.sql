-----------------------------------------------------------------------------------------------------------------------------
-- Creation of biw_GenerateBillActivityRequest
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[biw_GenerateBillActivityRequest]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.biw_GenerateBillActivityRequest.'
	Drop procedure [dbo].[biw_GenerateBillActivityRequest]
End
Print '**** Creating Stored Procedure dbo.biw_GenerateBillActivityRequest...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.biw_GenerateBillActivityRequest
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnItemEntityNo	        int,
	@pnItemTransNo	        int,
        @pnTransType             int             = null,
        @pnMainCaseId           int             = null,
        @pnOfficeId              int             = null
)
as
-- PROCEDURE:	biw_GenerateBillActivityRequest
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Generates activity request for finalised open item

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 FEB 2018	MS	R72834	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
Declare @sSQLString 	nvarchar(4000)
Declare @nBillFormatId int
Declare @nLanguage int
Declare @nEntityNo int
Declare @nDebtorNo int
Declare @sCaseType nvarchar(1)
Declare @sAction nvarchar(2)
Declare @sPropertyType nvarchar(1)
Declare @nSingleCase int
Declare @nEmployeeNo int
Declare @nBillLetterNo int
Declare @nCoveringLetterNo int
Declare @nCreditBillLetterGen int
Declare @nInstructor int
Declare @sDebitOpenItemNo nvarchar(12)
Declare @bDebug		bit

-- Initialise variables
Set @nErrorCode = 0
Set @bDebug = 0

Select @nCreditBillLetterGen = COLINTEGER FROM SITECONTROL WHERE CONTROLID = 'Credit Bill Letter Generation'

If (@nErrorCode = 0 and @pnMainCaseId is not null)
Begin

	If (@bDebug = 1)
	Begin
		Print 'Get Case details to insert into ACTIVITYREQUEST'
	End

	Set @sSQLString = "SELECT	@sCaseType = C.CASETYPE,
		@sPropertyType = C.PROPERTYTYPE
		FROM CASES C
		WHERE C.CASEID = @pnMainCaseId"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@sCaseType		nvarchar(1) OUTPUT,
				  @sPropertyType	nvarchar(1) OUTPUT,
				  @pnMainCaseId		int',
				  @sCaseType = @sCaseType OUTPUT,
				  @sPropertyType = @sPropertyType OUTPUT,
				  @pnMainCaseId = @pnMainCaseId


        If @nErrorCode = 0
        Begin
	Set @sSQLString = "Select @nSingleCase = CASE WHEN WHCASECOUNT.CASECOUNT > 1 THEN 0 -- Multi-Case
							WHEN WHCASECOUNT.CASECOUNT = 1 THEN 1 -- Single Case
							WHEN WHCASECOUNT.CASECOUNT = 0 THEN 2 -- Debtor Only
							END	-- Single Case
		From (Select COUNT(*) as CASECOUNT 
				From WORKHISTORY 
				Where REFENTITYNO = @pnItemEntityNo 
				and REFTRANSNO = @pnItemTransNo 
				Group by CASEID) AS WHCASECOUNT"

	exec @nErrorCode=sp_executesql @sSQLString, 
				N'@nSingleCase		int OUTPUT,
				  @pnItemEntityNo	int,
				  @pnItemTransNo	int',
				  @nSingleCase = @nSingleCase OUTPUT,
				  @pnItemEntityNo = @pnItemEntityNo,
				  @pnItemTransNo = @pnItemTransNo
        End

End

if (@nErrorCode = 0)
Begin
        -- Get the properties required to retrieve the letter for each openitem
        DECLARE OpenItem_Cursor CURSOR FOR 
	        SELECT O.BILLFORMATID, O.LANGUAGE, O.ACCTENTITYNO, O.ACCTDEBTORNO, O.ACTION, O.EMPLOYEENO,
	        B.DEBITNOTE, B.COVERINGLETTER, O.OPENITEMNO
	        FROM OPENITEM O
	        Left Join BILLFORMAT B ON B.BILLFORMATID = O.BILLFORMATID
	        WHERE  O.ITEMENTITYNO = @pnItemEntityNo
	        and		O.ITEMTRANSNO = @pnItemTransNo

        OPEN OpenItem_Cursor

        FETCH NEXT FROM OpenItem_Cursor 
        INTO @nBillFormatId, @nLanguage, @nEntityNo, @nDebtorNo, @sAction, @nEmployeeNo,
        @nBillLetterNo, @nCoveringLetterNo, @sDebitOpenItemNo

        WHILE (@nErrorCode = 0 and @@FETCH_STATUS = 0)
        Begin

                Set @nInstructor = null

	        -- if credit full bill and related debit note has no bill format (cfIsDocGenBillReq)
	        If @nErrorCode = 0 
		        and @pnTransType = 511
		        and exists (SELECT * FROM OPENITEM OID
					        JOIN OPENITEM OIC ON OIC.ASSOCOPENITEMNO = OID.OPENITEMNO
					        WHERE OID.BILLFORMATID IS NULL
					        and OIC.ITEMENTITYNO = @pnItemEntityNo
					        and OIC.ITEMTRANSNO = @pnItemTransNo)
	        Begin

		        Set @sDebitOpenItemNo = null
		
		        Set @nBillLetterNo = null
		        Set @nCoveringLetterNo = null

		        If (@nCreditBillLetterGen = 1) -- (cfIsActivityRequestLetterReq)
		        Begin
			        -- Get the letter from ActivityHistory (cfRetrieveChGenLetters)
			        select
			        @nBillLetterNo = A.LETTERNO, 
			        @nCoveringLetterNo = A.COVERINGLETTERNO,
			        @nInstructor = OIDEBIT.INSTRUCTOR,
			        @sDebitOpenItemNo = OIDEBIT.OPENITEMNO
			        From ACTIVITYHISTORY A
			        Join (SELECT OID.OPENITEMNO, OIC.ACCTDEBTORNO as INSTRUCTOR
					        From OPENITEM OID
					        Join OPENITEM OIC ON OIC.ASSOCOPENITEMNO = OID.OPENITEMNO
					        Where OIC.ITEMENTITYNO = @pnItemEntityNo
					        and OIC.ITEMTRANSNO = @pnItemTransNo) as OIDEBIT
				        on (OIDEBIT.OPENITEMNO = A.DEBITNOTENO)
			        Where A.ACTIVITYCODE IN (3202, 3204)
			        and A.LETTERNO IS NOT NULL

		        End
		        Else If (@nCreditBillLetterGen = 2)
		        Begin
			        -- Retrieve best fit Bill Format
			        exec @nErrorCode = dbo.biw_FetchBestBillFormat
					        @pnUserIdentityId = @pnUserIdentityId,		-- Mandatory
					        @psCulture = @psCulture,
					        @pbCalledFromCentura = @pbCalledFromCentura,
					        @pnBillFormatId = @nBillFormatId OUTPUT,
					        @pnLanguage	= @nLanguage, -- Set the remainder if best fit is to be used.
					        @pnEntityNo = @nEntityNo,
					        @pnNameNo = @nDebtorNo,
					        @psCaseType = @sCaseType,
					        @psAction = @sAction,
					        @psPropertyType	= @sPropertyType,
					        @pnRenewalWIP =	null, -- always null in this case
					        @pnSingleCase = @nSingleCase,
					        @pnEmployeeNo = @nEmployeeNo,
					        @pnOfficeId	= @pnOfficeId,
					        @pbReturnBillFormatDetails = 0

			        If (@nBillFormatId is not null)
			        Begin
				        Select 
				        @nBillLetterNo = B.DEBITNOTE,
				        @nCoveringLetterNo = B.COVERINGLETTER
				        from BILLFORMAT B
				        WHERE BILLFORMATID = @nBillFormatId
			        End
		        End
	        End
	        Else
	        Begin
		        If (@nBillLetterNo is not null)
		        Begin
			        If not exists (Select * from WORKHISTORY 
							        Where REFENTITYNO = @pnItemEntityNo and REFTRANSNO = @pnItemTransNo
							        and CASEID is not null)
			        Begin
				        -- DEBTOR ONLY BILL can only generate a letter with NameNo as entry point.
				        If not exists (Select * from LETTER
								        Where ENTRYPOINTTYPE = 4041 or ENTRYPOINTTYPE is null
								        And LETTERNO = @nBillLetterNo)
				        Begin
					        Set @nBillLetterNo = null
				        End
			        End
		        End
	        End

	        If (@nErrorCode = 0 and @nBillLetterNo is not null)
	        Begin
	
		        If (@bDebug = 1)
		        Begin
			        Print 'Insert into ACTIVITYREQUEST'
		        End
	
		        -- Insert Activity Request
		        Insert into ACTIVITYREQUEST
		        (
		        CASEID, WHENREQUESTED, SQLUSER,
		        ENTITYNO, PROGRAMID,
		        LETTERNO, COVERINGLETTERNO, HOLDFLAG, INSTRUCTOR,

		        DEBITNOTENO,
		        ACTIVITYTYPE,
		        ACTIVITYCODE,
		        PROCESSED,
		        DEBTOR,
		        IDENTITYID
		        )
		        select
		        @pnMainCaseId, GETDATE(), system_user,
		        @nEntityNo, 'BILLING',
		        @nBillLetterNo, @nCoveringLetterNo, L.HOLDFLAG,
		        @nInstructor,
		        CASE WHEN @sDebitOpenItemNo = "" then NULL ELSE @sDebitOpenItemNo END,
		        32, -- activitytype (System Activity)
		        3204, -- activity (letter)
		        0, -- PROCESSED
		        @nDebtorNo,
		        @pnUserIdentityId
		        From LETTER L 
		        Where L.LETTERNO = @nBillLetterNo
	        End

	        FETCH NEXT FROM OpenItem_Cursor 
	        INTO @nBillFormatId, @nLanguage, @nEntityNo, @nDebtorNo, @sAction, @nEmployeeNo,
		         @nBillLetterNo, @nCoveringLetterNo, @sDebitOpenItemNo
        End

        CLOSE OpenItem_Cursor
        DEALLOCATE OpenItem_Cursor

End

Return @nErrorCode
GO

Grant execute on dbo.biw_GenerateBillActivityRequest to public
GO
