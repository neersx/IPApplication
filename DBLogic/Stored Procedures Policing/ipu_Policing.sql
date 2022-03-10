-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_Policing
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipu_Policing]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipu_Policing.'
	drop procedure dbo.ipu_Policing
end
print '**** Creating procedure dbo.ipu_Policing...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ipu_Policing
			@pdtPolicingDateEntered	datetime = null,
			@pnPolicingSeqNo		int 	 = null, 
			@pnDebugFlag			tinyint  = 0,		-- 0=off; 1=procedures; 2=dump TEMPCASEEVENT at end; 3=dump temp table at end of each procedure
			@pnBatchNo			int      = null,
			@psDelayLength			varchar(9)=null,	-- the lengh of time in the format hhh:mm:ss to wait between restarting the Policing process
			@pnUserIdentityId		int	  =null,
			@psPolicingMessageTable 	nvarchar(128)=null,	-- table for loading details of Policing progress
			@pnAsynchronousFlag		tinyint = 0,		-- 1 indicates that caller called this SP asynchronously
			@pnSessionTransNo		int = null,		-- Audit transaction number assocated with the caller session.  Only applicable for asynchronous mode.
			@pnEDEBatchNo			int = null,		-- Batch number held in CONTEXT_INFO.  Passed when Policing called asynchronously.
			@pnBatchSize			int = null		-- Explicit number of Policing rows to process at the one time

as
-- PROCEDURE :	ipu_Policing
-- VERSION :	173
-- DESCRIPTION:	A procedure to recalculate the Criteria, Due Dates and Reminders for Cases.
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13/07/2000	MF			Procedure created	
-- 15/08/2001	MF			Initialise the @nSysGeneratedFlag when reading it from the POLICING table in case
--					the column on POLICING is set to NULL.
-- 15/08/2001	MF			Add a new colum to TEMPCASEEVENT called EVENTUPDATEDMANUALLY to flag those rows that
--					were updated prior to Policing being called.  If there is a Status update associated 
--					with these events then it will only be applied if the EventDate is greater than or equal
--					to the highest EventDate associated with the Case.
-- 16/08/2001	MF			Remove restriction of ONHOLDFLAG=0 when getting a specific POLICING row.
-- 28/08/2001	MF			After reading the POLICING row set flags to zero if they are null
-- 07/09/2001	MF	7041		Call a stored procedure to remove events that are Satisfied
-- 10/09/2001	MF	7049		Whenever the ErrorCode is set a row should be written to POLICINGERRORS
-- 19/09/2001	MF	7062		When Policing is being run with Recalc Reminders only no events are being 
--					returned to actually recalculate
-- 02/10/2001	MF	7094		When an Event is cleared out ensure that it is marked for Deletion if it
--					has not been recalculated.
-- 08/10/2001	MF	7107		When Policing detects an error code and a PolicingLog row does not exist
--					then a row must be inserted to enable a PolicingErrors child rows to be inserted.
-- 09/10/2001	MF	7109		If an Event has failed to be calculated but the Event previously existed then 
--					it should be marked for deletion.
-- 30/10/2001	MF	7158		When error messages have been inserted in the TEMPPOLICINGERRORS table but
--					the ErrorCode is still zero, the errors were not being reported.
-- 31/10/2001	MF	7161		When using the CREATEDBYCRITERIA to get the Reminders make sure that the
--					Action is Open for the Case.
-- 13/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 01/02/2002	MF	7381		Continue to loop if the STATE is 'D'
-- 15/02/2002	MF	7415		If a Policing Recalculation is being performed on Reminders dates only then 
--					there is no need to get the Standing Instructions.  This will improve performance.
-- 28/02/2002	MF	7367		Add ESTIMATEFLAG to TEMPCASEEVENT so an Estimate request can be sent to Charge Generation.
-- 12/03/2002	MF	7485		Change the function USER to SYSTEM_USER
-- 10/04/2002	MF	7564		When an Event occurs check to see if the Event is also attached to other open
--					actions and make an addition entry in TEMPCASEEVENT to ensure that all
--					processing is performed.
-- 12/04/2002	MF	7570		Whenever OpenActions are to be recalculated processing of the inner loop should
--					be interrupted to allow the recalculation to occurr before continuing with the
--					calculation of Events.
-- 06/05/2002	MF	7608		The correction for 7570 is being revisited.  Ensure that the checking of the
--					date of law change occurs before the STATE is updated for TEMPCASEEVENT.
-- 08/05/2002	MF	7625		Revisit of 7564.  If the Event was created and updated itself then it is possible
--					to cause the same Event to be put on the queue.  Change to stop this.
-- 24/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 18/07/2002	MF	7858		Start the UNIQUEID allocated to each TEMPCASEEVENT row from 10 instead of 0 as 
--					we were getting an ACTIVITYHISTORY and ACTIVITYREQUEST row written with the same
--					key because UNIQUEID was being used to increment the current DateTime.
-- 22/07/2002	MF	7750		Increase IRN to 30 characters
-- 09/08/2002	MF	7392		Allow specific Periods of time to be saved against Standing Instructions
--					so that they may be used in Due Date calculations.
-- 21/08/2002	MF	7532		Allow a new facility that causes the Due Date of an Event to be advanced by
--					a defined amount whenever the due date matches or exceeds the system date.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 21/08/2002	MF	7946		Extend the size of the USERID field to avoid truncation errors.
-- 08/11/2002	MF	8171		Allow email reminders to be generated with Hyperlink
-- 03/01/2003	MF	8259 		When multiple Policing requests are to be processed in parallel, Policing 
--					should process any explicit request to open an Action before processing 
--					any other requests for the same Case.  Also allow a DelayLength parameter
--					to be passed to allow Policing to automatically continue processing without
--					the need for the Policing Server interface.  A SiteControl 'Police Continuously'
--					needs to be set ON to allow Policing to restart.  The Site Control will be
--					checked on each cycle.
-- 14/02/2003	MF	8413		Allow Policing requests to be batch.  If Policing is called with a BatchNo
--					as the parameter then process all of the POLICING rows with the same BatchNo
--					at the same time.
-- 26/02/2003	MF	8413		Revisit.  When Policing is called using the BatchNo then the POLICING rows 
--					will have the ONHOLDFLAG set on to stop the possibility of the Policing Server
--					running elsewhere attempting to process the same rows.
-- 28/02/2003	MF	8464		An event deleted by Policing was not causing other Events to be triggered
--					for recalculation.
-- 20/03/2003	MF	8549		Policing can go into an endless loop where it is processing a Batch and an error
--					is experienced thus leaving the POLICING row intact.
-- 03/03/2003	MF			Speed improvements.
-- 22/05/2003	MF	8775		Policing not correctly processing a request when the "Police Continuously" site 
--					control is set on.  The @bFirstTimeFlag needed to be reinitialised when the 
--					processing continued.
-- 14 Jul 03	MF	8975	10	Need to keep track of the EventNo and Cycle that is updating the Renewal Status
-- 16 Jul 03	MF	8987	11	Need to keep track of the number of rows in STATE 'RX'
-- 21 Jul 03	MF	9007	12	Coding error in determining if ip_PoliceSatisfyEvents should be called.  This
--					resulted in some satisfied events not being recalculated.
-- 24 Jul 03	MF	8260	13	Patent Term Adjustment totals are to be calculated
-- 28 Jul 2003	MF	8673	13	Get the OFFICE associated with the Case so it can be used to determine the
--					best CriteriaNo for an Action.
-- 26 Aug 2003	MF	9162	14	Remove "SORT_IN_TEMPDB" option from Policing as it is not supported by SQLServer 7
-- 01 Oct 2003	MF	9311	15	Reminder recalculations not being called because rowcount variable not set.
-- 23 Oct 2003	MF	9375	16	Use the CRITERIANO from the #TEMPCASEEVENT table instead of CREATEDBYCRITERIA
-- 27 Nov 2003	MF	9495	17	Discovered that a newly opened Action was not breaking out of the inner loop.
-- 07 Jan 2004	MF	9589	18	Increase COUNTRYFLAGS and CHECKCOUNTRYFLAG columns from SMALLINT to INT
-- 08 Jan 2004	MF	9538	19	Change the value of the Policing.OnHoldFlag to be 2 so that the system can
--					recognise requests that have failed to complete so they can be automatically
--					reset to try again.  Only do this if there are no logged errors for the 
--					request.  Any rows with ONHOLDFLAG=1 will continue to be ignored as these
--					will indicate requests that have manually been placed on hold.
-- 16 Jan 2004	MF	9621	20	Increase EventDescription to 100 characters.
-- 26 Feb 2004	MF	RFC708	21	To identify workbench users add the parameter @pnUserIdentityId
-- 11 May 2004	MF	10022	22	Ensure that CaseEvents that have failed to recalculate a due date are considered
--					for deletion.  These may be marked with a STATE='RX'
-- 08 Jun 2004	MF	10051	23	Add columns to #TEMPACTIVITYREQUEST to cater for multiple rows being inserted 
--					for each Name associated with the Case with the NameType specified for the
--					Letter.
-- 24 Jun 2004	MF	9880	24	Increase the size of the ADJUSTMENT column in temporary table to nvarchar(4)
-- 01 Jul 2004	MF	10251	25	Insert reminders immediatly after getting the Events to be Policed for a Policing
--					Request run. This is so Event that automatically update still have the opportunity
--					of a Reminder being generated.
-- 23 Jul 2004	MF	10312	26	When a looping error occurs update the FAILMESSAGE on the POLICINGLOG table.
-- 17 Aug 2004	MF	10358	27	The Policing Sequence No has been extended to an INT from a SMALLINT
-- 05 Aug 2004	AB	8035	27	Add collate database_default to temp table definitions
-- 12 Sep 2004	MF	RFC1327	28	Allow Policing of specific ALERT row to be processed.
-- 03 Nov 2004	MF	10385	29	New EventControl column SETTHIRDPARTYOFF to turn off the ReportToThirdParty
--					flag against Cases when an Event occurs
-- 04 Jan 2005	MF	10830	30	When Events automatically occur make certain that if there are any duplicate
--					TempCaseEvent rows because of multiple Open Action rows that these duplicates 
--					are also updated.
-- 09 Feb 2005	MF		31	The LastEvent pointer on OPENACTION is not always being updated.  This is
--					because it was only being updated when the Status was also being updated.
-- 08 Mar 2005	MF	11122	32	Add USERID and IDENTITYID to the #TEMPCASES table so that any processes triggered
--					by CASES will carry through the user identity.
-- 01 Apr 2005	AB	11225	33	Collation conflict - add collate database_default syntax to #TEMPPOLICING
-- 14 Apr 2005  AB	11267	34	Collation conflict - add collate database_default syntax to #TEMPCASEEVENT
-- 01 Jun 2005	MF	11433	35	Provide an option that causes Policing requests that are on hold to be reset.
-- 04 Jul 2005	MF	11581	36	Do not process a Policing row request for a specific Case if there are 
--					unprocessed rows existing for that same Case with an earlier date.  This will
--					ensure processing occurs in the correct sequence and avoid the situation of a
--					request having its changes underdone as a result of an earlier request being
--					processed after a later request.
-- 07 Jul 2005	MF	11011	37	Increase CaseCategory column size to NVARCHAR(2)
-- 09 Sep 2005	MF	11845	39	If more than one user has issued a Policing request for the same Case then
--					do not try and process both users requests together.
-- 12 Sep 2005	MF	11845	40	Revisit syntax error.
-- 13 Sep 2005	MF	11861	41	Ignore check of Critical Level site control against Event Importance Level
--					when Policing is being run with the Update flag turned off as the flag
--					will block any Events from actually being updated.
-- 09 Jan 2006	MF	11971	42	Allow for specific Events that have been flagged to allow the Event Date to be
--					cleared out and recalculated on a specific Policing recalculation.
-- 20 Jan 2006	MF	11122	43	Revisit code that allows IDENTITYID to be passed.  When an Event is attached to
--					multiple Actions the IDENTITYID was not being set against the subsequent
--					#TEMPCASEEVENT rows being inserted for these additional actions which later
--					caused a duplicate key error if an Action was being triggered to be inserted.
-- 20 Jan 2006	MF	11845	43	Revisit - If multiple users have requested policing against the same Case then 
--					only one User at a time will be processed.  The open action type of request
--					(value 1) will take precedence.
-- 09 Feb 2006	MF	10983	44	Event Dates are able to be pushed into a Related Case where the rule is 
--					defined against the specific Relationship
-- 24 Apr 2006	MF	12319	45	Adjustments are able to be dynamically determined from a Case
--					standing instruction.
-- 15 May 2006	MF	12315	46	Allow CASENAME updates to occur when an Event occurs
-- 06 Jun 2006	MF	12417	47	Load details of Policing progress into a table for display to the user
-- 16 Jun 2006	MF	12417	48	Revisit. Error in testing
-- 24 Jul 2006	MF	13109	49	Multiple Policing rows for the one Case are being ignored if one row
--					has a SQLUser and the other does not.
-- 02 Aug 2006	MF	13161	50	Allow the COMPOSITEEVENT column in the TEMPCASEINSTRUCTIONS table to 
--					accept NULLs.  This is a short term correction to reset the table to 
--					how it used to work however a future change (13162 in the next release) 
--					will address why Nulls are being inserted in the first place.
-- 21 Aug 2006	MF	13089	51	When charges are raised, indicate if the the Charge is for a direct payment.
--					The information to indicate this will be in the EventControl and Reminders
--					tables. 
-- 23 Oct 2006	MF	13646	52	Dynamically determine the Adjustment coming from an inherited Standing Instruction.
--					Increase the CompositeCode to 33 bytes.
-- 02 Nov 2006	MF	13724	53	Provide a new option to manage concurrency when a Policing Request instigated
--					process is running.
-- 07 Nov 2006	MF	13775	54	POLICINGLOG row should only be inserted when running in Policing Server mode
--					if there is an to be written.
-- 24 Nov 2006	MF	13162	55	Add sequence number to #TEMPCASES to allow performance improvement when
--					extracting the Case Standing Instructions.
-- 09 Jan 2007	MF	12548	56	Events that are to automatically update need to check if there are any
--					rules associated with the Event that can block the update from occurring.
-- 13 Mar 2007	MF	14563	57	If no value is passed in @pnUserIdentityId then determine it from the logged
--					on User.
-- 18 Apr 2007	MF	14201	58	Allow the Reminder destination to be determined from a related name. This 
--					requires RELATIONSHIP to be stored on #TEMPEMPLOYEEREMINDER.
-- 11 May 2007	MF	12299	59	When Policing is run immediately for a batch with the @pnBatchNo passed as a
--					parameter then the Police Continuously option was being incorrectly checked.
--					If the Police Continuously flag is on the Policing would not end.
-- 24 May 2007	MF	14812	60	Load all CASEEVENTS into TEMPCASEEVENT to improve performance.
-- 30 Aug 2007	MF	14425	61	Reserve word [STATE]
-- 03 Sep 2007	DL	15188	62	Add optional parameters @pnAsynchronousFlag and @pnSessionTransNo.
-- 20 Oct 2007	vql	15318	63	Add batch number when setting context.
-- 26 Oct 2007	MF	15518	64	Add new LIVEFLAG on #TEMPCASEEVENT to indicate the CASEEVENT row already
--					existed on database when Policing started.
-- 29 Oct 2007	vql	15523	65	Fixed error in using an Policing BatchNo instead of EDE BatchNo.
-- 30 Jan 2008	MF	15888	66	Lock POLICING rows between the time they are selected into #TEMPPOLICING
--					and the time they are updated to set the ONHOLDFLAG. This will stop the same
--					requests from being processed by multiple Policing Server executions.
-- 07 Feb 2008	MF	15188	67	Revisit to handle BatchNo being passed as parameter when Policing is run asynchronously.
-- 27 Feb 2008	MF	16033	68	Need to cater for asynchronous policing trying to process Policing rows with an
--					ONHOLDFLAG set to 2.  When multi threads of Policing are started asynchronously
--					Policing might try and process a request that is already being processed. See
--					SQA9538 as to why we allow Policing rows with ONHOLDFLAG=2 to be processed.

-- 24 Oct 2006	MF	15503	63	CREATEDBYCRITERIA should only be updated on CASEEVENT if the Update flag is set.
-- 07 Nov 2007	MF	15187	63	Provide the ability filter by one or more offices.
-- 07 Jan 2008	MF	15586	64	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 07 Feb 2008	MF	15865	61	The ability to standardise log times across replicated offices in different
--					time zones is to be catered for.  A site control will get the Office and
--					any off set required to local time in order to standardise it.
-- 18 Mar 2008	MF	14297	68	Changes for processing of Policing recalculations resulting from law update.
--					This includes the ability to place a date time against a Policing row so it is
--					not processed until that time is reached.
-- 25 Mar 2008	MF	16141	69	Events being monitored by Document Required rules are delaying the completion
--					of the Policing request while searching for the Cases that are to be recalculated.
--					By breaking out this task into a separate Policing request for the Policing Server
--					to process we will remove delays experienced by the triggering Case while it waits
--					for its initial Policing to complete.
-- 19 May 2008	MF	16424	70	Allows the number of Policing requests to be processed at the one time to be
--					passed as a parameter. If no value passed then a default from a SiteControl will
--					continue to be used.
-- 22 May 2008	MF	16424	71	Revisit.  When getting the limited number of Policing rows, we need to order 
--					the rows by ONHOLDFLAG so that the previously unprocessed rows are taken in
--					preference to rows that have already had one attempt at being processed.
-- 04 Jun 2008	MF	16430	71	When getting messages from sysmessages table after an error, limit the message
--					to the language in use.
-- 26 Jun 2008	MF	16610	72	Ensure Police Continuously only runs if @psDelayLength is not null.
-- 11 Jul 2008	MF	16690	73	Get SiteControl to see if ACTIVITYREQUEST rows require a unique WHENREQUESTED
--					datetime column.
-- 14 Jul 2008	MF	16709	73	When checking if the Event is defined under other Actions, remember to check
--					using the NEWCRITERIANO.
-- 17 Jul 2008	MF	16720	74	Revisit of 16297. Ensure ADHOCDATECREATED and ADHOCNAMENO are both NULL when
--					processing law update Policing request.
-- 08 Sep 2008	MF	16899	75	Allow events to be cleared when a due date is updated.
-- 09 Oct 2008	MF	16991	75	Revisit of 16033. Extend the period of time before picking up Policing rows that
--					have ONHOLDFLAG set to 2. This will avoid multi thread Policing from picking up
--					requests that are still being processed.
-- 11 Nov 2008	MF	16991	76	Revisit. Use a site control to determine the period of time that Policing will wait
--					before retrying to process a Policing row with ONHOLDFLAG set to 2. If the period of
--					time is not defined or is zero then a retry will not occur.
-- 11 Dec 2008	MF	17136	77	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 18 Dec 2008	MF	17231	78	When checking if a CaseEvent exists for a different Action then compare against the
--					Action being held not the CriteriaNo as that may have already changed.
-- 15 Jan 2009	MF	17294	79	The Sitecontrol 'Policing On Hold Reset' should reset requests where ONHOLDFLAG is either 1 or 3
-- 16 Jan 2009	MF	17298	80	Get site control used to determine if Policing updates are to be queue for a single
--					process at a time.
-- 18 Feb 2009	MF	17409	81	Revisit of 17231. Under certain situations the additional CaseEvents were not being loaded.
-- 06 May 2009	DL	17622	82	Insert a row into PROCESSREQUEST to indicate that policing continously is running
-- 12 May 2009	vql	17404	83	Allow recording of ad hoc reminders against names, add new NAMENO column to #TEMPALERT and #TEMPEMPLOYEEREMINDER.
-- 01 Jun 2009	MF	17748	84	Keep the transaction as short as possible when updating the POLICING table to avoid
--					contributing to blocks or deadlocks. Use BEGIN TRY and BEGIN CATCH to catch deadlock
--					errors (1205) so multiple attempts can be made to update the POLICING table.
-- 02 Jul 2009	MF	17844	85	Revisit of 17748 to set the @ErrorCode variable in the BEGIN CATCH.
-- 24 Jul 2009	MF	16548	86	The FROMEVENTNO will now identify the Event from a related Case that will be pushed
--					into the child Case.
-- 12 Aug 2009	MF	17943	87	Policing immediately can inadvertently pick up other Policing requests on the queue.
-- 01 Sep 2009	MF	17979	88	Recalculate the State counters after due dates are calculated as some Events were not
--					automatically updating when the due date had not actually changed.
-- 14 Sep 2009	MF	18041	89	Change index on #TEMPCASES to included ERRORFOUND.
-- 04 Feb 2010	MF	18436	90	Policing loop may occur when CaseEvent row with no EventDate or EventDueDate found and 
--					is then marked for Delete but triggers other Events to calculate. Change STATE to D1 to 
--					avoid the triggering of other Events while still allowing the CASEEVENT row to be deleted.
-- 16 Sep 2009	MF	17773	91	An Event that may push a date into another Case is also now able to push an official number into the
--					same Case.
-- 14 Oct 2009	MF	18131	92	Call to ip_PoliceRemoveSatisfiedEvents should occur if there are Events that are marked to just have their 
--					reminder recalculated as this can occur for manually entered due dates that have been satisfied.
-- 23 Oct 2009	MF	18155	93	Policing requests generated by Law Updates are cauing Policing Continuously to close down.
-- 11 Nov 2009	MF	18215	94	Allow a SiteControl to suppress reminders against system generated Policing Requests.
-- 12 Jan 2010	MF	18145	95	Add index to #TEMPEMPLOYEEREMINDERS to allow good performance when embedding data into SHORTMESSAGE.
-- 01 Feb 2010	MF	18422	96	Revist of 18155. Policing called for Ad Hoc Alert calculations were going into a loop.
-- 11 May 2010	MF	18736	97	Status change of a Case that now allows Policing should trigger recalculation of open Actions.
-- 19 May 2010	MF	18756	98	New indexes added to #TEMPCASEEVENT on advice of SQLServer Index Tuner. Note that these indexes do not
--					look logical to me however I am inserting them to see if there is any measurable change in performance.
-- 21 May 2010	MF	18765	99	Do not delete a #TEMPCASEEVENT row that failed to calculate if the Event is used in a 
--					NOT EXISTS date comparison rule as failure to calculate may allow another Event to now calculate.
-- 26 May 2010	MF	18765	100	SQA18765 - reverse code inserted on 21 May 2010
-- 28 Jun 2010	MF	RFC9296	101	When POLICING is being run for a saved set of Policing parameters, check to see if there are any outstanding
--					requests for CASEINSTRUCTIONS to be recalculated and if so start that process as a background task.
-- 01 Jul 2010	MF	18758	102	Increase the column size of Instruction Type to allow for expanded list.
-- 13 Jul 2010	MF	18891	103	If newly calculated Due Dates has Reminders definition against other OpenAction rows then insert 
--					an additional #TEMPCASEEVENT row for that Action so that those reminders will be considered.
-- 19 Jul 2010	MF	18891	104	Revisit to allow for reminders defined in a different Action to where the Event due date was calculated
--					and where that Action was opened after the due date was calculated.
-- 30 Jul 2010	MF	18953	105	Revisit of 18436. Deleted Event is not triggering the removal of an Event calculated from it.
-- 20 Oct 2010	AT	RFC7272  106	Extended length of ALERTMESSAGE columns.
-- 29 Oct 2010	MF	18494	107	Allow Alerts to be directed to different users depending on the rules defined against the Alert 
--					and resolved to the specific Name at the time the alert is generated.
-- 16 Nov 2010	MF	RFC9968 108	When an Event belongs to more than one Action and the calculation for that Event has failed, do not
--					delete the Event from the #TEMPCASEEVENT table if another row exists for that same Event and Cycle 
--					where the STATE='R1'. When the event was being deleted a situation existed where the deleted Event
--					was not triggered to recalculate as a result of a change to another Event.
-- 23 Dec 2010	MF	19304	109	Revist of SQA18494 to ensure that Daily Policing continues to process Alerts and send out ad-hoc reminders
-- 04 Jan 2011	MF	19234	110	On commencement of processing a POLICING row, the row is to be updated to set the SQL Process Id
--					into the SPIDINPROGRESS column.  This can then be used to help identify if there are any Policing 
--					rows that are showing that they are in progress but the SPID does not exist. This will indicate
--					that Policing has failed to process the POLICING row to completion.
-- 20 Apr 2011	MF	RFC10333 111	Reminders generated from an ALERT need to carry a reference to the EMPLOYEENO of the ALERT.
-- 10 May 2011	MF	10596	112	Events updating on production of letter should also consider letters defined against Action other than
--					the Action with the due date calculation.
-- 01 Jul 2011	MF	10929	113	Keep track of when the CASES and PROPERTY rows were last updated so that we can check that no changes
--					have been applied to the database when Policing attempts to update these.
-- 19 Jul 2011	MF	19815	114	Letter not being generated for CaseEvent entered in bulk Detail Entry. This is because the CaseEvent
--					had the wrong CreatedByCriteriaNo for the Action.
-- 08 Aug 2011	MF	R11092	115	If the calculated EventDueDate is empty and the STATE='RX' and the LoopCount is > 0 then set the STATE 
--					to "D1" to avoid triggering other events to recalculate as these have already been processed.
-- 30 Aug 2011	LP	R11237	116	Allow policing to process Open Action and Event requests when Police Immediately is ON.
-- 12 Sep 2011	MF	19919	117	Store the ALERTSEQ on #TEMPEMPLOYEEREMINDER to identify the ALERT that generated the reminder.
-- 14 Sep 2011	MF	19993	118	Recalculate Criteria occurring by default even when the save Policing request explicitly has the option turned off.
-- 20 Sep 2011	MF	19915	119	If multiple policing threads are being run, a second thread should not pick up a Case that is already 
--					being processed by an earlier thread. At the moment policing will wait for the earlier thread to 
--					finish processing if the policing request was from another user, however it does not do this if the 
--					request is from the same user. 
-- 07 Oct 2011	MS	R11333	117     Cast insertion to POLICINGERRORS.MESSAGE to 254 characters.
-- 12 Oct 2011	MF	R11092	118	If the calculated EventDueDate is empty and the STATE='RX' and the LoopCount is > 0 then set the STATE 
--					to "D1" to avoid triggering other events to recalculate as these have already been processed.
-- 24 Oct 2011	MF	R11463	119	Revist of SQA19993. Newly opened Action is not getting the CriteriaNo calculated. 
-- 25 Oct 2011	MF	R11457	120	After an Event due date has been calculated, consider if there are any other rules for that Event defined against
--					other Open Actions for the Case.
-- 27 Oct 2011	MF	R11457	121	Failed testing. Extend to include call to ip_PoliceRemoveSatisfiedEvents for rows with a STATE of R1 or RX.
-- 09 Dec 2011	MF	S20212	122	This is an extension to SQA19915. When checking Policing of the same CaseId has not been started under a 
--					different SPID, ensure that you exclude the actual Policing row currently about to be Policed as it may already
--					have a SPID value from a previously failed process.
-- 21 Dec 2011	MF	R11729	123	Revisit of RFC11457. When the Event is being inserted into #TEMPCASEEVENT make sure the DATEDUESAVED value is also 
--					carried over.
-- 07 Feb 2012	MF	R11908	124	Policing rows that are left unprocessed on the queue should also have their BATCHNO cleared out.
-- 15 Feb 2012	MF	R11941	125	This is an extension to SQA19915. If the Policing row is being processed immediately then Policing does not need to 
--					check if there are other processes running. This will avoid the problem where opening an Action is processed immediately
--					but an Event date (e.g. Priority date) Policing has been sent through to the Policing Server.
-- 26 Feb 2012	MF	S20377	126	Action column is not defined as nvarchar  in #TEMPCASEEVENT
-- 27 Feb 2012	MF	S20363	127	Revisit of RFC11457. When the Event is being inserted into #TEMPCASEEVENT make sure the OCCURREDFLAG value is also 
--					carried over.
-- 11 Apr 2012	MF	R12161	128	Database level errors (such as caused by a constraint) are not being correctly captured so they can be saved in POLICINGERRORS.
-- 19 Apr 2012	MF	R12199	129	Extension to RFC 12128. Ensure the STATE value of "CD" is also considered against #TEMPOPENACTION to cause the CriteriaNo to be calculated.
-- 10 May 2012	MF	R12262	130	When responsible name for an Event is defined on a different Action to the one used to calculate the Event, the responsible name is not 
--					being picked up.
-- 01 Jun 2012	MF	R12372	131	Ensure CASEEVENT row that has just occurred gets the correct CreatedByCriteria set.
-- 04 Jun 2012	MF	S19252	131	Provide a site control to enable Events that may recalculate after they have occurred to be triggered as a result of changes to the
--					governing date.
-- 18 Jun 2012	MF	R12424	132	An Event that is a candidate to be deleted that did not exist prior to the commencement of Policing should not be removed from the temporary
--					table if it is referenced to Not Exist by another Event. It should then be marked to be Deleted so that it will trigger the other Event.
-- 19 Feb 2012	MF	R13240	133	Policing rows waiting to be processed are blocking each other. Open Action requests are processed before Event requests however if requests from
--					different users are found then they are processed separately in time order. Where an Event request has been entered by one user and then an Action
--					request is raised by a different user then the two requests block each other. The Action requests are to take precedence.
-- 26 Jun 2012	MF	R12201	134	Alerts that are directed to a recipient based on rules stored against the Alert are to actually generate
--					an Alert row for each recipient that can be determined. These rows will exist in the #TEMPALERT table and will  be copied
--					to the ALERT table. Needed to add IMPORTANCELEVEL to #TEMPALERT in order to carry across to new Alert.
-- 27 Feb 2013	MF	R13230	135	During testing found a duplicate key error inserting into POLICINGERRORS.
-- 05 Apr 2013	MF	R13383	136	Revisit of RFC11092 to ensure the change of STATE to 'D1' takes precedence over some other conditions.
-- 28 May 2013	DL	R10030	137	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 06 Jun 2013	MF	S21404	138	Events flagged with SUPPRESSCALCULATION are to not have their due date calculated.
-- 13 Jun 2013	MF	R13570	139	Take care not to write a duplicate row into POLICINGERRORS
-- 19 Jul 2013	MF	R13081	140	The LOGTRANSACTIONNO from POLICING requests raised by Law Update Changes is to carry through for Policing to use. This will allows changes to 
--					CaseEvents to be tracked back to the law update changes.
-- 30 Aug 2013	MF	S21584	141	A very large negative EventNo of 9 digits is causing an overflow error.
-- 05 Sep 2013	MF	R13744	142	Event that should be marked for Deletion is not. The Event is being retained because it is referenced in a Not Exists rule of another Event
--					however its STATE should be getting set to D1.
-- 23 Jan 2014	MF	R13693	143	If Policing is not being run with the UPDATE option on then reminders to be sent by email
--					must not have a reminder date in the future.
-- 05 Sep 2014	MF	R39157	144	POLICING.RECALCEVENTDATE when set to 1 should take precedence over the Site Control 'Policing Recalculates Event'.
-- 14 Oct 2014	DL	R39102	145	Use service broker instead of OLE Automation to run the command asynchronoulsly
-- 19 Nov 2014	MF	R40815	146	An Event that has been deleted but did not previously exists should still have its STATE changed to D if it is used as a Not Exists comparison 
--					rule on another Event.  Currently the STATE is being changed to D1 which will fail to trigger the other Event.
-- 12 Dec 2014	MF	R40815	144	Further work on RFC40815. To avoid a loop occurring within the configured rules the STATE should only be set to D if it has not previously
--					been set to D to trigger the calculation of other Cases.
-- 07 Jan 2015	MF	R43200	145	When "Policing On Hold Reset" sitecontrol is used, it should not be blocked by warning in the POLICINGERRORS table for
--					the Message like "Due date rule for this Event exists for more than 1 Action....".
-- 06 Jan 2015	MF	R43118	146	Introduce the POLICING.EMAILFLAG to control whether reminders may be emailed for Policing Requests where SYSGENERATEDFLAG=0.
-- 09 Jan 2014	MF	R41513	147	Events triggered to recalculate the due date (Type of Request = 6) should also consider Events that are flagged with RECALCEVENTDATE=1
--					if the Site Control 'Policing Recalculates Event' is set to TRUE and passed as parameter @pbRecalcEventDate.
-- 19 Feb 2015	MF	R44921 	148	When checking if an Event being processed belongs to other Open Actions, ensure that the cycle for the CaseEvent is considered against the OpenAction.
-- 10 Jun 2015	MF	R45361	149	Cater for requests to distribute Prior Art across the extended Case family determined from RelatedCases. The potential for large volumes of Cases
--					that can be impacted has required this to run as a separate asynchronous process from the triggering activity.
-- 19 Jun 2015	MF	R46257	150	Clear out the variable @dtUntilDate when Police Continuously is running so as to cater for the system date changing.
-- 04 Dec 2015	MF	R55253	151	Clear the SPIDINPROGRESS column of POLICING when ONHOLDFLAG=2 and there has been no activity for more than the specified time period.
-- 11 Apr 2016	MF	R60302	152	When opening an action, carry the criteriano/eventno that is requesting the action to open.  This can then be used in reporting an error if a 
--					criteriano cannot be found for the Action.
-- 13 May 2016	MF	R61527	153	When inserting a row into PROCESSREQUEST to indicate that Police Continuously is running, also check that te Police Continuously site control is set.
-- 18 May 2016	MF	R61781	154	When Policing detects a looping error when a non case specific request is being processed (e.g. Law Update recalculation), it will now generate a 
--					separate POLICING row for each Case in error to leave on the queue which will also be linked to the Error.
-- 04 Jul 2016	MF	R63439	155	Consider the run date and time (SCHEDULEDDATETIME) on all POlICING rows where SYSGENERATEDFLAG=1.
-- 22 Nov 2016	MF	69970	156	Policing of a specific batch identified by @pnBatchNo is not occurring because of outstanding Law Update recalculations.
-- 24 Jan 2017	SF	DR21394	157 	Use alternative method to identify running continuous policing processes
-- 15 Mar 2017	MF	70049	158	Allow Renewal Status to be separately specified to be updated by an Event.
-- 06 Jun 2017	MF	71573	159	Some Police Immediately tasks are being left unprocessed. This may be happening if a Policing request for Prior Art to be propagated has been raised
--					against the same Case earlier than the request being left on the queue.
-- 03 Aug 2017	MF	71939	160	When two scheduled policing jobs start at exactly the same time, the system is throwing a duplicate key error on the insert into POLICINGLOG.
-- 21 Aug 2017	MF	72214	161	When Police Immediately is processing a specific BATCHNO, ensure that Policing rows being processed are for the same user.  This is to safeguard the
--					possibility that two different users have managed to create POLICING requests with the same BATCHNO.
-- 19 Sep 2017	MF	72463	162	Policing continuously was failing with an invalid query.  A comment had been inserted which caused a closing bracket that was appended to be treated as a comment.
-- 19 Dec 2017	MF	73121	163	The "Policing On Hold Reset" should also apply when the ONHOLDFLAG is equal to 4 and there are no POLICINGERRORS for the case.  A Deadlock may have occurred multiple times
--					resulting in the Policing request being left on the queue.
-- 07 Nov 2018	MF	DR-45442 162	RECALCEVENTDATE flag to be considered for system generated Policing request against specific CASEID.
-- 14 Nov 2018  AV	DR-45358 165	Date conversion errors when creating cases and opening names in Chinese DB
-- 10 Apr 2019	DL	DR-47863 166 	Error opening new action
-- 12 Jun 2019	MF	DR-49537 167	Increase the number of retry attempts and the wait time when the process is the victim of a deadlock error.  Also lower the deadlock priority to 
--					make this process the preferred victim.
-- 18 Jun 2019	DL	DR-49441 168	Provide more information in the Error Log Message of the Policing Dashboard
-- 08 Jul 2019	MF	DR-50117 169	Ensure @ErrorCode is tested before allowing processing to continue. This may have allowed a Constraint
--					error inserting POLICINGERRORS row.
-- 29 Nov 2019	MF	DR-54681 170	Problems caused when an Event exists against multiple Actions. Each TEMPCASEEVENT records the ACTION the Event exists under.  This ACTION was being 
--					changed at times and as a result caused another TEMPCASEEVENT row to be inserted for that same ACTION resulting in exponential growth of TEMPCASEEVENT.
--					The ACTION should not have been changed.
-- 06 Jan 2020	BS	DR-55556 171	Audit Log Transaction Number generation code copied from ip_PoliceUpdateDataBase to ipu_Policing so that it will not miss Log Transaction Number 
--					and will help to back-track/troubleshoot error that happens before ip_PoliceUpdateDataBase. 
--					Also, @pnSessionTransNo parameter to ip_PoliceUpdateDataBase logic modified for Policing Continuously to work properly after this audit changes. 
-- 19 May 2020	DL	DR-58943 172	Ability to enter up to 3 characters for Number type code via client server	
-- 26 May 2020	BS	DR-53425 173	Added SPID and SPIDSTART columns to PolicingLog table

