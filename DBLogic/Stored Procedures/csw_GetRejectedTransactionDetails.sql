-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetRejectedTransactionDetails
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetRejectedTransactionDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetRejectedTransactionDetails.'
	Drop procedure [dbo].[csw_GetRejectedTransactionDetails]
End
Print '**** Creating Stored Procedure dbo.csw_GetRejectedTransactionDetails...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_GetRejectedTransactionDetails
(	
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnImportBatchNo		int,			-- Mandatory
	@pnCaseId		int,			-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_GetRejectedTransactionDetails
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the rejected transaction details.

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Nov 2009	NG		RFC8098	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString nvarchar(max)

declare @sTransactionType	nvarchar(20)
declare @sRejectReason		nvarchar(254)

-- Initialise variables
Set @nErrorCode = 0

Begin
	Select top 1 @sTransactionType = IJ.TRANSACTIONTYPE, 
					@sRejectReason =IJ.REJECTREASON 
		from IMPORTJOURNAL IJ 
		where IJ.IMPORTBATCHNO = @pnImportBatchNo and IJ.CASEID = @pnCaseId
		order by  IJ.REJECTREASON desc
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "Select ROW_NUMBER() OVER(ORDER BY IJ.REJECTREASON DESC) as RowKey," +char(10)+
					"IJ.TRANSACTIONNO as TransactionNo,"+char(10)+
					"IJ.TRANSACTIONTYPE as TransactionType, "+char(10)+ 					
					"IJ.REJECTREASON as RejectReason"+char(10)+ 					
					"from IMPORTJOURNAL IJ"+char(10)+
					"where IJ.IMPORTBATCHNO = @pnImportBatchNo and IJ.CASEID = @pnCaseId"

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnImportBatchNo	int,
				  @pnCaseId		int',
				  @pnImportBatchNo = @pnImportBatchNo,
				  @pnCaseId = @pnCaseId
End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetRejectedTransactionDetails to public
GO