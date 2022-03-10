-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ev_EventConsolidation
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ev_EventConsolidation]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ev_EventConsolidation.'
	Drop procedure [dbo].[ev_EventConsolidation]
	Print '**** Creating Stored Procedure dbo.ev_EventConsolidation...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ev_EventConsolidation
(
	@psOldEventNoString	varchar(8000),		-- Comma separated string of EventNo
	@pnNewEventNo		int,
	@pbPrintLog		bit		= 0,
	@pbCalledFromCentura    bit		= 0,
	@pbCheckBlockingRules	bit		= 0,	-- Flag to indicate that Blocking rules will be considered.
	@psRestrictToActions	nvarchar(1000)	= null	-- Optional comma separated list of Actions that Event Consolidation will be restricted to.
)
as
-- PROCEDURE:	ev_EventConsolidation
-- VERSION:	20
-- DESCRIPTION:	Used to consolidate one one or more Events into a single Event.
--		All references to the old Event must be changed to refer to the
--		new Event and on completion the old Events will be removed

-- MODIFICATIONS :
-- Date		Who	Number	    Version	Change
-- ------------	-------	------	    -------	----------------------------------------------- 
-- 12-Jan-2006  MF			1	Procedure created
-- 07-Jan-2007	DL	SQA15801	2	Fixed bug.
-- 24 Jul 2009	MF	SQA16548	3	The DISPLAYEVENTNO or FROMEVENTNO have been added to CASERELATION table.
-- 13 Jan 2010	MF	SQA18364	4	Event consolidation cannot update CASEEVENT.EVENTNO because audit triggers reset the EVENTNO.
--						Change the code to copy a new row into CASEEVENT for the new EVENTNO and then delete the 
--						CASEEVENT row with the old EVENTNO.
-- 15 Jul 2010	MF	R9565		5	Remove any OldEventNo rows in the EVENTREPLACED table where the EVENTNO is null
-- 25 Jul 2013	MF	R13690		6	Excluded columns with a uniqueidentifier when copying data from an existing Event.
-- 03 Mar 2015	MS	R43203		7	Replace CASEEVENTTEXT.EVENTNO reference to new event no
-- 18 Sep 2015	MF	R51952		8	Events can exist as a QUALIFIER in the QUERYCOLUMN table.
-- 09 Dec 2015	MF	R55492		9	Consolidation needs to consider the CASEEVENT.GOVERNINGEVENTNO column.
-- 26 May 2016	MF	R61991		10	Where the EVENTNO being consolidated forms a part of the primary key of the table, it is possible for
--						the Audit Triggers that are configured as an "Instead Of" trigger to cause the original EVENTNO to be
--						set back.  To avoid this the triggers on specific tables will be disabled temporarily.
-- 28 Jun 2016  Dw      R62052		11	If called from centura we need to select the error code.
-- 11 Jul 2016	MF	63725		12	If there are multiple events being consolidated then check that only 1 of those events already exists
--						within any given Criteria. Without that check the potential exists for the consolidated event to be 
--						inserted more than once into the Criteria resulting in a duplicate key error.
-- 28 Jul 2016	MF	64572		13	Revist 51952 to cater for non numeric qualifier causing a conversion error.
-- 16 Nov 2016	MF	69942		14	After the consolidation of CASEEVENTTEXT, ensure there are no notes for the one CaseEvent that has the same Event Text Type.
-- 28 Nov 2016	MF	69971		15	Event consolidation to include an option to consider Blocking Rules used by Law Updates as well as the 
--						option to restrict Event Consolidation to specific Actions.
-- 07 Dec 2016	MF	69971		16	Rework to improve the delete of the Event when a partial consolidation is being performed.
-- 05 May 2017	MF	71410		17	Need to introduce a new function fn_IsInteger because the ISNUMERIC function is treating a $ as a numeric.
-- 17 Jan 2019	MF	DR-46538	18	#TEMPACTIONS.ACTION to set collation to database_default.
-- 08 Feb 2019	MF	DR-46976	19	Change the consolidation of CASEEVENTTEXT to insert a new row rather than Update the EVENTNO, as this is inadvertently leading
--						to the deletion of the EVENTTEXT child row.
-- 08 Oct 2019	DL	DR-52857	20 Invalid column name error using Law Update Service (LUS)


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Create table	#TEMPOLDEVENTS	(OLDEVENTNO	int		not null)

Create table	#TEMPACTIONS	(ACTION		nvarchar(2)	collate database_default not null)

Create table	#TEMPCRITERIA	(CRITERIANO	int		not null PRIMARY KEY)

declare @TranCountStart		int
declare @ErrorCode		int
declare @RowCount		int
declare @nCaseEventTextCount	int

