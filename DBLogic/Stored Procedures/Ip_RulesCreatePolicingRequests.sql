-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Ip_RulesCreatePolicingRequests
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[Ip_RulesCreatePolicingRequests]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.Ip_RulesCreatePolicingRequests.'
	drop procedure dbo.Ip_RulesCreatePolicingRequests
end
print '**** Creating procedure dbo.Ip_RulesCreatePolicingRequests...'
print ''
go


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF
GO

		    
create proc dbo.Ip_RulesCreatePolicingRequests
		@pnRowCount		int 		= 0	OUTPUT,
		@pnTransNo		int		= null	 -- Transaction number used in updates of rules
as
-- PROCEDURE :	Ip_RulesCreatePolicingRequests
-- VERSION :	14
-- DESCRIPTION:	Create policing requests for the countries/case property types being affected by the 
--		law changes.  
--		This SP is based on ip_RulesImportReport.		  
--
-- MODIFICATIONS :
-- Date		Who	Change	    Version	Description
-- -----------	-------	------	    -------	----------------------------------------------- 
-- 22 Jan 2008	DL	SQA14297	1	Procedure Created
-- 25 Mar 2008	MF	SQA14297	2	Determine rules that have changed by checking the 
--						Transaction Number used in update.
-- 17 Feb 2009	MF	SQA17402	3	Policing rows are to set the RECALCEVENTDATE flag
--						on. This will cause Policing to clear out certain
--						events that have already occurred so they will
--						recalculate.
-- 10 Sep 2009	MF	SQA18026	4	When determining if any Cases exist that require a
--						recalculation, only match on the columns that have 
--						a value to be used in the Policing Request as no
--						value means that the column is not to be considered.
-- 18 Nov 2009	MF	SQA18246	5	Correct flag values on Policing rows.
-- 15 Jan 2010	MF	SQA18150	5	Status changes within the Law Update Sevice will not 
--						be updated on existing rules.
-- 02 Jun 2010	MF	SQA18792	6	SQL Error because of missing comma
-- 18 May 2011	MF	SQA17652	7	Check if there are any Events that are to be saved into 
--						a mapped Event prior to the law update generating requests
--						for Policing to be recalculated.
-- 24 Nov 2011	MF	R11612		8	Policing request must also have the DueDateFlag set on to
--						ensure the Standing Instructions for Cases are considered.
-- 05 Jan 2011	MF	R11616		9	Allow a Site Control to default the Scheduled Time for Policing to run.
-- 28 Aug 2012	MF	R12666		10	Error inserting snapshot CASEEVENT when Event belongs to more than one Action of 
--						different cycles.  Will use CREATEDBYACTION in preference.
-- 05 Sep 2012	MF	R12666		11	Revisited to handle the situation where Renewal dates are calculated by ~2 Action
--						but the Action is controlled by the RN Action.
-- 29 May 2015	MF	R48057		12	Only Actions delivered by CPA (first character is ~ ) will generate Policing.
-- 18 May 2016	MF	R61792		13	Policing rows that will be left on hold must now use ONHOLDFLAG=9.
-- 24 Oct 2017	AK	R72645	        14	Make compatible with case sensitive server with case insensitive database.

-- SETTINGS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


Create Table #TEMPRULECHANGE	(
		ROWID		int		identity(1,1),
		CASEOFFICEID	int						null,
		CASETYPE	nchar(1)	collate database_default	null,
		PROPERTYTYPE	nchar(1)	collate database_default	null,
		COUNTRYCODE	nvarchar(3)	collate database_default	null,
		CASECATEGORY	nvarchar(2)	collate database_default	null,
		SUBTYPE		nvarchar(2)	collate database_default	null,
		ACTION		nvarchar(2)	collate database_default	null
		)

Create Table #TEMPMAPPEDEVENTS(
		EVENTNO		int		not null,
		MAPPEDEVENTNO	int		not null
		)

declare @nTranCountStart 	int
declare	@ErrorCode		int
declare	@sSQLString		nvarchar(max)
declare	@sAction		nvarchar(3)
declare @sStartTime		nvarchar(5)
declare @sTime			nvarchar(12)
declare @sNow			nvarchar(12)
declare @sDateTime		nvarchar(23)


