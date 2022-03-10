/** DR-47987 Add new Time Recording COMPONENT for auditing Time Recording via Apps **/

IF NOT EXISTS (select * from COMPONENTS where COMPONENTNAME = 'Time Recording')
BEGIN
    insert into COMPONENTS (COMPONENTNAME,INTERNALNAME) values ('Time Recording','Time Recording')

	EXEC ipu_UtilGenerateAuditTriggers 'DIARY'
END
GO