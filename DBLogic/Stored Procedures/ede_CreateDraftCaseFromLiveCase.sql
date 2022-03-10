-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_CreateDraftCaseFromLiveCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_CreateDraftCaseFromLiveCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ede_CreateDraftCaseFromLiveCase.'
	Drop procedure [dbo].[ede_CreateDraftCaseFromLiveCase]
End
Print '**** Creating Stored Procedure dbo.ede_CreateDraftCaseFromLiveCase...' 
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ede_CreateDraftCaseFromLiveCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@pnLiveCaseKey			int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnSessionNo			int,		-- Mandatory
	@pnDraftCaseKey			int		= null	output
)
as
-- PROCEDURE:	ede_CreateDraftCaseFromLiveCase
-- VERSION:	5
-- DESCRIPTION:	Copies the essential data from the specified live case into a new draft case.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- -----------	------	--------	-------	----------------------------------------------- 
-- 03 May 2007	IB	SQA12306	1	Procedure created
-- 01 Jun 2007  Dev	SQA12306	2	Changed the way the new IRN is created
-- 08 May 2007	MF	SQA17665	3	When copying OpenActions, determine the correct CriteriaNo to use
-- 21 Sep 2009  LP      RFC8047         4       Pass ProfileKey parameter to fn_GetCriteriaNo
-- 26 Feb 2015	LP	R44661		5	Identity column OFFICIALNUMBERID should not be inserted

-- Settings
SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON
-- Reset so that next procedure gets the default. 
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @nRowCount	int
declare @sSQLString	nvarchar(4000)
declare @sSQL		nvarchar(4000)
declare @sIRN		nvarchar(30)
declare @sColumns 	nvarchar(1000)
declare @sColumns1 	nvarchar(1000)
declare @sCaseType	char
declare @sGSTextType 	nvarchar(2)
declare @nCount 	int
declare @bFlag		bit	
declare @nProfileKey    int

-- Initialise variables
Set @nErrorCode 	= 0
Set @bFlag		= 0
Set @sCaseType 		= 'X'
Set @sGSTextType 	= 'G'

If @nErrorCode = 0
Begin
	exec @nErrorCode = dbo.ip_GetLastInternalCode
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture		= @psCulture,
			@psTable		= N'DRAFT CASES',
			@pnLastInternalCode	= @pnDraftCaseKey OUTPUT
End

-- Get the ProfileKey for the current user
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
        
        Set @nErrorCode = @@ERROR
End

--Generate the IRN to use for the Draft Case
If @nErrorCode=0
Begin
	Select @sIRN = IRN 
	from CASES 
	where CASEID = @pnLiveCaseKey
	
	Select @nErrorCode=@@Error,
	       @nRowCount =@@Rowcount
	       
	If @nErrorCode=0
	and @nRowCount=0
	Begin
		RAISERROR('@pnLiveCaseKey does not exist as a CASEID in CASES table', 14, 1)
		Set @nErrorCode = @@ERROR
	End

	If @nErrorCode=0
	Begin
		Select @nCount = count(IRN) 
		from CASES 
		where IRN like @sIRN+'%'
		
		Set @nErrorCode=@@Error

		Set @sIRN = @sIRN + cast(@nCount as nvarchar)
	End
	
	While @bFlag=0
	and @nErrorCode=0
	Begin
		if exists( Select * from CASES where IRN = @sIRN)
		Begin
			Set @nCount = @nCount + 1
			Set @sIRN = substring(@sIRN, 1, len(@sIRN) - len(@nCount))
			Set @sIRN = @sIRN + cast(@nCount as nvarchar)
		End
		Else
			Set @bFlag = 1
	End 
End