declare @sSQLString		nvarchar(max)
declare @sColumnList		nvarchar(max)
declare @sCriteriaList		nvarchar(max)
declare	@sComma			char(1)

Set @TranCountStart = @@TranCount
Set @ErrorCode      = 0
Set @RowCount	    = 0
Set @sComma         = ','

BEGIN TRANSACTION

-----------------------------------
-- Load the comma separated list of 
-- Old Events into a temporary table
-----------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPOLDEVENTS(OLDEVENTNO)
	select OLD.EVENTNO
	from EVENTS OLD
	join EVENTS NEW on (NEW.EVENTNO=@pnNewEventNo)
	where OLD.EVENTNO in ("+@psOldEventNoString+")"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnNewEventNo		int',
				  @pnNewEventNo=@pnNewEventNo

	Set @RowCount=@@Rowcount
	
	-- If no rows are found to be consolidated then set the ErrorCode
	-- to abort further processing.
	If  @ErrorCode=0
	and @RowCount =0
		Set @ErrorCode=-1
End
-----------------------------------
-- Load the comma separated list of 
-- Actions into a temporary table.
-- This is used if we want to limit
-- consolidations to those Actions.
-----------------------------------
If @ErrorCode=0
and @psRestrictToActions is not null
Begin
	Set @sSQLString="
	insert into #TEMPACTIONS(ACTION)
	select distinct Parameter
	from dbo.fn_Tokenise(@psRestrictToActions,@sComma)"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@psRestrictToActions	nvarchar(1000),
				  @sComma		char(1)',
				  @psRestrictToActions	=@psRestrictToActions,
				  @sComma		=@sComma
End

--------------------------------------
-- Check if consideration is to be
-- given to the Blocking Rules when
-- performing consolidations.
--------------------------------------
If  @pbCheckBlockingRules=1
and @ErrorCode=0
Begin
	-----------------------------------------
	-- Load the CRITERIA that are candidates
	-- to be imported into a temporary table.
	-- This allows rules defined by a firm to
	-- block or allow criteria.
	-----------------------------------------
	set @sSQLString="
	insert into #TEMPCRITERIA (CRITERIANO)
	select distinct C.CRITERIANO
	from (select EC.CRITERIANO
	      from EVENTCONTROL EC
	      join #TEMPOLDEVENTS E on (E.OLDEVENTNO in (EC.EVENTNO, EC.UPDATEFROMEVENT))
	      UNION
	      select DD.CRITERIANO
	      from DUEDATECALC DD
	      join #TEMPOLDEVENTS E on (E.OLDEVENTNO in (DD.FROMEVENT, DD.COMPAREEVENT))
	      UNION
	      select RE.CRITERIANO
	      from RELATEDEVENTS RE
	      join #TEMPOLDEVENTS E on (E.OLDEVENTNO in (RE.RELATEDEVENT))
	      UNION
	      select DC.CRITERIANO
	      from DETAILCONTROL DC
	      join #TEMPOLDEVENTS E on (E.OLDEVENTNO in (DC.DISPLAYEVENTNO, DC.HIDEEVENTNO, DC.DIMEVENTNO))
	      UNION
	      select DD.CRITERIANO
	      from DETAILDATES DD
	      join #TEMPOLDEVENTS E on (E.OLDEVENTNO in (DD.EVENTNO, DD.OTHEREVENTNO))
	      ) C2
	join CRITERIA C	on (C.CRITERIANO=C2.CRITERIANO)"
	
	If @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPACTIONS T on (T.ACTION=C.ACTION)"
		
	set @sSQLString=@sSQLString+"
	left join CRITERIA C1 on (C1.CRITERIANO = dbo.fn_GetCriteriaNoForLawImportBlocking( C.CASETYPE,	
											    C.ACTION,
											    C.PROPERTYTYPE,
											    C.COUNTRYCODE,
											    C.CASECATEGORY,
											    C.SUBTYPE,
											    C.BASIS,
											    C.DATEOFACT) )
	where isnull(C1.RULEINUSE,0)=0"
	
	exec @ErrorCode=sp_executesql @sSQLString
End
Else 
If @psRestrictToActions is not null
and @ErrorCode=0
Begin
	-----------------------------------------
	-- Load the CRITERIA that are candidates
	-- to be imported into a temporary table
	-- that match the Actions that the event
	-- consolidation is to be restricted to.
	-----------------------------------------
	set @sSQLString="
	insert into #TEMPCRITERIA (CRITERIANO)
	select distinct C.CRITERIANO
	from CRITERIA C
	join #TEMPACTIONS T on (T.ACTION=C.ACTION)
	where C.PURPOSECODE='E'"
	
	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
