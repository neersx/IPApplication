if exists (select * from sysobjects where id = object_id(N'[dbo].[apps_ReverseCaseImportBatch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.apps_ReverseCaseImportBatch.'
	drop procedure dbo.apps_ReverseCaseImportBatch
	print '**** Creating procedure dbo.apps_ReverseCaseImportBatch...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS on
GO

Create PROCEDURE [dbo].[apps_ReverseCaseImportBatch]
(	
	@pnUserIdentityId int,
	@pnBatchNo int
)
-- PROCEDURE :	apps_ReverseCaseImportBatch
-- VERSION :	1
-- DESCRIPTION:	Based on original [ede_ReverseBatch] procedure VERSION 3.

-- Modifications
--
-- Date			Who	Number	Version	Description
-- ------------	------	-------	-------	------------------------------------
-- 16/07/2018	SF	DR-12092	1	Procedure created.

as
begin

	-- cases to be deleted
	create table #DELETECASES 
	(
		ROWID				int identity(1,1),
		CASEID				int,
		TRANSACTIONIDENTIFIER nvarchar(100) collate database_default
	)

	create index X1TEMPCASES on #DELETECASES
	(
		CASEID
	)

	create index X2TEMPCASES on #DELETECASES
	(
		TRANSACTIONIDENTIFIER
	) 

	-- cases to be repoliced due to relationship with related case got deleted
	create table #REPOLICECASES(
		ROWID				int identity(1,1),
		CASEID				int,
		[ACTION]			nvarchar(4)  collate database_default, 
		CYCLE				smallint,
		CURRENTDATE			datetime 			
	)

	declare @nErrorCode 				int,
		@nNumberOfCasesToBeDeleted		int,
		@nNumberOfRelatedCases			int,
		@nPolicingBatchNo				int,
		@nCountBatch					smallint,
		@sBatchRevSeq					varchar(6),
		@nTransNo						int,
		@bHexNumber						varbinary(128),
		@sSQLString						nvarchar(max)

	set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO) values(getdate(),@pnBatchNo)
	Set @nTransNo=SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnBatchNo int,
				@nTransNo	int	OUTPUT',
				@pnBatchNo=@pnBatchNo,
				@nTransNo=@nTransNo	OUTPUT

	-- Add transaction/session info to context_info to enable triggers to get related infor for this batch.
	if @nErrorCode = 0
	begin
		set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4) + 
						substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
						substring(cast(isnull(@pnBatchNo,'') as varbinary),1,4)
		set CONTEXT_INFO @bHexNumber
	end

	if @nErrorCode = 0
	and exists(select * from PROCESSREQUEST where BATCHNO = @pnBatchNo and CONTEXT = 'EDE' and REQUESTTYPE = 'EDE Resubmit Batch' and [STATUSCODE] <> 14040 )
	begin
	
		raiserror(N'Unable to reverse batch. The batch already has a status of in progress.', 16, 1)

		set @nErrorCode = 99
	end

	if @nErrorCode = 0
	begin
	
		insert PROCESSREQUEST (BATCHNO, REQUESTDATE, CONTEXT, SQLUSER, REQUESTTYPE, REQUESTDESCRIPTION, SPID)
		values (@pnBatchNo, getdate(), 'EDE', USER, 'EDE Resubmit Batch', 'Reverse batch of imported cases', @@spid)

		set @nErrorCode = @@error
	End

	if @nErrorCode = 0
	begin
		-- Get policing batch number 
		begin transaction TRAN1

		update	LASTINTERNALCODE 
		set		INTERNALSEQUENCE = INTERNALSEQUENCE+1,
				@nPolicingBatchNo = INTERNALSEQUENCE+1
		where	TABLENAME = 'POLICINGBATCH'

		set @nErrorCode = @@ERROR
		
		-- RELEASE LOCK ON LASTINTERNALCODE IMMEDIATELY
		if @nErrorCode = 0
			commit transaction TRAN1
		else
			rollback transaction TRAN1
	end

	if @nErrorCode = 0
	begin

		begin transaction TRAN2

			if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'CASES_iLOG') 
			begin

				-- ----------------------------------------------------------
				-- Get cases to be deleted EXCLUDE cases with financial info.
				-- ----------------------------------------------------------

				Set @sSQLString="
					insert into #DELETECASES (CASEID)
					select distinct CIL.CASEID 
					from CASES_iLOG CIL
					join TRANSACTIONINFO TI on TI.LOGTRANSACTIONNO = CIL.LOGTRANSACTIONNO
					WHERE CIL.LOGACTION = 'I' 
					and TI.BATCHNO = @pnBatchNo"

				-- exclude cases with financial info
				set @sSQLString = @sSQLString + "
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
				"

				-- exclude cases referenced or used in E-filing
				if exists (select * from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'B2BCASEPACKAGE') 
				begin 
					set @sSQLString = @sSQLString + "
						and NOT EXISTS (select * from B2BCASEPACKAGE T where T.CASEID = CIL.CASEID)
					"
				end
					
				exec @nErrorCode=sp_executesql @sSQLString, 
					N'@pnBatchNo	int',
					  @pnBatchNo	= @pnBatchNo
				
				select	@nErrorCode = @@error, 
						@nNumberOfCasesToBeDeleted = count(*)
				from #DELETECASES
			end
			
			-- --------------------------------------
			-- Start deassociating and deleting cases
			-- --------------------------------------

			if @nErrorCode = 0 and @nNumberOfCasesToBeDeleted > 0
			begin
				
				update T
					set TRANSACTIONIDENTIFIER = case 
													when ECM.TRANSACTIONIDENTIFIER is not null then ECM.TRANSACTIONIDENTIFIER
													when ECD.TRANSACTIONIDENTIFIER is not null then ECD.TRANSACTIONIDENTIFIER
												end
				from #DELETECASES T
				left join EDECASEMATCH ECM on (ECM.LIVECASEID = T.CASEID or ECM.DRAFTCASEID = T.CASEID) and ECM.BATCHNO = @pnBatchNo
				left join EDECASEDETAILS ECD on ECD.CASEID = T.CASEID and ECD.BATCHNO = @pnBatchNo

				set @nErrorCode = @@error
				
				if @nErrorCode = 0
				begin
					update CASEEVENT 
					set FROMCASEID = NULL
					from CASEEVENT A 
					join #DELETECASES T on T.CASEID = A.FROMCASEID
					set @nErrorCode = @@error
				end

				if @nErrorCode = 0
				begin
					delete COSTTRACKALLOC from COSTTRACKALLOC A join #DELETECASES T on T.CASEID = A.CASEID
					set @nErrorCode = @@error
				end

				if @nErrorCode = 0
				begin
					delete COSTTRACKLINE from COSTTRACKLINE A join #DELETECASES T on T.CASEID = A.CASEID
					set @nErrorCode = @@error
				end

				if @nErrorCode = 0
				begin
					update EDECASEDETAILS 
					set CASEID = NULL
					from EDECASEDETAILS A 
					join #DELETECASES T on T.CASEID = A.CASEID
					where A.BATCHNO = @pnBatchNo
					set @nErrorCode = @@error
				end

				if @nErrorCode = 0
				begin
					delete EDECASEMATCH from EDECASEMATCH A join #DELETECASES T on T.CASEID = A.LIVECASEID AND A.BATCHNO = @pnBatchNo
					set @nErrorCode = @@error
				end

				if @nErrorCode = 0
				begin
					delete EXPENSEIMPORT from EXPENSEIMPORT A join #DELETECASES T on T.CASEID = A.CASEID
					set @nErrorCode = @@error
				end

				if @nErrorCode = 0
				begin
					delete QUOTATION from QUOTATION A join #DELETECASES T on T.CASEID = A.CASEID
					set @nErrorCode = @@error
				end

				if @nErrorCode = 0
				begin
					delete RECORDALAFFECTEDCASE from RECORDALAFFECTEDCASE A join #DELETECASES T on T.CASEID = A.CASEID
					set @nErrorCode = @@error
				end

				if @nErrorCode = 0
				begin
					delete RECORDALSTEP from RECORDALSTEP A join #DELETECASES T on T.CASEID = A.CASEID
					set @nErrorCode = @@error
				end

				if @nErrorCode = 0
				begin
					-- Get affected cases to be repoliced where RELATEDCASEID is the related case
					insert into #REPOLICECASES(CASEID, ACTION, CYCLE, CURRENTDATE) 
					select O.CASEID, O.ACTION, O.CYCLE, getdate() 
					from OPENACTION O
					join RELATEDCASE RC on RC.CASEID = O.CASEID
					join #DELETECASES T on T.CASEID = RC.RELATEDCASEID
					where  O.POLICEEVENTS=1 
					-- do not repolice deleting cases
					and NOT EXISTS (Select * from #DELETECASES T where T.CASEID = O.CASEID)

					select @nErrorCode = @@error, @nNumberOfRelatedCases = @@rowcount

					-- and delete the related case relationship
					if @nErrorCode = 0
					begin
						delete RELATEDCASE from RELATEDCASE A join #DELETECASES T on T.CASEID = A.RELATEDCASEID
						set @nErrorCode = @@error
					end
				end

				-- now delete rows from CASES
				if @nErrorCode = 0
				begin
					delete CASES from CASES C join #DELETECASES T on T.CASEID = C.CASEID
					set @nErrorCode = @@error
				end

				-- delete any draft cases related to this batch
				if @nErrorCode = 0
				begin
					delete CASES from CASES C 
					join EDECASEMATCH T on T.DRAFTCASEID = C.CASEID 
					where T.BATCHNO =@pnBatchNo
					set @nErrorCode = @@error
				end

				if @nErrorCode = 0
				begin
					update T
						set TRANSACTIONRETURNCODE = 'Case Reversed'
					from EDETRANSACTIONBODY T
					join #DELETECASES D on D.TRANSACTIONIDENTIFIER = T.TRANSACTIONIDENTIFIER
					where T.BATCHNO = @pnBatchNo

					set @nErrorCode = @@error
				end
			end

			-- Delete unresolved names associated with the batch
			if @nErrorCode = 0 
			begin
				update EDEADDRESSBOOK 
				set UNRESOLVEDNAMENO = null 
				where UNRESOLVEDNAMENO is not null 
				and  BATCHNO =@pnBatchNo

				set @nErrorCode = @@error

				if @nErrorCode = 0 
				begin
					delete from EDEUNRESOLVEDNAME 
					where BATCHNO =@pnBatchNo
					set @nErrorCode = @@error
				end
			end

			-- Delete EDECASEMATCH related to the batch
			if @nErrorCode = 0 
			begin
				delete EDECASEMATCH 
				where BATCHNO =@pnBatchNo

				set @nErrorCode = @@error
			end

			-- Delete outstanding issues related to the batch
			if @nErrorCode = 0 
			begin
				delete EDEOUTSTANDINGISSUES 
				where BATCHNO =@pnBatchNo

				set @nErrorCode = @@error
			end

			-- Set the transaction status of all transactions in the batch to ‘Processed’
			if @nErrorCode = 0 
			begin
				update EDETRANSACTIONBODY
				set TRANSSTATUSCODE = 3480
				where BATCHNO = @pnBatchNo

				set @nErrorCode = @@error
			end

			--  Set the batch status to ‘Output Produced’
			if @nErrorCode = 0 
			begin
				update  EDETRANSACTIONHEADER 
				set BATCHSTATUS = 1282 , DATEOUTPUTPRODUCED = getdate() 
				where BATCHNO =@pnBatchNo

				set @nErrorCode = @@error
			end

			-- Add ‘_REV’ suffix to the batch ID
			-- If a batch is reversed multiple time then the suffix would be _REV, _REV1, _REV2… 
			if @nErrorCode = 0 
			begin
				select @nCountBatch = count(*)
				from EDESENDERDETAILS SD1
				where SD1.SENDERREQUESTIDENTIFIER LIKE 
				  (select SENDERREQUESTIDENTIFIER + '%' from EDESENDERDETAILS where BATCHNO = @pnBatchNo)
				and SD1.SENDER =   (select SENDER from EDESENDERDETAILS where BATCHNO = @pnBatchNo)

				set @nErrorCode = @@error

				if @nErrorCode = 0 
				begin
					if @nCountBatch = 1
						set @sBatchRevSeq = '_REV'
					else 
						set @sBatchRevSeq = '_REV' + CAST(@nCountBatch-1 AS VARCHAR(2))

					update  EDESENDERDETAILS  
					set SENDERREQUESTIDENTIFIER =  SENDERREQUESTIDENTIFIER  + @sBatchRevSeq  
					where BATCHNO = @pnBatchNo

					set @nErrorCode = @@error
				end
			end

			if @nErrorCode = 0 and @nNumberOfRelatedCases > 0
			begin
				--Create policing requests
				if @nErrorCode = 0
				Begin
					insert into POLICING(
							BATCHNO, DATEENTERED, POLICINGSEQNO, POLICINGNAME, 
							[ACTION], SYSGENERATEDFLAG, ONHOLDFLAG, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
					select  @nPolicingBatchNo, RC.CURRENTDATE, RC.ROWID, convert(varchar, RC.CURRENTDATE, 121)+' '+convert(varchar, RC.ROWID), 
							RC.[ACTION], 1, 1, RC.CASEID, RC.CYCLE, 1, SYSTEM_USER, @pnUserIdentityId 
					from #REPOLICECASES RC

					set @nErrorCode = @@ERROR
				end

				-- ...And run policing
				if @nErrorCode = 0
				begin
					exec @nErrorCode=dbo.ipu_Policing
							@pdtPolicingDateEntered 	= null,
							@pnPolicingSeqNo 		= null,
							@pnDebugFlag			= 0,
							@pnBatchNo			= @nPolicingBatchNo,
							@psDelayLength			= null,
							@pnUserIdentityId		= @pnUserIdentityId,
							@psPolicingMessageTable		= null
				end
			end
		
		if @nErrorCode = 0
			commit transaction TRAN2
		else
			rollback transaction TRAN2
	end

	if @nErrorCode = 0
	begin
		delete from PROCESSREQUEST
		where  BATCHNO = @pnBatchNo
		and SQLUSER = USER
		and CONTEXT = 'EDE'
		and SPID = @@spid
	
		set @nErrorCode = @@error
	end

	return @nErrorCode

end
go

grant execute on dbo.apps_ReverseCaseImportBatch to public
go