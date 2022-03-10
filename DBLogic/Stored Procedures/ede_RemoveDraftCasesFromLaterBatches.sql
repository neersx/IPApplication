-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_RemoveDraftCasesFromLaterBatches
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ede_RemoveDraftCasesFromLaterBatches]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure ede_RemoveDraftCasesFromLaterBatches.'
	Drop procedure [dbo].[ede_RemoveDraftCasesFromLaterBatches]
End
Print '**** Creating Stored Procedure ede_RemoveDraftCasesFromLaterBatches...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE [dbo].[ede_RemoveDraftCasesFromLaterBatches]
			@pnRowCount		int=0	OUTPUT,
			@pnBatchNo		int,	-- Mandatory
			@pbDeleteCases		bit=0	-- When set to 1 will remove draft Cases
			
AS
-- PROCEDURE :	ede_RemoveDraftCasesFromLaterBatches
-- VERSION :	1
-- SCOPE:	CPA Inprotech
-- DESCRIPTION:	When EDE batches have been processed from a Sender in a different sequence
--		from how they were sent, then it is possible for Draft Cases to be created
--		that will then block the earlier batch from being processed.  This procedure
--		will look for matching Draft Cases created in a later batch and remove them and
--		reset that transaction so it can be reloaded after the earlier batch has been 
--		correctly processed to completion.
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 25 Aug 2009	MF	17971	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF	-- normally not recommended however required in this situation

Create table #TEMPCANDIDATECASES(
				TRANSACTIONIDENTIFIER	nvarchar(50)	collate database_default NOT NULL,
				CASEID			int		NOT NULL, 
				CASEIDMATCH		bit		NOT NULL, 
				IRNMATCH		bit		NOT NULL,
				REQUESTORMATCH		bit		NOT NULL,
				REQUESTORREFMATCH	bit		NOT NULL,
				INSTRUCTORMATCH		bit		NOT NULL,
				INSTRUCTORREFMATCH	bit		NOT NULL,
				NUMBERTYPEMATCH		int		NULL,
				OFFICIALNOMATCH		int		NULL,
				NOFUTURENAMEFOUND	bit		NOT NULL
				)

Create Unique Index XPKTEMPCANDIDATECASES ON #TEMPCANDIDATECASES
	(
	TRANSACTIONIDENTIFIER,
	CASEID
	)

Create table #TEMPCASEMATCH(	TRANSACTIONIDENTIFIER	nvarchar(50)	collate database_default NOT NULL,
				DRAFTCASEID		int		NULL,
				MATCHINGBATCHNO		int		NULL,
				MATCHINGTRANSACTION	nvarchar(50)	collate database_default NULL
				)

-- Declare working variables
Declare	@sSQLString 		nvarchar(max)
declare @nTranCountStart 	int
Declare @nErrorCode 		int
Declare @nRowCount		int
Declare	@nTransactionCount	int
Declare @nExistDraftCases	int

-- Variables from the input batch
declare @sRequestorNameType	nvarchar(3)
declare	@sRequestType		nvarchar(50)
declare	@nSenderNameNo		int
declare	@nFamilyNo		int
declare @nReasonNo		int

-----------------------
-- Initialise Variables
-----------------------
Set @nErrorCode = 0
Set @pnRowCount	= 0

