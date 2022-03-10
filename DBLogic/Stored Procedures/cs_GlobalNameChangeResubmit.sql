-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalNameChangeResubmit
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_GlobalNameChangeResubmit]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_GlobalNameChangeResubmit.'
	drop procedure dbo.cs_GlobalNameChangeResubmit
end
print '**** Creating procedure dbo.cs_GlobalNameChangeResubmit...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_GlobalNameChangeResubmit
	@pnNamesUpdatedCount		int		= 0	output,
	@pnNamesInsertedCount		int		= 0	output,
	@pnNamesDeletedCount		int		= 0	output,
	@pnUserIdentityId		int		= null,
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	-- Filter Parameters
	@psGlobalTempTable		nvarchar(32)		-- name of temporary table of CASEIDs 
	
AS
-- PROCEDURE :	cs_GlobalNameChangeResubmit  
-- VERSION:	2
-- DESCRIPTION:	For each case in the provided temporary table, check for outstanding global name change requests
--		and resubmit them.
-- COPYRIGHT	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Aug 2008	MF	16832	1	Procedure created
-- 23 Mar 2009	MF	17489	2	Reprocess the outstanding requests in REQUESTNO order

set nocount on

-- VARIABLES

Create table #TEMPREQUESTS(	REQUESTNO	int	not null,
				SEQUENCE	int	identity(1,1))

declare @ErrorCode		int
declare @TranCountStart		int
declare @nRowCount		int
declare @nRequestNo		int
declare @nSequence		int
declare @nUpdateCount		int
declare @nInsertCount		int
declare @nDeleteCount		int
declare @sSQLString		nvarchar(4000)

set @ErrorCode=0

set @pnNamesUpdatedCount =0
set @pnNamesInsertedCount=0
set @pnNamesDeletedCount =0

If @ErrorCode=0
Begin
	------------------------------------
	-- Get a distinct set of global name
	-- change requests that are still
	-- outstanding against the Cases in
	-- the supplied temporary table.
	------------------------------------
	Set @sSQLString="
	insert into #TEMPREQUESTS(REQUESTNO)
	select distinct REQUESTNO
	from CASENAMEREQUESTCASES CN
	join "+@psGlobalTempTable+" T on (T.CASEID=CN.CASEID)
	order by REQUESTNO"
	
	exec @ErrorCode=sp_executesql @sSQLString
	
	set @nRowCount=@@rowcount
End


-----------------------
-- Loop through each
-- outstanding global
-- name change request.
-----------------------
Set @nSequence=0

While @nSequence<@nRowCount
and @ErrorCode=0
Begin
	Set @nSequence=@nSequence+1
	--------------------
	-- Get the RequestNo
	--------------------
	Set @sSQLString="
	select @nRequestNo=REQUESTNO
	from #TEMPREQUESTS
	where SEQUENCE=@nSequence"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nRequestNo		int	OUTPUT,
				  @nSequence		int',
				  @nRequestNo	=@nRequestNo	OUTPUT,
				  @nSequence	=@nSequence
				  
	If @ErrorCode=0
	Begin
		-----------------------------------------
		-- For each different Change Request call 
		-- global name change.
		-----------------------------------------
		exec @ErrorCode=cs_GlobalNameChange
				@pnNamesUpdatedCount	=@nUpdateCount	output,
				@pnNamesInsertedCount	=@nInsertCount	output,
				@pnNamesDeletedCount	=@nDeleteCount	output,
				@pnUserIdentityId	=@pnUserIdentityId,
				@psCulture		=@psCulture,
				@pbSuppressOutput	=1,
				@pnRequestNo		=@nRequestNo
		
		----------------------------------
		-- Keep a running total of changes
		----------------------------------
		If @ErrorCode=0
		Begin
			set @pnNamesUpdatedCount = @pnNamesUpdatedCount  + @nUpdateCount
			set @pnNamesInsertedCount= @pnNamesInsertedCount + @nInsertCount
			set @pnNamesDeletedCount = @pnNamesDeletedCount  + @nDeleteCount
		End
	End
End

If @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	---------------------------------------
	-- Remove any childless CASENAMEREQUEST
	-- rows with no Cases associated
	---------------------------------------
	delete CN
	from CASENAMEREQUEST CN
	left join CASENAMEREQUESTCASES C on (C.REQUESTNO=CN.REQUESTNO)
	where C.REQUESTNO is null
	and CN.ONHOLDFLAG>0
	
	set @ErrorCode=@@Error
	
	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

RETURN @ErrorCode
go

grant execute on dbo.cs_GlobalNameChangeResubmit  to public
go