and @RowCount>1
Begin
	-- Check if more than one EventNo that is to be concatenated
	-- already exists in any one CriteriaNo, and if so generate
	-- a list of those CriteriaNo
	if @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		select @sCriteriaList=CASE WHEN(@sCriteriaList is not null) THEN @sCriteriaList+',' ELSE '' END  + ''''+cast(EC.CRITERIANO as varchar)+''''
		from EVENTCONTROL EC 
		join #TEMPCRITERIA C  on (C.CRITERIANO=EC.CRITERIANO)
		join #TEMPOLDEVENTS T on (T.OLDEVENTNO=EC.EVENTNO)
		group by EC.CRITERIANO
		having COUNT(*)>1
		order by EC.CRITERIANO
	Else
		select @sCriteriaList=CASE WHEN(@sCriteriaList is not null) THEN @sCriteriaList+',' ELSE '' END  + ''''+cast(EC.CRITERIANO as varchar)+''''
		from EVENTCONTROL EC 
		join #TEMPOLDEVENTS T on (T.OLDEVENTNO=EC.EVENTNO)
		group by EC.CRITERIANO
		having COUNT(*)>1
		order by EC.CRITERIANO
	
	If @sCriteriaList is not null
	Begin	
		Set @sCriteriaList='Only 1 event being consolidated may exist in any given Criteria. The following Criteria have more than 1 of these events: '+ @sCriteriaList
		RAISERROR(@sCriteriaList, 14, 1)
		Set @ErrorCode = @@ERROR
	End
End

-- Data cleanup
-- Remove invalid EVENTSREPLACED
-- rows pointing to a NULL Event.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Delete ER
	from #TEMPOLDEVENTS T
	join EVENTSREPLACED ER on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where ER.EVENTNO is null"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Load the Events to be consolidated into a cross reference table.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into EVENTSREPLACED(OLDEVENTNO, EVENTNO) 
	Select T.OLDEVENTNO, @pnNewEventNo
	from #TEMPOLDEVENTS T
	left join EVENTSREPLACED ER on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where ER.OLDEVENTNO is null"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnNewEventNo		int',
				  @pnNewEventNo=@pnNewEventNo
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	update EVENTSREPLACED
	set EVENTNO=@pnNewEventNo
	from #TEMPOLDEVENTS T
	join EVENTSREPLACED ER on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where ER.EVENTNO<>@pnNewEventNo"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnNewEventNo		int',
				  @pnNewEventNo=@pnNewEventNo
End


If @ErrorCode=0
Begin
	-- Get the comma separated list of Columns in the table being consolidated
	Set @sColumnList = null

	Select @sColumnList=isnull(nullif(@sColumnList+',',','),'')
				+CASE WHEN(COLUMN_NAME='EVENTNO') THEN 'ER.' ELSE 'E1.' END
				+COLUMN_NAME
	from INFORMATION_SCHEMA.COLUMNS
	where TABLE_NAME='EVENTCONTROL'
	and DATA_TYPE not in ('sysname','uniqueidentifier')
	order by ORDINAL_POSITION

	Set @sSQLString="
	insert into EVENTCONTROL("+@sColumnList+")
	select "+@sColumnList+"
	from EVENTCONTROL E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where not exists
	(select * from EVENTCONTROL E2
	 where E2.CRITERIANO=E1.CRITERIANO
	 and   E2.EVENTNO=ER.EVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - EVENTCONTROL rows inserted '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update EMPLOYEEREMINDER
	set EVENTNO=ER.EVENTNO
	from EMPLOYEEREMINDER E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join CASEEVENT CE     on (CE.CASEID =E1.CASEID"  +CHAR(10)+
		"	                      and CE.EVENTNO=E1.EVENTNO" +CHAR(10)+
		"	                      and CE.CYCLE  =E1.CYCLENO)"+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=CE.CREATEDBYCRITERIA)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - EMPLOYEEREMINDER rows updated '+CONVERT(CHAR(10), @RowCount)
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	update EVENTCONTROL
	set UPDATEFROMEVENT=ER.EVENTNO
	from EVENTCONTROL E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.UPDATEFROMEVENT)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - EVENTCONTROL.UPDATEFROMEVENT rows updated '+CONVERT(CHAR(10), @RowCount)
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	update CRITERIACHANGES
	set EVENTNO=ER.EVENTNO
	from CRITERIACHANGES E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CRITERIACHANGES rows updated '+CONVERT(CHAR(10), @RowCount)
End


