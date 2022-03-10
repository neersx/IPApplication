if exists (select * from sysobjects where type='TR' and name = 'DeleteRELATEDCASE_RecalcPriority')
begin
	PRINT 'Refreshing trigger DeleteRELATEDCASE_RecalcPriority...'
	DROP TRIGGER DeleteRELATEDCASE_RecalcPriority
end
go

CREATE TRIGGER DeleteRELATEDCASE_RecalcPriority
ON RELATEDCASE
FOR DELETE NOT FOR REPLICATION AS
Begin
-- TRIGGER:	DeleteRELATEDCASE_RecalcPriority  
-- VERSION:	1
-- DESCRIPTION:	When a RELATEDCASE row is deleted 
--		and the RELATIONSHIP updated the EVENTDATE of a Priority Event
--		then we should clear the EVENTDATE for the CASEEVENT row
--		and add a Policing request for it to be processed.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Aug-2014	LP	R38642	1	Trigger created
-- 21-Jan-2015	MF	R57245	2	Recode to allow for multiple RELATEDCASE rows to be deleted.
--					Only clear Event and Police if the EVENTDATE matches the date from which it was supposed to be extracted.
-- 25-Jul-2016	MF	63904	3	The removal of the CASEEVENT row should only occur if the Relationship is one that is flagged
--					as pointing to a parent case.
	declare @nIdentityId	int
	declare	@nRowCount	int
	----------------------------------------------------
	-- Table variable to hold CASEEVENT rows that are to 
	-- be cleared out and recalculated as a result of a 
	-- RelatedCase being deleted.
	----------------------------------------------------
	declare @tblCaseEvent	table (
			CaseId	int	not null,
			EventNo	int	not null,
			Cycle	int	not null,
			SeqNo	int	identity(1,1) )
	
	----------------------------------------------------
	-- Only CaseEvents whose EventDate matches the date 
	-- from the related Case is to be cleared out as a
	-- result of the RelatedCase being deleted.
	-- Also there must not be another RelatedCase of the
	-- same relationship that could now provide another
	-- date to be used as the EVENTDATE.
	----------------------------------------------------
	insert into @tblCaseEvent(CaseId, EventNo, Cycle)
	select	CE.CASEID, CE.EVENTNO, CE.CYCLE
	from deleted d
	join CASERELATION C	on (C.RELATIONSHIP = d.RELATIONSHIP
				and C.POINTERTOPARENT=1)
	join CASEEVENT CE	on (CE.CASEID      = d.CASEID
				and CE.EVENTNO     = C.EVENTNO
				and CE.EVENTDATE is not null)
	left join CASEEVENT CE1	on (CE1.CASEID     = d.RELATEDCASEID
				and CE1.EVENTNO    = C.FROMEVENTNO
				and CE1.CYCLE      = 1)
	where CE.EVENTDATE = CASE WHEN(CE1.CASEID IS NOT NULL) THEN CE1.EVENTDATE ELSE d.PRIORITYDATE END
	and not exists
	(select 1
	 from RELATEDCASE RC
	 left join CASEEVENT CE2 on (CE2.CASEID =RC.RELATEDCASEID
	                         and CE2.EVENTNO=C.FROMEVENTNO
	                         and CE2.CYCLE  =1)
	 where RC.CASEID         =d.CASEID
	 and   RC.RELATIONSHIP   =d.RELATIONSHIP
	 and   RC.RELATIONSHIPNO<>d.RELATIONSHIPNO
	 and   ISNULL(CE2.EVENTDATE, RC.PRIORITYDATE) is not null)
	
	Set @nRowCount = @@ROWCOUNT
	
	if (@nRowCount > 0)
	Begin
				
		Update CE 
		SET EVENTDATE = NULL, 
		    OCCURREDFLAG = 0
		From @tblCaseEvent t
		join CASEEVENT CE on (CE.CASEID =t.CaseId
				  and CE.EVENTNO=t.EventNo
				  and CE.CYCLE  =t.Cycle)
				  
		--------------------------------------------------
		-- Get the User Identity Id
		--------------------------------------------------
		select	@nIdentityId=CASE WHEN(substring(context_info,1,4) <>0x0000000) THEN cast(substring(context_info,1,4)  as int) END
		from master.dbo.sysprocesses
		where spid=@@SPID
		and substring(context_info,1, 4)<>0x0000000
						
		--------------------------------------------------
		-- Insert a POLICING row for the updated CASEEVENT
		--------------------------------------------------
		Insert Into POLICING
			(	DATEENTERED,
				POLICINGSEQNO,
				POLICINGNAME,	
				SYSGENERATEDFLAG,
				ONHOLDFLAG,
				CASEID,
				EVENTNO,
				CYCLE,
				SQLUSER,
				TYPEOFREQUEST,
				IDENTITYID
			)
		select		getdate(),
				t.SeqNo,
				dbo.fn_DateToString(getdate(),'CLEAN-DATETIME') + cast(t.SeqNo as nvarchar)+'Rel Case',	
				1,
				0,
				t.CaseId,
				t.EventNo,
				t.Cycle,
				SYSTEM_USER,
				3,
				@nIdentityId
		from @tblCaseEvent t
		
	End
End	
go	