Set @ErrorCode=0
Set @pnRowCount=0

-- Load characteristics of the rules that have just been inserted/updated

If  @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRULECHANGE(CASEOFFICEID,CASETYPE,PROPERTYTYPE,COUNTRYCODE,CASECATEGORY,SUBTYPE,ACTION)

	select C.CASEOFFICEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE, C.ACTION
	from ADJUSTMENT A
	join DUEDATECALC DD	on (DD.ADJUSTMENT=A.ADJUSTMENT)
	join CRITERIA C		on (C.CRITERIANO=DD.CRITERIANO)
	where A.LOGTRANSACTIONNO=@pnTransNo
	and C.RULEINUSE=1
	and C.ACTION like '~%'
	UNION
	select C.CASEOFFICEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE, C.ACTION
	from VALIDACTION VA
	join CRITERIA C		on (C.PURPOSECODE='E'
				and C.COUNTRYCODE=VA.COUNTRYCODE
				and C.PROPERTYTYPE=VA.PROPERTYTYPE
				and C.CASETYPE=VA.CASETYPE
				and C.ACTION=VA.ACTION)
	where VA.LOGTRANSACTIONNO=@pnTransNo
	and VA.ACTEVENTNO is not null
	and C.RULEINUSE=1
	and C.ACTION like '~%'
	UNION
	select C.CASEOFFICEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE, C.ACTION
	from VALIDACTDATES VA
	join CRITERIA C		on (C.PURPOSECODE='E'
				and C.COUNTRYCODE=VA.COUNTRYCODE
				and C.PROPERTYTYPE=VA.PROPERTYTYPE
				and C.DATEOFACT=VA.DATEOFACT
				and C.ACTION=isnull(VA.RETROSPECTIVEACTIO,C.ACTION))
	where VA.LOGTRANSACTIONNO=@pnTransNo
	and C.RULEINUSE=1
	and C.ACTION like '~%'
	UNION
	select C.CASEOFFICEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE, C.ACTION
	from CRITERIA C
	where C.LOGTRANSACTIONNO=@pnTransNo
	and C.ACTION like '~%'
	UNION
	select C.CASEOFFICEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE, C.ACTION
	from EVENTCONTROL EC
	join CRITERIA C		on (C.CRITERIANO=EC.CRITERIANO)
	where EC.LOGTRANSACTIONNO=@pnTransNo
	and C.RULEINUSE=1
	and C.ACTION like '~%'
	UNION
	select C.CASEOFFICEID, C.CASETYPE, C.PROPERTYTYPE, isnull(C.COUNTRYCODE,DD.COUNTRYCODE), C.CASECATEGORY, C.SUBTYPE, C.ACTION
	from DUEDATECALC DD
	join CRITERIA C		on (C.CRITERIANO=DD.CRITERIANO)
	where DD.LOGTRANSACTIONNO=@pnTransNo
	and C.RULEINUSE=1
	and C.ACTION like '~%'
	UNION
	select C.CASEOFFICEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE, C.ACTION
	from RELATEDEVENTS RE
	join CRITERIA C		on (C.CRITERIANO=RE.CRITERIANO)
	where RE.LOGTRANSACTIONNO=@pnTransNo
	and C.RULEINUSE=1
	and C.ACTION like '~%'
	UNION
	select C.CASEOFFICEID, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE, C.ACTION
	from REMINDERS R
	join CRITERIA C		on (C.CRITERIANO=R.CRITERIANO)
	where R.LOGTRANSACTIONNO=@pnTransNo
	and C.RULEINUSE=1
	and C.ACTION like '~%'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnTransNo	int',
					  @pnTransNo=@pnTransNo

	Set @pnRowCount=@@rowcount
