
if exists (select * from sysobjects where type='TR' and name = 'UpdateCASEEVENT')
begin
	PRINT 'Refreshing trigger UpdateCASEEVENT...'
	DROP TRIGGER UpdateCASEEVENT
end
go
	
CREATE TRIGGER [dbo].[UpdateCASEEVENT] ON [dbo].[CASEEVENT]
FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	UpdateCASEEVENT
-- VERSION:	4
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	------------------------------------------------------------- 
-- 17 Mar 2015	SW	45377	1	Trigger created to be called after update on EVENTTEXT OR EVENTLONGTEXT CaseEvent table
-- 16 Apr 2015  SW      45377   2       Used rowcount in while loop , explicitly set start value and increment value in identity column
--                                      and moved local decleration of @eventText, @eventtextid out of while loop.
-- 17 Apr 2015  SW      45377   3       Added GO-keyword
-- 22 Mar 2019	MF	DR-47719 4	An Event with a saved due date that is being satisfied should remove its EventNotes and when it
--					is no longer satisfied it should reinstate any shared notes.

If NOT UPDATE(LOGDATETIMESTAMP)
 Begin
      If Update(EVENTTEXT) or Update(EVENTLONGTEXT)
      Begin
        
        DECLARE @IdentityId int, @Count int = 1, @nRowCount int, @eventText nvarchar(max), @eventtextid int;
              
        DECLARE @ModifiedCaseEvents table ( 
                Id int identity(1,1),                
                CaseId int NOT NULL,
                EventNo int NOT NULL, 
                Cycle smallint NOT NULL,
                EventText nvarchar(max));
                
        -- get modified case events
        insert into @ModifiedCaseEvents (CaseId, EventNo, Cycle, EventText)
        select i.CASEID, i.EVENTNO, i.CYCLE, isnull(i.EVENTLONGTEXT, i.EVENTTEXT)
        from inserted i
        join deleted d on i.CASEID = d.CASEID
                      and i.EVENTNO = d.EVENTNO
                      and i.CYCLE = d.CYCLE
        where CHECKSUM(i.EVENTLONGTEXT) <> CHECKSUM(d.EVENTLONGTEXT)
          or CHECKSUM(i.EVENTTEXT) <> CHECKSUM(d.EVENTTEXT)
          
        set @nRowCount = @@ROWCOUNT;                 
	
	 --loop in @ModifiedCaseEvents and insert into eventtext and caseeventtext
        WHILE @Count <= @nRowCount        
        Begin        
                            	    
	      select @eventText = EventText from @ModifiedCaseEvents
	      where Id = @Count;
	        	
	      if exists(select 1 from CASEEVENTTEXT CET
	                        join EVENTTEXT ET on CET.EVENTTEXTID = ET.EVENTTEXTID
	                        join @ModifiedCaseEvents m on m.CaseId = CET.CASEID 
	                                                  and m.EventNo = CET.EVENTNO
	                                                  and m.Cycle = CET.CYCLE	                                        
	                where m.Id = @Count and ET.EVENTTEXTTYPEID is null)
	      Begin
	    
	        If @eventText is null
	        begin	                
	                -- delete caseeventtext instance when eventtext is set to a null value in caseevent
	                Delete CET
			        from @ModifiedCaseEvents m
			        join CASEEVENTTEXT CET on (CET.CASEID = m.CaseId					
					           and CET.EVENTNO = m.EventNo
					           and CET.CYCLE = m.Cycle)
			        join EVENTTEXT ET on (ET.EVENTTEXTID = CET.EVENTTEXTID)
			        where m.Id = @Count and ET.EVENTTEXTTYPEID is null 
	        end
	        else
	        begin	                
	                -- update eventtext when eventext is updated in caseevent
	                Update ET set ET.EVENTTEXT = @eventText
	                from @ModifiedCaseEvents m
	                        join CASEEVENTTEXT CET on (CET.CASEID = m.CaseId					
					           and CET.EVENTNO = m.EventNo
					           and CET.CYCLE = m.Cycle)
			        join EVENTTEXT ET on (ET.EVENTTEXTID = CET.EVENTTEXTID)
			        where m.Id = @Count and ET.EVENTTEXTTYPEID is null
			                and CHECKSUM(m.EventText) <> CHECKSUM(ET.EVENTTEXT)
	        end 
	      end
	      else
	      Begin	                
	                if(@eventText is not null)
	                Begin         	
	                        -- insert into caseeventtext and eventtext if there is no entry in 
	                        -- eventtext and caseventtext table	                        
	                        Insert into EVENTTEXT(EVENTTEXT, EVENTTEXTTYPEID) 
	                        Select @eventText, null	                
	
                                select @eventtextid = scope_identity();

	                        Insert into CASEEVENTTEXT(EVENTTEXTID, CASEID, EVENTNO, CYCLE) 
	                        Select @eventtextid, m.CaseId, m.EventNo, m.Cycle
	                        from @ModifiedCaseEvents m
	                        where  m.Id = @Count
	                End        		
	      End
	    Set @Count = @Count + 1; 
	  end    
      end

	If update(OCCURREDFLAG)
	begin
		------------------------------------------------------------------------
		-- When the OCCURREDFLAG is changed to a 9 it indicates that 
		-- the due date that was previously manually saved (DATEDUESAVED=1)
		-- is now satisfied by the existence of another Event.  When this occurs
		-- any EventNotes being pointed to are to be removed.
		------------------------------------------------------------------------
		delete CET
		from inserted i
		join deleted d		on (d.CASEID   =i.CASEID
					and d.EVENTNO  =i.EVENTNO
					and d.CYCLE    =i.CYCLE)
		join CASEEVENTTEXT CET	on (CET.CASEID =i.CASEID
					and CET.EVENTNO=i.EVENTNO
					and CET.CYCLE  =i.CYCLE)
		Where i.OCCURREDFLAG=9
		and   isnull(d.OCCURREDFLAG,0)<>9
		
		------------------------------------------------------------------------
		-- When the OCCURREDFLAG is changed to a value from 9 to something else
		-- the event is no longer considered to be satisfied.  If there are any
		-- shared Event Notes then these can be reinstated by inserting a row
		-- back into CASEEVENTTEXT.
		------------------------------------------------------------------------
		If exists(select 1 
			  from inserted i
			  join deleted d on (d.CASEID   =i.CASEID
					 and d.EVENTNO  =i.EVENTNO
					 and d.CYCLE    =i.CYCLE)
			  where i.EVENTNO<>-14
			  and d.OCCURREDFLAG=9
			  and isnull(i.OCCURREDFLAG,0)<>9)
		Begin
			insert into CASEEVENTTEXT(EVENTTEXTID, CASEID, EVENTNO, CYCLE)
			Select distinct CT.EVENTTEXTID, i.CASEID, i.EVENTNO, i.CYCLE
			from inserted i
			join deleted d on (d.CASEID   =i.CASEID
			               and d.EVENTNO  =i.EVENTNO
				       and d.CYCLE    =i.CYCLE)
			join EVENTS E1 on (E1.EVENTNO=i.EVENTNO)
			-------------------------------------------------
			-- Find other events that have the same NOTEGROUP
			-------------------------------------------------
			left join EVENTS E2 on (E2.NOTEGROUP=E1.NOTEGROUP)
			join CASEEVENTTEXT CT   on (CT.CASEID =i.CASEID
						and CT.EVENTNO=CASE WHEN(E2.EVENTNO is not null)       THEN E2.EVENTNO
									WHEN(E1.NOTESSHAREDACROSSCYCLES=1) THEN E1.EVENTNO
								END
						and CT.CYCLE = CASE WHEN(E1.NOTESSHAREDACROSSCYCLES=1 and E2.NOTESSHAREDACROSSCYCLES=1) THEN CT.CYCLE -- Text for both events are shared across cycles
									WHEN(E1.NOTESSHAREDACROSSCYCLES=1 and CT.EVENTNO=i.EVENTNO)     THEN CT.CYCLE -- Text for same event is shared across cycles
									WHEN(E2.NUMCYCLESALLOWED=1)                                     THEN 1	      -- Text can only exists for cycle 1
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
			---------------------------------------------
			-- CaseEvent row is no longer being satisfied
			---------------------------------------------
			and d.OCCURREDFLAG=9
			and isnull(i.OCCURREDFLAG,0)<>9
		End
	end

  end
    
  GO