-- User Defined Errors
-- ===================
-- 	-1	No entry in POLICING table
--	-2	Policing terminated due to suspected loop

set nocount on
set DEADLOCK_PRIORITY -1
SET DATEFORMAT mdy	-- SQA9375 Added this when found problem with Adjustment of date

-- Create a temporary table to load the POLICING rows that are being processed for system generated requests.
	CREATE TABLE #TEMPPOLICING (
            DATEENTERED          datetime	NOT NULL,
            POLICINGSEQNO        int 		NOT NULL,
            ACTION               nvarchar(2) 	collate database_default NULL,
            EVENTNO              int		NULL,
            CASEID               int		NULL,
            CRITERIANO           int		NULL,
            CYCLE                smallint	NULL,
            TYPEOFREQUEST        smallint	NULL,
            COUNTRYFLAGS         int		NULL,
            FLAGSETON            decimal(1,0)	NULL,
            SQLUSER              nvarchar(255)	collate database_default NULL,
	    PROCESSED		 bit		NULL,
	    IDENTITYID		 int		NULL,
	    ADHOCNAMENO		 int		NULL,
	    ADHOCDATECREATED	 datetime	NULL,
	    RECALCEVENTDATE	 bit		NULL
            )

-- Create a temporary table to load the POLICING rows that are being processed for system generated requests.
	CREATE TABLE #TEMPPOLICINGREQUEST (
            POLICINGSEQNO        int 		identity(0,1),
	    CASEID		 int		NULL,
            EVENTNO              int		NULL,
            CYCLE                smallint	NULL,
            TYPEOFREQUEST        smallint	NULL,
	    CRITERIANO		 int		NULL,
            SQLUSER              nvarchar(255)	collate database_default NULL,
	    IDENTITYID		 int		NULL
            )


-- Create a temporary table to load the Status details of the Case.  This information may be updated
-- as the Case progresses.  The Status controls

	create table #TEMPCASES (
            CASEID               int		NOT NULL,
            STATUSCODE           int            NULL,
            RENEWALSTATUS        int            NULL,
	    REPORTTOTHIRDPARTY   decimal(1,0)	NULL,
            PREDECESSORID        int            NULL,
	    ACTION		 nvarchar(2)	collate database_default NULL,
	    EVENTNO		 int		NULL,
	    CYCLE		 smallint	NULL,
            CASETYPE             nchar(1)	collate database_default NULL,
            PROPERTYTYPE         nchar(1)	collate database_default NULL,
            COUNTRYCODE          nvarchar(3)	collate database_default NULL,
            CASECATEGORY         nvarchar(2)	collate database_default NULL,
            SUBTYPE              nvarchar(2)	collate database_default NULL,
            BASIS                nvarchar(2)	collate database_default NULL,
            REGISTEREDUSERS      nchar(1)	collate database_default NULL,
            LOCALCLIENTFLAG      decimal(1,0)	NULL,
            EXAMTYPE             int		NULL,
            RENEWALTYPE          int		NULL,
            INSTRUCTIONSLOADED   tinyint	NULL,
	    ERRORFOUND           bit            NULL,
	    RENEWALACTION	 nvarchar(2)	collate database_default NULL,
	    RENEWALEVENTNO	 int		NULL,
	    RENEWALCYCLE	 smallint	NULL,
	    RECALCULATEPTA	 bit		default(0),
	    IPODELAY 		 int		default(0),
	    APPLICANTDELAY 	 int		default(0),
            USERID               nvarchar(255)  collate database_default NULL,
	    IDENTITYID		 int		NULL,
	    CASESEQUENCENO	 int		identity(1,1),
	    OFFICEID		 int		NULL,
            OLDSTATUSCODE        int            NULL,	--SQA18736
            OLDRENEWALSTATUS     int            NULL,	--SQA18736
	    CASELOGSTAMP	 datetime	NULL,	--RFC10929
	    PROPERTYLOGSTAMP	 datetime	NULL	--RFC10929
	)

	/* The index includes STATUSCODE, RENEWALSTATUS and     */
	/* ERRORFOUND. These columns are often required so	*/
	/* by including them in the index the select will run	*/
	/* faster as it will get everything it needs from the	*/
	/* index.						*/

	CREATE INDEX XPKTEMPCASES ON #TEMPCASES
 	(
        	CASEID,
		STATUSCODE,
		RENEWALSTATUS,
		ERRORFOUND
 	)


	/* This index is required to improve the performance	*/
	/* of extracting the standing instructions by Case.	*/

	CREATE UNIQUE INDEX XAK1TEMPCASES ON #TEMPCASES
 	(
        	CASEID,
		PROPERTYTYPE,
		COUNTRYCODE,
		INSTRUCTIONSLOADED,
		CASESEQUENCENO
 	)

-- Create a temporary table to load the Standing Instructions for a Case.  Standing Instructions are determined
-- from a reasonably complex hierarchy and are used throughout Policing in a number of places so it is 
-- more efficient to calculate the specific Standing Instructions applying to Case just once.

	create table #TEMPCASEINSTRUCTIONS (
		CASEID			int		NOT NULL, 
		INSTRUCTIONTYPE		nvarchar(3)	collate database_default NOT NULL,
		COMPOSITECODE		nchar(33) 	collate database_default NULL,	--SQA13161
		INSTRUCTIONCODE 	smallint	NULL,
		PERIOD1TYPE		nchar(1) 	collate database_default NULL,
		PERIOD1AMT		smallint	NULL,
		PERIOD2TYPE		nchar(1) 	collate database_default NULL,
		PERIOD2AMT		smallint	NULL,
		PERIOD3TYPE		nchar(1) 	collate database_default NULL,
		PERIOD3AMT		smallint	NULL,
		ADJUSTMENT		nvarchar(4)	collate database_default NULL,
		ADJUSTDAY		tinyint		NULL,
		ADJUSTSTARTMONTH	tinyint		NULL,
		ADJUSTDAYOFWEEK		tinyint		NULL,
		ADJUSTTODATE		datetime	NULL
	)

	CREATE CLUSTERED INDEX XPKTEMPCASEINSTRUCTIONS ON #TEMPCASEINSTRUCTIONS
 	(
        	CASEID,
		INSTRUCTIONTYPE
 	)

-- Create a temporary table to be loaded with Open Action details.
-- The temporary table will also contain the ncharacteristics of the Case used to determine the Criteria.  This 
-- CASE information is redundant to improve overall performance.

	create table #TEMPOPENACTION (
            CASEID               int		NOT NULL,
            ACTION               nvarchar(2)	collate database_default NOT NULL,
            CYCLE                smallint	NOT NULL,
            LASTEVENT            int		NULL,
            CRITERIANO           int		NULL,
            NEWCRITERIANO        int		NULL,
            DATEFORACT           datetime	NULL,
            NEXTDUEDATE          datetime	NULL,
            POLICEEVENTS         decimal(1,0)	NULL,
            STATUSCODE           smallint	NULL,
            STATUSDESC           nvarchar(50)	collate database_default NULL,
            OPENINGCRITERIANO    int		NULL,
            OPENINGEVENTNO       int		NULL,
            OPENINGCYCLE         smallint	NULL,
            CLOSINGCRITERIANO    int		NULL,
            CLOSINGEVENTNO       int		NULL,
            CLOSINGCYCLE         smallint	NULL,
            DATEENTERED          datetime	NULL,
            DATEUPDATED          datetime	NULL,
            CASETYPE             nchar(1)	collate database_default NULL,
            PROPERTYTYPE         nchar(1)	collate database_default NULL,
            COUNTRYCODE          nvarchar(3)	collate database_default NULL,
            CASECATEGORY         nvarchar(2)	collate database_default NULL,
            SUBTYPE              nvarchar(2)	collate database_default NULL,
            BASIS                nvarchar(2)	collate database_default NULL,
            REGISTEREDUSERS      nchar(1)	collate database_default NULL,
            LOCALCLIENTFLAG      decimal(1,0)	NULL,
            EXAMTYPE             int		NULL,
            RENEWALTYPE          int		NULL,
	    CASEOFFICEID	 int		NULL,
            USERID               nvarchar(255)  collate database_default NULL,
            [STATE]              nvarchar(2)	collate database_default NULL,	/* C-Calculate, C1-Calculation Done, E-Error	*/
	    IDENTITYID		 int		NULL
	)

	CREATE CLUSTERED INDEX XPKTEMPOPENACTION ON #TEMPOPENACTION
 	(
        	CASEID,
		ACTION,
		CYCLE
 	)


	CREATE INDEX XIE1TEMPOPENACTION ON #TEMPOPENACTION
	 (
	        ACTION,
		COUNTRYCODE,
		PROPERTYTYPE,
		DATEFORACT,
		CASETYPE,
		CASECATEGORY,
		SUBTYPE,
		BASIS,
		REGISTEREDUSERS,
		LOCALCLIENTFLAG,
		EXAMTYPE,
		RENEWALTYPE
	 )


	CREATE INDEX XIE2TEMPOPENACTION ON #TEMPOPENACTION
	 (
	        CASEID
	 )
-- Create a temporary table to be loaded with Case Event details.

	CREATE TABLE #TEMPCASEEVENT (
            CASEID               int		NOT NULL,
            DISPLAYSEQUENCE      smallint	NULL,
            EVENTNO              int		NOT NULL,
            CYCLE                smallint	NOT NULL,
            OLDEVENTDATE         datetime	NULL,
            OLDEVENTDUEDATE      datetime	NULL,
            DATEREMIND           datetime	NULL,
            DATEDUESAVED         decimal(1,0)	NULL,
            OCCURREDFLAG         decimal(1,0)	NULL,
            CREATEDBYACTION      nvarchar(2)	collate database_default NULL,
            CREATEDBYCRITERIA    int		NULL,
            ENTEREDDEADLINE      smallint	NULL,
            PERIODTYPE           nchar(1)	collate database_default NULL,
            DOCUMENTNO           smallint	NULL,
            DOCSREQUIRED         smallint	NULL,
            DOCSRECEIVED         smallint	NULL,
            USEMESSAGE2FLAG      decimal(1,0)	NULL,
	    SUPPRESSREMINDERS    decimal(1,0)   NULL,
	    OVERRIDELETTER       int            NULL,
            GOVERNINGEVENTNO     int		NULL,
            [STATE]              nvarchar(2) 	collate database_default NOT NULL,-- C=calculate; I=insert; D=delete
            ADJUSTMENT           nvarchar(4) 	collate database_default NULL,	 -- any adjustment to be made to the date
            IMPORTANCELEVEL      nvarchar(2)	collate database_default NULL,
            WHICHDUEDATE         nchar(1) 	collate database_default NULL,
            COMPAREBOOLEAN       decimal(1,0) 	NULL,
            CHECKCOUNTRYFLAG     int		NULL,
            SAVEDUEDATE          smallint	NULL,
            STATUSCODE           smallint	NULL,
            RENEWALSTATUS        smallint	NULL,
            SPECIALFUNCTION      nchar(1)	collate database_default NULL,
            INITIALFEE           int		NULL,
            PAYFEECODE           nchar(1)	collate database_default NULL,
            CREATEACTION         nvarchar(2)	collate database_default NULL,
            STATUSDESC           nvarchar(50) 	collate database_default NULL,
            CLOSEACTION          nvarchar(2)	collate database_default NULL,
            RELATIVECYCLE        smallint	NULL,
            INSTRUCTIONTYPE      nvarchar(3)	collate database_default NULL,
            FLAGNUMBER           smallint	NULL,
            SETTHIRDPARTYON      decimal(1,0)	NULL,
            COUNTRYCODE          nvarchar(3)	collate database_default NULL,	-- used to get Due Date rule
            NEWEVENTDATE         datetime 	NULL,
            NEWEVENTDUEDATE      datetime 	NULL,
            NEWDATEREMIND        datetime 	NULL,
            USEDINCALCULATION	 nchar(1)	collate database_default NULL,	-- if Y then removing the row will trigger recalculations	
            LOOPCOUNT		 smallint	NULL,
	    REMINDERTOSEND	 smallint	NULL,
            UPDATEFROMPARENT	 tinyint	NULL,
            PARENTEVENTDATE      datetime       NULL,
            USERID		 nvarchar(255)	collate database_default NULL,
            EVENTUPDATEDMANUALLY tinyint        NULL,	-- 15/08/2001 MF  Flag to indicate that the Event was updated outside of Policing
            CRITERIANO           int            NULL,	-- 20/09/2001 MF  Holds the CriteriaNo the Event is attached to
            ACTION               nvarchar(2)	collate database_default NULL,	-- 20/09/2001 MF  Holds the Action the Event is attached to
	    UNIQUEID		 int		identity(10,10), -- Increment by 10 so can use to add as Miliseconds; SQA7858 also start from 10
	    ESTIMATEFLAG         decimal(1,0)	NULL,	-- SQA7367
            EXTENDPERIOD         smallint	NULL,	-- SQA7532
            EXTENDPERIODTYPE     nchar(1)	collate database_default NULL,	-- SQA7532
            INITIALFEE2          int		NULL,	-- SQA7627
            PAYFEECODE2          nchar(1)	collate database_default NULL,	-- SQA7627
            ESTIMATEFLAG2        decimal(1,0)   NULL,
	    PTADELAY		 smallint	NULL,	-- SQA8260
	    IDENTITYID		 int		NULL,
	    SETTHIRDPARTYOFF	 bit		NULL,
            CHANGENAMETYPE	 nvarchar(3)	collate database_default NULL,
            COPYFROMNAMETYPE     nvarchar(3)	collate database_default NULL,
            COPYTONAMETYPE       nvarchar(3)	collate database_default NULL,
            DELCOPYFROMNAME      bit		NULL,
	    DIRECTPAYFLAG	 bit		NULL,
	    DIRECTPAYFLAG2	 bit		NULL,
	    FROMCASEID		 int		NULL,
	    LIVEFLAG		 bit		default(0),
	    RESPNAMENO		 int		NULL,
	    RESPNAMETYPE	 nvarchar(3)	collate database_default NULL,
	    LOADNUMBERTYPE	 nvarchar(3)	collate database_default NULL,	--SQA17773
	    PARENTNUMBER	 nvarchar(36)	collate database_default NULL,	--SQA17773
	    RECALCEVENTDATE	 bit		NULL,	-- SQA19252
	    SUPPRESSCALCULATION  bit		NULL,	-- SQA21404
	    DELETEDPREVIOUSLY	 tinyint	NULL	-- RFC40815 Counter used to avoid continuously triggering an Event as deleted	
	)

	-- Moved STATE column outside of the 
	-- index as this is very dynamic column
	CREATE INDEX XPKTEMPCASEEVENT ON #TEMPCASEEVENT
 	(
        	CASEID,
		EVENTNO,
		CYCLE,
		UNIQUEID
 	)
 	INCLUDE (
		CREATEDBYCRITERIA,
 		[STATE],
		LIVEFLAG
 	)

	CREATE INDEX XPKTEMPCASEEVENT1 ON #TEMPCASEEVENT
 	(
        	[STATE],
        	CASEID,
		EVENTNO,
		CYCLE,
		UNIQUEID
 	)

	-- SQA18756 Index created on recommendation of SQLServer Index Tuner
	CREATE INDEX XPKTEMPCASEEVENT2 ON #TEMPCASEEVENT
 	(
        	[STATE],
		NEWEVENTDATE,
        	CASEID,
		EVENTNO,
		CYCLE
 	)

	-- SQA18756 Index created on recommendation of SQLServer Index Tuner
	CREATE INDEX XPKTEMPCASEEVENT3 ON #TEMPCASEEVENT
	(
		CASEID, 
		EVENTNO, 
		CYCLE, 
		[STATE],
		NEWEVENTDATE, 
		USERID, 
		IDENTITYID, 
		OCCURREDFLAG
	) 
	INCLUDE 
	(
		OLDEVENTDATE,
		NEWEVENTDUEDATE,
		LIVEFLAG
	)

-- Create a temporary to hold Case Events details
-- that are candidates to automatically update
	CREATE TABLE #TEMPUPDATECANDIDATE (
		CASEID			int		NOT NULL,
		EVENTNO			int		NOT NULL,
		CYCLE			smallint	NOT NULL,
		NEWEVENTDATE		datetime	NOT NULL,
		CURRENTSTATE		nvarchar(2) 	collate database_default NOT NULL,
		CRITERIANO		int		NULL,
		FROMCASEID		int		NULL
		)

-- Create a temporary table to be used to store Employee Reminders.  This interim table is used so that
-- a unique MESSAGESEQ can be generated when it is loaded into the EmployeeReminder table and also enables 
-- Email and Task versions of the reminders to be generated.

	CREATE TABLE #TEMPEMPLOYEEREMINDER (
        	NAMENO			int 		NULL,	-- SQA14201 allow nulls
	        UNIQUEID		int 		identity (0,10),
	        CASEID			int 		NULL,
	        REFERENCE		nvarchar(20)	collate database_default NULL,
	        EVENTNO			int		NULL,
	        CYCLENO			smallint	NULL,
		CRITERIANO		int		NULL,	-- 08/11/2002 MF added for Hyperlink in reminders
	        DUEDATE			datetime	NULL,
	        REMINDERDATE		datetime	NULL,
	        READFLAG		decimal(1,0)	NULL,
	        SOURCE			decimal(1,0)	NULL,
	        HOLDUNTILDATE		datetime	NULL,
	        DATEUPDATED		datetime	NULL,
	        SHORTMESSAGE		nvarchar(254)	collate database_default NULL,
	        LONGMESSAGE		nvarchar(max)	collate database_default NULL,
	        SEQUENCENO		int		NOT NULL,
		EVENTDESCRIPTION	nvarchar(100)	collate database_default NULL,
		SENDELECTRONICALLY	tinyint		NULL,
		EMAILSUBJECT		nvarchar(100)	collate database_default NULL,
		ACTION			nvarchar(2)	collate database_default NULL,
		PROPERTYTYPE		nchar(1)	collate database_default NULL,
		COUNTRYCODE		nvarchar(3)	collate database_default NULL,
		RELATIONSHIP		nvarchar(3)	collate database_default NULL,
		ALERTNAMENO		int		NULL,
		FROMEMPLOYEENO		int		NULL,
		ALERTSEQ		datetime	NULL
	)

	CREATE  UNIQUE CLUSTERED INDEX XAK1EMPLOYEEREMINDER ON #TEMPEMPLOYEEREMINDER
	(
		NAMENO		ASC,
		CASEID		ASC,
		EVENTNO		ASC,
		CYCLENO		ASC,
		REFERENCE	ASC,
		SEQUENCENO	ASC,
		UNIQUEID	ASC
	)

	-- Index used to find messages that will reqiure
	-- extracted data to be embedded.
	CREATE  INDEX XIE1EMPLOYEEREMINDER ON #TEMPEMPLOYEEREMINDER
	(
		SHORTMESSAGE	ASC
	)

-- Create a temporary table to load the ALERTs to be processed

	CREATE TABLE #TEMPALERT (
	        EMPLOYEENO           	int 		NOT NULL,
	        ALERTSEQ             	datetime	NOT NULL,
	        CASEID               	int		NULL,
	        ALERTMESSAGE         	nvarchar(max)	collate database_default NULL,
	        REFERENCE            	nvarchar(20)	collate database_default NULL,
	        ALERTDATE            	datetime	NULL,
	        DUEDATE              	datetime	NULL,
	        DATEOCCURRED         	datetime	NULL,
	        OCCURREDFLAG         	decimal(1,0)	NULL,
	        DELETEDATE           	datetime	NULL,
	        STOPREMINDERSDATE    	datetime	NULL,
	        MONTHLYFREQUENCY     	smallint	NULL,
	        MONTHSLEAD           	smallint	NULL,
	        DAILYFREQUENCY       	smallint	NULL,
	        DAYSLEAD             	smallint	NULL,
	        SEQUENCENO           	int		NOT NULL,
		SENDELECTRONICALLY	tinyint		NULL,
		EMAILSUBJECT		nvarchar(100)	collate database_default NULL,
		NAMENO			int		NULL, 
		EMPLOYEEFLAG		bit		NULL,
		SIGNATORYFLAG		bit		NULL,
		CRITICALFLAG		bit		NULL,
	        NAMETYPE            	nvarchar(3)	collate database_default NULL,
	        RELATIONSHIP           	nvarchar(3)	collate database_default NULL,
		TRIGGEREVENTNO		int		NULL,
		EVENTNO			int		NULL,
		CYCLE			int		NULL,
		IMPORTANCELEVEL		int		NULL
 	)

