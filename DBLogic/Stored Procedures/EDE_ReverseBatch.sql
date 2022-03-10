-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_ReverseBatch
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_ReverseBatch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_ReverseBatch.'
	Drop procedure [dbo].[ede_ReverseBatch]
End
Print '**** Creating Stored Procedure dbo.ede_ReverseBatch...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ede_ReverseBatch
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10)	= null,
	@pnBatchNo		int
)
as
-- PROCEDURE :	ede_ReverseBatch
-- VERSION :	3
-- DESCRIPTION:	Partially rollback data imported by an EDE batch.  
--		Delete new cases, delete unresolved names, change all transaction status to processed
--		and batch status to output produced.
-- COPYRIGHT:	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17/10/2008	DL	15028	1	Procedure created
-- 21/05/2009	DL	17677	2	Delete issues related to batch being reversed.
-- 22 Aug 2017	MF	72214	3	Ensure POLICING rows are written with the IdentityId and start Policing with the same IdentityId.

SET CONCAT_NULL_YIELDS_NULL OFF		

-- cases to be deleted
CREATE TABLE #DELETECASES(
	ROWID				int identity(1,1),
	CASEID				int
	)

CREATE INDEX X1TEMPCASES ON #DELETECASES
(
	CASEID
)

-- cases to be repoliced due to relationship with related case got deleted
CREATE TABLE #REPOLICECASES(
	ROWID				int identity(1,1),
	CASEID				int,
	ACTION				nvarchar(4)  collate database_default, 
	CYCLE				smallint,
	CURRENTDATE			datetime 			
	)


Declare @nErrorCode 				int,
	@nNumberOfCasesToBeDeleted		int,
	@nNumberOfRelatedCases			int,
	@nPolicingBatchNo			int,
	@nCountBatch				smallint,
	@sBatchRevSeq				varchar(6),
	@nTransNo				int,
	@bHexNumber				varbinary(128),
	@sSQLString				nvarchar(4000)



Set @nErrorCode = 0


-- Insert a new transaction for auditing purposes.
Begin TRANSACTION ATRAN
Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO) values(getdate(),@pnBatchNo)
		Set @nTransNo=SCOPE_IDENTITY()"

exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo int,
				  @nTransNo	int	OUTPUT',
				  @pnBatchNo=@pnBatchNo,
				  @nTransNo=@nTransNo	OUTPUT

If @nErrorCode = 0
	COMMIT TRANSACTION ATRAN
Else
	ROLLBACK TRANSACTION ATRAN


-- Add transaction/session info to context_info to enable triggers to get related infor for this batch.
If @nErrorCode = 0
Begin
	Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4) + 
substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
substring(cast(isnull(@pnBatchNo,'') as varbinary),1,4)
	Set CONTEXT_INFO @bHexNumber
End


Begin TRANSACTION TRAN1

-- -------------------
-- Get cases to be deleted EXCLUDE cases with financial info.
-- -------------------
Begin
	Insert into #DELETECASES (CASEID)
	select distinct CIL.CASEID 
	from CASES_iLOG CIL
	join TRANSACTIONINFO TI on TI.LOGTRANSACTIONNO = CIL.LOGTRANSACTIONNO
	WHERE CIL.LOGACTION = 'I' 
	and TI.BATCHNO = @pnBatchNo
	-- exclude cases with financial info
	and NOT EXISTS (select * from BILLEDCREDIT T where T.CRCASEID = CIL.CASEID)
	and NOT EXISTS (select * from CASEBUDGET T where T.CASEID = CIL.CASEID)
	and NOT EXISTS (select * from DEBTORHISTORYCASE T where T.CASEID = CIL.CASEID)
	and NOT EXISTS (select * from DIARY T where T.CASEID = CIL.CASEID)
	and NOT EXISTS (select * from FEELISTCASE T where T.CASEID = CIL.CASEID)
	and NOT EXISTS (select * from INSTALMENT T where T.BILLEDCASEID = CIL.CASEID)
	and NOT EXISTS (select * from OPENITEMBREAKDOWN T where T.CASEID = CIL.CASEID)
	and NOT EXISTS (select * from OPENITEMCASE T where T.CASEID = CIL.CASEID)
	and NOT EXISTS (select * from TRANSADJUSTMENT T where T.TOCASEID = CIL.CASEID)
	and NOT EXISTS (select * from WORKHISTORY T where T.CASEID = CIL.CASEID)
	and NOT EXISTS (select * from WORKINPROGRESS T where T.CASEID = CIL.CASEID)

	Select @nErrorCode = @@ERROR, @nNumberOfCasesToBeDeleted = @@ROWCOUNT
