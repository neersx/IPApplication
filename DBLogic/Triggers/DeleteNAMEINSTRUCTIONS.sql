/******************************************************************************************************************/
/*** Create DeleteNAMEINSTRUCTIONS trigger									***/
/******************************************************************************************************************/     
if exists (select * from sysobjects where type='TR' and name = 'DeleteNAMEINSTRUCTIONS')
begin
 	PRINT 'Refreshing trigger DeleteNAMEINSTRUCTIONS...'
	DROP TRIGGER DeleteNAMEINSTRUCTIONS
end
else
	PRINT 'Creating trigger DeleteNAMEINSTRUCTIONS...'
	print ''
go
	
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE TRIGGER DeleteNAMEINSTRUCTIONS ON NAMEINSTRUCTIONS FOR DELETE NOT FOR REPLICATION AS
-- TRIGGER:	DeleteNAMEINSTRUCTIONS    
-- VERSION:	6
-- DESCRIPTION:	If a NameInstructions row that is specific to a particular Case
--		is deleted then a recalculation is required for any Event that
--		has not occurred and is associated with an OpenAction and uses
--		the same instruction type.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 28-Jun-2004	MF	10950 	1	Trigger created
-- 19-Dec-2005	VL	12137	2	
-- 21-Jun-2010	MF	R9296	3	When a NameInstruction row is deleted the Case level
--					standing instructions are to be triggered to recalculate.
-- 06-Dec-2010	MF	R10073	4	Only raise a CASEINSTRUCTIONSRECALC request if the CASEID
--					exists CASES or NAMENO exists on NAME.
-- 28-Jul-2011	MF	R11031	5	When determining the Case Events to recalculate we need to consider
--					the possible Cycle(s) that may be calculated by looking at the calculation
--					rules and consider referenced events and their cycles.
-- 09 Jan 2014	MF	R41513	6	Events triggered to recalculate the due date (Type of Request = 6) should also consider Events that are flagged with RECALCEVENTDATE=1
--					if the Site Control 'Policing Recalculates Event' is set to TRUE.

	Declare @tbPolicing table (	POLICINGSEQNO	int	identity(0,1),
					CASEID		int,
					EVENTNO		int,
					CYCLE		smallint,
					CRITERIANO	int)

	Declare @nRowCount	int

	-- When Standing Instruction against a Case is deleted then have Policing
	-- recalculate any Events that calculate for the same Instruction Type
	Insert into @tbPolicing(CASEID, EVENTNO, CYCLE, CRITERIANO)
	Select distinct d.CASEID, 
			EC.EVENTNO, 
			isnull(	CASE WHEN(A.NUMCYCLESALLOWED>1) 
					THEN OA.CYCLE 
					ELSE Case DD.RELATIVECYCLE
						WHEN (0) Then CE1.CYCLE
						WHEN (1) Then CE1.CYCLE+1
						WHEN (2) Then CE1.CYCLE-1
							 Else isnull(DD.CYCLENUMBER,1)
					     End
				END,1), 
			OA.CRITERIANO
	from deleted d 
	join INSTRUCTIONS I	on (I.INSTRUCTIONCODE=d.INSTRUCTIONCODE)
	join OPENACTION OA	on (OA.CASEID=d.CASEID
				and OA.POLICEEVENTS=1)
	join ACTIONS A		on (A.ACTION=OA.ACTION)
	join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
				and EC.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
	left join SITECONTROL SC
				on (SC.CONTROLID='Policing Recalculates Event')
	left join DUEDATECALC DD
				on (DD.CRITERIANO=EC.CRITERIANO
				and DD.EVENTNO   =EC.EVENTNO)
	left join CASEEVENT CE1	on (CE1.CASEID =OA.CASEID
				and CE1.EVENTNO=DD.FROMEVENT)
	left join CASEEVENT CE2	on (CE2.CASEID =OA.CASEID
				and CE2.EVENTNO=EC.EVENTNO
				and CE2.CYCLE  =CASE WHEN(A.NUMCYCLESALLOWED>1) 
							THEN OA.CYCLE 
							ELSE Case DD.RELATIVECYCLE
								WHEN (0) Then CE1.CYCLE
								WHEN (1) Then CE1.CYCLE+1
								WHEN (2) Then CE1.CYCLE-1
									 Else isnull(DD.CYCLENUMBER,1)
							     End
						END)
	where (isnull(CE2.OCCURREDFLAG,0)=0 and isnull(CE2.DATEDUESAVED,0)=0)
	 or  (SC.COLBOOLEAN=1 and EC.RECALCEVENTDATE=1 and EC.SAVEDUEDATE between 2 and 5)

	Set @nRowCount=@@RowCount

	If @nRowCount>0
	Begin
		insert into POLICING (DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, CASEID, EVENTNO, CYCLE, CRITERIANO, TYPEOFREQUEST, SQLUSER)
		select getdate(), T.POLICINGSEQNO, convert(varchar, getdate(), 109)+' '+convert(varchar,T.POLICINGSEQNO), 1,0,T.CASEID, T.EVENTNO, T.CYCLE, T.CRITERIANO, 6, SYSTEM_USER
		from @tbPolicing T
		left join POLICING P	on (P.CASEID       =T.CASEID
					and P.EVENTNO      =T.EVENTNO
					and P.CYCLE        =T.CYCLE
					and P.CRITERIANO   =T.CRITERIANO
					and P.TYPEOFREQUEST=6
					and P.ONHOLDFLAG   =0)
		where P.CASEID is null
	End

	---------------------------------------------------
	-- Removal of a Standing Instruction against either
	-- a Name or a Case is to trigger the recalculation
	-- of the Standing Instructions against Cases.
	---------------------------------------------------
	-- Case Level
	Insert into CASEINSTRUCTIONSRECALC(CASEID, ONHOLDFLAG)
	select	d.CASEID, 0
	from deleted d
	join CASES C				on (C.CASEID=d.CASEID)
	left join CASEINSTRUCTIONSRECALC CI	on (CI.CASEID=d.CASEID
						and CI.ONHOLDFLAG=0)
	where CI.CASEID is null

	-- Name Level
	Insert into CASEINSTRUCTIONSRECALC(NAMENO, ONHOLDFLAG)
	select	d.NAMENO, 0
	from deleted d
	join NAME N				on (N.NAMENO=d.NAMENO)
	left join CASEINSTRUCTIONSRECALC CI	on (CI.NAMENO=d.NAMENO
						and CI.ONHOLDFLAG=0)
	where d.CASEID is null
	AND  CI.NAMENO is null
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
