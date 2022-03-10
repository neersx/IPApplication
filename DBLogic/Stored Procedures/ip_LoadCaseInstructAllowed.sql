-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_LoadCaseInstructAllowed
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_LoadCaseInstructAllowed]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_LoadCaseInstructAllowed.'
	Drop procedure [dbo].[ip_LoadCaseInstructAllowed]
	Print '**** Creating Stored Procedure dbo.ip_LoadCaseInstructAllowed...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_LoadCaseInstructAllowed
(
	@pnCaseId		int		= null,		-- Case to be loaded
	@pnDefinitionId		int		= null,		-- Specific definition to be loaded
	@psTableName		nvarchar(50) 	= null,		-- Name of table listing Cases (CASEID) to be loaded
	@pbClearExisting	bit		= 0
)
-- PROCEDURE:	ip_LoadCaseInstructAllowed
-- VERSION :	3
-- DESCRIPTION:	Loads a table used to indicate that a Case is in a state that it may receive
--		instructions.  This table has been designed to improve online performance.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 20-Feb-2007	MF	RFC2982	1	Procedure created
-- 01 Jun 2010	MF	RFC9415	2	Change procedure so that CASEINSTRUCTALLOWED is only inserted by the
--					existence of the appropriate due date and if there is a prerequisite
--					event then that must exist as an occurred event for the same cycle.
-- 07 Apr 2016  MS      R52206  3       Added quotename for @psTableName to avoid sql injection


as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @sSQLString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

-- Optionally remove any CASEINSTRUCTALLOWED rows

If  @nErrorCode=0
and @pbClearExisting=1
Begin
	Set @sSQLString='
	Delete CASEINSTRUCTALLOWED
	from CASEINSTRUCTALLOWED CI'+char(10)+
	CASE WHEN(@psTableName is not null)
		THEN '	join '+ quotename(@psTableName,'') +' T on (T.CASEID=CI.CASEID)'+char(10)+
		     '	where 1=1'
		ELSE CASE WHEN(@pnCaseId is not null) 
			THEN '	where CI.CASEID=@pnCaseId'
			ELSE '	where 1=1'
		     END
	END

	If @pnDefinitionId is not null
		Set @sSQLString=@sSQLString+char(10)+'	and CI.DEFINITIONID=@pnDefinitionId'

	Exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnDefinitionId	int',
				  @pnCaseId=@pnCaseId,
				  @pnDefinitionId=@pnDefinitionId
End

If @nErrorCode = 0
Begin
	Set @sSQLString = "
	insert into CASEINSTRUCTALLOWED(CASEID,EVENTNO,CYCLE,DEFINITIONID)
	SELECT  distinct INCE.CASEID, INCE.EVENTNO, INCE.CYCLE,IND.DEFINITIONID
	FROM CASES C"+char(10)+

	CASE WHEN(@psTableName is not null)
		THEN "	join "+ quotename(@psTableName,'') +" T on (T.CASEID=C.CASEID)"+char(10)
	END+"
	CROSS JOIN INSTRUCTIONDEFINITION IND
	-- Locate the event that drives the applicability of the instruction
	JOIN EVENTS INE		on (INE.EVENTNO=IND.DUEEVENTNO)
	-- Locate the driving case event that must be a due date.
	join CASEEVENT INCE	on (INCE.CASEID      =C.CASEID
				and INCE.EVENTNO     =IND.DUEEVENTNO
				and INCE.OCCURREDFLAG=0)
	-- Find the best open action for the event and instruction
	Join (	select OA.CASEID, OA.ACTION, A.NUMCYCLESALLOWED, EC.EVENTNO, isnull(max(OA.CYCLE),null) as MAXCYCLE, isnull(min(OA.CYCLE),null) as MINCYCLE
		from EVENTCONTROL EC
		join OPENACTION OA	on (OA.CRITERIANO=EC.CRITERIANO
					and OA.POLICEEVENTS = 1)
		join ACTIONS A		on (A.ACTION=OA.ACTION)
		group by OA.CASEID, OA.ACTION, A.NUMCYCLESALLOWED, EC.EVENTNO) INOA 	
									on (INOA.CASEID=C.CASEID
									and(INOA.ACTION=IND.ACTION OR IND.ACTION is NULL)
									and INOA.EVENTNO=IND.DUEEVENTNO
									and INCE.CYCLE=
										case
										 -- For non-cyclic events, action is irrelevant
										 when INE.NUMCYCLESALLOWED=1 then INCE.CYCLE
										 -- If instruction is controlled by an action, event must match the cycle
										 when IND.ACTION is not null and INOA.NUMCYCLESALLOWED=1 then INCE.CYCLE 
										 when IND.ACTION is not null and IND.USEMAXCYCLE=1       then INOA.MAXCYCLE 
										 when IND.ACTION is not null and IND.USEMAXCYCLE=0       then INOA.MINCYCLE
										 -- If instruction has no action, use the max cycle for the OpenAction
										 else (	select max(OA2.CYCLE)
											from OPENACTION OA2
											where OA2.CASEID=INOA.CASEID
											and OA2.ACTION=INOA.ACTION
											and OA2.POLICEEVENTS=1)
										end)
	-- Ensure the row does not already exist
	left join CASEINSTRUCTALLOWED CI	on (CI.CASEID      =INCE.CASEID
						and CI.EVENTNO     =INCE.EVENTNO
						and CI.CYCLE       =INCE.CYCLE
						and CI.DEFINITIONID=IND.DEFINITIONID)
	-- Check for prerequisite event
	left join CASEEVENT CE			on (CE.CASEID =INCE.CASEID
						and CE.EVENTNO=IND.PREREQUISITEEVENTNO
						and CE.CYCLE  =INCE.CYCLE
						and CE.OCCURREDFLAG=1)

	where CI.CASEID IS NULL "+char(10)+
	CASE WHEN(@pnDefinitionId is not null)
		THEN "	and IND.DEFINITIONID=@pnDefinitionId"+char(10)
		ELSE ""
	END+
	CASE WHEN(@pnCaseId is not null) 
		THEN "	and C.CASEID=@pnCaseId"+char(10)
		ELSE ""
	END+char(9)+
	  -- If driven by prerequisite event, it must exist
	"and (IND.PREREQUISITEEVENTNO=CE.EVENTNO OR IND.PREREQUISITEEVENTNO is null)
	-- without any responses
	and not exists
	(select 1
	 from INSTRUCTIONRESPONSE R
	 join EVENTS E		on (E.EVENTNO=R.FIREEVENTNO)
	 join CASEEVENT CE1 	on (CE1.CASEID=C.CASEID
				and CE1.EVENTNO=R.FIREEVENTNO
				and CE1.CYCLE=
					case
					 when E.NUMCYCLESALLOWED=1 then 1
					 else INCE.CYCLE
					end)
	 where R.DEFINITIONID=IND.DEFINITIONID
	 and CE1.OCCURREDFLAG=1)"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnCaseId		int,
				  @pnDefinitionId	int',
				  @pnCaseId=@pnCaseId,
				  @pnDefinitionId=@pnDefinitionId
End

Return @nErrorCode
GO

Grant execute on dbo.ip_LoadCaseInstructAllowed to public
GO
