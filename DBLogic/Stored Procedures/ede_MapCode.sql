-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_MapCode
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_MapCode]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_MapCode.'
	Drop procedure [dbo].[ede_MapCode]
End
Print '**** Creating Stored Procedure dbo.ede_MapCode...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_MapCode
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null,
	@pnBatchNo		int
)
as
-- PROCEDURE:	ede_MapCode
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	This procedure uses predefined mapping rules to update
--		and validate the the EDE holding tables.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Sep 2006	vql	12995	1	Procedure created.
-- 29 Jan 2009	MF	17330	2	Ensure @nErrorCode is tested after every statement
--					that causes it to be set.
-- 04 Mar 2009	MF	17453	3	Minimise locks by keeping length of transactions as short
--					as possible.
-- 30 Jul 2012	Dw	12921	4	Derive Data Source from Sender where possible.
--					Also fixed syntax error noticed in logic used to register errors. 

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @TranCountStart		int
Declare @sSQLString		nvarchar(4000)
Declare @nRowNumber		int
Declare @nMaxRow		int
Declare @nMissingMapForBatch	int

Declare	@nMapStructureKey	smallint
Declare	@nDataSourceKey		int
Declare @nFromSchemeKey		int
Declare @nCommonSchemeKey	int
Declare	@sTableName		nvarchar(254)
Declare	@sCodeColumnName	nvarchar(254)
Declare	@sDescriptionColumnName nvarchar(254)
Declare	@sMappedColumn		nvarchar(254)
Declare @sUnmappedInfo		nvarchar(254)
Declare @nDataSourceId		int		-- SQA12921

-- Create temporary table for columns that need to be mapped.
Declare @tTables  table (
	ROWNUMBER 		int IDENTITY(1,1),
	TABLENAME		nvarchar(254) collate database_default NULL,
	CODECOLUMNNAME		nvarchar(254) collate database_default NULL,
	DESCRIPTIONCOLUMNNAME	nvarchar(254) collate database_default NULL,
	DATASOURCEKEY		int,
	FROMSCHEMEKEY		int,
	COMMONSCHEMEKEY		int,
	MAPPEDCOLUMNNAME	nvarchar(254) collate database_default NULL,
	MAPSTRUCTUREID		int NULL
 )

-- Initialise variables.
Set @nErrorCode = 0
Set @nMissingMapForBatch = 0


-- SQA12921 derive data source from sender
If @pnBatchNo is not null
and @nErrorCode=0
Begin
	Set @sSQLString = "
	select @nDataSourceId = isnull(DS.DATASOURCEID, -4)
	from EDESENDERDETAILS ESD
	left join DATASOURCE DS on (DS.SOURCENAMENO = ESD.SENDERNAMENO)
	where ESD.BATCHNO = @pnBatchNo"
	
	Execute @nErrorCode = sp_executesql @sSQLString,
				N'@nDataSourceId	int OUTPUT,
				  @pnBatchNo	int',
				  @nDataSourceId	OUTPUT,
				  @pnBatchNo	= @pnBatchNo
End


-- Populate the @tTables table mapping so we know what mappings we have to do.
If @nErrorCode = 0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	Insert into @tTables(TABLENAME, CODECOLUMNNAME, DESCRIPTIONCOLUMNNAME, DATASOURCEKEY, FROMSCHEMEKEY, COMMONSCHEMEKEY, MAPPEDCOLUMNNAME, MAPSTRUCTUREID)
	select TABLENAME, CODECOLUMNNAME, DESCRIPTIONCOLUMNNAME, @nDataSourceId, FROMSCHEMEKEY, COMMONSCHEMEKEY, MAPPEDCOLUMNNAME, MAPSTRUCTUREID
	from EDEMAPPINGRULE
	
	Select  @nMaxRow   = @@rowcount,
		@nErrorCode= @@error

	-------------------------------------
	-- Remove previous issues generate --
	-------------------------------------
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
			Delete from EDEOUTSTANDINGISSUES
			where BATCHNO = @pnBatchNo
			and ISSUEID = -25"

			Execute @nErrorCode = sp_executesql @sSQLString,
						N'@pnBatchNo		int',
						  @pnBatchNo		= @pnBatchNo
	End

	---------------
	-- Map codes --
	---------------
	If @nErrorCode = 0
	Begin
		-- If the status is unmapped then null it, there was a error last time and its being reprocessed.
		Set @sSQLString = "
			Update EDETRANSACTIONBODY
			set TRANSSTATUSCODE = null
			where BATCHNO = @pnBatchNo
			and TRANSSTATUSCODE = 3410"

		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo		= @pnBatchNo
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