------------------------------------------------
-- Inserting the draft case into the CASES table
------------------------------------------------
If @nErrorCode = 0
Begin
	-- Get the Names of columns excluding CASEID, CASETYPE and IRN
	SELECT  @sColumns = case
				when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
				else COLUMN_NAME
			    end
	FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'CASES' 
	and COLUMN_NAME not in ('CASEID', 'CASETYPE','IRN','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
	
	Set @nErrorCode=@@Error
	
	If @nErrorCode=0
	Begin
		--Generate SQL statement for Inserting a row into CASES
		Set @sSQL = '
			Insert into CASES (CASEID,IRN, CASETYPE, ' +   @sColumns + '  )
			Select @pnDraftCaseKey, @sIRN, @sCaseType, '+ @sColumns + ' From CASES where CASEID ='+ cast(@pnLiveCaseKey as nvarchar)
		
		exec @nErrorCode=sp_executesql @sSQL,
				 N'@pnDraftCaseKey	int,
				   @sIRN		nvarchar(30),
				   @sCaseType		nvarchar(10)',
				   @pnDraftCaseKey	= @pnDraftCaseKey,
				   @sIRN		= @sIRN,
				   @sCaseType		= @sCaseType
	End
End

---------------------------------------------------
-- Inserting the draft case into the PROPERTY table
---------------------------------------------------
If @nErrorCode = 0
Begin
	Set @sColumns = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
				when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
				else COLUMN_NAME
			    end
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = 'PROPERTY' 
	and COLUMN_NAME not in ('CASEID','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
	
	Set @nErrorCode=@@Error

	If @nErrorCode=0
	Begin
		--Generate SQL statement for Inserting a row into PROPERTY
		Set @sSQL = '
			Insert into PROPERTY (CASEID, ' +   @sColumns + '  )
			Select @pnDraftCaseKey, '+ @sColumns + ' From PROPERTY where CASEID ='+ cast(@pnLiveCaseKey as nvarchar)
		
		exec @nErrorCode=sp_executesql @sSQL,
				 N'@pnDraftCaseKey	int',
				   @pnDraftCaseKey	= @pnDraftCaseKey
	End
End

---------------------------------------------------
-- Inserting the draft case into the CASENAME table
---------------------------------------------------
If @nErrorCode = 0
Begin
	Set @sColumns = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
				when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
				else COLUMN_NAME
			    end
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = 'CASENAME' 
	and COLUMN_NAME not in ('CASEID','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
	
	Set @nErrorCode=@@Error

	If @nErrorCode=0
	Begin	
		--Generate SQL statement for Inserting a row into CASENAMES
		Set @sSQL = '
			Insert into CASENAME (CASEID, ' +   @sColumns + '  )
			Select @pnDraftCaseKey, '+ @sColumns + ' From CASENAME where CASEID ='+ cast(@pnLiveCaseKey as nvarchar)
		
		exec @nErrorCode=sp_executesql @sSQL,
				 N'@pnDraftCaseKey	int',
				   @pnDraftCaseKey	= @pnDraftCaseKey
	End
End

------------------------------------------------------
-- Inserting the draft case into the OPENACTION table
------------------------------------------------------
If @nErrorCode = 0
Begin
	Set @sColumns = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
				when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
				else COLUMN_NAME
			    end
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = 'OPENACTION' 
	and COLUMN_NAME not in ('CASEID','CRITERIANO','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
	
	Set @nErrorCode=@@Error

	If @nErrorCode=0
	Begin
		-- Generate SQL statement for Inserting a row into OPENACTION
		-- Calculate the correct CRITERIANO for the new draft Case and
		-- do not insert a row if no Criteria exists.
		Set @sSQL = '
			Insert into OPENACTION (CASEID, CRITERIANO, ' +   @sColumns + '  )
			Select @pnDraftCaseKey, dbo.fn_GetCriteriaNo(@pnDraftCaseKey,''E'',ACTION,isnull(DATEFORACT,getdate()),@nProfileKey),'+ @sColumns + '
			From OPENACTION 
			where CASEID ='+ cast(@pnLiveCaseKey as nvarchar)+'
			and dbo.fn_GetCriteriaNo(@pnDraftCaseKey,''E'',ACTION,isnull(DATEFORACT,getdate()),@nProfileKey) is not null'
		
		exec @nErrorCode=sp_executesql @sSQL,
				 N'@pnDraftCaseKey	int,
				   @nProfileKey         int',
				   @pnDraftCaseKey	= @pnDraftCaseKey,
				   @nProfileKey         = @nProfileKey
	End
End

-----------------------------------------------------
-- Inserting the draft case into the CASEEVENT table
-----------------------------------------------------
If @nErrorCode = 0
Begin
	Set @sColumns = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns1 = case
				when (@sColumns1 is not null) then @sColumns1 + ',CE.' + COLUMN_NAME
				else 'CE.'+COLUMN_NAME
			    end,
		   @sColumns = case
			when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
			else  COLUMN_NAME
		    end
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = 'CASEEVENT' 
	and COLUMN_NAME not in ('CASEID','CREATEDBYCRITERIA','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
	
	Set @nErrorCode=@@Error

	If @nErrorCode=0
	Begin
		--Generate SQL statement for Inserting a row into CASEEVENT
		Set @sSQL = '
			Insert into CASEEVENT (CASEID, CREATEDBYCRITERIA,' +   @sColumns + '  )
			Select @pnDraftCaseKey, OA.CRITERIANO,'+ @sColumns1 + ' 
			From CASEEVENT CE
			left join (select distinct CASEID, ACTION, CRITERIANO
			           from OPENACTION) OA	on (OA.CASEID=@pnDraftCaseKey
							and OA.ACTION=CE.CREATEDBYACTION)
			where CE.CASEID ='+ cast(@pnLiveCaseKey as nvarchar)
		
		exec @nErrorCode=sp_executesql @sSQL,
				 N'@pnDraftCaseKey	int',
				   @pnDraftCaseKey	= @pnDraftCaseKey
	End
End

---------------------------------------------------
-- Inserting the draft case into the CASETEXT table
---------------------------------------------------
If @nErrorCode = 0
Begin
	Set @sColumns = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
				when (@sColumns is not null) then @sColumns + ', CT1.' + COLUMN_NAME
				else 'CT1.' + COLUMN_NAME
			    end
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = 'CASETEXT' 
	and COLUMN_NAME not in ('CASEID','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
	
	Set @nErrorCode=@@Error

	If @nErrorCode=0
	Begin
		--Generate SQL statement for Inserting a row into CASETEXT
		Set @sSQL = '
			Insert into CASETEXT (CASEID, ' +   @sColumns + '  )
			select @pnDraftCaseKey, '+ @sColumns + '
			from CASETEXT CT1
			where CT1.CASEID ='+ cast(@pnLiveCaseKey as nvarchar) + '
			and not exists (Select 0 
					from CASETEXT CT2
					where CT2.CASEID = @pnDraftCaseKey
					and CT2.CLASS = CT1.CLASS
					and TEXTTYPE = @sGSTextType)'
		
		exec @nErrorCode=sp_executesql @sSQL,
				 N'@pnDraftCaseKey	int,
				   @sGSTextType		nvarchar(2)',
				   @pnDraftCaseKey	= @pnDraftCaseKey,
				   @sGSTextType		= @sGSTextType
	End
End

----------------------------------------------------------
-- Inserting the draft case into the OFFICIALNUMBERS table
----------------------------------------------------------
If @nErrorCode = 0
Begin
	Set @sColumns = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
				when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
				else COLUMN_NAME
			    end
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = 'OFFICIALNUMBERS' 
	and COLUMN_NAME not in ('CASEID','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID','OFFICIALNUMBERID')
	
	Set @nErrorCode=@@Error

	If @nErrorCode=0
	Begin
		--Generate SQL statement for Inserting a row into OFFICIALNUMBERS
		Set @sSQL = '
			Insert into OFFICIALNUMBERS (CASEID, ' +   @sColumns + '  )
			Select @pnDraftCaseKey, '+ @sColumns + ' From OFFICIALNUMBERS where CASEID ='+ cast(@pnLiveCaseKey as nvarchar)
		
		exec @nErrorCode=sp_executesql @sSQL,
				 N'@pnDraftCaseKey	int',
				   @pnDraftCaseKey	= @pnDraftCaseKey
	End
End

------------------------------------------------------
-- Inserting the draft case into the RELATEDCASE table
------------------------------------------------------
If @nErrorCode = 0
Begin
	Set @sColumns = NULL

	-- Get the Names of columns excluding CASEID
	SELECT  @sColumns = case
				when (@sColumns is not null) then @sColumns + ', ' + COLUMN_NAME
				else COLUMN_NAME
			    end
	FROM INFORMATION_SCHEMA.COLUMNS 
	WHERE TABLE_NAME = 'RELATEDCASE' 
	and COLUMN_NAME not in ('CASEID','LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGAPPLICATION','LOGOFFICEID')
	
	Set @nErrorCode=@@Error

	If @nErrorCode=0
	Begin
		--Generate SQL statement for Inserting a row into RELATEDCASE
		Set @sSQL = '
			Insert into RELATEDCASE (CASEID, ' +   @sColumns + '  )
			Select @pnDraftCaseKey, '+ @sColumns + ' From RELATEDCASE where CASEID ='+ cast(@pnLiveCaseKey as nvarchar)
		
		exec @nErrorCode=sp_executesql @sSQL,
				 N'@pnDraftCaseKey	int',
				   @pnDraftCaseKey	= @pnDraftCaseKey
	End
End

-------------------------------------------------------------
-- Inserting the draft case into the EDETRANSACTIONBODY table
-------------------------------------------------------------
If @nErrorCode = 0
Begin
	Insert into EDETRANSACTIONBODY (BATCHNO, USERID, TRANSACTIONIDENTIFIER, TRANSACTIONRETURNCODE, TRANSSTATUSCODE,
					TRANSNARRATIVECODE)
	Values (-1, @pnUserIdentityId, @pnDraftCaseKey, NULL, 3460, NULL)

	Set @nErrorCode = @@Error
End

-------------------------------------------------------------
-- Inserting the draft case into the EDECASEMATCH table
-------------------------------------------------------------
If @nErrorCode = 0
Begin

	Insert into EDECASEMATCH (DRAFTCASEID,BATCHNO,TRANSACTIONIDENTIFIER,LIVECASEID,SEQUENCENO,MATCHLEVEL,APPROVALREQUIRED,
				  SESSIONNO,SUPERVISORDATE)
	Values (@pnDraftCaseKey, -1, @pnDraftCaseKey, @pnLiveCaseKey, NULL, 3254, NULL, @pnSessionNo, NULL)

	Set @nErrorCode = @@ERROR
End

-- select draft case key if called from Centura
If @nErrorCode = 0
and @pbCalledFromCentura = 1
Begin
	Select @pnDraftCaseKey
End

Return @nErrorCode
GO

Grant execute on dbo.ede_CreateDraftCaseFromLiveCase to public
GO