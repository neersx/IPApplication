-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_AssignBatchNumber
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_AssignBatchNumber]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_AssignBatchNumber.'
	Drop procedure [dbo].[ede_AssignBatchNumber]
End
Print '**** Creating Stored Procedure dbo.ede_AssignBatchNumber...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_AssignBatchNumber
(
	@pnBatchNo	int OUTPUT
)
as
-- PROCEDURE:	ede_AssignBatchNumber
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Updates the keys of the EDE holding tables with a generated key.
--		NOTE: If adding/removing EDE tables, you must also remove the references
--		to these tables from stored proc ede_ClearCorruptBatch.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20 Aug 2014	AT	R37920	1	Procedure Created.
 
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
 
Declare	@nErrorCode 	int
Declare @nBatchNo int

-- Initialise variables
Set @nErrorCode = 0

SET @nBatchNo = (select max(BATCHNO) from EDETRANSACTIONHEADER WHERE USERID = USER AND PROCESSED=0)

if @nErrorCode = 0
Begin
	Update EDESENDERDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDESENDERDETAILS
	Set SENDERNAMENO = COLINTEGER
	FROM SITECONTROL
	Where SENDERNAMENO IS NULL and BATCHNO = @nBatchNo
	and CONTROLID = 'HOMENAMENO'

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDESENDERSOFTWARE
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDERECEIVERDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDERECEIVERSOFTWARE
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDETRANSACTIONBODY
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDETRANSACTIONMESSAGEDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDETRANSACTIONCONTENTDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDECASEDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEDESCRIPTIONDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEIDENTIFIERNUMBERDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEDESIGNATEDCOUNTRYDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEEVENTDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDECHARGEDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEGOODSSERVICESDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDECLASSDESCRIPTION
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDECASENAMEDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEADDRESSBOOK
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDENAME
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEFORMATTEDNAME
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEFORMATTEDADDRESS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDECONTACTINFORMATIONDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEASSOCIATEDCASEDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEDOCUMENT
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDENAMEADDRESSDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEPAYMENTDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEPAYMENTMETHOD
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEACCOUNT
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDECARDACCOUNT
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDECHEQUE
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEBANKTRANSFER
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEPAYMENTFEEDETAILS
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEFORMATTEDATTNOF
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	Update EDEPATENTTERMADJ
	Set BATCHNO = @nBatchNo Where BATCHNO is null and USERID = USER;

	Select @nErrorCode = @@ERROR
End

if @nErrorCode = 0
Begin
	UPDATE EDETRANSACTIONHEADER
	SET	PROCESSED = 1,
		BATCHSTATUS = 1280
	WHERE USERID = USER AND PROCESSED = 0;

	Select @nErrorCode = @@ERROR
End

-- Return the output
Set @pnBatchNo = @nBatchNo

Return @nErrorCode
GO

Grant execute on dbo.ede_AssignBatchNumber to public
GO