End


-- Delete cases from CASES dependent tables with no CASCADE delete attribute.
if @nErrorCode = 0 and @nNumberOfCasesToBeDeleted > 0
begin
	delete B2BCASEPACKAGE from B2BCASEPACKAGE A join #DELETECASES T on T.CASEID = A.CASEID
	set @nErrorCode = @@ERROR

	if @nErrorCode = 0
	begin
		Update CASEEVENT 
		set FROMCASEID = NULL
		from CASEEVENT A 
		join #DELETECASES T on T.CASEID = A.FROMCASEID
		set @nErrorCode = @@ERROR
	end

	if @nErrorCode = 0
	begin
		delete COSTTRACKALLOC from COSTTRACKALLOC A join #DELETECASES T on T.CASEID = A.CASEID
		set @nErrorCode = @@ERROR
	end

	if @nErrorCode = 0
	begin
		delete COSTTRACKLINE from COSTTRACKLINE A join #DELETECASES T on T.CASEID = A.CASEID
		set @nErrorCode = @@ERROR
	end


	if @nErrorCode = 0
	begin
		Update EDECASEDETAILS 
		set CASEID = NULL
		from EDECASEDETAILS A 
		join #DELETECASES T on T.CASEID = A.CASEID
		where A.BATCHNO = @pnBatchNo
		set @nErrorCode = @@ERROR
	end

	if @nErrorCode = 0
	begin
		delete EDECASEMATCH from EDECASEMATCH A join #DELETECASES T on T.CASEID = A.LIVECASEID AND A.BATCHNO = @pnBatchNo
		set @nErrorCode = @@ERROR
	end

	if @nErrorCode = 0
	begin
		delete EXPENSEIMPORT from EXPENSEIMPORT A join #DELETECASES T on T.CASEID = A.CASEID
		set @nErrorCode = @@ERROR
	end

	if @nErrorCode = 0
	begin
		delete QUOTATION from QUOTATION A join #DELETECASES T on T.CASEID = A.CASEID
		set @nErrorCode = @@ERROR
	end

	if @nErrorCode = 0
	begin
		delete RECORDALAFFECTEDCASE from RECORDALAFFECTEDCASE A join #DELETECASES T on T.CASEID = A.CASEID
		set @nErrorCode = @@ERROR
	end

	if @nErrorCode = 0
	begin
		delete RECORDALSTEP from RECORDALSTEP A join #DELETECASES T on T.CASEID = A.CASEID
		set @nErrorCode = @@ERROR
	end

	if @nErrorCode = 0
	begin
		-- Get affected cases to be repoliced where RELATEDCASEID is the related case
		Insert into #REPOLICECASES(CASEID, ACTION, CYCLE, CURRENTDATE) 
		select O.CASEID, O.ACTION, O.CYCLE, GETDATE() 
		from OPENACTION O
		join RELATEDCASE RC on RC.CASEID = O.CASEID
		join #DELETECASES T on T.CASEID = RC.RELATEDCASEID
		where  O.POLICEEVENTS=1 
		-- do not repolice deleting cases
		and NOT EXISTS (Select * from #DELETECASES T where T.CASEID = O.CASEID)

		Select @nErrorCode = @@ERROR, @nNumberOfRelatedCases = @@ROWCOUNT


		-- and delete the related case relationship
		if @nErrorCode = 0
		begin
			delete RELATEDCASE from RELATEDCASE A join #DELETECASES T on T.CASEID = A.RELATEDCASEID
			set @nErrorCode = @@ERROR
		end
	end

	-- now delete rows from CASES
	if @nErrorCode = 0
	begin
		delete CASES from CASES C join #DELETECASES T on T.CASEID = C.CASEID
		set @nErrorCode = @@ERROR
	end

	-- delete any draft cases related to this batch
	if @nErrorCode = 0
	begin
		delete CASES from CASES C 
		join EDECASEMATCH T on T.DRAFTCASEID = C.CASEID 
		where T.BATCHNO =@pnBatchNo
		set @nErrorCode = @@ERROR
	end
end


-- Delete unresolved names associated with the batch
If @nErrorCode = 0 
Begin
	Update EDEADDRESSBOOK 
	SET UNRESOLVEDNAMENO = null 
	WHERE UNRESOLVEDNAMENO IS NOT NULL 
	AND  BATCHNO =@pnBatchNo

	set @nErrorCode = @@ERROR

	If @nErrorCode = 0 
	Begin
		Delete from EDEUNRESOLVEDNAME 
		where BATCHNO =@pnBatchNo
		set @nErrorCode = @@ERROR
	End
End


-- Delete EDECASEMATCH related to the batch
If @nErrorCode = 0 
Begin
	Delete EDECASEMATCH 
	Where BATCHNO =@pnBatchNo

	set @nErrorCode = @@ERROR
End


-- Delete outstanding issues related to the batch
If @nErrorCode = 0 
Begin
	Delete EDEOUTSTANDINGISSUES 
	Where BATCHNO =@pnBatchNo

	set @nErrorCode = @@ERROR
End


-- Set the transaction status of all transactions in the batch to ‘Processed’
If @nErrorCode = 0 
Begin
	Update EDETRANSACTIONBODY
	set TRANSSTATUSCODE = 3480
	where BATCHNO = @pnBatchNo

	set @nErrorCode = @@ERROR
End

--  Set the batch status to ‘Output Produced’
If @nErrorCode = 0 
Begin
	Update  EDETRANSACTIONHEADER 
	Set BATCHSTATUS = 1282 , DATEOUTPUTPRODUCED = getdate() 
	Where BATCHNO =@pnBatchNo

	set @nErrorCode = @@ERROR
End


-- Add ‘_REV’ suffix to the batch ID
-- If a batch is reversed multiple time then the suffix would be _REV, _REV1, _REV2… 
If @nErrorCode = 0 
Begin
	Select @nCountBatch = count(*)
	from EDESENDERDETAILS SD1
	where SD1.SENDERREQUESTIDENTIFIER LIKE 
	  (select SENDERREQUESTIDENTIFIER + '%' from EDESENDERDETAILS where BATCHNO = @pnBatchNo)
	and SD1.SENDER =   (select SENDER from EDESENDERDETAILS where BATCHNO = @pnBatchNo)

	set @nErrorCode = @@ERROR

	If @nErrorCode = 0 
	Begin
		if @nCountBatch = 1
			set @sBatchRevSeq = '_REV'
		else 
			set @sBatchRevSeq = '_REV' + CAST(@nCountBatch-1 AS VARCHAR(2))

		Update  EDESENDERDETAILS  
		SET SENDERREQUESTIDENTIFIER =  SENDERREQUESTIDENTIFIER  + @sBatchRevSeq  
		where BATCHNO = @pnBatchNo

		set @nErrorCode = @@ERROR
	End
End


If @nErrorCode = 0 and @nNumberOfRelatedCases > 0
Begin
	-- Get policing batch number 
	BEGIN TRANSACTION TRAN2

	Update LASTINTERNALCODE 
	set INTERNALSEQUENCE = INTERNALSEQUENCE+1,
		@nPolicingBatchNo = INTERNALSEQUENCE+1
	where TABLENAME = 'POLICINGBATCH'

	set @nErrorCode = @@ERROR
	-- RELEASE LOCK ON LASTINTERNALCODE IMMEDIATELY
	If @nErrorCode = 0
		COMMIT TRANSACTION TRAN2
	Else
		ROLLBACK TRANSACTION TRAN2

	--Create policing requests
	If @nErrorCode = 0
	Begin
		Insert into POLICING(BATCHNO, DATEENTERED, POLICINGSEQNO, POLICINGNAME, 
			ACTION, SYSGENERATEDFLAG, ONHOLDFLAG, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
		Select  @nPolicingBatchNo, RC.CURRENTDATE, RC.ROWID, convert(varchar, RC.CURRENTDATE, 121)+' '+convert(varchar, RC.ROWID), 
			RC.ACTION, 1, 1, RC.CASEID, RC.CYCLE, 1, SYSTEM_USER, @pnUserIdentityId 
		From #REPOLICECASES RC

		set @nErrorCode = @@ERROR
	End

	-- ...And run policing
	If @nErrorCode = 0
	Begin
		exec @nErrorCode=dbo.ipu_Policing
				@pdtPolicingDateEntered 	= null,
				@pnPolicingSeqNo 		= null,
				@pnDebugFlag			= 0,
				@pnBatchNo			= @nPolicingBatchNo,
				@psDelayLength			= null,
				@pnUserIdentityId		= @pnUserIdentityId,
				@psPolicingMessageTable		= null
	End
End



If @nErrorCode = 0
	COMMIT TRANSACTION TRAN1
Else
	ROLLBACK TRANSACTION TRAN1




RETURN @nErrorCode
GO

Grant execute on dbo.ede_ReverseBatch to public
GO