-- Create a temporary table to load the Letters to be produced

 	CREATE TABLE #TEMPACTIVITYREQUEST (
	        CASEID               int NOT NULL,
	        UNIQUENO       	     int identity(0,10),
	        SQLUSER              nvarchar(255) 	collate database_default NOT NULL,
	        PROGRAMID            nvarchar(8) 	collate database_default NULL,
	        ACTION               nvarchar(2) 	collate database_default NULL,
	        EVENTNO              int NULL,
	        CYCLE                smallint NULL,
	        LETTERNO             smallint NULL,
	        COVERINGLETTERNO     smallint NULL,
	        HOLDFLAG             decimal(1,0) NULL,
	        LETTERDATE           datetime NULL,
	        DELIVERYID           smallint NULL,
	        ACTIVITYTYPE         smallint NULL,
	        ACTIVITYCODE         int NULL,
	        PROCESSED            decimal(1,0) NULL,
		IDENTITYID	     int NULL,
		WRITETONAME          int NULL,		--SQA10151
		BILLPERCENTAGE       decimal(5,2) NULL	--SQA10151
 	)

-- Create a temporary table to be used to store POLICING errors detected during execution

	CREATE TABLE #TEMPPOLICINGERRORS (
            ERRORSEQNO           smallint identity,
            CASEID               int NULL,
	    CRITERIANO           int NULL,
	    EVENTNO              int NULL,
	    CYCLENO              smallint NULL,
	    MESSAGE              nvarchar(254) 		collate database_default NULL
	)

-- Create a temporary table to be used to distribute Prior Art across an extended family of Cases

	CREATE TABLE #TEMPCASESEARCHRESULT (
		FAMILYPRIORARTID	int		NULL,
		CASEID			int		NOT NULL,
		PRIORARTID		int		NOT NULL,
		STATUS			int		NULL,
		UPDATEDDATE		datetime	NOT NULL,
		CASEFIRSTLINKEDTO	int		NULL,
		CASELISTPRIORARTID	int		NULL,
		NAMEPRIORARTID		int		NULL,
		ISCASERELATIONSHIP	bit		NULL
	)


DECLARE		@dtStartDateTime	datetime,
		@dtLockDateTime		datetime,
		@ErrorCode		int,
		@nRetry			int,
		@SaveErrorCode		int,	-- SQA 7049
		@TranCountStart 	int,
		@nRowsToGet		int,
		@nPolicingCount		int,
		@nLoopCount		int,
		@nMainCount		int,
		@bLawRecalc		bit,
		@bFirstTimeFlag		bit,
		@bContinue		bit,
		@bCalculateAction	bit,
		@bStatusUpdates		bit,
		@bCloseActions		bit,
		@bOpenActions		bit,
		@bClearEvents		bit,
		@bUpdateEvents		bit,
		@bSatisfyEvents		bit,
		@bTerminateBatch	bit,
		@bCriteriaUpdated	bit,
		@bPTARecalc		bit,
		@bOnHoldReset		bit,	--SQA11433
		@bLoadMessageTable	bit,
		@bPolicingConcurrency	bit,	--SQA13724
		@bSuppressReminders	bit,	--SQA18215
		@bCheckDocumentCase	bit,	--SQA12548
		@bUniqueTimeRequired	bit,	--SQA16690
		@nWaitPeriod		int,	--SQA16991
		@nUpdateQueueWait	int,	--SQA17298 time in seconds to wait before rechecking if process is free to update database
		@nRowCount		int,
		@nAlerts		int,
		@nCountStateC		int,
		@nCountStateI		int,
		@nCountStateI1		int,
		@nCountStateD		int,
		@nCountStateR		int,
		@nCountStateRX		int,
		@nCountStateR1		int,
		@nCountParentUpdate	int,
		@nCountPTAUpdate	int,
		@nReminderCount		int,
		@nUpdateCandidates	int,
		@nPrePolicingReminders	int,
		@nErrors		int,
		@nSendEmail		int,
		@sInsertString		nvarchar(4000),
		@sSelectString		nvarchar(4000),
		@sSQLString		nvarchar(4000),
		@sTimeStamp		nvarchar(24),
		@bHexNumber		varbinary(128),
		@nEDEBatchNo		int,
		@nTransNo		int

If  @pnDebugFlag>0
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_Policing-Commence Processing',0,1,@sTimeStamp ) with NOWAIT
End


-- The following variables are used to hold the contents of the POLICING
-- row whose key was passed as parameters
DECLARE		@sPolicingName		nvarchar(40),
		@nSysGeneratedFlag	decimal(1,0),
		@nOnHoldFlag		decimal(1,0),
		@sOfficeId		nvarchar(254),
		@sErrorMessage		nvarchar(max),
		@sIRN			nvarchar(30),
		@sPropertyType		nchar(1),
		@sCountryCode		nvarchar(3),
		@dtDateOfAct		datetime,
		@sAction		nvarchar(2),
		@nEventNo		int,
		@sNameType		nvarchar(3),
		@nNameNo		int,
		@sCaseType		nchar(1),
		@sCaseCategory		nvarchar(2),
		@sSubtype		nvarchar(2),
		@dtFromDate		datetime,
		@dtUntilDate		datetime,
		@nNoOfDays		smallint,
		@dtLetterDate		datetime,
		@nCriticalOnlyFlag	decimal(1,0),
		@nUpdateFlag		decimal(1,0),
		@nReminderFlag		decimal(1,0),
		@nAdhocFlag		decimal(1,0),
		@nCriteriaFlag		decimal(1,0),
		@nDueDateFlag		decimal(1,0),
		@nCalcReminderFlag	decimal(1,0),
		@nExcludeProperty	decimal(1,0),
		@nExcludeCountry	decimal(1,0),
		@nExcludeAction		decimal(1,0),
		@sEmployeeNo		int,
		@nCaseid		int,
		@nCriteriano		int,
		@nCycle			smallint,
		@nTypeOfRequest		smallint,
		@nCountryFlags		int,
		@nFlagSetOn		decimal(1,0),
		@sSqlUser		nvarchar(30),
		@nDueDateOnlyflag	decimal(1,0),
		@nLetterFlag		decimal(1,0),
		@nDueDateRange		smallint,
		@nLetterAfterDays	smallint,
		@bRecalcEventDate	bit,
		@bDocumentsRequired	bit,
		@bErrorInserted		bit,
		@bEmailFlag		bit

------------------------------------
-- Variables for trapping any errors
-- raised during database update.
------------------------------------
declare		@nErrorSeverity		int
declare		@nErrorState		int

-- RFC9296
-- Variables required to start background process
Declare		@nObject		int,
		@nObjectExist		tinyint,
		@sCommand		varchar(255)

-- Initialise the errorcode and then set it after each SQL Statement

Set 	@ErrorCode 	 =0
Set	@bTerminateBatch =0
Set	@nUpdateQueueWait=0
Set	@bErrorInserted  =0
Set	@nPrePolicingReminders=0

If  @psPolicingMessageTable is not null
and @ErrorCode=0
Begin
	Set @bLoadMessageTable=1

	Set @sSQLString="
	insert into "+@psPolicingMessageTable+"(MESSAGE) values('Policing commenced')"

	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
If @pnSessionTransNo<>0
and @ErrorCode=0
Begin
	Set @nTransNo=@pnSessionTransNo

	--------------------------------------------------------------
	-- Load a common area accessible from the database server with
	-- the UserIdentityId the supplied TransactionNo and BatchNo.
	-- This will be used by the audit logs.
	--------------------------------------------------------------

	Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4)+ 
			substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
			substring(cast(isnull(@pnEDEBatchNo,'') as varbinary),1,4)
	SET CONTEXT_INFO @bHexNumber
End
Else If @ErrorCode=0
Begin
	-- A separate database transaction will be used to insert the TRANSACTIONINFO
	-- row to ensure the lock on the database is kept to a minimum as this table
	-- will be used extensively by other processes.

	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Allocate a transaction id that can be accessed by the audit logs
	-- for inclusion.
	
	-- When inserting a row into TRANSACTIONINFO default the TRANSACTIONREASONNO
	-- TRANSACTIONMESSAGENO if a valid row exists in the associated table.
	Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE,BATCHNO, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO) 
			Select getdate(),@pnEDEBatchNo, R.TRANSACTIONREASONNO, M.TRANSACTIONMESSAGENO
			from (select 1 as COL1) A
			left join TRANSACTIONREASON  R on (R.TRANSACTIONREASONNO=-1)
			left join TRANSACTIONMESSAGE M on (M.TRANSACTIONMESSAGENO=2)
			Set @nTransNo=SCOPE_IDENTITY()"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nTransNo		int	OUTPUT,
				  @pnEDEBatchNo		int',
				  @nTransNo    =@nTransNo	OUTPUT,
				  @pnEDEBatchNo=@pnEDEBatchNo

	--------------------------------------------------------------
	-- Load a common area accessible from the database server with
	-- the UserIdentityId and the TransactionNo just generated.
	-- This will be used by the audit logs.
	--------------------------------------------------------------

	Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4)+ 
			substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
			substring(cast(isnull(@pnEDEBatchNo,'') as varbinary),1,4)
	SET CONTEXT_INFO @bHexNumber

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End
End

--Update the POLICING table so that tU_POLICING_Audit is triggered and updates the audit details
--This helps to create audit detail which can be back tracked to POLICING for errors early in policing
If @pdtPolicingDateEntered is not null and @pnPolicingSeqNo is not null and @ErrorCode=0
Begin
	Set @sSQLString="
	Update POLICING
	Set DATEENTERED=DATEENTERED
	Where DATEENTERED=@pdtPolicingDateEntered
	and POLICINGSEQNO=@pnPolicingSeqNo"

	exec @ErrorCode=sp_executesql @sSQLString, 
				N'@pdtPolicingDateEntered	datetime,
					@pnPolicingSeqNo		int',
					@pdtPolicingDateEntered=@pdtPolicingDateEntered,
					@pnPolicingSeqNo=@pnPolicingSeqNo
End
Else If @pnBatchNo is not null and @ErrorCode=0
Begin
	Set @sSQLString="
	Update POLICING
	Set DATEENTERED=DATEENTERED
	Where BATCHNO=@pnBatchNo"

	exec @ErrorCode=sp_executesql @sSQLString, 
				N'@pnBatchNo		int',
				@pnBatchNo=@pnBatchNo
End
Else If @ErrorCode=0
Begin 
	Set @sSQLString="
	Update POLICING
	Set DATEENTERED=DATEENTERED
	Where SYSGENERATEDFLAG=1"

	exec @ErrorCode=sp_executesql @sSQLString
End 

-- Read the POLICING table for the parameters passed and save the contents in variables.  These will be
-- used to determine what should be policed and what type of processing is required.
-- If no parameter for the POLICING table is passed then this indicates that stored procedure is being
-- called by the Policing Server and multiple Policing rows are to be processed at one time.
if @pdtPolicingDateEntered is not null
and @ErrorCode=0
Begin
	Select	@sPolicingName		= POLICINGNAME,
		@nSysGeneratedFlag	= isnull(SYSGENERATEDFLAG,0),	-- 15/08/2001 MF  Initialise the value if null
		@nOnHoldFlag		= isnull(ONHOLDFLAG,0),		-- 28/08/2001 MF  Initialise the value if null
		@sIRN			= IRN,
		@sOfficeId		= replace(CASEOFFICEID,';',','),	-- semicolons to be replaced by comma
		@sPropertyType		= PROPERTYTYPE,
		@sCountryCode		= COUNTRYCODE,
		@dtDateOfAct		= DATEOFACT,
		@sAction		= ACTION,
		@nEventNo		= EVENTNO,
		@sNameType		= NAMETYPE,
		@nNameNo		= NAMENO, 
		@sCaseType		= CASETYPE,
		@sCaseCategory		= CASECATEGORY, 
		@sSubtype		= SUBTYPE,
		@dtFromDate		= FROMDATE, 
		@dtUntilDate		= UNTILDATE,
		@nNoOfDays		= NOOFDAYS, 
		@dtLetterDate		= LETTERDATE,
		@nCriticalOnlyFlag	= isnull(CRITICALONLYFLAG,0),	-- 28/08/2001 MF  Initialise the value if null
		@nUpdateFlag		= isnull(UPDATEFLAG,0),		-- 28/08/2001 MF  Initialise the value if null
		@nReminderFlag		= isnull(REMINDERFLAG,0),	-- 28/08/2001 MF  Initialise the value if null
		@bEmailFlag		= isnull(EMAILFLAG,1),		
		@nAdhocFlag		= CASE WHEN(ADHOCNAMENO is not null)
						THEN 1
						ELSE isnull(ADHOCFLAG,0)
					  END,
		@nCriteriaFlag		= isnull(CRITERIAFLAG,0),	-- 28/08/2001 MF  Initialise the value if null
		@nDueDateFlag		= isnull(DUEDATEFLAG,0),	-- 28/08/2001 MF  Initialise the value if null
		@nCalcReminderFlag	= isnull(CALCREMINDERFLAG,0),	-- 28/08/2001 MF  Initialise the value if null
		@nExcludeProperty	= isnull(EXCLUDEPROPERTY,0),	-- 28/08/2001 MF  Initialise the value if null
		@nExcludeCountry	= isnull(EXCLUDECOUNTRY,0),	-- 28/08/2001 MF  Initialise the value if null
		@nExcludeAction		= isnull(EXCLUDEACTION,0),	-- 28/08/2001 MF  Initialise the value if null
		@sEmployeeNo		= EMPLOYEENO,
		@nCaseid		= CASEID,
		@nCriteriano		= CRITERIANO,
		@nCycle			= CYCLE,
		@nTypeOfRequest		= TYPEOFREQUEST,
		@nCountryFlags		= COUNTRYFLAGS,
		@nFlagSetOn		= FLAGSETON,
		@sSqlUser		= SQLUSER, 
		@nDueDateOnlyflag	= isnull(DUEDATEONLYFLAG,0),	-- 28/08/2001 MF  Initialise the value if null
		@nLetterFlag		= isnull(LETTERFLAG,0),		-- 28/08/2001 MF  Initialise the value if null
		@nDueDateRange		= SC1.COLINTEGER,
		@nLetterAfterDays	= SC2.COLINTEGER,
		@nLoopCount		= isnull(SC3.COLINTEGER,25),
		@nRowsToGet		= isnull(SC4.COLINTEGER,0),
		@bPolicingConcurrency	= isnull(SC5.COLBOOLEAN,0),
		@bRecalcEventDate	= CASE WHEN(RECALCEVENTDATE=1) THEN 1 ELSE coalesce(SC6.COLBOOLEAN,0) END -- RFC39157
	From 	POLICING
	left join
		SITECONTROL SC1	on (SC1.CONTROLID='Due Date Range')
	left join
		SITECONTROL SC2 on (SC2.CONTROLID='LETTERSAFTERDAYS')
	left join
		SITECONTROL SC3 on (SC3.CONTROLID='Policing Loop Count')
	left join
		SITECONTROL SC4 on (SC4.CONTROLID='Policing Rows To Get')
	left join
		SITECONTROL SC5 on (SC5.CONTROLID='Policing Concurrency Control')
	left join
		SITECONTROL SC6 on (SC6.CONTROLID='Policing Recalculates Event')--SQA19252
	Where	DATEENTERED	= @pdtPolicingDateEntered
	and	POLICINGSEQNO	= @pnPolicingSeqNo

	Select  @ErrorCode=@@Error,
		@nRowCount=@@Rowcount

	If  @nRowCount=0
	and @ErrorCode=0
	Begin
		set @ErrorCode=-1
	End
End
Else If @ErrorCode=0
Begin
	-- SiteControls required when Policing is running in server mode
	Select	@nLoopCount      = SC.COLINTEGER,
		@nRowsToGet      = isnull(SC4.COLINTEGER,0),
		@bOnHoldReset    = isnull(SC5.COLBOOLEAN,0),
		@bPolicingConcurrency= isnull(SC6.COLBOOLEAN,0),
		@nWaitPeriod = isnull(SC7.COLINTEGER,0),
		@bSuppressReminders	= isnull(SC8.COLBOOLEAN,0),
		@bRecalcEventDate	= isnull(SC9.COLBOOLEAN,0),
		@bEmailFlag		= 1	-- Defaulted on for system generated Policing.
	From 	SITECONTROL SC
	left join
		SITECONTROL SC4 on (SC4.CONTROLID='Policing Rows To Get')
	left join
		SITECONTROL SC5 on (SC5.CONTROLID='Policing On Hold Reset')	--SQA11433
	left join
		SITECONTROL SC6 on (SC6.CONTROLID='Policing Concurrency Control')
	left join
		SITECONTROL SC7 on (SC7.CONTROLID='Policing Retry After Minutes')
	left join
		SITECONTROL SC8 on (SC8.CONTROLID='Policing Suppress Reminders')--SQA18215
	left join
		SITECONTROL SC9 on (SC9.CONTROLID='Policing Recalculates Event')--SQA19252
	Where	SC.CONTROLID='Policing Loop Count'

	Select  @ErrorCode=@@Error,
		@nRowCount=@@Rowcount

	If  @nRowCount=0
	and @ErrorCode=0
	Begin
		Set @nLoopCount=25
		Set @nRowsToGet=0
		Set @nUpdateQueueWait=0
	End
End
------------------------------------------------------------------------------
-- A sitecontrol is used to indicate if the rows inserted into ACTIVITYREQUEST
-- must have a unique WHENREQUESTED column.  This is to maintain backward
-- compatibility with earlier versions before ACTIVITYID was added to the
-- ACTIVITYREQUEST table. Once firms have modified their letter templates
-- they can set the site control OFF which will provide a performance boost
-- by avoiding the need to reset the WHENREQUESTED column.
------------------------------------------------------------------------------
If  @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bUniqueTimeRequired=S.COLBOOLEAN
	from SITECONTROL S
	where S.CONTROLID='Activity Time Must Be Unique'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@bUniqueTimeRequired			bit	OUTPUT',
					  @bUniqueTimeRequired=@bUniqueTimeRequired	OUTPUT
End

------------------------------------------------------------------------------
-- SQA17298
-- If Policing is being run as a Policing Server job or a specific Policing
-- Request, then check to see if the database updates are to be queued to 
-- ensure a single database connection (SPID) is processed at the one time.
-- The following site control when set to a value higher than 0 indicates that
-- sequential processing will occur. The actual value will be the number of 
-- seconds (maximum 59) that the process will wait before rechecking the queue.
-- Police Immediately requests will not use this feature.
------------------------------------------------------------------------------
If @ErrorCode=0
and (@nSysGeneratedFlag=0					-- Policing request batch
 or (@pdtPolicingDateEntered is null and @pnBatchNo is null))	-- Policing server

Begin
	Set @sSQLString="
	Select	@nUpdateQueueWait= isnull(SC.COLINTEGER,0)
	From 	SITECONTROL SC
	Where	SC.CONTROLID='Policing Update After Seconds'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nUpdateQueueWait	int		OUTPUT',
					  @nUpdateQueueWait=@nUpdateQueueWait	OUTPUT
				
	-- Limit the maximum delay to 59 seconds	  
	If @nUpdateQueueWait>59
		Set @nUpdateQueueWait=59
End

-- SQA16424
-- A parameter may now override the system
-- default for the number of rows to process.

If @pnBatchSize is not null
	set @nRowsToGet=@pnBatchSize

If isnull(@pnUserIdentityId,'')=''
and @ErrorCode=0
Begin
	------------------------------------
	-- Attempt to get the UserIdentityId
	-- associated with the SPID
	------------------------------------
	select	@pnUserIdentityId=CASE WHEN(substring(context_info,1,4) <>0x0000000) THEN cast(substring(context_info,1,4)  as int) END
	from master.dbo.sysprocesses
	where spid=@@SPID
	and(substring(context_info,1, 4)<>0x0000000)

	Set @ErrorCode=@@ERROR

	If isnull(@pnUserIdentityId,'')=''
	and @ErrorCode=0
	Begin
		--------------------------------------
		-- If still no UserIdentityId then get
		-- the one linked to current login
		--------------------------------------
		Select @pnUserIdentityId=min(IDENTITYID)
		from USERIDENTITY
		where LOGINID=substring(SYSTEM_USER,1,50)

		Set @ErrorCode=@@ERROR
	End
End

If  @bLoadMessageTable=1
and @ErrorCode=0
Begin
	Set @sSQLString="
	insert into "+@psPolicingMessageTable+"(MESSAGE) values('Options loaded')"

	exec sp_executesql @sSQLString
End

-- The following label is used as a point to restart processing from if the system is set
-- up for continuous Policing (SiteControl = 'Police Continuous').  This only occurs when
-- the procedure is being run from the Policing Server and only restarts if unprocessed rows
-- are found in the POLICING table.

CommenceProcessing:
	if @pdtPolicingDateEntered is null
	begin
		Set @nReminderFlag   = 0
		Set @nLetterFlag     = 0
		Set @nUpdateFlag     = 0
		Set @nAdhocFlag      = 0
	end

	Set @dtStartDateTime = null
	Set @bFirstTimeFlag  = 1
	Set @nMainCount      = 0
	Set @bCriteriaUpdated= 0
	Set @nPolicingCount  = 0

-- At the commencement of the processing a row will be inserted into the POLICINGLOG table only
-- when the procedure is not system generated.

If  @ErrorCode = 0
and @nSysGeneratedFlag=0
Begin
	Set @TranCountStart  = @@TranCount
	Set @dtStartDateTime = getdate()
	Set @nRetry=0

	While @nRetry=0
	and   @ErrorCode=0
	Begin
		BEGIN TRY

		BEGIN TRANSACTION

		insert into POLICINGLOG (STARTDATETIME, USERNAME, POLICINGNAME, FROMDATE, NOOFDAYS, FINISHDATETIME, 
					 OPENACTIONCOUNT, CASEEVENTCOUNT, REMINDERCOUNT, LETTERCOUNT, PROGRAMVERSION, IDENTITYID, SPID, SPIDSTART)
		select @dtStartDateTime, SYSTEM_USER,  @sPolicingName, isnull(@dtFromDate, convert(nvarchar, getdate(),112)), 
		       @nNoOfDays, NULL, 0,0,0,0,0,@pnUserIdentityId, @@SPID, (SELECT last_request_start_time FROM dbo.fn_GetSysActiveSessions()  WHERE session_id=@@SPID)

		Set @ErrorCode=@@Error

		-- Commit or Rollback the transaction

		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
		
		Set @nRetry=-1

		END TRY

		BEGIN CATCH
			------------------------------------------
			-- If a duplicate key error has occurred
			-- then increment the key and make 
			-- another attempt at the insert.
			------------------------------------------
			If ERROR_NUMBER() in (2601, 2627)
			Begin
				Set @dtStartDateTime=DATEADD(ms,3,@dtStartDateTime)
				Set @ErrorCode=0
			End
			Else Begin
				Set @nRetry=-1
			End
			
			If XACT_STATE()<>0
				Rollback Transaction
		
			If @nRetry<0
			Begin
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
	End --While Loop
End

-- Calculate the FromDate, UntilDate and LetterDate if they have not been explicitly entered.

If  @dtFromDate is NULL
and @ErrorCode=0
Begin
	If @nNoOfDays is Null
	Or @nNoOfDays > -1
	Begin
		-- Set the FromDate to the current system date if the NoOfDays is either NULL or a positive number
		Set @dtFromDate = convert(nvarchar,getdate(),112)
	End
	Else Begin
		-- If the NoOfDays is negative then set the UntilDate to the current system date and subtract 
		-- the NoOfDays from it to get the FromDate
		Set @dtUntilDate = convert(nvarchar,getdate(),112)
		Set @dtFromDate  = dateadd(day, @nNoOfDays, @dtUntilDate)
	End
End

-- If the UntilDate has not been set then add the NoOfDays less 1 to the FromDate
If  @dtUntilDate is NULL
and @ErrorCode=0
Begin
	If  @nNoOfDays is not Null
	Begin
		Set @dtUntilDate = dateadd(day, isnull(@nNoOfDays-1, 0), @dtFromDate)
	End
	Else If @dtFromDate>getdate()
	Begin
		Set @dtUntilDate = @dtFromDate
	End
	Else Begin
		Set @dtUntilDate = convert(nvarchar,getdate(),112)
	End
	
End

-- If the LetterDate has not been set then add the LetterAfterDays from SiteControl to the UntilDate
-- to get the date to use on any generated letters
If  @dtLetterDate is NULL
and @ErrorCode=0
Begin
	Set @dtLetterDate = dateadd(day, isnull(@nLetterAfterDays, 0), @dtUntilDate)
End

If  @pnDebugFlag>0
and @ErrorCode=0
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_Policing-Initialisation Complete',0,1,@sTimeStamp ) with NOWAIT

	If  @bLoadMessageTable=1
	Begin
		Set @sSQLString="
		insert into "+@psPolicingMessageTable+"(MESSAGE) values('Initialisation Complete')"
	
		exec sp_executesql @sSQLString
	End
End

-- Getting the Cases and Events to be initialy Policed will depend upon the parameters of the 
-- Policing table.  There are 4 separate approaches :
--  1.	For Recalculations called from Policing Request
--	===============================================
--	Get the Cases that match the selection criteria followed by the Openactions for those Cases then
--	return the CaseEvents to be recalculated.
--
--  2.	For Non Recalculation Policing called from Policing Request
--	===========================================================
--	Get the CaseEvents to be policed within the selection criteria, then get the Cases and Openactions.
--
--  3.	For Policing a Case with a Type of Request (called from Cases and Import Journal)
--	=================================================================================
--	Get the Case and OpenActions then get the CaseEvents depending on the TypeOfRequest and parameters
--	passed.
--
--  4.	For Policing Multiple Cases with Type of Request (called from Policing Server)
--	==============================================================================
--	Get the Cases and OpenActions for the Policing rows and then get the CaseEvents depending on the
--	TypeOfRequest and parameters.
--

IF @ErrorCode=0
Begin
	If  (@nCriteriaFlag    =1 OR @nDueDateFlag=1 OR @nCalcReminderFlag=1)
	and  @nSysGeneratedFlag=0
	Begin
		--------------------------------------------------
--  		For Recalculations called from Policing Request
		--================================================
		-- Get the Cases that match the selection criteria followed by the OpenActions

		set transaction isolation level read uncommitted

		execute @ErrorCode = dbo.ip_PoliceGetOpenActions
							@nRowCount	OUTPUT,
							@pnDebugFlag,
							@sIRN,
							@sOfficeId,
							@sPropertyType,
							@sCountryCode,
							@dtDateOfAct,
							@sAction,
							@nEventNo,
							@sNameType,
							@nNameNo,
							@sCaseType,
							@sCaseCategory,
							@sSubtype,
							@nExcludeProperty,
							@nExcludeCountry,
							@nExcludeAction,
							@nCaseid,
							@nTypeOfRequest,
							@nCriteriaFlag,
							@nDueDateFlag,
							@nCalcReminderFlag,
							@bRecalcEventDate,
							@pnUserIdentityId

--		If the Reminder Date only is being recalculated then get the Events to be recalculated.

		If   @nCalcReminderFlag= 1
		and (@nCriteriaFlag    = 0 or @nCriteriaFlag is null)
		and (@nDueDateFlag     = 0 or @nDueDateFlag  is null)
		and  @nRowCount        > 0  -- Only do this if there are OpenAction rows
		and  @ErrorCode        = 0
		Begin
			execute @ErrorCode = dbo.ip_PoliceGetEventReminderToRecalculate
							@nRowCount	OUTPUT,
							@pnDebugFlag,
							@nEventNo
			Set @nCountStateR1=@nRowCount
		End

