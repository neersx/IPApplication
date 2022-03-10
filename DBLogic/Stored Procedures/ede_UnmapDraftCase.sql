-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_UnmapDraftCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_UnmapDraftCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_UnmapDraftCase.'
	Drop procedure [dbo].[ede_UnmapDraftCase]
End
Print '**** Creating Stored Procedure dbo.ede_UnmapDraftCase...'
Print ''
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[ede_UnmapDraftCase]
(
	@pnUserIdentityId		int,			-- Mandatory
	@pnBatchNo			int,			-- Mandatory
	@psTransactionIdentifier	nvarchar(50),		-- Mandatory
	@pnDraftCaseKey			int,			-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnSessionNo			int			-- Mandatory
)
as
-- PROCEDURE:	ede_UnmapDraftCase
-- VERSION:	2

-- DESCRIPTION:	Copies the essential data from the specified mapped draft case into a new unmapped draft case.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	------	--------	-------	----------------------------------------------- 
-- 05 Aug 2007	KR	SQA16786	1	Procedure created
-- 26 Feb 2015	LP	R44661		2	Identity column OFFICIALNUMBERID should not be inserted

-- Settings
SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare @sSQL		nvarchar(4000)
declare @sIRN		nvarchar(30)
declare @sColumns 	nvarchar(1000)

declare @sGSTextType 	nvarchar(2)
declare @nCount 	int
declare @bFlag		bit	
declare @nNewDraftCaseKey	int
declare @nIssueNo int

-- Initialise variables
Set @nErrorCode 	= 0
Set @bFlag		= 0
Set @sGSTextType 	= 'G'
Set @sIRN = '<Generate Reference>'

If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'CASES',
			@pnLastInternalCode	= @nNewDraftCaseKey OUTPUT	
	Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin
	-- Get the Names of columns excluding CASEID and IRN
	SELECT  @sColumns = case
			when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
			else COLUMN_NAME
			end
	 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CASES' and
	COLUMN_NAME not in ('CASEID', 'IRN')	
	
	--Generate SQL statement for Inserting a row into CASES
	Set @sSQL = '
		Insert into CASES (CASEID,IRN, ' +   @sColumns + '  )
		Select @nNewDraftCaseKey, @sIRN, '+ @sColumns + ' From CASES where CASEID ='+ cast(@pnDraftCaseKey as nvarchar)
	
	exec @nErrorCode=sp_executesql @sSQL,
			 N'@nNewDraftCaseKey	int,
			   @sIRN		nvarchar(30)',
			   @nNewDraftCaseKey	= @nNewDraftCaseKey,
			   @sIRN		= @sIRN

	Set @nErrorCode = @@ERROR
End

--inserting the draft case into the PROPERTY table
If @nErrorCode = 0
Begin
	Set @sColumns = NULL
	Set @sSQL = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
			when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
			else COLUMN_NAME
			end
	 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'PROPERTY' and
	COLUMN_NAME not in ('CASEID')	

	--Generate SQL statement for Inserting a row into PROPERTY
	Set @sSQL = '
		Insert into PROPERTY (CASEID, ' +   @sColumns + '  )
		Select @nNewDraftCaseKey, '+ @sColumns + ' From PROPERTY where CASEID ='+ cast(@pnDraftCaseKey as nvarchar)
	
	exec @nErrorCode=sp_executesql @sSQL,
			 N'@nNewDraftCaseKey	int',
			   @nNewDraftCaseKey	= @nNewDraftCaseKey

	Set @nErrorCode = @@ERROR
End

--inserting the draft case into the CASENAME table
If @nErrorCode = 0
Begin
	Set @sColumns = NULL
	Set @sSQL = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
			when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
			else COLUMN_NAME
			end
	 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CASENAME' and
	COLUMN_NAME not in ('CASEID')	

	--Generate SQL statement for Inserting a row into CASENAMES
	Set @sSQL = '
		Insert into CASENAME (CASEID, ' +   @sColumns + '  )
		Select @nNewDraftCaseKey, '+ @sColumns + ' From CASENAME where CASEID ='+ cast(@pnDraftCaseKey as nvarchar)
	
	exec @nErrorCode=sp_executesql @sSQL,
			 N'@nNewDraftCaseKey	int',
			   @nNewDraftCaseKey	= @nNewDraftCaseKey

	Set @nErrorCode = @@ERROR
End


