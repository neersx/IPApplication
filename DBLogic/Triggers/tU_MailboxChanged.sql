if exists (select * from sysobjects where type='TR' and name = 'tU_MailboxChanged')
   begin
    PRINT 'Refreshing trigger tU_MailboxChanged...'
    DROP TRIGGER tU_MailboxChanged
   end
  go	

CREATE TRIGGER  tU_MailboxChanged ON SETTINGVALUES  FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER :	tU_MailboxChanged
-- VERSION :	3
-- DESCRIPTION:	If the user’s mailbox changes, this trigger  re-sets the Exchange Initialised setting 
--		to false so that the new mailbox will be populated the next time a reminder is sent.
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 	
-- 05 Sep 2005	TM	RFC2952	 1	Trigger created
-- 06 Feb 2008	MF	SQA15192 2	Restrict the update only if any of the main columns have updated
--					as there are now LOG... columns which audit triggers update. Changes
--					to these LOG... columns should not reset the COLBOOLEAN column.
-- 17 Mar 2009	MF	SQA17490 3	Ignore if trigger is being fired as a result of the audit details being updated

If NOT UPDATE(LOGDATETIMESTAMP)
Begin
	If UPDATE(SETTINGVALUEID)
	or UPDATE(SETTINGID)
	or UPDATE(IDENTITYID)
	or UPDATE(COLCHARACTER)
	or UPDATE(COLINTEGER)
	or UPDATE(COLDECIMAL)
	or UPDATE(COLBOOLEAN)
	BEGIN
		Update 	SETTINGVALUES
		set 	SETTINGVALUES.COLBOOLEAN = 0
		from 	SETTINGVALUES  	
		join    inserted i	on (i.IDENTITYID = SETTINGVALUES.IDENTITYID
				   	and i.SETTINGID = 3)
		where SETTINGVALUES.SETTINGID = 1
		and isnull(SETTINGVALUES.COLBOOLEAN,1)=1
	END
END
go

