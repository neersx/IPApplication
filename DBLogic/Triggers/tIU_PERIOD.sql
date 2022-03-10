if exists (select * from sysobjects where type='TR' and name = 'tIU_PERIOD')
begin
	PRINT 'Refreshing trigger tIU_PERIOD...'
	DROP TRIGGER tIU_PERIOD
end
go
	
CREATE TRIGGER tIU_PERIOD on PERIOD AFTER INSERT, UPDATE NOT FOR REPLICATION as
-- TRIGGER:	tIU_PERIOD    
-- VERSION:	2
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	MF	SQA17490 2	Ignore if trigger is being fired as a result of the audit details being updated
Begin

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	 Declare @INVALID_START_DATE  		int
	 Declare @INVALID_END_DATE  		int
	 Declare @INVALID_PERIOD_INCREMENT  	int
	 Declare @INVALID_YEAR_INCREMENT  	int
	 Declare @nErrorType int
	 Declare @dtStartDate 	datetime
	 Declare @dtEndDate 	datetime
	 Declare @pnPeriodId 	int

	 Set @INVALID_START_DATE 	= 1
	 Set @INVALID_END_DATE 		= 2
	 Set @INVALID_PERIOD_INCREMENT 	= 3
	 Set @INVALID_YEAR_INCREMENT 	= 4

	 Select	@dtStartDate = inserted.STARTDATE,
		@dtEndDate = inserted.ENDDATE,
		@pnPeriodId = inserted.PERIODID 
	 from 	inserted

	 Exec ar_ValidatePeriod 
		null, 
		null, 
		@nErrorType output , 
		@dtStartDate,
		@dtEndDate ,
		@pnPeriodId
	 If @nErrorType = @INVALID_START_DATE
		RAISERROR  ( 'The period start date is invalid.', 12,1)
	 else if @nErrorType = @INVALID_END_DATE
		RAISERROR  ( 'The period end date is invalid.', 12,1)
	 else if @nErrorType = @INVALID_PERIOD_INCREMENT
		RAISERROR  ( 'The period no is invalid.', 12,1)
	 else if @nErrorType = @INVALID_YEAR_INCREMENT
		RAISERROR  ( 'The period year is invalid.', 12,1)

	 If @nErrorType <> 0
		Rollback
	End
End
go