--------------------------------------
-- Get the sender details of the batch
--------------------------------------
If @nErrorCode=0
Begin
	---------------------------------------------------------------------------------
	-- Check to see if the Sender of the batch requires the Name of the sender
	-- to be associated with each Case.
	-- This is determined if there is a NameType associated with the type of request.
	---------------------------------------------------------------------------------
	Set @sSQLString="
	select	@sRequestorNameType=R.REQUESTORNAMETYPE,
		@nSenderNameNo	   =S.SENDERNAMENO,
		@sRequestType	   =S.SENDERREQUESTTYPE,
		@nReasonNo	   =R.TRANSACTIONREASONNO,
		@nFamilyNo	   =N.FAMILYNO
	from EDESENDERDETAILS S
	join EDEREQUESTTYPE R	on (R.REQUESTTYPECODE=S.SENDERREQUESTTYPE)
	join NAME N		on (N.NAMENO=S.SENDERNAMENO)
	where S.BATCHNO=@pnBatchNo"
	
	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@sRequestorNameType	nvarchar(3)		OUTPUT,
				  @nSenderNameNo	int			OUTPUT,
				  @sRequestType		nvarchar(50)		OUTPUT,
				  @nReasonNo		int			OUTPUT,
				  @nFamilyNo		int			OUTPUT,
				  @pnBatchNo		int',
				  @sRequestorNameType=@sRequestorNameType	OUTPUT,
				  @nSenderNameNo     =@nSenderNameNo		OUTPUT,
				  @sRequestType      =@sRequestType		OUTPUT,
				  @nReasonNo	     =@nReasonNo		OUTPUT,
				  @nFamilyNo	     =@nFamilyNo		OUTPUT,
				  @pnBatchNo         =@pnBatchNo
End

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- CHECK FOR VALID TRANSACTIONS
-------------------------------------------------------------------------------------

