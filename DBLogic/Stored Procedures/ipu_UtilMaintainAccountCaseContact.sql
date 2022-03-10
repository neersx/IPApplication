-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_UtilMaintainAccountCaseContact
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_UtilMaintainAccountCaseContact]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipu_UtilMaintainAccountCaseContact.'
	Drop procedure [dbo].[ipu_UtilMaintainAccountCaseContact]
End
Print '**** Creating Stored Procedure dbo.ipu_UtilMaintainAccountCaseContact...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipu_UtilMaintainAccountCaseContact
(
	@pnDayLapsed		int		= 2,
	@pnCaseId		int		= null
)
as
-- PROCEDURE:	ipu_UtilMaintainAccountCaseContact
-- VERSION:	1
-- DESCRIPTION:	Recalculate the contents of the Account Case Contact table 
--		based on changes of CASENAME_iLOG in the last n days or a specific CaseId.
--		Can be run as:
--		*** Recalculate all cases that have casename changes in the last 2 days
--		EXEC ipu_UtilMaintainAccountCaseContact	
--		*** Recalculate specific case 
--		EXEC ipu_UtilMaintainAccountCaseContact	@pnCaseId = 339697
--		*** Recalculate  all cases that have casename changes in the last 5 days
--		EXEC ipu_UtilMaintainAccountCaseContact	@pnDayLapsed = 5


-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23-Apr-2009	DL		1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


create table #TEMPCASES( ROWID		int IDENTITY,
			 CASEID		int NOT NULL
			)

declare @TranCountStart	int
declare	@nErrorCode	int
declare @nNumberOfCases int
declare @nIndex int
declare @nCaseId int

-- Initialise variables
Set @nErrorCode = 0
Set @nNumberOfCases = 0

-------------------------------------------
-- Get cases to process
-------------------------------------------
If @nErrorCode = 0 
Begin
	If @pnCaseId is null
	Begin
		-- Get the list of CASES from CASENAME_iLOG that has changes in the last n days
		Insert into #TEMPCASES( CASEID)
		select DISTINCT CASEID
		from CASENAME_iLOG LOG
		WHERE LOG.LOGDATETIMESTAMP >= GETDATE() - @pnDayLapsed
		
		Select @nErrorCode=@@Error, @nNumberOfCases = @@ROWCOUNT
	End
	Else
	Begin
		-- maintain specific case only
		Insert into #TEMPCASES( CASEID)
		values(@pnCaseId )
		
		Select @nErrorCode=@@Error, @nNumberOfCases = 1

	End
End


-- For each case call ua_MaintainAccountCaseContact to update ACCOUNTCASECONTACT
If @nErrorCode = 0 and @nNumberOfCases > 0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	Set @nIndex = 1
	While @nErrorCode = 0 and @nIndex <= @nNumberOfCases
	Begin
		Set @nCaseId = null
		
		Select @nCaseId = CASEID 
		from #TEMPCASES
		where ROWID = @nIndex

		Select @nErrorCode=@@Error 

		if @nErrorCode = 0 and @nCaseId is not null
			exec @nErrorCode = ua_MaintainAccountCaseContact @pnCaseKey = @nCaseId

		Set @nIndex = @nIndex + 1
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


drop table #TEMPCASES

Return @nErrorCode
GO

Grant execute on dbo.ipu_UtilMaintainAccountCaseContact to public
GO