If @ErrorCode=0
Begin
	-----------------------------------------
	-- Triggers need to be disabled because
	-- column in primary key is being changed
	-----------------------------------------
	alter table REMINDERS
	    disable trigger all
	    
	Set @sSQLString="
	update REMINDERS
	set EVENTNO=ER.EVENTNO
	from REMINDERS E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where not exists
	(select * from REMINDERS E2
	 where E2.CRITERIANO=E1.CRITERIANO
	 and   E2.EVENTNO=ER.EVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - REMINDERS rows updated '+CONVERT(CHAR(10), @RowCount)
	-----------------------------------------
	-- Enable triggers again after the Update
	-----------------------------------------
	alter table REMINDERS
	    enable trigger all
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	delete DUEDATECALC
	from DUEDATECALC E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.FROMEVENT)
	where E1.COMPARISON is null
	and exists
	(select * 
	 from DUEDATECALC DD
	 join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	 where DD.CRITERIANO	=E1.CRITERIANO
	 and   DD.EVENTNO   	=E1.EVENTNO
	 and   DD.FROMEVENT 	=ER.EVENTNO
	 and   DD.CYCLENUMBER	=E1.CYCLENUMBER
	 and  (DD.COUNTRYCODE	=E1.COUNTRYCODE OR (DD.COUNTRYCODE is null and E1.COUNTRYCODE is null))
	 and   DD.RELATIVECYCLE	=E1.RELATIVECYCLE
	 and   DD.COMPARISON is null
	 and   DD.OPERATOR	=E1.OPERATOR
	 and   DD.DEADLINEPERIOD=E1.DEADLINEPERIOD
	 and   DD.PERIODTYPE	=E1.PERIODTYPE
	 and   DD.EVENTDATEFLAG	=E1.EVENTDATEFLAG)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - DUEDATECALC row duplicated removed '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	-----------------------------------------
	-- Triggers need to be disabled because
	-- column in primary key is being changed
	-----------------------------------------
	alter table DUEDATECALC
	    disable trigger all
	    
	Set @sSQLString="
	update DUEDATECALC
	set EVENTNO=ER.EVENTNO
	from DUEDATECALC E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where not exists
	(select * from DUEDATECALC E2
	 where E2.CRITERIANO=E1.CRITERIANO
	 and   E2.EVENTNO=ER.EVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - DUEDATECALC rows updated '+CONVERT(CHAR(10), @RowCount)
	-----------------------------------------
	-- Enable triggers again after the Update
	-----------------------------------------
	alter table DUEDATECALC
	    enable trigger all
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	update DUEDATECALC
	set FROMEVENT=ER.EVENTNO
	from DUEDATECALC E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.FROMEVENT)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - DUEDATECALC FromEvent rows updated '+CONVERT(CHAR(10), @RowCount)
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	update DUEDATECALC
	set COMPAREEVENT=ER.EVENTNO
	from DUEDATECALC E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.COMPAREEVENT)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - DUEDATECALC CompareEvent rows updated '+CONVERT(CHAR(10), @RowCount)
End


If @ErrorCode=0
Begin
	-----------------------------------------
	-- Triggers need to be disabled because
	-- column in primary key is being changed
	-----------------------------------------
	alter table RELATEDEVENTS
	    disable trigger all
	    
	Set @sSQLString="
	update RELATEDEVENTS
	set EVENTNO=ER.EVENTNO
	from RELATEDEVENTS E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where not exists
	(select * from RELATEDEVENTS E2
	 where E2.CRITERIANO=E1.CRITERIANO
	 and   E2.EVENTNO=ER.EVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - RELATEDEVENTS rows updated '+CONVERT(CHAR(10), @RowCount)
	-----------------------------------------
	-- Enable triggers again after the Update
	-----------------------------------------
	alter table RELATEDEVENTS
	    enable trigger all
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	update RELATEDEVENTS
	set RELATEDEVENT=ER.EVENTNO
	from RELATEDEVENTS E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.RELATEDEVENT)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - RELATEDEVENTS RelatedEvent rows updated '+CONVERT(CHAR(10), @RowCount)
End
	

-- Delete any RelatedEvents that will reference themselves after the consolidation