--		If Policing Request has specified a particular Event to recalculate then
--		load the TEMPCASEEVENT table with this Event.

		Else If (@nEventNo is not NULL OR @bRecalcEventDate=1)
		     and @nRowCount > 0	-- Only do this if there are OpenAction rows
		     and @ErrorCode = 0
		Begin
			execute @ErrorCode = dbo.ip_PoliceGetEventToRecalculate
							@nRowCount	OUTPUT,
							@pnDebugFlag,
							@nEventNo,
							@bRecalcEventDate
		End

		-- If the concurrency control option is on then a POLICING row will be 
		-- inserted for each Case being processed.  This will act as a queuing
		-- control mechanism to stop requests against the same Case from other
		-- users being processed.
		If  @ErrorCode=0
		and @bPolicingConcurrency=1
		and @nUpdateFlag=1
		Begin
			execute @ErrorCode = dbo.ip_PoliceLockCasesInProgress
							@pdtLockDateTime	=@dtLockDateTime	OUTPUT,
							@pnDebugFlag		=@pnDebugFlag,
							@psAction		=@sAction,
							@pnEventNo		=@nEventNo,
							@pnUserIdentityId	=@pnUserIdentityId,
							@pbRecalcFlag		=1
		End
	End
	Else If @nSysGeneratedFlag=0
	Begin
		--------------------------------------------------------------
--  		For Non Recalculation Policing called from Policing Request
		--============================================================
		-- Get the CaseEvents to be policed for the selection criteria, 
		-- then get the Cases and OpenActions.

		set transaction isolation level read uncommitted

		execute @ErrorCode = dbo.ip_PoliceGetEvents
							@nRowCount	OUTPUT,
							@pnDebugFlag,
							@sIRN,
							@sOfficeId,
							@sPropertyType,
							@sCountryCode,
							@dtDateOfAct,
							@sAction,
							@nEventNo,
							@sNameType,
							@nNameNo,
							@sCaseType,
							@sCaseCategory,
							@sSubtype,
							@nExcludeProperty,
							@nExcludeCountry,
							@nExcludeAction,
							@nCaseid,
							@nTypeOfRequest,
							@dtFromDate,
							@dtUntilDate,
							@nDueDateRange

		-- Generate reminders associated with Events

		if  @nReminderFlag=1
		and @ErrorCode=0
		Begin
			execute @ErrorCode = dbo.ip_PoliceInsertReminders 
						@dtFromDate, 
						@dtUntilDate, 
						@pnDebugFlag,
						@nPrePolicingReminders OUTPUT
		End

		-- If the concurrency control option is on then a POLICING row will be 
		-- inserted for each Case being processed.  This will act as a queuing
		-- control mechanism to stop requests against the same Case from other
		-- users being processed.

		If  @ErrorCode=0
		and @bPolicingConcurrency=1
		and @nUpdateFlag=1
		Begin
			execute @ErrorCode = dbo.ip_PoliceLockCasesInProgress
							@pdtLockDateTime	=@dtLockDateTime	OUTPUT,
							@pnDebugFlag		=@pnDebugFlag,
							@psAction		=@sAction,
							@pnEventNo		=@nEventNo,
							@pnUserIdentityId	=@pnUserIdentityId,
							@pbRecalcFlag		=0
		End
	End
	Else If @nSysGeneratedFlag=1
	Begin
		-------------------------------
		-- Turn the flag on that allows
		-- the CriteriaNo for an Action
		-- to be determined.
		--------------------------------
		Set @nCriteriaFlag=1
		--------------------------------------------------------------------------
--		For Policing a specific Case with a Type of Request (called from Cases)
		--========================================================================
--		Copy the Policing row into a temporary table

		set transaction isolation level read uncommitted

		set @sInsertString="
		insert into #TEMPPOLICING (	DATEENTERED, POLICINGSEQNO, ACTION, EVENTNO, CASEID, CRITERIANO, 
						CYCLE, TYPEOFREQUEST, COUNTRYFLAGS, FLAGSETON, SQLUSER, IDENTITYID,
						ADHOCNAMENO, ADHOCDATECREATED )
		select	P.DATEENTERED, P.POLICINGSEQNO, P.ACTION, P.EVENTNO, P.CASEID, P.CRITERIANO, 
			P.CYCLE, P.TYPEOFREQUEST, P.COUNTRYFLAGS, P.FLAGSETON, P.SQLUSER, P.IDENTITYID,
			P.ADHOCNAMENO, P.ADHOCDATECREATED
		from	POLICING P
		-- Police immediately request is delayed if there is an outstanding
		-- earlier Policing request for the same Case unless the Police
		-- immediately request is to open or repolice an Action
		left join POLICING P1	on (P1.CASEID=P.CASEID
					and P1.SYSGENERATEDFLAG=1
					and P1.DATEENTERED<@pdtPolicingDateEntered
					and P1.TYPEOFREQUEST not in (7,8,9)	-- Certain requests will not block the current one 
					and P.TYPEOFREQUEST  not in (1))
		where	P.DATEENTERED   = @pdtPolicingDateEntered
		and	P.POLICINGSEQNO = @pnPolicingSeqNo
		and	P1.CASEID is null"	-- Ensure no earlier request exists

		Execute @ErrorCode = sp_executesql @sInsertString, 
					N'@pdtPolicingDateEntered	datetime, 
					  @pnPolicingSeqNo	 	int',
					  @pdtPolicingDateEntered, 
					  @pnPolicingSeqNo

		Set @nRowCount=@@Rowcount
	End
	Else Begin
		-------------------------------
		-- Turn the flag on that allows
		-- the CriteriaNo for an Action
		-- to be determined.
		--------------------------------
		Set @nCriteriaFlag=1

		Set @nRetry=5

		While @nRetry>0
		and @ErrorCode=0
		Begin
			Begin Try
				Set @nPolicingCount=0
				---------------------------------------
				-- Law Update Recalculations (SQA14297)
				---====================================
				-- Get the first system generated Policing request that does not specify a 
				-- Case and is available to be processed.  This will provide the parameters
				-- to expand the request into individual Case specific Policing requests.

				Select @TranCountStart = @@TranCount
				BEGIN TRANSACTION

				Select	TOP 1
					@sOfficeId		= replace(CASEOFFICEID,';',','),	-- semicolons to be replaced by comma
					@nSysGeneratedFlag	= isnull(SYSGENERATEDFLAG,0),
					@sPropertyType		= PROPERTYTYPE,
					@sCountryCode		= COUNTRYCODE,
					@dtDateOfAct		= DATEOFACT,
					@sAction		= ACTION,
					@nEventNo		= EVENTNO,
					@sNameType		= NAMETYPE,
					@nNameNo		= NAMENO, 
					@sCaseType		= CASETYPE,
					@sCaseCategory		= CASECATEGORY, 
					@sSubtype		= SUBTYPE,
					@nCriteriaFlag		= isnull(CRITERIAFLAG,1),
					@nUpdateFlag		= 1,
					@nDueDateFlag		= isnull(DUEDATEFLAG,0),
					@nCalcReminderFlag	= isnull(CALCREMINDERFLAG,0),
					@nLetterFlag		= isnull(LETTERFLAG,0),	
					@nExcludeProperty	= isnull(EXCLUDEPROPERTY,0),
					@nExcludeCountry	= isnull(EXCLUDECOUNTRY,0),
					@nExcludeAction		= isnull(EXCLUDEACTION,0),
					@sEmployeeNo		= EMPLOYEENO,
					@nCriteriano		= CRITERIANO,
					@nCycle			= CYCLE,
					@nTypeOfRequest		= TYPEOFREQUEST,
					@bRecalcEventDate	= isnull(RECALCEVENTDATE,0),
					@sSqlUser		= SQLUSER, 
					@pdtPolicingDateEntered = DATEENTERED,
					@pnPolicingSeqNo	= POLICINGSEQNO,
					@pnSessionTransNo	= isnull(SC.LOGTRANSACTIONNO,P.LOGTRANSACTIONNO),	-- RFC13081
					@bLawRecalc		= 1
				From 	POLICING P with (UPDLOCK)
				left join SITECONTROL SC on (SC.CONTROLID='CPA Law Update Service')
				Where	P.SYSGENERATEDFLAG=1
				and	isnull(P.ONHOLDFLAG,0)=0
				and	P.CASEID is null
				and	P.ADHOCNAMENO is null		--SQA16720
				and	P.ADHOCDATECREATED is null	--SQA16720
				and	isnull(P.SCHEDULEDDATETIME,getdate())<=getdate()
				and    (P.BATCHNO=@pnBatchNo OR (P.BATCHNO is null and @pnBatchNo is null))
				ORDER BY P.DATEENTERED, P.POLICINGSEQNO

				Select	@ErrorCode=@@Error,
					@nPolicingCount=@@Rowcount

				-- Lock down the Policing row so it is not grabbed by 
				-- another Policing process
				If @ErrorCode=@@Error
				and @nPolicingCount>0
				Begin
					Set @sSQLString="
					Update POLICING
					Set ONHOLDFLAG=1
					Where DATEENTERED=@pdtPolicingDateEntered
					and POLICINGSEQNO=@pnPolicingSeqNo"

					exec @ErrorCode=sp_executesql @sSQLString, 
								N'@pdtPolicingDateEntered	datetime,
								  @pnPolicingSeqNo		int',
								  @pdtPolicingDateEntered=@pdtPolicingDateEntered,
								  @pnPolicingSeqNo=@pnPolicingSeqNo
				End

				If @@TranCount > @TranCountStart
				Begin
					If @ErrorCode = 0
						COMMIT TRANSACTION
					Else
						ROLLBACK TRANSACTION
				End
			
				-- Terminate the WHILE loop
				Set @nRetry=-1
			End Try

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
				
				If @nRetry<0
					Set @ErrorCode=ERROR_NUMBER()
				else 
					-- Wait for 5 seconds before making the next attempt
					WAITFOR DELAY '00:00:05'
					
				If XACT_STATE()<>0
					Rollback Transaction
			END CATCH
		End -- While loop

		-- Load the Policing temporary table which will be used later to delete
		-- the live Policing row once it has successfully been processed.
		If @ErrorCode=0
		and @nPolicingCount>0
		Begin
			Set @sSQLString="
			insert into #TEMPPOLICING (	DATEENTERED, POLICINGSEQNO, ACTION, EVENTNO, CASEID, CRITERIANO, 
							CYCLE, TYPEOFREQUEST, COUNTRYFLAGS, FLAGSETON, SQLUSER, IDENTITYID,
							ADHOCNAMENO, ADHOCDATECREATED )
			select	P.DATEENTERED, P.POLICINGSEQNO, P.ACTION, P.EVENTNO, P.CASEID, P.CRITERIANO,
				P.CYCLE, P.TYPEOFREQUEST, P.COUNTRYFLAGS, P.FLAGSETON, P.SQLUSER, P.IDENTITYID,
				P.ADHOCNAMENO, P.ADHOCDATECREATED
			from POLICING P
			where DATEENTERED=@pdtPolicingDateEntered
			and POLICINGSEQNO=@pnPolicingSeqNo"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pdtPolicingDateEntered	datetime,
						  @pnPolicingSeqNo		int',
						  @pdtPolicingDateEntered=@pdtPolicingDateEntered,
						  @pnPolicingSeqNo=@pnPolicingSeqNo
		End

		----------------------------------------------------
		-- Get the details to be recalculated as a result of 
		-- the law change
		----------------------------------------------------

		If @ErrorCode=0
		and @nPolicingCount>0
		Begin
			set transaction isolation level read uncommitted

			execute @ErrorCode = dbo.ip_PoliceGetOpenActions
							@nRowCount	OUTPUT,
							@pnDebugFlag,
							@sIRN,
							@sOfficeId,
							@sPropertyType,
							@sCountryCode,
							@dtDateOfAct,
							@sAction,
							@nEventNo,
							@sNameType,
							@nNameNo,
							@sCaseType,
							@sCaseCategory,
							@sSubtype,
							@nExcludeProperty,
							@nExcludeCountry,
							@nExcludeAction,
							@nCaseid,
							@nTypeOfRequest,
							@nCriteriaFlag,
							@nDueDateFlag,
							@nCalcReminderFlag,
							@bRecalcEventDate,
							@pnUserIdentityId,
							@sSqlUser

			-- If Policing Request has specified a particular Event to recalculate then
			-- load the TEMPCASEEVENT table with this Event.

			If (@nEventNo is not NULL OR @bRecalcEventDate=1)
			and @nRowCount > 0	-- Only do this if there are OpenAction rows
			and @ErrorCode = 0
			Begin
				execute @ErrorCode = dbo.ip_PoliceGetEventToRecalculate
								@nRowCount	OUTPUT,
								@pnDebugFlag,
								@nEventNo,
								@bRecalcEventDate
			End

			-- If the concurrency control option is on then a POLICING row will be 
			-- inserted for each Case being processed.  This will act as a queuing
			-- control mechanism to stop requests against the same Case from other
			-- users being processed.
			If  @ErrorCode=0
			and @bPolicingConcurrency=1
			and @nRowCount>0
			Begin
				execute @ErrorCode = dbo.ip_PoliceLockCasesInProgress
								@pdtLockDateTime	=@dtLockDateTime	OUTPUT,
								@pnDebugFlag		=@pnDebugFlag,
								@psAction		=@sAction,
								@pnEventNo		=@nEventNo,
								@pnUserIdentityId	=@pnUserIdentityId,
								@pbRecalcFlag		=1
			End
		End
		Else If @ErrorCode=0
		Begin
			Set @nRetry=5

			While @nRetry>0
			and @ErrorCode=0
			Begin
				Begin Try
					Set @nRowCount=0
					------------------------------------------------------------------------------
			--		For Policing Multiple Cases with Type of Request (called from Policing Server)
			--		==============================================================================
			--		Copy the Policing rows into a temporary table.

					Select @TranCountStart = @@TranCount
					BEGIN TRANSACTION

					If @nRowsToGet>0
					and @ErrorCode=0
					Begin
			--			Construct the Insert statement with the number of rows to return which is a user
			--			defined parameter.  Any Open Action requests for a Case must be processed before any
			--			other requests.

						set @sInsertString="
						insert into #TEMPPOLICING (	DATEENTERED, POLICINGSEQNO, ACTION, EVENTNO, CASEID, CRITERIANO, 
										CYCLE, TYPEOFREQUEST, COUNTRYFLAGS, FLAGSETON, SQLUSER, IDENTITYID,
										ADHOCNAMENO, ADHOCDATECREATED, RECALCEVENTDATE )
						select	TOP " + convert(nvarchar, @nRowsToGet) + " P.DATEENTERED, P.POLICINGSEQNO, P.ACTION, P.EVENTNO, P.CASEID, P.CRITERIANO, 
							P.CYCLE, P.TYPEOFREQUEST, P.COUNTRYFLAGS, P.FLAGSETON, P.SQLUSER, P.IDENTITYID,
							P.ADHOCNAMENO, P.ADHOCDATECREATED, P.RECALCEVENTDATE
						from POLICING P with (UPDLOCK)
						left join POLICINGERRORS E on (E.CASEID=P.CASEID
									   and P.ONHOLDFLAG=2)
						where	P.SYSGENERATEDFLAG=1
						and	 isnull(P.SCHEDULEDDATETIME,getdate())<=getdate()
						and    ((isnull(P.ONHOLDFLAG,0)=0 and @pnBatchNo is null)"
					
						If @nWaitPeriod>0
						Begin
						     Set @sInsertString=@sInsertString+"
						     OR (P.ONHOLDFLAG=2 and datediff(minute, P.DATEENTERED, getdate())>=@nWaitPeriod and @pnBatchNo is null) --SQA16033"
						End
					
						Set @sInsertString=@sInsertString+"
						     OR  (P.BATCHNO=@pnBatchNo and isnull(P.IDENTITYID,@pnUserIdentityId)=@pnUserIdentityId))
						and     E.CASEID is NULL -- no errors when ONHOLDFLAG=2
						and     P.TYPEOFREQUEST<>8 -- exclude as these requests are slow to process
						and    (P.TYPEOFREQUEST=1 
						     OR @pnBatchNo is not null -- not blocked by other requests
						     OR not exists(	select * from POLICING P1
									where P1.CASEID=P.CASEID
									and P1.TYPEOFREQUEST=1
									and P1.SYSGENERATEDFLAG=1
									and isnull(P1.SCHEDULEDDATETIME,getdate())<=getdate()
									and P.BATCHNO is null))
						-- if there are requests for the same Case that have already
						-- commenced processing then wait until those requests have been
						-- completed or placed on hold. This is to stop multiple requests 
						-- from the same user being split across multiple Policing threads
						and    (P.BATCHNO is not null				-- RFC11941 Police immediately requests do not have to wait
						     OR not exists
							(select 1 from POLICING P3
							 where P3.CASEID=P.CASEID
							 and isnull(P3.SCHEDULEDDATETIME,getdate())<=getdate()
							 and(P3.DATEENTERED<>P.DATEENTERED OR P3.POLICINGSEQNO<>P.POLICINGSEQNO)
							 and P3.SYSGENERATEDFLAG>0
							 and P3.SPIDINPROGRESS<>@@SPID  -- indicates it has been started on a different process
							 and P3.ONHOLDFLAG<>9))
						-- if multiple Users have issued a request against the same Case
						-- then process the Users one at a time in date of request sequence
						and    (P.BATCHNO is not null				-- Police immediately requests do not have to wait
						     OR not exists
							(select * from POLICING P2
							 where P2.CASEID=P.CASEID
							 and P2.SYSGENERATEDFLAG>0
							 and isnull(P2.SCHEDULEDDATETIME,getdate())<=getdate()
							 and(convert(nchar(23),P2.DATEENTERED,121)+
							     convert(nchar(30),isnull(P2.SQLUSER,''))+
							     convert(varchar,  isnull(P2.IDENTITYID,9999999)))
							   <(convert(nchar(23),P.DATEENTERED,121)+
							     convert(nchar(30),isnull(P.SQLUSER,''))+
							     convert(varchar,  isnull(P.IDENTITYID,9999999)))
							 and ((P.TYPEOFREQUEST=1 and P2.TYPEOFREQUEST=1) OR P.TYPEOFREQUEST>1)  -- RFC13240
							 and  isnull(P2.ONHOLDFLAG,0)<3
							 and (isnull(P2.SQLUSER,'')<>isnull(P.SQLUSER,'') 
							  OR (isnull(P2.IDENTITYID,9999999)<>isnull(P.IDENTITYID,9999999) and P2.SQLUSER=P.SQLUSER))))
						order by P.ONHOLDFLAG, P.DATEENTERED, P.POLICINGSEQNO"

						-- Now execute the dynamically created Insert.

						Execute @ErrorCode = sp_executesql @sInsertString,
										N'@pnBatchNo		int,
										  @pnUserIdentityId	int,
										  @nWaitPeriod		int',
										  @pnBatchNo		=@pnBatchNo,
										  @pnUserIdentityId	=@pnUserIdentityId,
										  @nWaitPeriod		=@nWaitPeriod

						Set @nRowCount=@@Rowcount
					End
					Else If @ErrorCode=0
					Begin 
			-- 			Get all of the eligible POLICING rows to be processed. Any Open Action requests for 
			--			a Case must be processed before any other requests.

						Set @sInsertString="
						insert into #TEMPPOLICING (	DATEENTERED, POLICINGSEQNO, ACTION, EVENTNO, CASEID, CRITERIANO, 
										CYCLE, TYPEOFREQUEST, COUNTRYFLAGS, FLAGSETON, SQLUSER, IDENTITYID,
										ADHOCNAMENO, ADHOCDATECREATED, RECALCEVENTDATE )
						select	P.DATEENTERED, P.POLICINGSEQNO, P.ACTION, P.EVENTNO, P.CASEID, P.CRITERIANO,
							P.CYCLE, P.TYPEOFREQUEST, P.COUNTRYFLAGS, P.FLAGSETON, P.SQLUSER, P.IDENTITYID,
							P.ADHOCNAMENO, P.ADHOCDATECREATED, P.RECALCEVENTDATE
						from POLICING P with (UPDLOCK)
						left join POLICINGERRORS E on (E.CASEID=P.CASEID
									   and P.ONHOLDFLAG=2)
						where	P.SYSGENERATEDFLAG=1
						and	 isnull(P.SCHEDULEDDATETIME,getdate())<=getdate()
						and    ((isnull(P.ONHOLDFLAG,0)=0 and @pnBatchNo is null)"
					
						If @nWaitPeriod>0
						Begin
						     Set @sInsertString=@sInsertString+"
						     OR (P.ONHOLDFLAG=2 and datediff(minute, P.DATEENTERED, getdate())>=@nWaitPeriod and @pnBatchNo is null) --SQA16033"
						End
					
						Set @sInsertString=@sInsertString+"
						     OR (P.BATCHNO=@pnBatchNo and isnull(P.IDENTITYID,@pnUserIdentityId)=@pnUserIdentityId))
						and     E.CASEID is NULL -- no errors when ONHOLDFLAG=2
						and     P.TYPEOFREQUEST<>8 -- exclude as these requests are slow to process
						and    (P.TYPEOFREQUEST = 1 
						     OR not exists(	select * from POLICING P1
									where P1.CASEID=P.CASEID
									and P1.TYPEOFREQUEST=1
									and P1.SYSGENERATEDFLAG=1
									and isnull(P1.SCHEDULEDDATETIME,getdate())<=getdate()
									and P.BATCHNO is null))
						-- if there are requests for the same Case that have already
						-- commenced processing then wait until those requests have been
						-- completed or placed on hold. This is to stop multiple requests 
						-- from the same user being split across multiple Policing threads
						and    (P.BATCHNO is not null				-- RFC11941 Police immediately requests do not have to wait
						     OR not exists
							(select 1 from POLICING P3
							 where P3.CASEID=P.CASEID
							 and(P3.DATEENTERED<>P.DATEENTERED OR P3.POLICINGSEQNO<>P.POLICINGSEQNO)
							 and P3.SYSGENERATEDFLAG>0
							 and isnull(P3.SCHEDULEDDATETIME,getdate())<=getdate()
							 and P3.SPIDINPROGRESS<>@@SPID  -- indicates it has been started on a different process
							 and P3.ONHOLDFLAG<>9))
						-- if multiple Users have issued a request against the same Case
						-- then process the Users one at a time in date of request sequence
						and    (P.BATCHNO is not null				-- Police immediately requests do not have to wait
						     OR not exists
							(select * from POLICING P2
							 where P2.CASEID=P.CASEID
							 and P2.SYSGENERATEDFLAG>0
							 and isnull(P2.SCHEDULEDDATETIME,getdate())<=getdate()
							 and(convert(nchar(23),P2.DATEENTERED,121)+
							     convert(nchar(30),isnull(P2.SQLUSER,''))+
							     convert(varchar,  isnull(P2.IDENTITYID,9999999)))
							   <(convert(nchar(23),P.DATEENTERED,121)+
							     convert(nchar(30),isnull(P.SQLUSER,''))+
							     convert(varchar,  isnull(P.IDENTITYID,9999999)))
							 and ((P.TYPEOFREQUEST=1 and P2.TYPEOFREQUEST=1) OR P.TYPEOFREQUEST>1)  -- RFC13240
							 and  isnull(P2.ONHOLDFLAG,0)<3
							 and (isnull(P2.SQLUSER,'')<>isnull(P.SQLUSER,'') 
							  OR (isnull(P2.IDENTITYID,9999999)<>isnull(P.IDENTITYID,9999999) and P2.SQLUSER=P.SQLUSER))))"

						Execute @ErrorCode = sp_executesql @sInsertString,
										N'@pnBatchNo		int,
										  @pnUserIdentityId	int,
										  @nWaitPeriod		int',
										  @pnBatchNo		=@pnBatchNo,
										  @pnUserIdentityId	=@pnUserIdentityId,
										  @nWaitPeriod		=@nWaitPeriod

						Set @nRowCount=@@Rowcount
					End

					------------------------------------------------------
					-- If some rows have been inserted into #TEMPPOLICING
					-- then if any have RECALCEVENTDATE set to 1 then we
					-- will process all of the requests 
					------------------------------------------------------
					If @nRowCount>0
					and @ErrorCode=0
					Begin
						If exists(select 1 from #TEMPPOLICING where RECALCEVENTDATE=1)
						Begin
							Set @bRecalcEventDate=1
						End
					End

					------------------------------------------------------------------------------
					-- If no Policing rows were ready to process then check to see if there
					-- are any rows with TYPEOFREQUEST=8.  These are potentially slow Policing
					-- requests and are quarantined to process when there are no other outstanding
					-- requests.
					------------------------------------------------------------------------------
					If @nRowCount=0
					and @pnBatchNo is null
					and @ErrorCode=0
					Begin
						Set @sInsertString="
						insert into #TEMPPOLICING (	DATEENTERED, POLICINGSEQNO, ACTION, EVENTNO, CASEID, CRITERIANO, 
										CYCLE, TYPEOFREQUEST, COUNTRYFLAGS, FLAGSETON, SQLUSER, IDENTITYID,
										ADHOCNAMENO, ADHOCDATECREATED )
						select	P.DATEENTERED, P.POLICINGSEQNO, P.ACTION, P.EVENTNO, P.CASEID, P.CRITERIANO,
							P.CYCLE, P.TYPEOFREQUEST, P.COUNTRYFLAGS, P.FLAGSETON, P.SQLUSER, P.IDENTITYID,
							P.ADHOCNAMENO, P.ADHOCDATECREATED
						from POLICING P with (UPDLOCK)
						left join POLICINGERRORS E on (E.CASEID=P.CASEID
									   and P.ONHOLDFLAG=2)
						where	P.SYSGENERATEDFLAG=1
						and	isnull(P.SCHEDULEDDATETIME,getdate())<=getdate()
						and	P.TYPEOFREQUEST=8
						and    ( isnull(P.ONHOLDFLAG,0)=0"
					
						If @nWaitPeriod>0
						Begin
						     Set @sInsertString=@sInsertString+"
								     OR (P.ONHOLDFLAG=2 and datediff(minute, P.LOGDATETIMESTAMP, getdate())>=@nWaitPeriod)"
						End
					
						Set @sInsertString=@sInsertString+")
						and     E.CASEID is NULL -- no errors when ONHOLDFLAG=2"

						Execute @ErrorCode = sp_executesql @sInsertString,
										N'@nWaitPeriod	int',
										  @nWaitPeriod=@nWaitPeriod

						Set @nRowCount=@@Rowcount
					End

					-- Create a TRANSACTION to update POLICING rows being processed to set their ONHOLDFLAG to 1 
					-- so that no other Policing process will pick up these rows while they are being processed.
					-- Only do this if there were actually rows inserted into the #TEMPPOLICING table.

					If  @nRowCount>0
					and @ErrorCode=0
					Begin
						-- Set the POLICING rows to be processed on HOLD so they won't be processed by another
						-- Policing process.  Do this by incrementing the ONHOLDFLAG by 2.  The next time Policing
						-- is run it will attempt to reprocess all POLICING rows with an ONHOLDFLAG of either 0 
						-- or 2.  This means if a row is left unprocessed a second attempt will automatically be
						-- made if there was no explainable error.
						Set @sSQLString="
						update POLICING
						set ONHOLDFLAG=isnull(ONHOLDFLAG,0)+2,
						    SPIDINPROGRESS=@@SPID,
						    @nAdhocFlag=CASE WHEN(P.ADHOCNAMENO is not null) THEN 1 ELSE @nAdhocFlag END
						from POLICING P
						join #TEMPPOLICING T	on (P.DATEENTERED  =T.DATEENTERED
									and P.POLICINGSEQNO=T.POLICINGSEQNO)
						where T.PROCESSED is null"

						Exec @ErrorCode=sp_executesql @sSQLString,
										N'@nAdhocFlag	decimal(1,0)	OUTPUT',
										  @nAdhocFlag=@nAdhocFlag	OUTPUT
					End
				
					If @@TranCount > @TranCountStart
					Begin
						If @ErrorCode = 0
							COMMIT TRANSACTION
						Else
							ROLLBACK TRANSACTION
					End

					-- Terminate the WHILE loop
					Set @nRetry=-1
				End Try

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
						
					If @nRetry<0
						Set @ErrorCode=ERROR_NUMBER()
					Else 
						-- Wait for 5 seconds before making the next attempt
						WAITFOR DELAY '00:00:05'
						
					If XACT_STATE()<>0
						Rollback Transaction
				END CATCH
			End -- While loop

			set transaction isolation level read uncommitted
		End
	End
End


-- When Policing Server is processing policing requests then get the Case,  OpenActions and CaseEvents
-- depending on the TypeOfRequest and parameters passed.

