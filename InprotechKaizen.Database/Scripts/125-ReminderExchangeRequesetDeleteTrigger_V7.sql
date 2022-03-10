/**********************************************************************************************************/
/*** Creation of trigger tD_ReminderExchangeRequest							***/
/**********************************************************************************************************/   
if exists (select * from sysobjects where type='TR' and name = 'tD_ReminderExchangeRequest')
   begin
    PRINT 'Refreshing trigger tD_ReminderExchangeRequest...'
    DROP TRIGGER tD_ReminderExchangeRequest
   end
  go	
-- TRIGGER :	tD_ReminderExchangeRequest
-- VERSION :	5
-- DESCRIPTION:	Trigger to add a delete exchange request to the queue.
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 	
-- 07 Mar 2017	vql	R61776		1	Trigger created
-- 18 May 2017	vql	R71387		2	Cater for when case, name and event do not exist (DR-30943)
-- 12 Jul 2017	LP	R71937		3	Cater for when delete does not affect any records
--									as well as when Exchange Integration is disabled (DR-32985)
-- 27 Dec 2017	vql	R73130		4	Improve error handling in trigger (DR-37458)
-- 19 Feb 2021	AK	DR-68356	5	Renamed ISSERVICEENABLED to ISREMINDERENABLED
-- 23 Feb 2021	LS	DR-68674	6	Fixed ISREMINDERENABLED check

CREATE TRIGGER  tD_ReminderExchangeRequest ON EMPLOYEEREMINDER FOR DELETE NOT FOR REPLICATION AS

	Declare @nStaffId						int
	Declare @bRequireExchangeIntegration	bit
	Declare @bIsExchangeServerRunning		bit
	Declare @sExchangeSettings				nvarchar(max)
	Declare @nErrorCode						int

	if exists (select 1 from deleted)
	Begin
		Select @nStaffId = d.EMPLOYEENO
		from deleted d

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
				Raiserror ('Error %d tD_ReminderExchangeRequest - Unable to find Staff', 10, 1, @nErrorCode)
			end

			if (@nErrorCode = 0 and @bRequireExchangeIntegration = 1)
			Begin
				INSERT INTO EXCHANGEREQUESTQUEUE(EMPLOYEENO, MESSAGESEQ, STATUSID, REQUESTTYPE, DATECREATED, REFERENCE, CASEID, NAMENO, ALERTNAMENO, EVENTNO)
				select N1.NAMENO, d.MESSAGESEQ, 0, 2, getdate(), d.REFERENCE, C.CASEID, N2.NAMENO, N3.NAMENO, E.EVENTNO
				from deleted d			
				left join CASES C on (C.CASEID = d.CASEID)
				left join EVENTS E on (E.EVENTNO = d.EVENTNO)			
				left join NAME N1 on (N1.NAMENO = d.EMPLOYEENO)
				left join NAME N2 on (N2.NAMENO = d.NAMENO)
				left join NAME N3 on (N3.NAMENO = d.ALERTNAMENO)		
				
				Set @nErrorCode=@@ERROR
			End
		End
	
		if @nErrorCode <> 0
		Begin
			Raiserror ('Error %d tD_ReminderExchangeRequest - Unable to create Exchange Request',  10,1, @nErrorCode)
		End	
	End	
go