--inserting the draft case into the CASENEVENT table
If @nErrorCode = 0
Begin
	Set @sColumns = NULL
	Set @sSQL = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
			when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
			else COLUMN_NAME
			end
	 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CASEEVENT' and
	COLUMN_NAME not in ('CASEID')	

	--Generate SQL statement for Inserting a row into CASEEVENT
	Set @sSQL = '
		Insert into CASEEVENT (CASEID, ' +   @sColumns + '  )
		Select @nNewDraftCaseKey, '+ @sColumns + ' From CASEEVENT where CASEID ='+ cast(@pnDraftCaseKey as nvarchar)
	
	exec @nErrorCode=sp_executesql @sSQL,
			 N'@nNewDraftCaseKey	int',
			   @nNewDraftCaseKey	= @nNewDraftCaseKey

	Set @nErrorCode = @@ERROR
End


--inserting the draft case into the OPENACTION table
If @nErrorCode = 0
Begin
	Set @sColumns = NULL
	Set @sSQL = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
			when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
			else COLUMN_NAME
			end
	 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'OPENACTION' and
	COLUMN_NAME not in ('CASEID')	

	--Generate SQL statement for Inserting a row into OPENACTION
	Set @sSQL = '
		Insert into OPENACTION (CASEID, ' +   @sColumns + '  )
		Select @nNewDraftCaseKey, '+ @sColumns + ' From OPENACTION where CASEID ='+ cast(@pnDraftCaseKey as nvarchar)
	
	exec @nErrorCode=sp_executesql @sSQL,
			 N'@nNewDraftCaseKey	int',
			   @nNewDraftCaseKey	= @nNewDraftCaseKey

	Set @nErrorCode = @@ERROR
End


--inserting the draft case into the CASETEXT table
If @nErrorCode = 0
Begin
	Set @sColumns = NULL
	Set @sSQL = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
			when (@sColumns is not null) then @sColumns + ', CT1.' + COLUMN_NAME
			else 'CT1.' + COLUMN_NAME
			end
	 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'CASETEXT' and
	COLUMN_NAME not in ('CASEID')	

	--Generate SQL statement for Inserting a row into CASETEXT
	Set @sSQL = '
		Insert into CASETEXT (CASEID, ' +   @sColumns + '  )
		select @nNewDraftCaseKey, '+ @sColumns + '
		from CASETEXT CT1
		where CT1.CASEID ='+ cast(@pnDraftCaseKey as nvarchar) + '
		and not exists (Select 0 
				from CASETEXT CT2
				where CT2.CASEID = @nNewDraftCaseKey
				and CT2.CLASS = CT1.CLASS
				and TEXTTYPE = @sGSTextType)'
	
	exec @nErrorCode=sp_executesql @sSQL,
			 N'@nNewDraftCaseKey	int,
			   @sGSTextType		nvarchar(2)',
			   @nNewDraftCaseKey	= @nNewDraftCaseKey,
			   @sGSTextType		= @sGSTextType

	Set @nErrorCode = @@ERROR
End


--inserting the draft case into the OFFICIALNUMBERS table
If @nErrorCode = 0
Begin
	Set @sColumns = NULL
	Set @sSQL = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
			when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
			else COLUMN_NAME
			end
	 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'OFFICIALNUMBERS' and
	COLUMN_NAME not in ('CASEID','OFFICIALNUMBERID')	

	--Generate SQL statement for Inserting a row into OFFICIALNUMBERS
	Set @sSQL = '
		Insert into OFFICIALNUMBERS (CASEID, ' +   @sColumns + '  )
		Select @nNewDraftCaseKey, '+ @sColumns + ' From OFFICIALNUMBERS where CASEID ='+ cast(@pnDraftCaseKey as nvarchar)
	
	exec @nErrorCode=sp_executesql @sSQL,
			 N'@nNewDraftCaseKey	int',
			   @nNewDraftCaseKey	= @nNewDraftCaseKey

	Set @nErrorCode = @@ERROR
End


