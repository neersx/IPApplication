-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_ClearCorruptBatch
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_ClearCorruptBatch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_ClearCorruptBatch.'
	Drop procedure [dbo].[ede_ClearCorruptBatch]
End
Print '**** Creating Stored Procedure dbo.ede_ClearCorruptBatch...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_ClearCorruptBatch
(
	@psUserName	nvarchar(40)
)
as
-- PROCEDURE:	ede_ClearCorruptBatch
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Clears a corrupt batch from the EDE Holding tables.
--		NOTE: If adding/removing EDE tables, you must also remove the references
--		to these tables from stored proc ede_UpdateKeys.
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02/01/2007	AT	13997	1	Procedure Created
-- 31/05/2007	AT	12330	2	Changed to avoid deleting EDETRANSACTIONHEADER with -ve BatchNo
-- 21/08/2014	AT	R37920	3	Remove ImportQueue check.
 
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

If exists (SELECT 1 from EDETRANSACTIONHEADER where BATCHSTATUS IS NULL and USERID = @psUserName and BATCHNO > 0)
Begin
	Delete from EDETRANSACTIONHEADER where BATCHSTATUS IS NULL AND USERID = @psUserName and BATCHNO > 0
End

If exists (SELECT 1 from EDESENDERDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDESENDERDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDESENDERSOFTWARE where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDESENDERSOFTWARE where BATCHNO IS NULL AND USERID = @psUserName
End

If exists (SELECT 1 from EDERECEIVERDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDERECEIVERDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDERECEIVERSOFTWARE where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDERECEIVERSOFTWARE where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDETRANSACTIONBODY where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDETRANSACTIONBODY where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDETRANSACTIONMESSAGEDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDETRANSACTIONMESSAGEDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDETRANSACTIONCONTENTDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDETRANSACTIONCONTENTDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDECASEDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDECASEDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEDESCRIPTIONDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEDESCRIPTIONDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEIDENTIFIERNUMBERDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEIDENTIFIERNUMBERDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEDESIGNATEDCOUNTRYDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEDESIGNATEDCOUNTRYDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEEVENTDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEEVENTDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEGOODSSERVICESDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEGOODSSERVICESDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDECLASSDESCRIPTION where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDECLASSDESCRIPTION where BATCHNO IS NULL AND USERID = @psUserName
End

If exists (SELECT 1 from EDECHARGEDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDECHARGEDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDECASENAMEDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDECASENAMEDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEADDRESSBOOK where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEADDRESSBOOK where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDENAME where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDENAME where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEFORMATTEDNAME where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEFORMATTEDNAME where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEFORMATTEDADDRESS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEFORMATTEDADDRESS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDECONTACTINFORMATIONDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDECONTACTINFORMATIONDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEASSOCIATEDCASEDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEASSOCIATEDCASEDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEDOCUMENT where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEDOCUMENT where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDENAMEADDRESSDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDENAMEADDRESSDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEPAYMENTDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEPAYMENTDETAILS where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEPAYMENTMETHOD where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEPAYMENTMETHOD where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEACCOUNT where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEACCOUNT where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDECARDACCOUNT where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDECARDACCOUNT where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDECHEQUE where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDECHEQUE where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEBANKTRANSFER where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEBANKTRANSFER where BATCHNO IS NULL AND USERID = @psUserName 
End

If exists (SELECT 1 from EDEPAYMENTFEEDETAILS where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEPAYMENTFEEDETAILS where BATCHNO IS NULL AND USERID = @psUserName
End

If exists (SELECT 1 from EDEFORMATTEDATTNOF where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEFORMATTEDATTNOF where BATCHNO IS NULL AND USERID = @psUserName
End

If exists (SELECT 1 from EDEPATENTTERMADJ where BATCHNO IS NULL and USERID = @psUserName)
Begin
	Delete from EDEPATENTTERMADJ where BATCHNO IS NULL AND USERID = @psUserName
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ede_ClearCorruptBatch to public
go
