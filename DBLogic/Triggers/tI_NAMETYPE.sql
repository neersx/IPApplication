/**********************************************************************************************************/
/*** Creation of trigger tI_NAMETYPE 								***/
/**********************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'tI_NAMETYPE')
begin
	PRINT 'Refreshing trigger tI_NAMETYPE...'
	DROP TRIGGER tI_NAMETYPE
end
go

CREATE TRIGGER tI_NAMETYPE on NAMETYPE for INSERT NOT FOR REPLICATION as
-- TRIGGER :	tI_NAMETYPE
-- VERSION :	1
-- DESCRIPTION:	Whenever a NameType is added, automatically insert this
--  Name Type to Topic Control and marked this topic as hidden
--		
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18 Mar 2009	JC	RFC7756	1	Trigger Created

Begin
	insert into TOPICCONTROL (WINDOWCONTROLNO, TOPICNAME, ISHIDDEN, FILTERNAME, FILTERVALUE, ISINHERITED)
	select WC.WINDOWCONTROLNO, 'CaseNameTopic_' + Cast(N.NAMETYPEID as varchar),1, 'NameTypeCode', N.NAMETYPE, WC.ISINHERITED
		from inserted N
		join CRITERIA C on (C.PURPOSECODE = 'W')
		join WINDOWCONTROL WC on (WC.CRITERIANO = C.CRITERIANO AND WC.WINDOWNAME='CaseNameMaintenance')
End
go