If (@nSysGeneratedFlag=1 OR @nSysGeneratedFlag is null)
and @nPolicingCount=0
and @ErrorCode=0
and @nRowCount>0
Begin
	execute @ErrorCode = dbo.ip_PoliceGetTypeOfRequest 
						@nRowCount	OUTPUT,
						@bPTARecalc	OUTPUT,
						@bRecalcEventDate,
						@pnDebugFlag

	-- SQA18215
	-- Reminder production may be suppressed
	-- by Site Control
	If @bSuppressReminders = 1
		set @nReminderFlag=0
	Else
	set	@nReminderFlag	=1
		
	set	@nLetterFlag	=1
	set	@nUpdateFlag	=1
End

If  @bLoadMessageTable=1
and @ErrorCode=0
Begin
	Set @sSQLString="
	insert into "+@psPolicingMessageTable+"(MESSAGE) values('Retrieve Standing Instructions')"

	exec sp_executesql @sSQLString
End

-- Get the Standing Instructions for the Case.  If the reminders are only
-- being recalculated then don't bother getting the standing instructions

If    @ErrorCode=0
and ((@nCalcReminderFlag=1 and @nDueDateFlag=1) OR isnull(@nCalcReminderFlag,0)=0)
and   @nRowCount>0
Begin
	execute @ErrorCode = dbo.ip_PoliceGetStandingInstructions @pnDebugFlag
End

If  @ErrorCode=0
and @nRowCount>0
Begin
	Set @bCalculateAction=0
	Set @sSQLString="
	Select @bCalculateActionOUT=1
	from #TEMPOPENACTION
	where [STATE]='C'"

	Execute @ErrorCode=sp_executesql @sSQLString, 
					N'@bCalculateActionOUT	bit OUTPUT',
					  @bCalculateActionOUT=@bCalculateAction OUTPUT
End

-- Loop through the #TEMPOPENACTION table while there are rows marked to be calculated (State = 'C')
-- or the FirstTimeFlag is set ON.
WHILE	@ErrorCode = 0
	and (@bFirstTimeFlag = 1 OR @bCalculateAction=1)