--inserting the draft case into the RELATEDCASE table
If @nErrorCode = 0
Begin
	Set @sColumns = NULL
	Set @sSQL = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
			when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
			else COLUMN_NAME
			end
	 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'RELATEDCASE' and
	COLUMN_NAME not in ('CASEID')	

	--Generate SQL statement for Inserting a row into RELATEDCASE
	Set @sSQL = '
		Insert into RELATEDCASE (CASEID, ' +   @sColumns + '  )
		Select @nNewDraftCaseKey, '+ @sColumns + ' From RELATEDCASE where CASEID ='+ cast(@pnDraftCaseKey as nvarchar)
	
	exec @nErrorCode=sp_executesql @sSQL,
			 N'@nNewDraftCaseKey	int',
			   @nNewDraftCaseKey	= @nNewDraftCaseKey

	Set @nErrorCode = @@ERROR
End

--inserting the new draft case into the EDECASEMATCH table
If @nErrorCode = 0
Begin

	Set @sSQL = 'Insert into EDECASEMATCH (DRAFTCASEID,BATCHNO,TRANSACTIONIDENTIFIER,LIVECASEID,SEQUENCENO,MATCHLEVEL,APPROVALREQUIRED,
				  SESSIONNO,SUPERVISORDATE)
	Values (@nNewDraftCaseKey, @pnBatchNo, @psTransactionIdentifier, NULL, NULL, 3251, NULL, @pnSessionNo, NULL)'
	
	exec @nErrorCode=sp_executesql @sSQL,
			 N'@nNewDraftCaseKey	int,
			 @pnBatchNo				int,
			 @psTransactionIdentifier varchar(50),
			 @pnSessionNo			int',
			 @nNewDraftCaseKey	= @nNewDraftCaseKey,
			 @pnBatchNo			= @pnBatchNo,
			 @psTransactionIdentifier = @psTransactionIdentifier,
			 @pnSessionNo	= @pnSessionNo

	Set @nErrorCode = @@ERROR
End

-- delete the EDECASEMATCH row for the original draft case
If @nErrorCode = 0
Begin
	
	Set @sSQL = 'Delete from EDECASEMATCH Where DRAFTCASEID = @pnDraftCaseKey and BATCHNO = @pnBatchNo'
	
	exec @nErrorCode=sp_executesql @sSQL,
			 N'@pnDraftCaseKey	int,
			 @pnBatchNo				int',
			 @pnDraftCaseKey	= @pnDraftCaseKey,
			 @pnBatchNo			= @pnBatchNo

	Set @nErrorCode = @@ERROR

End

-- delete the Original Draft Case from the CASES table and Cascade delete will delete from all dependant tables.
If @nErrorCode = 0
Begin
	
	Set @sSQL = 'Delete from CASES Where CASEID = @pnDraftCaseKey'

	exec @nErrorCode=sp_executesql @sSQL,
			 N'@pnDraftCaseKey	int',
			 @pnDraftCaseKey	= @pnDraftCaseKey

	Set @nErrorCode = @@ERROR

End


-------------------------------------------------------------
-- Call a stored procedure to get the IRN to use for the Case
-- The procedure will actually update the CASES row.
-------------------------------------------------------------
If @nErrorCode = 0
Begin
	exec @nErrorCode=dbo.cs_ApplyGeneratedReference
				@psCaseReference =@sIRN	OUTPUT,
				@pnUserIdentityId=@pnUserIdentityId,
				@psCulture	 =@psCulture,
				@pnCaseKey	 =@nNewDraftCaseKey
End


If @nErrorCode=50000
Begin
	----------------------------
	-- If IRN failed to generate
	-- raise an issue
	----------------------------
	Set @nIssueNo = -27

	Set @sSQLString="
	Insert into EDEOUTSTANDINGISSUES(ISSUEID, BATCHNO, TRANSACTIONIDENTIFIER, DATECREATED)
	Select @nIssueNo, C.BATCHNO, C.TRANSACTIONIDENTIFIER, getdate()
	from EDECASEMATCH C
	left join EDEOUTSTANDINGISSUES I on (I.ISSUEID=@nIssueNo
					 and I.BATCHNO=C.BATCHNO
					 and I.TRANSACTIONIDENTIFIER=C.TRANSACTIONIDENTIFIER)
	where C.BATCHNO=@pnBatchNo
	and C.DRAFTCASEID=@nNewDraftCaseKey
	and I.ISSUEID is null"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo	int,
				  @nIssueNo	int,
				  @nCaseId	int',
				  @pnBatchNo=@pnBatchNo,
				  @nIssueNo =@nIssueNo,
				  @nCaseId  =@nNewDraftCaseKey
End


Return @nErrorCode
go

grant execute on dbo.ede_UnmapDraftCase to public
go