-- First check that there are rows to process by taking a snapshot of the
-- transactions that are currently in a state to be processed.  Taking a snapshot
-- allows those transactions that are not further enough progressed to be worked
-- on in parallel to this processing.
-------------------------------------------------------------------------------------
If @nErrorCode=0
Begin
	-- Start a new transaction
	Set @nTranCountStart = @@TranCount
	BEGIN TRANSACTION

	------------------------------------------------------------------------------
	-- Only transactions in the given batch which are valid to this point 
	-- (ie. where transaction status = "Ready For Case Import") will be processed.
	------------------------------------------------------------------------------ 

	set @sSQLString="
	Insert into #TEMPCASEMATCH(TRANSACTIONIDENTIFIER)
	Select B.TRANSACTIONIDENTIFIER
	From EDETRANSACTIONBODY B with (UPDLOCK)
	left join EDECASEMATCH M on (M.BATCHNO=B.BATCHNO
				 and M.TRANSACTIONIDENTIFIER=B.TRANSACTIONIDENTIFIER)
	where B.BATCHNO=@pnBatchNo
	and   B.TRANSSTATUSCODE=3440	--'Ready For Case Import'
	and   M.BATCHNO is null		-- Ensure the transaction has not already been processed
	Order by B.TRANSACTIONIDENTIFIER"

	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo	int',
				  @pnBatchNo=@pnBatchNo

	Set @nTransactionCount=@@RowCount

	-- Commit transaction if successful
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-------------------------------------------------------------------------------------
-- IDENTIFY/MATCH TO DRAFT CASE for 'Data Input' batches
-------------------------------------------------------------------------------------
-- Load the candidate Cases for this batch that are returned from the stored procedure
-- ede_FindCandidateCases into a temporary table
-- This temporary table will list all of the possible Cases along with information
-- indicating how the match occurred
-------------------------------------------------------------------------------------
If @sRequestType='Data Input'
and @nTransactionCount>0
Begin			
	If @nErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPCANDIDATECASES(TRANSACTIONIDENTIFIER, CASEID, CASEIDMATCH, IRNMATCH, 
						REQUESTORMATCH, REQUESTORREFMATCH, INSTRUCTORMATCH, 
						INSTRUCTORREFMATCH, NUMBERTYPEMATCH,OFFICIALNOMATCH, NOFUTURENAMEFOUND)
		exec ede_FindCandidateCases
				@pnBatchNo	    =@pnBatchNo,
				@psRequestorNameType=@sRequestorNameType,
				@pnSenderNameNo	    =@nSenderNameNo,
				@pbDraftCaseSearch  =1,
				@pnFamilyNo	    =@nFamilyNo"
		
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @sRequestorNameType	nvarchar(3),
					  @nSenderNameNo	int,
					  @nFamilyNo		int',
					  @pnBatchNo		=@pnBatchNo,
					  @sRequestorNameType	=@sRequestorNameType,
					  @nSenderNameNo	=@nSenderNameNo,
					  @nFamilyNo		=@nFamilyNo					  
	End
		
	-------------------------------------------------------------------------------------
	-- GET EXISTING DRAFT CASEID
	-------------------------------------------------------------------------------------
	-- If a draft Case linked to an existing Live Case has not been assigned then consider
	-- the candidate draft Cases that already exist
	-------------------------------------------------------------------------------------

	If @nErrorCode=0
	Begin
		-----------------------------------------------------------------------------
		-- A best fit weighting is used to determine the level of matching achieved.
		-- 9 flags are concatenated together to indicate the match level. The highest
		-- value will then indicate the best fit.  The flags are :
		-- Position 1 -	Match on CaseId
		-- Position 2 -	Match on IRN
		-- Position 3 - Match on Number Type
		-- Position 4 -	Match on Official Number
		-- Position 5 -	Match on Requestor
		-- Position 6 -	Match on Requestor's reference
		-- Position 7 -	Match on Instructor
		-- Position 8 -	Match on Instructor's reference
		-- Position 9 - No Future Name found for Instructor or Requestor
		-----------------------------------------------------------------------------
		
		Set @sSQLString="
		Update #TEMPCASEMATCH
		Set DRAFTCASEID		=CC.CASEID,
		    MATCHINGBATCHNO	=M.BATCHNO,
		    MATCHINGTRANSACTION =M.TRANSACTIONIDENTIFIER
		From #TEMPCASEMATCH T
	
		-- Find the BestFit weighting 
		join(	select TRANSACTIONIDENTIFIER, 
			  max(	cast(CASEIDMATCH	as char(1))+
				cast(IRNMATCH		as char(1))+
				CASE WHEN(NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+
				CASE WHEN(OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+
				cast(REQUESTORMATCH 	as char(1))+
				cast(REQUESTORREFMATCH 	as char(1))+
				cast(INSTRUCTORMATCH 	as char(1))+
				cast(INSTRUCTORREFMATCH as char(1))+
				cast(NOFUTURENAMEFOUND  as char(1))) as BESTFIT
			  from #TEMPCANDIDATECASES
			  group by TRANSACTIONIDENTIFIER) BF	on (BF.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER)
	
		-- Now find how many candidate rows that have a match weighting equivalent to the BestFit
		join(	select TRANSACTIONIDENTIFIER,
			  	cast(CASEIDMATCH	as char(1))+
				cast(IRNMATCH		as char(1))+
				CASE WHEN(NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+
				CASE WHEN(OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+
				cast(REQUESTORMATCH 	as char(1))+
				cast(REQUESTORREFMATCH 	as char(1))+
				cast(INSTRUCTORMATCH 	as char(1))+
				cast(INSTRUCTORREFMATCH as char(1))+
				cast(NOFUTURENAMEFOUND  as char(1)) as BESTFIT,
				Count(*) as MATCHCOUNT
			  from #TEMPCANDIDATECASES
			  group by 
				TRANSACTIONIDENTIFIER,
			  	cast(CASEIDMATCH	as char(1))+
				cast(IRNMATCH		as char(1))+
				CASE WHEN(NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+
				CASE WHEN(OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+
				cast(REQUESTORMATCH 	as char(1))+
				cast(REQUESTORREFMATCH 	as char(1))+
				cast(INSTRUCTORMATCH 	as char(1))+
				cast(INSTRUCTORREFMATCH as char(1))+
				cast(NOFUTURENAMEFOUND  as char(1))) MC
								on (MC.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
								and MC.BESTFIT=BF.BESTFIT)
	
		-- Where there is one possible match return the candidate draft case
		join #TEMPCANDIDATECASES CC			on (CC.TRANSACTIONIDENTIFIER=T.TRANSACTIONIDENTIFIER
								and MC.MATCHCOUNT=1
								and cast(CC.CASEIDMATCH	       as char(1))+ 
								    cast(CC.IRNMATCH	       as char(1))+
								    CASE WHEN(CC.NUMBERTYPEMATCH>0) THEN '1' ELSE '0' END+
								    CASE WHEN(CC.OFFICIALNOMATCH>0) THEN '1' ELSE '0' END+
								    cast(CC.REQUESTORMATCH     as char(1))+
								    cast(CC.REQUESTORREFMATCH  as char(1))+
								    cast(CC.INSTRUCTORMATCH    as char(1))+
								    cast(CC.INSTRUCTORREFMATCH as char(1))+
								    cast(CC.NOFUTURENAMEFOUND  as char(1))=BF.BESTFIT )
		join EDECASEMATCH M		on (M.DRAFTCASEID=CC.CASEID
						and M.BATCHNO>@pnBatchNo)
		join EDETRANSACTIONBODY TB	on (TB.BATCHNO=M.BATCHNO
						and TB.TRANSACTIONIDENTIFIER=M.TRANSACTIONIDENTIFIER
						and TB.TRANSSTATUSCODE=3460) -- Still in progress
		Where T.DRAFTCASEID is null
		and M.MATCHLEVEL=3252		-- Match level is New Case
		and BF.BESTFIT like '____11%'	-- Match on Requestor and Requestor Reference (underscores mean any character in that position)
		and MC.MATCHCOUNT=1		-- Only one candidate Draft Case"
	
		exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo=@pnBatchNo
		
		Set @nExistDraftCases=@@Rowcount
	End
	
	------------------------------------------------------
	-- List details of the Draft Cases about to be removed
	------------------------------------------------------
	If @nErrorCode=0
	and @nExistDraftCases>0
	Begin
		Set @sSQLString="
		Select	TRANSACTIONIDENTIFIER	as [Blocked Transaction],
			DRAFTCASEID		as [Draft CaseId for Removal],
			MATCHINGBATCHNO		as [Blocking BatchNo],
			MATCHINGTRANSACTION	as [Blocking Transaction]
		from #TEMPCASEMATCH
		where DRAFTCASEID is not null"
		
		exec @nErrorCode=sp_executesql @sSQLString
	End

	-------------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	-- B A T C H   C L E A N U P
	-------------------------------------------------------------------------------------
	If @nErrorCode=0
	and @nExistDraftCases>0
	and @pbDeleteCases=1
	Begin		
		Select @nTranCountStart = @@TranCount
		BEGIN TRANSACTION
		
		----------------------------------------------------------------
		-- Remove any draft Cases that have been matched for this Sender
		-- that were created in a later batch to the current batch.
		----------------------------------------------------------------
		set @sSQLString="
		Delete C
		From #TEMPCASEMATCH T
		join CASES C on (C.CASEID=T.DRAFTCASEID)"

		Exec @nErrorCode=sp_executesql @sSQLString
		
		Set @pnRowCount=@@Rowcount
					
		If @nErrorCode=0
		Begin  
			----------------------------------------------------------------
			-- Remove any EDECASEMATCH rows that may exist for transactions
			-- of this batch that are at the 'Ready For Case Import' status.
			-- This will cleanup any batches that have failed previously.
			----------------------------------------------------------------
			set @sSQLString="
			Delete M
			From #TEMPCASEMATCH T
			join EDECASEMATCH M on (M.BATCHNO=T.MATCHINGBATCHNO
					    and M.TRANSACTIONIDENTIFIER=T.MATCHINGTRANSACTION)"

			Exec @nErrorCode=sp_executesql @sSQLString
		End
		
		If @nErrorCode=0
		Begin
			--------------------------
			-- Update the transaction
			-- to a status that allows
			-- it to be reloaded.
			--------------------------
			Set @sSQLString="
			Update B
			Set TRANSSTATUSCODE=3440 -- 'Ready For Case Import'
			From #TEMPCASEMATCH T
			join EDETRANSACTIONBODY B on (B.BATCHNO=T.MATCHINGBATCHNO
						  and B.TRANSACTIONIDENTIFIER=T.MATCHINGTRANSACTION)"
			
			exec @nErrorCode=sp_executesql @sSQLString
		End
					  
		-- Commit transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
End

RETURN @nErrorCode
go

grant execute on ede_RemoveDraftCasesFromLaterBatches to public
go