BEGIN
	If @ErrorCode=0
	Begin
		-- RFC11463
		If ISNULL(@bCalculateAction,0)=0
		Begin
			Set @nCriteriaFlag=1
		End
		-- If there are Open Actions to calculate
		Else if @bCalculateAction=1
		begin
			If  @bLoadMessageTable=1
			and @ErrorCode=0
			Begin
				-- Load Policing Message Table
				Set @sSQLString="
				insert into "+@psPolicingMessageTable+"(MESSAGE) values('Calculate Criteria')

				insert into "+@psPolicingMessageTable+"(MESSAGE)
				select C.IRN+' - '+isnull(VA.ACTIONNAME,A.ACTIONNAME)+'('+T.ACTION+'{'+convert(varchar,T.CYCLE)+'})'
				from #TEMPOPENACTION T
				join CASES C	on (C.CASEID=T.CASEID)
				join ACTIONS A	on (A.ACTION=T.ACTION)
				left join VALIDACTION VA
						on (VA.CASETYPE=C.CASETYPE
						and VA.PROPERTYTYPE=C.PROPERTYTYPE
						and VA.ACTION=T.ACTION
						and VA.COUNTRYCODE=(select min(VA1.COUNTRYCODE)
								    from VALIDACTION VA1
								    where VA1.CASETYPE=VA.CASETYPE
								    and VA1.PROPERTYTYPE=VA.PROPERTYTYPE
								    and VA1.ACTION=VA.ACTION
								    and VA1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
				where T.[STATE]='C'"
			
				exec sp_executesql @sSQLString
			End
			---------------------------------------------------------------------------------------------
			-- Update DATEFORACT
			-- This section is used to update TEMPOPENACTION with the date of the law (Act) to use for the
			--  particular combination of Country, Propertytype and Action.
			-- The DATEFORACT only needs to be calculated where there exists a Criteria for the Country, 
			-- Property & Actioncombination that actually makes use of a particular DATEOFACT.
			If @nCriteriaFlag=1
			execute @ErrorCode = dbo.ip_PoliceCalculateDateofLaw @pnDebugFlag

			---------------------------------------------------------------------------------------------
			-- Calculate the Criteria

			If @ErrorCode=0
			and @nCriteriaFlag=1
			Begin
				execute @ErrorCode = dbo.ip_PoliceCalculateCriteria 
										@bCriteriaUpdated OUTPUT,
										@pnDebugFlag
			End
			Else Begin
				Set @nCriteriaFlag=1
			End

			---------------------------------------------------------------------------------------------
			-- Load the Events to be Processed as follows :

			-- 1. Events that can be loaded directly from another Event

			If @ErrorCode=0
			Begin
				execute @ErrorCode = dbo.ip_PoliceGetEventsToUpdate @pnDebugFlag
			End
	
			-- 2. Events that are eligible to be calculated

			If @ErrorCode=0
			Begin
				execute @ErrorCode = dbo.ip_PoliceGetEventsToCalculateFromAction 
									@nRowCount	OUTPUT,
									@bRecalcEventDate,
									@pnDebugFlag
			End

			---------------------------------------------------------------------------------------------
			-- Update the TEMPOPENACTION rows that have been calculated so they will not be processed any more

			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Update #TEMPOPENACTION
				set	[STATE]	= 'C1'
				where	[STATE]	= 'C'"

				exec @ErrorCode=sp_executesql @sSQLString
			End
		End	
	End
	---------------------------------------------------------------------------------------------------------------------


	-- Processing of the #TEMPCASEEVENT table is to continue until there are no more unprocessed rows.
	-- This will work on the principle of a State table where each row in the #TEMPCASEEVENT table will have a particular
	-- State value which will be updated to a different State as the rows are processed.

	------------------------------------------------------------------------------------------------------------
	-- From State    | Action Performed                                                       | Change to State |
	--===============|========================================================================|=================|
	-- Calculate (C) | 1. Calculate the due date of the Event. If the Event is not calculated | Reminder (R)    |
	--               |    it will be set to NULL                                              |                 |
	-----------------|------------------------------------------------------------------------|-----------------|
	-- Reminder  (R) | 1. If Event did not originally exist AND no EVENTDUEDATE calculated    |                 |
	--               |    and the TEMPCASEEVENT row has not been used in a calculation        |                 |
	--               |    then the entire TEMPCASEEVENT row is to be deleted.                 |                 |
	------------------------------------------------------------------------------------------------------------
	-- Reminder  (R) | 1. If no EVENTDUEDATE calculated and the event originally existed or   |                 |
	--               |    the Event has been used in a calculation already then the row in    | Delete   (D)    |
	--               |    TEMPCASEEVENT row is to be marked to be deleted.                    |                 |
	------------------------------------------------------------------------------------------------------------
	-- Reminder  (R) | 1. If DATEDUESAVED in (2,3,4,5) then update EVENTDATE                  | Insert   (I)    |
	--               |    This will depend on the date for which Policing is being run.       |                 |
	-----------------|------------------------------------------------------------------------|-----------------|
	-- Reminder  (R) | 1. If LETTER to be produced causes Event to occur then update EVENTDATE| Insert   (I)    |
	-----------------|------------------------------------------------------------------------|-----------------|
	-- Insert    (I) | 1. Actions are to be closed at this time so that unnecessary           |                 |
	--               |    calculations are not performed.                                     |                 |
	-----------------|------------------------------------------------------------------------|-----------------|
	-- Reminder  (R) | 1. Find Events to be calculated as a result of this event being        | Insert/Update(C)|
	-- Insert    (I) |    calculated, inserted or updated and insert into or update           |                 | 
	-- Delete    (D) |    TEMPCASEEVENT as (C).         					  |                 |
	-----------------|------------------------------------------------------------------------|-----------------|
	-- Insert    (I) | 1. Find Events to be cleared and insert/update TEMPCASEEVENT as (C).   |                 |
	--               | 2. Find Events to be inserted and inset into TEMPCASEEVENT as (I).     |                 |
	--               | 3. Find Events that are Satisfied by Event having occurred.            |                 |
	--               | 4. Insert/Update TEMPOPENACTION rows for Closed and Opened cases.      |                 |
	--               | 5. Find Events to be calculated when Action is Opened and insert into  |                 |
	--               |    TEMPOPENACTION as (C).                                              |                 |
	-----------------|------------------------------------------------------------------------|-----------------|
	-- Reminder  (R) | 1. Change the STATE of the row to indicate that its processing has been| Finished (R1)   |
	-- Insert    (I) |    completed successfully.                                             |          (I1)   | 
	-- Delete    (D) |                              					  |          (D1)   |
	------------------------------------------------------------------------------------------------------------

	-- Determine if there are any #TEMPCASEEVENT rows that still require processing before entering
	-- the next WHILE loop.

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		select 
		@nCountStateC =Sum(CASE WHEN([STATE] like 'C%') THEN 1 ELSE 0 END),
		@nCountStateI =Sum(CASE WHEN([STATE]    = 'I' ) THEN 1 ELSE 0 END),
		@nCountStateI1=Sum(CASE WHEN([STATE]    = 'I1') THEN 1 ELSE 0 END),
		@nCountStateD =Sum(CASE WHEN([STATE]    = 'D' ) THEN 1 ELSE 0 END),
		@nCountStateR =Sum(CASE WHEN([STATE]    = 'R' ) THEN 1 ELSE 0 END),
		@nCountStateR1=Sum(CASE WHEN([STATE]    = 'R1') THEN 1 ELSE 0 END),
		@nCountStateRX=Sum(CASE WHEN([STATE]    = 'RX') THEN 1 ELSE 0 END),
		@nCountParentUpdate=Sum(CASE WHEN(UPDATEFROMPARENT=1) THEN 1 ELSE 0 END),
		@nCountPTAUpdate=Sum(CASE WHEN(PTADELAY>0) THEN 1 ELSE 0 END)
		from #TEMPCASEEVENT"

		Execute @ErrorCode=sp_executesql @sSQLString, 
						N'@nCountStateC		int OUTPUT,
						  @nCountStateI		int OUTPUT,
						  @nCountStateD		int OUTPUT,
						  @nCountStateR		int OUTPUT,
						  @nCountStateI1	int OUTPUT,
						  @nCountStateR1	int OUTPUT,
						  @nCountStateRX	int OUTPUT,
						  @nCountParentUpdate	int OUTPUT,
						  @nCountPTAUpdate	int OUTPUT',
						  @nCountStateC =@nCountStateC  OUTPUT,
						  @nCountStateI =@nCountStateI  OUTPUT,
						  @nCountStateD =@nCountStateD  OUTPUT,
						  @nCountStateR =@nCountStateR  OUTPUT,
						  @nCountStateI1=@nCountStateI1 OUTPUT,
						  @nCountStateR1=@nCountStateR1 OUTPUT,
						  @nCountStateRX=@nCountStateRX OUTPUT,
						  @nCountParentUpdate=@nCountParentUpdate OUTPUT,
						  @nCountPTAUpdate=@nCountPTAUpdate OUTPUT
	End

	WHILE @ErrorCode=0
	and   @nCountStateC+@nCountStateI+@nCountStateD+@nCountStateR>0
	BEGIN

		-- Increment the loop counter.  When this counter exceeds a user defined value
		-- the procedure will check if any specific CaseEvents have also exceeded that
		-- value and if so all processing on that Case will stop.

		Set @nMainCount=@nMainCount+1

		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |
		--===============|========================================================================|=================|
		-- Calculate (C) | 1. Calculate the due date of the Event. If the Event is not calculated | Reminder (R)    |
		-- Reminder  (R) |    it will be set to NULL which may result in it being deleted.        | Delete   (D)    |
		------------------------------------------------------------------------------------------------------------

		if  @ErrorCode=0
		and @nCountStateC+@nCountStateR+@nCountStateR1+@nCountStateRX>0
		Begin
			execute @ErrorCode = dbo.ip_PoliceRemoveSatisfiedEvents 
								@nCountStateC	OUTPUT,
								@nCountStateI	OUTPUT,
								@nCountStateR	OUTPUT,
								@nCountStateR1	OUTPUT,
								@nCountStateRX	OUTPUT,
								@nCountStateD	OUTPUT,
								@pnDebugFlag
		End

		if   @ErrorCode=0
		and (@nCountStateC+@nCountParentUpdate>0)
		Begin
			If  @bLoadMessageTable=1
			and @ErrorCode=0
			Begin
				-- Load Policing Message Table
				Set @sSQLString="
				insert into "+@psPolicingMessageTable+"(MESSAGE) values('Calculate Due Dates')

				insert into "+@psPolicingMessageTable+"(MESSAGE)
				select C.IRN+' - '+isnull(EC.EVENTDESCRIPTION,E.EVENTDESCRIPTION)+'('+convert(varchar,T.EVENTNO)+'{'+convert(varchar,T.CYCLE)+'})'
				from #TEMPCASEEVENT T
				join CASES C	on (C.CASEID=T.CASEID)
				join EVENTS E	on (E.EVENTNO=T.EVENTNO)
				left join EVENTCONTROL EC
						on (EC.CRITERIANO=T.CRITERIANO
						and EC.EVENTNO   =T.EVENTNO)
				where T.[STATE]='C'"
			
				exec sp_executesql @sSQLString
			End

			execute @ErrorCode = dbo.ip_PoliceCalculateDueDate 
								@nCountStateC		OUTPUT,
								@nCountStateI		OUTPUT,
								@nCountStateR		OUTPUT,
								@nCountStateRX		OUTPUT,
								@nCountStateD		OUTPUT,
								@nCountParentUpdate	OUTPUT,
								@dtUntilDate,
								@pnDebugFlag
			If @ErrorCode=0
			Begin
				-- R11457
				-- Immediately following the calculation of a CaseEvent
				-- check to see if any of those Events that now have a due date
				-- have also been referenced on another Action and if so load a 
				-- #TEMPCASEEVENT row for the additional Action. This is required
				-- in case some of the rules associated with the Event are split
				-- across multiple Actions.
				Set @sSQLString="
				insert into #TEMPCASEEVENT
						(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
							OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA, 
							ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
							DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO, [STATE], ADJUSTMENT,
							IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
							SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
							INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, NEWEVENTDATE, NEWEVENTDUEDATE,
							USEDINCALCULATION, DATEREMIND, USERID, IDENTITYID, CRITERIANO, ACTION, EVENTUPDATEDMANUALLY, ESTIMATEFLAG,
							EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,SETTHIRDPARTYOFF,
							CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE, RECALCEVENTDATE,
							SUPPRESSCALCULATION )
				select	Distinct
					TC.CASEID, E.DISPLAYSEQUENCE, TC.EVENTNO, TC.CYCLE, 0, TC.OLDEVENTDATE, TC.OLDEVENTDUEDATE, TC.DATEDUESAVED, 
					TC.OCCURREDFLAG, TC.CREATEDBYACTION, TC.CREATEDBYCRITERIA, 
					TC.ENTEREDDEADLINE, TC.PERIODTYPE, TC.DOCUMENTNO, 
					TC.DOCSREQUIRED, TC.DOCSRECEIVED, TC.USEMESSAGE2FLAG, TC.GOVERNINGEVENTNO, TC.[STATE], TC.ADJUSTMENT,
					E.IMPORTANCELEVEL, E.WHICHDUEDATE, E.COMPAREBOOLEAN, E.CHECKCOUNTRYFLAG, E.SAVEDUEDATE, E.STATUSCODE,E.RENEWALSTATUS,
					E.SPECIALFUNCTION, E.INITIALFEE, E.PAYFEECODE, E.CREATEACTION, E.STATUSDESC, E.CLOSEACTION, E.RELATIVECYCLE,
					E.INSTRUCTIONTYPE, E.FLAGNUMBER, E.SETTHIRDPARTYON, TC.COUNTRYCODE, TC.NEWEVENTDATE, TC.NEWEVENTDUEDATE,
					TC.USEDINCALCULATION, TC.DATEREMIND, TC.USERID, TC.IDENTITYID, E.CRITERIANO, 
					T.ACTION, 
					TC.EVENTUPDATEDMANUALLY, E.ESTIMATEFLAG,
					E.EXTENDPERIOD, E.EXTENDPERIODTYPE, E.INITIALFEE2, E.PAYFEECODE2, E.ESTIMATEFLAG2,E.PTADELAY,E.SETTHIRDPARTYOFF,
					E.CHANGENAMETYPE, E.COPYFROMNAMETYPE, E.COPYTONAMETYPE, E.DELCOPYFROMNAME, E.DIRECTPAYFLAG,E.DIRECTPAYFLAG2,TC.LIVEFLAG,
					E.DUEDATERESPNAMENO,E.DUEDATERESPNAMETYPE, TC.RECALCEVENTDATE, TC.SUPPRESSCALCULATION
				From	#TEMPOPENACTION T 
				join	ACTIONS A	on (A.ACTION=T.ACTION)
				join	EVENTCONTROL E	on (E.CRITERIANO=T.NEWCRITERIANO)

				-- The Event under consideration must already exist as a due date
				-- for a different Action to the one being calculated.
				join	#TEMPCASEEVENT TC	
							on (TC.CASEID	   	=T.CASEID 
							and TC.EVENTNO	   	=E.EVENTNO
							and isnull(TC.ACTION,T.ACTION)<>T.ACTION)

				-- The CaseEvent must not already exist for this Action
				left join #TEMPCASEEVENT TC1	
							on (TC1.CASEID =TC.CASEID 
							and TC1.EVENTNO=TC.EVENTNO
							and TC1.CYCLE  =TC.CYCLE
							and TC1.ACTION =T.ACTION)

				-- No due date calculations exist for this Event and Action
				left join (select distinct CRITERIANO, EVENTNO
					   from DUEDATECALC) DD
							on (DD.CRITERIANO=E.CRITERIANO
							and DD.EVENTNO   =E.EVENTNO)

				-- Only process Actions that are open for policing.
				WHERE	T.POLICEEVENTS = 1
				 -- The event must have just been calculated.
				and    TC.[STATE] = 'R'
				and    TC.NEWEVENTDUEDATE is not null
				and    TC.OCCURREDFLAG in (0,9)
				 -- The event may not already exist against for this Action
				and    TC1.CASEID is null
				-- the cycle of Event must match the cycle of the OpenAction if the Action is cyclic.	
				and    (A.NUMCYCLESALLOWED=1 OR T.CYCLE=TC.CYCLE)
				-- No due date calculations exist for this Event and Action
				and DD.CRITERIANO is null"

				Exec @ErrorCode=sp_executesql @sSQLString
			End
		
			If @ErrorCode=0
			Begin
				-- 17979 Recalculate the State counters
				Set @sSQLString="
				select 
				@nCountStateC =Sum(CASE WHEN([STATE] like 'C%') THEN 1 ELSE 0 END),
				@nCountStateI =Sum(CASE WHEN([STATE]    = 'I' ) THEN 1 ELSE 0 END),
				@nCountStateI1=Sum(CASE WHEN([STATE]    = 'I1') THEN 1 ELSE 0 END),
				@nCountStateD =Sum(CASE WHEN([STATE]    = 'D' ) THEN 1 ELSE 0 END),
				@nCountStateR =Sum(CASE WHEN([STATE]    = 'R' ) THEN 1 ELSE 0 END),
				@nCountStateR1=Sum(CASE WHEN([STATE]    = 'R1') THEN 1 ELSE 0 END),
				@nCountStateRX=Sum(CASE WHEN([STATE]    = 'RX') THEN 1 ELSE 0 END),
				@nCountParentUpdate=Sum(CASE WHEN(UPDATEFROMPARENT=1) THEN 1 ELSE 0 END),
				@nCountPTAUpdate=Sum(CASE WHEN(PTADELAY>0) THEN 1 ELSE 0 END)
				from #TEMPCASEEVENT"

				Execute @ErrorCode=sp_executesql @sSQLString, 
								N'@nCountStateC		int OUTPUT,
								  @nCountStateI		int OUTPUT,
								  @nCountStateD		int OUTPUT,
								  @nCountStateR		int OUTPUT,
								  @nCountStateI1	int OUTPUT,
								  @nCountStateR1	int OUTPUT,
								  @nCountStateRX	int OUTPUT,
								  @nCountParentUpdate	int OUTPUT,
								  @nCountPTAUpdate	int OUTPUT',
								  @nCountStateC =@nCountStateC  OUTPUT,
								  @nCountStateI =@nCountStateI  OUTPUT,
								  @nCountStateD =@nCountStateD  OUTPUT,
								  @nCountStateR =@nCountStateR  OUTPUT,
								  @nCountStateI1=@nCountStateI1 OUTPUT,
								  @nCountStateR1=@nCountStateR1 OUTPUT,
								  @nCountStateRX=@nCountStateRX OUTPUT,
								  @nCountParentUpdate=@nCountParentUpdate OUTPUT,
								  @nCountPTAUpdate=@nCountPTAUpdate OUTPUT
			End
		End

		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |	
		--===============|========================================================================|=================|
		-- Reminder  (R) | 1. If Event did not originally exist AND no EVENTDUEDATE calculated    |                 |
		--               |    and the TEMPCASEEVENT row has not been used in a calculation        |                 |
		--               |    then the entire TEMPCASEEVENT row is to be deleted                  |                 |
		------------------------------------------------------------------------------------------------------------
		If  @ErrorCode=0
		and @nCountStateR>0
		Begin
			set @sSQLString="
			Delete T
			from #TEMPCASEEVENT T
			Where	[STATE]='R'
			and	NEWEVENTDUEDATE	  is null
			and	OLDEVENTDUEDATE   is null
			and	OLDEVENTDATE	  is null
			and 	USEDINCALCULATION is null
			-- SQA18765
			-- Do not delete if Event is used in a NOT EXISTS
			-- date comparison rule as deleting the Event may
			-- allow another Event to now calculate.
			and not exists
			(select 1 from #TEMPOPENACTION OA
			 join DUEDATECALC DD	on (DD.CRITERIANO=OA.NEWCRITERIANO
						and DD.FROMEVENT =T.EVENTNO)
			 where OA.CASEID=T.CASEID
			 and OA.POLICEEVENTS=1
			 and DD.COMPARISON='NE')
			-- RFC9968
			-- Do not delete if Event also exists as an R1 row
			and not exists
			(select 1 from #TEMPCASEEVENT T1
			 where T1.CASEID=T.CASEID
			 and T1.EVENTNO=T.EVENTNO
			 and T1.CYCLE=T.CYCLE
			 and T1.[STATE]='R1')"

			Exec @ErrorCode=sp_executesql @sSQLString
			Set  @nCountStateR=@nCountStateR-@@Rowcount
		End

		If  @ErrorCode=0
		and @nCountStateRX>0
		Begin
			set @sSQLString="
			Delete T
			from #TEMPCASEEVENT T
			Where	[STATE]='RX'
			and	NEWEVENTDUEDATE	  is null
			and	OLDEVENTDUEDATE   is null
			and	OLDEVENTDATE	  is null
			and 	USEDINCALCULATION is null
			-- SQA18765
			-- Do not delete if Event is used in a NOT EXISTS
			-- date comparison rule as deleting the Event may
			-- allow another Event to now calculate.
			and not exists
			(select 1 from #TEMPOPENACTION OA
			 join DUEDATECALC DD	on (DD.CRITERIANO=OA.NEWCRITERIANO
						and DD.FROMEVENT =T.EVENTNO)
			 where OA.CASEID=T.CASEID
			 and OA.POLICEEVENTS=1
			 and DD.COMPARISON='NE')
			-- RFC9968
			-- Do not delete if Event also exists as an R1 row
			and not exists
			(select 1 from #TEMPCASEEVENT T1
			 where T1.CASEID=T.CASEID
			 and T1.EVENTNO=T.EVENTNO
			 and T1.CYCLE=T.CYCLE
			 and T1.[STATE]='R1')"

			Exec @ErrorCode=sp_executesql @sSQLString
			Set  @nCountStateRX=@nCountStateRX-@@Rowcount
		End
		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |	
		--===============|========================================================================|=================|
		-- Reminder  (R) | 1. If no EVENTDUEDATE calculated and the event originally existed or   |                 |
		--               |    the Event has been used in a calculation already then the row in    | Delete   (D)    |
		--               |    TEMPCASEEVENT row is to be marked to be deleted.                    |                 |
		------------------------------------------------------------------------------------------------------------


		if  @ErrorCode=0
		and @nCountStateR+@nCountStateRX>0
		Begin
			------------------------------------------------
			-- RFC40815
			-- Reset the DELETEDPREVIOUSLY counter if there
			-- is now a NEWEEVENTDATE or NEWEVENTDUEDATE.
			------------------------------------------------
			Set @sSQLString="
			update #TEMPCASEEVENT
			set DELETEDPREVIOUSLY=0
			where isnull(DELETEDPREVIOUSLY,1)>0
			and [STATE] in ('R','RX')
			and(NEWEVENTDATE is not null OR NEWEVENTDUEDATE is not null)"

			Exec @ErrorCode=sp_executesql @sSQLString
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Update	T
				set	@nCountStateR =@nCountStateR -CASE WHEN(T.[STATE]='R')  THEN 1 ELSE 0 END,
					@nCountStateRX=@nCountStateRX-CASE WHEN(T.[STATE]='RX') THEN 1 ELSE 0 END,
					@nCountStateD =@nCountStateD +1,
							-- SQA18436 Set STATE to D1 if row did not previously exist
					[STATE]=CASE WHEN(T.[STATE]='RX' and T.LOOPCOUNT>0)  -- RFC11092 The EventDueDate has previously been cleared (RFC13383 changed position in CASE statement)
							THEN 'D1'
						     WHEN(T1.DELETEDPREVIOUSLY>1)
							THEN 'D1'
						     WHEN(T.USEDINCALCULATION='Y' and T.OLDEVENTDATE is NULL AND T.OLDEVENTDUEDATE is NULL)
							THEN 'D'
						     WHEN(DD.FROMEVENT is  not null)
							THEN 'D'
						     WHEN(T.OLDEVENTDATE is NULL AND T.OLDEVENTDUEDATE is NULL)
							THEN 'D1'
							ELSE 'D'
						END,
					DELETEDPREVIOUSLY=coalesce(T1.DELETEDPREVIOUSLY, T.DELETEDPREVIOUSLY,0)+1,
					LOOPCOUNT=LOOPCOUNT+1
				From #TEMPCASEEVENT T
				-------------------------------------------------
				-- RFC40815
				-- Need to cater for possibility of multiple rows
				-- in #TEMPCASEEVENT when Event has been defined
				-- against more than one Action
				-------------------------------------------------
				left join (select distinct CASEID, EVENTNO, CYCLE, max(DELETEDPREVIOUSLY) as DELETEDPREVIOUSLY
				           from #TEMPCASEEVENT
				           where DELETEDPREVIOUSLY>1
				           group by CASEID, EVENTNO, CYCLE) T1
									on (T1.CASEID =T.CASEID
									and T1.EVENTNO=T.EVENTNO
									and T1.CYCLE  =T.CYCLE)
				-- RFC13744 Also consider events that are referenced in a NOT EXISTS rule.
				left join (	select distinct OA.CASEID, DD.FROMEVENT
						from #TEMPOPENACTION OA
						join DUEDATECALC DD on (DD.CRITERIANO=OA.NEWCRITERIANO)
						where OA.POLICEEVENTS=1
						and DD.COMPARISON='NE') DD on (DD.CASEID   =T.CASEID
									   and DD.FROMEVENT=T.EVENTNO)

				Where	T.[STATE] in ('R','RX')
				and	T.NEWEVENTDUEDATE is NULL
				and	(T.USEDINCALCULATION='Y' 
				  OR     T.OLDEVENTDATE    is not NULL
				  OR     T.OLDEVENTDUEDATE is not NULL
				  OR    DD.FROMEVENT       is not NULL)"

				Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCountStateR		int	OUTPUT,
							  @nCountStateD		int	OUTPUT,
							  @nCountStateRX	int	OUTPUT',
							  @nCountStateR			OUTPUT,
							  @nCountStateD			OUTPUT,
							  @nCountStateRX		OUTPUT
			End
		End

		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |
		--===============|========================================================================|=================|
		-- Reminder  (R) | 1. If DATEDUESAVED in (2,3,4,5) then update EVENTDATE                  | Insert   (I)    |
		--               |    This will depend on the date for which Policing is being run.       |                 |
		------------------------------------------------------------------------------------------------------------
		-- For each row just calculated check to to see if the Event should be saved. The Importance Level of the 
		-- Event needs to be considered if the Due Date is not greater than or equal to the current system date.

		-- If the SAVEDUEDATE is 2 or 3 then EventDate is saved immediately the EventDueDate is calculated.

		-- If the SAVEDUEDATE is 4 or 5 then EventDate is saved from the EventDueDate when this date is equal to or 
		-- greater than the date for which Policing is being run.  Note that if the ImportanceLevel of the Event is 
		-- equal to or greater than a value set in SITECONTROL then the EventDate will only be updated if the 
		-- EventDueDate is equal to or greater than the system date.

		-- SQA12548 Candidates to automatically update will first be saved in a temporary table and 
		-- then checked to see if there are any rules controlling if they are allowed to be updated.

		Set @nUpdateCandidates=0

		if   @ErrorCode=0
		and (@nCountStateR>0 OR @nCountStateRX>0)
		Begin
			Set @sSQLString="
			Insert into #TEMPUPDATECANDIDATE(CASEID, EVENTNO, CYCLE, NEWEVENTDATE, CURRENTSTATE, CRITERIANO)
			Select T.CASEID, T.EVENTNO, T.CYCLE, T.NEWEVENTDUEDATE, T.[STATE], T.CRITERIANO
			from	#TEMPCASEEVENT T
			left join SITECONTROL S on (S.CONTROLID='CRITICAL LEVEL')
			Where	T.[STATE]  in ('R','RX')
			and	NEWEVENTDUEDATE is not null"

			If @nUpdateFlag=1
			Begin
				Set @sSQLString=@sSQLString+"
				and	(T.SAVEDUEDATE in (2,3) 
				 OR	(T.SAVEDUEDATE in (4,5) and convert(nvarchar,T.NEWEVENTDUEDATE,102)<=convert(nvarchar,getdate(),102))
				 OR	(T.SAVEDUEDATE in (4,5) and T.NEWEVENTDUEDATE<=@dtUntilDate and (T.IMPORTANCELEVEL<S.COLINTEGER OR T.IMPORTANCELEVEL is null OR S.COLINTEGER is null)))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"
				and	(T.SAVEDUEDATE in (2,3) 
				 OR	(T.SAVEDUEDATE in (4,5) and convert(nvarchar,T.NEWEVENTDUEDATE,102)<=convert(nvarchar,getdate(),102))
				 OR	(T.SAVEDUEDATE in (4,5) and T.NEWEVENTDUEDATE<=@dtUntilDate))"
			End

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@dtUntilDate	datetime',
							  @dtUntilDate

			Set @nUpdateCandidates=@@rowcount
		End 

		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |
		--===============|========================================================================|=================|
		-- Reminder  (R) | 1. If LETTER to be produced causes Event to occur then update EVENTDATE| Insert   (I)    |
		------------------------------------------------------------------------------------------------------------

		if   @ErrorCode=0
		and (@nCountStateR>0 or @nCountStateRX>0)
		Begin
			Set @sSQLString="
			Insert into #TEMPUPDATECANDIDATE(CASEID, EVENTNO, CYCLE, NEWEVENTDATE, CURRENTSTATE, CRITERIANO)
			Select distinct T.CASEID, T.EVENTNO, T.CYCLE, convert(nvarchar,getdate(),112), T.STATE, T.CRITERIANO
			From	#TEMPCASEEVENT T
			join	#TEMPOPENACTION OA
						on (OA.CASEID       =T.CASEID
						and(OA.CRITERIANO   =T.CRITERIANO
						 or OA.NEWCRITERIANO=T.CRITERIANO)
						and OA.POLICEEVENTS =1)
			join	REMINDERS R	on (R.CRITERIANO=OA.NEWCRITERIANO
						and R.EVENTNO=T.EVENTNO)
			join	#TEMPCASES TC	on (TC.CASEID   =T.CASEID)
			left join ACTIONS A	on (A.ACTION	=OA.ACTION)
			left join STATUS SC	on (SC.STATUSCODE=TC.STATUSCODE)
			left join STATUS SR	on (SR.STATUSCODE=TC.RENEWALSTATUS)
			left join SITECONTROL S on (S.CONTROLID='CRITICAL LEVEL')
			Where	T.[STATE] in ('R','RX')
			and	R.LETTERNO is not null
			and	R.UPDATEEVENT=1
			-- Note that the STATUS of the case is to be checked to ensure that LETTERS are to be produced
			-- depending upon the type of Action that created the Event.
			and   ((A.ACTIONTYPEFLAG =1 and (SR.LETTERSALLOWED=1 or SR.LETTERSALLOWED is null))
			 OR    (A.ACTIONTYPEFLAG<>1 and (SC.LETTERSALLOWED=1 or SR.LETTERSALLOWED is null))
			 OR	A.ACTIONTYPEFLAG is null)"

			If @nUpdateFlag=1
			Begin
				Set @sSQLString=@sSQLString+"
				and    (convert(nvarchar,T.NEWEVENTDUEDATE,102)<=convert(nvarchar,getdate(),102)
				 OR    (T.NEWEVENTDUEDATE<=@dtUntilDate and (T.IMPORTANCELEVEL<S.COLINTEGER OR T.IMPORTANCELEVEL is null OR S.COLINTEGER is null)))"
			End
			Else Begin
				Set @sSQLString=@sSQLString+"
				and    (convert(nvarchar,T.NEWEVENTDUEDATE,102)<=convert(nvarchar,getdate(),102)
				 OR    (T.NEWEVENTDUEDATE<=@dtUntilDate ))"
			End

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@dtUntilDate	datetime',
							  @dtUntilDate

			Set @nUpdateCandidates=@nUpdateCandidates+@@rowcount
		End
		
		-- The CaseEvents that are candidates to be updated now need to check to see
		-- if there are any rules that will block the update from occurring.
		If  @ErrorCode=0
		and @nUpdateCandidates>0
		Begin
			
			-- check to see if the Document Case is to be considered
			Set @bCheckDocumentCase=0

			Set @sSQLString="
			select @bCheckDocumentCase=1
			from #TEMPUPDATECANDIDATE T
			join EVENTCONTROL EC	on (EC.CRITERIANO=T.CRITERIANO
						and EC.EVENTNO=T.EVENTNO)
			where EC.CASETYPE is not null"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@bCheckDocumentCase	bit			OUTPUT',
						  @bCheckDocumentCase=@bCheckDocumentCase	OUTPUT

			If @bCheckDocumentCase=1
			and @ErrorCode=0
			Begin
				If  @bLoadMessageTable=1
				Begin
					-- Load Policing Message Table
					Set @sSQLString="
					insert into "+@psPolicingMessageTable+"(MESSAGE) values('Is Update Allowed?')
	
					insert into "+@psPolicingMessageTable+"(MESSAGE)
					select C.IRN+' - '+isnull(EC.EVENTDESCRIPTION,E.EVENTDESCRIPTION)+'('+convert(varchar,T.EVENTNO)+'{'+convert(varchar,T.CYCLE)+'})'
					from #TEMPUPDATECANDIDATE T
					join CASES C	on (C.CASEID=T.CASEID)
					join EVENTS E	on (E.EVENTNO=T.EVENTNO)
					left join EVENTCONTROL EC
							on (EC.CRITERIANO=T.CRITERIANO
							and EC.EVENTNO   =T.EVENTNO)
					where EC.CASETYPE is not null"
				
					exec sp_executesql @sSQLString
				End
	
				-- Call the stored procedure to check if there are any
				-- rules that will block the update from occurring.
				exec @ErrorCode=ip_PoliceCheckIfUpdateAllowed
								@nUpdateCandidates	OUTPUT,
								@pnDebugFlag
			End
		End

		If @ErrorCode=0
		and @nCountStateR>0
		and @nUpdateCandidates>0
		Begin
			Set @sSQLString="
			Update	#TEMPCASEEVENT
			set	[STATE]='I',
				NEWEVENTDATE=U.NEWEVENTDATE,
				OCCURREDFLAG=1,
				FROMCASEID=U.FROMCASEID,
				LOOPCOUNT=LOOPCOUNT+1
			From #TEMPCASEEVENT T
			join #TEMPUPDATECANDIDATE U	on (U.CASEID=T.CASEID
							and U.EVENTNO=T.EVENTNO
							and U.CYCLE  =T.CYCLE)
			Where U.CURRENTSTATE='R'"

			Exec @ErrorCode=sp_executesql @sSQLString

			Select @nCountStateR=@nCountStateR-@@Rowcount,
			       @nCountStateI=@nCountStateI+@@Rowcount
		End

		-- If the Event has just occurred then if there are multiple TEMPCASEEVENT rows for the 
		-- one CASEID, EVENTNO and CYCLE because there are multiple OpenActions, then also ensure
		-- that the other TEMPCASEEVENT rows are updated.
		If  @ErrorCode=0
		and @nCountStateI>0
		and @nCountStateR+@nCountStateRX>0
		Begin
			Set @sSQLString="
			Update #TEMPCASEEVENT
			set	@nCountStateR =@nCountStateR -CASE WHEN(T.[STATE]='R')  THEN 1 ELSE 0 END,
				@nCountStateRX=@nCountStateRX-CASE WHEN(T.[STATE]='RX') THEN 1 ELSE 0 END,
				@nCountStateI =@nCountStateI +1,
				[STATE]='I',
				NEWEVENTDATE=T1.NEWEVENTDATE,
				FROMCASEID=T1.FROMCASEID,
				OCCURREDFLAG=1,
				LOOPCOUNT=LOOPCOUNT+1
			from #TEMPCASEEVENT T
			join (	select CASEID, EVENTNO, CYCLE, NEWEVENTDATE, OCCURREDFLAG, [STATE], FROMCASEID
				from #TEMPCASEEVENT) T1	on (T1.CASEID=T.CASEID
							and T1.EVENTNO=T.EVENTNO
							and T1.CYCLE=T.CYCLE
							and T1.[STATE]='I'
							and T1.NEWEVENTDATE is not null
							and T1.OCCURREDFLAG=1)
			where T.NEWEVENTDATE is null
			and T.[STATE] in ('R','RX')
			and T.OCCURREDFLAG=0"

			exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCountStateR		int	OUTPUT,
							  @nCountStateI		int	OUTPUT,
							  @nCountStateRX	int	OUTPUT',
							  @nCountStateR			OUTPUT,
							  @nCountStateI			OUTPUT,
							  @nCountStateRX		OUTPUT
		End

		If @ErrorCode=0
		and @nCountStateRX>0
		and @nUpdateCandidates>0
		Begin
			Set @sSQLString="
			Update	#TEMPCASEEVENT
			set	[STATE]='I',
				NEWEVENTDATE=U.NEWEVENTDATE,
				FROMCASEID=U.FROMCASEID,
				OCCURREDFLAG=1,
				LOOPCOUNT=LOOPCOUNT+1
			From #TEMPCASEEVENT T
			join #TEMPUPDATECANDIDATE U	on (U.CASEID=T.CASEID
							and U.EVENTNO=T.EVENTNO
							and U.CYCLE  =T.CYCLE)
			Where U.CURRENTSTATE='RX'"

			Exec @ErrorCode=sp_executesql @sSQLString

			Select @nCountStateRX=@nCountStateRX-@@Rowcount,
			       @nCountStateI=@nCountStateI +@@Rowcount
		End

		-- Clear out any update candidates
		If @ErrorCode=0
		and @nUpdateCandidates>0
		Begin
			Set @sSQLString="delete from #TEMPUPDATECANDIDATE"

			exec @ErrorCode=sp_executesql @sSQLString
		End

		-- SQA19815
		-- If the Event has just occurred then check that the
		-- CriteriaNo for the Action correctly matches the CriteriaNo on the
		-- OpenAction for that Action. It is possible for this to not match
		-- when the CASEEVENT has been inserted as a bulk entry through Case
		-- Detail Entry.
		
		If  @ErrorCode=0
		and @nCountStateI>0
		Begin
			Set @sSQLString="
			Update T
			Set CREATEDBYCRITERIA=OA.CRITERIANO,
			    CRITERIANO       =OA.CRITERIANO
			from #TEMPCASEEVENT T
			join #TEMPOPENACTION OA	on (OA.CASEID=T.CASEID
						and OA.ACTION=T.CREATEDBYACTION
						and OA.ACTION=T.ACTION)
			join ACTIONS A		on ( A.ACTION=T.ACTION)
			where T.[STATE] = 'I'
			and  OA.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN T.CYCLE ELSE OA.CYCLE END
			and   T.CREATEDBYCRITERIA<>OA.CRITERIANO"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- If the Event has just occurred then check to see if the Event also belongs to another
		-- OpenAction and if so insert a row into the TEMPCASEEVENT table.  This is to ensure that
		-- all update tasks associated with an Event are considered.
		If  @ErrorCode=0
		and @nCountStateI>0
		Begin
			Set @sSQLString="
			insert into #TEMPCASEEVENT
			(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
				OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA, 
				ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
				DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO, [STATE], ADJUSTMENT,
				IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
				SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
				INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, NEWEVENTDATE, NEWEVENTDUEDATE,
				USEDINCALCULATION, DATEREMIND, USERID, IDENTITYID, CRITERIANO, ACTION, EVENTUPDATEDMANUALLY, ESTIMATEFLAG,
				EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,SETTHIRDPARTYOFF,
				CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE, RECALCEVENTDATE,
				SUPPRESSCALCULATION )
			select	T.CASEID, EC.DISPLAYSEQUENCE, T.EVENTNO, T.CYCLE, 0, T.OLDEVENTDATE, T.OLDEVENTDUEDATE, T.DATEDUESAVED, 
				T.OCCURREDFLAG, T.CREATEDBYACTION, T.CREATEDBYCRITERIA, 
				T.ENTEREDDEADLINE, T.PERIODTYPE, T.DOCUMENTNO, 
				T.DOCSREQUIRED, T.DOCSRECEIVED, T.USEMESSAGE2FLAG, T.GOVERNINGEVENTNO, T.[STATE], T.ADJUSTMENT,
				EC.IMPORTANCELEVEL, EC.WHICHDUEDATE, EC.COMPAREBOOLEAN, EC.CHECKCOUNTRYFLAG, EC.SAVEDUEDATE, EC.STATUSCODE,EC.RENEWALSTATUS,
				EC.SPECIALFUNCTION, EC.INITIALFEE, EC.PAYFEECODE, EC.CREATEACTION, EC.STATUSDESC, EC.CLOSEACTION, EC.RELATIVECYCLE,
				EC.INSTRUCTIONTYPE, EC.FLAGNUMBER, EC.SETTHIRDPARTYON, T.COUNTRYCODE, T.NEWEVENTDATE, T.NEWEVENTDUEDATE,
				T.USEDINCALCULATION, T.DATEREMIND, T.USERID, T.IDENTITYID, EC.CRITERIANO, CR.ACTION, T.EVENTUPDATEDMANUALLY, EC.ESTIMATEFLAG,
				EC.EXTENDPERIOD, EC.EXTENDPERIODTYPE, EC.INITIALFEE2, EC.PAYFEECODE2, EC.ESTIMATEFLAG2,EC.PTADELAY,EC.SETTHIRDPARTYOFF,
				EC.CHANGENAMETYPE, EC.COPYFROMNAMETYPE, EC.COPYTONAMETYPE, EC.DELCOPYFROMNAME, EC.DIRECTPAYFLAG,EC.DIRECTPAYFLAG2,T.LIVEFLAG,
				EC.DUEDATERESPNAMENO,EC.DUEDATERESPNAMETYPE, T.RECALCEVENTDATE, T.SUPPRESSCALCULATION
			from #TEMPCASEEVENT T
			join EVENTCONTROL EC	on (EC.EVENTNO=T.EVENTNO
			  			and exists (	select CRITERIANO
								from #TEMPOPENACTION OA
								join ACTIONS A on (A.ACTION=OA.ACTION)
								where OA.CASEID=T.CASEID
								and   OA.POLICEEVENTS=1
								and   isnull(OA.NEWCRITERIANO,OA.CRITERIANO)=EC.CRITERIANO
								and   OA.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED=1) THEN 1 ELSE T.CYCLE END))	-- RFC44921
			join CRITERIA CR	on (CR.CRITERIANO=EC.CRITERIANO)
			left join #TEMPCASEEVENT T1	on (T1.CASEID =T.CASEID
							and T1.EVENTNO=T.EVENTNO
							and T1.CYCLE  =T.CYCLE
							and T1.ACTION=CR.ACTION)	--SQA17231 & SQA17409
			where T.[STATE]='I'
			and T1.CASEID is null -- ensure the row being inserted does not already exist"

			Exec @ErrorCode=sp_executesql @sSQLString
			Select @nCountStateI=@nCountStateI+@@Rowcount
		End

		-- SQA16899
		-- If newly calculated Due Dates has a rule to clear out an Event or Due date
		-- whenever the due date changes against a different Action, then insert and
		-- additional TEMPCASEEVENT row for that Action

		If  @ErrorCode=0
		and @nCountStateR>0
		Begin

			Set @sSQLString="
			insert into #TEMPCASEEVENT
			(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
				OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA, 
				ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
				DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO, [STATE], ADJUSTMENT,
				IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
				SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
				INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, NEWEVENTDATE, NEWEVENTDUEDATE,
				USEDINCALCULATION, DATEREMIND, USERID, IDENTITYID, CRITERIANO, ACTION, EVENTUPDATEDMANUALLY, ESTIMATEFLAG,
				EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,SETTHIRDPARTYOFF,
				CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE, RECALCEVENTDATE,
				SUPPRESSCALCULATION )
			select	T.CASEID, EC.DISPLAYSEQUENCE, T.EVENTNO, T.CYCLE, 0, T.OLDEVENTDATE, T.OLDEVENTDUEDATE, T.DATEDUESAVED, 
				T.OCCURREDFLAG, T.CREATEDBYACTION, T.CREATEDBYCRITERIA, 
				T.ENTEREDDEADLINE, T.PERIODTYPE, T.DOCUMENTNO, 
				T.DOCSREQUIRED, T.DOCSRECEIVED, T.USEMESSAGE2FLAG, T.GOVERNINGEVENTNO, T.[STATE], T.ADJUSTMENT,
				EC.IMPORTANCELEVEL, EC.WHICHDUEDATE, EC.COMPAREBOOLEAN, EC.CHECKCOUNTRYFLAG, EC.SAVEDUEDATE, EC.STATUSCODE,EC.RENEWALSTATUS,
				EC.SPECIALFUNCTION, EC.INITIALFEE, EC.PAYFEECODE, EC.CREATEACTION, EC.STATUSDESC, EC.CLOSEACTION, EC.RELATIVECYCLE,
				EC.INSTRUCTIONTYPE, EC.FLAGNUMBER, EC.SETTHIRDPARTYON, T.COUNTRYCODE, T.NEWEVENTDATE, T.NEWEVENTDUEDATE,
				T.USEDINCALCULATION, T.DATEREMIND, T.USERID, T.IDENTITYID, EC.CRITERIANO, CR.ACTION, T.EVENTUPDATEDMANUALLY, EC.ESTIMATEFLAG,
				EC.EXTENDPERIOD, EC.EXTENDPERIODTYPE, EC.INITIALFEE2, EC.PAYFEECODE2, EC.ESTIMATEFLAG2,EC.PTADELAY,EC.SETTHIRDPARTYOFF,
				EC.CHANGENAMETYPE, EC.COPYFROMNAMETYPE, EC.COPYTONAMETYPE, EC.DELCOPYFROMNAME, EC.DIRECTPAYFLAG,EC.DIRECTPAYFLAG2,T.LIVEFLAG,
				EC.DUEDATERESPNAMENO,EC.DUEDATERESPNAMETYPE, T.RECALCEVENTDATE, T.SUPPRESSCALCULATION
			from #TEMPCASEEVENT T
			join EVENTCONTROL EC	on (EC.EVENTNO=T.EVENTNO
			  			and exists (	select CRITERIANO
								from #TEMPOPENACTION OA
								join ACTIONS A on (A.ACTION=OA.ACTION)
								where OA.CASEID=T.CASEID
								and   OA.POLICEEVENTS=1
								and   isnull(OA.NEWCRITERIANO,OA.CRITERIANO)=EC.CRITERIANO
								and   OA.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED=1) THEN 1 ELSE T.CYCLE END))
			join CRITERIA CR	on (CR.CRITERIANO=EC.CRITERIANO)
			join (	select distinct CRITERIANO, EVENTNO
				from RELATEDEVENTS
				where CLEAREVENTONDUECHANGE=1
				OR    CLEARDUEONDUECHANGE=1) RE	
							on (RE.CRITERIANO=EC.CRITERIANO
							and RE.EVENTNO=EC.EVENTNO)
			left join #TEMPCASEEVENT T1	on (T1.CASEID =T.CASEID
							and T1.EVENTNO=T.EVENTNO
							and T1.CYCLE  =T.CYCLE
							and(T1.ACTION=CR.ACTION OR T1.CREATEDBYACTION=CR.ACTION))	--SQA17231
							--and(T1.CRITERIANO=EC.CRITERIANO OR T1.CREATEDBYCRITERIA=EC.CRITERIANO)) --SQA17231 commented out
			where T.[STATE]='R'
			and T1.CASEID is null -- ensure the row being inserted does not already exist"

			Exec @ErrorCode=sp_executesql @sSQLString
			Select @nCountStateR=@nCountStateR+@@Rowcount
		End

		If @ErrorCode=0
		and @nCountStateI+@nCountStateR>0
		Begin
			-----------------------------------------------------
			-- RFC12262
			-- When responsible name for an Event is defined on a 
			-- different Action to the one used to calculate the 
			-- Event, the responsible name rule is to be added to
			-- the other #TEMPCASEEVENT rows for the same CASEID,
			-- EVENTNO and CYCLE.
			-----------------------------------------------------
			Set @sSQLString="
			update T
			set RESPNAMENO  =T1.RESPNAMENO,
			    RESPNAMETYPE=T1.RESPNAMETYPE
			from #TEMPCASEEVENT T
			join (SELECT * from #TEMPCASEEVENT) T1
					on (T1.CASEID =T.CASEID
					and T1.EVENTNO=T.EVENTNO
					and T1.CYCLE  =T.CYCLE
					and T1.UNIQUEID<>T.UNIQUEID)
			where T.RESPNAMENO is NULL
			and T.RESPNAMETYPE is NULL
			and (T1.RESPNAMENO is not NULL OR T1.RESPNAMETYPE is not NULL)"
			
			Exec @ErrorCode=sp_executesql @sSQLString
		End

		If  @pnDebugFlag>0
		and @ErrorCode=0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s ipu_Policing - after Update of #TEMPCASEEVENT',0,1,@sTimeStamp ) with NOWAIT

			If @pnDebugFlag>2
			Begin
				Set @sSQLString="
				Select	CASEID, EVENTNO,CYCLE,T.[STATE],LOOPCOUNT,OLDEVENTDATE,NEWEVENTDATE,OLDEVENTDUEDATE,NEWEVENTDUEDATE,DATEREMIND,NEWDATEREMIND, DATEDUESAVED,OCCURREDFLAG,CREATEDBYACTION,CREATEDBYCRITERIA,ACTION,CRITERIANO,STATUSCODE,RENEWALSTATUS,INITIALFEE, SAVEDUEDATE, T.*
				from	#TEMPCASEEVENT T
				where	T.[STATE]<>'X'
				order by 4,1,2,3"
		
				Exec @ErrorCode=sp_executesql @sSQLString
			End
		End

		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |
		--===============|========================================================================|=================|
		-- Insert    (I) | 1. Actions are to be closed at this time so that unnecessary           |                 |
		--               |    calculations are not performed.                                     |                 |
		------------------------------------------------------------------------------------------------------------

		If  @ErrorCode=0
		and @nCountStateI>0
		Begin
			-- Only call the stored procedure to close actions if there are unprocessed
			-- transactions to do this.

			Set @bCloseActions=0
			Set @sSQLString="
			Select @bCloseActionsOUT=1
			from #TEMPCASEEVENT
			where STATE='I'
			and CLOSEACTION is not null"
	
			Execute @ErrorCode=sp_executesql @sSQLString, 
							N'@bCloseActionsOUT		bit 	OUTPUT',
							  @bCloseActionsOUT=@bCloseActions	OUTPUT

			If  @ErrorCode=0
			and @bCloseActions=1
			Begin
				execute @ErrorCode = dbo.ip_PoliceCloseActions @pnDebugFlag
			End

		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |
		--===============|========================================================================|=================|
		-- Insert    (I) | 1. Update the STATUS of the Case if the Event is being updated.        |                 |
		--               |    Also update the TEMPOPENACTION with the last Status and last Event  |                 |
                --               |    that was updated.                                                   |                 |
		------------------------------------------------------------------------------------------------------------
		-- Check if there are any CaseEvent rows that need to update the Status of the Case.

			If @ErrorCode=0
			Begin
				Set @bStatusUpdates=0
				Set @sSQLString="
				Select @bStatusUpdatesOUT=1
				from #TEMPCASEEVENT
				where [STATE]='I'
				and isnull(STATUSCODE,RENEWALSTATUS) is not null"
		
				Execute @ErrorCode=sp_executesql @sSQLString, 
								N'@bStatusUpdatesOUT	bit OUTPUT',
								  @bStatusUpdatesOUT=@bStatusUpdates OUTPUT
			End

			if  @ErrorCode=0
			and @bStatusUpdates=1
			Begin
				execute @ErrorCode = dbo.ip_PoliceUpdateCaseStatus @pnDebugFlag
			End

			-- Update the LASTEVENT of the #TEMPOPENACTION with what would be the last EVENTNO 
			-- to have been updated for that Action.
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				update 	#TEMPOPENACTION
				set	LASTEVENT=T.EVENTNO
				from	#TEMPOPENACTION O
				join	#TEMPCASEEVENT	T on (T.CASEID		=O.CASEID
							  and T.CREATEDBYACTION	=O.ACTION)
				where	O.POLICEEVENTS=1
				and	T.[STATE]='I'
				and	convert(nchar(8),T.NEWEVENTDATE,112)+
					space(5-len(isnull(T.DISPLAYSEQUENCE,0)))+convert(nvarchar(5),isnull(T.DISPLAYSEQUENCE,0))+
					convert(nchar(13),T.EVENTNO)+
					convert(nchar(5),T.CYCLE)
						= (select max(	convert(nchar(8),T1.NEWEVENTDATE,112)+
								space(5-len(isnull(T1.DISPLAYSEQUENCE,0)))+convert(nvarchar(5),isnull(T1.DISPLAYSEQUENCE,0))+
								convert(nchar(13),T1.EVENTNO)+
								convert(nchar(5),T1.CYCLE) )
						   from #TEMPCASEEVENT T1
						   join ACTIONS A on (A.ACTION=T1.CREATEDBYACTION)
						   where T1.CASEID=T.CASEID
						   and   T1.[STATE] ='I'
						   and   T1.NEWEVENTDATE is not null
						   and   T1.CREATEDBYACTION=T.CREATEDBYACTION
						   and ((T1.CYCLE = O.CYCLE AND A.NUMCYCLESALLOWED>1) OR A.NUMCYCLESALLOWED=1))"
			
				Exec @ErrorCode=sp_executesql @sSQLString
			End

			-- Update the REPORTTOTHIRDPARTY column of the Case if an Event has just
			-- occurred that sets it on or sets it off.
			
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				update 	#TEMPCASES
				set	REPORTTOTHIRDPARTY=CASE WHEN(T.SETTHIRDPARTYOFF=1) 
								THEN 0 
								ELSE T.SETTHIRDPARTYON
							   END
				from	#TEMPCASES C
				join	#TEMPCASEEVENT	T on (T.CASEID=C.CASEID)
				where	T.[STATE]='I'
				and	((T.SETTHIRDPARTYON =1 and isnull(C.REPORTTOTHIRDPARTY,0)=0)
				 or	 (T.SETTHIRDPARTYOFF=1 and C.REPORTTOTHIRDPARTY=1))"
			
				Exec @ErrorCode=sp_executesql @sSQLString
			End

			--------------------------------------------------------------
			-- SQA18494
			-- Check to see if the Event that has just occurred is linked
			-- to any user defined ALERTS. If so the new Event Date will 
			-- be used as the Due Date for the Alert to trigger reminders.
			-- A special Policing request will be raised to cause the
			-- Alert dates to calculate.
			--------------------------------------------------------------
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Insert into #TEMPPOLICING(DATEENTERED, POLICINGSEQNO,CASEID, TYPEOFREQUEST, SQLUSER, PROCESSED, ADHOCNAMENO, ADHOCDATECREATED)
				select A.ALERTSEQ, 0, A.CASEID, 2, SQLUSER, 1, A.EMPLOYEENO, A.ALERTSEQ
				from #TEMPCASEEVENT T
				join ALERT A	on (A.CASEID=T.CASEID
						and A.TRIGGEREVENTNO=T.EVENTNO
						and (A.DUEDATE is null and T.NEWEVENTDATE is not null
						 OR  A.DUEDATE          <> T.NEWEVENTDATE) )
				left join #TEMPPOLICING T1
						on (T1.DATEENTERED     =A.ALERTSEQ
						and T1.POLICINGSEQNO   =0
						and T1.CASEID          =A.CASEID
						and T1.TYPEOFREQUEST   =2
						and T1.ADHOCNAMENO     =A.EMPLOYEENO
						and T1.ADHOCDATECREATED=A.ALERTSEQ)
				where T.[STATE]='I'
				and   T.NEWEVENTDATE is not null
				and  T1.DATEENTERED  is null"

				Exec @ErrorCode=sp_executesql @sSQLString
				Set @nAlerts=@@RowCount

				-- Set the flag on if any rows have been
				-- inserted.  This will cause the Alerts 
				-- to be calculated
				If @nAlerts>0
					Set @nAdhocFlag=1
			End

		End -- end of STATE='I'
		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |
		--===============|========================================================================|=================|
		-- Reminder  (R) | 1. Find Events to be calculated as a result of this event being        | Insert/Update(C)|
		-- Insert    (I) |    calculated, inserted or updated and insert into or update           |                 | 
		-- Delete    (D) |    TEMPCASEEVENT as (C).         					  |                 |
		--		 | 2. Related Cases may also need to be updated as a result of this event |                 |
		--		 |    changing in some way.                                               |                 |
		------------------------------------------------------------------------------------------------------------

		if @ErrorCode=0
		and @nCountStateR+@nCountStateI+@nCountStateD>0
		Begin
			execute @ErrorCode = dbo.ip_PoliceGetEventsToCalculateFromEvents 
									@pnRowCount=@nRowCount	OUTPUT,
									@pbRecalcEventDate=@bRecalcEventDate,
									@pnDebugFlag=@pnDebugFlag

			-- If the #TEMPCASEEVENT table had rows added or changed in the last
			-- stored procedure then we need to reset our current count of the different
			-- STATES.  This has to be done in this way because of the complex nature of the
			-- UPDATE in the ipb_PoliceGetEventsToCalculateFromEvents where a variety of
			-- STATES were changed to other STATES

			If  @ErrorCode=0
			and @nRowCount>0
			Begin	
				Set @sSQLString="
				select 
				@nCountStateC =Sum(CASE WHEN([STATE] LIKE 'C%') THEN 1 ELSE 0 END),
				@nCountStateI =Sum(CASE WHEN([STATE]    = 'I' ) THEN 1 ELSE 0 END),
				@nCountStateD =Sum(CASE WHEN([STATE]    = 'D' ) THEN 1 ELSE 0 END),
				@nCountStateR =Sum(CASE WHEN([STATE]    = 'R' ) THEN 1 ELSE 0 END),
				@nCountParentUpdate=Sum(CASE WHEN(UPDATEFROMPARENT=1) THEN 1 ELSE 0 END)
				from #TEMPCASEEVENT
				where [STATE] in ('I','C','C1','D','R')
				OR UPDATEFROMPARENT=1"
		
				Execute @ErrorCode=sp_executesql @sSQLString, 
								N'@nCountStateC		int OUTPUT,
								  @nCountStateI		int OUTPUT,
								  @nCountStateD		int OUTPUT,
								  @nCountStateR		int OUTPUT,
								  @nCountParentUpdate	int OUTPUT',
								  @nCountStateC =@nCountStateC  OUTPUT,
								  @nCountStateI =@nCountStateI  OUTPUT,
								  @nCountStateD =@nCountStateD  OUTPUT,
								  @nCountStateR =@nCountStateR  OUTPUT,
								  @nCountParentUpdate=@nCountParentUpdate OUTPUT
			End
		End

		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |
		--===============|========================================================================|=================|
		-- Insert    (I) | 1. Find Events to be cleared and insert/update TEMPCASEEVENT as (C).   |                 |
		--           (R) |                                                                        |                 |
		--           (D) |                                                                        |                 |
		------------------------------------------------------------------------------------------------------------

		If  @ErrorCode=0
		and(@nCountStateI>0
		 or @nCountStateR>0
		 or @nCountStateD>0)
		Begin
			-- Only call the stored procedure to clear events if there are unprocessed
			-- transactions to do this.

			Set @bClearEvents=0

			Set @sSQLString="
			Select @bClearEventsOUT=1
			from #TEMPCASEEVENT T
			join RELATEDEVENTS RE	on ( RE.CRITERIANO=T.CRITERIANO
						and  RE.EVENTNO=T.EVENTNO)
			where (T.[STATE]='I'         AND (RE.CLEAREVENT=1 OR RE.CLEARDUE=1))
			   OR (T.[STATE] in('R','D') AND (RE.CLEAREVENTONDUECHANGE=1 OR RE.CLEARDUEONDUECHANGE=1))"
	
			Execute @ErrorCode=sp_executesql @sSQLString, 
							N'@bClearEventsOUT		bit 	OUTPUT',
							  @bClearEventsOUT=@bClearEvents	OUTPUT

			If  @ErrorCode=0
			and @bClearEvents=1
			Begin
				execute @ErrorCode = dbo.ip_PoliceClearEvents
								@nCountStateC		OUTPUT,
								@nCountStateI		OUTPUT,
								@nCountStateR		OUTPUT,
								@nCountStateD		OUTPUT,
								@pnDebugFlag
			End
		End

		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |
		--===============|========================================================================|=================|
		-- Insert    (I) | 1. Find Events to be inserted and insert into TEMPCASEEVENT as (I).    |                 |
		--               | 2. Find Events that are Satisfied by Event having occurred.            |                 |
		--               | 3. Insert/Update TEMPOPENACTION rows for Opened cases.                 |                 |
		--               | 4. Events just inserted or updated may update the Date of Act          |                 |
		------------------------------------------------------------------------------------------------------------
		

		If  @ErrorCode=0
		and @nCountStateI>0
		Begin
			-- Only call the stored procedure to update events if there are unprocessed
			-- transactions to do this.

			Set @bUpdateEvents=0

			Set @sSQLString="
			Select @bUpdateEventsOUT=1
			from #TEMPCASEEVENT T
			join RELATEDEVENTS RE	on ( RE.CRITERIANO =T.CRITERIANO
						and  RE.EVENTNO=T.EVENTNO
						and  RE.UPDATEEVENT = 1)
			where T.[STATE]='I'"
	
			Execute @ErrorCode=sp_executesql @sSQLString, 
							N'@bUpdateEventsOUT		bit 	OUTPUT',
							  @bUpdateEventsOUT=@bUpdateEvents	OUTPUT

			If  @ErrorCode=0
			and @bUpdateEvents=1
			Begin
				execute @ErrorCode = dbo.ip_PoliceUpdateEvents
								@nCountStateC		OUTPUT,
								@nCountStateI		OUTPUT,
								@nCountStateR		OUTPUT,
								@nCountStateD		OUTPUT,
								@pnDebugFlag
			End
		End
		

		-- SQA10983
		If  @ErrorCode=0
		and @nCountStateI+@nCountStateR+@nCountStateD>0
		Begin
			-- Only call the stored procedure to update events if there are unprocessed
			-- transactions to do this and a relevant CaseRelation rule exists.

			Set @bUpdateEvents=0

			Set @sSQLString="
			Select @bUpdateEventsOUT=1
			from #TEMPCASEEVENT T
			join RELATEDCASE RC	on ( RC.RELATEDCASEID=T.CASEID)
			join CASERELATION CR	on ( CR.RELATIONSHIP=RC.RELATIONSHIP
						and  CR.FROMEVENTNO=T.EVENTNO)
			where T.[STATE] in ('I', 'R','D')
			and T.CYCLE=1
			and isnull(CR.DISPLAYEVENTONLY,0)=0"
	
			Execute @ErrorCode=sp_executesql @sSQLString, 
							N'@bUpdateEventsOUT		bit 	OUTPUT',
							  @bUpdateEventsOUT=@bUpdateEvents	OUTPUT

			If  @ErrorCode=0
			and @bUpdateEvents=1
			Begin
				execute @ErrorCode = dbo.ip_PoliceUpdateRelatedCaseEvent
								@pnRowCount=@nRowCount	OUTPUT,
								@pnDebugFlag=@pnDebugFlag
				-- If the #TEMPCASEEVENT table had rows added or changed in the last
				-- stored procedure then we need to reset our current count of the different
				-- STATES.  This has to be done in this way because of the complex nature of the
				-- UPDATE in the ip_PoliceUpdateRelatedCaseEvent where a variety of
				-- STATES were changed to other STATES

				If  @ErrorCode=0
				and @nRowCount>0
				Begin	
					Set @sSQLString="
					select 
					@nCountStateC =Sum(CASE WHEN([STATE] LIKE 'C%') THEN 1 ELSE 0 END),
					@nCountStateI =Sum(CASE WHEN([STATE]    = 'I' ) THEN 1 ELSE 0 END),
					@nCountStateD =Sum(CASE WHEN([STATE]    = 'D' ) THEN 1 ELSE 0 END),
					@nCountStateR =Sum(CASE WHEN([STATE]    = 'R' ) THEN 1 ELSE 0 END)
					from #TEMPCASEEVENT
					where [STATE] in ('I','C','C1','D','R')"
			
					Execute @ErrorCode=sp_executesql @sSQLString, 
									N'@nCountStateC		int OUTPUT,
									  @nCountStateI		int OUTPUT,
									  @nCountStateD		int OUTPUT,
									  @nCountStateR		int OUTPUT',
									  @nCountStateC =@nCountStateC  OUTPUT,
									  @nCountStateI =@nCountStateI  OUTPUT,
									  @nCountStateD =@nCountStateD  OUTPUT,
									  @nCountStateR =@nCountStateR  OUTPUT
				End
			End
		End

		if @ErrorCode=0
		and @nCountStateI>0
		Begin
			-- Only call the stored procedure to satisfy events if there are unprocessed
			-- transactions to do this.

			Set @bSatisfyEvents=0

			Set @sSQLString="
			Select @bSatisfyEventsOUT=1
			from #TEMPCASEEVENT T
			join RELATEDEVENTS RE    on ( RE.RELATEDEVENT=T.EVENTNO
						and  RE.SATISFYEVENT=1)
			where T.[STATE]='I'"
	
			Execute @ErrorCode=sp_executesql @sSQLString, 
							N'@bSatisfyEventsOUT		bit 	OUTPUT',
							  @bSatisfyEventsOUT=@bSatisfyEvents	OUTPUT

			If  @ErrorCode=0
			and @bSatisfyEvents=1
			Begin
				execute @ErrorCode = dbo.ip_PoliceSatisfyEvents
								@nCountStateC		OUTPUT,
								@nCountStateI		OUTPUT,
								@nCountStateR		OUTPUT,
								@nCountStateD		OUTPUT,
								@pnDebugFlag
			End
		End

		if  @ErrorCode=0
		and @nCountStateI>0
		Begin
			-- Only call the stored procedure to open new actions if there are unprocessed
			-- transactions to do this.

			Set @bOpenActions=0
			Set @sSQLString="
			Select @bOpenActionsOUT=1
			from #TEMPCASEEVENT
			where [STATE]='I'
			and CREATEACTION is not null"
	
			Execute @ErrorCode=sp_executesql @sSQLString, 
							N'@bOpenActionsOUT		bit 	OUTPUT',
							  @bOpenActionsOUT=@bOpenActions	OUTPUT

			If  @ErrorCode=0
			and @bOpenActions=1
			Begin
				execute @ErrorCode = dbo.ip_PoliceOpenNewActions @pnDebugFlag
			End

			-- Close any actions that have just been opened within this same loop as it is possible
			-- for one event to trigger the opening of an Action and another event to immediately
			-- trigger its closing.  
			-- The routine to close actions was previously called within this loop to avoid processing
			-- events belonging to what would become a closed action.

			-- Only call the stored procedure to close actions if there are unprocessed
			-- transactions to do this.

			If @ErrorCode=0
			Begin
				Set @bCloseActions=0
				Set @sSQLString="
				Select @bCloseActionsOUT=1
				from #TEMPCASEEVENT
				where [STATE]='I'
				and CLOSEACTION is not null"
		
				Execute @ErrorCode=sp_executesql @sSQLString, 
								N'@bCloseActionsOUT		bit 	OUTPUT',
								  @bCloseActionsOUT=@bCloseActions	OUTPUT
			End

			If  @ErrorCode=0
			and @bCloseActions=1
			Begin
				execute @ErrorCode = dbo.ip_PoliceCloseActions @pnDebugFlag
			End

			-- Only call the stored procedure to trigger the update of other CaseEvents
			-- that have a "document required" rule if there are unprocessed transactions
			-- to do this.

			If @ErrorCode=0
			Begin
				Set @bDocumentsRequired=0
				Set @sSQLString="
				Select @bDocumentsRequired=1
				from #TEMPCASEEVENT T
				join #TEMPCASES TC		on (TC.CASEID=T.CASEID)
				-- Rule that requires a Case of the given Case Type 
				join EVENTCONTROL EC		on (EC.CASETYPE=TC.CASETYPE
								and EC.SAVEDUEDATE between 2 and 5)
				join EVENTCONTROLREQEVENT RE	on (RE.CRITERIANO=EC.CRITERIANO
								and RE.EVENTNO=EC.EVENTNO
								and RE.REQEVENTNO=T.EVENTNO)
				where T.[STATE]='I'
				and   T.NEWEVENTDATE is not null"
		
				Execute @ErrorCode=sp_executesql @sSQLString, 
								N'@bDocumentsRequired		bit 		OUTPUT',
								  @bDocumentsRequired=@bDocumentsRequired	OUTPUT
			End

			If  @ErrorCode=0
			and @bDocumentsRequired=1
			Begin
				execute @ErrorCode = dbo.ip_PoliceDocumentCase @pnDebugFlag
			End
		End

		------------------------------------------------------------------------------------------------------------
		-- From State    | Action Performed                                                       | Change to State |
		--===============|========================================================================|=================|
		-- Reminder  (R) | 1. Change the STATE of the row to indicate that its processing has been| Finished (R1)   |
		-- Insert    (I) |    completed successfully or if it has just been inserted then it will |          (I1)   | 
		-- Delete    (D) |    be set to "I" for processing in the next pass or marked for         |          (D1)   |
                -- New Insert(IX)|    deletion "D" if it has just been deleted.                           | Insert   (I)    |
		-- New Delete(DX)|                                                                        | Delete   (D)    |
		------------------------------------------------------------------------------------------------------------

		-- Check to see if any events that can trigger a law change have occurred

		if @ErrorCode=0
		and @nCountStateI+@nCountStateR+@nCountStateRX>0
		Begin
			execute @ErrorCode = dbo.ip_PoliceCheckDateOfLaw @pnDebugFlag
		End

		if @ErrorCode=0
		Begin
			set @sSQLString="
			update	#TEMPCASEEVENT
			set	[STATE]=CASE ([STATE])	WHEN ('R')  THEN 'R1'
						   	WHEN ('RX') THEN 'R1'
						   	WHEN ('I')  THEN 'I1'
							WHEN ('D')  THEN 'D1'
							WHEN ('IX') THEN 'I'
							WHEN ('DX') THEN 'D'
					END
			where 	STATE in ('R','RX','I','D','IX','DX')"

			exec @ErrorCode=sp_executesql @sSQLString
		End
		------------------------------------------------------------------------------------
		-- If any Event has been processed more than a user defined number of times then a 
		-- potential loop may have occurred.  Flag all TempCaseEvent and TempOpenAction rows 
		-- for that Case as being in error.  This will cause that Case to be exclude in further 
		-- processing but allow other Cases to continue.
		------------------------------------------------------------------------------------
		If @ErrorCode=0
		and @nMainCount>@nLoopCount
		Begin
			Set @sSQLString="
			Update #TEMPCASEEVENT
			set [STATE]='E'
			From #TEMPCASEEVENT T
			where [STATE]<>'E'
			and exists
			(Select * from #TEMPCASEEVENT T1
			 where T1.CASEID=T.CASEID
			 and   T1.LOOPCOUNT>@nLoopCount)"

			Execute @ErrorCode=sp_executesql @sSQLString, 
						N'@nLoopCount   int',
					 	  @nLoopCount=@nLoopCount
			
			-- Flag any TEMPOPENACTION rows where the Case has
			-- exceeded the loop count.

			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Update #TEMPOPENACTION
				set [STATE]='E'
				From #TEMPOPENACTION T
				join #TEMPCASEEVENT TC	on (TC.CASEID=T.CASEID
							and TC.LOOPCOUNT>@nLoopCount)
				where T.[STATE]<>'E'"
	
				Execute sp_executesql @sSQLString, 
						N'@nLoopCount   int',
						  @nLoopCount=@nLoopCount
			End
			
			-- Flag any TEMPCASES rows where the Case has
			-- exceeded the loop count.

			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Update #TEMPCASES
				set ERRORFOUND=1
				From #TEMPCASES T
				join #TEMPCASEEVENT TC	on (TC.CASEID=T.CASEID
							and TC.LOOPCOUNT>@nLoopCount)
				where T.ERRORFOUND is null"
	
				Execute sp_executesql @sSQLString, 
						N'@nLoopCount   int',
						  @nLoopCount=@nLoopCount
			End
		End

		-- Check if there are any Open Actions that have been flagged to be recalculated
		-- If so then the recalculation needs to be done before any further processing of
		-- TEMPCASEEVENT. 

		If @ErrorCode=0
		Begin
			Set @bCalculateAction=0
			Set @sSQLString="
			Select @bCalculateActionOUT=1
			from #TEMPOPENACTION
			where [STATE] in ('C', 'CD')"
	
			Execute @ErrorCode=sp_executesql @sSQLString, 
							N'@bCalculateActionOUT	bit OUTPUT',
							  @bCalculateActionOUT=@bCalculateAction OUTPUT
		End

		-- Check if there are any more #TEMPCASEEVENT rows to process only if there 
		-- are no more Open Actions to be calculated.

		If @ErrorCode=0
		Begin
			If @bCalculateAction=1
			Begin 
				Set @nCountStateC      =0
				Set @nCountStateI      =0
				Set @nCountStateI1     =0
				Set @nCountStateD      =0
				Set @nCountStateR      =0
				Set @nCountStateR1     =0
				Set @nCountStateRX     =0
				Set @nCountParentUpdate=0
				Set @nCountPTAUpdate   =0
			End
			Else Begin	
				Set @sSQLString="
				select 
				@nCountStateC =Sum(CASE WHEN([STATE] like 'C%') THEN 1 ELSE 0 END),
				@nCountStateI =Sum(CASE WHEN([STATE]    = 'I' ) THEN 1 ELSE 0 END),
				@nCountStateI1=Sum(CASE WHEN([STATE]    = 'I1') THEN 1 ELSE 0 END),
				@nCountStateD =Sum(CASE WHEN([STATE]    = 'D' ) THEN 1 ELSE 0 END),
				@nCountStateR =Sum(CASE WHEN([STATE]    = 'R' ) THEN 1 ELSE 0 END),
				@nCountStateR1=Sum(CASE WHEN([STATE]    = 'R1') THEN 1 ELSE 0 END),
				@nCountStateRX=Sum(CASE WHEN([STATE]    = 'RX') THEN 1 ELSE 0 END),
				@nCountParentUpdate=Sum(CASE WHEN(UPDATEFROMPARENT=1) THEN 1 ELSE 0 END),
				@nCountPTAUpdate=Sum(CASE WHEN(PTADELAY>0) THEN 1 ELSE 0 END)
				from #TEMPCASEEVENT"

				Execute @ErrorCode=sp_executesql @sSQLString, 
								N'@nCountStateC		int OUTPUT,
								  @nCountStateI		int OUTPUT,
								  @nCountStateD		int OUTPUT,
								  @nCountStateR		int OUTPUT,
								  @nCountStateI1	int OUTPUT,
								  @nCountStateR1	int OUTPUT,
								  @nCountStateRX	int OUTPUT,
								  @nCountParentUpdate	int OUTPUT,
								  @nCountPTAUpdate	int OUTPUT',
								  @nCountStateC =@nCountStateC  OUTPUT,
								  @nCountStateI =@nCountStateI  OUTPUT,
								  @nCountStateD =@nCountStateD  OUTPUT,
								  @nCountStateR =@nCountStateR  OUTPUT,
								  @nCountStateI1=@nCountStateI1 OUTPUT,
								  @nCountStateR1=@nCountStateR1 OUTPUT,
								  @nCountStateRX=@nCountStateRX OUTPUT,
								  @nCountParentUpdate=@nCountParentUpdate OUTPUT,
								  @nCountPTAUpdate=@nCountPTAUpdate OUTPUT

			End
		End

	END	/* end the loop through #TEMPCASEEVENT	*/

	If @bFirstTimeFlag=1
	Begin
		set @bFirstTimeFlag=0
	End

	-- Recheck if any Actions need recalculating only if the CalculationAction flag is
	-- still turned on.  This is because the inner loop may never have been entered.

	If  @ErrorCode=0
	and @bCalculateAction=1
	Begin
		Set @bCalculateAction=0
		Set @sSQLString="
		Select @bCalculateActionOUT=1
		from #TEMPOPENACTION
		where [STATE] in ('C', 'CD')"
	
		Execute @ErrorCode=sp_executesql @sSQLString, 
						N'@bCalculateActionOUT	bit OUTPUT',
						  @bCalculateActionOUT=@bCalculateAction OUTPUT
	End