If @ErrorCode=0
Begin
	Set @sSQLString="
	delete RELATEDEVENTS
	from #TEMPOLDEVENTS T
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	join RELATEDEVENTS E1	on (E1.EVENTNO=ER.EVENTNO
				and E1.RELATEDEVENT=ER.EVENTNO)"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	where E1.RELATIVECYCLE in (0,3)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - RELATEDEVENTS rows deleted '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update DETAILCONTROL
	set DISPLAYEVENTNO=ER.EVENTNO
	from DETAILCONTROL E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.DISPLAYEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - DETAILCONTROL DisplayEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update DETAILCONTROL
	set HIDEEVENTNO=ER.EVENTNO
	from DETAILCONTROL E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.HIDEEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - DETAILCONTROL HideEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update DETAILCONTROL
	set DIMEVENTNO=ER.EVENTNO
	from DETAILCONTROL E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.DIMEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - DETAILCONTROL DimEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update DETAILDATES
	set OTHEREVENTNO=ER.EVENTNO
	from DETAILDATES E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.OTHEREVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - DETAILDATES OtherEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	-----------------------------------------
	-- Triggers need to be disabled because
	-- column in primary key is being changed
	-----------------------------------------
	alter table DETAILDATES
	    disable trigger all
	    
	Set @sSQLString="
	update DETAILDATES
	set EVENTNO=ER.EVENTNO
	from DETAILDATES E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where not exists
	(Select * from DETAILDATES E2
	 where E2.CRITERIANO=E1.CRITERIANO
	 and   E2.ENTRYNUMBER=E1.ENTRYNUMBER
	 and   E2.EVENTNO=ER.EVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - DETAILDATES rows updated '+CONVERT(CHAR(10), @RowCount)
		
	-----------------------------------------
	-- Enable triggers again after the Update
	-----------------------------------------
	alter table DETAILDATES
	    enable trigger all
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Delete DETAILDATES
	from DETAILDATES E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	and exists
	(select * from DETAILDATES E2
	 where E2.CRITERIANO=E1.CRITERIANO
	 and E2.ENTRYNUMBER=E1.ENTRYNUMBER
	 and E2.EVENTNO=ER.EVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - DETAILDATES rows deleted '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update PROTECTCODES
	set EVENTNO=ER.EVENTNO
	from PROTECTCODES E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - PROTECTCODES rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update CHARGETYPE
	set CHARGEDUEEVENT=ER.EVENTNO
	from CHARGETYPE E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.CHARGEDUEEVENT)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CHARGETYPE CHARGEDUEEVENT rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update CHARGETYPE
	set CHARGEINCURREDEVENT=ER.EVENTNO
	from CHARGETYPE E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.CHARGEINCURREDEVENT)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CHARGETYPE CHARGEINCURREDEVENT rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update CHECKLISTITEM
	set UPDATEEVENTNO=ER.EVENTNO
	from CHECKLISTITEM E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.UPDATEEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CHECKLISTITEM UpdateEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update CHECKLISTITEM
	set NOEVENTNO=ER.EVENTNO
	from CHECKLISTITEM E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.NOEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CHECKLISTITEM NoEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	-- CASEEVENT
	-- Get the comma separated list of Columns in the table being consolidated
	Set @sColumnList = null

	Select @sColumnList=isnull(nullif(@sColumnList+',',','),'')
				+CASE WHEN(COLUMN_NAME='EVENTNO') THEN 'ER.' ELSE 'E1.' END
				+COLUMN_NAME
	from INFORMATION_SCHEMA.COLUMNS
	where TABLE_NAME='CASEEVENT'
	and DATA_TYPE not in ('sysname','uniqueidentifier')
	order by ORDINAL_POSITION

	Set @sSQLString="
	insert into CASEEVENT("+@sColumnList+")
	select "+@sColumnList+"
	from CASEEVENT E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CREATEDBYCRITERIA)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where not exists
	(select * from CASEEVENT CE1
	 where CE1.CASEID=E1.CASEID
	 and CE1.EVENTNO=ER.EVENTNO
	 and CE1.CYCLE=E1.CYCLE)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If @RowCount > 0  and @ErrorCode = 0
	Begin
	
		-- CASEEVENTTEXT
		-- Get the comma separated list of Columns in the table being consolidated
		Set @sColumnList = null

		Select @sColumnList=isnull(nullif(@sColumnList+',',','),'')
					+CASE WHEN(COLUMN_NAME='EVENTNO') THEN 'ER.' ELSE 'E1.' END
					+COLUMN_NAME
		from INFORMATION_SCHEMA.COLUMNS
		where TABLE_NAME='CASEEVENTTEXT'
		and DATA_TYPE not in ('sysname','uniqueidentifier')
		order by ORDINAL_POSITION

		Set @sSQLString="
		insert into CASEEVENTTEXT("+@sColumnList+")
		select "+@sColumnList+"
		from CASEEVENTTEXT E1"

		-- DR-52857 Invalid column name error using Law Update Service (LUS)
		If @pbCheckBlockingRules=1
		or @psRestrictToActions is not null
			Set @sSQLString=@sSQLString+CHAR(10)+
			"	join CASEEVENT CE     on (CE.CASEID =E1.CASEID"  +CHAR(10)+
			"	                      and CE.EVENTNO=E1.EVENTNO" +CHAR(10)+
			"	                      and CE.CYCLE  =E1.CYCLE)"+CHAR(10)+
			"	join #TEMPCRITERIA C  on (C.CRITERIANO=CE.CREATEDBYCRITERIA)"
	
		Set @sSQLString=@sSQLString+"
		join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
		join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
		where not exists
		(select * from CASEEVENTTEXT CE1
		 where CE1.CASEID     =E1.CASEID
		 and   CE1.EVENTNO    =ER.EVENTNO
		 and   CE1.CYCLE      =E1.CYCLE
		 and   CE1.EVENTTEXTID=E1.EVENTTEXTID)"

		Exec @ErrorCode=sp_executesql @sSQLString
	 
		 Set @nCaseEventTextCount=@@ROWCOUNT
		 
		 If  @nCaseEventTextCount>0
		 and @ErrorCode=0
		 Begin
			----------------------------------------------
			-- After CASEEVENTTEXT have been consolidated, 
			-- we need to ensure that there is only one
			-- EVENTTEXT of the same Event Text Type for
			-- a given CASEEVENT.
			----------------------------------------------
			Set @sSQLString="
			declare @tblDuplicateText table (
				CASEID		int	not null,
				EVENTNO		int	not null,
				CYCLE		int	not null,
				EVENTTEXTTYPEID	int	null)
			
			Insert into @tblDuplicateText(CASEID, EVENTNO, CYCLE, EVENTTEXTTYPEID)
			select CET.CASEID, CET.EVENTNO, CET.CYCLE, ET.EVENTTEXTTYPEID
			from #TEMPOLDEVENTS T
			join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
			join CASEEVENTTEXT CET	on (CET.EVENTNO  =ER.EVENTNO)
			join EVENTTEXT ET	on (ET.EVENTTEXTID=CET.EVENTTEXTID)
			group by CET.CASEID, CET.EVENTNO, CET.CYCLE, ET.EVENTTEXTTYPEID
			having COUNT(*)>1
			
			delete CET
			from @tblDuplicateText DT
			join CASEEVENTTEXT CET	on (CET.CASEID =DT.CASEID
						and CET.EVENTNO=DT.EVENTNO
						and CET.CYCLE  =DT.CYCLE)
			join EVENTTEXT ET	on (ET.EVENTTEXTID    =CET.EVENTTEXTID
						and(ET.EVENTTEXTTYPEID=DT.EVENTTEXTTYPEID OR (ET.EVENTTEXTTYPEID is null and DT.EVENTTEXTTYPEID is null)))
			join  CASEEVENTTEXT CET1 on(CET1.CASEID =DT.CASEID
						and CET1.EVENTNO=DT.EVENTNO
						and CET1.CYCLE  =DT.CYCLE
						and CET1.EVENTTEXTID>CET.EVENTTEXTID)
			join EVENTTEXT ET1	on (ET1.EVENTTEXTID    =CET1.EVENTTEXTID
						and(ET1.EVENTTEXTTYPEID=DT.EVENTTEXTTYPEID OR (ET1.EVENTTEXTTYPEID is null and DT.EVENTTEXTTYPEID is null)))"

			Exec @ErrorCode=sp_executesql @sSQLString
		 End
	End

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CASEEVENT rows replaced '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Delete CASEEVENT
	from CASEEVENT E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CREATEDBYCRITERIA)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	and exists
	(select * from CASEEVENT CE1
	 where CE1.CASEID=E1.CASEID
	 and CE1.EVENTNO=ER.EVENTNO
	 and CE1.CYCLE=E1.CYCLE)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CASEEVENT rows deleted '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update CASEEVENT
	set GOVERNINGEVENTNO=ER.EVENTNO
	from CASEEVENT E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CREATEDBYCRITERIA)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.GOVERNINGEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CASEEVENT.GOVERNINGEVENTNO rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update OPENACTION
	set LASTEVENT=ER.EVENTNO
	from OPENACTION E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.LASTEVENT)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - OPENACTION rows updated '+CONVERT(CHAR(10), @RowCount)
