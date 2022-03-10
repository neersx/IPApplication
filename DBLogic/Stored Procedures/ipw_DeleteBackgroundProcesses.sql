-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_DeleteBackgroundProcesses
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_DeleteBackgroundProcesses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_DeleteBackgroundProcesses.'
	Drop procedure [dbo].[ipw_DeleteBackgroundProcesses]
End
Print '**** Creating Stored Procedure dbo.ipw_DeleteBackgroundProcesses...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_DeleteBackgroundProcesses
(	
	@pnUserIdentityId	int,		-- Mandatory	
	@psCulture		nvarchar(10) 	= null,
	@ptProcessKeys		nvarchar(max),	-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@pbAsyncProcess		bit		= 0	-- 1 indicates process was started asynchonously
)
as
-- PROCEDURE:	ipw_DeleteBackgroundProcesses
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Delete the background processes from the BACKGROUNDPROCESS table 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02 FEB 2009	MS	5703	1	Procedure created
-- 25 JUL 2016	AV	64292	2	@ptProcessKeys parameter size changed to nvarchar(max) from nvarchar(1000)
-- 28 Apr 2017	MF	71093	3	When there are more than 10000 rows or more in CPAXMLEXPORTRESULT to be deleted,
--					then restart this procedure asynchronously and delete 1,000 rows at a time to 
--					reduce the possibility of locking the table.
-- 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sKeys		nvarchar(max)
declare @sSQLString	nvarchar(max)
declare	@sCommand	nvarchar(max)
declare @idoc 		int 	-- Declare a document handle of the XML document 
declare @nRowCount	int
declare @nRowPointer	int
declare @TranCountStart	int

-- Initialise variables
Set @nErrorCode = 0
Set @nRowCount	= 0

If @nErrorCode = 0
Begin

	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptProcessKeys

	Select @sKeys=CASE WHEN(@sKeys is null) THEN '' ELSE @sKeys+',' END + cast(ProcessKey as nvarchar)
	From OPENXML (@idoc, '//Processes/ProcessKey',2)
	WITH (ProcessKey int 'text()')

	Set @nErrorCode=@@ERROR

	If @nErrorCode=0
	Begin
		exec sp_xml_removedocument @idoc
	
		Set @nErrorCode=@@ERROR
	End
End
	

If @nErrorCode = 0
and @sKeys is not null
Begin
	---------------------------------------------------------
	-- If the stored procedure is not running asynchronously,
	-- then we need to check the number of rows in the 
	-- CPAXMLEXPORTRESULT table that will be deleted.
	-- The number of rows will determine if the delete runs
	-- in background or not.
	---------------------------------------------------------
	If isnull(@pbAsyncProcess,0)=0
	begin
		Set @sSQLString = 'select @nRowCount=count(*)
				   From CPAXMLEXPORTRESULT 
				   where PROCESSID in ('+@sKeys+')'

		exec @nErrorCode=sp_executesql  @sSQLString,
					N'@nRowCount	int	OUTPUT',
					  @nRowCount=@nRowCount	OUTPUT
	end
	
	---------------------------------------------------------
	-- If the stored procedure is running asynchronously then
	-- this means there are more than 10,000 rows in the 
	-- CPAXMLEXPORTRESULT table.  For performance reasons and
	-- to minimise the locks on that table we will delete
	-- rows from that table in blocks of 10,000, committing
	-- after each deletion.
	---------------------------------------------------------
	If  @nErrorCode=0
	and @pbAsyncProcess=1
	Begin
		Create table #TEMPDELETECANDIDATE (ID		int	not null,
						   SEQNO	int	identity(1,1) Primary Key
						   )
		------------------------------------------------
		-- Load the ID Of the CPAXMLEXPORTRESULT rows to
		-- be deleted into a temporary table.
		------------------------------------------------
		Set @sSQLString = 'insert into #TEMPDELETECANDIDATE(ID)
				   select ID
				   From CPAXMLEXPORTRESULT 
				   where PROCESSID in ('+@sKeys+')'

		exec @nErrorCode=sp_executesql  @sSQLString
		
		Set @nRowCount=@@ROWCOUNT

		Set @nRowPointer=0
		
		---------------------------------
		-- Loop through and delete blocks 
		-- of 1000 rows at a time.
		-- This seems to be the highest
		-- number with minimal delay.
		---------------------------------
		While @nRowPointer<@nRowCount
		and @nErrorCode=0
		Begin
			---------------------------------
			-- Each DELETE is to be committed
			-- to reduce locks being held.
			---------------------------------
			Select @TranCountStart = @@TranCount
			BEGIN TRANSACTION

			Set @nRowPointer=@nRowPointer+1000

			Set @sSQLString = "Delete C
					   from #TEMPDELETECANDIDATE T
					   join CPAXMLEXPORTRESULT C on (C.ID=T.ID)
					   where T.SEQNO<=@nRowPointer"

			exec @nErrorCode=sp_executesql  @sSQLString,
							N'@nRowPointer		int',
							  @nRowPointer=@nRowPointer 
							  
			-------------------------------------
			-- Commit or Rollback the transaction
			-------------------------------------
			If @@TranCount > @TranCountStart
			Begin
				If @nErrorCode = 0
					COMMIT TRANSACTION
				Else
					ROLLBACK TRANSACTION
			End
		End

		Set @nRowCount=0
	End

	If @nErrorCode=0
	and isnull(@nRowCount,0)<10000	-- Note that when @pbAsyncProcess=1 then @nRowCount=0
	Begin
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		Set @sSQLString = 'Delete From BACKGROUNDPROCESS
				   where PROCESSID in ('+@sKeys+')'

		exec @nErrorCode=sp_executesql  @sSQLString
							  
		-------------------------------------
		-- Commit or Rollback the transaction
		-------------------------------------
		If @@TranCount > @TranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
End

------------------------------------------------------------
-- If there are 10000 or more rows in CPAXMLEXPORTRESULT
-- to be deleted, then restart the procedure asynchronously
-- to avoid the user waiting too long for the delete to 
-- complete.
------------------------------------------------------------

If  @nErrorCode = 0
and isnull(@nRowCount,0)>=10000
Begin
	----------------------------------------------------------
	-- Build command line to run ipw_DeleteBackgroundProcesses
	-- as a background process.
	----------------------------------------------------------
	Set @sCommand = 'dbo.ipw_DeleteBackgroundProcesses '
	
	If @pnUserIdentityId is not null
		Set @sCommand = @sCommand + "@pnUserIdentityId=" + convert(varchar,@pnUserIdentityId) + ","

	If @psCulture is not null
		Set @sCommand = @sCommand + "@psCulture='" + convert(varchar,@psCulture) + "',"

	Set @sCommand = @sCommand + "@ptProcessKeys='" + @ptProcessKeys+"',"
		
	Set @sCommand = @sCommand + "@pbCalledFromCentura=0,"
		
	Set @sCommand = @sCommand + "@pbAsyncProcess=1" 	

	------------------------------------------------------
	-- Run the command asynchronously using Service Broker
	 -----------------------------------------------------
	If @nErrorCode = 0
	Begin
		print ''
		exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
		print 'Command called...'
		print @sCommand
		print ''
	End
	 	
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_DeleteBackgroundProcesses to public
GO
