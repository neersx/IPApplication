if exists (select * from sysobjects where type='TR' and name = 'tU_ReminderExchangeRequest')
	begin
	PRINT 'Refreshing trigger tU_ReminderExchangeRequest...'
	DROP TRIGGER tU_ReminderExchangeRequest
	end
	go	
-- TRIGGER :	tU_ReminderExchangeRequest
-- VERSION :	5
-- DESCRIPTION:	This trigger passes the details of any employee reminders that have been updated
-- 		to the EXCHANGEREQUESTQUEUE table for processing.
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 	
-- 07 Mar 2017	LP	R59311		1	Trigger created 
-- 12 Jul 2017	LP	R71937		2	Cater for when Exchange Integration is disabled (DR-32985)
-- 27 Dec 2017	vql	R73130		3	Improve error handling in trigger (DR-37458)
-- 15 Oct 2018	LP	DR44457		4	Do not execute trigger as a result of audit trigger firing.
-- 19 Feb 2021	AK	DR-68356	5	Renamed ISSERVICEENABLED to ISREMINDERENABLED
-- 23 Feb 2021	LS	DR-68674	6	Fixed ISREMINDERENABLED check

CREATE TRIGGER  tU_ReminderExchangeRequest ON EMPLOYEEREMINDER  FOR UPDATE NOT FOR REPLICATION AS
	Declare @nStaffId						int
	Declare @bRequireExchangeIntegration	bit
	Declare @bIsExchangeServerRunning		bit
	Declare @sExchangeSettings				nvarchar(max)	
	Declare @nErrorCode						int
	
	If NOT UPDATE(LOGDATETIMESTAMP)
	Begin
		Select @nStaffId = ER.EMPLOYEENO
		from inserted ER

		Set @nErrorCode=@@ERROR

		if (@nErrorCode = 0 and exists (select 1 from EXTERNALSETTINGS where PROVIDERNAME = 'ExchangeSetting'))
		begin
			Select @sExchangeSettings=replace(upper(SETTINGS),' ','') from EXTERNALSETTINGS where PROVIDERNAME = 'ExchangeSetting'
		
			Set @nErrorCode=@@ERROR

			if (@nErrorCode = 0)
			begin
				select @bIsExchangeServerRunning = 
				case when charindex('TRUE', substring(@sExchangeSettings, charindex('ISREMINDERENABLED', @sExchangeSettings), 23)) = 0
				then 0 
				else 1 
				end

				Set @nErrorCode=@@ERROR
			end
		end

		if (@nErrorCode = 0 and @bIsExchangeServerRunning = 1)
		Begin
			if (@nErrorCode = 0 and @nStaffId is not null)
			begin
				Select @bRequireExchangeIntegration = 1
				from dbo.fn_PermissionsGrantedName(@nStaffId, 'TASK', 51, NULL, getdate())
				where CanExecute = 1 

				Set @nErrorCode=@@ERROR
			end
			else begin 
				Raiserror ('Error %d tU_ReminderExchangeRequest - Unable to find Staff', 10, 1, @nErrorCode)
			end

			if (@nErrorCode = 0 and @bRequireExchangeIntegration = 1)
			Begin
				INSERT INTO EXCHANGEREQUESTQUEUE(EMPLOYEENO, MESSAGESEQ, STATUSID, REQUESTTYPE, DATECREATED, REFERENCE, CASEID, NAMENO, ALERTNAMENO, EVENTNO)
				SELECT ER.EMPLOYEENO, ER.MESSAGESEQ, 0, 1, getdate(), ER.REFERENCE, ER.CASEID, ER.NAMENO, ER.ALERTNAMENO, ER.EVENTNO 
				from inserted ER

				Set @nErrorCode=@@ERROR
			End
		End
		
		if @nErrorCode <> 0
		Begin
			Raiserror ('Error %d tU_ReminderExchangeRequest - Unable to create Exchange Request',  10,1, @nErrorCode)
		End
	End
go