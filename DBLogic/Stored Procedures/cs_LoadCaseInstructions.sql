-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_LoadCaseInstructions
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_LoadCaseInstructions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_LoadCaseInstructions.'
	drop procedure dbo.cs_LoadCaseInstructions
end
print '**** Creating procedure dbo.cs_LoadCaseInstructions...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.cs_LoadCaseInstructions 
			@pnUserIdentityId	int	= NULL

as
-- PROCEDURE :	cs_LoadCaseInstructions
-- VERSION :	4
-- DESCRIPTION:	A procedure to clear out and load the CASEINSTRUCTIONS table
--		with the standing instruction determined for each Case and 
--		instruction type. This table will be used to improve performance
--		when searching for Cases by a specific Standing Instruction as it
--		removes the need to dynamically determine the current standing
--		instruction.
--
--		The CASEINSTRUCTIONSRECALC table will be loaded with NAMENO or CASEID
--		details to indicate that the associated Cases are to have their
--		standing instructions recalulated. This table is loaded whenever
--		a change that may impact Case level standing instructions occurs.
--
--		NOTE:
--		Dynamically determined standing instructions will 
--		continue to be used during POLICING to ensure accuracy in case
--		there is any delay in loading CASEINSTRUCTIONS.

-- MODIFICATION
-- Date		Who	RFC	Version	Change
-- ===========  ===	====== 	=======	==========================================
-- 25 Jun 2010	MF	9296	1	Procedure created
-- 22 Sep 2011	MF	11328	2	Performance problem when a huge number of Cases are triggered to process.
--					Change the processing so that a @nBatchSize number of Cases are processed
--					at the one time and committed to the database before continuing and processing
--					all requests.
-- 28 Oct 2011	MF	S20089	3	Merge error has reset INSTRUCTIONTYPE to nchar(1) when it should be nvarchar(3)
-- 20 Feb 2012	vql	S20364	4	CASEINSTRUCTIONSRECALC record not processed.

set nocount on

Create table #TEMPCASES (
			SEQUENCENO		int		identity(1,1)	Primary Key,
			CASEID			int		NOT NULL
			)

Create table #TEMPNAMES (
			NAMENO			int		NOT NULL
			)

Create table #TEMPCASESBATCH(
			CASEID			int		NOT NULL
			)


Create table #TEMPCASEINSTRUCTIONS (
			CASEID			int		NOT NULL,
			INSTRUCTIONTYPE		nvarchar(3)	collate database_default NOT NULL, 
			INSTRUCTIONCODE		smallint	NOT NULL)


Declare	@ErrorCode		int
Declare	@TranCountStart 	int
Declare	@nBatchSize		int
Declare	@nRowCount		int
Declare	@nRowNo			int
Declare	@nRetry			smallint
Declare	@sSQLString		nvarchar(max)
Declare @sInstructionTypes	nvarchar(300)

----------------------------------
-- Initialise the errorcode and 
-- set it after each SQL Statement
----------------------------------
Set @ErrorCode     =0
Set @TranCountStart=0
Set @nRowCount     =0
Set @nRetry        =3

While @nRetry>0
and @ErrorCode=0
Begin
	BEGIN TRY
		---------------------------------------
		-- Reset the CASEINSTRUCTIONSRECALC rows
		-- that are currently on hold but were
		-- last updated more than 1 hour before
		---------------------------------------
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		Update CI
		Set ONHOLDFLAG=0
		from CASEINSTRUCTIONSRECALC CI
		where CI.LOGDATETIMESTAMP < DATEADD(hh,-1,GETDATE())
		and CI.ONHOLDFLAG>0
					
		Select @ErrorCode=@@Error

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
		
		-- Terminate the WHILE loop
		Set @nRetry=-1
	END TRY	

	---------------------------------
	-- D E A D L O C K   V I C T I M   
	--       P R O C E S S I N G
	---------------------------------
	BEGIN CATCH
		------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
		------------------------------------------
		If ERROR_NUMBER()=1205
			Set @nRetry=@nRetry-1
		Else
			Set @nRetry=-1
			
		If XACT_STATE()<>0
			Rollback Transaction
		
		If @nRetry<1
			Set @ErrorCode=ERROR_NUMBER()
	END CATCH
End -- WHILE loop

If  @ErrorCode=0
Begin
	----------------------------------
	-- Get the Cases that are eligible 
	-- to be recalculated.
	---------------------------------- 
	Set @sSQLString="
	Insert into #TEMPNAMES(NAMENO)
	SELECT distinct NAMENO
	from CASEINSTRUCTIONSRECALC
	where NAMENO is not null
	and ONHOLDFLAG=0"

	exec @ErrorCode=sp_executesql @sSQLString
End