End


If @ErrorCode=0
Begin
	Set @sSQLString="
	DELETE EVENTCONTROL 
	from EVENTCONTROL E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPCRITERIA C  on (C.CRITERIANO=E1.CRITERIANO)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where exists
	(select *
	 from EVENTCONTROL E2
	 where E2.CRITERIANO=E1.CRITERIANO
	 and   E2.EVENTNO=ER.EVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - EVENTCONTROL rows deleted '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update EVENTSREPLACED
	set EVENTNO=isnull((select E1.EVENTNO from EVENTSREPLACED E1 where E1.OLDEVENTNO=ER.EVENTNO), EVENTNO)
	from #TEMPOLDEVENTS T
	join EVENTSREPLACED ER on (ER.EVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - EVENTSREPLACED rows updated '+CONVERT(CHAR(10), @RowCount)
End


If @ErrorCode=0
Begin
	
	Set @sSQLString="
	update POLICING
	set EVENTNO=ER.EVENTNO
	from POLICING E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - POLICING rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update ALERT
	set EVENTNO=ER.EVENTNO
	from ALERT E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - ALERT EventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update ALERT
	set TRIGGEREVENTNO=ER.EVENTNO
	from ALERT E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.TRIGGEREVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - ALERT TriggerEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update B2BTASKEVENT
	set EVENTNO=ER.EVENTNO
	from B2BTASKEVENT E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - B2BTASKEVENT EventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update B2BTASKEVENT
	set RETROEVENTNO=ER.EVENTNO
	from B2BTASKEVENT E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.RETROEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - B2BTASKEVENT RetroEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update CASERELATION
	set EVENTNO=ER.EVENTNO
	from CASERELATION E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CASERELATION EventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update CASERELATION
	set DISPLAYEVENTNO=ER.EVENTNO
	from CASERELATION E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.DISPLAYEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CASERELATION DisplayEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update CASERELATION
	set FROMEVENTNO=ER.EVENTNO
	from CASERELATION E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.FROMEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CASERELATION FromEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update CPAEVENTCODE
	set CASEEVENTNO=ER.EVENTNO
	from CPAEVENTCODE E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.CASEEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CPAEVENTCODE rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update CPANARRATIVE
	set CASEEVENTNO=ER.EVENTNO
	from CPANARRATIVE E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.CASEEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - CPANARRATIVE rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update EVENTUPDATEPROFILE
	set EVENT1NO=ER.EVENTNO
	from EVENTUPDATEPROFILE E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENT1NO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - EVENTUPDATEPROFILE Event1No rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update EVENTUPDATEPROFILE
	set EVENT2NO=ER.EVENTNO
	from EVENTUPDATEPROFILE E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENT2NO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - EVENTUPDATEPROFILE Event2No rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update IMPORTCONTROL
	set EVENTNO=ER.EVENTNO
	from IMPORTCONTROL E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - IMPORTCONTROL rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update IMPORTJOURNAL
	set ERROREVENTNO=ER.EVENTNO
	from IMPORTJOURNAL E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.ERROREVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - IMPORTJOURNAL rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update INSTALMENT
	set EVENTNO=ER.EVENTNO
	from INSTALMENT E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - INSTALMENT rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update NUMBERTYPES
	set RELATEDEVENTNO=ER.EVENTNO
	from NUMBERTYPES E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.RELATEDEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - NUMBERTYPES rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update POLICINGERRORS
	set EVENTNO=ER.EVENTNO
	from POLICINGERRORS E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.EVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - POLICINGERRORS rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update C
	set QUALIFIER=ER.EVENTNO
	from #TEMPOLDEVENTS T
	join QUERYCOLUMN C      on (T.OLDEVENTNO= CASE WHEN(dbo.fn_IsInteger(C.QUALIFIER)=1) THEN cast(C.QUALIFIER as int) END)
	join QUERYDATAITEM D	on (D.DATAITEMID=C.DATAITEMID
				and D.QUALIFIERTYPE=4)	-- Indicates Qualifier is an EVENTNO
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	where isnumeric(C.QUALIFIER)=1"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - QUERYCOLUMN rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDACTDATES
	set ACTEVENTNO=ER.EVENTNO
	from VALIDACTDATES E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.ACTEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - VALIDACTDATES ActEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDACTDATES
	set RETROEVENTNO=ER.EVENTNO
	from VALIDACTDATES E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.RETROEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - VALIDACTDATES RetroEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDACTION
	set ACTEVENTNO=ER.EVENTNO
	from VALIDACTION E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPACTIONS A  on (A.ACTION=E1.ACTION)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.ACTEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - VALIDACTION ActEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDACTION
	set RETROEVENTNO=ER.EVENTNO
	from VALIDACTION E1"
	
	If @pbCheckBlockingRules=1
	or @psRestrictToActions is not null
		Set @sSQLString=@sSQLString+CHAR(10)+
		"	join #TEMPACTIONS A  on (A.ACTION=E1.ACTION)"
	
	Set @sSQLString=@sSQLString+"
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.RETROEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - VALIDACTION RetroEventNo rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	update VALIDCATEGORY
	set PROPERTYEVENTNO=ER.EVENTNO
	from VALIDCATEGORY E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.PROPERTYEVENTNO)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - VALIDCATEGORY rows updated '+CONVERT(CHAR(10), @RowCount)
End

If @ErrorCode = 0
Begin Try
	Set @sSQLString="
	DELETE EVENTS
	from EVENTS E1
	join #TEMPOLDEVENTS T		on (T.OLDEVENTNO=E1.EVENTNO)
	left join EVENTCONTROL EC	on (EC.EVENTNO=E1.EVENTNO)
	Where EC.EVENTNO is null"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount >0 
	and @ErrorCode=0
	and @pbPrintLog=1
		SELECT 'Event Consolidation - EVENTS rows deleted '+CONVERT(CHAR(10), @RowCount)

End Try
Begin Catch
	if @@Error = 547
	Begin
		Set @ErrorCode=0
		
		If @pbPrintLog=1
		Begin
			If @pbCheckBlockingRules=1
				Select 'Event Consolidation - EVENT(s) being consolidated not deleted as still being referenced due to blocking rules being considered.'	
			else
				Select 'Event Consolidation - EVENT(s) being consolidated not deleted as still being referenced because consolidation restricted to specific Actions.'
		End		
	End
	Else Begin
		Declare @ErrorMessage	nvarchar(4000)
		Declare @ErrorSeverity	int
		Declare @ErrorState	int

		Select	@ErrorMessage	= ERROR_MESSAGE(),
			@ErrorSeverity	= ERROR_SEVERITY()   
		
		RAISERROR (@ErrorMessage,@ErrorSeverity,1)
	End
End Catch


If @ErrorCode=0
Begin
	Set @sSQLString="
	update SITECONTROL
	set COLINTEGER=ER.EVENTNO
	From SITECONTROL E1
	join #TEMPOLDEVENTS T	on (T.OLDEVENTNO=E1.COLINTEGER)
	join EVENTSREPLACED ER	on (ER.OLDEVENTNO=T.OLDEVENTNO)
	Where E1.CONTROLID in (
		'Abandoned Event',
		'Adjust Next G Event',
		'Adjustment F Event',
		'Adjustment K Event',
		'BulkRenAbandonEvent',
		'BulkRenDueEvent',
		'BulkRenRenewEvent',
		'CPA D 15',
		'CPA Date-Acceptance',
		'CPA Date-Affidavit',
		'CPA Date-Assoc Des',
		'CPA Date-Expiry',
		'CPA Date-Filing',
		'CPA Date-Intent Use',
		'CPA Date-Nominal',
		'CPA Date-Parent',
		'CPA Date-PCT Filing',
		'CPA Date-Priority',
		'CPA Date-Publication',
		'CPA Date-Quin Tax',
		'CPA Date-Registratn',
		'CPA Date-Renewal',
		'CPA Date-Start',
		'CPA Date-Stop',
		'CPA Modify Case',
		'CPA P 15',
		'CPA PD 13',
		'CPA PD 14',
		'CPA PD 16',
		'CPA PD 17',
		'CPA PD 18',
		'CPA PD 27',
		'CPA PD 28',
		'CPA PD 49',
		'CPA PD 50',
		'CPA Received Event',
		'CPA Rejected Event',
		'CPA Sent Event',
		'CPA TM 13',
		'CPA TM 14',
		'CPA TM 15',
		'CPA TM 16',
		'CPA TM 17',
		'CPA TM 18',
		'CPA TM 28',
		'CPA TM 29',
		'CPA-CEF Case Lapse',
		'CPA-CEF Event',
		'CPA-CEF Expiry',
		'CPA-CEF Next Renewal',
		'CPA-CEF Renewal',
		'IPOfficeDivDateEvent',
		'Reciprocity Event')"

	Exec @ErrorCode=sp_executesql @sSQLString
	
	Set @RowCount =@@Rowcount

	If  @RowCount>0 
	and @pbPrintLog=1
		SELECT 'Event Consolidation - SITECONTROL rows updated '+CONVERT(CHAR(10), @RowCount)
End

-- Commit the transaction if it has successfully completed

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
	Begin
		COMMIT TRANSACTION
		If @pbPrintLog=1
			Print '*** SUCCESS ***** Event Consolidation completed successfully ****'
	End
	Else Begin
		ROLLBACK TRANSACTION
		If @pbPrintLog=1
			If @ErrorCode=-1
				Print '*** FAILURE ***** Event Consolidation failed - no eligible rows to consolidate found ****'
			Else
				Print '*** FAILURE ***** Event Consolidation failed - transaction rolled back ****'
	End
End

If @pbCalledFromCentura = 1
Begin 
        Select @ErrorCode
End

Return @ErrorCode
GO

Grant execute on dbo.ev_EventConsolidation to public
GO