If @nErrorCode = 0
Begin
	Set @nRowNumber = 1

	-- For each mapping we need to do run the dm_ApplyMapping SP.
	While @nRowNumber <= @nMaxRow 
	and @nErrorCode = 0
	Begin
		-- Minimise length of transactions by treating each
		-- mapping as its own discrete transaction.
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION
		
		Select	@sTableName		= TABLENAME,
			@sCodeColumnName	= CODECOLUMNNAME,
			@sDescriptionColumnName = DESCRIPTIONCOLUMNNAME,
			@nDataSourceKey		= DATASOURCEKEY,
			@nFromSchemeKey		= FROMSCHEMEKEY,
			@nCommonSchemeKey	= COMMONSCHEMEKEY,
			@sMappedColumn		= MAPPEDCOLUMNNAME,
			@nMapStructureKey	= MAPSTRUCTUREID
		from @tTables
		where ROWNUMBER = @nRowNumber
		
		Set @nErrorCode=@@Error

		If @nErrorCode=0
			Execute @nErrorCode = dbo.dm_ApplyMapping
						@pnUserIdentityId	= @pnUserIdentityId,
						@pbCalledFromCentura	= 0,
						@pnMapStructureKey	= @nMapStructureKey,
						@pnDataSourceKey	= @nDataSourceKey,
						@pnFromSchemeKey	= @nFromSchemeKey,
						@pnCommonSchemeKey	= @nCommonSchemeKey,
						@psTableName		= @sTableName,
						@psCodeColumnName	= @sCodeColumnName,
						@psDescriptionColumnName = @sDescriptionColumnName,
						@psMappedColumn		= @sMappedColumn,
						@pnDebugFlag		= 0,
						@pbKeepNonApplicableRows = 1,	-- Do not delete rows from source table.
						@pbReturnUnmappedInfo	= 1,	-- Return the error message.
						@psUnmappedInfo		= @sUnmappedInfo output

		-- Insert error into the issues register for the batch and current structure.
		If @sUnmappedInfo is not null
		and @nErrorCode=0
		Begin
			Set @sSQLString = "
			select top 1 @nMissingMapForBatch = 1
			from "+@sTableName+"
			where BATCHNO = @pnBatchNo
			and "+@sMappedColumn+" is null"
			--SQA12921 fixed syntax error in next segment
			Execute @nErrorCode = sp_executesql @sSQLString,
						N'@nMissingMapForBatch	int OUTPUT,
						  @pnBatchNo	int',
						  @nMissingMapForBatch	OUTPUT,
						  @pnBatchNo	= @pnBatchNo

			If @nMissingMapForBatch = 1
			and @nErrorCode=0
			Begin
				Set @sSQLString = "
				Insert into EDEOUTSTANDINGISSUES (BATCHNO, ISSUETEXT, ISSUEID, DATECREATED)
				values (@pnBatchNo, @sUnmappedInfo, -25, getdate( ) )"
	
				Execute @nErrorCode = sp_executesql @sSQLString,
							N'@pnBatchNo		int,
							  @sUnmappedInfo	nvarchar(254)',
							  @pnBatchNo		= @pnBatchNo,
							  @sUnmappedInfo	= @sUnmappedInfo
			End

			If @nErrorCode=0
			Begin
				-- Update transaction to Unmapped Codes if mapping failed for a transaction.
				Set @sSQLString = "
				Update EDETRANSACTIONBODY
				set TRANSSTATUSCODE = 3410
				from "+@sTableName+"
				where EDETRANSACTIONBODY.BATCHNO = "+@sTableName+".BATCHNO
				and EDETRANSACTIONBODY.TRANSACTIONIDENTIFIER = "+@sTableName+".TRANSACTIONIDENTIFIER
				and EDETRANSACTIONBODY.BATCHNO = @pnBatchNo
				and "+@sTableName+"."+@sMappedColumn+" is null
				and "+@sTableName+"."+@sCodeColumnName+" is not null"

				Execute @nErrorCode = sp_executesql @sSQLString,
							N'@pnBatchNo		int',
							  @pnBatchNo		= @pnBatchNo
			End
		End

		Set @sUnmappedInfo = null
		Set @nMissingMapForBatch = 0
		Set @nRowNumber = @nRowNumber + 1

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @nErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
End

If @nErrorCode = 0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	-- After all mapping done, flag rows that are not flagged unmapped as mapped.
	-- They cannot proceed until all Code mappings are done for that transaction.
	Set @sSQLString = "
		Update EDETRANSACTIONBODY
		set TRANSSTATUSCODE = 3420
		where BATCHNO = @pnBatchNo
		and (TRANSSTATUSCODE <> 3410 or TRANSSTATUSCODE is null)
		and (TRANSSTATUSCODE < 3430 or TRANSSTATUSCODE is null)"

		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo		= @pnBatchNo

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-----------------------------
-- REMOVE FOR TESTING ONLY --
-----------------------------
/*
If @nErrorCode = 0
Begin
	Set @sSQLString = "
		Update EDETRANSACTIONBODY
		set TRANSSTATUSCODE = 3420
		where BATCHNO = @pnBatchNo"

		Execute @nErrorCode = sp_executesql @sSQLString,
					N'@pnBatchNo		int',
					  @pnBatchNo		= @pnBatchNo
End
*/
Return @nErrorCode
GO

Grant execute on dbo.ede_MapCode to public
GO