If  @ErrorCode=0
Begin
	----------------------------------
	-- Get the Cases that are eligible 
	-- to be recalculated.
	---------------------------------- 
	Set @sSQLString="
	Insert into #TEMPCASES(CASEID)
	SELECT X.CASEID
	from (	select CI.CASEID as CASEID
		from CASEINSTRUCTIONSRECALC CI with(NOLOCK) 
		where CI.CASEID is not null
		and CI.ONHOLDFLAG=0
		UNION
		select CN.CASEID as CASEID
		from #TEMPNAMES TN
		join CASENAME CN on (CN.NAMENO=TN.NAMENO)
		join (	select NAMETYPE as NAMETYPE
			from INSTRUCTIONTYPE
			where NAMETYPE is not null
			UNION
			select RESTRICTEDBYTYPE
			from INSTRUCTIONTYPE
			where RESTRICTEDBYTYPE is not null) I on (I.NAMETYPE=CN.NAMETYPE)
		where CN.EXPIRYDATE is null) X
	Order by X.CASEID"

	exec @ErrorCode=sp_executesql @sSQLString
	
	Set @nRowCount=@@Rowcount
End

Set @nRetry =3

While @nRetry>0
and @ErrorCode=0
and @nRowCount>0
Begin
	BEGIN TRY
		---------------------------------------
		-- Mark the CASEINSTRUCTIONSRECALC
		-- rows that are about to be processed.
		-- Keep the transaction very short.
		---------------------------------------
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		Update CI
		Set ONHOLDFLAG=1
		from #TEMPCASES T
		join CASEINSTRUCTIONSRECALC CI on (CI.CASEID=T.CASEID)
		Where CI.ONHOLDFLAG=0
					
		Select @ErrorCode=@@Error
		
		If @ErrorCode=0
		Begin
			Update CI
			Set ONHOLDFLAG=1
			from #TEMPNAMES T
			join CASEINSTRUCTIONSRECALC CI on (CI.NAMENO=T.NAMENO)
			Where CI.ONHOLDFLAG=0
						
			Select @ErrorCode=@@Error
		End

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
		
		-- Terminate the WHILE loop
		Set @nRetry=-1
	END TRY	

	---------------------------------
	-- D E A D L O C K   V I C T I M   
	--       P R O C E S S I N G
	---------------------------------
	BEGIN CATCH
		------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
		------------------------------------------
		If ERROR_NUMBER()=1205
			Set @nRetry=@nRetry-1
		Else
			Set @nRetry=-1
			
		If XACT_STATE()<>0
			Rollback Transaction
		
		If @nRetry<1
			Set @ErrorCode=ERROR_NUMBER()
	END CATCH
End -- WHILE loop

If  @ErrorCode=0
and @nRowCount>0
Begin
	-----------------------------------
	-- Concatenate the InstructionTypes
	-- that are to be extracted.
	-----------------------------------
	Set @sSQLString="
	Select @sInstructionTypes=CASE WHEN(@sInstructionTypes is not null) 
					THEN @sInstructionTypes+','+I.INSTRUCTIONTYPE
					ELSE I.INSTRUCTIONTYPE
				  END
	from INSTRUCTIONTYPE I"

	Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@sInstructionTypes	nvarchar(300)	output',
				  @sInstructionTypes=@sInstructionTypes	output
End
	
--------------------------------------------
-- Loop through the Cases to process so that 
-- we can process these in a batch size that
-- does not cause extensive locking on the
-- database
--------------------------------------------
Set @nRowNo = 1
Set @nBatchSize=1000

