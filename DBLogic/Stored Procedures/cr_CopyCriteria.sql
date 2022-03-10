-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cr_CopyCriteria
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cr_CopyCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cr_CopyCriteria.'
	drop procedure dbo.cr_CopyCriteria
end
print '**** Creating procedure dbo.cr_CopyCriteria...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cr_CopyCriteria
(
	@pnUserIdentityId		int		= null,	
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnCriteriaNo			int,			-- mandatory Criteria to be copied
	@psIntoServer			nvarchar(50),		-- mandatory name of the database server into which Criteria details will be copied
	@psIntoDatabase			nvarchar(50),		-- mandatory name of the database into which Criteria details will be copied
	@pbCopyAllChildCriteria		bit		= 0,	-- flag to indicate that all of the child Criteria inherited from @pnCriteriaNo will be copied
	@pbGenerateNewNumbers		bit		= 0,	-- flag indicates that new internal numbers are to be generated for Criteria rows inserted 
	@pbGenerateNewEventNumbers	bit		= 0,	-- flag indicates that new internal numbers are to be generated for Events rows inserted.
	@pbReplaceExistingCriteria	bit		= 0,	-- flag indicates Criteria with the same characteristics as those being copied are to have their Rule In Use flag turned off
	@pbReplaceExistingCriteriaNo	bit		= 0	-- flag indicates Criteria with the exact same CRITERIANO is to be replaced.

)
AS
-- PROCEDURE :	cr_CopyCriteria
-- VERSION :	21
-- DESCRIPTION:	Copies the details of a Criteria from the current database into another database.
--
-- NOTES :	****** WHEN USING DISTRIBUTED SERVERS ******
--		@psIntoServer parameter allows the copy of data to a database ona different server.
--		There is SQLServer configuration required to allow for transactions to span servers.
--		1. Ensure Distributed Transaction Coordinator service is running on both servers.
--		2. Disable all MSDTC security on both servers.
--		3. Turn on random options on the linked server.
--		Following post explained step  http://stackoverflow.com/questions/7473508/unable-to-begin-a-distributed-transaction
--
--		*********************************************************************************************************************
-- CALLED BY :	DataAccess directly
-- COPYRIGHT:	Copyright 1993 - 2016 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 Nov 2010	MF	R9358	1	Procedure created
-- 14 Nov 2011	MF	R11549	2	Only copy columns that exist in both the sending and receiving database. This will
--					allow for the possibility of the databases not being at exactly the same version.
-- 15 Nov 2011	MF	R11549	3	Reinstated the BEGIN TRY CATCH code to trap deadlocks.
-- 23 Aug 2012	MF	R12652	4	Ensure DELIVERYMETHOD is copied before LETTER table rows.
-- 09 Jan 2013	MF	R13102	5	New EventNo not being generated on Criteria copy for Events that don't exist on the database being copied into.	
-- 18 May 2013	MF	R13504	6	Provide a new parameter, @pbReplaceExistingCriteriaNo, to force the use of the same CRITERIANO
--					from the source database into the receiving database (@psIntoDatabase).
-- 24 May 2013	MF	R13504	7	Extension to ensure transaction can span distributed servers.
-- 31 Jul 2013	MF	R13714	8	Exclude columns that are defined with the IDENTITY property
-- 02 Jul 2014	MF	R36739	9	The RELATEDEVENTNO on the NUMBERTYPES table was not being considered in the Events copy and resulted
--					in a referential integrity failure.
-- 05 Sep 2014	MF	R39158	10	Report any database level failures that occur other than deadlocks which are handled by CATCH RETRY.
--					Also get the APPLICATIONBASIS rows from the VALIDBASIS table irrespective of the CRITERIA reference.
-- 21 Jan 2015	MF	R43732	11	Allow the copying over of existing CriteriaNo but allow for the generation of new EventNos. This requires the
--					introduction of the additional parameter @pbGenerateNewEventNumbers to separately control whether new Events
--					can be generated.
-- 05 Feb 2015	MF	R44645	12	The copying of DETAILCONTROL hasn’t taken into account the possibility of having new events created 
--					to control the dim, hiding or display of Entries.
-- 20 Jul 2015	MF	R50116	12	Error when EVENTNO referenced by VALIDACTDATES does not exist in recipient database. 
-- 27 Jul 2015	MF	R49680	13	TID columns are excluded deliberately from the dynamically generated SQL for copying various tables.  It is 
--					possible to accidentally exclude other columns that may match the mask being used.  This change will improve
--					the code to safeguard against this.
-- 24 Mar 2016	MF	R58265	14	Extend the procedure to copy SCREENCONTROL, FIELDCONTROL, GROUPCONTROL and USERCONTROL if it is associated with
--					the Events & Entries criteria being copied. Also requires USERS and SECURITYGROUP as referenced tables.
-- 24 Mar 2016	MF	R59759	14	Extend the procedure to copy IMPORTANCE if it is associated with the Events & Entries criteria being copied.
-- 30 Mar 2016	MF	R57446	15	Duplicate key error on INSTRUCTIONLABEL table.
-- 05 Apr 2016	MF	R60115	16	Error when EVENTNO referenced by EVENTCONTROL.UPDATEFROMEVENT does not exist in recipient database.
-- 05 Apr 2016	MF	R60116	17	When replacing a Criteria it must have the same Purpose Code.  Throw an error if there is a mismatch.
-- 07 Apr 2016	MF	R60139	18	Copy any CHARGETYPE rows referenced by the EVENTCONTROL table as well as the Events referenced by CHARGETYPE.
-- 11 Apr 2016	MF	R60315	19	Ensure duplicate CHARGETYPEs are not attempted to be inserted into the target database.
-- 11 Apr 2016	MF	R60317	19	Check if there are Events that are candidates for Event Consolidation and throw and error if there are more than
--					one that are identical in EVENTDESCRIPTION, NUMCYCLESALLOWED, EVENTCODE, CONTROLLINGACTION and DEFINITION.
-- 11 Apr 2016	MF	R60317	20	Rework.
-- 23 Mar 2017	MF	61729	21	Cater for new ROLESCONTROL table that can be used to indicate who has access to an Entry.

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF
Set XACT_ABORT ON	-- RFC13504 This is critical to allow transactions to span different servers

-- NOTE : Temporary table for storing all Criteria in 
--        the tree. Cannot use a table variable as this 
--        would block the use of dyamic SQL.

Create table #TEMPCRITERIA 
		      (	DEPTH			smallint	not null,
			CRITERIANO		int		not null,
			NEWCRITERIANO		int		not null,
			MATCHINGCRITERIANO	int		null,
			SEQUENCENO		int		identity(1,1)
			)

Create table #TEMPEVENTS
		      (	EVENTNO			int		not null,
			NEWEVENTNO		int		null,
			COPYNOTREQUIRED		bit		default(0)
			)
		

declare @ErrorCode		int
declare	@TranCountStart 	int

declare	@nCriteriaNo		int
declare @nEventNo		int
declare	@nRetry			smallint
declare @nDepth			smallint
declare @nTotalRows		smallint
declare @nNewRows		smallint
declare @sSQLString		nvarchar(max)
declare @sIntoColumnList	varchar(4000)
declare @sFromColumnList	varchar(4000)
declare @sUpdateColumnList	varchar(4000)
declare @sTable			varchar(128)
declare	@bPurposeCodeMismatch	bit

------------------------------------
-- Variables for trapping any errors
-- raised during database update.
------------------------------------
declare @sErrorMessage		nvarchar(max)
declare @nErrorSeverity		int
declare @nErrorState		int

set @ErrorCode	=0
set @nDepth	=1
set @nTotalRows	=1
set @bPurposeCodeMismatch = 0

------------------------------
-- If new Criteria numbers are 
-- to be generated then also
-- allow new Event numbers to 
-- be generated
------------------------------
If @pbGenerateNewNumbers=1
	Set @pbGenerateNewEventNumbers=1

-----------------------------------------------
-- Enclose Server and Database name by brackets
-----------------------------------------------
set @psIntoServer  ='['+replace(replace(@psIntoServer,  '[',''),']','')+']'
set @psIntoDatabase='['+replace(replace(@psIntoDatabase,'[',''),']','')+']'

If @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPCRITERIA(DEPTH, CRITERIANO, NEWCRITERIANO) 
	Select @nDepth,CRITERIANO, CRITERIANO
	from CRITERIA
	where CRITERIANO=@pnCriteriaNo
	and RULEINUSE=1
	and PURPOSECODE='E'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nDepth		smallint,
					  @pnCriteriaNo		int',
					  @nDepth	=@nDepth,
					  @pnCriteriaNo	=@pnCriteriaNo

	set @nNewRows=@@rowcount
End

-------------------
-- Get the Criteria
-- to be copied
-------------------
While @nNewRows>0
and   @ErrorCode=0
and   @pbCopyAllChildCriteria=1
Begin
	Set @nDepth=@nDepth+1
	-----------------------------------
	-- Get all the child Criteria whose
	-- parents are at the depth level
	-- just inserted.
	-----------------------------------
	Set @sSQLString="
	insert into #TEMPCRITERIA(DEPTH, CRITERIANO, NEWCRITERIANO)
	select @nDepth, I.CRITERIANO, I.CRITERIANO
	from #TEMPCRITERIA C
	join INHERITS I	on (I.FROMCRITERIA=C.CRITERIANO)
	join CRITERIA U on (U.CRITERIANO  =I.CRITERIANO)
	left join #TEMPCRITERIA C1
			on (C1.CRITERIANO=I.CRITERIANO) 
	where C.DEPTH=@nDepth-1
	and   U.RULEINUSE=1
	and   U.PURPOSECODE='E'
	and C1.CRITERIANO is null"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nDepth	int',
				  @nDepth=@nDepth

	Set @nNewRows=@@Rowcount
	Set @nTotalRows=@nTotalRows+@nNewRows
End

--------------------------------
-- Validate that valid Critieria
-- to be copied have be found.=
--------------------------------
If  @ErrorCode = 0
and @nTotalRows= 0
Begin
	RAISERROR('No valid Criteria to copy have been found. Must be for Events & Enties and must be marked as In Use.', 14, 1)
	Set @ErrorCode = @@ERROR
End
-----------------------------------
-- If the existing CriteriaNo is
-- to be replaced then new numbers
-- are not allowed to be generated.
-----------------------------------
If  @pbReplaceExistingCriteriaNo=1
and @pbGenerateNewNumbers=1
Begin
	Set @pbGenerateNewNumbers=0
	
	------------------------------
	-- Now print a warning message
	------------------------------
	RAISERROR('The parameter @pbGenerateNewNumbers for Criteria has been turned off becaused @pbReplaceExistingCriteriaNo flag is on.', 0, 1)
End

---------------------------------
-- If replacing existing Criteria
-- ensure Criteria being replaced
-- match the PurposeCode of the
-- new criteria.
--------------------------------
If  @ErrorCode = 0
and @pbReplaceExistingCriteriaNo=1
Begin
	Set @sSQLString="
	Select @bPurposeCodeMismatch=1
	from #TEMPCRITERIA T
	join CRITERIA F on (F.CRITERIANO=T.CRITERIANO)
	join "+@psIntoServer+"."+@psIntoDatabase+".dbo."+"CRITERIA C on (C.CRITERIANO=T.CRITERIANO)
	where C.PURPOSECODE<>F.PURPOSECODE collate database_default"
	
	exec @ErrorCode=sp_executesql @sSQLString,
					N'@bPurposeCodeMismatch		bit		OUTPUT',
					  @bPurposeCodeMismatch=@bPurposeCodeMismatch	OUTPUT
	
	If @bPurposeCodeMismatch=1
	and @ErrorCode=0
	Begin
		If @pbCopyAllChildCriteria=1
			RAISERROR('Criteria or descendant criteria attempting to replace a Criteria that is not configured for Events & Entries. Consider running with @pbGenerateNewNumbers=1.', 14, 1)
		Else
			RAISERROR('Criteria is attempting to replace a Criteria that is not configured for Events & Entries. Consider running with @pbGenerateNewNumbers=1.', 14, 1)
			
		Set @ErrorCode = @@ERROR
	End