END	/* end the loop through #TEMPOPENACTION	*/

-- Update the CREATEDBYCRITERIA column of CASEEVENT as required.

if  @ErrorCode=0
and @bCriteriaUpdated=1
and @nUpdateFlag=1	-- SQA15503
Begin
	execute @ErrorCode = dbo.ip_PoliceUpdateCaseEventCriteria @pnDebugFlag
End

-- Calculate the next Reminder date for each calculated row if the database is to be updated.

set @nReminderCount=0

if  @ErrorCode=0
and @nCountStateR1>0
Begin
	-------------------------------------------------------------------------------
	-- SQA18891
	-- If calculated Due Dates has Reminders definition against other
	-- OpenAction rows then insert an additional TEMPCASEEVENT row for that Action.
	-- This will ensure those reminders are taken into consideration.
	-------------------------------------------------------------------------------
	Set @sSQLString="
	insert into #TEMPCASEEVENT
	(	CASEID, DISPLAYSEQUENCE, EVENTNO, CYCLE, LOOPCOUNT, OLDEVENTDATE, OLDEVENTDUEDATE, DATEDUESAVED, 
		OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA, 
		ENTEREDDEADLINE, PERIODTYPE, DOCUMENTNO, 
		DOCSREQUIRED, DOCSRECEIVED, USEMESSAGE2FLAG, GOVERNINGEVENTNO, [STATE], ADJUSTMENT,
		IMPORTANCELEVEL, WHICHDUEDATE, COMPAREBOOLEAN, CHECKCOUNTRYFLAG, SAVEDUEDATE, STATUSCODE,RENEWALSTATUS,
		SPECIALFUNCTION, INITIALFEE, PAYFEECODE, CREATEACTION, STATUSDESC, CLOSEACTION, RELATIVECYCLE,
		INSTRUCTIONTYPE, FLAGNUMBER, SETTHIRDPARTYON, COUNTRYCODE, NEWEVENTDATE, NEWEVENTDUEDATE,
		USEDINCALCULATION, DATEREMIND, USERID, IDENTITYID, CRITERIANO, ACTION, EVENTUPDATEDMANUALLY, ESTIMATEFLAG,
		EXTENDPERIOD, EXTENDPERIODTYPE, INITIALFEE2, PAYFEECODE2, ESTIMATEFLAG2,PTADELAY,SETTHIRDPARTYOFF,
		CHANGENAMETYPE, COPYFROMNAMETYPE, COPYTONAMETYPE, DELCOPYFROMNAME, DIRECTPAYFLAG, DIRECTPAYFLAG2,LIVEFLAG,RESPNAMENO,RESPNAMETYPE, RECALCEVENTDATE,
		SUPPRESSCALCULATION)
	select	T.CASEID, EC.DISPLAYSEQUENCE, T.EVENTNO, T.CYCLE, 0, T.OLDEVENTDATE, T.OLDEVENTDUEDATE, T.DATEDUESAVED, 
		T.OCCURREDFLAG, T.CREATEDBYACTION, T.CREATEDBYCRITERIA, 
		T.ENTEREDDEADLINE, T.PERIODTYPE, T.DOCUMENTNO, 
		T.DOCSREQUIRED, T.DOCSRECEIVED, T.USEMESSAGE2FLAG, T.GOVERNINGEVENTNO, T.[STATE], T.ADJUSTMENT,
		EC.IMPORTANCELEVEL, EC.WHICHDUEDATE, EC.COMPAREBOOLEAN, EC.CHECKCOUNTRYFLAG, EC.SAVEDUEDATE, EC.STATUSCODE,EC.RENEWALSTATUS,
		EC.SPECIALFUNCTION, EC.INITIALFEE, EC.PAYFEECODE, EC.CREATEACTION, EC.STATUSDESC, EC.CLOSEACTION, EC.RELATIVECYCLE,
		EC.INSTRUCTIONTYPE, EC.FLAGNUMBER, EC.SETTHIRDPARTYON, T.COUNTRYCODE, T.NEWEVENTDATE, T.NEWEVENTDUEDATE,
		T.USEDINCALCULATION, T.DATEREMIND, T.USERID, T.IDENTITYID, EC.CRITERIANO, CR.ACTION, T.EVENTUPDATEDMANUALLY, EC.ESTIMATEFLAG,
		EC.EXTENDPERIOD, EC.EXTENDPERIODTYPE, EC.INITIALFEE2, EC.PAYFEECODE2, EC.ESTIMATEFLAG2,EC.PTADELAY,EC.SETTHIRDPARTYOFF,
		EC.CHANGENAMETYPE, EC.COPYFROMNAMETYPE, EC.COPYTONAMETYPE, EC.DELCOPYFROMNAME, EC.DIRECTPAYFLAG,EC.DIRECTPAYFLAG2,T.LIVEFLAG,
		EC.DUEDATERESPNAMENO,EC.DUEDATERESPNAMETYPE, T.RECALCEVENTDATE, T.SUPPRESSCALCULATION
	from #TEMPCASEEVENT T
	join EVENTCONTROL EC	on (EC.EVENTNO=T.EVENTNO
	  			and exists (	select CRITERIANO
						from #TEMPOPENACTION OA
						join ACTIONS A on (A.ACTION=OA.ACTION)
						where OA.CASEID=T.CASEID
						and   OA.POLICEEVENTS=1
						and   isnull(OA.NEWCRITERIANO,OA.CRITERIANO)=EC.CRITERIANO
						and   OA.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED=1) THEN 1 ELSE T.CYCLE END))
	join CRITERIA CR	on (CR.CRITERIANO=EC.CRITERIANO)
	join (	select distinct CRITERIANO, EVENTNO
		from REMINDERS) RE	on (RE.CRITERIANO=EC.CRITERIANO
					and RE.EVENTNO=EC.EVENTNO)
	left join #TEMPCASEEVENT T1	on (T1.CASEID =T.CASEID
					and T1.EVENTNO=T.EVENTNO
					and T1.CYCLE  =T.CYCLE
					and(T1.ACTION=CR.ACTION OR T1.CREATEDBYACTION=CR.ACTION))
	where T.[STATE]='R1'
	and T1.CASEID is null -- ensure the row being inserted does not already exist"

	Exec @ErrorCode=sp_executesql @sSQLString
	Select @nCountStateR1=@nCountStateR1+@@Rowcount

	if @nUpdateFlag=1
	and @ErrorCode=0
	Begin
		If  @bLoadMessageTable=1
		Begin
			-- Load Policing Message Table
			Set @sSQLString="
			insert into "+@psPolicingMessageTable+"(MESSAGE) values('Calculate Reminder Dates')

			insert into "+@psPolicingMessageTable+"(MESSAGE)
			select C.IRN+' - '+isnull(EC.EVENTDESCRIPTION,E.EVENTDESCRIPTION)+'('+convert(varchar,T.EVENTNO)+'{'+convert(varchar,T.CYCLE)+'})'
			from #TEMPCASEEVENT T
			join CASES C	on (C.CASEID=T.CASEID)
			join EVENTS E	on (E.EVENTNO=T.EVENTNO)
			left join EVENTCONTROL EC
					on (EC.CRITERIANO=T.CREATEDBYCRITERIA
					and EC.EVENTNO   =T.EVENTNO)
			where T.[STATE]='R1'
			and exists 
			(select 1 from REMINDERS R
			 where R.CRITERIANO=T.CREATEDBYCRITERIA
			 and R.EVENTNO=T.EVENTNO)"
		
			exec @ErrorCode = sp_executesql @sSQLString
		End

		If @ErrorCode=0
		Begin
			execute @ErrorCode = dbo.ip_PoliceCalculateReminderDate
						@dtUntilDate, 
						@pnDebugFlag
		End
	End

	-- Generate reminders associated with Events

	if  @nReminderFlag=1
	and @ErrorCode=0
	Begin
		execute @ErrorCode = dbo.ip_PoliceInsertReminders 
					@dtFromDate, 
					@dtUntilDate, 
					@pnDebugFlag,
					@nReminderCount OUTPUT
	End

