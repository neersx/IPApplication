if exists (select * from sysobjects where type='TR' and name = 'InsertCASEEVENT')
begin
	PRINT 'Refreshing trigger InsertCASEEVENT...'
	DROP TRIGGER InsertCASEEVENT
end
go
	
CREATE TRIGGER [dbo].[InsertCASEEVENT] ON [dbo].[CASEEVENT]
FOR INSERT NOT FOR REPLICATION AS
-- TRIGGER:	InsertCASEEVENT
-- VERSION:	7
-- DESCRIPTION:	
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	------------------------------------------------------------- 
-- 17 Mar 2015	SW	45377	1	Trigger created to be called after insert on CaseEvent table
-- 16 Apr 2015  SW      45377   2       Used rowcount in while loop and explicitly set start value and increment value in identity column
-- 17 Apr 2015  SW      45377   3       Added G_O
-- 23 Sep 2016	MF	64418	4	When a row is inserted into the CASEEVENT table we need to determine if the EVENT in question 
--					indicates that the EVENTTEXT is to be shared with other CASEEVENT rows.
-- 22 Aug 2018	MF	74751	5	Ignore CaseEvent rows where EVENTNO=-14.  This is because this can cause the triggers to bounce between here and
--					triggers on the CASEEVENTTEXT table which will also cause the CASEEVENT row for EventNo -14 to be updated.
-- 18 Apr 2019 DL	DR-48425 6	Fix bug - Maximum stored procedure, function, trigger, or view nesting level exceeded (limit 32)
-- 30 Oct 2019  MS      DR-53394 7      Fix issue where trigger was not running due to Logdatetimestamp check

If NOT UPDATE(LOGDATETIMESTAMP) or EXISTS (select 1 from inserted where LOGDATETIMESTAMP IS NULL)
Begin   
        DECLARE @IdentityId int, @Count int = 1, @nRowCount int;
              
        DECLARE @InsertedCaseEvents table ( 
                Id int identity(1,1),                
                CaseId int NOT NULL,
                EventNo int NOT NULL, 
                Cycle smallint NOT NULL,
                EventText nvarchar(max));
             
        -- get inserted case events
        insert into @InsertedCaseEvents (CaseId, EventNo, Cycle, EventText)
        select i.CASEID, i.EVENTNO, i.CYCLE, isnull(i.EVENTLONGTEXT,i.EVENTTEXT) 
        from inserted i
        where isnull(i.EVENTLONGTEXT,i.EVENTTEXT) is not null
	and i.EVENTNO<>-14;  
        
        set @nRowCount = @@ROWCOUNT;              

        --loop in @InsertedCaseEvents and insert into eventtext and caseeventtext
        WHILE @Count <= @nRowCount        
        Begin
                --insert into EVENTTEXT
	        Insert into EVENTTEXT(EVENTTEXT, EVENTTEXTTYPEID)	        
	        Select EventText, null
	        from @InsertedCaseEvents 
	        where Id = @Count
	
	        Set @IdentityId = SCOPE_IDENTITY();
	        
                -- insert into CASEEVENTTEXT
	        Insert into CASEEVENTTEXT(EVENTTEXTID, CASEID, EVENTNO, CYCLE) 
	        Select @IdentityId, CaseId, EventNo, Cycle
	        from @InsertedCaseEvents
	        where Id = @Count
	        	        
	        Set @Count=@Count+1 ;
	End
	--------------------------------------------------------------------------
	-- For each CASEEVENT row being inserted, check if the Event is configured
	-- so that EVENTTEXT associated with other CASEEVENT rows are to now be 
	-- linked to this CASEEVENT
	--------------------------------------------------------------------------
	If exists(select 1 from inserted where EVENTNO<>-14)
	Begin
		insert into CASEEVENTTEXT(EVENTTEXTID, CASEID, EVENTNO, CYCLE)
		Select distinct CT.EVENTTEXTID, i.CASEID, i.EVENTNO, i.CYCLE
		from inserted i
		join EVENTS E1 on (E1.EVENTNO=i.EVENTNO)
		-------------------------------------------------
		-- Find other events that have the same NOTEGROUP
		-------------------------------------------------
		left join EVENTS E2 on (E2.NOTEGROUP=E1.NOTEGROUP)
		join CASEEVENTTEXT CT on (CT.CASEID =i.CASEID
					and CT.EVENTNO=CASE WHEN(E2.EVENTNO is not null)       THEN E2.EVENTNO
								WHEN(E1.NOTESSHAREDACROSSCYCLES=1) THEN E1.EVENTNO
							END
					and CT.CYCLE = CASE WHEN(E1.NOTESSHAREDACROSSCYCLES=1 and E2.NOTESSHAREDACROSSCYCLES=1) THEN CT.CYCLE -- Text for both events are shared across cycles
								WHEN(E1.NOTESSHAREDACROSSCYCLES=1 and CT.EVENTNO=i.EVENTNO)         THEN CT.CYCLE -- Text for same event is share across cycles
								WHEN(E2.NUMCYCLESALLOWED=1)                                         THEN 1	    -- Text can only exists for cycle 1
																ELSE i.CYCLE  -- Use the current cycle to fetch text
							END)
		-------------------------------------------------
		-- Ensure the CaseEvent has not already been
		-- linked to the EventText
		-------------------------------------------------
		left join CASEEVENTTEXT CT1
					on (CT1.EVENTTEXTID=CT.EVENTTEXTID
					and CT1.CASEID     =i.CASEID
					and CT1.EVENTNO    =i.EVENTNO
					and CT1.CYCLE      =i.CYCLE)
		where (CT.EVENTNO<>E1.EVENTNO OR E1.NOTESSHAREDACROSSCYCLES=1)
		and CT1.EVENTTEXTID is null
		and i.EVENTNO<>-14
	End
End	
GO	  
	
	
	