While @nRowNo <= @nRowCount
and   @ErrorCode=0
and   @sInstructionTypes is not null
Begin
	-------------------------------------
	-- Get the next @nBatchSize set of
	-- Cases to process
	-------------------------------------

	insert into #TEMPCASESBATCH(CASEID)
	select CASEID
	from #TEMPCASES
	where SEQUENCENO between @nRowNo and @nRowNo+@nBatchSize
	
	Set @ErrorCode=@@ERROR

	If  @ErrorCode=0
	Begin
		-------------------------------------
		-- Now get the Standing Instructions
		-- for each Case and Instruction Type
		-------------------------------------
		Exec @ErrorCode=dbo.cs_GetStandingInstructionsBulk 
					@psInstructionTypes=@sInstructionTypes,
					@psCaseTableName   ='#TEMPCASESBATCH'

		--------------------------------
		-- Apply the resolved Case level
		-- standing instructions to the
		-- live database tables
		--------------------------------
		Set @nRetry=3

		While @nRetry>0
		and @ErrorCode=0
		Begin
			BEGIN TRY

				Select @TranCountStart = @@TranCount
				BEGIN TRANSACTION

				-------------------------------------
				-- Delete CASEINSTRUCTIONS row if the
				-- Case has just been recalculated 
				-- and matching Instruction Type has
				-- not been found.
				-------------------------------------
				Set @sSQLString="
				Delete CI
				from CASEINSTRUCTIONS CI
				join #TEMPCASESBATCH C on (C.CASEID=CI.CASEID)
				left join #TEMPCASEINSTRUCTIONS TCI
						  on (TCI.CASEID         =CI.CASEID
						  and TCI.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE)
				where TCI.CASEID is null"

				exec @ErrorCode=sp_executesql @sSQLString

				If @ErrorCode=0
				Begin
					-------------------------------------
					-- Update CASEINSTRUCTIONS row if the
					-- InstructionCode for an Instruction
					-- Type now has different value.
					-------------------------------------
					Set @sSQLString="
					Update CI
					set INSTRUCTIONCODE=TCI.INSTRUCTIONCODE
					from CASEINSTRUCTIONS CI
					join #TEMPCASEINSTRUCTIONS TCI
							on (TCI.CASEID         =CI.CASEID
							and TCI.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE)
					where CI.INSTRUCTIONCODE<>TCI.INSTRUCTIONCODE"

					exec @ErrorCode=sp_executesql @sSQLString
				End

				If @ErrorCode=0
				Begin
					-------------------------------------
					-- Insert CASEINSTRUCTIONS row if the
					-- InstructionType doe not exist.
					-------------------------------------
					Set @sSQLString="
					Insert into CASEINSTRUCTIONS(CASEID, INSTRUCTIONTYPE, INSTRUCTIONCODE)
					Select TCI.CASEID, TCI.INSTRUCTIONTYPE, TCI.INSTRUCTIONCODE
					From #TEMPCASEINSTRUCTIONS TCI
					join CASES C	on (C.CASEID=TCI.CASEID)	-- Join to ensure CASES row still exists
					left join CASEINSTRUCTIONS CI
							on (CI.CASEID         =TCI.CASEID
							and CI.INSTRUCTIONTYPE=TCI.INSTRUCTIONTYPE)
					where CI.CASEID is null"

					exec @ErrorCode=sp_executesql @sSQLString
				End
		
				If @ErrorCode=0
				Begin
					------------------------------------
					-- Delete the CASEINSTRUCTIONSRECALC
					-- rows that have been processed for
					-- a specific Case.
					------------------------------------
					Delete CI
					from CASEINSTRUCTIONSRECALC CI
					join #TEMPCASESBATCH TC on (TC.CASEID=CI.CASEID)
					Where ONHOLDFLAG=1
							
					Set @ErrorCode=@@Error
				End

				-- Commit or Rollback the transaction
				
				If @@TranCount > @TranCountStart
				Begin
					If @ErrorCode = 0
						COMMIT TRANSACTION
					Else
						ROLLBACK TRANSACTION
				End
				
				-- Terminate the WHILE loop
				Set @nRetry=-1
			END TRY	

			---------------------------------
			-- D E A D L O C K   V I C T I M   
			--       P R O C E S S I N G
			---------------------------------
			BEGIN CATCH
				------------------------------------------
				-- If the process has been made the victim
				-- of a deadlock (error 1205), then allow 
				-- another attempt to apply the updates 
				-- to the database up to a retry limit.
				------------------------------------------
				If ERROR_NUMBER()=1205
					Set @nRetry=@nRetry-1
				Else
					Set @nRetry=-1
					
				If XACT_STATE()<>0
					Rollback Transaction
				
				If @nRetry<1
					Set @ErrorCode=ERROR_NUMBER()
			END CATCH
		End -- WHILE loop
	End
	----------------
	-- C L E A N U P
	----------------
	If @ErrorCode=0
	Begin
		delete #TEMPCASESBATCH
		
		set @ErrorCode=@@ERROR
	End
	
	If @ErrorCode=0
	Begin
		delete #TEMPCASEINSTRUCTIONS
		
		set @ErrorCode=@@ERROR
	End
	
	-----------------------------------
	-- Move the @nRowNo forward for the
	-- next batch to extract
	-----------------------------------
	Set @nRowNo = @nRowNo + @nBatchSize + 1
	
End  -- End of WHILE

Set @nRetry=3

While @nRetry>0
and @ErrorCode=0
Begin
	BEGIN TRY

		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		--------------------------------------
		-- Delete the CASEINSTRUCTIONSRECALC
		-- rows that have been processed for
		-- a specific NameNo where all of the
		-- Cases for that NameNo have now been
		-- processed.
		--------------------------------------
		Delete CI
		from CASEINSTRUCTIONSRECALC CI
		join #TEMPNAMES TN on (TN.NAMENO=CI.NAMENO)
		Where CI.ONHOLDFLAG=1
				
		Set @ErrorCode=@@Error

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
		
		-- Terminate the WHILE loop
		Set @nRetry=-1
	END TRY	

	---------------------------------
	-- D E A D L O C K   V I C T I M   
	--       P R O C E S S I N G
	---------------------------------
	BEGIN CATCH
		------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
		------------------------------------------
		If ERROR_NUMBER()=1205
			Set @nRetry=@nRetry-1
		Else
			Set @nRetry=-1
			
		If XACT_STATE()<>0
			Rollback Transaction
		
		If @nRetry<1
			Set @ErrorCode=ERROR_NUMBER()
	END CATCH
End -- WHILE loop

return @ErrorCode
go

grant execute on dbo.cs_LoadCaseInstructions  to public
go