End
--------------------------------------------------------
-- Now remove any row where a less specific rules exists
--------------------------------------------------------
If @ErrorCode=0
and @pnRowCount>0
Begin
	Set @sSQLString="
	Delete #TEMPRULECHANGE
	from #TEMPRULECHANGE T
	join (	select * from #TEMPRULECHANGE) T1
			on (isnull(T1.CASEOFFICEID,'')=isnull(T.CASEOFFICEID,'')
			and T1.ACTION        =T.ACTION
			and T1.CASETYPE      =T.CASETYPE
			and T1.PROPERTYTYPE  =T.PROPERTYTYPE
			and ((T1.COUNTRYCODE =T.COUNTRYCODE  and
			      T1.CASECATEGORY=T.CASECATEGORY and
			      T1.SUBTYPE      is null and T.SUBTYPE      is not null)
			 OR  (T1.COUNTRYCODE=T.COUNTRYCODE   and
			      T1.CASECATEGORY is null and T.CASECATEGORY is not null and
			      T1.SUBTYPE      is null and T.SUBTYPE      is null)
			 OR  (T1.COUNTRYCODE=T.COUNTRYCODE   and
			      T1.CASECATEGORY is null and T.CASECATEGORY is not null and
			      T1.SUBTYPE      is null and T.SUBTYPE      is not null)
			 OR  (T1.COUNTRYCODE  is null and T.COUNTRYCODE  is not null and
			      T1.CASECATEGORY is null and T.CASECATEGORY is not null and
			      T1.SUBTYPE      is null and T.SUBTYPE      is not null) ) )"

	exec @ErrorCode=sp_executesql @sSQLString

	Set @pnRowCount=@pnRowCount-@@rowcount
End

-----------------------------------------------------
-- Continue if there are Policing requests to process
-----------------------------------------------------
If  @ErrorCode =0
and @pnRowCount>0
Begin
	---------------------------------------------------------
	-- If Policing Requests are to be generated then check to
	-- see if there are any Events that require a snapshot to
	-- be taken of their current content prior to Policing
	-- running a recalculation.
	---------------------------------------------------------
	Set @sSQLString="
	insert into #TEMPMAPPEDEVENTS(EVENTNO, MAPPEDEVENTNO)
	select cast(rtrim(ltrim(substring(CONTROLID,22,8))) as int), COLINTEGER
	from SITECONTROL
	where CONTROLID like 'Law Update Save Event%'
	and isnumeric(rtrim(ltrim(substring(CONTROLID,22,8))))=1"

	exec @ErrorCode=sp_executesql @sSQLString

	Set @pnRowCount=@@rowcount

	If @ErrorCode=0
	Begin
		-- Start a new transaction
		Set @nTranCountStart = @@TranCount
		BEGIN TRANSACTION

		If @pnRowCount>0
		Begin
			---------------------------------------------------
			-- Delete any CASEEVENT rows that are to be used to 
			-- hold the Event snapshot
			--------------------------------------------------- 
			Set @sSQLString="
			delete CE
			from #TEMPMAPPEDEVENTS T
			join CASEEVENT CE on (CE.EVENTNO=T.MAPPEDEVENTNO)"

			exec @ErrorCode=sp_executesql @sSQLString
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sAction=COLCHARACTER
				from SITECONTROL
				where CONTROLID='Main Renewal Action'"

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@sAction	nvarchar(3)	OUTPUT',
							  @sAction	=@sAction	OUTPUT
			End

			If @ErrorCode=0
			Begin
				---------------------------------------------------
				-- Save the Events that have been mapped into a 
				-- snapshot event prior to Policing performing a
				-- recalculation. Always save as an Event Date.
				--------------------------------------------------- 
				-- NOTE
				-- Policing of these rows is not required because
				-- if they are included in any rules then they will
				-- be picked up in the Action recalculations that
				-- will be generated.
				--------------------------------------------------- 
				Set @sSQLString="
				Insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG, DATEDUESAVED)
				Select distinct CE.CASEID, M.MAPPEDEVENTNO, 1, isnull(CE.EVENTDATE, CE.EVENTDUEDATE), 1, 0
				From #TEMPRULECHANGE T
					-----------------------------------------
					-- Only consider the Cases that are to be
					-- recalculated due to the rule change.
					-----------------------------------------
				join CASES C		on ((C.OFFICEID    =T.CASEOFFICEID OR T.CASEOFFICEID is null)
							and (C.CASETYPE    =T.CASETYPE     OR T.CASETYPE     is null)
							and (C.PROPERTYTYPE=T.PROPERTYTYPE OR T.PROPERTYTYPE is null)
							and (C.COUNTRYCODE =T.COUNTRYCODE  OR T.COUNTRYCODE  is null)
							and (C.CASECATEGORY=T.CASECATEGORY OR T.CASECATEGORY is null)
							and (C.SUBTYPE     =T.SUBTYPE      OR T.SUBTYPE      is null) )
				join OPENACTION OA	 on (OA.CASEID=C.CASEID
							 and OA.CYCLE=(	select min(OA1.CYCLE)
									from OPENACTION OA1
									where OA1.CASEID=OA.CASEID
									and OA1.ACTION=OA.ACTION
									and OA1.POLICEEVENTS=1))
				join ACTIONS A		 on ( A.ACTION=OA.ACTION)
				join EVENTCONTROL EC	 on (EC.CRITERIANO=OA.CRITERIANO)
				join EVENTS E		 on (E.EVENTNO=EC.EVENTNO)
				join #TEMPMAPPEDEVENTS M on (M.EVENTNO=EC.EVENTNO)
				join STATUS SC		 on (SC.STATUSCODE=C.STATUSCODE)
				left join PROPERTY P	 on ( P.CASEID=C.CASEID)
				left join STATUS SR	 on (SR.STATUSCODE=P.RENEWALSTATUS)
				join CASEEVENT CE	 on (CE.CASEID =C.CASEID
							 and CE.EVENTNO=EC.EVENTNO
							 and CE.CYCLE  =CASE WHEN(EC.NUMCYCLESALLOWED=1)
										THEN 1
									     WHEN(A.NUMCYCLESALLOWED=1)
										THEN (	select min(CE1.CYCLE)
											from CASEEVENT CE1
											where CE1.CASEID=CE.CASEID
											and CE1.EVENTNO=CE.EVENTNO
											and CE1.OCCURREDFLAG=0)
										ELSE OA.CYCLE
									END)
				where OA.ACTION=CASE WHEN(CE.EVENTNO=-11) THEN @sAction ELSE coalesce(E.CONTROLLINGACTION, CE.CREATEDBYACTION, OA.ACTION) END
					---------------------------------------------
					-- Only save the  CASEEVENT row if the Status
					-- allows the Action to be policed.
					---------------------------------------------
				and    ((A.ACTIONTYPEFLAG  =0 and (SC.POLICEOTHERACTIONS=1 or SC.STATUSCODE is null))
				 or     (A.ACTIONTYPEFLAG  =2 and (SC.POLICEEXAM        =1 or SC.STATUSCODE is null))
				 or     (A.ACTIONTYPEFLAG  =1 and (SC.POLICERENEWALS    =1 or SC.STATUSCODE is null) 
							      and (SR.POLICERENEWALS    =1 or SR.STATUSCODE is null)))"

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@sAction	nvarchar(3)',
							  @sAction	=@sAction
			End
		End

		If @ErrorCode=0
		Begin
			------------------------------------------------------
			-- Check the SiteControl to determine if the scheduled
			-- date and time should be set for each Policing row
			-- to be inserted.  If a valid value is not found then
			-- leave the Policing rows on hold.
			------------------------------------------------------
			Set @sSQLString="
			Select @sStartTime=LTRIM(RTRIM(COLCHARACTER))
			from SITECONTROL S
			where S.CONTROLID='Law Update Policing Start Time'"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@sStartTime	nvarchar(5)	OUTPUT',
						  @sStartTime =	@sStartTime	OUTPUT

			If @ErrorCode=0
			Begin
				--------------------------------------------
				-- Check that a valid time has been provided
				--------------------------------------------
				If  isnumeric(substring(@sStartTime,1,2))=1	-- Hour as 24 hour clock in HH format with leading zero
				and isnumeric(substring(@sStartTime,4,2))=1	-- Minute with leading zero.
				and           substring(@sStartTime,3,1) =':'	-- Colon as Separator
				Begin
					Set @sTime=substring(@sStartTime,1,2)+':'+ substring(@sStartTime,4,2)+':00:000'

					--------------------------------------------------
					-- Get the current time + 5 Minutes to determine
					-- if the scheduled date will be today or tomorrow
					--------------------------------------------------
					Set @sNow=convert(varchar(23), DATEADD(MI,5,getdate()), 114)

					-------------------------------------------------
					-- If the current time + 5 Minutes is after the 
					-- required scheduled time then the scheduled day 
					-- will be set to tomorrow.
					-------------------------------------------------
					If @sNow>@sTime
						Set @sDateTime=substring(convert(varchar(23), DATEADD(dd,1,getdate()), 121),1,10) + ' ' + @sTime
					Else
						Set @sDateTime=substring(convert(varchar(23),              getdate() , 121),1,10) + ' ' + @sTime
				End
			End
		End

		If @ErrorCode=0
		Begin
			--------------------------------------------------------------
			-- Load the Policing requests as system generated requests
			-- with the On Hold Flag set on.
			--------------------------------------------------------------
			Set @sSQLString="
			insert into POLICING(	DATEENTERED, POLICINGSEQNO, POLICINGNAME, 
							CASEOFFICEID,CASETYPE,PROPERTYTYPE,COUNTRYCODE,CASECATEGORY,SUBTYPE,ACTION,SYSGENERATEDFLAG, ONHOLDFLAG, 
							TYPEOFREQUEST, CRITERIAFLAG, DUEDATEFLAG, RECALCEVENTDATE, CALCREMINDERFLAG, LETTERFLAG, SQLUSER, SCHEDULEDDATETIME)
			Select	distinct
				getdate(),
				ROWID,
				'Law recalc '+convert(varchar, getdate(), 120)+ ' ' + cast(T.ROWID as varchar(9)),
				T.CASEOFFICEID,
				T.CASETYPE,
				T.PROPERTYTYPE,
				T.COUNTRYCODE,
				T.CASECATEGORY,
				T.SUBTYPE,
				T.ACTION,
				1 as SYSGENERATEDFLAG,
				CASE WHEN(@sDateTime is null) THEN 9 ELSE 0 END as ONHOLDFLAG,
				4 as TYPEOFREQUEST, 
				1 as CRITERIAFLAG,
				1 as DUEDATEFLAG,
				1 as RECALCEVENTDATE,
				1 as CALCREMINDERFLAG, 
				1 as LETTERFLAG,
				SYSTEM_USER as SQLUSER,
				@sDateTime  as SCHEDULEDDATETIME
			From #TEMPRULECHANGE T
			join CASES C		on ((C.OFFICEID    =T.CASEOFFICEID OR T.CASEOFFICEID is null)		-- SQA18026
						and (C.CASETYPE    =T.CASETYPE     OR T.CASETYPE     is null)		-- SQA18026
						and (C.PROPERTYTYPE=T.PROPERTYTYPE OR T.PROPERTYTYPE is null)		-- SQA18026
						and (C.COUNTRYCODE =T.COUNTRYCODE  OR T.COUNTRYCODE  is null)		-- SQA18026
						and (C.CASECATEGORY=T.CASECATEGORY OR T.CASECATEGORY is null)		-- SQA18026
						and (C.SUBTYPE     =T.SUBTYPE      OR T.SUBTYPE      is null) )		-- SQA18026
			join OPENACTION OA	on (OA.CASEID=C.CASEID
						and OA.ACTION=T.ACTION)
			where OA.POLICEEVENTS=1"

			exec @ErrorCode=sp_executesql @sSQLString,
							N'@sDateTime	nvarchar(23)',
							  @sDateTime =	@sDateTime

			Set @pnRowCount=@@rowcount
		End

		-- Commit transaction if successful
		If @@TranCount > @nTranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
End

Return @ErrorCode
go

grant execute on dbo.Ip_RulesCreatePolicingRequests to public
go