End

----------------------------------
-- Allocate new set of CriteriaNos
-- if required to do so
----------------------------------
Set @nRetry=3

While @nRetry>0
and @pbGenerateNewNumbers=1
and @ErrorCode=0
Begin
	BEGIN TRY
		---------------------------------------
		-- Reserve the CRITERIANO to be used in
		-- the database being copied into.
		---------------------------------------
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		Set @sSQLString="
		Update L
		Set INTERNALSEQUENCE=C.MAXCRITERIANO+@nTotalRows,
		    @nCriteriaNo    =C.MAXCRITERIANO
		From "+@psIntoServer+"."+@psIntoDatabase+".dbo."+"LASTINTERNALCODE L
		cross join (Select max(CRITERIANO) as MAXCRITERIANO from "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA) C
		where L.TABLENAME='CRITERIA'"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCriteriaNo		int	OUTPUT,
						  @nTotalRows		int',
						  @nCriteriaNo	=@nCriteriaNo	OUTPUT,
						  @nTotalRows	=@nTotalRows
					
		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End

		If @ErrorCode=0
		Begin
			---------------------------------
			-- Now allocate a new CriteriaNo
			-- for each Criteria being copied
			---------------------------------
			Set @sSQLString="
			Update #TEMPCRITERIA
			Set NEWCRITERIANO=@nCriteriaNo+SEQUENCENO"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCriteriaNo		int',
						  @nCriteriaNo=@nCriteriaNo
		End
		
		-- Terminate the WHILE loop
		Set @nRetry=-1
	END TRY	

	---------------------------------
	-- D E A D L O C K   V I C T I M   
	--       P R O C E S S I N G
	---------------------------------
	BEGIN CATCH
		------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
		------------------------------------------
		If ERROR_NUMBER()=1205
			Set @nRetry=@nRetry-1
		Else
			Set @nRetry=-1
			
		-- Wait 1 second before attempting to
		-- retry the update.
		If @nRetry>0
			WAITFOR DELAY '00:00:01'
		Else
			Set @ErrorCode=ERROR_NUMBER()
			
		If XACT_STATE()<>0
			Rollback Transaction
		
		If @nRetry<1
		Begin
			-- Get error details to propagate to the caller
			Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
				@nErrorSeverity = ERROR_SEVERITY(),
				@nErrorState    = ERROR_STATE(),
				@ErrorCode     = ERROR_NUMBER()

			-- Use RAISERROR inside the CATCH block to return error
			-- information about the original error that caused
			-- execution to jump to the CATCH block.
			RAISERROR ( @sErrorMessage,	-- Message text.
				    @nErrorSeverity,	-- Severity.
				    @nErrorState	-- State.
				   )
		End
	END CATCH
End -- WHILE loop


----------------------------------
-- Load every EVENTNO that will 
-- be referenced in the rules to
-- be copied.
----------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPEVENTS(EVENTNO)
	SELECT EC.EVENTNO
	FROM #TEMPCRITERIA C
	JOIN EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO)
	union
	SELECT EC.UPDATEFROMEVENT
	FROM #TEMPCRITERIA C
	JOIN EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO)
	Where EC.UPDATEFROMEVENT is not null
	union
	SELECT E.EVENTNO
	FROM #TEMPCRITERIA C
	JOIN EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO)
	JOIN CHARGETYPE CH	on (CH.CHARGETYPENO in (EC.INITIALFEE, EC.INITIALFEE2))
	JOIN EVENTS E		on (E.EVENTNO       in (CH.CHARGEDUEEVENT, CH.CHARGEINCURREDEVENT))
	union
	SELECT DD.FROMEVENT
	FROM #TEMPCRITERIA C
	JOIN DUEDATECALC DD	on (DD.CRITERIANO=C.CRITERIANO)
	Where DD.FROMEVENT is not null
	union
	SELECT DD.COMPAREEVENT
	FROM #TEMPCRITERIA C
	JOIN DUEDATECALC DD	on (DD.CRITERIANO=C.CRITERIANO)
	where DD.COMPAREEVENT is not null
	union
	SELECT RE.RELATEDEVENT
	FROM #TEMPCRITERIA C
	JOIN RELATEDEVENTS RE	on (RE.CRITERIANO=C.CRITERIANO)
	where RE.RELATEDEVENT is not null
	union
	SELECT DL.COMPAREEVENT
	FROM #TEMPCRITERIA C
	JOIN DATESLOGIC DL	on (DL.CRITERIANO=C.CRITERIANO)
	where DL.COMPAREEVENT is not null
	union
	SELECT DD.EVENTNO
	FROM #TEMPCRITERIA C
	JOIN DETAILDATES DD	on (DD.CRITERIANO=C.CRITERIANO)
	union
	SELECT DD.OTHEREVENTNO
	FROM #TEMPCRITERIA C
	JOIN DETAILDATES DD	on (DD.CRITERIANO=C.CRITERIANO)
	where DD.OTHEREVENTNO is not null
	union
	SELECT N.RELATEDEVENTNO
	FROM NUMBERTYPES N
	where N.RELATEDEVENTNO is not null
	union
	Select V.ACTEVENTNO
	from VALIDACTDATES V
	where V.ACTEVENTNO is not null
	union
	Select V.RETROEVENTNO
	from VALIDACTDATES V
	where V.RETROEVENTNO is not null"

	exec @ErrorCode=sp_executesql @sSQLString
End

----------------------------------
-- Load the DRAFTEVENTNO that is 
-- associated with any of the
-- Event to be copied.
----------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Insert into #TEMPEVENTS(EVENTNO)
	SELECT distinct E.DRAFTEVENTNO
	FROM #TEMPEVENTS T
	JOIN EVENTS E	on (E.EVENTNO=T.EVENTNO)
	LEFT JOIN #TEMPEVENTS T1 on (T1.EVENTNO=E.DRAFTEVENTNO)
	where E.DRAFTEVENTNO is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	Set @nTotalRows=@nTotalRows+@@rowcount
End

-------------------------------------------
-- RFC60317
-- Validate Events to be copied do not have
-- an identical equivalent based on the 
-- EventDescription, NumCyclesAllowed,
-- EventCode, ControllingAction and
-- Definition.
-------------------------------------------
If  @ErrorCode = 0
Begin
	Set @nTotalRows=0

	Set @sSQLString="
	select @nTotalRows=count(*)
	from #TEMPEVENTS T
	join EVENTS E on (E.EVENTNO=T.EVENTNO)
	group by E.EVENTDESCRIPTION,E.NUMCYCLESALLOWED,E.EVENTCODE,E.CONTROLLINGACTION,E.DEFINITION 
	having COUNT(*)>1"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nTotalRows		int	OUTPUT',
					  @nTotalRows=@nTotalRows	OUTPUT

	If  @ErrorCode=0
	and @nTotalRows>0
	Begin
		SELECT E2.EVENTNO, E2.EVENTDESCRIPTION,E2.NUMCYCLESALLOWED,E2.EVENTCODE,E2.CONTROLLINGACTION,E2.DEFINITION 
		from #TEMPEVENTS E1
		join EVENTS E2 on (E2.EVENTNO=E1.EVENTNO)
		join (	select E.EVENTDESCRIPTION,E.NUMCYCLESALLOWED,E.EVENTCODE,E.CONTROLLINGACTION,E.DEFINITION 
			from  #TEMPEVENTS T
			join EVENTS E on (E.EVENTNO=T.EVENTNO)
			group by E.EVENTDESCRIPTION,E.NUMCYCLESALLOWED,E.EVENTCODE,E.CONTROLLINGACTION,E.DEFINITION 
			having COUNT(*)>1 ) E3	on ( E3.EVENTDESCRIPTION =E2.EVENTDESCRIPTION
						and  E3.NUMCYCLESALLOWED =E2.NUMCYCLESALLOWED
						and((E3.EVENTCODE        =E2.EVENTCODE)         or (E3.EVENTCODE         is null and E2.EVENTCODE         is null))
						and((E3.DEFINITION       =E2.DEFINITION)        or (E3.DEFINITION        is null and E2.DEFINITION        is null))
						and((E3.CONTROLLINGACTION=E2.CONTROLLINGACTION) or (E3.CONTROLLINGACTION is null and E2.CONTROLLINGACTION is null)))
		order by E2.EVENTDESCRIPTION,E2.NUMCYCLESALLOWED,E2.EVENTCODE,E2.CONTROLLINGACTION,E2.DEFINITION , E2.EVENTNO
		
		RAISERROR('More than one Event being copied have identical EVENTDESCRIPTION, NUMCYCLESALLOWED, EVENTCODE, CONTROLLINGACTION and DEFINITION but different EventNos. Consider an Event Consolidation first or vary some detail between Events.', 14, 1)
		Set @ErrorCode = @@ERROR
	End
End

-------------------------------------
-- Get the NEWEVENTNO for EVENTS that 
-- already map to an existing EVENT 
-- on the IntoDatabase
-------------------------------------
If @ErrorCode=0
Begin	
	--------------------------------------------------------
	-- Initially map the identical Events including EVENTNO
	--------------------------------------------------------		
	Set @sSQLString="
	Update T
	Set COPYNOTREQUIRED=1,
	    NEWEVENTNO=N.EVENTNO
	from #TEMPEVENTS T
	join EVENTS E	on (E.EVENTNO=T.EVENTNO)
	join "+@psIntoServer+"."+@psIntoDatabase+".dbo."+"EVENTS N 
			on (N.EVENTNO          =E.EVENTNO
			and N.EVENTDESCRIPTION =E.EVENTDESCRIPTION  collate database_default
			and N.NUMCYCLESALLOWED =E.NUMCYCLESALLOWED
			and(N.EVENTCODE        =E.EVENTCODE         collate database_default or (N.EVENTCODE         is NULL and E.EVENTCODE         is null))
			and(N.CONTROLLINGACTION=E.CONTROLLINGACTION collate database_default or (N.CONTROLLINGACTION is NULL and E.CONTROLLINGACTION is null))
			and(N.DEFINITION       =E.DEFINITION        collate database_default or (N.DEFINITION        is NULL and E.DEFINITION        is null)) )"

	exec @ErrorCode=sp_executesql @sSQLString			
End

If @ErrorCode=0
Begin
	--------------------------------------------------------
	-- Now map the identical Events but not on EVENTNO
	--------------------------------------------------------
	Set @sSQLString="
	Update T
	Set COPYNOTREQUIRED=1,
	    NEWEVENTNO=N.EVENTNO
	from #TEMPEVENTS T
	join EVENTS E	on (E.EVENTNO=T.EVENTNO)
	join "+@psIntoServer+"."+@psIntoDatabase+".dbo."+"EVENTS N 
			on (N.EVENTDESCRIPTION =E.EVENTDESCRIPTION  collate database_default
			and N.NUMCYCLESALLOWED =E.NUMCYCLESALLOWED
			and(N.EVENTCODE        =E.EVENTCODE         collate database_default or (N.EVENTCODE         is NULL and E.EVENTCODE         is null))
			and(N.CONTROLLINGACTION=E.CONTROLLINGACTION collate database_default or (N.CONTROLLINGACTION is NULL and E.CONTROLLINGACTION is null))
			and(N.DEFINITION       =E.DEFINITION        collate database_default or (N.DEFINITION        is NULL and E.DEFINITION        is null)) )
	where T.NEWEVENTNO is null"

	exec @ErrorCode=sp_executesql @sSQLString			
End

If  @ErrorCode=0
Begin
	If @pbGenerateNewEventNumbers=1
	Begin
		-----------------------------
		-- Count how many EVENT rows
		-- are required to have a new
		-- EventNo allocated
		-----------------------------
		Set @nTotalRows=0

		Set @sSQLString="
		Select @nTotalRows=count(*)
		from #TEMPEVENTS
		where COPYNOTREQUIRED=0"

		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nTotalRows		int	OUTPUT',
					  @nTotalRows=@nTotalRows	OUTPUT
	End
	Else Begin
		-------------------------------
		-- Events that don't already
		-- have a matching event should
		-- use the same EventNo from the
		-- source database if the 
		-- @@pbGenerateNewEventNumbers flag
		-- is off and the EVENTNO is
		-- not already in use in the
		-- target database.
		-------------------------------
		Set @sSQLString="
		Update T
		set NEWEVENTNO=T.EVENTNO
		from #TEMPEVENTS T
		left join  "+@psIntoServer+"."+@psIntoDatabase+".dbo.EVENTS E on (E.EVENTNO=T.EVENTNO)
		where T.NEWEVENTNO is null
		and   E.EVENTNO    is null"

		Exec @ErrorCode=sp_executesql @sSQLString
		
		Set @nTotalRows=@@ROWCOUNT
	End
