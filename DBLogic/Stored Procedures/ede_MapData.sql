-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_MapData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_MapData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_MapData.'
	Drop procedure [dbo].[ede_MapData]
End
Print '**** Creating Stored Procedure dbo.ede_MapData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_MapData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null,
	@pnBatchNo		int,
	@pnProcessId		int		= null,
	@pbReducedLocking	bit		= 1		
)
as
-- PROCEDURE:	ede_MapData
-- VERSION:	14
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure will start off the code mapping, check for identical rows 
--		and name mappings for a batch. Then it will start the case load.

-- MODIFICATIONS :
-- Date		Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Jul 2006	vql	12995	1	Procedure created.
-- 28 Apr 2007	DL	13716	2	A request row is created when this SP is called asynchronouly
--					Add parameter @pnProcessId to allow deletion of this request row at the end
--					of this SP.
-- 18 Jul 2007	MF	15039	3	Allow procedure to be called with ReducedLocking flag which will be passed
--					to te proceduer EDE_LoadDraftCasesFromEDE
-- 03 Sep 2007	DL	15188	4	If running in Asynchronous mode then set the userid that submitted the process in the context_info
--					to allow correct audit information recording. 
-- 16 Oct 2007	vql	15318	5	Insert new transaction when a batch is submitted.
-- 06 Mar 2008	MF	16079	6	Reduce the period of time that locks are held on the database by changing the 
--					default value for the @pbReducedLocking flag to be ON.
-- 29 Jan 2009	MF	17330	7	Reduce the potential for locking by setting explicit transactions around the mapping
--					before calling ede_LoadDraftCasesFromEDE
-- 04 Feb 2009	KR	17325	8	Write SPID and Login_Time into the PROCESSREQUEST table
-- 27 Jul 2009	MF	17814	9	Errors returned by ede_LoadDraftCasesFromEDE are not being trapped and reported to the User.
-- 16 Feb 2012	DL	20266	10	Introduce new stop reason code of N
-- 05 Jan 2015	SS	42679	11	Set processrequest status to 'Processing', along with setting SPID. This is done to cater for the scenarios when processing is restarted due to service broker issues.
-- 23 Mar 2016	DL	75502	12	Case Import errors are not always being trapped and displayed as error message
-- 02 May 2016	MF	60845	13	If Case being imported cannot locate a draft case type to use then report a batch error.
-- 10 May 2016	MF	60845	14	Reformat the message generated for missing draft case type.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @TranCountStart	int
Declare @sSQLString	nvarchar(max)
Declare @nRowCount	int
Declare	@nLastErrorCode	int
Declare	@bHexNumber	varbinary(128)
Declare	@nTransNo	int
Declare @LoginTime	datetime
Declare @nSpID		smallint
Declare @sErrorMessage	nvarchar(254)
Declare @sCaseTypes	nvarchar(254)

-- Initialise variables.
Set @nErrorCode = 0

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Global error handling for case import / EDE
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Begin Try


-----------------------------------------------------------------------------------------
--If the batch is executed as a background task update the SPID and LOGINTIME columns---
--using the current SPID and its LoginTime											-----
-----------------------------------------------------------------------------------------

If @pnProcessId is not null 
Begin
	Set @nSpID = @@SPID
	
	Set @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @LoginTime = login_time from master.dbo.sysprocesses where SPID = @nSpID"
	
		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@LoginTime 	datetime OUTPUT,
					  @nSpID		smallint',
					  @LoginTime	= @LoginTime OUTPUT,
					  @nSpID		= @nSpID
	End
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "	Update PROCESSREQUEST 
							set SPID = @nSpID ,
							LOGINTIME = @LoginTime,
							STATUSCODE = 14020,
							STATUSMESSAGE = NULL
							where PROCESSID = @pnProcessId"
		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@LoginTime 	datetime,
					  @nSpID		smallint,
					  @pnProcessId	int',
					  @LoginTime	= @LoginTime,
					  @nSpID		= @nSpID,
					  @pnProcessId	= @pnProcessId
	End

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