End

--  Extract any adhoc reminders to be sent

if  @nAdhocFlag=1
and @ErrorCode=0
Begin
	execute @ErrorCode = dbo.ip_PoliceInsertAlerts 
					@dtFromDate,
					@dtUntilDate,
					@sIRN,
					@sOfficeId,
					@sPropertyType,
					@sCountryCode,
					@sNameType,
					@nNameNo,
					@sCaseType,
					@sCaseCategory,
					@sSubtype,
					@nExcludeProperty,
					@nExcludeCountry,
					@nUpdateFlag,
					@pnDebugFlag,
					@nReminderCount OUTPUT

End

NothingToProcess:

-- Add the number of reminders created prior to the main Policing
-- process being run. 
Set @nReminderCount=@nReminderCount+@nPrePolicingReminders

-- If Policing is being run with the UpdateFlag set on then apply the changes 
-- currently held in the temporary tables to the live database.
-- Reminders and Letters will be generated as part of the update transaction
-- unless they are required but the database is not being updated.

Begin Try

if  @ErrorCode	=0
and @nUpdateFlag=1
Begin
	If @nCountStateI1>0
	Begin
		------------------------------------------------------------------------
		-- New POLICING request rows are to be created for any Event that
		-- has the potential to cause the Event in another Case to recalculate.
		-- For performance reason these requests have been separated out as they
		-- may be slow to process in their own right and they do not directly 
		-- impact on the Case that has triggered this behaviour.
		------------------------------------------------------------------------
		Set @sSQLString="
		insert into #TEMPPOLICINGREQUEST (CASEID,EVENTNO,CYCLE,TYPEOFREQUEST,CRITERIANO,SQLUSER,IDENTITYID)
		select	distinct T.CASEID,T.EVENTNO,T.CYCLE,8,T.CREATEDBYCRITERIA,T.USERID,T.IDENTITYID
		from #TEMPCASEEVENT T
		join #TEMPCASES TC		on (TC.CASEID=T.CASEID)
		-- Rule that requires a Case of the given Case Type 
		join EVENTCONTROL EC		on (EC.CASETYPE=TC.CASETYPE
						and EC.SAVEDUEDATE between 2 and 5)
		join EVENTCONTROLREQEVENT RE	on (RE.CRITERIANO=EC.CRITERIANO
						and RE.EVENTNO=EC.EVENTNO
						and RE.REQEVENTNO=T.EVENTNO)
		where T.[STATE]='I1'
		and   T.NEWEVENTDATE is not null"

		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If  @bLoadMessageTable=1
	and @ErrorCode=0
	Begin
		-- Load Policing Message Table
		Set @sSQLString="
		insert into "+@psPolicingMessageTable+"(MESSAGE) values('Update Database')"
	
		exec sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @nTransNo = ISNULL(@nTransNo,@pnSessionTransNo)

		execute @ErrorCode = dbo.ip_PoliceUpdateDataBase 
					@nReminderFlag, 
					@nAdhocFlag, 
					@nLetterFlag, 
					@bPTARecalc,
					@dtFromDate, 
					@dtUntilDate, 
					@dtLetterDate, 
					@dtStartDateTime,
					@nReminderCount,
					@nCountStateI1,
					@nCountStateR1,
					@nCountPTAUpdate,
					@pnDebugFlag,
					@pnUserIdentityId,
					@dtLockDateTime,
					@nTransNo,
					@pnEDEBatchNo,
					@bUniqueTimeRequired,
					@nUpdateQueueWait

		Set @nTransNo = NULL
	End
End
else Begin
	if  @ErrorCode=0
     	and (@nReminderFlag=1 or @nAdhocFlag=1)
	and @nReminderCount > 0 
     	Begin
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		if  @ErrorCode=0
		Begin
			execute @ErrorCode = dbo.ip_PoliceLoadEmployeeReminders @pnDebugFlag
		End

		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
     	End

	if  @ErrorCode=0
     	and @nLetterFlag=1
	and @nCountStateI1+@nCountStateR1>0
     	Begin
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		execute @ErrorCode = dbo.ip_PoliceInsertLetters 
					@dtFromDate, 
					@dtUntilDate, 
					@dtLetterDate, 
					@nCountStateI1,
					@nCountStateR1,
					@pnDebugFlag,
					@pnUserIdentityId,
					@bUniqueTimeRequired

		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
     	End
End

-- If reminders are being generated check to see if any are to be delivered electronically.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @nSendEmailOUT=1
	from #TEMPEMPLOYEEREMINDER
	where exists
	(select * from #TEMPEMPLOYEEREMINDER
	 where SENDELECTRONICALLY=1)"

	Execute @ErrorCode=sp_executesql @sSQLString, 
					N'@nSendEmailOUT	 int OUTPUT',
					  @nSendEmailOUT=@nSendEmail OUTPUT
End

if   @ErrorCode=0
and (@nReminderFlag=1 or @nAdhocFlag=1)
and  @nSendEmail=1
and  @bEmailFlag=1
Begin
	execute @ErrorCode = dbo.ip_PoliceSendEmails	@pnDebugFlag,
							@nUpdateFlag
End
End Try

Begin Catch
	set @SaveErrorCode = Error_Number()
	set @sErrorMessage = Error_Message()
	-- DR-49441 Add ERROR_LINE() & ERROR_PROCEDURE() to error message
	If isnull(PATINDEX('%Error Proc:%', @sErrorMessage), 0) = 0
		AND ERROR_PROCEDURE() is NOT NULL
	Begin 
		set @sErrorMessage = @sErrorMessage + 
			'; Error Proc: ' + isnull(ERROR_PROCEDURE(), '') +
			'; Error line number: ' +  isnull(CAST(ERROR_LINE() AS VARCHAR(20)),0) 
	End
	
	-- If there are Errors and no PolicingLog has already been written then it must be inserted now to allow
	-- PolicingErrors to be inserted.

	If @dtStartDateTime is null
	Begin

	PolicingLogInsert:
		Set @dtStartDateTime = getdate()
	
		Set @sSQLString="
		insert into POLICINGLOG (STARTDATETIME, USERNAME, POLICINGNAME,   FINISHDATETIME, FAILMESSAGE, SPID, SPIDSTART)
		select @dtStartDateTime, SYSTEM_USER,  'Invoked from Policing Server', @dtStartDateTime,'Database fail - see POLICINGERRORS',@@SPID, (SELECT last_request_start_time FROM dbo.fn_GetSysActiveSessions()  WHERE session_id=@@SPID)
		where @SaveErrorCode<>0"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@dtStartDateTime	datetime,
						  @SaveErrorCode	int',
						  @dtStartDateTime,
						  @SaveErrorCode

		If @ErrorCode in (2601, 2627)
	   		Goto PolicingLogInsert
	End

	-- Insert the PolicingErrors

	If  @SaveErrorCode>0
	and @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into POLICINGERRORS (STARTDATETIME, ERRORSEQNO, MESSAGE)
		select @dtStartDateTime, 1, cast(@sErrorMessage as nvarchar(254))"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@dtStartDateTime	datetime,
						  @sErrorMessage	nvarchar(4000)',
						  @dtStartDateTime,
						  @sErrorMessage
	End
	
	Set @ErrorCode=@SaveErrorCode
	
	Set @bErrorInserted=1
End Catch

Set @SaveErrorCode=@ErrorCode

-- If a looping error has been detected then insert a row into the TEMPPOLICINGERRORS for each CASEEVENT row
-- effected.  This will allow the ERRORSEQNO to be automatically assigned.

If  @ErrorCode=0
and @bErrorInserted=0
and @nMainCount>@nLoopCount
Begin
	Set @sSQLString="
	insert into #TEMPPOLICINGERRORS (CASEID, CRITERIANO, EVENTNO, CYCLENO, MESSAGE)
	select CASEID, CREATEDBYCRITERIA, EVENTNO, CYCLE, 'Loop count limit exceeded - check set up for potential loop'
	from #TEMPCASEEVENT 
	where LOOPCOUNT>@nLoopCount 
	and [STATE] = 'E' "

	Exec @ErrorCode=sp_executesql @sSQLString, 
				N'@nLoopCount   int',
				  @nLoopCount

	-- Set the SaveErrorCode to -2 if the loop count was actually exceeded
	-- on a Case Event

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Select @SaveErrorCodeOUT=-2
		from #TEMPCASEEVENT
		where exists
		(select * from #TEMPCASEEVENT
		 where LOOPCOUNT>@nLoopCount)"
	
		Execute @ErrorCode=sp_executesql @sSQLString, 
						N'@SaveErrorCodeOUT	int   OUTPUT,
						  @nLoopCount		int',
						  @SaveErrorCodeOUT=@SaveErrorCode OUTPUT,
						  @nLoopCount      =@nLoopCount
	End
End

-- Insert any POLICINGERRORS detected

Select @TranCountStart = @@TranCount

BEGIN TRANSACTION

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @nErrorsOUT=1
	from #TEMPPOLICINGERRORS
	where exists
	(select * from #TEMPPOLICINGERRORS)"

	Execute @ErrorCode=sp_executesql @sSQLString, 
					N'@nErrorsOUT	int OUTPUT',
					  @nErrorsOUT=@nErrors OUTPUT
End

If  @ErrorCode <> 0
OR  @nErrors is not null
Begin
	set @ErrorCode = 0 

	-- If there are Errors and no PolicingLog has already been written then it must be inserted now to allow
	-- PolicingErrors to be inserted.

	If @dtStartDateTime is null
	Begin

	LogInsert:
		Set @dtStartDateTime = getdate()
	
		Set @sSQLString="
		insert into POLICINGLOG (STARTDATETIME, USERNAME, POLICINGNAME,   FINISHDATETIME, FAILMESSAGE, SPID, SPIDSTART)
		select @dtStartDateTime, SYSTEM_USER,  'Invoked from Policing Server', @dtStartDateTime,
			CASE WHEN(@SaveErrorCode=-1) Then 'No entry found in POLICING table'
			End, @@SPID, (SELECT last_request_start_time FROM dbo.fn_GetSysActiveSessions()  WHERE session_id=@@SPID)
		where @SaveErrorCode<>0
		OR exists (select 1 from #TEMPPOLICINGERRORS)"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@dtStartDateTime	datetime,
						  @SaveErrorCode	int',
						  @dtStartDateTime,
						  @SaveErrorCode

		If @ErrorCode in (2601, 2627)
	   		Goto LogInsert
	End

	-- Insert the PolicingErrors
	If not exists (select 1 from POLICINGERRORS where STARTDATETIME=@dtStartDateTime and ERRORSEQNO=1)	-- RFC13570
	and    exists (select 1 from POLICINGLOG    where STARTDATETIME=@dtStartDateTime)
	and @ErrorCode = 0
	Begin
		If @SaveErrorCode>0
		Begin
			Set @sSQLString="
			insert into POLICINGERRORS (STARTDATETIME, ERRORSEQNO, MESSAGE)
			select @dtStartDateTime, 1, cast(description as nvarchar(254))
			from master..sysmessages
			where error=@SaveErrorCode
				and msglangid=(SELECT msglangid FROM master..syslanguages WHERE name = @@LANGUAGE)"

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@dtStartDateTime	datetime,
							  @SaveErrorCode	int',
							  @dtStartDateTime,
							  @SaveErrorCode
		End
		Else If @SaveErrorCode<-1
		     or @SaveErrorCode=0	-- SQA 7158
		Begin
			Set @sSQLString="
			insert into POLICINGERRORS (STARTDATETIME, ERRORSEQNO, CASEID, CRITERIANO, EVENTNO, CYCLENO, MESSAGE)
			select distinct @dtStartDateTime, 
					ROW_NUMBER() OVER(ORDER BY T.CASEID), -- Unique Sequence Number 
					T.CASEID, 
					T.CRITERIANO, 
					T.EVENTNO, 
					T.CYCLENO, 
					T.MESSAGE
			from (	select Distinct CASEID, CRITERIANO, EVENTNO, CYCLENO, MESSAGE
				from #TEMPPOLICINGERRORS) T"

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@dtStartDateTime	datetime',
							  @dtStartDateTime
		
			-- RFC61781
			-- If errors have been raised against a specific Case(s) as a result of a batch
			-- process, then generate a separate Policing request for each Case that needs
			-- recalculating.

			If not exists(select 1 from #TEMPPOLICING where CASEID is not null)
			and @nUpdateFlag=1
			and @ErrorCode  =0
			Begin
				Set @sSQLString="
				insert into POLICING(	DATEENTERED, POLICINGSEQNO, POLICINGNAME, CASEID, ACTION, CYCLE, SYSGENERATEDFLAG, ONHOLDFLAG, 
							TYPEOFREQUEST, RECALCEVENTDATE, SQLUSER, IDENTITYID)
				Select	@dtStartDateTime,
					ROW_NUMBER() OVER(ORDER BY CS.CASEID), -- Unique Sequence Number
					'Error-'+convert(varchar, @dtStartDateTime, 120)+convert(varchar,ROW_NUMBER() OVER(ORDER BY CS.CASEID)),
					CS.CASEID,
					CS.ACTION,
					CS.CYCLE,
					1 as SYSGENERATEDFLAG,
					2 as ONHOLDFLAG,	-- Indicates request has already attempted to be processed
					4 as TYPEOFREQUEST, 
					1 as RECALCEVENTDATE,
					SYSTEM_USER as SQLUSER,
					@pnUserIdentityId
				from (	Select distinct OA.CASEID, OA.ACTION, OA.CYCLE
					From POLICINGERRORS E
					join CRITERIA C on (C.CRITERIANO=E.CRITERIANO)
					join OPENACTION OA on (OA.CASEID=E.CASEID
							   and OA.ACTION=isnull(@sAction, C.ACTION) -- Use the original Action being Policed if it is available
							   and OA.POLICEEVENTS=1)
					Where E.STARTDATETIME=@dtStartDateTime) CS"

				Exec @ErrorCode=sp_executesql @sSQLString,
							N'@dtStartDateTime	datetime,
							  @sAction		nvarchar(3),
							  @pnUserIdentityId	int',
							  @dtStartDateTime	=@dtStartDateTime,
							  @sAction		=@sAction,
							  @pnUserIdentityId	=@pnUserIdentityId
			End
		End
	End

	-- If a specific Batch has been processed then terminate the processing of the 
	-- remaining batch as it may be important that all aspects of the batch correctly
	-- process.

	If @pnBatchNo is not Null
		Set @bTerminateBatch=1
End

-- Update the POLICINGLOG row if processing has completed with no errors.
if   @SaveErrorCode in (0,-2) --SQA10312
and  @ErrorCode=0
and (@nSysGeneratedFlag=0 or @nSysGeneratedFlag is null)
and @dtStartDateTime is not null
Begin
	If @SaveErrorCode=0
		Set @sSQLString="
		update	POLICINGLOG
		set	FINISHDATETIME=getdate()
		where	STARTDATETIME=@dtStartDateTime"
	Else
		Set @sSQLString="
		update	POLICINGLOG
		set	FAILMESSAGE='Looping error. Check Policing error log for details'
		where	STARTDATETIME=@dtStartDateTime"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@dtStartDateTime	datetime',
					  @dtStartDateTime
End

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

-- Reinstate the Error Code

Select @ErrorCode  = @SaveErrorCode

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	If @pnDebugFlag>1
	Begin
		Set @sSQLString="
		Select	C.IRN, C.CASEID, T.EVENTNO,T.CYCLE,T.[STATE],T.LOOPCOUNT,T.OLDEVENTDATE,T.NEWEVENTDATE,T.OLDEVENTDUEDATE,T.NEWEVENTDUEDATE,T.DATEREMIND,T.NEWDATEREMIND,
			T.*
		from 	#TEMPCASEEVENT T
		join	#TEMPCASES TC	on (TC.CASEID=T.CASEID
					and TC.ERRORFOUND is null)
		join	CASES C		on (C.CASEID=T.CASEID)
		where T.[STATE]<>'X'
		order by 1,2,3,4"

		Exec @ErrorCode=sp_executesql @sSQLString
	End

	Select convert(nvarchar,getdate(),126), 'ipu_Policing - End'
End

-- If the Policing Server was used to call this procedure then check to see if the procedure 
-- should restart

If  @ErrorCode=0
and @bTerminateBatch=0
and (@pdtPolicingDateEntered is null or @bLawRecalc=1)	-- this indicates Policing Server called the procedure
and @pnBatchNo is null
Begin
	Set @pdtPolicingDateEntered=null
	Set @pnPolicingSeqNo       =null
	Set @nSysGeneratedFlag     =null
	Set @bLawRecalc            =null
	
	-- Check to see if any Policing rows that have been left on hold need to be updated.
	-- Ignore rows that have Policing Errors or have been added in the last 10 minutes.
	If @bOnHoldReset=1
	and @nWaitPeriod>0
	Begin
		Set @nRetry=5
		While @nRetry>0
		and @ErrorCode=0
		Begin
			BEGIN TRY
				Select @TranCountStart = @@TranCount
				BEGIN TRANSACTION
				
				Set @sSQLString="
				Update POLICING
				Set ONHOLDFLAG=CASE WHEN(P.ONHOLDFLAG=2) THEN 2 ELSE 0 END, --RFC55253
				    BATCHNO   =null,	--RFC11908
				    SPIDINPROGRESS=null
				from POLICING P
				left join POLICINGERRORS E on (E.CASEID=P.CASEID
							   and E.MESSAGE not like 'Due date rule for this Event exists for more than 1 Action%')	-- RFC43200
				Where P.ONHOLDFLAG in (1,2,3,4)
				and P.SYSGENERATEDFLAG=1
				and datediff(minute, P.LOGDATETIMESTAMP, getdate())>@nWaitPeriod
				and P.CASEID is not null	
				and E.CASEID is null"

				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@nWaitPeriod	int',
								  @nWaitPeriod=@nWaitPeriod

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
				If ERROR_NUMBER()=1205
					Set @nRetry=@nRetry-1
				Else
					Set @nRetry=-1
					
				-- Wait 5 seconds before attempting to
				-- retry the update.
				If @nRetry>0
					WAITFOR DELAY '00:00:05'
				Else
					Set @ErrorCode=ERROR_NUMBER()
					
				If XACT_STATE()<>0
					Rollback Transaction
			END CATCH
		End -- While loop
	End

	-- Check to see if the Site Control to allow continuous Policing is on.  This must be checked
	-- on each cycle so that the user may modify the SiteControl to stop the continuous processing.
	-- Asynchronous Policing does not need to perform this check as it will be performed within
	-- the ipu_Policing_async procedure.
	If @pnAsynchronousFlag=1
	Begin
		Set @bContinue=0
	End
	Else Begin
		Set @sSQLString="
		Select @bContinueOUT=S.COLBOOLEAN
		from SITECONTROL S
		where S.CONTROLID='Police Continuously'"
	
		Execute @ErrorCode=sp_executesql @sSQLString, 
						N'@bContinueOUT	bit OUTPUT',
						  @bContinueOUT=@bContinue OUTPUT
	End

	If  @bContinue=1
	and @psDelayLength is not null
	and @ErrorCode=0
	Begin
		-- Now check to see if there are any unprocessed rows in Policing
		
		Set @bContinue=0

		Set @sSQLString="
		Select @bContinueOUT=1
		from POLICING
		where exists
		(select * from POLICING P
		 where SYSGENERATEDFLAG=1
		 and  isnull(P.SCHEDULEDDATETIME,getdate())<=getdate()
		 and ((P.BATCHNO=@pnBatchNo and isnull(P.IDENTITYID,@pnUserIdentityId)=@pnUserIdentityId) OR (P.BATCHNO is null and @pnBatchNo is null))
		 and  (P.ONHOLDFLAG=0 or P.ONHOLDFLAG is null or P.BATCHNO=@pnBatchNo)
		 and not exists
		(select * from #TEMPPOLICING T
		 where T.DATEENTERED  =P.DATEENTERED
		 and T.POLICINGSEQNO=P.POLICINGSEQNO
		 and T.TYPEOFREQUEST=P.TYPEOFREQUEST
		 and T.CASEID       =P.CASEID
		 and T.SQLUSER      =P.SQLUSER
		 and(T.ACTION       =P.ACTION       OR (T.ACTION       is null and P.ACTION       is NULL))
		 and(T.EVENTNO      =P.EVENTNO      OR (T.EVENTNO      is null and P.EVENTNO      is NULL))
		 and(T.CRITERIANO   =P.CRITERIANO   OR (T.CRITERIANO   is null and P.CRITERIANO   is NULL))
		 and(T.CYCLE        =P.CYCLE        OR (T.CYCLE        is null and P.CYCLE        is NULL))
		 and(T.COUNTRYFLAGS =P.COUNTRYFLAGS OR (T.COUNTRYFLAGS is null and P.COUNTRYFLAGS is NULL))
		 and(T.FLAGSETON    =P.FLAGSETON    OR (T.FLAGSETON    is null and P.FLAGSETON    is NULL))))"
	
		Execute @ErrorCode=sp_executesql @sSQLString, 
						N'@bContinueOUT		bit OUTPUT,
						  @pnBatchNo		int,
						  @pnUserIdentityId	int',
						  @bContinueOUT		=@bContinue OUTPUT,
						  @pnBatchNo		=@pnBatchNo,
						  @pnUserIdentityId	=@pnUserIdentityId

		-- If there are no rows in POLICING waiting to be processed then check 
		-- to see if the parameter to wait a period of time before restarting the process 
		-- has been passed as a parameter.

		If  @bContinue=0
		and @psDelayLength is not null
		Begin
			WAITFOR DELAY @psDelayLength
			Set @bContinue=1
		End

		If @ErrorCode=0
		Begin
			------------------------------------
			-- Check Policing Continuously again
			-- after the wait delay.
			------------------------------------
			Set @bContinue=0
			
			Set @sSQLString="
			Select @bContinueOUT=S.COLBOOLEAN
			from SITECONTROL S
			where S.CONTROLID='Police Continuously'"
		
			Execute @ErrorCode=sp_executesql @sSQLString, 
						N'@bContinueOUT	bit OUTPUT',
						  @bContinueOUT=@bContinue OUTPUT
		End

		If  @ErrorCode=0
		and @bContinue=1
		Begin
			-- SQA17622 insert a row into PROCESSREQUEST to indicate that policing continously is running
			-- this will enable Policing Server to display appropriate policing status to users.
			if not exists (	Select 1 
					from PROCESSREQUEST PR
					join master.dbo.sysprocesses sp on (sp.spid = PR.SPID and sp.login_time = PR.LOGINTIME)
					where PR.REQUESTTYPE = 'POLICING BACKGROUND' 
					and sp.spid = @@SPID ) 
			Begin
				Select @TranCountStart = @@TranCount
				BEGIN TRANSACTION
				Insert into PROCESSREQUEST (REQUESTTYPE, REQUESTDESCRIPTION, CONTEXT, SQLUSER, SPID, LOGINTIME)
				select N'POLICING BACKGROUND', N'POLICING BACKGROUND CONTINOUSLY', 'POLICING', CURRENT_USER, spid, login_time
				from master.dbo.sysprocesses 
				where spid = @@SPID

				set @ErrorCode = @@ERROR

				If @@TranCount > @TranCountStart
				Begin
					If @ErrorCode = 0
						COMMIT TRANSACTION
					Else
						ROLLBACK TRANSACTION
				End
			End

			if not exists(select 1 from tempdb.INFORMATION_SCHEMA.TABLES where TABLE_NAME like dbo.fn_PolicingContinuouslyTrackingTable(@@spid))
			begin
				Select @TranCountStart = @@TranCount
				BEGIN TRANSACTION

					set @sSQLString = 'create table ' + dbo.fn_PolicingContinuouslyTrackingTable(@@spid) + '(spid int)'
					exec @ErrorCode = sp_executesql @sSQLString

				If @@TranCount > @TranCountStart
				Begin
					If @ErrorCode = 0
						COMMIT TRANSACTION
					Else
						ROLLBACK TRANSACTION
				End
			end
		End


		If  @ErrorCode=0
		and @bContinue=1
		Begin
			-- Clear out the temporary tables
			truncate table #TEMPCASES
			truncate table #TEMPCASEINSTRUCTIONS
			truncate table #TEMPOPENACTION
			truncate table #TEMPCASEEVENT
			truncate table #TEMPEMPLOYEEREMINDER
			truncate table #TEMPALERT
			truncate table #TEMPACTIVITYREQUEST
			truncate table #TEMPPOLICINGERRORS

			-- Only clear out the #TEMPPOLICING table if not processing a
			-- specific Batch.  This is because we need to keep track of what entries
			-- in POLICING for the Batch have already been processed.

			If @pnBatchNo is null
				truncate table #TEMPPOLICING
	
			Set @bContinue=0
			
			-- Clear out the @dtUntilDate
			-- so that it gets reset to the
			-- current system date.
			Set @dtUntilDate=null
	
			-- Yes I know I should not be using a Goto however I am justifying it on the 
			-- basis of there already being a number of nested WHILE loops for what is 
			-- already a very large procedure.  In this instance I think the Goto is 
			-- probably more readable.
	
			Goto CommenceProcessing
		End
	End
End

-- DR-47863	only drop temp table if it exists
If object_id('tempdb..#TEMPPOLICING') is not null 
	drop table #TEMPPOLICING
If object_id('tempdb..#TEMPCASES') is not null 
	drop table #TEMPCASES
If object_id('tempdb..#TEMPCASEINSTRUCTIONS') is not null 
	drop table #TEMPCASEINSTRUCTIONS
If object_id('tempdb..#TEMPOPENACTION') is not null 
	drop table #TEMPOPENACTION
If object_id('tempdb..#TEMPCASEEVENT') is not null 
	drop table #TEMPCASEEVENT
If object_id('tempdb..#TEMPEMPLOYEEREMINDER') is not null 
	drop table #TEMPEMPLOYEEREMINDER
If object_id('tempdb..#TEMPALERT') is not null 
	drop table #TEMPALERT
If object_id('tempdb..#TEMPACTIVITYREQUEST') is not null 
	drop table #TEMPACTIVITYREQUEST
If object_id('tempdb..#TEMPPOLICINGERRORS') is not null 
	drop table #TEMPPOLICINGERRORS


If  @bLoadMessageTable=1
Begin
	Set @sSQLString="
	insert into "+@psPolicingMessageTable+"(MESSAGE, LASTMESSAGEFLAG) values('Policing finished.', 1)"

	exec sp_executesql @sSQLString
End

------------------------------------------------------------
-- RFC9296
-- If Policing is being run from a saved set of parameters,
-- then check if there are any outstanding requests to 
-- recalculate standing instructions held at the Case level.
-- If there are, then start a process runing in background 
-- to perform the recalculation.
------------------------------------------------------------
If @nSysGeneratedFlag=0
and @ErrorCode=0
Begin
	If exists (select 1 from CASEINSTRUCTIONSRECALC with (NOLOCK) where ONHOLDFLAG=0)
	begin
		-- RFC-39102 Use service broker instead of OLE Automation to run the command asynchronoulsly
		----------------------------------------------------
		-- Build command line to run cs_LoadCaseInstructions 
		-- using service broker
		----------------------------------------------------
		If @ErrorCode = 0
		Begin
			Set @sCommand = 'dbo.cs_LoadCaseInstructions'
			If @pnUserIdentityId is not null
				Set @sCommand = @sCommand + ' @pnUserIdentityId='+ convert(varchar,@pnUserIdentityId)
				
			exec @ErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
		End
	End
End

select @ErrorCode
return @ErrorCode
go

grant execute on dbo.ipu_Policing  to public
go