End

----------------------------------
-- Allocate new set of EVENTNOs
-- if required to do so
----------------------------------
Set @nRetry=3

While @nRetry>0
and @nTotalRows>0
and @ErrorCode=0 
Begin
	BEGIN TRY
		------------------------------------
		-- Reserve the EVENTNO to be used in
		-- the database being copied into.
		------------------------------------
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		If @pbGenerateNewEventNumbers=1
		Begin
			Set @sSQLString="
			Update L
			Set INTERNALSEQUENCE=E.MAXEVENTNO+@nTotalRows,
			    @nEventNo       =E.MAXEVENTNO
			from  "+@psIntoServer+"."+@psIntoDatabase+".dbo.LASTINTERNALCODE L
			cross join (Select max(EVENTNO) as MAXEVENTNO from "+@psIntoServer+"."+@psIntoDatabase+".dbo.EVENTS) E
			where L.TABLENAME='EVENTS'"

			exec @ErrorCode=sp_executesql @sSQLString,
							N'@nEventNo		int	OUTPUT,
							  @nTotalRows		int',
							  @nEventNo	=@nEventNo	OUTPUT,
							  @nTotalRows	=@nTotalRows
		End
		Else Begin
			Set @sSQLString="   
			Update L
			Set INTERNALSEQUENCE= CASE WHEN(T.MAXEVENTNO>=E.MAXEVENTNO) THEN T.MAXEVENTNO ELSE E.MAXEVENTNO END
			from  "+@psIntoServer+"."+@psIntoDatabase+".dbo.LASTINTERNALCODE L
			cross join (Select max(EVENTNO)    as MAXEVENTNO from "+@psIntoServer+"."+@psIntoDatabase+".dbo.EVENTS) E
			cross join (Select max(NEWEVENTNO) as MAXEVENTNO from #TEMPEVENTS) T
			where L.TABLENAME='EVENTS'"

			exec @ErrorCode=sp_executesql @sSQLString
		End
					
		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End

		If  @ErrorCode=0
		and @pbGenerateNewEventNumbers=1
		Begin
			------------------------------
			-- Now allocate a new EventNo
			-- for each Event being copied
			------------------------------
			Set @sSQLString="
			Update #TEMPEVENTS
			Set @nEventNo =@nEventNo+1,
			    NEWEVENTNO=@nEventNo
			where NEWEVENTNO is null"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nEventNo		int	OUTPUT',
						  @nEventNo=@nEventNo		OUTPUT
		End
		
		-- Terminate the WHILE loop
		Set @nRetry=-1
	END TRY	

	---------------------------------
	-- D E A D L O C K   V I C T I M   
	--       P R O C E S S I N G
	---------------------------------
	BEGIN CATCH
		------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
		------------------------------------------
		If ERROR_NUMBER()=1205
			Set @nRetry=@nRetry-1
		Else
			Set @nRetry=-1
			
		-- Wait 1 second before attempting to
		-- retry the update.
		If @nRetry>0
			WAITFOR DELAY '00:00:01'
		Else
			Set @ErrorCode=ERROR_NUMBER()
			
		If XACT_STATE()<>0
			Rollback Transaction
		
		If @nRetry<1
		Begin
			-- Get error details to propagate to the caller
			Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
				@nErrorSeverity = ERROR_SEVERITY(),
				@nErrorState    = ERROR_STATE(),
				@ErrorCode     = ERROR_NUMBER()

			-- Use RAISERROR inside the CATCH block to return error
			-- information about the original error that caused
			-- execution to jump to the CATCH block.
			RAISERROR ( @sErrorMessage,	-- Message text.
				    @nErrorSeverity,	-- Severity.
				    @nErrorState	-- State.
				   )
		End
	END CATCH
End -- WHILE loop

--------------------------------
-- D A T A   V A L I D A T I O N
--------------------------------

--------------------------------
-- Validate Events to be copied
-- do not clash with existing
-- Events.
--------------------------------
If  @ErrorCode = 0
and isnull(@pbReplaceExistingCriteriaNo,0)=0
Begin
	Set @nTotalRows=0

	Set @sSQLString="
	select @nTotalRows=count(*)
	from #TEMPEVENTS T
	join "+@psIntoServer+"."+@psIntoDatabase+".dbo.EVENTS E
			on (E.EVENTNO=T.EVENTNO)
	where T.NEWEVENTNO is null"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nTotalRows		int	OUTPUT',
					  @nTotalRows=@nTotalRows	OUTPUT

	If  @ErrorCode=0
	and @nTotalRows>0
	Begin
		RAISERROR('EventNos to be copied clash with EventNo on destination database. Consider setting parameter @@pbGenerateNewEventNumbers=1', 14, 1)
		Set @ErrorCode = @@ERROR
	End
End

---------------------------------
-- Validate Criteria to be copied
-- do not clash with existing
-- Criteria.
---------------------------------
If  @ErrorCode = 0
and isnull(@pbReplaceExistingCriteriaNo,0)=0
Begin
	Set @nTotalRows=0

	Set @sSQLString="
	select @nTotalRows=count(*)
	from #TEMPCRITERIA T
	join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA C
			on (C.CRITERIANO=T.NEWCRITERIANO)"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nTotalRows		int	OUTPUT',
					  @nTotalRows=@nTotalRows	OUTPUT

	If  @ErrorCode=0
	and @nTotalRows>0
	Begin
		RAISERROR('CriteriaNos to be copied clash with CriteriaNo on destination database. Consider setting parameter @pbReplaceExistingCriteriaNo=1 OR @pbGenerateNewNumbers=1', 14, 1)
		Set @ErrorCode = @@ERROR
	End
End

-------------------------------------
-- Validate Criteria to be copied do
-- not clash with the characteristics
-- of destination Criteria.
-------------------------------------
If @ErrorCode = 0
Begin
	Set @nTotalRows=0

	Set @sSQLString="
	Update X
	Set MATCHINGCRITERIANO=C.CRITERIANO
	from #TEMPCRITERIA X
	join CRITERIA T on (T.CRITERIANO=X.CRITERIANO)
	join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA C
			on (C.PURPOSECODE     =T.PURPOSECODE	 collate database_default
			and C.RULEINUSE       =1
			and(C.CASETYPE        =T.CASETYPE        collate database_default or (C.CASETYPE         is null and T.CASETYPE         is null))
			and(C.ACTION          =T.ACTION          collate database_default or (C.ACTION           is null and T.ACTION           is null))
			and(C.CHECKLISTTYPE   =T.CHECKLISTTYPE                            or (C.CHECKLISTTYPE    is null and T.CHECKLISTTYPE    is null))
			and(C.PROGRAMID       =T.PROGRAMID       collate database_default or (C.PROGRAMID        is null and T.PROGRAMID        is null))
			and(C.PROPERTYTYPE    =T.PROPERTYTYPE    collate database_default or (C.PROPERTYTYPE     is null and T.PROPERTYTYPE     is null))
			and(C.COUNTRYCODE     =T.COUNTRYCODE     collate database_default or (C.COUNTRYCODE      is null and T.COUNTRYCODE      is null))
			and(C.CASECATEGORY    =T.CASECATEGORY    collate database_default or (C.CASECATEGORY     is null and T.CASECATEGORY     is null))
			and(C.SUBTYPE         =T.SUBTYPE         collate database_default or (C.SUBTYPE          is null and T.SUBTYPE          is null))
			and(C.BASIS           =T.BASIS           collate database_default or (C.BASIS            is null and T.BASIS            is null))
			and(C.REGISTEREDUSERS =T.REGISTEREDUSERS collate database_default or (C.REGISTEREDUSERS  is null and T.REGISTEREDUSERS  is null))
			and(C.LOCALCLIENTFLAG =T.LOCALCLIENTFLAG                          or (C.LOCALCLIENTFLAG  is null and T.LOCALCLIENTFLAG  is null))
			and(C.TABLECODE       =T.TABLECODE                                or (C.TABLECODE        is null and T.TABLECODE        is null))
			and(C.RATENO          =T.RATENO                                   or (C.RATENO           is null and T.RATENO           is null))
			and(C.DATEOFACT       =T.DATEOFACT                                or (C.DATEOFACT        is null and T.DATEOFACT        is null))
			and(C.USERDEFINEDRULE =T.USERDEFINEDRULE                          or (C.USERDEFINEDRULE  is null and T.USERDEFINEDRULE  is null))
			and(C.TYPEOFMARK      =T.TYPEOFMARK                               or (C.TYPEOFMARK       is null and T.TYPEOFMARK       is null))
			and(C.RENEWALTYPE     =T.RENEWALTYPE                              or (C.RENEWALTYPE      is null and T.RENEWALTYPE      is null))
			and(C.CASEOFFICEID    =T.CASEOFFICEID                             or (C.CASEOFFICEID     is null and T.CASEOFFICEID     is null))
			and(C.DATAEXTRACTID   =T.DATAEXTRACTID                            or (C.DATAEXTRACTID    is null and T.DATAEXTRACTID    is null))
			and(C.RULETYPE        =T.RULETYPE                                 or (C.RULETYPE         is null and T.RULETYPE         is null))
			and(C.REQUESTTYPE     =T.REQUESTTYPE     collate database_default or (C.REQUESTTYPE      is null and T.REQUESTTYPE      is null))
			and(C.DATASOURCETYPE  =T.DATASOURCETYPE                           or (C.DATASOURCETYPE   is null and T.DATASOURCETYPE   is null))
			and(C.DATASOURCENAMENO=T.DATASOURCENAMENO                         or (C.DATASOURCENAMENO is null and T.DATASOURCENAMENO is null))
			and(C.RENEWALSTATUS   =T.RENEWALSTATUS                            or (C.RENEWALSTATUS    is null and T.RENEWALSTATUS    is null))
			and(C.STATUSCODE      =T.STATUSCODE                               or (C.STATUSCODE       is null and T.STATUSCODE       is null)) )
	Where (@pbReplaceExistingCriteriaNo=1 and T.CRITERIANO<>C.CRITERIANO)
	OR isnull(@pbReplaceExistingCriteriaNo,0)=0"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pbReplaceExistingCriteriaNo	bit',
					  @pbReplaceExistingCriteriaNo=@pbReplaceExistingCriteriaNo

	Set @nTotalRows=@@Rowcount

	If  @ErrorCode=0
	and @nTotalRows>0
	Begin
		If @pbReplaceExistingCriteriaNo=1
		Begin
			RAISERROR('Criteria to be copied have identical characteristics to a Criteria on the destination database but with a different CriteriaNo.', 14, 1)
		End
		Else If @pbReplaceExistingCriteria=0
		Begin
			RAISERROR('Criteria to be copied have identical characteristics to a Criteria on the destination database. Consider setting @pbReplaceExistingCriteria=1', 14, 1)
		End
		
		Set @ErrorCode = @@ERROR
	End		
End

----------------------------------
-- Copy all referenced tables as 
-- required to ensure a complete
-- criteria is copied to the 
-- destination database.
----------------------------------
-- Perform the entire copy as a 
-- single database transaction.
----------------------------------
Set @nRetry=3

While @nRetry>0
and @ErrorCode=0
Begin
	BEGIN TRY
		-------------------------------------------
		-- Start the TRANSACTION so all references
		-- from the Criteria are Committed together 
		-------------------------------------------
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		-----------------------------
		-- P R O P E R T Y T Y P E --
		-----------------------------
		Set @sTable ='PROPERTYTYPE'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.PROPERTYTYPE("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From PROPERTYTYPE F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.PROPERTYTYPE I 
						on (I.PROPERTYTYPE=F.PROPERTYTYPE collate database_default)
			JOIN (	SELECT C.PROPERTYTYPE
				FROM #TEMPCRITERIA T
				join CRITERIA C	on (C.CRITERIANO=T.CRITERIANO)
				WHERE C.PROPERTYTYPE is not null
				UNION
				SELECT PROPERTYTYPE
				FROM VALIDPROPERTY
				UNION
				SELECT VC.PROPERTYTYPE
				FROM #TEMPCRITERIA T
				JOIN CRITERIA C		on (C.CRITERIANO=T.CRITERIANO)
				JOIN VALIDCATEGORY VC	on (VC.CASETYPE=C.CASETYPE
							and VC.CASECATEGORY=C.CASECATEGORY)
				UNION
				SELECT VS.PROPERTYTYPE
				FROM #TEMPCRITERIA T
				JOIN CRITERIA C		on (C.CRITERIANO=T.CRITERIANO)
				JOIN VALIDSUBTYPE VS	on (VS.CASETYPE=C.CASETYPE
							and VS.CASECATEGORY=C.CASECATEGORY
							and VS.SUBTYPE=C.SUBTYPE) )  X on (X.PROPERTYTYPE=F.PROPERTYTYPE)
			where I.PROPERTYTYPE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------
		-- C O U N T R Y --
		-------------------
		Set @sTable ='COUNTRY'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.COUNTRY("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From COUNTRY F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.COUNTRY I 
						on (I.COUNTRYCODE=F.COUNTRYCODE collate database_default)
			JOIN (	SELECT C.COUNTRYCODE
				FROM #TEMPCRITERIA T
				join CRITERIA C	on (C.CRITERIANO=T.CRITERIANO)
				WHERE C.COUNTRYCODE is not null
				UNION
				SELECT COUNTRYCODE
				FROM COUNTRYTEXT
				UNION
				SELECT COUNTRYCODE
				FROM VALIDPROPERTY
				UNION
				SELECT COUNTRYCODE
				FROM VALIDACTDATES
				UNION
				SELECT COUNTRYCODE
				FROM VALIDACTION
				UNION
				SELECT COUNTRYCODE
				FROM VALIDATENUMBERS
				UNION
				SELECT COUNTRYCODE
				FROM VALIDBASIS
				UNION
				SELECT COUNTRYCODE
				FROM VALIDCATEGORY
				UNION
				SELECT COUNTRYCODE
				FROM VALIDRELATIONSHIPS
				UNION
				SELECT COUNTRYCODE
				FROM VALIDSTATUS
				UNION
				SELECT COUNTRYCODE
				FROM VALIDSUBTYPE)  X on (X.COUNTRYCODE=F.COUNTRYCODE)
			where I.COUNTRYCODE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------
		-- I M P O R T A N C E --
		-------------------------
		Set @sTable ='IMPORTANCE'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.IMPORTANCE("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From IMPORTANCE F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.IMPORTANCE I 
						on (I.IMPORTANCELEVEL=F.IMPORTANCELEVEL collate database_default)
			JOIN (	Select I.IMPORTANCELEVEL
				FROM #TEMPCRITERIA T
				JOIN EVENTCONTROL EC	on (EC.CRITERIANO=T.CRITERIANO)
				JOIN IMPORTANCE I	on (I.IMPORTANCELEVEL=EC.IMPORTANCELEVEL)
				UNION
				Select I.IMPORTANCELEVEL
				FROM #TEMPCRITERIA T
				JOIN EVENTCONTROL EC	on (EC.CRITERIANO=T.CRITERIANO)
				JOIN EVENTS E		on (E.EVENTNO=EC.EVENTNO)
				JOIN IMPORTANCE I	on (I.IMPORTANCELEVEL in (E.IMPORTANCELEVEL, E.CLIENTIMPLEVEL))
				UNION
				Select I.IMPORTANCELEVEL
				FROM #TEMPCRITERIA T
				JOIN DUEDATECALC DD	on (DD.CRITERIANO=T.CRITERIANO)
				JOIN EVENTS E		on (E.EVENTNO in (DD.FROMEVENT, DD.COMPAREEVENT))
				JOIN IMPORTANCE I	on (I.IMPORTANCELEVEL in (E.IMPORTANCELEVEL, E.CLIENTIMPLEVEL))
				UNION
				Select I.IMPORTANCELEVEL
				FROM #TEMPCRITERIA T
				JOIN RELATEDEVENTS RE	on (RE.CRITERIANO=T.CRITERIANO)
				JOIN EVENTS E		on (E.EVENTNO=RE.RELATEDEVENT)
				JOIN IMPORTANCE I	on (I.IMPORTANCELEVEL in (E.IMPORTANCELEVEL, E.CLIENTIMPLEVEL))
				UNION
				Select I.IMPORTANCELEVEL
				FROM #TEMPCRITERIA T
				JOIN CRITERIA C		on (C.CRITERIANO=T.CRITERIANO)
				JOIN ACTIONS A	 	on (A.ACTION=C.ACTION)
				JOIN IMPORTANCE I	on (I.IMPORTANCELEVEL=A.IMPORTANCELEVEL) )  X on (X.IMPORTANCELEVEL=F.IMPORTANCELEVEL)
			where I.IMPORTANCELEVEL is NULL"
			
			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------
		-- A C T I O N S --
		-------------------
		Set @sTable ='ACTIONS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.ACTIONS("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From ACTIONS F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.ACTIONS I 
						on (I.ACTION=F.ACTION collate database_default)
			JOIN (	SELECT C.ACTION
				FROM #TEMPCRITERIA T
				join CRITERIA C	on (C.CRITERIANO=T.CRITERIANO)
				WHERE C.ACTION is not null 
				UNION
				SELECT EC.CREATEACTION
				FROM #TEMPCRITERIA T
				join EVENTCONTROL EC on (EC.CRITERIANO=T.CRITERIANO)
				WHERE EC.CREATEACTION is not null 
				UNION
				SELECT EC.CLOSEACTION
				FROM #TEMPCRITERIA T
				join EVENTCONTROL EC on (EC.CRITERIANO=T.CRITERIANO)
				WHERE EC.CLOSEACTION is not null 
				UNION
				SELECT RETROSPECTIVEACTIO
				from VALIDACTDATES
				where RETROSPECTIVEACTIO is not null)  X on (X.ACTION=F.ACTION)
			where I.ACTION is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------
		-- C A S E T Y P E --
		---------------------
		Set @sTable ='CASETYPE'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.CASETYPE("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From CASETYPE F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CASETYPE I 
						on (I.CASETYPE=F.CASETYPE collate database_default)
			JOIN (	SELECT distinct C.CASETYPE
				FROM #TEMPCRITERIA T
				join CRITERIA C	on (C.CRITERIANO=T.CRITERIANO)
				WHERE C.CASETYPE is not null )  X on (X.CASETYPE=F.CASETYPE)
			where I.CASETYPE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------
		-- C A S E C A T E G O R Y --
		-----------------------------
		Set @sTable ='CASECATEGORY'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.CASECATEGORY("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From CASECATEGORY F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CASECATEGORY I 
						on (I.CASETYPE    =F.CASETYPE collate database_default
						and I.CASECATEGORY=F.CASECATEGORY collate database_default)
			JOIN (	SELECT distinct C.CASETYPE, C.CASECATEGORY
				FROM #TEMPCRITERIA T
				join CRITERIA C	on (C.CRITERIANO=T.CRITERIANO)
				WHERE C.CASETYPE is not null
				and   C.CASECATEGORY is not null )  X on (X.CASETYPE=F.CASETYPE
								      and X.CASECATEGORY=F.CASECATEGORY)
			where I.CASECATEGORY is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------
		-- S U B T Y P E --
		-------------------
		Set @sTable ='SUBTYPE'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.SUBTYPE("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From SUBTYPE F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.SUBTYPE I 
						on (I.SUBTYPE=F.SUBTYPE collate database_default)
			JOIN (	SELECT distinct C.SUBTYPE
				FROM #TEMPCRITERIA T
				join CRITERIA C	on (C.CRITERIANO=T.CRITERIANO)
				WHERE C.SUBTYPE is not null )  X on (X.SUBTYPE=F.SUBTYPE)
			where I.SUBTYPE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------------
		-- A P P L I C A T I O N B A S I S --
		-------------------------------------
		Set @sTable ='APPLICATIONBASIS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.APPLICATIONBASIS("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From APPLICATIONBASIS F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.APPLICATIONBASIS I 
						on (I.BASIS=F.BASIS collate database_default)
			JOIN (	SELECT distinct BASIS
				FROM VALIDBASIS )  X on (X.BASIS=F.BASIS)
			where I.BASIS is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------
		-- S T A T U S --
		-----------------
		Set @sTable ='STATUS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.STATUS("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From STATUS F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.STATUS I 
						on (I.STATUSCODE=F.STATUSCODE)
			JOIN (	SELECT EC.STATUSCODE
				FROM #TEMPCRITERIA T
				join EVENTCONTROL EC on (EC.CRITERIANO=T.CRITERIANO)
				WHERE EC.STATUSCODE is not null
				UNION
				SELECT DC.STATUSCODE
				FROM #TEMPCRITERIA T
				join DETAILCONTROL DC on (DC.CRITERIANO=T.CRITERIANO)
				WHERE DC.STATUSCODE is not null
				UNION
				SELECT DC.RENEWALSTATUS
				FROM #TEMPCRITERIA T
				join DETAILCONTROL DC on (DC.CRITERIANO=T.CRITERIANO)
				WHERE DC.RENEWALSTATUS is not null )  X on (X.STATUSCODE=F.STATUSCODE)
			where I.STATUSCODE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------
		-- C A S E R E L A T I O N --
		-----------------------------
		Set @sTable ='CASERELATION'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.CASERELATION("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From CASERELATION F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CASERELATION I 
						on (I.RELATIONSHIP=F.RELATIONSHIP collate database_default)
			JOIN (	Select CR.RELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN EVENTCONTROL EC	on (EC.CRITERIANO=T.CRITERIANO)
				JOIN CASERELATION CR	on (CR.RELATIONSHIP=EC.FROMRELATIONSHIP)
				UNION
				Select VR.RECIPRELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN EVENTCONTROL EC		on (EC.CRITERIANO=T.CRITERIANO)
				JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=EC.FROMRELATIONSHIP)
				Where VR.RECIPRELATIONSHIP is not null
				UNION
				Select CR.RELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN DUEDATECALC DD	on (DD.CRITERIANO=T.CRITERIANO)
				JOIN CASERELATION CR	on (CR.RELATIONSHIP=DD.COMPARERELATIONSHIP)
				UNION
				Select VR.RECIPRELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN DUEDATECALC DD		on (DD.CRITERIANO=T.CRITERIANO)
				JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=DD.COMPARERELATIONSHIP)
				WHERE VR.RECIPRELATIONSHIP is not null
				UNION
				Select CR.RELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN DATESLOGIC DL	on (DL.CRITERIANO=T.CRITERIANO)
				JOIN CASERELATION CR	on (CR.RELATIONSHIP=DL.CASERELATIONSHIP)
				UNION
				Select VR.RECIPRELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN DATESLOGIC DL		on (DL.CRITERIANO=T.CRITERIANO)
				JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=DL.CASERELATIONSHIP)
				WHERE VR.RECIPRELATIONSHIP is not null )  X on (X.RELATIONSHIP=F.RELATIONSHIP)
			where I.RELATIONSHIP is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------
		-- E V E N T S --
		-----------------
		Set @sTable ='EVENTS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME,
				@sUpdateColumnList=CASE WHEN(F.COLUMN_NAME<>'EVENTNO') THEN isnull(nullif(@sUpdateColumnList+',',','),'')     +F.COLUMN_NAME+'=F.'+F.COLUMN_NAME+CHAR(10)+CHAR(9)+CHAR(9)+CHAR(9) END
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sUpdateColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList  =@sIntoColumnList	OUTPUT,
						  @sFromColumnList  =@sFromColumnList	OUTPUT,
						  @sUpdateColumnList=@sUpdateColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If  @ErrorCode=0
		and @pbReplaceExistingCriteriaNo=1
		Begin
			----------------------------------------
			-- Update the attributes of the existing
			-- EVENTS row
			----------------------------------------
			Set @sSQLString="
			Update N
			Set "+@sUpdateColumnList+"
			From "+@psIntoServer+"."+@psIntoDatabase+".dbo.EVENTS N
			join #TEMPEVENTS T on (T.EVENTNO=N.EVENTNO)
			join (select * from EVENTS) F
						on (F.EVENTNO=N.EVENTNO)"
				
			exec @ErrorCode=sp_executesql @sSQLString
		End

		If @ErrorCode=0
		Begin
			----------------------
			-- Need to cater for
			-- regenerated EventNo
			----------------------
			set @sFromColumnList=replace(@sFromColumnList,'F.EVENTNO','T.NEWEVENTNO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.EVENTS("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From #TEMPEVENTS T
			join EVENTS F	on (F.EVENTNO=T.EVENTNO)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.EVENTS I 
					on (I.EVENTNO=T.NEWEVENTNO)
			where I.EVENTNO  is NULL
			and T.NEWEVENTNO is not NULL
			and T.COPYNOTREQUIRED=0"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------
		-- A D J U S T M E N T --
		-------------------------
		Set @sTable ='ADJUSTMENT'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.ADJUSTMENT("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From ADJUSTMENT F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.ADJUSTMENT I 
						on (I.ADJUSTMENT=F.ADJUSTMENT collate database_default)
			JOIN (	SELECT EC.ADJUSTMENT
				FROM #TEMPCRITERIA T
				JOIN EVENTCONTROL EC	on (EC.CRITERIANO=T.CRITERIANO)
				WHERE EC.ADJUSTMENT is not null
				UNION
				SELECT DD.ADJUSTMENT
				FROM #TEMPCRITERIA T
				JOIN DUEDATECALC DD	on (DD.CRITERIANO=T.CRITERIANO)
				WHERE DD.ADJUSTMENT is not null )  X on (X.ADJUSTMENT=F.ADJUSTMENT)
			where I.ADJUSTMENT is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------
		-- C H A R G E T Y P E --
		-------------------------
		Set @sTable ='CHARGETYPE'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CHARGEDUEEVENT',  'E1.NEWEVENTNO')
			set @sFromColumnList=replace(@sFromColumnList,'F.CHARGEINCURREDEVENT','E2.NEWEVENTNO')
			
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.CHARGETYPE("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From CHARGETYPE F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CHARGETYPE I 
						on (I.CHARGEDESC=F.CHARGEDESC)
			JOIN (	SELECT distinct C.CHARGETYPENO
				FROM #TEMPCRITERIA T
				join EVENTCONTROL EC on (EC.CRITERIANO=T.CRITERIANO)
				join CHARGETYPE C    on (C.CHARGETYPENO in (EC.INITIALFEE, EC.INITIALFEE2)))  X on (X.CHARGETYPENO=F.CHARGETYPENO)
						
			left join #TEMPEVENTS E1 on (E1.EVENTNO=F.CHARGEDUEEVENT)
			left join #TEMPEVENTS E2 on (E2.EVENTNO=F.CHARGEINCURREDEVENT)
			
			where I.CHARGETYPENO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------------------
		-- D E L I V E R Y M E T H O D --
		---------------------------------
		Set @sTable ='DELIVERYMETHOD'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.DELIVERYMETHOD("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From DELIVERYMETHOD F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.DELIVERYMETHOD I 
						on (I.DELIVERYID=F.DELIVERYID)
			JOIN (	Select L.DELIVERYID as DELIVERYID
				From #TEMPCRITERIA T
				Join REMINDERS R	on (R.CRITERIANO=T.CRITERIANO)
				Join LETTER L		on (L.LETTERNO  =R.LETTERNO)
				Where L.DELIVERYID is not null
				UNION
				Select L.DELIVERYID
				From #TEMPCRITERIA T
				Join DETAILLETTERS D	on (D.CRITERIANO=T.CRITERIANO)
				Join LETTER L		on (L.LETTERNO  =D.LETTERNO)
				Where L.DELIVERYID is not null
				UNION
				Select L1.DELIVERYID
				From LETTER L
				Join LETTER L1		on (L1.LETTERNO=L.COVERINGLETTER)
				Where L1.DELIVERYID is not null )  X on (X.DELIVERYID=F.DELIVERYID)
			where I.DELIVERYID is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------
		-- L E T T E R --
		-----------------
		Set @sTable ='LETTER'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.LETTER("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From LETTER F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.LETTER I 
						on (I.LETTERNO=F.LETTERNO)
			JOIN (	Select R.LETTERNO as LETTERNO
				From #TEMPCRITERIA T
				Join REMINDERS R	on (R.CRITERIANO=T.CRITERIANO)
				Where R.LETTERNO is not null
				UNION
				Select D.LETTERNO
				From #TEMPCRITERIA T
				Join DETAILLETTERS D	on (D.CRITERIANO=T.CRITERIANO)
				Where D.LETTERNO is not null
				UNION
				Select L.COVERINGLETTER
				From LETTER L
				Where L.COVERINGLETTER is not null )  X on (X.LETTERNO=F.LETTERNO)
			where I.LETTERNO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------
		-- S E C U R I T Y G R O U P --
		-------------------------------
		Set @sTable ='SECURITYGROUP'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.SECURITYGROUP("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From SECURITYGROUP F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.SECURITYGROUP I 
						on (I.SECURITYGROUP=F.SECURITYGROUP)
			JOIN (	Select distinct G.SECURITYGROUP as SECURITYGROUP
				From #TEMPCRITERIA T
				Join GROUPCONTROL G on (G.CRITERIANO=T.CRITERIANO))  X on (X.SECURITYGROUP=F.SECURITYGROUP)
			where I.SECURITYGROUP is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------
		-- U S E R S --
		---------------
		Set @sTable ='USERS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.USERS(USERID, NAMEOFUSER,EXTERNALUSERFLAG, CASEVIEW, REMINDERVIEW )
			Select F.USERID, F.NAMEOFUSER,F.EXTERNALUSERFLAG,F.CASEVIEW,F.REMINDERVIEW
			From USERS F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.USERS I 
						on (I.USERID=F.USERID collate database_default)
			JOIN (	Select distinct U.USERID as USERID
				From #TEMPCRITERIA T
				Join USERCONTROL U on (U.CRITERIANO=T.CRITERIANO))  X on (X.USERID=F.USERID)
			where I.USERID is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------------
		-- N U M B E R T Y P E S --
		---------------------------
		Set @sTable ='NUMBERTYPES'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.RELATEDEVENTNO','T.NEWEVENTNO')
			
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.NUMBERTYPES("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From NUMBERTYPES F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.NUMBERTYPES I 
					on (I.NUMBERTYPE=F.NUMBERTYPE collate database_default)
			left join #TEMPEVENTS T on (T.EVENTNO=F.RELATEDEVENTNO)
			where I.NUMBERTYPE is NULL"
			
			exec @ErrorCode=sp_executesql @sSQLString
		End
		-----------------------
		-- T A B L E T Y P E --
		-----------------------
		Set @sTable ='TABLETYPE'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.TABLETYPE("+@sIntoColumnList+")
			Select distinct "+@sFromColumnList+"
			From TABLECODES TC
			join dbo.TABLETYPE F on (F.TABLETYPE=TC.TABLETYPE)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.TABLETYPE I on (I.TABLETYPE=F.TABLETYPE)
			JOIN (	SELECT C.ADDRESSSTYLE as TABLECODE
				FROM COUNTRY C
				WHERE C.ADDRESSSTYLE is not null
				UNION
				SELECT C.NAMESTYLE
				FROM COUNTRY C
				WHERE C.NAMESTYLE is not null
				UNION
				SELECT C.VALIDATINGSPID
				FROM VALIDATENUMBERS C
				WHERE C.VALIDATINGSPID is not null
				UNION
				SELECT C.TABLECODE
				FROM #TEMPCRITERIA T
				join CRITERIA C on (C.CRITERIANO=T.CRITERIANO)
				WHERE C.TABLECODE is not null
				UNION
				SELECT C.TEXTID
				FROM COUNTRYTEXT C
				WHERE C.TEXTID is not null
				UNION
				SELECT C.LANGUAGE
				FROM COUNTRYTEXT C
				WHERE C.LANGUAGE is not null
				UNION
				SELECT C.TABLECODE
				FROM TABLEATTRIBUTES C
				WHERE C.PARENTTABLE='COUNTRY'
				and C.TABLECODE is not null )  X on (X.TABLECODE=TC.TABLECODE)
			where I.TABLETYPE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------
		-- T A B L E C O D E S --
		-------------------------
		Set @sTable ='TABLECODES'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.TABLECODES("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From TABLECODES F
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.TABLETYPE TT on (TT.TABLETYPE=F.TABLETYPE)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.TABLECODES I on (I.TABLECODE=F.TABLECODE)
			JOIN (	SELECT C.ADDRESSSTYLE as TABLECODE
				FROM COUNTRY C
				WHERE C.ADDRESSSTYLE is not null
				UNION
				SELECT C.NAMESTYLE
				FROM COUNTRY C
				WHERE C.NAMESTYLE is not null
				UNION
				SELECT C.VALIDATINGSPID
				FROM VALIDATENUMBERS C
				WHERE C.VALIDATINGSPID is not null
				UNION
				SELECT C.TABLECODE
				FROM #TEMPCRITERIA T
				join CRITERIA C on (C.CRITERIANO=T.CRITERIANO)
				WHERE C.TABLECODE is not null
				UNION
				SELECT C.TEXTID
				FROM COUNTRYTEXT C
				WHERE C.TEXTID is not null
				UNION
				SELECT C.LANGUAGE
				FROM COUNTRYTEXT C
				WHERE C.LANGUAGE is not null
				UNION
				SELECT C.TABLECODE
				FROM TABLEATTRIBUTES C
				WHERE C.PARENTTABLE='COUNTRY'
				and C.TABLECODE is not null )  X on (X.TABLECODE=F.TABLECODE)
			where I.TABLECODE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End
		-----------------------------------
		-- I N S T R U C T I O N T Y P E --
		-----------------------------------
		Set @sTable ='INSTRUCTIONTYPE'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.INSTRUCTIONTYPE("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From INSTRUCTIONTYPE F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.INSTRUCTIONTYPE I 
					on (I.INSTRUCTIONTYPE=F.INSTRUCTIONTYPE collate database_default)
			JOIN (	SELECT distinct EC.INSTRUCTIONTYPE
				FROM #TEMPCRITERIA T
				join EVENTCONTROL EC on (EC.CRITERIANO=T.CRITERIANO)
				WHERE EC.INSTRUCTIONTYPE is not null )  X on (X.INSTRUCTIONTYPE=F.INSTRUCTIONTYPE)
			where I.INSTRUCTIONTYPE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------------
		-- V A L I D A T E N U M B E R S --
		-----------------------------------
		Set @sTable ='VALIDATENUMBERS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDATENUMBERS("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From VALIDATENUMBERS F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDATENUMBERS I 
					on (I.VALIDATIONID=F.VALIDATIONID)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDATENUMBERS J 
					on ((J.COUNTRYCODE =F.COUNTRYCODE  collate database_default OR (J.COUNTRYCODE  is null and F.COUNTRYCODE  is null))
					and (J.PROPERTYTYPE=F.PROPERTYTYPE collate database_default OR (J.PROPERTYTYPE is null and F.PROPERTYTYPE is null))
					and (J.NUMBERTYPE  =F.NUMBERTYPE   collate database_default OR (J.NUMBERTYPE   is null and F.NUMBERTYPE   is null))
					and (J.VALIDFROM   =F.VALIDFROM                             OR (J.VALIDFROM    is null and F.VALIDFROM    is null)))
			where I.VALIDATIONID is NULL
			and   J.VALIDATIONID is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------------
		-- C O U N T R Y T E X T --
		---------------------------
		Set @sTable ='COUNTRYTEXT'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.COUNTRYTEXT("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From COUNTRYTEXT F
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.TABLECODES T 
						on (T.TABLECODE  =F.TEXTID)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.COUNTRYTEXT I 
						on (I.COUNTRYCODE=F.COUNTRYCODE collate database_default
						and I.TEXTID     =F.TEXTID)
			where I.COUNTRYCODE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------
		-- C O U N T R Y G R O U P --
		-----------------------------
		Set @sTable ='COUNTRYGROUP'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.COUNTRYGROUP("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From COUNTRYGROUP F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.COUNTRYGROUP I 
						on (I.TREATYCODE   =F.TREATYCODE    collate database_default
						and I.MEMBERCOUNTRY=F.MEMBERCOUNTRY collate database_default)
			where I.TREATYCODE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------------
		-- V A L I D S T A T U S --
		---------------------------
		Set @sTable ='VALIDSTATUS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDSTATUS("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From VALIDSTATUS F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDSTATUS I 
						on (I.COUNTRYCODE =F.COUNTRYCODE  collate database_default
						and I.PROPERTYTYPE=F.PROPERTYTYPE collate database_default
						and I.CASETYPE    =F.CASETYPE     collate database_default
						and I.STATUSCODE  =F.STATUSCODE)
			JOIN (	SELECT EC.STATUSCODE
				FROM #TEMPCRITERIA C
				JOIN EVENTCONTROL EC	on (EC.CRITERIANO=C.CRITERIANO)
				WHERE EC.STATUSCODE is not null
				UNION
				SELECT DC.STATUSCODE
				FROM #TEMPCRITERIA C
				JOIN DETAILCONTROL DC	on (DC.CRITERIANO=C.CRITERIANO)
				WHERE DC.STATUSCODE is not null
				UNION
				SELECT DC.RENEWALSTATUS
				FROM #TEMPCRITERIA C
				JOIN DETAILCONTROL DC	on (DC.CRITERIANO=C.CRITERIANO)
				WHERE DC.RENEWALSTATUS is not null )  X on (X.STATUSCODE=F.STATUSCODE)
			where I.STATUSCODE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------
		-- V A L I D P R O P E R T Y --
		-------------------------------
		Set @sTable ='VALIDPROPERTY'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDPROPERTY("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From VALIDPROPERTY F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDPROPERTY I 
						on (I.COUNTRYCODE =F.COUNTRYCODE  collate database_default
						and I.PROPERTYTYPE=F.PROPERTYTYPE collate database_default)
			where I.PROPERTYTYPE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------------
		-- V A L I D A C T I O N --
		---------------------------
		Set @sTable ='VALIDACTION'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDACTION("+@sIntoColumnList+")
			Select distinct "+@sFromColumnList+"
			From #TEMPCRITERIA T
			join CRITERIA C		on (C.CRITERIANO=T.CRITERIANO)
			join VALIDACTION F	on (F.ACTION=C.ACTION)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDACTION I 
						on (I.COUNTRYCODE =F.COUNTRYCODE  collate database_default
						and I.PROPERTYTYPE=F.PROPERTYTYPE collate database_default
						and I.CASETYPE    =F.CASETYPE     collate database_default
						and I.ACTION      =F.ACTION       collate database_default)
			where I.ACTION is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------
		-- V A L I D C A T E G O R Y --
		-------------------------------
		Set @sTable ='VALIDCATEGORY'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDCATEGORY("+@sIntoColumnList+")
			Select distinct "+@sFromColumnList+"
			From VALIDCATEGORY F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDCATEGORY I 
						on (I.COUNTRYCODE=F.COUNTRYCODE   collate database_default
						and I.PROPERTYTYPE=F.PROPERTYTYPE collate database_default
						and I.CASETYPE    =F.CASETYPE     collate database_default
						and I.CASECATEGORY=F.CASECATEGORY collate database_default)
			JOIN (	SELECT distinct C.CASETYPE, C.CASECATEGORY
				FROM #TEMPCRITERIA T
				join CRITERIA C on (C.CRITERIANO=T.CRITERIANO)
				WHERE C.CASETYPE     is not null 
				and   C.CASECATEGORY is not null)  X	on (X.CASETYPE    =F.CASETYPE
									and X.CASECATEGORY=F.CASECATEGORY)
			where I.CASECATEGORY is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------
		-- V A L I D S U B T Y P E --
		-----------------------------
		Set @sTable ='VALIDSUBTYPE'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDSUBTYPE("+@sIntoColumnList+")
			Select distinct "+@sFromColumnList+"
			From VALIDSUBTYPE F
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDCATEGORY C 
						on (C.COUNTRYCODE=F.COUNTRYCODE   collate database_default
						and C.PROPERTYTYPE=F.PROPERTYTYPE collate database_default
						and C.CASETYPE    =F.CASETYPE     collate database_default
						and C.CASECATEGORY=F.CASECATEGORY collate database_default)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDSUBTYPE I 
						on (I.COUNTRYCODE =F.COUNTRYCODE  collate database_default
						and I.PROPERTYTYPE=F.PROPERTYTYPE collate database_default
						and I.CASETYPE    =F.CASETYPE     collate database_default
						and I.CASECATEGORY=F.CASECATEGORY collate database_default
						and I.SUBTYPE     =F.SUBTYPE      collate database_default)
			JOIN (	SELECT distinct C.SUBTYPE
				FROM #TEMPCRITERIA T
				join CRITERIA C on (C.CRITERIANO=T.CRITERIANO)
				WHERE C.SUBTYPE is not null)  X	on (X.SUBTYPE=F.SUBTYPE)
			where I.SUBTYPE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------
		-- V A L I D B A S I S --
		-------------------------
		Set @sTable ='VALIDBASIS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDBASIS("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From VALIDBASIS F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDBASIS I
						on (I.COUNTRYCODE =F.COUNTRYCODE  collate database_default
						and I.PROPERTYTYPE=F.PROPERTYTYPE collate database_default
						and I.BASIS       =F.BASIS        collate database_default)
			where I.BASIS is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------
		-- V A L I D A C T D A T E S --
		-------------------------------
		Set @sTable ='VALIDACTDATES'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME

			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.ACTEVENTNO',  'E1.NEWEVENTNO')
			set @sFromColumnList=replace(@sFromColumnList,'F.RETROEVENTNO','E2.NEWEVENTNO')
			
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDACTDATES("+@sIntoColumnList+")
			Select distinct "+@sFromColumnList+"
			From VALIDACTDATES F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDACTDATES I 
						on (I.COUNTRYCODE =F.COUNTRYCODE  collate database_default
						and I.PROPERTYTYPE=F.PROPERTYTYPE collate database_default
						and I.DATEOFACT   =F.DATEOFACT
						and I.SEQUENCENO  =F.SEQUENCENO)
						
			left join #TEMPEVENTS E1 on (E1.EVENTNO=F.ACTEVENTNO)
			left join #TEMPEVENTS E2 on (E2.EVENTNO=F.RETROEVENTNO)
					
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.COUNTRY C on (C.COUNTRYCODE=F.COUNTRYCODE   collate database_default)
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.ACTIONS A on (A.ACTION=F.RETROSPECTIVEACTIO collate database_default)
			where I.DATEOFACT is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------------------
		-- V A L I D R E L A T I O N S H I P S --
		-----------------------------------------
		Set @sTable ='VALIDRELATIONSHIPS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDRELATIONSHIPS("+@sIntoColumnList+")
			Select distinct "+@sFromColumnList+"
			From VALIDRELATIONSHIPS F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.VALIDRELATIONSHIPS I
							on (I.COUNTRYCODE =F.COUNTRYCODE  collate database_default
							and I.PROPERTYTYPE=F.PROPERTYTYPE collate database_default
							and I.RELATIONSHIP=F.RELATIONSHIP collate database_default)
			JOIN (	Select CR.RELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN EVENTCONTROL EC	on (EC.CRITERIANO=T.CRITERIANO)
				JOIN CASERELATION CR	on (CR.RELATIONSHIP=EC.FROMRELATIONSHIP)
				UNION
				Select VR.RECIPRELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN EVENTCONTROL EC		on (EC.CRITERIANO=T.CRITERIANO)
				JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=EC.FROMRELATIONSHIP)
				Where VR.RECIPRELATIONSHIP is not null
				UNION
				Select CR.RELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN DUEDATECALC DD	on (DD.CRITERIANO=T.CRITERIANO)
				JOIN CASERELATION CR	on (CR.RELATIONSHIP=DD.COMPARERELATIONSHIP)
				UNION
				Select VR.RECIPRELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN DUEDATECALC DD		on (DD.CRITERIANO=T.CRITERIANO)
				JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=DD.COMPARERELATIONSHIP)
				WHERE VR.RECIPRELATIONSHIP is not null
				UNION
				Select CR.RELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN DATESLOGIC DL	on (DL.CRITERIANO=T.CRITERIANO)
				JOIN CASERELATION CR	on (CR.RELATIONSHIP=DL.CASERELATIONSHIP)
				UNION
				Select VR.RECIPRELATIONSHIP
				FROM #TEMPCRITERIA T
				JOIN DATESLOGIC DL		on (DL.CRITERIANO=T.CRITERIANO)
				JOIN VALIDRELATIONSHIPS VR	on (VR.RELATIONSHIP=DL.CASERELATIONSHIP)
				WHERE VR.RECIPRELATIONSHIP is not null )  X on (X.RELATIONSHIP=F.RELATIONSHIP)
			where I.RELATIONSHIP is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------------
		-- I N S T R U C T I O N L A B E L --
		-------------------------------------
		Set @sTable ='INSTRUCTIONLABEL'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.INSTRUCTIONLABEL("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From INSTRUCTIONLABEL F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.INSTRUCTIONLABEL I
						on (I.INSTRUCTIONTYPE=F.INSTRUCTIONTYPE collate database_default
						and I.FLAGNUMBER     =F.FLAGNUMBER)
			JOIN (	SELECT distinct EC.INSTRUCTIONTYPE, EC.FLAGNUMBER
				FROM #TEMPCRITERIA T
				join EVENTCONTROL EC on (EC.CRITERIANO=T.CRITERIANO)
				WHERE EC.INSTRUCTIONTYPE is not null )  X on (X.INSTRUCTIONTYPE=F.INSTRUCTIONTYPE
									  and X.FLAGNUMBER     =F.FLAGNUMBER)
			where I.INSTRUCTIONTYPE is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------------
		-- T A B L E A T T R I B U T E S --
		-----------------------------------
		Set @sTable ='TABLEATTRIBUTES'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.TABLEATTRIBUTES("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From TABLEATTRIBUTES F
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.TABLETYPE TT on (TT.TABLETYPE=F.TABLETYPE)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.TABLEATTRIBUTES I
							on (I.PARENTTABLE=F.PARENTTABLE collate database_default
							and I.GENERICKEY =F.GENERICKEY  collate database_default
							and I.TABLECODE  =F.TABLECODE)
			where I.TABLECODE is NULL
			and F.PARENTTABLE='COUNTRY'"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------
		-- C R I T E R I A --
		---------------------
		Set @sTable ='CRITERIA'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList  =isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList  =isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME,
				@sUpdateColumnList=CASE WHEN(F.COLUMN_NAME<>'CRITERIANO') THEN isnull(nullif(@sUpdateColumnList+',',','),'')     +F.COLUMN_NAME+'=F.'+F.COLUMN_NAME+CHAR(10)+CHAR(9)+CHAR(9)+CHAR(9) END
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sUpdateColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList  =@sIntoColumnList	OUTPUT,
						  @sFromColumnList  =@sFromColumnList	OUTPUT,
						  @sUpdateColumnList=@sUpdateColumnList	OUTPUT,
						  @sTable=@sTable
		End
		
		------------------------------------------------------------------
		-- If the CRITERIANO is to be retained, then the existing CRITERIA 
		-- with the same CRITERIANO is to first be updated before removing 
		-- all of the child tables for that CRITERIANO.
		------------------------------------------------------------------
		If  @pbReplaceExistingCriteriaNo=1
		and @ErrorCode=0
		Begin
			----------------------------------------
			-- Update the attributes of the existing
			-- CRITERIA row
			----------------------------------------
			Set @sSQLString="
			Update N
			Set "+@sUpdateColumnList+"
			From "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA N
			join #TEMPCRITERIA T	on (T.CRITERIANO=N.CRITERIANO)
			join (select * from CRITERIA) F
						on (F.CRITERIANO=N.CRITERIANO)"
				
			exec @ErrorCode=sp_executesql @sSQLString
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Delete N
				from "+@psIntoServer+"."+@psIntoDatabase+".dbo.DETAILCONTROL N
				join #TEMPCRITERIA T on(T.CRITERIANO=N.CRITERIANO)"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Delete N
				from "+@psIntoServer+"."+@psIntoDatabase+".dbo.EVENTCONTROL N
				join #TEMPCRITERIA T on(T.CRITERIANO=N.CRITERIANO)"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Delete N
				from "+@psIntoServer+"."+@psIntoDatabase+".dbo.INHERITS N
				join #TEMPCRITERIA T on(T.CRITERIANO=N.CRITERIANO)"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Delete N
				from "+@psIntoServer+"."+@psIntoDatabase+".dbo.DETAILDATES N
				join #TEMPCRITERIA T on(T.CRITERIANO=N.CRITERIANO)"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Delete N
				from "+@psIntoServer+"."+@psIntoDatabase+".dbo.DETAILLETTERS N
				join #TEMPCRITERIA T on(T.CRITERIANO=N.CRITERIANO)"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Delete N
				from "+@psIntoServer+"."+@psIntoDatabase+".dbo.DUEDATECALC N
				join #TEMPCRITERIA T on(T.CRITERIANO=N.CRITERIANO)"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Delete N
				from "+@psIntoServer+"."+@psIntoDatabase+".dbo.RELATEDEVENTS N
				join #TEMPCRITERIA T on(T.CRITERIANO=N.CRITERIANO)"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Delete N
				from "+@psIntoServer+"."+@psIntoDatabase+".dbo.DATESLOGIC N
				join #TEMPCRITERIA T on(T.CRITERIANO=N.CRITERIANO)"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Delete N
				from "+@psIntoServer+"."+@psIntoDatabase+".dbo.REMINDERS N
				join #TEMPCRITERIA T on(T.CRITERIANO=N.CRITERIANO)"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
			
			If @ErrorCode=0
			Begin
				------------------------------------------------
				-- Set the NEWEVENTNO that does not have a value
				-- to ensure these get inserted correctly using
				-- the existing EVENTNO.
				------------------------------------------------
				Set @sSQLString="
				Update #TEMPEVENTS
				Set NEWEVENTNO=EVENTNO
				where NEWEVENTNO is null"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
		End
		
		--------------------------------------------------
		-- Now copy the CRITERIA rows where the CRITERIANO
		-- is not already in use
		--------------------------------------------------
		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO',    'T.NEWCRITERIANO')
			set @sFromColumnList=replace(@sFromColumnList,'F.PARENTCRITERIA','C.NEWCRITERIANO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From CRITERIA F
			join #TEMPCRITERIA T      on (T.CRITERIANO=F.CRITERIANO)
			left join #TEMPCRITERIA C on (C.CRITERIANO=F.PARENTCRITERIA)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA I on (I.CRITERIANO=T.NEWCRITERIANO)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------
		-- D E T A I L C O N T R O L --
		-------------------------------
		Set @sTable ='DETAILCONTROL'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO',    'T.NEWCRITERIANO')
			set @sFromColumnList=replace(@sFromColumnList,'F.DISPLAYEVENTNO','DE.NEWEVENTNO')	-- RFC44645
			set @sFromColumnList=replace(@sFromColumnList,'F.HIDEEVENTNO',   'HE.NEWEVENTNO')	-- RFC44645
			set @sFromColumnList=replace(@sFromColumnList,'F.DIMEVENTNO',    'GE.NEWEVENTNO')	-- RFC44645

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.DETAILCONTROL("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From DETAILCONTROL F
			join #TEMPCRITERIA T      on (T.CRITERIANO =F.CRITERIANO)
			left join #TEMPEVENTS DE  on (DE.EVENTNO   =F.DISPLAYEVENTNO)	-- RFC44645
			left join #TEMPEVENTS HE  on (HE.EVENTNO   =F.HIDEEVENTNO)	-- RFC44645
			left join #TEMPEVENTS GE  on (GE.EVENTNO   =F.DIMEVENTNO)	-- RFC44645

			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.DETAILCONTROL I 
						on (I.CRITERIANO =T.NEWCRITERIANO
						and I.ENTRYNUMBER=F.ENTRYNUMBER)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End
		
		------------------------------
		-- E V E N T C O N T R O L --
		------------------------------
		Set @sTable ='EVENTCONTROL'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION','PARENTCRITERIANO','PARENTEVENTNO')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO','T.NEWCRITERIANO')
			set @sFromColumnList=replace(@sFromColumnList,'F.EVENTNO','E.NEWEVENTNO')
			set @sFromColumnList=replace(@sFromColumnList,'F.UPDATEFROMEVENT','E2.NEWEVENTNO')
			set @sFromColumnList=replace(@sFromColumnList,'F.INITIALFEE2','C2.CHARGETYPENO')
			set @sFromColumnList=replace(@sFromColumnList,'F.INITIALFEE', 'C1.CHARGETYPENO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.EVENTCONTROL("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From EVENTCONTROL F
			join #TEMPCRITERIA T     on (T.CRITERIANO=F.CRITERIANO)
			join #TEMPEVENTS E	 on (E.EVENTNO   =F.EVENTNO)
			left join #TEMPEVENTS E2 on (E2.EVENTNO  =F.UPDATEFROMEVENT)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.EVENTCONTROL I 
						on (I.CRITERIANO=T.NEWCRITERIANO
						and I.EVENTNO   =E.NEWEVENTNO)
			left join CHARGETYPE I1	on (I1.CHARGETYPENO=F.INITIALFEE)
			left join CHARGETYPE I2 on (I2.CHARGETYPENO=F.INITIALFEE2)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CHARGETYPE C1 on (C1.CHARGEDESC=I1.CHARGEDESC) 
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CHARGETYPE C2 on (C2.CHARGEDESC=I2.CHARGEDESC)
			
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------
		-- I N H E R I T S --
		---------------------

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.INHERITS(CRITERIANO, FROMCRITERIA)
			Select T.NEWCRITERIANO, T1.NEWCRITERIANO
			From #TEMPCRITERIA T
			join INHERITS F		on ( F.CRITERIANO  =T.CRITERIANO)
			join #TEMPCRITERIA T1	on (T1.CRITERIANO  =F.FROMCRITERIA)
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA C
						on ( C.CRITERIANO  =T1.NEWCRITERIANO)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.INHERITS I
						on ( I.CRITERIANO  = T.NEWCRITERIANO
						and  I.FROMCRITERIA=T1.NEWCRITERIANO)
			where I.CRITERIANO is NULL
			UNION
			Select T.NEWCRITERIANO, F.FROMCRITERIA
			From #TEMPCRITERIA T
			join INHERITS F		on ( F.CRITERIANO  =T.CRITERIANO)
			left join #TEMPCRITERIA T1	
						on (T1.CRITERIANO  =F.FROMCRITERIA)
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA C
						on ( C.CRITERIANO  =F.FROMCRITERIA)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.INHERITS I
						on ( I.CRITERIANO  =T.NEWCRITERIANO
						and  I.FROMCRITERIA=F.FROMCRITERIA)
			where I.CRITERIANO is NULL
			and  T1.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------------
		-- D E T A I L D A T E S --
		---------------------------
		Set @sTable ='DETAILDATES'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO','T.NEWCRITERIANO')
			set @sFromColumnList=replace(@sFromColumnList,'F.EVENTNO','E.NEWEVENTNO')
			set @sFromColumnList=replace(@sFromColumnList,'F.OTHEREVENTNO','D.NEWEVENTNO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.DETAILDATES("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From #TEMPCRITERIA T
			join DETAILDATES F	on (F.CRITERIANO=T.CRITERIANO)
			join #TEMPEVENTS E	on (E.EVENTNO   =F.EVENTNO)
			left join #TEMPEVENTS D	on (D.EVENTNO   =F.OTHEREVENTNO)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.DETAILDATES I 
						on (I.CRITERIANO =T.NEWCRITERIANO
						and I.ENTRYNUMBER=F.ENTRYNUMBER
						and I.EVENTNO    =E.NEWEVENTNO)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------
		-- D E T A I L L E T T E R S --
		-------------------------------
		Set @sTable ='DETAILLETTERS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO','T.NEWCRITERIANO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.DETAILLETTERS("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From #TEMPCRITERIA T
			join DETAILLETTERS F	on (F.CRITERIANO=T.CRITERIANO)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.DETAILLETTERS I 
						on (I.CRITERIANO =T.NEWCRITERIANO
						and I.ENTRYNUMBER=F.ENTRYNUMBER
						and I.LETTERNO   =F.LETTERNO)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------------
		-- D U E D A T E C A L C --
		---------------------------
		Set @sTable ='DUEDATECALC'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO',   'T.NEWCRITERIANO')
			set @sFromColumnList=replace(@sFromColumnList,'F.EVENTNO',      'E.NEWEVENTNO')
			set @sFromColumnList=replace(@sFromColumnList,'F.FROMEVENT',    'G.NEWEVENTNO')
			set @sFromColumnList=replace(@sFromColumnList,'F.COMPAREEVENT,','H.NEWEVENTNO,')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.DUEDATECALC("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From DUEDATECALC F
			join #TEMPCRITERIA T    on (T.CRITERIANO=F.CRITERIANO)
			join #TEMPEVENTS E	on (E.EVENTNO   =F.EVENTNO)
			left join #TEMPEVENTS G	on (G.EVENTNO   =F.FROMEVENT)
			left join #TEMPEVENTS H	on (H.EVENTNO   =F.COMPAREEVENT)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.DUEDATECALC I 
						on (I.CRITERIANO=T.NEWCRITERIANO
						and I.EVENTNO   =E.NEWEVENTNO
						and I.SEQUENCE  =F.SEQUENCE)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------
		-- R E L A T E D E V E N T S --
		-------------------------------
		Set @sTable ='RELATEDEVENTS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO',   'T.NEWCRITERIANO')
			set @sFromColumnList=replace(@sFromColumnList,'F.EVENTNO',      'E.NEWEVENTNO')
			set @sFromColumnList=replace(@sFromColumnList,'F.RELATEDEVENT', 'G.NEWEVENTNO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.RELATEDEVENTS("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From RELATEDEVENTS F
			join #TEMPCRITERIA T    on (T.CRITERIANO=F.CRITERIANO)
			join #TEMPEVENTS E	on (E.EVENTNO   =F.EVENTNO)
			left join #TEMPEVENTS G	on (G.EVENTNO   =F.RELATEDEVENT)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.RELATEDEVENTS I 
						on (I.CRITERIANO=T.NEWCRITERIANO
						and I.EVENTNO   =E.NEWEVENTNO
						and I.RELATEDNO =F.RELATEDNO)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------
		-- D A T E S L O G I C --
		-------------------------
		Set @sTable ='DATESLOGIC'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO',   'T.NEWCRITERIANO')
			set @sFromColumnList=replace(@sFromColumnList,'F.EVENTNO',      'E.NEWEVENTNO')
			set @sFromColumnList=replace(@sFromColumnList,'F.COMPAREEVENT', 'G.NEWEVENTNO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.DATESLOGIC("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From DATESLOGIC F
			join #TEMPCRITERIA T    on (T.CRITERIANO=F.CRITERIANO)
			join #TEMPEVENTS E	on (E.EVENTNO   =F.EVENTNO)
			left join #TEMPEVENTS G	on (G.EVENTNO   =F.COMPAREEVENT)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.DATESLOGIC I 
						on (I.CRITERIANO=T.NEWCRITERIANO
						and I.EVENTNO   =E.NEWEVENTNO
						and I.SEQUENCENO=F.SEQUENCENO)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------
		-- R E M I N D E R S --
		-----------------------
		Set @sTable ='REMINDERS'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO','T.NEWCRITERIANO')
			set @sFromColumnList=replace(@sFromColumnList,'F.EVENTNO',   'E.NEWEVENTNO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.REMINDERS("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From REMINDERS F
			join #TEMPCRITERIA T    on (T.CRITERIANO=F.CRITERIANO)
			join #TEMPEVENTS E	on (E.EVENTNO   =F.EVENTNO)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.REMINDERS I 
						on (I.CRITERIANO=T.NEWCRITERIANO
						and I.EVENTNO   =E.NEWEVENTNO
						and I.REMINDERNO=F.REMINDERNO)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------
		-- S C R E E N C O N T R O L --
		-------------------------------
		Set @sTable ='SCREENCONTROL'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO','T.NEWCRITERIANO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.SCREENCONTROL("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From SCREENCONTROL F
			join #TEMPCRITERIA T    on (T.CRITERIANO=F.CRITERIANO)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.SCREENCONTROL I 
						on (I.CRITERIANO=T.NEWCRITERIANO
						and I.SCREENNAME=F.SCREENNAME
						and I.SCREENID  =F.SCREENID)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------
		-- F I E L D C O N T R O L --
		-----------------------------
		Set @sTable ='FIELDCONTROL'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO','T.NEWCRITERIANO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.FIELDCONTROL("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From FIELDCONTROL F
			join #TEMPCRITERIA T    on (T.CRITERIANO=F.CRITERIANO)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.FIELDCONTROL I 
						on (I.CRITERIANO=T.NEWCRITERIANO
						and I.SCREENNAME=F.SCREENNAME
						and I.SCREENID  =F.SCREENID
						and I.FIELDNAME =F.FIELDNAME)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------
		-- G R O U P C O N T R O L --
		-----------------------------
		Set @sTable ='GROUPCONTROL'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO','T.NEWCRITERIANO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.GROUPCONTROL("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From GROUPCONTROL F
			join #TEMPCRITERIA T    on (T.CRITERIANO=F.CRITERIANO)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.GROUPCONTROL I 
						on (I.CRITERIANO=T.NEWCRITERIANO
						and I.SECURITYGROUP=F.SECURITYGROUP
						and I.ENTRYNUMBER  =F.ENTRYNUMBER)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------------
		-- U S E R C O N T R O L --
		---------------------------
		Set @sTable ='USERCONTROL'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			set @sFromColumnList=replace(@sFromColumnList,'F.CRITERIANO','T.NEWCRITERIANO')

			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.USERCONTROL("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From USERCONTROL F
			join #TEMPCRITERIA T    on (T.CRITERIANO=F.CRITERIANO)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.USERCONTROL I 
						on (I.CRITERIANO =T.NEWCRITERIANO
						and I.ENTRYNUMBER=F.ENTRYNUMBER
						and I.USERID     =F.USERID)
			where I.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------
		-- R O L E --
		-------------
		Set @sTable ='ROLE'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.ROLE("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From ROLE F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.ROLE I 
						on (I.ROLENAME=F.ROLENAME  collate database_default)
			JOIN (	Select distinct RC.ROLEID as ROLEID
				From #TEMPCRITERIA T
				Join ROLESCONTROL RC on (RC.CRITERIANO=T.CRITERIANO))  X on (X.ROLEID=F.ROLEID)
			where I.ROLEID is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------
		-- U S E R I D E N T I T Y --
		-----------------------------
		Set @sTable ='USERIDENTITY'

		If @ErrorCode=0
		Begin
			-------------------------------------------------
			-- Get a list of the columns to be copied to the
			-- destination database for each table.
			-------------------------------------------------
			Set @sIntoColumnList=null
			Set @sFromColumnList=null

			Set @sSQLString="
			Select  @sIntoColumnList=isnull(nullif(@sIntoColumnList+',',','),'')     +F.COLUMN_NAME,
				@sFromColumnList=isnull(nullif(@sFromColumnList+',',','),'')+'F.'+F.COLUMN_NAME
			from INFORMATION_SCHEMA.COLUMNS F 
			join "+@psIntoServer+"."+@psIntoDatabase+".INFORMATION_SCHEMA.COLUMNS I
						on (I.TABLE_NAME  collate DATABASE_DEFAULT=F.TABLE_NAME
						and I.COLUMN_NAME collate DATABASE_DEFAULT=F.COLUMN_NAME)
			where F.TABLE_NAME=@sTable
			and F.COLUMN_NAME not in ('LOGUSERID','LOGIDENTITYID','LOGTRANSACTIONNO','LOGDATETIMESTAMP','LOGACTION','LOGOFFICEID','LOGAPPLICATION')
			and F.COLUMN_NAME not like '%[_]TID'
			and F.DATA_TYPE not in ('sysname','uniqueidentifier')
			and COLUMNPROPERTY(object_id(F.TABLE_NAME),F.COLUMN_NAME, 'IsIdentity' )=0
			order by F.ORDINAL_POSITION"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIntoColumnList	varchar(4000)	OUTPUT,
						  @sFromColumnList	varchar(4000)	OUTPUT,
						  @sTable		varchar(128)',
						  @sIntoColumnList=@sIntoColumnList	OUTPUT,
						  @sFromColumnList=@sFromColumnList	OUTPUT,
						  @sTable=@sTable
		End

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.USERIDENTITY("+@sIntoColumnList+")
			Select "+@sFromColumnList+"
			From USERIDENTITY F
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.USERIDENTITY I 
						on (I.LOGINID=F.LOGINID  collate database_default)
			JOIN (	Select distinct I.IDENTITYID as IDENTITYID
				From #TEMPCRITERIA T
				Join ROLESCONTROL RC on (RC.CRITERIANO=T.CRITERIANO)
				join IDENTITYROLES I on ( I.ROLEID    =RC.ROLEID))  X on (X.IDENTITYID=F.IDENTITYID)
			where I.IDENTITYID is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-------------------------------
		-- I D E N T I T Y R O L E S --
		-------------------------------

		If @ErrorCode=0
		Begin
			-----------------------------------------------
			-- We need to get the new IDENTITYID and ROLEID
			-- values generated on the receiving database
			-----------------------------------------------
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.IDENTITYROLES(IDENTITYID, ROLEID)
			Select I1.IDENTITYID, R1.ROLEID
			From (	Select distinct RC.ROLEID as ROLEID, I.IDENTITYID as IDENTITYID
				From #TEMPCRITERIA T
				Join ROLESCONTROL RC on (RC.CRITERIANO=T.CRITERIANO)
				join IDENTITYROLES I on ( I.ROLEID    =RC.ROLEID))  X 
			join ROLE R on (R.ROLEID =X.ROLEID)
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.ROLE R1 on (R1.ROLENAME =R.ROLENAME collate database_default)
			join USERIDENTITY UI on (UI.IDENTITYID=X.IDENTITYID)
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.USERIDENTITY I1 on (I1.LOGINID =UI.LOGINID collate database_default)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.IDENTITYROLES IR 
						on (IR.IDENTITYID=I1.IDENTITYID
						and IR.ROLEID   =R1.ROLEID)
			where IR.IDENTITYID is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End
		
		------------------------------
		-- R O L E S C O N T R O L  --
		------------------------------

		If @ErrorCode=0
		Begin
			-----------------------------------------------
			-- We need to get the new ROLEID value just
			-- generated on the receiving database
			-----------------------------------------------
			Set @sSQLString="
			Insert into "+@psIntoServer+"."+@psIntoDatabase+".dbo.ROLESCONTROL(CRITERIANO, ENTRYNUMBER, ROLEID, INHERITED)
			Select X.CRITERIANO, X.ENTRYNUMBER, R1.ROLEID, X.INHERITED
			From (	Select distinct RC.ROLEID as ROLEID, RC.CRITERIANO as CRITERIANO, RC.ENTRYNUMBER as ENTRYNUMBER, RC.INHERITED as INHERITED
				From #TEMPCRITERIA T
				Join ROLESCONTROL RC on (RC.CRITERIANO=T.CRITERIANO))  X 
			join ROLE R on (R.ROLEID =X.ROLEID)
			join "+@psIntoServer+"."+@psIntoDatabase+".dbo.ROLE R1 on (R1.ROLENAME =R.ROLENAME collate database_default)
			left join "+@psIntoServer+"."+@psIntoDatabase+".dbo.ROLESCONTROL RC 
						on (RC.CRITERIANO =X.CRITERIANO
						and RC.ENTRYNUMBER=X.ENTRYNUMBER
						and RC.ROLEID     =R1.ROLEID)
			where RC.CRITERIANO is NULL"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		------------------------------------
		-- C R I T E R I A N O   U P D A T E
		------------------------------------
		If  @ErrorCode=0
		and @pbReplaceExistingCriteria=1
		Begin
			---------------------------------------
			-- Those existing Criteria that have
			-- identical characteristics to the
			-- Criteria being copied, are to be
			-- updated to point to the new Criteria
			---------------------------------------
			Set @sSQLString="
			Update OA
			Set CRITERIANO=NEWCRITERIANO
			From #TEMPCRITERIA T
			Join "+@psIntoServer+"."+@psIntoDatabase+".dbo.OPENACTION OA on (OA.CRITERIANO= T.MATCHINGCRITERIANO)"

			exec @ErrorCode=sp_executesql @sSQLString

			If @ErrorCode=0
			Begin
				---------------------------------------
				-- The existing Criteria that have
				-- identical characteristics to the
				-- Criteria being copied, are to be
				-- have the Rule In Use flag set off
				---------------------------------------
				Set @sSQLString="
				Update C
				Set RULEINUSE=0
				From #TEMPCRITERIA T
				Join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA C
						on ( C.CRITERIANO = T.MATCHINGCRITERIANO
						and  C.RULEINUSE  = 1)
				Join "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA C1
						on (C1.CRITERIANO = T.NEWCRITERIANO
						and C1.RULEINUSE  = 1)
				Where T.NEWCRITERIANO<>T.MATCHINGCRITERIANO"

				exec @ErrorCode=sp_executesql @sSQLString
			End
		End

		------------------------------------------------
		-- L A S T I N T E R N A L C O D E   U P D A T E
		------------------------------------------------
		If  @ErrorCode=0
		Begin
			Set @sSQLString="
			Update L
			Set INTERNALSEQUENCE= (select max(CRITERIANO) from  "+@psIntoServer+"."+@psIntoDatabase+".dbo.CRITERIA)
			from  "+@psIntoServer+"."+@psIntoDatabase+".dbo.LASTINTERNALCODE L
			where L.TABLENAME='CRITERIA'"

			exec @ErrorCode=sp_executesql @sSQLString
		End
		--===================================
		-- Commit or Rollback the transaction
		--===================================		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
		
		-- Terminate the WHILE loop
		Set @nRetry=-1
	END TRY	

	---------------------------------
	-- D E A D L O C K   V I C T I M   
	--       P R O C E S S I N G
	---------------------------------
	BEGIN CATCH
		------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
		------------------------------------------
		Set @ErrorCode=ERROR_NUMBER()
		If @ErrorCode=1205
			Set @nRetry=@nRetry-1
		Else
			Set @nRetry=-1
			
		If XACT_STATE()<>0
			Rollback Transaction
		
		If @nRetry<1
		Begin
			--Set @ErrorCode=ERROR_NUMBER()
			
			-- Get error details to propagate to the caller
			Select 	@sErrorMessage = 'Error:' + cast(ERROR_NUMBER() as nvarchar) + ' - ' + ERROR_MESSAGE(),
				@nErrorSeverity = ERROR_SEVERITY(),
				@nErrorState    = ERROR_STATE(),
				@ErrorCode      = ERROR_NUMBER()

			-- Use RAISERROR inside the CATCH block to return error
			-- information about the original error that caused
			-- execution to jump to the CATCH block.
			RAISERROR ( @sErrorMessage,	-- Message text.
			            @nErrorSeverity,	-- Severity.
			            @nErrorState	-- State.
			           )
		End
	END CATCH
End -- WHILE loop

RETURN @ErrorCode
go

grant execute on dbo.cr_CopyCriteria  to public
go