If @nErrorCode=0
Begin
	-- A separate database transaction will be used to insert the TRANSACTIONINFO
	-- row to ensure the lock on the database is kept to a minimum as this table
	-- will be used extensively by other processes.

	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Insert a new transaction each time a batch submitted for processing.
	Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE, BATCHNO) values(getdate(),@pnBatchNo)
			Set @nTransNo=SCOPE_IDENTITY()"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnBatchNo int,
					  @nTransNo	int	OUTPUT',
					  @pnBatchNo=@pnBatchNo,
					  @nTransNo=@nTransNo	OUTPUT

	-- If running in asynchronous mode then update the userid that requested the process in the context_info.
	If @nErrorCode = 0
	Begin
		Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4) + 
				substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
				substring(cast(isnull(@pnBatchNo,'') as varbinary),1,4)
		Set CONTEXT_INFO @bHexNumber
	End

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

------------------------------
-- Hard Coded Data Mappings --
------------------------------
If @nErrorCode = 0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	-- Gender
	Set @sSQLString = "
	Update EDEFORMATTEDNAME
	set GENDER_T =	CASE(GENDER)
				WHEN('Male')	Then 'M'
				WHEN('Female')	Then 'F'
						Else GENDER_T
			END
	where BATCHNO = @pnBatchNo
	and   GENDER in ('Male','Female')"
		
	Execute @nErrorCode = sp_executesql @sSQLString,
				N'@pnBatchNo	int',
				  @pnBatchNo	= @pnBatchNo
				  
	If @nErrorCode=0
	Begin
		-- Entity Size
		Set @sSQLString = "
		Update EDECASEDETAILS
		set ENTITYSIZE_T =	CASE(ENTITYSIZE)
					WHEN('Large')	Then 2601
					WHEN('Small')	Then CASE(CASECOUNTRYCODE)
								WHEN('US') then 2602
								WHEN('CA') then 2603
									   else null
							     END
							Else ENTITYSIZE_T
				END
		where BATCHNO = @pnBatchNo
		and ENTITYSIZE in ('Large','Small')
		 "
			
		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo	= @pnBatchNo
	End

	If @nErrorCode=0
	Begin
		--  SQA20266 Stop Reason Code
		Set @sSQLString = "
		Update CD
		set CD.STOPREASONCODE_T = TC.USERCODE
		from EDECASEDETAILS CD
		join TABLECODES TC ON TC.DESCRIPTION = CD.STOPREASONCODE and TC.TABLETYPE = 68
		where CD.BATCHNO = @pnBatchNo
		"
			
		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo	= @pnBatchNo
	End

				  
	If @nErrorCode=0
	Begin
		-- Short Title
		Set @sSQLString = "
		Update EDEDESCRIPTIONDETAILS
		set DESCRIPTIONCODE_T = 
				CASE WHEN(DESCRIPTIONCODE='Short Title') 
						then DESCRIPTIONCODE 
						else DESCRIPTIONCODE_T 
				END
		where BATCHNO = @pnBatchNo
		and   DESCRIPTIONCODE = 'Short Title'"
			
		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo	int',
					  @pnBatchNo	= @pnBatchNo
	End

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

---------------
-- Map codes --
---------------

If @nErrorCode = 0
Begin
	-- Note the database transaction is defined within ede_MapCode
	
	Execute @nErrorCode = ede_MapCode @pnUserIdentityId, @psCulture, @pnBatchNo
End

-----------------------------------------------------------------------------------------
-- Check if any cases in this batch is identical to cases in the last batch -------------
-- If identical then set the EDETRANSACTIONBODY.TRANSSTATUSCODE column to processed -----
-----------------------------------------------------------------------------------------
If @nErrorCode = 0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	Execute @nErrorCode = ede_FlagIdentical @pnUserIdentityId, @psCulture, @pnBatchNo

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End


-----------------------------------------
-- Map Names and find unresolved names --
-----------------------------------------
If @nErrorCode = 0
Begin
	-- Note the database transaction is defined within ede_MapName
	
	Execute @nErrorCode = ede_MapName @pnUserIdentityId, @psCulture, @pnBatchNo
End

-------------------------------------------
-- Find any Case Types that do not have an
-- associated draft case type.
-------------------------------------------
If @nErrorCode=0
Begin
	Set @sSQLString="
	Select @sCaseTypes=substring(  (select distinct ','+CT.CASETYPEDESC+'('+CT.CASETYPE+')' as [text()]
					from EDECASEDETAILS C
					     join CASETYPE CT on (CT.CASETYPE      =C.CASETYPECODE_T)
					left join CASETYPE CD on (CD.ACTUALCASETYPE=C.CASETYPECODE_T)
					where C.BATCHNO=@pnBatchNo
					and C.CASETYPECODE_T is not null
					and CD.CASETYPE is null
					For XML PATH ('')),
					2,100)"
	
	Execute @nErrorCode = sp_executesql @sSQLString, 
					N'@sCaseTypes	nvarchar(100)	OUTPUT,
					  @pnBatchNo	int',
					  @sCaseTypes  =@sCaseTypes	OUTPUT,
					  @pnBatchNo   =@pnBatchNo
End

---------------------------------------
-- Remove any previously rejected batch
-- errors associated with the missing
-- draft Case Type.
---------------------------------------
If @nErrorCode=0
Begin
	Set @sSQLString="
	Delete EDEOUTSTANDINGISSUES
	where BATCHNO=@pnBatchNo
	and ISSUEID=-39"

	Execute @nErrorCode = sp_executesql @sSQLString,
				N'@pnBatchNo		int',
				  @pnBatchNo		= @pnBatchNo
End	

-------------------------------------
-- Load cases if there are no missing
-- draft case types otherwise report
-- the CaseTypes with no draft case
-- type as an issue.
-------------------------------------
If @nErrorCode = 0
Begin
	If @sCaseTypes is not null
	begin
		Set @sSQLString = "
		Insert into EDEOUTSTANDINGISSUES (BATCHNO, ISSUETEXT, ISSUEID, DATECREATED)
		values (@pnBatchNo, @sCaseTypes, -39, getdate( ) )"

		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo		int,
					  @sCaseTypes		nvarchar(254)',
					  @pnBatchNo		= @pnBatchNo,
					  @sCaseTypes		= @sCaseTypes
	End
	Else Begin
		Execute @nErrorCode = ede_LoadDraftCasesFromEDE	@nRowCount OUTPUT, 
								@pnUserIdentityId, 
								@psCulture, 
								@pnBatchNo,
								@pbReducedLocking
	End
End


End Try	


--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Trap errors that occurred in the called stored procedures 
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
Begin Catch
	-- Get error to log against the command
	set @nErrorCode = ERROR_NUMBER()
	set @sErrorMessage = isnull(CAST(ERROR_NUMBER() AS VARCHAR(20)),0) + ' - ' + isnull(ERROR_MESSAGE(), '')
	If XACT_STATE() <> 0
	Begin
		ROLLBACK TRANSACTION;
	End
End Catch


-- A process request row is created when this stored proc is called anynchronously.
-- The request row should be deleted at the end of this stored proc if no error occured.
If @pnProcessId is not null 
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Delete PROCESSREQUEST
		where  PROCESSID = @pnProcessId"
	
		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnProcessId 	int',
					  @pnProcessId	= @pnProcessId
	End
	Else Begin
		Set @nLastErrorCode = @nErrorCode 

		If  @sErrorMessage is null
		Begin
			-- Log errors that has been trap locally in callee stored procedures
			Set @sSQLString = "
			Update PROCESSREQUEST
			Set STATUSCODE = 14040,  -- ERROR
			STATUSMESSAGE = (	Select isnull(description, '') + CHAR(13) + CHAR(10) + 'Please contact the system administrator and report the problem.' 
						from master.dbo.sysmessages 
						where error = @nLastErrorCode
						and msglangid = 1033) 
			where  PROCESSID = @pnProcessId"
		
			Execute @nErrorCode = sp_executesql @sSQLString,
						N'@nLastErrorCode	int,
						  @pnProcessId		int',
						  @nLastErrorCode = @nLastErrorCode, 
						  @pnProcessId	= @pnProcessId
		End					  
		Else Begin
			-- Log errors that has been caught in this stored procedure.  This includes errors that not trapped or caught and re-raise in the callee stored procedures.
			Set @sSQLString = "
			Update PROCESSREQUEST
			Set STATUSCODE = 14040,  -- ERROR
			STATUSMESSAGE = @sErrorMessage 
			+ CASE WHEN @sErrorMessage like '%.' THEN '' ELSE '.' END 
			+ CHAR(13) + CHAR(10) + ' Please contact the system administrator and report the problem.' 
			where  PROCESSID = @pnProcessId"
		
			Execute @nErrorCode = sp_executesql @sSQLString,
						N'@sErrorMessage	nvarchar(1000),
						  @pnProcessId		int',
						  @sErrorMessage = @sErrorMessage,
						  @pnProcessId	= @pnProcessId
		End
	End

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End


Return @nErrorCode
GO

Grant execute on dbo.ede_MapData to public
GO