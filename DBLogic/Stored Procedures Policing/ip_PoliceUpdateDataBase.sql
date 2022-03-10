-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_PoliceUpdateDataBase 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_PoliceUpdateDataBase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_PoliceUpdateDataBase.'
	drop procedure dbo.ip_PoliceUpdateDataBase
end
go
print '**** Creating procedure dbo.ip_PoliceUpdateDataBase...'
print ''

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ip_PoliceUpdateDataBase 
			@pnReminderFlag 	decimal(1,0),
			@pnAdhocFlag	 	decimal(1,0),
			@pnLetterFlag		decimal(1,0),
			@pbPTARecalc		bit, 
			@pdtFromDate		datetime, 
			@pdtUntilDate		datetime, 
			@pdtLetterDate		datetime, 
			@pdtStartDateTime	datetime,
			@pnRowCount		int,
			@pnCountStateI1		int,
			@pnCountStateR1		int,
			@nCountPTAUpdate	int,
			@pnDebugFlag		tinyint,
			@pnUserIdentityId	int	= null,
			@pdtLockDateTime	datetime,
			@pnSessionTransNo	int = null,	-- Audit transaction number assocated with the caller session.  Only applicable for asynchronous mode.
			@pnEDEBatchNo		int = null,	-- Batch number held in CONTEXT_INFO.  Passed when Policing called asynchronously.
			@pbUniqueTimeRequired	bit = 0,
			@nUpdateQueueWait	int = 0

as
-- PROCEDURE :	ip_PoliceUpdateDataBase
-- VERSION :	118
-- DESCRIPTION:	The changes currently held in temporary tables will be applied to the database and committed.
-- COPYRIGHT: 	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- CALLED BY :	ipu_Policing
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 13/03/2001	MF			Procedure created
-- 25/09/2001	MF	7069		When the due date of an event has changed the Employee Reminder is to b
--					deleted if there are no comments against it and allowed to be reissued.
-- 10/09/2001	MF	7109		Allow CASEEVENT rows to be deleted even if their DATEDUESAVED flag is set to 1
-- 15/10/2001	MF	7120		Move the inserting of letters to before the updating of CASES and PROPERTY so
--					that the check of the Status in these tables is before the updates generated
--					by this Policing execution.
-- 14/11/2001	MF	7189		If the CREATEDBYCRITERIA is NULL then do not update the CASEEVENT row as it is 
--					probable that the CREATEBYCRITRIA
-- 16/11/2001	MF	7190		Use sp_executesql for all SQL to improve performance by avoiding recompiles
-- 01/03/2002	MF	7367 		When inserting ACTIVITYREQUEST rows for charges also insert the ESTIMATEFLAG.
-- 12/03/2002	MF	7485		Change the function USER to SYSTEM_USER
-- 08/04/2002	MF	7367		When writing an ActivityRequest row for a charge request make sure that
--					the PAYFEECODE column can be set to NULL for estimate only requests.
-- 16/05/2002	MF	7667		Ensure that ACTIVITYREQUEST rows are inserted with a different WHENREQUESTED
--					date and time stamp to any rows inserted into ACTIVITYHISTORY as this may 
--					result later in a duplicate key error in the Charge Generation or Document
--					Server program.
-- 07/06/2002	MF	7719		When Policing is being run with Update it is possible for an error to occur 
--					if an Event generates a charge and no previous ActivityHistory data for the 
--					Case exists.  The error was caused because NULL is being returned when 
--					trying to extract the current highest WHENREQUESTED date for the Case.
-- 25/06/2002	MF	7765		Make certain that the USERID that triggered the policing request carrys
--					through to any other TEMPCASEEVENT rows.
-- 21/08/2002	MF	7627		Allow a second Fee to be requested when an Event is updated.
-- 22/08/2002	MF	7946		Extend the size of the USERID to avoid truncation errors.
-- 23/09/2002	MF	7979		Charges are not be raised when the Event was updated via a checklist.  This is
--					because the checklist is setting the OCCURREDFLAG to 4 instead of 1.  Modify
--					the test to allow an OCCURREDFLAG betwen 1 and 8
-- 17/02/2003	MF	8429		Only apply updates if the OpenAction row for the Case has not been flagged
--					in error.  This is as a result of allowing Loop Count errors to only effect the
--					specific Cases involved.
-- 03/03/2003	MF	8465		When an Event is updated from a related Case, Policing is not setting the 
--					OCCURREDFLAG.
-- 09/04/2003	MF	8647		A manually entered due date is not correctly being marked as Satisfied by the 
--					occurrence of the related event.
-- 26/05/2003	MF			Do not perform any updates if TEMPCASES is marked as having an error.
-- 10/06/2003	MF	8892		The Policing row may be deleted even if no matching row exists in TEMPCASES.
-- 14 Jul 03	MF	8975	10	Get the Renewal Event and Cycle that updated the Renewal Status.
-- 25 Jul 03	MF	8260	11	Cases flagged to recalculate the Patent Term Adjustment are to recalculate
--					the columns.
-- 08 Jan 2004	MF	9538	12	Policing.OnHoldFlag may now be 1,2,4 at the end of processing.
-- 26 Feb 2004	MF	RFC709	13	To identify workbench users add the parameter @pnUserIdentityId
-- 10 May 2004	MF	SQA9865	14	Generate multiple charge requests into ACTIVITYREQUEST if there are multiple
--					debtors held against the Case and the SiteControl option requires separate
--					calculations per debtor.
-- 12 May 2004	MF	SQA10033 15	Delete Employee Reminders if the Due Date has been cleared out or the Event
--					has now occurred.  Also delete Employee Reminders where all of the Reminder
--					rules for the Event have been removed.
-- 02 Jun 2004	MF	SQA10127 16	Provide a SiteControl that must be ON to allow Policing to remove no longer
--					required EmployeeReminders.
-- 30 Jun 2004	MF	SQA10127 17	Revisit of 10127 to extend the function to allow individuals to override the
--					the default setting of the SiteControl.
-- 03 Sep 2004	MF	SQA10440 18	Revisit SQA10127 to remove another source of where the Employee Reminder
--					was being deleted.
-- 13 Sep 2004	MF	RFC1327	 19	Allow Policing of specific ALERT row to be processed.
-- 15 Nov 2004	MF	SQA10658 20	Insert a row in the PROPERTY table if the RenewalStatus is set 
--					but there is no PROPERTY row already in existence.
-- 06 Dec 2004	MF	SQA10771 21	Delete ALERT rows being processed if they have no Due Date or Occurred Date.
-- 07 Dec 2004	MF	SQA10593 22	Ensure that rows written to the ACITIVITYHISTORY have a different datetime
--					stamp to those written to ACTIVITYREQUEST.  This ensures that when the 
--					ACTIVITREQUEST row is eventually processed and moved to ACTIVITYHISTORY that
--					a duplicate key error is avoided.
-- 25 Feb 2005	MF	RFC2375	 23	If the appropriate options are on then remove EmployeeReminders generated
--					from an Alert where the Alert is no longer due. Related to SQA10127.
-- 09 Jun 2005	MF	SQA11480 24	Duplicate error on ActivityRequest when client PC time is in advance of server.
-- 02 Dec 2005	MF	SQA11777 25	Generate a separate Charge Request for each RateNo associated with 
--					the Charge Type that is being requested to be raised.
-- 05 Dec 2005	AB		 26	Add collate database_default to temp table #TEMPCHARGEREQUEST.
-- 22 Feb 2006	MF	SQA12336 27	Extension to 11777 that will now dynamically determine which RateNo(s) associate
--					with a Charge Type to raise requests for depending on the characteristics
--					of the Case being processed.
-- 17 May 2006	MF	SQA12684 28	Duplicate key error inserting rows into ACTIVITYREQUEST.  This is caused because
--					SQLServer gives the same result when adding 18ms to a DateTime as adding 15ms.
-- 17 May 2006	MF	SQA12315 29	When an event occurs it may now trigger changes to CASENAME entries to be applied.
-- 21 Jun 2006	MF	SQA11777 30	Revisit.  The best fit rule was incorrect and too many Rates may have been returned.
-- 22 Jul 2006	MF	SQA13036 31	Manually inserting a CaseEvent that causes Change of Name Type was not
--					triggering the the CaseName changes.  This was because the system was trying 
--					to only do this when a CaseEvent was marked as occurred for the first time.  The
--					problem is that manually entered Events have no way of knowing that they just
--					occurred.  An extra test has been included to say the OLDEVENTDATE must equal the
--					NEWEVENTDATE but the OLDEVENTDUEDATE must be empty.
-- 21 Aug 2006	MF	SQA13089 32	The DIRECTPAYFLAG is to be considered when raising charges.
-- 31 Aug 2006	MF	SQA13344 33	Change the SQL that determines the RateNo(s) associated with ChargeType.
-- 11 Sep 2006	MF	SQA13416 34	Allow for the situation where an Event is triggering a Name change but no
--					Copy To NameType has been provided.
-- 09 Oct 2006	MF	SQA13580 35	Allow Name Changes to be triggered when the Event is updated and not just
--					when the event occurs for the first time.
-- 25 Oct 2006	MF	SQA13645 36	Consider Standing Instruction when determining the Rate Calculations to
--					raise against a Charge Type.
-- 02 Nov 2006	MF	SQA13724 37	If Policing concurrency option is in use then delete the rows from the
--					Policing table used to block a Case in progress from being policed.
-- 08 Dec 2006	MF	SQA13344 38	Change the SQL that determines the RateNo(s) associated with ChargeType.
-- 09 Jan 2007	MF	SQA12548 39	Update the FROMCASEID column on the CASEEVENT table.
-- 06 Feb 2007	MF	SQA13333 40	A transaction id is to be allocated and made available for the audit logs
--					to access and record.
-- 23 Feb 2007	MF	SQA14431 41	Clear out the HOLDUNTILDATE once the date is reached.
-- 02 Apr 2007	MF	SQA14650 42	SQL statement exceeded 4000 character maximum.
-- 29 May 2007	MF	SQA14812 43	All CASEEVENTS are now loaded into TEMPCASEEVENT to improve performance.  Only
--					update if STATE<>'X'
-- 30 Aug 2007	MF	SQA14425 44	Reserve word [STATE]
-- 19 Oct 2007	vql	SQA15318 45	Include BatchNo when inserting into TRANSACTIONINFO and setting CONTEXT
-- 09 Nov 2007	MF	15518	46	During performance improvements also discovered duplicate key error inserting
--					into OPENACTION.  Changes to ip_PoliceGetOpenActions have addressed this problem
--					however an additional safeguard will be included in this procedure.
--					Also load Policing Requests that resulted from Document Case Events triggering
--					other Case Events to occur.
-- 07 Jan 2008	MF	15586	 46	Allow a specific Name or NameType to be associated with a CaseEvent due date.
-- 07 Feb 2008	MF	15188	47	Pass @pnSessionTransNo and @pnEDEBatchNo when Policing is run asynchronously as
--					this information is associated with the original SPID not the one executing
--					Policing.
-- 07 Feb 2008	MF	SQA15865 43	Additional data required in CONTEXT_INFO for audit triggers to pick up.
-- 13 Feb 2008	MF	SQA15865 43	Revisit.  Ensure @bHexNumber is varbinary(128)
-- 25 Feb 2008	DL		 48	Syntax error correction.
-- 10 Mar 2008	MF	16070	48	The ACTIVITYREQUEST and ACTIVITYHISTORY tables now have a system assigned unique
--					identity column as the unique primary key. As a result the WHENREQUESTED datetime
--					stamp is no longer required to be unique so we can simplify the code used to 
--					ensure rows written were always unique.  This will create a performance improvement.
-- 07 Apr 2008	MF	14208	49	Minor correction to update of CASEEVENT.CREATEDBYCRITERIA.
-- 29 Apr 2008	MF	16319	50	Employee Reminders are being deleted and reinserted when the Reminder Rule
--					does not exist under the same criteria that created the due date.
-- 13 May 2008	MF	16410	51	Due date on Employee Reminder is not being changed when due date on Alert is
--					moved forward. Should work the same as for CaseEvent changes.
-- 14 May 2008	MF	16419	52	Rearrange the order in which the tables in the database are updated to reduce
--					the possibility of deadlocks occurring with other Policing processes.
-- 22 May 2008	MF	16430	53	Global Name change requests are to be loaded into a table in the database and 
--					the request started asynchronously.
-- 13 Jun 2008	MF	16545	54	Change call to sp_oamethod to pass an output parameter which will stop the
--					procedure from returning a result set which is causing the calling Centura
--					program to crash.
-- 23 Jun 2008	MF	16430	55	Revisit. Move the asynchronous call to cs_GlobalNameChange outside of the 
--					Policing transaction so that it occurs after the transaction has been committed.
--					Also change the call to cs_GlobalNameChangeByTransNo so that only one call needs
--					to be made to handle all of the separate Global Name Change requests.
-- 24 Jun 2008	MF	16577	56	Old Name Types should be using 'Start date' to indicate when the name became old.
--					Also set the Expiry Date on any existing COPYTONAMETYPE that is about to get a 
--					new NameNo inserted into it.
-- 07 Jul 2008	MF	16663	57	Improve performance of EMPLOYEEREMINDER delete by removing Join to SITECONTROL.
-- 26 Jun 2008	MF	16610	57	Prefix the POLICING.POLICINGNAME colum with POL- to indicate that this 
--					procedure inserted the row. This is for debugging reasons.
-- 04 Jul 2008	MF	16651	58	If more than one Event triggers the same copying of a CASENAME to another NameType
--					then we need to ensure a duplicate key error on CASENAME does not occur.
-- 10 Jul 2008	MF	16690	58	Need to reinstate the unique datetime stamp as an option when inserting rows
--					into ACTIVITYREQUEST.
-- 22 Jul 2008	MF	16734	59	Recode DELETE of CASEEVENT to avoid Internal Error from SQLServer 2000.
-- 26 Aug 2008	MF	16852	60	Reset EMPLOYEEREMINDER.DATEUPDATED to current system date on each update
-- 27 Aug 2008	MF	16846	59	Ensure the BatchNo is passed into the CASENAMEREQUEST row written for global name changes.
-- 01 Sep 2008	MF	16867	60	The TRANSACTIONREASON and TRANSACTIONMESSAGE is to be set to a default value when inserting
--					a row into TRANSACTIONINFO.
-- 07 Oct 2008	MF	16962	61	Creation of Old Name Type not occurring when Event Date manually entered. This is because the 
--					code is checking that the OLDEVENTDATE and NEWEVENTDATE are different.  Need to ensure there is
--					a NEWEVENTDATE only.
-- 10 Oct 2008	MF	16998	62	Revisit 16651 to correct problem.
-- 21 Oct 2008	MF	16998	63	Revisit 16998.
-- 04 Nov 2008	MF	17094	64	EMPLOYEEREMINDER rows associated with an ALERT should only be Updated or Deleted if the SEQUENCENO
--					of the ALERT matches with SEQUENCENO of the EMPLOYEEREMINDER. This will allow multiple Alert reminders
--					for the same Case to exist.
-- 08 Dec 2008	MF	17161	65	CREATEDBYACTION is being cleared out under some situations.
-- 11 Dec 2008	MF	17136	66	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 16 Jan 2009	MF	17298	67	Optionally control the application of updates to the database by checking if this connection (SPID)
--					is next in the queue to be processed.
-- 05 Feb 2009	vql	17350	68	Batch no in TRANSACTIONINFO table should be null for non EDE changes.
-- 14 Apr 2009	MF	17601	69	Charges raised when a letter is placed on a queue were incorrectly referring to #TEMPACTIVITYREQUEST
--					which was removed as a result of a performance improvement.
-- 20 May 2009	MF	17708	70	Trap a deadlock error (1205) where this process has been chosen as the victim and reset the code to allow
--					another attempt to apply updates to the database.
-- 26 May 2009	MF	17708	71	Revisit 17708. Need to use the BEGIN TRY and BEGIN CATCH construct to trap the deadlock error.
--					NOTE : SQLServer 2005 or higher is required.
-- 02 Jul 2009	MF	17844	72	Revisit of 17748 to set the @ErrorCode variable in the BEGIN CATCH.
-- 09 Jul 2009	MF	17853	73	Improve performance on deletes of EMPLOYEEREMINDER by changing single DELETE into multiple statement.
-- 13 Jul 2009	MF	17863	74	Incorrectly getting BatchNo for SPID which cannot be relied up.  Remove this code.
-- 20 Jul 2009	MF	17878	75	When applying changes of Names, also check if the Correspondence Name (Attention) has changed.
--					Also move the Delete of the COPYFROMNAMETYPE CASENAME rows so that it occurs irrespective of if any 
--					names are actually changed.
-- 02 Sep 2009	MF	17983	76	Reinstate code from SQA15586 that was lost during a ClearCase merge.
-- 11 Sep 2009	MF	18041	72	Improve performance of when Policing identifies Events to trigger a change of name. Restructure SELECT
--					as current SELECT can run slow on large batches resulting in blocks.
-- 15 Sep 2009	MF	9030	77	When an Event associated with a Number Type is being applied to the database, update the Date In Force
--					for Official Number if no value already exists from the EventDate.
-- 16 Sep 2009	MF	17773	78	An Event that may push a date into another Case is also now able to push an official number into the
--					same Case.
-- 26 Oct 2009	MF	17949	79	Removal of debug code found during testing of 17949
-- 07 Jan 2010	MF	18198	80	When Employee Reminders are being automatically deleted as a result of the Case Status not allowing reminders,
--					an additional check is required to restrict this to only system generated reminders as Ad Hoc reminders are
--					allowed to be sent even if the Case does not normally receive reminders.
-- 08 Feb 2010	MF	18443	81	Employee Reminders being generated from an Ad Hoc associated with a Name should only be deleted
--					when there is a match on the name and the due date has subsequently changed.
-- 11 Feb 2010	MF	18456	82	Only one cycle of an Event is being loaded as a result of a line of code being removed by
--					a ClearCase merge.
-- 04 Mar 2010	MF	18525	83	Reminders for satisfied events that have not occurred are no longer being removed.
-- 11 May 2010	MF	18732	84	When the due date of an Event is changed this will normally regenerate any associated reminders however
--					if there is a Comment against the reminder the due date should be modified on the reminder even if it is
--					not deleted.
-- 25 May 2010	MF	18767	85	Change Delete of EMPLOYEEREMINDER rows generated by ALERT where ALERT no longer exists. Will improve 
--					performance by splitting into separate DELETE statements.
-- 26 May 2010	MF	18765	86	Do not insert any CASEEVENT rows where EVENTDATE and EVENTDUEDATE are both null
-- 29 Jun 2010	MF	18858	87	Always check if any letters are to be inserted irrespective of the STATE count.
-- 29 Oct 2010	MF	19124	88	Revisit of 18765. Only delete #TEMPCASEEVENT rows wht null EVENTDATE and EVENTDUEDATE if State not like 'D%'
-- 31 Oct 2010	MF	18494	88	Alerts may now be created with no specific Due Date. Instead a Trigger EventNo is specified which will be 
--					used to set the DueDate and start sending reminders.  Do not delete ALERT rows that are missing a Due Date
--					if they also have a Trigger EventNo
-- 04 Nov 2010	MF	R9922	89	If the TabeCodes entry 'Policing removes satisfied reminders' with TABLECODE=9900 does not exist then the
--					dynamically constructed delete of the EMPLOYEEREMINDER row was being set to NULL and so no delete occurred.
-- 25 Nov 2010	MF	R10007	90	Revisit of 18767. Ensure EMPLOYEEREMINDER rows from an ALERT will still delete when the ALERT has a date 
--					occurred entered against it.
-- 21 Dec 2010	MF	R10122	91	Change of Renewal Status was not setting the associated Stop Pay Reason.
-- 28 Feb 2011	MF	19451	92	Loop count error not being logged when Event causing loop does not have an EventDate or Due Date. 
-- 20 Apr 2011	MF	RFC10333 93	Reminders generated from an Alert or forwarded from another Reminder generated by an Alert can now
--					refer back to the original Alert as a result of a new ALERTNAMENO column on the EMPLOYEEREMINDER table.
-- 12 Apr 2011	MF	19504	93	Events that trigger a change of Name should be allowed to do so even if the Name already exists against
--					the case for the given Name Type.  This will result in a global name change request that will trigger any
--					inheritance rules that may currently contain gaps.
-- 30 May 2011	MF	RFC10724 94	When deleteing EmployeeReminders need to consider the Source of the Reminder and not just whether an Event i
--					referenced or not.  This is because an Ad Hoc Alert may trigger a Reminder on the occurrence of an Event and
--					we want to avoid accidentally removing these reminders.
-- 02 Jun 2011	MF	19504	95	Revisit after failed testing. By always forcing the Global Name Change, some NameTypes that would have been inherited
--					were in fact overwriting the inherited Name. The order of the GNC transactions will now be such that those that do not
--					trigger inheritance are applied first, followed by those that trigger inheritance but are themselves inherted and then 
--					finally those that trigger inheritance but are not inherited themselves.
-- 01 Jul 2011	MF	10929	96	Keep track of when the CASES and PROPERTY rows were last updated so that we can check that no changes
--					have been applied to the database when Policing attempts to update these.

-- 17 Oct 2011	MF	R11431	97	Due Date Resp Name no longer appears after user manually updates event due date. Policing is clearing the
--					responsible name and name type.
-- 21 Oct 2011	MF	R11457	98	CaseEvents whose CREATEDBYCRITERIA is being changed also require the CREATEDBYACTION to be updated.
-- 16 Dec 2011	MF	20220	99	If the Stop Pay Date is removed, then the Stop Pay Reason should be removed also. 
--					These fields always go together and should always be both populated or both empty.
-- 20 Dec 2011	MF	R11723	100	Resetting failed Policing requests needs to consider if looping error has occurred.
-- 11 Apr 2012	MF	R12161	101	Database level errors (such as caused by a constraint) are not being correctly captured so they can be saved in POLICINGERRORS.
-- 26 Jun 2012	MF	R12201	102	Alerts that are directed to a recipient based on rules stored against the Alert are to actually generate
--					an Alert row for each recipient that can be determined. These rows will exist in the #TEMPALERT table and will  be copied
--					to the ALERT table.
-- 27 Nov 2012	MF	20912	103	Push through the EDE BatchNo on a change of name request being generated.
-- 28 May 2013	DL	10030	104	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 12 Jul 2013	Dw	R12904	105	Replaced reference to site control 'Charge Gen by All Debtors' with 'WIP Split Multi Debtor'.

-- 05 Jul 2013	MF	R13635	105	Related to R12201. Employee Reminders generated by an Alert are being deleted when a matching Alert cannot be found. The
--					join to the ALERT table should use the ALERNAMENO as this is the source of the reminder.
-- 16 Jul 2013	MF	R13662	105	After loading POLICING rows for Case Events that are waiting on a Document, ensure the rows in #TEMPPOLICINGREQUEST are removed.
-- 22 Aug 2014	MF	R38000	106	When Employee against caseevent has been changed, do not reset it when the CaseEvent is recalculated and updated.
-- 14 Oct 2014	DL	R39102	107	Use service broker instead of OLE Automation to run the command asynchronoulsly

-- 11 Jun 2015	MF	R45361	108	Cater for requests to distribute Prior Art across the extended Case family determined from RelatedCases. The potential for large volumes of Cases
--					that can be impacted has required this to run as a separate asynchronous process from the triggering activity.
-- 18 May 2016	MF	R61791	108	Reset ONHOLDFLAG to 4 if POLICINGERROR just generated. Previously it was being reset to 1.
-- 26 Aug 2016	MF	R66016	109	When the CPA Start Pay Date occurs then any value in the STOPPAYREASON should be cleared out.
-- 12 Sep 2016	MF	66861	110	Whenever Policing is processing prior art rows into the CASESEARCHRESULT table, add another step to ensure that the Case is not linked 
--					to the same PriorArt multiple times unless it is because of a Family, CaseList or Name.
-- 14 Sep 2016	MF	68323	111	Only apply changes to the database if the Case still exists. This is to handle the situation where a Case has been deleted after
--					the Policing request has commenced.
-- 19 Oct 2016	MF	69566	112	EmployeeReminder table is updated when there is a change of EventDueDate.  There is an extra update when the reminder has a Comment which
--					should be removed.
-- 20 Apr 2017	MF	70830	113	When an Official Number has been pulled down from a parent case by Policing, we need to update the CURRENTOFFICIALNO on the CASES table.
-- 19 Jul 2017	MF	71968	114	When determining the default Case program, first consider the Profile of the User.
-- 11 Jan 2018	MF	73259	115	An employee name associated with a due date should not be cleared out when the Event occurs.
-- 14 Nov 2018  AV	DR-45358 116	Date conversion errors when creating cases and opening names in Chinese DB
-- 12 Jun 2019	MF	DR-49537 117	Increase the number of retry attempts and the wait time when the process is the victim of a deadlock error.  Also lower the deadlock priority to 
--					make this process the preferred victim.
-- 18 Jun 2019	DL	DR-49441 118	Provide more information in the Error Log Message of the Policing Dashboard
--
set nocount on
set DEADLOCK_PRIORITY -1
-- A temporary table to load all of the possible global name changes that will be required
CREATE TABLE #TEMPGLOBALNAMECHANGES(
	CHANGENAMETYPE		nvarchar(3)	collate database_default NOT NULL,
	COPYFROMNAMETYPE	nvarchar(3)	collate database_default NOT NULL,
	COPYFROMNAMENO		int		NOT NULL,
	COPYFROMREF		nvarchar(80)	collate database_default NULL,
	COPYFROMATTN		int		NULL,
	EDEBATCHNO		int		NULL,
	COMMENCEDATE		datetime	NULL,
	SEQUENCENO		int		identity(1,1)
 )

-- A temporary table to store the Cases that are to have the global name change applied
CREATE TABLE #TEMPCASESFORNAMECHANGE(
	CASEID			int		NOT NULL
 )

DECLARE	@ErrorCode		int,
	@TranCountStart 	int,
	@nMaxID			int,
	@nChargeRequests	int,
	@nSequenceNo		int,
	@nCaseId		int,
	@nGlobalChanges		int,
	@nCopyFromNameNo	int,
	@nCopyFromAttn		int,
	@nNamesUpdatedCount	int,
	@nNamesInsertedCount	int,
	@nNamesDeletedCount	int,
	@nCaseCount		int,
	@nTransNo		int,
	@nEDEBatchNo		int,
	@nBatchNo		int,
	@nOfficeID		int,
	@nLogMinutes		int,
	@nStopPayEvent		int,
	@nStartPayEvent		int,
	@nKeepReferenceNo	smallint,
	@nDeadlockCount		tinyint,
	@bMultiDebtor		bit,
	@bRemoveReminder	bit,
	@bRemoveReminderOveride	bit,
	@bCaseNameLog		bit,
	@bHexNumber		varbinary(128),
	@dtTimeStamp		datetime,
	@dtTimeStamp1		datetime,
	@dtCommenceDate		datetime,
	@dtStartTime		datetime,
	@sChangeNameType  	nvarchar(3),
	@sCopyFromNameType	nvarchar(3),
	@sCopyFromRef		nvarchar(80),
	@sProgramId		nvarchar(8),
	@sDelayLength		nvarchar(6),
	@sSQLString		nvarchar(max),
	@sFrom			nvarchar(1000),
	@sWhere			nvarchar(1000),
	@nRequestNo		int,
	@nQueueId		int,
	@nRetry			smallint

-- Variables for background processing
declare	@nObject		int
declare	@nObjectExist		tinyint
declare	@sCommand		varchar(255)
------------------------------------
-- Variables for trapping any errors
-- raised during database update.
------------------------------------
declare @sErrorMessage		nvarchar(4000)
declare @nErrorSeverity		int
declare @nErrorState		int

-- Initialise the errorcode and then set it after each SQL Statement

Set @ErrorCode	     = 0
Set @nDeadlockCount  = 0
Set @nChargeRequests = 0
Set @nGlobalChanges  = 0 
Set @nRetry          = 5
Set @nQueueId	     = null
Set @dtStartTime     = null

--------------------------------------
-- SQA15865
-- Initialise variables that will be 
-- loaded into CONTEXT_INFO for access
-- by the audit triggers
--------------------------------------

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @nOfficeID=COLINTEGER
	from SITECONTROL
	where CONTROLID='Office For Replication'

	Select @nLogMinutes=COLINTEGER
	from SITECONTROL
	where CONTROLID='Log Time Offset'"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nOfficeID	int		OUTPUT,
				  @nLogMinutes	int		OUTPUT',
				  @nOfficeID  = @nOfficeID	OUTPUT,
				  @nLogMinutes=@nLogMinutes	OUTPUT
End
-- A sitecontrol is used to indicate if the rows inserted into ACTIVITYREQUEST
-- must have a unique WHENREQUESTED column.  This is to maintain backward
-- compatibility with earlier versions before ACTIVITYID was added to the
-- ACTIVITYREQUEST table. Once firms have modified their letter templates
-- they can set the site control OFF which will provide a performance boost
-- by avoiding the need to reset the WHENREQUESTED column.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @pbUniqueTimeRequired=S.COLBOOLEAN
	from SITECONTROL S
	where upper(S.CONTROLID)='Activity Time Must Be Unique'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@pbUniqueTimeRequired			bit	OUTPUT',
					  @pbUniqueTimeRequired=@pbUniqueTimeRequired	OUTPUT
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bMultiDebtor=S.COLBOOLEAN
	from SITECONTROL S
	where S.CONTROLID='WIP Split Multi Debtor'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@bMultiDebtor		bit	OUTPUT',
					  @bMultiDebtor=@bMultiDebtor	OUTPUT
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bRemoveReminder=S.COLBOOLEAN
	from SITECONTROL S
	where S.CONTROLID='Policing Removes Reminders'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@bRemoveReminder		bit	OUTPUT',
					  @bRemoveReminder=@bRemoveReminder	OUTPUT
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @nStopPayEvent=S.COLINTEGER,
	       @nStartPayEvent=S1.COLINTEGER
	from SITECONTROL S
	left join SITECONTROL S1 on (S1.CONTROLID='CPA Date-Start')
	where S.CONTROLID='CPA Date-Stop'"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@nStopPayEvent		int	OUTPUT,
					  @nStartPayEvent		int	OUTPUT',
					  @nStopPayEvent =@nStopPayEvent	OUTPUT,
					  @nStartPayEvent=@nStartPayEvent	OUTPUT
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select @bRemoveReminderOveride=1
	from TABLECODES
	where TABLECODE=9900"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@bRemoveReminderOveride		bit		OUTPUT',
					  @bRemoveReminderOveride=@bRemoveReminderOveride	OUTPUT
End

set transaction isolation level read committed

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

While @nRetry>0
and @ErrorCode=0
Begin
	BEGIN TRY
		-----------------------------------------------------------------------------------------------------------
		-- U P D A T E   Q U E U E   C O N T R O L
		-- Optionally control processing of database updates by database connection (SPID) so that they occur
		-- sequentially. This is to reduce the probability of deadlocks occurring particularly on large Policing
		-- batches when multiple Policing threads are running.
		-----------------------------------------------------------------------------------------------------------
		If  @nUpdateQueueWait>0
		and @ErrorCode=0
		Begin	
			Select @TranCountStart = @@TranCount
			BEGIN TRANSACTION
			
			-------------------------------------------------
			-- Reset any existing queue records for this SPID
			-- as they represent earlier failed batches
			-------------------------------------------------
			UPDATE dbo.POLICINGUPDATEQUEUE
			SET	ENDTIME   = getdate(),
				RESETFLAG = 1
			WHERE	SPID = @@SPID
			AND	ENDTIME is null
			
			set @ErrorCode=@@Error

			If @ErrorCode=0
			Begin	
				-----------------------------------------
				-- Create the queue record for this batch
				-----------------------------------------
				INSERT dbo.POLICINGUPDATEQUEUE (SPID) VALUES (@@SPID)
				
				set @ErrorCode=@@Error
				---------------------------
				-- Save the ID of the queue
				-- just inserted
				---------------------------
				set @nQueueId = SCOPE_IDENTITY()
			End

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
				---------------------------------------
				-- Format the delay length used to wait
				-- between checking the update queue.  
				-- A maxumum of 59 seconds has already
				-- been set as the limit.
				---------------------------------------
				Set @sDelayLength='0:0:'+cast(@nUpdateQueueWait as nvarchar)
				
				---------------------------------------
				-- Save the current date and time so we
				-- can limit the total wait to 30 mins.
				-- This will avoid the potential for an
				-- endless loop. There is also a high
				-- chance that no deadlock will occur
				-- when this transaction continues.
				---------------------------------------
				Set @dtStartTime=getdate()
				
				---------------------------------------
				-- Wait until the entry for the current 
				-- connection has the lowest ID of
				-- unprocessed entries, indicating it
				-- is at the head of the queue.
				---------------------------------------
				WHILE @nQueueId <> (	SELECT	min(QUEUEID)
							FROM	dbo.POLICINGUPDATEQUEUE
							WHERE	ENDTIME IS NULL	)
				and  getdate()<dateadd(mi, 30, @dtStartTime)	-- Limit waiting for 30 minutes to avoid endless loop
				BEGIN
					WAITFOR DELAY @sDelayLength
				END
			End
			
			If @ErrorCode=0
			and @nQueueId is not null
			Begin
				Select @TranCountStart = @@TranCount
				BEGIN TRANSACTION
				
				------------------------------------
				-- Update StartTime for this batch
				-- now that entry is proceeding
				------------------------------------
				UPDATE	dbo.POLICINGUPDATEQUEUE
				SET	STARTTIME = GETDATE()
				WHERE	QUEUEID = @nQueueId
				
				Set @ErrorCode=@@Error

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

		-----------------------------------------------------------------------------------------------------------
		-- All the updates to the database are to be applied as a single transaction so that the entire
		-- transaction can be rolled back should a failure occur.  If this method turns out to cause extensive
		-- locks on the database then the alternative will be to loop through each Case to be updated and to commit
		-- on a Case by Case basis.
		-----------------------------------------------------------------------------------------------------------
		If @ErrorCode=0
		Begin
			Select @TranCountStart = @@TranCount
			BEGIN TRANSACTION

			--------------------------------------------------------------
			-- Load a common area accessible from the database server with
			-- the UserIdentityId and the TransactionNo just generated.
			-- This will be used by the audit logs.
			--------------------------------------------------------------

			Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4)+ 
					substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
					substring(cast(isnull(@nBatchNo,'') as varbinary),1,4) +
					substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
					substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
			SET CONTEXT_INFO @bHexNumber
		End

		---------------------------------------------------
		-- RFC10929
		-- Check if the Case to be updated by Policing has
		-- been updated on the database since Policing 
		-- commenced processing. If so then the Policing
		-- transaction will be ignored and later restarted.
		---------------------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update T
			Set ERRORFOUND=1
			From #TEMPCASES T
			join CASES C		on (C.CASEID=T.CASEID)
			left join PROPERTY P	on (P.CASEID=T.CASEID)
			Where isnull(T.ERRORFOUND,0)=0
			and (T.CASELOGSTAMP    <>C.LOGDATETIMESTAMP
			 OR  T.PROPERTYLOGSTAMP<>P.LOGDATETIMESTAMP)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- If Letters are to be created then generate them within the transaction

		if  @ErrorCode  =0
		and @pnLetterFlag=1
		Begin
			execute @ErrorCode = dbo.ip_PoliceInsertLetters 
							@pdtFromDate, 
							@pdtUntilDate, 
							@pdtLetterDate, 
							@pnCountStateI1,
							@pnCountStateR1,
							@pnDebugFlag,
							@pnUserIdentityId,
							@pbUniqueTimeRequired
		End

		-- Get the highest datetimestamp in ACTIVITYHISTORY used as a starting point for new rows to be inserted into
		-- the ACTIVITYREQUEST table
		If @ErrorCode=0
		Begin
			If @pbUniqueTimeRequired=1
			Begin
				Set @sSQLString="
				Select @dtTimeStamp=max(A.WHENREQUESTED)
				from #TEMPCASEEVENT T
				join ACTIVITYHISTORY A	on (A.CASEID=T.CASEID)
				where A.WHENREQUESTED>getdate()"
				
				exec @ErrorCode=sp_executesql @sSQLString,
								N'@dtTimeStamp	datetime	OUTPUT',
								  @dtTimeStamp=@dtTimeStamp	OUTPUT
			End
			Else Begin
				Set @dtTimeStamp=getdate()
			End
		End

		-- Need to see if there is any higher datetimestamp used on the ACTIVITYREQUEST table
		If @ErrorCode=0
		and @pbUniqueTimeRequired=1
		Begin
			Set @dtTimeStamp1=@dtTimeStamp

			Set @sSQLString="
			Select @dtTimeStamp=max(A.WHENREQUESTED)
			from #TEMPCASEEVENT T
			join ACTIVITYREQUEST A	on (A.CASEID=T.CASEID)
			where A.WHENREQUESTED>isnull(@dtTimeStamp1,getdate())"
			
			exec @ErrorCode=sp_executesql @sSQLString,
							N'@dtTimeStamp	datetime	OUTPUT,
							  @dtTimeStamp1	datetime',
							  @dtTimeStamp=@dtTimeStamp	OUTPUT,
							  @dtTimeStamp1=@dtTimeStamp1

			If @ErrorCode=0
			Begin
				Set @dtTimeStamp=dateadd(ms,3, ( CASE WHEN(@dtTimeStamp1>@dtTimeStamp)
									THEN @dtTimeStamp1
									ELSE coalesce(@dtTimeStamp, @dtTimeStamp1, getdate())
								 END))
			End
											
		End

		-- Insert rows into ACTIVITYREQUEST if any charges are to be raised.
		-- The current Status of the case must be checked to ensure that charges are allowed to be raised.

		If  @ErrorCode=0
		Begin
			If @bMultiDebtor=1
			Begin
				Set @sSQLString="
				insert into ACTIVITYREQUEST   (CASEID, WHENREQUESTED,SQLUSER,PROGRAMID,ACTION,EVENTNO,CYCLE,ACTIVITYTYPE,ACTIVITYCODE,PROCESSED,RATENO,ESTIMATEFLAG,PAYFEECODE,IDENTITYID,DEBTOR,SEPARATEDEBTORFLAG,BILLPERCENTAGE,DIRECTPAYFLAG)
				select	distinct T.CASEID, @dtTimeStamp, 
					substring(isnull(T.USERID,SYSTEM_USER),1,40), 'Pol-Proc', T.CREATEDBYACTION, T.EVENTNO, T.CYCLE, 
					32, 3202, 0, H.RATENO, isnull(T.ESTIMATEFLAG,0),
					CASE T.PAYFEECODE WHEN(1) THEN 'N'
							  WHEN(2) THEN 'Y'
							  WHEN(3) THEN 'B'
					END,isnull(T.IDENTITYID,@pnUserIdentityId),
					CN.NAMENO, 1, CN.BILLPERCENTAGE, isnull(T.DIRECTPAYFLAG,0)
				from	  #TEMPCASEEVENT T
				left join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID=T.CASEID)
				left join INSTRUCTIONFLAG F	   on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE)
				left join ACTIONS A	on (A.ACTION=T.CREATEDBYACTION)
				     join #TEMPCASES C	on (C.CASEID=T.CASEID)
				     join CASES CS	on (CS.CASEID=T.CASEID)
				     join CHARGERATES H on (H.CHARGETYPENO=T.INITIALFEE
							and(CASE WHEN(H.CASETYPE     is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.CASECATEGORY is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.SUBTYPE      is null) THEN '0' ELSE '1' END+
		    					    CASE WHEN(H.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
	  								=(	select max(CASE WHEN(H1.CASETYPE     is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.CASECATEGORY is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.SUBTYPE      is null) THEN '0' ELSE '1' END+
						    					   CASE WHEN(H1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
										from CHARGERATES H1
										where H1.CHARGETYPENO   =H.CHARGETYPENO
										and   H1.RATENO         =H.RATENO
										and  (H1.CASETYPE       =C.CASETYPE         OR H1.CASETYPE        is null)
										and  (H1.PROPERTYTYPE   =C.PROPERTYTYPE     OR H1.PROPERTYTYPE    is null)
										and  (H1.COUNTRYCODE    =C.COUNTRYCODE	    OR H1.COUNTRYCODE     is null)
										and  (H1.CASECATEGORY   =C.CASECATEGORY     OR H1.CASECATEGORY    is null)
										and  (H1.SUBTYPE        =C.SUBTYPE          OR H1.SUBTYPE         is null)
										and  (H1.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H1.INSTRUCTIONTYPE is null)
										and  (H1.FLAGNUMBER     =F.FLAGNUMBER       OR H1.FLAGNUMBER      is null))
							and  (H.CASETYPE       =C.CASETYPE         OR H.CASETYPE        is null)
							and  (H.PROPERTYTYPE   =C.PROPERTYTYPE     OR H.PROPERTYTYPE    is null)
							and  (H.COUNTRYCODE    =C.COUNTRYCODE      OR H.COUNTRYCODE     is null)
							and  (H.CASECATEGORY   =C.CASECATEGORY     OR H.CASECATEGORY    is null)
							and  (H.SUBTYPE        =C.SUBTYPE          OR H.SUBTYPE         is null)
							and  (H.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H.INSTRUCTIONTYPE is null)
							and  (H.FLAGNUMBER     =F.FLAGNUMBER       OR H.FLAGNUMBER      is null))
				     join RATES RT	on (RT.RATENO=H.RATENO)
				     join CASENAME CN	on (CN.CASEID=C.CASEID
							and CN.EXPIRYDATE is null
							and CN.BILLPERCENTAGE>0
							and CN.NAMETYPE=CASE WHEN(RT.RATETYPE=1601 OR (RT.RATETYPE is null AND A.ACTIONTYPEFLAG=1)) THEN 'Z' ELSE 'D' END)
				left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
				where	T.[STATE] like 'I%'
				and	T.OCCURREDFLAG between 1 and 8
				and    (S.CHARGESALLOWED is null or S.CHARGESALLOWED=1)
				and 	C.ERRORFOUND is null
				order by T.CASEID"
			End
			Else Begin
				Set @sSQLString="
				insert into ACTIVITYREQUEST(CASEID, WHENREQUESTED,SQLUSER,PROGRAMID,ACTION,EVENTNO,CYCLE,ACTIVITYTYPE,ACTIVITYCODE,PROCESSED,RATENO,ESTIMATEFLAG,PAYFEECODE,IDENTITYID, DIRECTPAYFLAG)
				select	distinct T.CASEID, @dtTimeStamp,
					substring(isnull(T.USERID,SYSTEM_USER),1,40), 'Pol-Proc', T.CREATEDBYACTION, T.EVENTNO, T.CYCLE, 
					32, 3202, 0, H.RATENO, isnull(T.ESTIMATEFLAG,0),
					CASE T.PAYFEECODE WHEN(1) THEN 'N'
							  WHEN(2) THEN 'Y'
							  WHEN(3) THEN 'B'
					END,isnull(T.IDENTITYID,@pnUserIdentityId), isnull(T.DIRECTPAYFLAG, 0)
				from	  #TEMPCASEEVENT T
				left join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID=T.CASEID)
				left join INSTRUCTIONFLAG F	   on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE)
				     join #TEMPCASES C	on (C.CASEID=T.CASEID)
				     join CASES CS	on (CS.CASEID=T.CASEID)
				     join CHARGERATES H on (H.CHARGETYPENO=T.INITIALFEE
							and(CASE WHEN(H.CASETYPE     is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.CASECATEGORY is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.SUBTYPE      is null) THEN '0' ELSE '1' END+
		    					    CASE WHEN(H.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
	  								=(	select max(CASE WHEN(H1.CASETYPE     is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.CASECATEGORY is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.SUBTYPE      is null) THEN '0' ELSE '1' END+
						    					   CASE WHEN(H1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
										from CHARGERATES H1
										where H1.CHARGETYPENO   =H.CHARGETYPENO
										and   H1.RATENO         =H.RATENO
										and  (H1.CASETYPE       =C.CASETYPE         OR H1.CASETYPE        is null)
										and  (H1.PROPERTYTYPE   =C.PROPERTYTYPE     OR H1.PROPERTYTYPE    is null)
										and  (H1.COUNTRYCODE    =C.COUNTRYCODE	    OR H1.COUNTRYCODE     is null)
										and  (H1.CASECATEGORY   =C.CASECATEGORY     OR H1.CASECATEGORY    is null)
										and  (H1.SUBTYPE        =C.SUBTYPE          OR H1.SUBTYPE         is null)
										and  (H1.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H1.INSTRUCTIONTYPE is null)
										and  (H1.FLAGNUMBER     =F.FLAGNUMBER       OR H1.FLAGNUMBER      is null))
							and  (H.CASETYPE       =C.CASETYPE         OR H.CASETYPE        is null)
							and  (H.PROPERTYTYPE   =C.PROPERTYTYPE     OR H.PROPERTYTYPE    is null)
							and  (H.COUNTRYCODE    =C.COUNTRYCODE      OR H.COUNTRYCODE     is null)
							and  (H.CASECATEGORY   =C.CASECATEGORY     OR H.CASECATEGORY    is null)
							and  (H.SUBTYPE        =C.SUBTYPE          OR H.SUBTYPE         is null)
							and  (H.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H.INSTRUCTIONTYPE is null)
							and  (H.FLAGNUMBER     =F.FLAGNUMBER       OR H.FLAGNUMBER      is null))
				left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
				where	T.[STATE] like 'I%'
				and	T.OCCURREDFLAG between 1 and 8
				and    (S.CHARGESALLOWED is null or S.CHARGESALLOWED=1)
				and 	C.ERRORFOUND is null
				order by T.CASEID"
			End

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnUserIdentityId	int,
							  @dtTimeStamp		datetime',
							  @pnUserIdentityId,
							  @dtTimeStamp

			Set @nChargeRequests=@nChargeRequests+@@Rowcount
		End

		-- Insert rows into ACTIVITYREQUEST if a second charge is to be raised.
		-- The current Status of the case must be checked to ensure that charges are allowed to be raised.

		If  @ErrorCode=0
		Begin
			If @bMultiDebtor=1
			Begin
				Set @sSQLString="
				insert into ACTIVITYREQUEST(CASEID, WHENREQUESTED, SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, ACTIVITYTYPE, ACTIVITYCODE, PROCESSED, RATENO, ESTIMATEFLAG, PAYFEECODE, IDENTITYID, DEBTOR, SEPARATEDEBTORFLAG, BILLPERCENTAGE, DIRECTPAYFLAG)
				select	distinct T.CASEID, @dtTimeStamp, 
					substring(isnull(T.USERID,SYSTEM_USER),1,40), 'Pol-Proc', T.CREATEDBYACTION, T.EVENTNO, T.CYCLE, 
					32, 3202, 0, H.RATENO, isnull(T.ESTIMATEFLAG2,0),
					CASE T.PAYFEECODE2 WHEN(1) THEN 'N'
							   WHEN(2) THEN 'Y'
							   WHEN(3) THEN 'B'
					END,isnull(T.IDENTITYID,@pnUserIdentityId),
					CN.NAMENO, 1, CN.BILLPERCENTAGE, isnull(T.DIRECTPAYFLAG2,0)
				from	  #TEMPCASEEVENT T
				left join ACTIONS A	on (A.ACTION=T.CREATEDBYACTION)
				left join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID=T.CASEID)
				left join INSTRUCTIONFLAG F	   on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE)
				     join #TEMPCASES C	on (C.CASEID=T.CASEID)
				     join CASES CS	on (CS.CASEID=T.CASEID)
				     join CHARGERATES H on (H.CHARGETYPENO=T.INITIALFEE2
							and(CASE WHEN(H.CASETYPE     is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.CASECATEGORY is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.SUBTYPE      is null) THEN '0' ELSE '1' END+
		    					    CASE WHEN(H.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
	  								=(	select max(CASE WHEN(H1.CASETYPE     is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.CASECATEGORY is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.SUBTYPE      is null) THEN '0' ELSE '1' END+
		    									   CASE WHEN(H1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
										from CHARGERATES H1
										where H1.CHARGETYPENO   =H.CHARGETYPENO
										and   H1.RATENO         =H.RATENO
										and  (H1.CASETYPE       =C.CASETYPE         OR H1.CASETYPE        is null)
										and  (H1.PROPERTYTYPE   =C.PROPERTYTYPE     OR H1.PROPERTYTYPE    is null)
										and  (H1.COUNTRYCODE    =C.COUNTRYCODE	    OR H1.COUNTRYCODE     is null)
										and  (H1.CASECATEGORY   =C.CASECATEGORY     OR H1.CASECATEGORY    is null)
										and  (H1.SUBTYPE        =C.SUBTYPE          OR H1.SUBTYPE         is null)
										and  (H1.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H1.INSTRUCTIONTYPE is null)
										and  (H1.FLAGNUMBER     =F.FLAGNUMBER       OR H1.FLAGNUMBER      is null))
							and  (H.CASETYPE       =C.CASETYPE         OR H.CASETYPE        is null)
							and  (H.PROPERTYTYPE   =C.PROPERTYTYPE     OR H.PROPERTYTYPE    is null)
							and  (H.COUNTRYCODE    =C.COUNTRYCODE      OR H.COUNTRYCODE     is null)
							and  (H.CASECATEGORY   =C.CASECATEGORY     OR H.CASECATEGORY    is null)
							and  (H.SUBTYPE        =C.SUBTYPE          OR H.SUBTYPE         is null)
							and  (H.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H.INSTRUCTIONTYPE is null)
							and  (H.FLAGNUMBER     =F.FLAGNUMBER       OR H.FLAGNUMBER      is null))
				     join RATES RT	on (RT.RATENO=H.RATENO)
				     join CASENAME CN	on (CN.CASEID=C.CASEID
							and CN.EXPIRYDATE is null
							and CN.BILLPERCENTAGE>0
							and CN.NAMETYPE=CASE WHEN(RT.RATETYPE=1601 OR (RT.RATETYPE is null AND A.ACTIONTYPEFLAG=1)) THEN 'Z' ELSE 'D' END)
				left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
				where	T.[STATE] like 'I%'
				and	T.OCCURREDFLAG between 1 and 8
				and    (S.CHARGESALLOWED is null or S.CHARGESALLOWED=1)
				and 	C.ERRORFOUND is null
				order by T.CASEID"
			End
			Else Begin
				Set @sSQLString="
				insert into ACTIVITYREQUEST(CASEID, WHENREQUESTED, SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, ACTIVITYTYPE, ACTIVITYCODE, PROCESSED, RATENO, ESTIMATEFLAG, PAYFEECODE, IDENTITYID, DIRECTPAYFLAG)
				select	distinct T.CASEID, @dtTimeStamp, 
					substring(isnull(T.USERID,SYSTEM_USER),1,40), 'Pol-Proc', T.CREATEDBYACTION, T.EVENTNO, T.CYCLE, 
					32, 3202, 0, H.RATENO, isnull(T.ESTIMATEFLAG2,0),
					CASE T.PAYFEECODE2 WHEN(1) THEN 'N'
							   WHEN(2) THEN 'Y'
							   WHEN(3) THEN 'B'
					END,isnull(T.IDENTITYID,@pnUserIdentityId), isnull(T.DIRECTPAYFLAG2,0)
				from	  #TEMPCASEEVENT T
				left join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID=T.CASEID)
				left join INSTRUCTIONFLAG F	   on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE)
				     join #TEMPCASES C	on (C.CASEID=T.CASEID)
				     join CASES CS	on (CS.CASEID=T.CASEID)
				     join CHARGERATES H on (H.CHARGETYPENO=T.INITIALFEE2
							and(CASE WHEN(H.CASETYPE     is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.CASECATEGORY is null) THEN '0' ELSE '1' END+
							    CASE WHEN(H.SUBTYPE      is null) THEN '0' ELSE '1' END+
		    					    CASE WHEN(H.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
	  								=(	select max(CASE WHEN(H1.CASETYPE     is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.CASECATEGORY is null) THEN '0' ELSE '1' END+
											   CASE WHEN(H1.SUBTYPE      is null) THEN '0' ELSE '1' END+
						    					   CASE WHEN(H1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
										from CHARGERATES H1
										where H1.CHARGETYPENO   =H.CHARGETYPENO
										and   H1.RATENO         =H.RATENO
										and  (H1.CASETYPE       =C.CASETYPE         OR H1.CASETYPE        is null)
										and  (H1.PROPERTYTYPE   =C.PROPERTYTYPE     OR H1.PROPERTYTYPE    is null)
										and  (H1.COUNTRYCODE    =C.COUNTRYCODE	    OR H1.COUNTRYCODE     is null)
										and  (H1.CASECATEGORY   =C.CASECATEGORY     OR H1.CASECATEGORY    is null)
										and  (H1.SUBTYPE        =C.SUBTYPE          OR H1.SUBTYPE         is null)
										and  (H1.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H1.INSTRUCTIONTYPE is null)
										and  (H1.FLAGNUMBER     =F.FLAGNUMBER       OR H1.FLAGNUMBER      is null))
							and  (H.CASETYPE       =C.CASETYPE         OR H.CASETYPE        is null)
							and  (H.PROPERTYTYPE   =C.PROPERTYTYPE     OR H.PROPERTYTYPE    is null)
							and  (H.COUNTRYCODE    =C.COUNTRYCODE      OR H.COUNTRYCODE     is null)
							and  (H.CASECATEGORY   =C.CASECATEGORY     OR H.CASECATEGORY    is null)
							and  (H.SUBTYPE        =C.SUBTYPE          OR H.SUBTYPE         is null)
							and  (H.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H.INSTRUCTIONTYPE is null)
							and  (H.FLAGNUMBER     =F.FLAGNUMBER       OR H.FLAGNUMBER      is null))
				left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
				where	T.[STATE] like 'I%'
				and	T.OCCURREDFLAG between 1 and 8
				and    (S.CHARGESALLOWED is null or S.CHARGESALLOWED=1)
				and 	C.ERRORFOUND is null
				order by T.CASEID"
			End

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnUserIdentityId	int,
							  @dtTimeStamp		datetime',
							  @pnUserIdentityId,
							  @dtTimeStamp

			Set @nChargeRequests=@nChargeRequests+@@Rowcount
		End

		-- Insert rows into ACTIVITYREQUEST if any charges are to be raised as a result of a letter being generated.
		-- The current Status of the case must be checked to ensure that charges are allowed to be raised.

		If  @ErrorCode=0
		Begin
			If @bMultiDebtor=1
			Begin
				Set @sSQLString="
				insert into ACTIVITYREQUEST(CASEID, WHENREQUESTED, SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, ACTIVITYTYPE, ACTIVITYCODE, PROCESSED, RATENO, ESTIMATEFLAG, PAYFEECODE, IDENTITYID, DEBTOR, SEPARATEDEBTORFLAG, BILLPERCENTAGE, DIRECTPAYFLAG)
				select	distinct T.CASEID, @dtTimeStamp, 
				substring(isnull(T.USERID,SYSTEM_USER),1,40), 'Pol-Proc', T.CREATEDBYACTION, T.EVENTNO, T.CYCLE, 
				32, 3202, 0, H.RATENO, R.ESTIMATEFLAG,
				CASE R.PAYFEECODE WHEN(1) THEN 'N'
						  WHEN(2) THEN 'Y'
						  WHEN(3) THEN 'B'
				END,isnull(T.IDENTITYID,@pnUserIdentityId),
				CN.NAMENO, 1, CN.BILLPERCENTAGE, isnull(R.DIRECTPAYFLAG,0)
				from	  #TEMPCASEEVENT T
				left join ACTIONS AC	on (AC.ACTION=T.CREATEDBYACTION)
				join REMINDERS R on (R.CRITERIANO=isnull(T.CRITERIANO, T.CREATEDBYCRITERIA)
						and R.EVENTNO	=T.EVENTNO)
				join ACTIVITYREQUEST A
						on (A.CASEID	=T.CASEID
						and A.ACTION	=T.CREATEDBYACTION
						and A.EVENTNO	=T.EVENTNO
						and A.CYCLE	=T.CYCLE
						and A.LETTERNO	=R.LETTERNO
						and(A.LOGTRANSACTIONNO=@nTransNo OR (A.LOGTRANSACTIONNO is null and @nTransNo is null)))
				join #TEMPCASES C	on (C.CASEID=T.CASEID)
				join CASES CS		on (CS.CASEID=T.CASEID)
				left join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID=T.CASEID)
				left join INSTRUCTIONFLAG F	   on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE)
				join CHARGERATES H on (H.CHARGETYPENO=R.LETTERFEE
						and(CASE WHEN(H.CASETYPE     is null) THEN '0' ELSE '1' END+
						    CASE WHEN(H.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
						    CASE WHEN(H.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
						    CASE WHEN(H.CASECATEGORY is null) THEN '0' ELSE '1' END+
						    CASE WHEN(H.SUBTYPE      is null) THEN '0' ELSE '1' END+
		   					    CASE WHEN(H.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
	  							=(	select max(CASE WHEN(H1.CASETYPE     is null) THEN '0' ELSE '1' END+
										   CASE WHEN(H1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
										   CASE WHEN(H1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
										   CASE WHEN(H1.CASECATEGORY is null) THEN '0' ELSE '1' END+
										   CASE WHEN(H1.SUBTYPE      is null) THEN '0' ELSE '1' END+
					    					   CASE WHEN(H1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
									from CHARGERATES H1
									where H1.CHARGETYPENO   =H.CHARGETYPENO
									and   H1.RATENO         =H.RATENO
									and  (H1.CASETYPE       =C.CASETYPE         OR H1.CASETYPE        is null)
									and  (H1.PROPERTYTYPE   =C.PROPERTYTYPE     OR H1.PROPERTYTYPE    is null)
									and  (H1.COUNTRYCODE    =C.COUNTRYCODE	    OR H1.COUNTRYCODE     is null)
									and  (H1.CASECATEGORY   =C.CASECATEGORY     OR H1.CASECATEGORY    is null)
									and  (H1.SUBTYPE        =C.SUBTYPE          OR H1.SUBTYPE         is null)
									and  (H1.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H1.INSTRUCTIONTYPE is null)
									and  (H1.FLAGNUMBER     =F.FLAGNUMBER       OR H1.FLAGNUMBER      is null))
						and  (H.CASETYPE       =C.CASETYPE         OR H.CASETYPE        is null)
						and  (H.PROPERTYTYPE   =C.PROPERTYTYPE     OR H.PROPERTYTYPE    is null)
						and  (H.COUNTRYCODE    =C.COUNTRYCODE      OR H.COUNTRYCODE     is null)
						and  (H.CASECATEGORY   =C.CASECATEGORY     OR H.CASECATEGORY    is null)
						and  (H.SUBTYPE        =C.SUBTYPE          OR H.SUBTYPE         is null)
						and  (H.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H.INSTRUCTIONTYPE is null)
						and  (H.FLAGNUMBER     =F.FLAGNUMBER       OR H.FLAGNUMBER      is null))
				join RATES RT	on (RT.RATENO=H.RATENO)
				join CASENAME CN	on (CN.CASEID=C.CASEID
							and CN.EXPIRYDATE is null
							and CN.BILLPERCENTAGE>0
							and CN.NAMETYPE=CASE WHEN(RT.RATETYPE=1601 OR (RT.RATETYPE is null AND AC.ACTIONTYPEFLAG=1)) THEN 'Z' ELSE 'D' END)
				left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
				where	T.[STATE]<>'X'
				and	A.SQLUSER	=substring(isnull(T.USERID,SYSTEM_USER),1,40)
				and	A.PROGRAMID	='Pol-Proc'
				and	A.ACTIVITYTYPE	=32
				and	A.ACTIVITYCODE	in (3204, 3206)
				and	A.PROCESSED	=0
				and    (S.CHARGESALLOWED is null or S.CHARGESALLOWED=1)
				and 	C.ERRORFOUND is null
				order by T.CASEID"
			End
			Else Begin
				Set @sSQLString="
				insert into ACTIVITYREQUEST(CASEID, WHENREQUESTED, SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, ACTIVITYTYPE, ACTIVITYCODE, PROCESSED, RATENO, ESTIMATEFLAG, PAYFEECODE, IDENTITYID, DIRECTPAYFLAG)
				select distinct T.CASEID, @dtTimeStamp, 
					substring(isnull(T.USERID,SYSTEM_USER),1,40), 'Pol-Proc', T.CREATEDBYACTION, T.EVENTNO, T.CYCLE, 
					32, 3202, 0, H.RATENO, R.ESTIMATEFLAG,
					CASE R.PAYFEECODE WHEN(1) THEN 'N'
							  WHEN(2) THEN 'Y'
							  WHEN(3) THEN 'B'
					END,isnull(T.IDENTITYID,@pnUserIdentityId), isnull(R.DIRECTPAYFLAG,0)
				from	  #TEMPCASEEVENT T
				join REMINDERS R	on (R.CRITERIANO=isnull(T.CRITERIANO, T.CREATEDBYCRITERIA)
							and R.EVENTNO	=T.EVENTNO)
				join ACTIVITYREQUEST A	on (A.CASEID	=T.CASEID
							and A.ACTION	=T.CREATEDBYACTION
							and A.EVENTNO	=T.EVENTNO
							and A.CYCLE	=T.CYCLE
							and A.LETTERNO	=R.LETTERNO
							and(A.LOGTRANSACTIONNO=@nTransNo OR (A.LOGTRANSACTIONNO is null and @nTransNo is null)))
				join #TEMPCASES C	on (C.CASEID=T.CASEID)
				join CASES CS		on (CS.CASEID=T.CASEID)
				left join #TEMPCASEINSTRUCTIONS CI on (CI.CASEID=T.CASEID)
				left join INSTRUCTIONFLAG F	   on (F.INSTRUCTIONCODE=CI.INSTRUCTIONCODE)
				join CHARGERATES H on (H.CHARGETYPENO=R.LETTERFEE
						and(CASE WHEN(H.CASETYPE     is null) THEN '0' ELSE '1' END+
						    CASE WHEN(H.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
						    CASE WHEN(H.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
						    CASE WHEN(H.CASECATEGORY is null) THEN '0' ELSE '1' END+
						    CASE WHEN(H.SUBTYPE      is null) THEN '0' ELSE '1' END+
	    					    CASE WHEN(H.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
  								=(	select max(CASE WHEN(H1.CASETYPE     is null) THEN '0' ELSE '1' END+
										   CASE WHEN(H1.PROPERTYTYPE is null) THEN '0' ELSE '1' END+
										   CASE WHEN(H1.COUNTRYCODE  is null) THEN '0' ELSE '1' END+
										   CASE WHEN(H1.CASECATEGORY is null) THEN '0' ELSE '1' END+
										   CASE WHEN(H1.SUBTYPE      is null) THEN '0' ELSE '1' END+
					    					   CASE WHEN(H1.FLAGNUMBER   is null) THEN '0' ELSE '1' END)
									from CHARGERATES H1
									where H1.CHARGETYPENO   =H.CHARGETYPENO
									and   H1.RATENO         =H.RATENO
									and  (H1.CASETYPE       =C.CASETYPE         OR H1.CASETYPE        is null)
									and  (H1.PROPERTYTYPE   =C.PROPERTYTYPE     OR H1.PROPERTYTYPE    is null)
									and  (H1.COUNTRYCODE    =C.COUNTRYCODE	    OR H1.COUNTRYCODE     is null)
									and  (H1.CASECATEGORY   =C.CASECATEGORY     OR H1.CASECATEGORY    is null)
									and  (H1.SUBTYPE        =C.SUBTYPE          OR H1.SUBTYPE         is null)
									and  (H1.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H1.INSTRUCTIONTYPE is null)
									and  (H1.FLAGNUMBER     =F.FLAGNUMBER       OR H1.FLAGNUMBER      is null))
						and  (H.CASETYPE       =C.CASETYPE         OR H.CASETYPE        is null)
						and  (H.PROPERTYTYPE   =C.PROPERTYTYPE     OR H.PROPERTYTYPE    is null)
						and  (H.COUNTRYCODE    =C.COUNTRYCODE      OR H.COUNTRYCODE     is null)
						and  (H.CASECATEGORY   =C.CASECATEGORY     OR H.CASECATEGORY    is null)
						and  (H.SUBTYPE        =C.SUBTYPE          OR H.SUBTYPE         is null)
						and  (H.INSTRUCTIONTYPE=CI.INSTRUCTIONTYPE OR H.INSTRUCTIONTYPE is null)
						and  (H.FLAGNUMBER     =F.FLAGNUMBER       OR H.FLAGNUMBER      is null))
				left join STATUS S	on (S.STATUSCODE=C.STATUSCODE)
				where	T.[STATE]<>'X'
				and	A.SQLUSER	=substring(isnull(T.USERID,SYSTEM_USER),1,40)
				and	A.PROGRAMID	='Pol-Proc'
				and	A.ACTIVITYTYPE	=32
				and	A.ACTIVITYCODE	in (3204, 3206)
				and	A.PROCESSED	=0
				and    (S.CHARGESALLOWED is null or S.CHARGESALLOWED=1)
				and 	C.ERRORFOUND is null
				order by T.CASEID"
			End

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@dtTimeStamp		datetime,
							  @pnUserIdentityId	int,
							  @nTransNo		int',
							  @dtTimeStamp,
							  @pnUserIdentityId,
							  @nTransNo

			Set @nChargeRequests=@nChargeRequests+@@Rowcount
		End
		--------------------------------------------------------------------
		-- The ACTIVITYREQUEST rows have now all been inserted with the
		-- same WHENREQUESTED datetime stamp.  This will cause problems
		-- for firms that have not changed their letter templates to use
		-- ACTIVITYID as the unique identifier of the ACTIVITYREQUEST table.
		-- To maintain backward compatibility the ACTIVITYREQUEST rows will
		-- now be updated to make the WHENREQUESTED value unique.
		--------------------------------------------------------------------
		If @ErrorCode=0
		and @nChargeRequests>0
		and @pbUniqueTimeRequired=1
		Begin
			-- The Update will use the generated sequential ACTIVITYID offset back
			-- to a starting point of zero. Each different value will then be 
			-- multiplied by 3 ms which is the minimum unique
			set @sSQLString="
			update ACTIVITYREQUEST
			set WHENREQUESTED=dateadd(millisecond,3*(A.ACTIVITYID-A1.MINACTIVITYID),A.WHENREQUESTED)
			from ACTIVITYREQUEST A
			cross join (	select min(A.ACTIVITYID) as MINACTIVITYID
					from ACTIVITYREQUEST A
					where A.WHENREQUESTED=@dtTimeStamp) A1
			where WHENREQUESTED=@dtTimeStamp"

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@dtTimeStamp		datetime',
							  @dtTimeStamp
		End

		-- Update existing OPENACTION rows that have changed.

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update	OPENACTION
			set	LASTEVENT   =T.LASTEVENT,
				CRITERIANO  =T.NEWCRITERIANO,
				DATEFORACT  =T.DATEFORACT,
				POLICEEVENTS=T.POLICEEVENTS,
				STATUSCODE  =T.STATUSCODE,
				STATUSDESC  =T.STATUSDESC,
				DATEUPDATED =getdate()
			from	OPENACTION OA
			join	#TEMPCASES C      on (C.CASEID=OA.CASEID
						  and C.ERRORFOUND is null)
			join	#TEMPOPENACTION T on (T.CASEID=OA.CASEID
						  and T.ACTION=OA.ACTION
						  and T.CYCLE =OA.CYCLE)
			where checksum( T.LASTEVENT, T.NEWCRITERIANO, T.DATEFORACT, T.POLICEEVENTS, T.STATUSCODE, T.STATUSDESC)
			   <> checksum(OA.LASTEVENT,OA.CRITERIANO,   OA.DATEFORACT,OA.POLICEEVENTS,OA.STATUSCODE,OA.STATUSDESC)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Insert new OPENACTION rows

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			insert into OPENACTION (CASEID, ACTION, CYCLE, LASTEVENT, CRITERIANO, DATEFORACT, NEXTDUEDATE, POLICEEVENTS, STATUSCODE, STATUSDESC, DATEENTERED, DATEUPDATED)
			select	distinct T.CASEID, T.ACTION, T.CYCLE, T.LASTEVENT, T.NEWCRITERIANO, T.DATEFORACT, T.NEXTDUEDATE, T.POLICEEVENTS, T.STATUSCODE, T.STATUSDESC, T.DATEENTERED, T.DATEUPDATED 
			from	#TEMPOPENACTION T
			join	#TEMPCASES C      on (C.CASEID=T.CASEID
						  and C.ERRORFOUND is null)
			join	CASES CS	  on (CS.CASEID=T.CASEID)
			left join OPENACTION OA	  on (OA.CASEID=T.CASEID
	 					  and OA.ACTION=T.ACTION
	 					  and OA.CYCLE =T.CYCLE)
			where OA.CASEID is null"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Delete any ALERT rows that are linked to a
		-- triggering Event that is about to be deleted.
		-- This must be performed before the CASEEVENT
		-- row is deleted otherwise the delete of 
		-- CASEEVENT will be blocked by referential integrity.

		if  @ErrorCode	=0
		Begin
			Set @sSQLString="
			delete ALERT
			from ALERT A
			join #TEMPCASEEVENT T	on (T.CASEID =A.FROMCASEID
						and T.EVENTNO=A.EVENTNO
						and T.CYCLE  =A.CYCLE
						and T.[STATE] like 'D%')
			join #TEMPCASES C    	on (C.CASEID=A.FROMCASEID
						and C.ERRORFOUND is null)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Delete rows from CASEEVENT

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			delete CASEEVENT
			from CASEEVENT CE
			join #TEMPCASEEVENT T	on (T.CASEID =CE.CASEID
						and T.EVENTNO=CE.EVENTNO
						and T.CYCLE  =CE.CYCLE
						and T.[STATE] like 'D%'
						and T.OCCURREDFLAG<9)
			join #TEMPCASES C    	on (C.CASEID=CE.CASEID
						and C.ERRORFOUND is null)"
			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Update the CASEEVENT rows that have changed.

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update	CASEEVENT
			set	EVENTDATE	 =T.NEWEVENTDATE,
				EVENTDUEDATE	 =CASE WHEN(T.NEWEVENTDUEDATE is null AND T.DATEDUESAVED=1)
							THEN T.OLDEVENTDUEDATE
							ELSE T.NEWEVENTDUEDATE
						  END,
				DATEREMIND	 =T.NEWDATEREMIND,
				DATEDUESAVED	 =T.DATEDUESAVED,
				CREATEDBYACTION	 =isnull(T.CREATEDBYACTION, CE.CREATEDBYACTION),
				CREATEDBYCRITERIA=isnull(T.CREATEDBYCRITERIA, CE.CREATEDBYCRITERIA),	-- SQA 7189
				USEMESSAGE2FLAG	 =T.USEMESSAGE2FLAG,
				GOVERNINGEVENTNO =T.GOVERNINGEVENTNO,
				OCCURREDFLAG	 =CASE WHEN(T.NEWEVENTDATE is not null)
							THEN 1
							ELSE isnull(T.OCCURREDFLAG,0)
						  END,
				FROMCASEID	 =CS.CASEID,
				EMPLOYEENO	 =CASE WHEN(T.OCCURREDFLAG between 1 and 8) THEN CE.EMPLOYEENO ELSE coalesce(CE.EMPLOYEENO,T.RESPNAMENO,CN.NAMENO) END,
				DUEDATERESPNAMETYPE
						 =CASE WHEN(T.OCCURREDFLAG between 1 and 8) THEN CE.DUEDATERESPNAMETYPE 
							ELSE CASE WHEN(coalesce(CE.EMPLOYEENO,T.RESPNAMENO,CN.NAMENO) is NULL) THEN isnull(T.RESPNAMETYPE, CE.DUEDATERESPNAMETYPE) END
						  END
			from	CASEEVENT CE
			join	#TEMPCASES C      on (C.CASEID=CE.CASEID
						  and C.ERRORFOUND is null)
			join	#TEMPCASEEVENT T on (T.CASEID =CE.CASEID
						 and T.EVENTNO=CE.EVENTNO
						 and T.CYCLE  =CE.CYCLE
						 and T.[STATE]<>'X'
						 and(T.CREATEDBYCRITERIA is not null
						  or(T.CREATEDBYCRITERIA is null		-- SQA 7189
						 and not exists					-- Only use a TEMPCASEEVENT row with
							(select * from #TEMPCASEEVENT T1	-- no CREATEDBYCRITERIA if no other
							 where T1.CASEID=T.CASEID		-- matching TEMPCASEEVENT row with a  
							 and   T1.EVENTNO=T.EVENTNO		-- CREATEDBYCRITERIA exists
							 and   T1.CYCLE  =T.CYCLE
							 and   T1.[STATE]<>'X'
							 and   T1.CREATEDBYCRITERIA is not null))))
			left join CASENAME CN	on (T.RESPNAMENO is null
						and CN.CASEID=CE.CASEID
						and CN.NAMETYPE=T.RESPNAMETYPE
						and CN.SEQUENCE=(select min(CN1.SEQUENCE)
								 from CASENAME CN1
								 where CN1.CASEID=CN.CASEID
								 and CN1.NAMETYPE=CN.NAMETYPE
								 and (CN1.EXPIRYDATE is null OR CN1.EXPIRYDATE>getdate())))
			left join CASES CS	on (CS.CASEID=T.FROMCASEID)			-- included as a performance improvement to stop Index Scan
			where	(CE.EVENTDATE        <>T.NEWEVENTDATE      or (CE.EVENTDATE         is null and T.NEWEVENTDATE      is not null) or (CE.EVENTDATE         is not null and T.NEWEVENTDATE      is null))
			or	(CE.EVENTDUEDATE     <>T.NEWEVENTDUEDATE   or (CE.EVENTDUEDATE      is null and T.NEWEVENTDUEDATE   is not null) or (CE.EVENTDUEDATE      is not null and T.NEWEVENTDUEDATE   is null))
			or	(CE.DATEREMIND       <>T.NEWDATEREMIND     or (CE.DATEREMIND        is null and T.NEWDATEREMIND     is not null) or (CE.DATEREMIND        is not null and T.NEWDATEREMIND     is null))
			or	(CE.DATEDUESAVED     <>T.DATEDUESAVED      or (CE.DATEDUESAVED      is null and T.DATEDUESAVED      is not null) or (CE.DATEDUESAVED      is not null and T.DATEDUESAVED      is null)) 
			or	(CE.OCCURREDFLAG     <>T.OCCURREDFLAG      or (CE.OCCURREDFLAG      is null and T.OCCURREDFLAG      is not null) or (CE.OCCURREDFLAG      is not null and T.OCCURREDFLAG      is null))
			or	(CE.CREATEDBYACTION  <>T.CREATEDBYACTION   or (CE.CREATEDBYACTION   is null and T.CREATEDBYACTION   is not null) or (CE.CREATEDBYACTION   is not null and T.CREATEDBYACTION   is null))
 			or	(CE.CREATEDBYCRITERIA<>T.CREATEDBYCRITERIA or (CE.CREATEDBYCRITERIA is null and T.CREATEDBYCRITERIA is not null) or (CE.CREATEDBYCRITERIA is not null and T.CREATEDBYCRITERIA is null))
			or	(CE.USEMESSAGE2FLAG  <>T.USEMESSAGE2FLAG   or (CE.USEMESSAGE2FLAG   is null and T.USEMESSAGE2FLAG   is not null) or (CE.USEMESSAGE2FLAG   is not null and T.USEMESSAGE2FLAG   is null)) 
			or	(CE.GOVERNINGEVENTNO <>T.GOVERNINGEVENTNO  or (CE.GOVERNINGEVENTNO  is null and T.GOVERNINGEVENTNO  is not null) or (CE.GOVERNINGEVENTNO  is not null and T.GOVERNINGEVENTNO  is null)) 
			or	(CE.EMPLOYEENO          is not null and T.OCCURREDFLAG between 1 and 8)
			or	(CE.DUEDATERESPNAMETYPE is not null and T.OCCURREDFLAG between 1 and 8)
			or	(CE.EMPLOYEENO  is null and isnull(T.RESPNAMENO,CN.NAMENO)  is not null)
			or	(CE.DUEDATERESPNAMETYPE<>T.RESPNAMETYPE  
									   or (CE.DUEDATERESPNAMETYPE is null and T.RESPNAMETYPE is not null and isnull(T.RESPNAMENO,CN.NAMENO) is null) )"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Update CASEEVENT rows where the OPENACTION criteriano has changed

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update CASEEVENT
			set  CREATEDBYCRITERIA=T.NEWCRITERIANO,
			     CREATEDBYACTION  =T.ACTION		-- RFC11457
			from CASEEVENT CE
			join #TEMPCASES C      on (C.CASEID=CE.CASEID
					       and C.ERRORFOUND is null)
			join #TEMPOPENACTION T on (T.CASEID=CE.CASEID)
			join EVENTCONTROL EC   on (EC.CRITERIANO=T.NEWCRITERIANO
					       and EC.EVENTNO	=CE.EVENTNO)
			left join OPENACTION OA on( OA.CASEID=CE.CASEID
						and OA.CRITERIANO=CE.CREATEDBYCRITERIA)
			where isnull(T.CRITERIANO,'')<>T.NEWCRITERIANO
			and isnull(CE.CREATEDBYCRITERIA,'')<>T.NEWCRITERIANO
			and OA.CASEID is null"

			Exec @ErrorCode=sp_executesql @sSQLString
		End
		
		-- SQA18765
		-- Delete #TEMPCASEEVENT rows where NEWEVENTDATE and NEWEVENTDUEDATE are both NULL
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Delete #TEMPCASEEVENT
			where NEWEVENTDATE is null
			and NEWEVENTDUEDATE is null
			and [STATE] not like 'D%'
			and [STATE] <> 'E'"
			
			exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Insert new CASEEVENT rows

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, EVENTDUEDATE, DATEREMIND, DATEDUESAVED, OCCURREDFLAG, CREATEDBYACTION, CREATEDBYCRITERIA, USEMESSAGE2FLAG, GOVERNINGEVENTNO, FROMCASEID,
						EMPLOYEENO, DUEDATERESPNAMETYPE)
			select T.CASEID, T.EVENTNO, T.CYCLE, T.NEWEVENTDATE, T.NEWEVENTDUEDATE, T.NEWDATEREMIND, T.DATEDUESAVED, 
				CASE WHEN(T.NEWEVENTDATE is not null) THEN 1 ELSE 0 END,
				T.CREATEDBYACTION, T.CREATEDBYCRITERIA, T.USEMESSAGE2FLAG, T.GOVERNINGEVENTNO, T.FROMCASEID,
				
				CASE WHEN(T.OCCURREDFLAG between 1 and 8) THEN NULL ELSE isnull(T.RESPNAMENO,CN.NAMENO) END,
				CASE WHEN(T.OCCURREDFLAG between 1 and 8) THEN NULL 
					ELSE CASE WHEN(isnull(T.RESPNAMENO,CN.NAMENO) is NULL) THEN T.RESPNAMETYPE END
				END
			from #TEMPCASEEVENT T
			join #TEMPCASES C      	on (C.CASEID=T.CASEID
			       			and C.ERRORFOUND is null)
			join CASES CS		on (CS.CASEID=T.CASEID)
			left join CASENAME CN	on (T.RESPNAMENO is null
						and CN.CASEID=T.CASEID
						and CN.NAMETYPE=T.RESPNAMETYPE
						and CN.SEQUENCE=(select min(CN1.SEQUENCE)
								 from CASENAME CN1
								 where CN1.CASEID=CN.CASEID
								 and CN1.NAMETYPE=CN.NAMETYPE
								 and (CN1.EXPIRYDATE is null OR CN1.EXPIRYDATE>getdate())))
			left join CASEEVENT CE 	on (CE.CASEID =T.CASEID
	 		 			and CE.EVENTNO=T.EVENTNO
						and CE.CYCLE  =T.CYCLE)
										-- Rows marked for Deletion will not be inserted unless	
										-- they have their OCCURREDFLAG set to 9 to indicate	
										-- that the Event has been satisfied but the due date 	
										-- has been saved.					
			where (T.[STATE] not in ('D','D1','X') OR T.OCCURREDFLAG=9)
			and T.UNIQUEID=( select min(UNIQUEID)
					 from #TEMPCASEEVENT T1
					 where T1.CASEID =T.CASEID
					 and   T1.EVENTNO=T.EVENTNO
					 and   T1.CYCLE  =T.CYCLE		-- SQA18456 line reinstated
					 and  (T1.[STATE] not in ('D','D1','X') OR T1.OCCURREDFLAG=9))
			and  CE.CASEID is null"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------------------
		-- Insert an OFFICIALNUMBER that has been
		-- pushed from a related Case.
		-----------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			insert into OFFICIALNUMBERS(CASEID, OFFICIALNUMBER, NUMBERTYPE, ISCURRENT, DATEENTERED)
			select distinct T.CASEID, T.PARENTNUMBER, T.LOADNUMBERTYPE, 1, NEWEVENTDATE
			from #TEMPCASEEVENT T
			join #TEMPCASES C on (C.CASEID=T.CASEID
					  and C.ERRORFOUND is null)
			join CASES CS	  on (CS.CASEID=T.CASEID)
			left join OFFICIALNUMBERS O on (O.CASEID=T.CASEID
						    and O.NUMBERTYPE=T.LOADNUMBERTYPE)
			where T.[STATE] like 'I%'
			and T.OCCURREDFLAG=1
			and T.NEWEVENTDATE   is not null
			and T.LOADNUMBERTYPE is not null
			and T.PARENTNUMBER   is not null
			and O.CASEID is null"
			
			exec sp_executesql @sSQLString
		End

		-----------------------------------------------------------
		-- SQA9030
		-- Update OFFICIALNUMBER.DATEENTERED when Event linked to
		-- Number Type has been updated and there is no DATEENTERED
		-- value against the Official Number.
		-----------------------------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update O
			Set DATEENTERED=T.NEWEVENTDATE
			from #TEMPCASEEVENT T
			join #TEMPCASES C      	on (C.CASEID=T.CASEID
			       			and C.ERRORFOUND is null)
			join NUMBERTYPES NT	on (NT.RELATEDEVENTNO=T.EVENTNO)
			join OFFICIALNUMBERS O	on (O.CASEID=T.CASEID
						and O.NUMBERTYPE=NT.NUMBERTYPE)
			where T.[STATE] like 'I%'
			and T.CYCLE=1
			and T.NEWEVENTDATE is not null
			and T.OCCURREDFLAG=1
			and O.DATEENTERED is null
			and O.ISCURRENT=1"
			
			exec @ErrorCode=sp_executesql @sSQLString
		End

		If @ErrorCode=0
		Begin
			-- Insert rows into the ACTIVITYHISTORY table when the Status of the Case has changed

			Set @sSQLString="
			Insert into ACTIVITYHISTORY (CASEID, WHENREQUESTED, SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, STATUSCODE, IDENTITYID)
			select	T.CASEID, @dtTimeStamp, substring(isnull(TC.USERID,SYSTEM_USER),1,40), 'Pol-Proc', T.ACTION, T.EVENTNO, T.CYCLE, T.STATUSCODE, isnull(TC.IDENTITYID,@pnUserIdentityId)
			from #TEMPCASES T
			     join CASES C		on (C.CASEID  =T.CASEID)
			left join #TEMPCASEEVENT TC	on (TC.CASEID =T.CASEID
							and TC.EVENTNO=T.EVENTNO
							and TC.CYCLE  =T.CYCLE
							and TC.UNIQUEID=(select min(UNIQUEID)
									 from #TEMPCASEEVENT TC1
 									 where TC1.CASEID =TC.CASEID
									 and   TC1.EVENTNO=TC.EVENTNO
									 and   TC1.CYCLE  =TC.CYCLE))
			where (C.STATUSCODE<>T.STATUSCODE OR C.STATUSCODE is null)
			and T.STATUSCODE is not null
			and T.ERRORFOUND is null"

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnUserIdentityId	int,
							  @dtTimeStamp		datetime',
							  @pnUserIdentityId,
							  @dtTimeStamp
		End
			
		-- Insert rows into the ACTIVITYHISTORY table when the RenewalStatus of the Case has changed

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into ACTIVITYHISTORY (CASEID, WHENREQUESTED, SQLUSER, PROGRAMID, ACTION, EVENTNO, CYCLE, STATUSCODE,IDENTITYID)
			select	T.CASEID, dateadd(ms,3,@dtTimeStamp), substring(isnull(TC.USERID,SYSTEM_USER),1,40), 'Pol-Proc', T.RENEWALACTION, T.RENEWALEVENTNO, T.RENEWALCYCLE, T.RENEWALSTATUS,isnull(TC.IDENTITYID,@pnUserIdentityId)
			from #TEMPCASES T
			     join PROPERTY P 		on (P.CASEID  =T.CASEID)
			left join #TEMPCASEEVENT TC	on (TC.CASEID =T.CASEID
							and TC.EVENTNO=T.RENEWALEVENTNO
							and TC.CYCLE  =T.RENEWALCYCLE
							and TC.UNIQUEID=(select min(UNIQUEID)
									 from #TEMPCASEEVENT TC1
 									 where TC1.CASEID =TC.CASEID
									 and   TC1.EVENTNO=TC.EVENTNO
									 and   TC1.CYCLE  =TC.CYCLE))
			where (P.RENEWALSTATUS<>T.RENEWALSTATUS OR P.RENEWALSTATUS is null)
			and T.RENEWALSTATUS is not null
			and T.ERRORFOUND is null"

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnUserIdentityId	int,
							  @dtTimeStamp		datetime',
							  @pnUserIdentityId,
							  @dtTimeStamp
		End

		-- Update the CASES table if the Status Code, ReportToThirdParty or StopPayReason has changed.
		-- Due to the slow nature of updating CASES it is more efficient to check if there is actually data
		-- to perform the update

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			with CTE_OfficialNumber(CASEID, CURRENTOFFICIALNO)
			as	(	select O.CASEID, 
					substring(
					max(convert(nchar(5), 99999-NT.DISPLAYPRIORITY )+
					    convert(nchar(8), ISNULL(O.DATEENTERED,0),112)+
					    O.OFFICIALNUMBER) , 14,36) as CURRENTOFFICIALNO
					from OFFICIALNUMBERS O
					join NUMBERTYPES NT 	on (NT.NUMBERTYPE = O.NUMBERTYPE)
					where NT.ISSUEDBYIPOFFICE = 1
					and NT.DISPLAYPRIORITY is not null
					and O.ISCURRENT=1
					group by O.CASEID
				)
			Update	CASES
			Set	STATUSCODE	  =isnull(T.STATUSCODE, C.STATUSCODE),
				REPORTTOTHIRDPARTY=isnull(T.REPORTTOTHIRDPARTY,0),
				STOPPAYREASON	  =CASE	WHEN ( C.STOPPAYREASON is not NULL and  CE.CASEID is not null)						THEN NULL -- SQA20220 Stop  Pay Event is being deleted so clear STOPPAYREASON
							WHEN ( C.STOPPAYREASON is not NULL and CE1.CASEID is not null)						THEN NULL -- RFC66016 Start Pay Event has occurred     so clear STOPPAYREASON
							WHEN (S1.STOPPAYREASON is not NULL and (T.RENEWALSTATUS<>P.RENEWALSTATUS or P.RENEWALSTATUS is null))	THEN S1.STOPPAYREASON
							WHEN ( S.STOPPAYREASON is not NULL and (T.STATUSCODE   <>C.STATUSCODE    or C.STATUSCODE    is null))	THEN  S.STOPPAYREASON
																				ELSE  C.STOPPAYREASON
						   END,
				CURRENTOFFICIALNO =isnull(CTE.CURRENTOFFICIALNO, C.CURRENTOFFICIALNO)
			From	CASES C
			join	#TEMPCASES T on (T.CASEID=C.CASEID
					     and T.ERRORFOUND is null)
			left join CTE_OfficialNumber CTE on (CTE.CASEID=C.CASEID)
			left join PROPERTY P on (P.CASEID=C.CASEID)
			left join STATUS S   on (S.STATUSCODE =T.STATUSCODE)
			left join STATUS S1	on (S1.STATUSCODE=T.RENEWALSTATUS)	-- RFC10122 Changed from P.RENEWALSTATUS to T.RENEWALSTATUS
			left join #TEMPCASEEVENT CE					-- SQA20220 Stop Pay Event is being deleted
						on (CE.CASEID =C.CASEID
						and CE.EVENTNO=@nStopPayEvent
						and CE.[STATE] like 'D%'
						and CE.OCCURREDFLAG<9)
			left join #TEMPCASEEVENT CE1					-- RFC66016 Start Pay Event is being inserted/updated as occurred
						on (CE1.CASEID =C.CASEID
						and CE1.EVENTNO=@nStartPayEvent
						and CE1.[STATE] like 'I%'
						and CE1.OCCURREDFLAG=1)
										-- Update if the Status code changes		
			where	( isnull(C.STATUSCODE,'')<>isnull(T.STATUSCODE,'') ) 
										-- Update if the Current Official No has changed
			OR	( isnull(C.CURRENTOFFICIALNO,'')<>CTE.CURRENTOFFICIALNO )
										-- Update if the REPORTTOTHIRDPARTY changes	
			OR	( isnull(C.REPORTTOTHIRDPARTY,0)<>isnull(T.REPORTTOTHIRDPARTY,0) )
										-- Stop Pay Event is deleted so STOPPAYREASON 
										-- is to be removed.			
			OR	( C.STOPPAYREASON is not NULL and CE.CASEID is not null)
										-- Start Pay Event has occurred so STOPPAYREASON 
										-- is to be removed.			
			OR	( C.STOPPAYREASON is not NULL and CE1.CASEID is not null)
										-- Update if the STOPPAYREASON associated with 	
										-- the Case STATUSCODE changes.			
			OR	( S.STOPPAYREASON is not NULL and (T.STATUSCODE   <>C.STATUSCODE    or C.STATUSCODE    is null))
										-- Update if the STOPPAYREASON associated with 	
										-- the Property RENEWALSTATUS changes.		
			OR	(S1.STOPPAYREASON is not NULL and (T.RENEWALSTATUS<>P.RENEWALSTATUS or P.RENEWALSTATUS is null))"

			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nStopPayEvent	int,
							  @nStartPayEvent	int',
							  @nStopPayEvent=@nStopPayEvent,
							  @nStartPayEvent=@nStartPayEvent
		End

		-- If the Case has been flagged to recalculate the Patent Term Adjustment totals or 
		-- there have been CaseEvents changes that are included in the PTA then recalculate
		-- the totals
		-- If no total is returned then the value already held in the CASES table is retained as this
		-- value may have been manually entered.

		If   @ErrorCode=0
		and (@pbPTARecalc=1 OR @nCountPTAUpdate>0)
		Begin
			Set @sSQLString="
			Update	CASES
			Set	IPODELAY=isnull(PTA.IPODELAY,C.IPODELAY),
				APPLICANTDELAY=isnull(PTA.APPLICANTDELAY,C.APPLICANTDELAY)
			From	CASES C
			join	#TEMPCASES T on (T.CASEID=C.CASEID
					     and T.ERRORFOUND is null)
			left join
			 (	Select CASEID
				from #TEMPCASEEVENT
				where PTADELAY>0
				group by CASEID) TC	on (TC.CASEID=C.CASEID)
			left join
			 (	select 	CE.CASEID, 
					sum(	CASE WHEN(EC.PTADELAY=1 AND CE.EVENTDATE>CE.EVENTDUEDATE)
							THEN datediff(day,CE.EVENTDUEDATE,CE.EVENTDATE)
							ELSE 0
						END) as IPODELAY, 
					sum(	CASE WHEN(EC.PTADELAY=2 AND CE.EVENTDATE>CE.EVENTDUEDATE)
							THEN datediff(day,CE.EVENTDUEDATE,CE.EVENTDATE)
							ELSE 0
						END) as APPLICANTDELAY
				from OPENACTION OA
				join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
							and EC.PTADELAY in (1,2))
				join CASEEVENT CE	on (CE.CASEID=OA.CASEID
							and CE.EVENTNO=EC.EVENTNO
							and CE.EVENTDATE is not null
							and CE.EVENTDUEDATE is not null
							and CE.OCCURREDFLAG between 1 and 8)
				group by CE.CASEID ) PTA	on (PTA.CASEID=C.CASEID)
			where T.RECALCULATEPTA=1
			OR TC.CASEID is not null"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Update the PROPERTY table if the Renewal Status has changed

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update	PROPERTY
			Set	RENEWALSTATUS=T.RENEWALSTATUS
			From	PROPERTY P
			join	#TEMPCASES T on (T.CASEID=P.CASEID)
			where	(P.RENEWALSTATUS<>T.RENEWALSTATUS OR P.RENEWALSTATUS is null)
			and	 T.RENEWALSTATUS is not null
			and 	 T.ERRORFOUND is null"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Insert a PROPERTY table row if the Renewal Status has been set and there
		-- currently is no PROPERTY row

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into PROPERTY (CASEID, RENEWALSTATUS)
			Select T.CASEID, T.RENEWALSTATUS
			from	#TEMPCASES T
			join CASES CS	     on (CS.CASEID=T.CASEID)
			left join PROPERTY P on (P.CASEID=T.CASEID)
			where	T.RENEWALSTATUS is not null
			and	T.ERRORFOUND is null
			and	P.CASEID is null"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- SQA 7069
		-- Delete the EmployeeReminders where the Due Date of the Event has changed, 
		-- and there is no comment stored against the Reminder

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			delete EMPLOYEEREMINDER
			from EMPLOYEEREMINDER E
			join #TEMPCASES C      	on (C.CASEID=E.CASEID
			       			and C.ERRORFOUND is null)
			join #TEMPCASEEVENT T	on (T.CASEID =E.CASEID
						and T.EVENTNO=E.EVENTNO
						and T.CYCLE  =E.CYCLENO
						AND T.[STATE]<>'X'
						and T.NEWEVENTDUEDATE<>E.DUEDATE)	-- SQA10440
			where E.COMMENTS is null"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- SQA 16410
		-- Delete the EmployeeReminders where the Due Date of the Alert has changed, 
		-- and there is no comment stored against the Reminder

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			delete EMPLOYEEREMINDER
			from EMPLOYEEREMINDER E
			join #TEMPALERT T	on (T.EMPLOYEENO=E.ALERTNAMENO
						and isnull(T.CASEID,'')=isnull(E.CASEID,'')
						and isnull(T.REFERENCE,'')=isnull(E.REFERENCE,'')
						and isnull(T.NAMENO,'')=isnull(E.NAMENO,'')
						and T.SEQUENCENO=E.SEQUENCENO )
			left join #TEMPCASES C  on (C.CASEID=E.CASEID)
			where E.COMMENTS is null
			and E.EVENTNO is null
			and E.CYCLENO is null
			and E.DUEDATE<>T.DUEDATE
			and (C.CASEID is null OR C.ERRORFOUND is null)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- SQA 10033
		-- Delete the EmployeeReminders where all of the Reminder rules for the Event have been removed
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			delete EMPLOYEEREMINDER
			from EMPLOYEEREMINDER E
			join #TEMPCASES C      	on (C.CASEID=E.CASEID
			       			and C.ERRORFOUND is null)
			join #TEMPCASEEVENT T	on (T.CASEID =E.CASEID
						and T.EVENTNO=E.EVENTNO
						and T.CYCLE  =E.CYCLENO)
			where T.[STATE]<>'X'
			and E.SOURCE=0	-- Only Event rule generated reminders
			and not exists
			(select 1 
			 from #TEMPOPENACTION OA
			 join REMINDERS R	on (R.CRITERIANO=OA.NEWCRITERIANO
						and R.EVENTNO=E.EVENTNO
						and R.LETTERNO is null)
			 where OA.CASEID=E.CASEID)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End


		-------------------------------------------------------
		-- SQA 10033 & 10127
		-- Delete the EmployeeReminders where 
		--	1. Status of Case no longer requires reminders
		--	2. CaseEvent has been deleted
		--	3. CaseEvent is no longer due
		--	4. CaseEvent is not attached to an open action
		-- Reminders may only be deleted if there is an explict 
		-- sitecontrol allowing it or the staff member has a 
		-- tableattribute that allows it.
		-------------------------------------------------------
		If @ErrorCode=0
		and (isnull(@bRemoveReminderOveride,0)=1 or isnull(@bRemoveReminder,0)=1)
		Begin
			Set @sFrom=''		-- RFC9922
			Set @sWhere=''		-- RFC9922
			-------------------------------------------------------------
			-- Checks to see if the SiteControl is on to allow Reminders
			-- to be removed and/or if the table attribute is allowed 
			-- to override the removal of reminders.
			-------------------------------------------------------------
			If @bRemoveReminderOveride=1
			and @bRemoveReminder      =1
			Begin
				Set @sFrom=char(10)+char(9)+
				"left join TABLEATTRIBUTES TA
						on (TA.PARENTTABLE='NAME'
						and TA.GENERICKEY=convert(varchar,ER.EMPLOYEENO)
						and TA.TABLETYPE=99)"
						
				Set @sWhere=char(10)+char(9)+
				"and isnull(TA.TABLECODE,9900)=9900"
			End
			Else If @bRemoveReminderOveride=1
			Begin
				Set @sFrom=char(10)+char(9)+
				"join TABLEATTRIBUTES TA
						on (TA.PARENTTABLE='NAME'
						and TA.GENERICKEY=convert(varchar,ER.EMPLOYEENO)
						and TA.TABLETYPE=99)"
						
				Set @sWhere=char(10)+char(9)+
				"and TA.TABLECODE=9900"
			End
	
			----------------------------------------------
			-- DELETE
			-- Employee Reminders associated with an Event
			-- where the due date against the reminder 
			-- is missing or CaseEvent row no long exists
			----------------------------------------------	

			Set @sSQLString="
			Delete ER   
			From EMPLOYEEREMINDER ER
			join #TEMPCASES T	on (T.CASEID=ER.CASEID
						and T.ERRORFOUND is null)"+ 
			@sFrom+"
			left join CASEEVENT CE	on (CE.CASEID  = ER.CASEID
   						and CE.EVENTNO = ER.EVENTNO
   						and CE.CYCLE   = ER.CYCLENO)    
			Where ER.EVENTNO is not null  
			and   ER.SOURCE=0  
			and ( ER.DUEDATE is NULL OR CE.CASEID is NULL )"+
			@sWhere

			Exec @ErrorCode=sp_executesql @sSQLString
					  
			If @ErrorCode=0
			Begin
				----------------------------------------------
				-- DELETE
				-- System generated Reminders associated with 
				-- a Case where the status of the Case does
				-- not allow reminders to be sent.
				----------------------------------------------	
				Set @sSQLString="
				Delete ER     
				From EMPLOYEEREMINDER ER
				join #TEMPCASES T on (T.CASEID=ER.CASEID
						  and T.ERRORFOUND is null)
				join CASES C	  on (C.CASEID    = ER.CASEID)  
				join STATUS S	  on (S.STATUSCODE=C.STATUSCODE)"+ 
				@sFrom+"  
				Where S.REMINDERSALLOWED=0
				and ER.SOURCE=0"+	-- SQA18198
				@sWhere
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
					  
			If @ErrorCode=0
			Begin
				----------------------------------------------
				-- DELETE
				-- Employee Reminders associated with an Event
				-- that is no longer due.
				----------------------------------------------	
				Set @sSQLString="
				Delete ER    
				From EMPLOYEEREMINDER ER
				join #TEMPCASES T	on (T.CASEID=ER.CASEID
							and T.ERRORFOUND is null)
				join CASEEVENT CE	on (CE.CASEID  = ER.CASEID
   							and CE.EVENTNO = ER.EVENTNO
   							and CE.CYCLE   = ER.CYCLENO)"+ 
				@sFrom+" 
				Where CE.EVENTDATE is not null
				and ER.SOURCE=0"+	-- SQA18198
				@sWhere
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
					  
			If @ErrorCode=0
			Begin
				----------------------------------------------
				-- SQA18525
				-- DELETE
				-- Employee Reminders associated with an Event
				-- that has been satisfied.
				----------------------------------------------	
				Set @sSQLString="
				Delete ER    
				From EMPLOYEEREMINDER ER
				join #TEMPCASES T	on (T.CASEID=ER.CASEID
							and T.ERRORFOUND is null)
				join CASEEVENT CE	on (CE.CASEID  = ER.CASEID
   							and CE.EVENTNO = ER.EVENTNO
   							and CE.CYCLE   = ER.CYCLENO)"+ 
				@sFrom+" 
				Where CE.OCCURREDFLAG>0
				and ER.SOURCE=0"+	-- SQA18198
				@sWhere
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
					  
			If @ErrorCode=0
			Begin
				----------------------------------------------
				-- DELETE
				-- Employee Reminders associated with an Event
				-- that is not associated with an Open Action.
				----------------------------------------------	
				Set @sSQLString="
				Delete ER  
				From EMPLOYEEREMINDER ER
				join #TEMPCASES T	on (T.CASEID=ER.CASEID
							and T.ERRORFOUND is null)
				join CASEEVENT CE	on (CE.CASEID  = ER.CASEID
   							and CE.EVENTNO = ER.EVENTNO
   							and CE.CYCLE   = ER.CYCLENO)"+ 
				@sFrom+"
				Where CE.EVENTDATE is null
				and ER.SOURCE=0"+	-- SQA18198
				@sWhere+"
				and not exists
				(select 1
				 from OPENACTION OA
				 join EVENTCONTROL EC	on (EC.CRITERIANO=OA.CRITERIANO
							and EC.EVENTNO=CE.EVENTNO)
				 join ACTIONS A		on (A.ACTION=OA.ACTION)
				 where OA.CASEID=CE.CASEID
				 and OA.POLICEEVENTS=1
				 and ((OA.CYCLE=CE.CYCLE and A.NUMCYCLESALLOWED>1) OR A.NUMCYCLESALLOWED=1) )"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
					  
			If @ErrorCode=0
			Begin
				----------------------------------------------
				-- DELETE
				-- Employee Reminders associated with an Alert
				-- that has been removed.
				-- Case level Alert
				----------------------------------------------	
				Set @sSQLString="
				Delete ER     
				From EMPLOYEEREMINDER ER"+ 
				@sFrom+"  
				left join ALERT A	on ( A.EMPLOYEENO= ER.ALERTNAMENO -- RFC13635
							and  A.CASEID    = ER.CASEID
							and  A.SEQUENCENO= ER.SEQUENCENO
							and  A.NAMENO    is null
							and  A.REFERENCE is null)
				Where ER.SOURCE=1
				and ER.CASEID    is not null
				and ER.NAMENO    is null
				and ER.REFERENCE is null
				and(A.EMPLOYEENO is null or A.DATEOCCURRED is not null)"+
				@sWhere
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End	
					  
			If @ErrorCode=0
			Begin
				----------------------------------------------
				-- DELETE
				-- Employee Reminders associated with an Alert
				-- that has been removed.
				-- Reference level Alert
				----------------------------------------------	
				Set @sSQLString="
				Delete ER     
				From EMPLOYEEREMINDER ER"+ 
				@sFrom+"  
				left join ALERT A	on ( A.EMPLOYEENO=ER.ALERTNAMENO 			
							and  A.REFERENCE = ER.REFERENCE
							and  A.SEQUENCENO=ER.SEQUENCENO 
							and  A.CASEID is null			
							and  A.NAMENO is null	)   
				Where ER.SOURCE=1
				and ER.REFERENCE is not null
				and ER.CASEID    is null
				and ER.NAMENO  is null
				and(A.EMPLOYEENO is null or A.DATEOCCURRED is not null)"+
				@sWhere
			
				Exec @ErrorCode=sp_executesql @sSQLString
			End	
					  
			If @ErrorCode=0
			Begin
				----------------------------------------------
				-- DELETE
				-- Employee Reminders associated with an Alert
				-- that has been removed.
				-- Name level Alert
				----------------------------------------------	
				Set @sSQLString="
				Delete ER     
				From EMPLOYEEREMINDER ER"+ 
				@sFrom+"  
				left join ALERT A	on ( A.EMPLOYEENO= ER.ALERTNAMENO 			
							and  A.NAMENO    = ER.NAMENO		
							and  A.SEQUENCENO= ER.SEQUENCENO 		
							and  A.CASEID    is null			
							and  A.REFERENCE is null)   
				Where ER.SOURCE=1
				and ER.NAMENO    is not null
				and ER.CASEID    is null
				and ER.REFERENCE is null
				and(A.EMPLOYEENO is null or A.DATEOCCURRED is not null)"+
				@sWhere
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End	
		End

		-- Update the Due Date of EmployeeReminders where the Due Date of the Event has changed
		-- Also clear out the HOLDUNTILDATE as the user should be forced to review the reminder
		-- if the due date has changed to an earlier date

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			update EMPLOYEEREMINDER
			set DUEDATE=T.NEWEVENTDUEDATE,
			    HOLDUNTILDATE=CASE WHEN(E.DUEDATE>T.NEWEVENTDUEDATE) THEN NULL ELSE E.HOLDUNTILDATE END,
			    DATEUPDATED=getdate()
			from EMPLOYEEREMINDER E
			join #TEMPCASES C      	on (C.CASEID=E.CASEID
			       			and C.ERRORFOUND is null)
			join #TEMPCASEEVENT T	on (T.CASEID =E.CASEID
						and T.EVENTNO=E.EVENTNO
						and T.CYCLE  =E.CYCLENO
						and T.NEWEVENTDUEDATE<>E.DUEDATE
						and T.OCCURREDFLAG=0)
			Where T.[STATE]<>'X'"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- SQA16410
		-- Update the Due Date of EmployeeReminders where the Due Date of the Alert has changed
		-- Also clear out the HOLDUNTILDATE as the user should be forced to review the reminder
		-- if the due date has changed to an earlier date

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			update EMPLOYEEREMINDER
			set DUEDATE=T.DUEDATE,
			    HOLDUNTILDATE=CASE WHEN(E.DUEDATE>T.DUEDATE) THEN NULL ELSE E.HOLDUNTILDATE END,
			    DATEUPDATED=getdate()
			from EMPLOYEEREMINDER E
			join #TEMPALERT T	on (T.EMPLOYEENO=E.ALERTNAMENO
						and isnull(T.CASEID,'')=isnull(E.CASEID,'')
						and isnull(T.REFERENCE,'')=isnull(E.REFERENCE,'')
						and T.SEQUENCENO=E.SEQUENCENO )
			left join #TEMPCASES C	on (C.CASEID=E.CASEID)
			where E.SOURCE=1
			and E.CYCLENO is null
			and E.DUEDATE<>T.DUEDATE
			and (C.CASEID is null OR C.ERRORFOUND is null)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Clear out the HOLDUNTILDATE on reminders when Policing is being run
		-- from a Policing Request process (not for a specific Case).
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			update EMPLOYEEREMINDER
			set HOLDUNTILDATE=NULL,
			    DATEUPDATED=getdate()
			where HOLDUNTILDATE<getdate()
			and not exists
			(select 1 from #TEMPPOLICING)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Load the EmployeeReminder table from the temporary table

		if   @ErrorCode     =0
		and (@pnReminderFlag=1 OR @pnAdhocFlag=1)
		and  @pnRowCount    >0 			 -- Only perform this call if reminders have been inserted
		Begin
			execute @ErrorCode = dbo.ip_PoliceLoadEmployeeReminders @pnDebugFlag
		End

		-- Update the ALERT table if Adhoc Reminders have been processed

		if  @ErrorCode	=0
		and @pnAdhocFlag=1
		Begin
			Set @sSQLString="
			update	ALERT
			set	ALERTDATE =T.ALERTDATE,
				DUEDATE   =T.DUEDATE,
				FROMCASEID=CASE WHEN(T.EVENTNO is not null and T.CYCLE is not null) THEN T.CASEID ELSE NULL END,
				EVENTNO   =T.EVENTNO,
				CYCLE	  =T.CYCLE
			from	ALERT A
			join	#TEMPALERT T	on (T.EMPLOYEENO=A.EMPLOYEENO
						and T.ALERTSEQ  =A.ALERTSEQ)
			where  ( isnull(A.ALERTDATE,'')<>isnull(T.ALERTDATE,'')
			or 	 isnull(A.DUEDATE  ,'')<>isnull(T.DUEDATE  ,'') 
			or	 isnull(T.EVENTNO  ,'')<>isnull(T.EVENTNO  ,'') 
			or	 isnull(T.CYCLE    ,'')<>isnull(T.CYCLE    ,'') )"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-----------------------------------------------------------------
		-- RFC 12201
		-- Insert into the ALERT table any Adhoc Reminders that have been 
		-- duplicated to be delivered to specific recipients based on the
		-- rules associated with the original ALERT
		-----------------------------------------------------------------
		if  @ErrorCode	=0
		and @pnAdhocFlag=1
		Begin
			Set @sSQLString="
			insert into ALERT(EMPLOYEENO, ALERTSEQ, CASEID, ALERTMESSAGE, REFERENCE, ALERTDATE, DUEDATE, 
					  DATEOCCURRED, OCCURREDFLAG, DELETEDATE, STOPREMINDERSDATE, MONTHLYFREQUENCY,
					  MONTHSLEAD, DAILYFREQUENCY, DAYSLEAD, SEQUENCENO, SENDELECTRONICALLY, EMAILSUBJECT, 
					  NAMENO, EMPLOYEEFLAG, SIGNATORYFLAG,CRITICALFLAG, NAMETYPE, RELATIONSHIP, TRIGGEREVENTNO, EVENTNO, CYCLE, IMPORTANCELEVEL,
					  FROMCASEID)
			select	T.EMPLOYEENO, T.ALERTSEQ, T.CASEID, T.ALERTMESSAGE, T.REFERENCE, T.ALERTDATE, T.DUEDATE, T.DATEOCCURRED, T.OCCURREDFLAG, 
				T.DELETEDATE, T.STOPREMINDERSDATE, T.MONTHLYFREQUENCY, T.MONTHSLEAD, T.DAILYFREQUENCY, T.DAYSLEAD, T.SEQUENCENO, 
				T.SENDELECTRONICALLY, T.EMAILSUBJECT, NULL, 0, 0, 0, NULL, T.RELATIONSHIP, T.TRIGGEREVENTNO, T.EVENTNO, T.CYCLE, T.IMPORTANCELEVEL,
				CASE WHEN(T.EVENTNO is not null and T.CYCLE is not null) THEN T.CASEID ELSE NULL END
			from #TEMPALERT T
			left join ALERT A on (A.EMPLOYEENO=T.EMPLOYEENO
					  and A.ALERTSEQ  =T.ALERTSEQ)
			left join CASES CS on (CS.CASEID=T.CASEID)
			where A.EMPLOYEENO is null
			and (CS.CASEID=T.CASEID or T.CASEID is null)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Delete any ALERT rows that have reached their DELETEDATE

		if  @ErrorCode	=0
		and @pnAdhocFlag=1
		Begin
			Set @sSQLString="
			delete ALERT
			from ALERT A
			join #TEMPALERT T	on (T.EMPLOYEENO=A.EMPLOYEENO
						and T.ALERTSEQ  =A.ALERTSEQ)
			where A.DELETEDATE<=convert(nvarchar,getdate(),112)
			OR (A.DATEOCCURRED is null and A.DUEDATE is null and A.TRIGGEREVENTNO is null)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		---------------------------------------------------------------------------
		-- SQA12315
		-- Allow CASENAME changes to be triggered by an Event occurring
		---------------------------------------------------------------------------
		-- The occurence of events may now cause CASENAME changes to be triggered.  To ensure
		-- that inheritance and standing instruction changes are considered with any name 
		-- changes, the Case global name change functionality will be used to apply the changes.
		
		---------------------------------------
		-- Check for the existence of the log
		-- table for CASENAME. If it exists it 
		-- may be used to determine the BATCHNO
		-- that inserted the COPYFROMNAMENO.
		---------------------------------------
		If @ErrorCode=0
		and exists (select 1 from INFORMATION_SCHEMA.TABLES where TABLE_NAME = 'CASENAME_iLOG')
			set @bCaseNameLog=1
		else
			set @bCaseNameLog=0
			
			
		
		-- Get a unique set of Name changes that will form the basis of the Case global
		-- name change.

		If @bCaseNameLog=1
		and (select COUNT(*) from EDETRANSACTIONHEADER)>0
		Begin
			-----------------------------------------------------------------------
			-- SQA20912
			-- If the CASENAME_iLOG exists then need to check if the COPYFROMNAMENO
			-- was originally inserted by and EDE Batch.  If it was inserted by an
			-- EDE Batch then use the EDEBATCHNO only if the status of that batch
			-- is NOT "Output Produced".
			-----------------------------------------------------------------------
			If @ErrorCode=0
			Begin
				----------------------------------------------------------------
				-- If the NAMETYPE being updated does not potentially trigger
				-- any inherited names, then only trigger the Global Name Change
				-- if the Name does not already exist for the NameType
				----------------------------------------------------------------
				Set @sSQLString="
				insert into #TEMPGLOBALNAMECHANGES(CHANGENAMETYPE, COPYFROMNAMETYPE, COPYFROMNAMENO, COPYFROMREF, COPYFROMATTN, COMMENCEDATE, EDEBATCHNO)
				select distinct T.CHANGENAMETYPE, T.COPYFROMNAMETYPE, CN.NAMENO, CN.REFERENCENO, CN.CORRESPONDNAME, T.NEWEVENTDATE, TH.BATCHNO
				from #TEMPCASEEVENT T
				join CASENAME CN on (CN.CASEID=T.CASEID
						 and CN.NAMETYPE=T.COPYFROMNAMETYPE
						 and CN.EXPIRYDATE is null)
				left join CASENAME_iLOG L
						 on (L.CASEID  =CN.CASEID
						 and L.NAMETYPE=CN.NAMETYPE
						 and L.NAMENO  =CN.NAMENO
						 and L.SEQUENCE=CN.SEQUENCE
						 and L.LOGACTION='I'
						 and L.EXPIRYDATE is null
						 and L.LOGTRANSACTIONNO=(select MAX(L1.LOGTRANSACTIONNO)
									 from CASENAME_iLOG L1
									 where L1.CASEID   =L.CASEID
									 and   L1.NAMETYPE =L.NAMETYPE
									 and   L1.NAMENO   =L.NAMENO
									 and   L1.SEQUENCE =L.SEQUENCE
									 and   L1.LOGACTION=L.LOGACTION))
				left join TRANSACTIONINFO TI
						 on (TI.LOGTRANSACTIONNO=L.LOGTRANSACTIONNO)
				left join EDETRANSACTIONHEADER TH
						 on (TH.BATCHNO=TI.BATCHNO
						 and isnull(TH.BATCHSTATUS,'')<>1282)					 
				left join NAMETYPE NT
						 on (NT.PATHNAMETYPE=T.CHANGENAMETYPE)
				where T.[STATE] like 'I%'
				and T.OCCURREDFLAG=1
				and NT.NAMETYPE is null	-- indicates the NameType being updated does not trigger inheritance
				and T.CHANGENAMETYPE is not null
				-- Ignore entries where the change has already been applied
				and not exists
				(select 1 from CASENAME CN1
				 where CN1.CASEID=CN.CASEID
				 and CN1.NAMETYPE=T.CHANGENAMETYPE
				 and CN1.NAMENO=CN.NAMENO
				 and CN1.EXPIRYDATE is null
				 and (CN1.CORRESPONDNAME=CN.CORRESPONDNAME OR CN.CORRESPONDNAME is null))
				order by 1,2"

				Exec @ErrorCode=sp_executesql @sSQLString
				Set @nGlobalChanges=@@RowCount
			End

			If @ErrorCode=0
			Begin
				-----------------------------------------------------------------
				-- If the NAMETYPE being updated potentially triggers inheritance
				-- of other NameTypes, then trigger the Global Name Change
				-- without consideration as to whether the Name already exists 
				-- for this Name Type. This is so we can force the inheritance.
				-- Insert those NameTypes that may be inherited from another
				-- NameType first.
				----------------------------------------------------------------
				Set @sSQLString="
				insert into #TEMPGLOBALNAMECHANGES(CHANGENAMETYPE, COPYFROMNAMETYPE, COPYFROMNAMENO, COPYFROMREF, COPYFROMATTN, COMMENCEDATE, EDEBATCHNO)
				select distinct T.CHANGENAMETYPE, T.COPYFROMNAMETYPE, CN.NAMENO, CN.REFERENCENO, CN.CORRESPONDNAME, T.NEWEVENTDATE, TH.BATCHNO
				from #TEMPCASEEVENT T
				join CASENAME CN on (CN.CASEID=T.CASEID
						 and CN.NAMETYPE=T.COPYFROMNAMETYPE
						 and CN.EXPIRYDATE is null)
				join NAMETYPE NT on (NT.NAMETYPE=T.CHANGENAMETYPE
						 and NT.PATHNAMETYPE is not null)
				left join CASENAME_iLOG L
						 on (L.CASEID  =CN.CASEID
						 and L.NAMETYPE=CN.NAMETYPE
						 and L.NAMENO  =CN.NAMENO
						 and L.SEQUENCE=CN.SEQUENCE
						 and L.LOGACTION='I'
						 and L.EXPIRYDATE is null
						 and L.LOGTRANSACTIONNO=(select MAX(L1.LOGTRANSACTIONNO)
									 from CASENAME_iLOG L1
									 where L1.CASEID   =L.CASEID
									 and   L1.NAMETYPE =L.NAMETYPE
									 and   L1.NAMENO   =L.NAMENO
									 and   L1.SEQUENCE =L.SEQUENCE
									 and   L1.LOGACTION=L.LOGACTION))
				left join TRANSACTIONINFO TI
						 on (TI.LOGTRANSACTIONNO=L.LOGTRANSACTIONNO)
				left join EDETRANSACTIONHEADER TH
						 on (TH.BATCHNO=TI.BATCHNO
						 and isnull(TH.BATCHSTATUS,'')<>1282)
				where T.[STATE] like 'I%'
				and T.OCCURREDFLAG=1
				and T.CHANGENAMETYPE is not null
				and exists
				(select 1
				 from NAMETYPE NT1
				 where NT1.PATHNAMETYPE=T.CHANGENAMETYPE)
				order by 1,2"

				Exec @ErrorCode=sp_executesql @sSQLString
				Set @nGlobalChanges=@nGlobalChanges+@@RowCount
			End

			If @ErrorCode=0
			Begin
				-----------------------------------------------------------------
				-- If the NAMETYPE being updated potentially triggers inheritance
				-- of other NameTypes, then trigger the Global Name Change
				-- without consideration as to whether the Name already exists 
				-- for this Name Type. This is so we can force the inheritance.
				-- Insert those NameTypes that do not inherit from another 
				-- Name Type.
				----------------------------------------------------------------
				Set @sSQLString="
				insert into #TEMPGLOBALNAMECHANGES(CHANGENAMETYPE, COPYFROMNAMETYPE, COPYFROMNAMENO, COPYFROMREF, COPYFROMATTN, COMMENCEDATE, EDEBATCHNO)
				select distinct T.CHANGENAMETYPE, T.COPYFROMNAMETYPE, CN.NAMENO, CN.REFERENCENO, CN.CORRESPONDNAME, T.NEWEVENTDATE, TH.BATCHNO
				from #TEMPCASEEVENT T
				join CASENAME CN on (CN.CASEID=T.CASEID
						 and CN.NAMETYPE=T.COPYFROMNAMETYPE
						 and CN.EXPIRYDATE is null)
				join NAMETYPE NT on (NT.NAMETYPE=T.CHANGENAMETYPE
						 and NT.PATHNAMETYPE is null)
				left join CASENAME_iLOG L
						 on (L.CASEID  =CN.CASEID
						 and L.NAMETYPE=CN.NAMETYPE
						 and L.NAMENO  =CN.NAMENO
						 and L.SEQUENCE=CN.SEQUENCE
						 and L.LOGACTION='I'
						 and L.EXPIRYDATE is null
						 and L.LOGTRANSACTIONNO=(select MAX(L1.LOGTRANSACTIONNO)
									 from CASENAME_iLOG L1
									 where L1.CASEID   =L.CASEID
									 and   L1.NAMETYPE =L.NAMETYPE
									 and   L1.NAMENO   =L.NAMENO
									 and   L1.SEQUENCE =L.SEQUENCE
									 and   L1.LOGACTION=L.LOGACTION))
				left join TRANSACTIONINFO TI
						 on (TI.LOGTRANSACTIONNO=L.LOGTRANSACTIONNO)
				left join EDETRANSACTIONHEADER TH
						 on (TH.BATCHNO=TI.BATCHNO
						 and isnull(TH.BATCHSTATUS,'')<>1282)
				where T.[STATE] like 'I%'
				and T.OCCURREDFLAG=1
				and T.CHANGENAMETYPE is not null
				and exists
				(select 1
				 from NAMETYPE NT1
				 where NT1.PATHNAMETYPE=T.CHANGENAMETYPE)
				order by 1,2"

				Exec @ErrorCode=sp_executesql @sSQLString
				Set @nGlobalChanges=@nGlobalChanges+@@RowCount
			End		
		End
		Else Begin
			If @ErrorCode=0
			Begin
				----------------------------------------------------------------
				-- If the NAMETYPE being updated does not potentially trigger
				-- any inherited names, then only trigger the Global Name Change
				-- if the Name does not already exist for the NameType
				----------------------------------------------------------------
				Set @sSQLString="
				insert into #TEMPGLOBALNAMECHANGES(CHANGENAMETYPE, COPYFROMNAMETYPE, COPYFROMNAMENO, COPYFROMREF, COPYFROMATTN, COMMENCEDATE)
				select distinct T.CHANGENAMETYPE, T.COPYFROMNAMETYPE, CN.NAMENO, CN.REFERENCENO, CN.CORRESPONDNAME, T.NEWEVENTDATE
				from #TEMPCASEEVENT T
				join CASENAME CN on (CN.CASEID=T.CASEID
						 and CN.NAMETYPE=T.COPYFROMNAMETYPE
						 and CN.EXPIRYDATE is null)
				left join NAMETYPE NT
						 on (NT.PATHNAMETYPE=T.CHANGENAMETYPE)
				where T.[STATE] like 'I%'
				and T.OCCURREDFLAG=1
				and NT.NAMETYPE is null	-- indicates the NameType being updated does not trigger inheritance
				and T.CHANGENAMETYPE is not null
				-- Ignore entries where the change has already been applied
				and not exists
				(select 1 from CASENAME CN1
				 where CN1.CASEID=CN.CASEID
				 and CN1.NAMETYPE=T.CHANGENAMETYPE
				 and CN1.NAMENO=CN.NAMENO
				 and CN1.EXPIRYDATE is null
				 and (CN1.CORRESPONDNAME=CN.CORRESPONDNAME OR CN.CORRESPONDNAME is null))
				order by 1,2"

				Exec @ErrorCode=sp_executesql @sSQLString
				Set @nGlobalChanges=@@RowCount
			End

			If @ErrorCode=0
			Begin
				-----------------------------------------------------------------
				-- If the NAMETYPE being updated potentially triggers inheritance
				-- of other NameTypes, then trigger the Global Name Change
				-- without consideration as to whether the Name already exists 
				-- for this Name Type. This is so we can force the inheritance.
				-- Insert those NameTypes that may be inherited from another
				-- NameType first.
				----------------------------------------------------------------
				Set @sSQLString="
				insert into #TEMPGLOBALNAMECHANGES(CHANGENAMETYPE, COPYFROMNAMETYPE, COPYFROMNAMENO, COPYFROMREF, COPYFROMATTN, COMMENCEDATE)
				select distinct T.CHANGENAMETYPE, T.COPYFROMNAMETYPE, CN.NAMENO, CN.REFERENCENO, CN.CORRESPONDNAME, T.NEWEVENTDATE
				from #TEMPCASEEVENT T
				join CASENAME CN on (CN.CASEID=T.CASEID
						 and CN.NAMETYPE=T.COPYFROMNAMETYPE
						 and CN.EXPIRYDATE is null)
				join NAMETYPE NT on (NT.NAMETYPE=T.CHANGENAMETYPE
						 and NT.PATHNAMETYPE is not null)
				where T.[STATE] like 'I%'
				and T.OCCURREDFLAG=1
				and T.CHANGENAMETYPE is not null
				and exists
				(select 1
				 from NAMETYPE NT1
				 where NT1.PATHNAMETYPE=T.CHANGENAMETYPE)
				order by 1,2"

				Exec @ErrorCode=sp_executesql @sSQLString
				Set @nGlobalChanges=@nGlobalChanges+@@RowCount
			End

			If @ErrorCode=0
			Begin
				-----------------------------------------------------------------
				-- If the NAMETYPE being updated potentially triggers inheritance
				-- of other NameTypes, then trigger the Global Name Change
				-- without consideration as to whether the Name already exists 
				-- for this Name Type. This is so we can force the inheritance.
				-- Insert those NameTypes that do not inherit from another 
				-- Name Type.
				----------------------------------------------------------------
				Set @sSQLString="
				insert into #TEMPGLOBALNAMECHANGES(CHANGENAMETYPE, COPYFROMNAMETYPE, COPYFROMNAMENO, COPYFROMREF, COPYFROMATTN, COMMENCEDATE)
				select distinct T.CHANGENAMETYPE, T.COPYFROMNAMETYPE, CN.NAMENO, CN.REFERENCENO, CN.CORRESPONDNAME, T.NEWEVENTDATE
				from #TEMPCASEEVENT T
				join CASENAME CN on (CN.CASEID=T.CASEID
						 and CN.NAMETYPE=T.COPYFROMNAMETYPE
						 and CN.EXPIRYDATE is null)
				join NAMETYPE NT on (NT.NAMETYPE=T.CHANGENAMETYPE
						 and NT.PATHNAMETYPE is null)
				where T.[STATE] like 'I%'
				and T.OCCURREDFLAG=1
				and T.CHANGENAMETYPE is not null
				and exists
				(select 1
				 from NAMETYPE NT1
				 where NT1.PATHNAMETYPE=T.CHANGENAMETYPE)
				order by 1,2"

				Exec @ErrorCode=sp_executesql @sSQLString
				Set @nGlobalChanges=@nGlobalChanges+@@RowCount
			End
		End

		If  @nGlobalChanges>0
		and @ErrorCode=0
		Begin
			--------------------------------------------------
			-- NOTE: Global Name Change functionality will 
			--       not be applied here
			--------------------------------------------------
			
			----------------------------------------------------------
			-- Any existing COPYTONAMETYPE rows that are about to have
			-- CHANGENAMETYPE copied across, are to be updated to set
			-- the expiry date.  This will indicate the history of 
			-- dates when COPYTONAMETYPE was replaced.
			----------------------------------------------------------
			Set @sSQLString="
			Update CN
			Set EXPIRYDATE=T.NEWEVENTDATE
			from (	select CASEID, CHANGENAMETYPE, COPYTONAMETYPE, max(COPYFROMNAMETYPE) as COPYFROMNAMETYPE, max(NEWEVENTDATE) as NEWEVENTDATE
				from #TEMPCASEEVENT
				where [STATE] like 'I%'
				and OCCURREDFLAG=1
				/****
				and isnull(OLDEVENTDATE,'')<>isnull(NEWEVENTDATE,'') -- SQA16962 comment code out
				****/
				and NEWEVENTDATE   is not null
				and CHANGENAMETYPE is not null
				and COPYTONAMETYPE is not null
				group by CASEID, CHANGENAMETYPE, COPYTONAMETYPE ) T
			join #TEMPCASES C	on (C.CASEID=T.CASEID
						and C.ERRORFOUND is null)
			join CASENAME CN	on (CN.CASEID  =T.CASEID
						and CN.NAMETYPE=T.COPYTONAMETYPE
						and CN.EXPIRYDATE is null)
			-- Existing Name to be copied to COPYTONAMETYPE
			join (select * from CASENAME) CN1
						on (CN1.CASEID=T.CASEID
						and CN1.NAMETYPE=T.CHANGENAMETYPE
						and CN1.EXPIRYDATE is null)
			-- NameType holding the Name to be copied to CHANGENAMETYPE
			left join (select * from CASENAME) CN2
						on (CN2.CASEID  =T.CASEID
						and CN2.NAMETYPE=T.COPYFROMNAMETYPE
						and CN2.NAMENO  =CN1.NAMENO
						and CN2.EXPIRYDATE is null
						and (CN2.CORRESPONDNAME=CN1.CORRESPONDNAME OR CN1.CORRESPONDNAME is null))
			where CN2.CASEID is null"-- Ignore entries where the change has already been applied

			exec @ErrorCode=sp_executesql @sSQLString

			If @ErrorCode=0
			Begin
				---------------------------------------------------------
				-- Copy CHANGENAMETYPE to COPYTONAMETYPE
				---------------------------------------------------------
				Set @sSQLString="
				insert into CASENAME(	CASEID, NAMETYPE, NAMENO, SEQUENCE, CORRESPONDNAME, ADDRESSCODE, REFERENCENO, 
							ASSIGNMENTDATE, COMMENCEDATE, EXPIRYDATE, BILLPERCENTAGE, INHERITED, INHERITEDNAMENO, 
							INHERITEDRELATIONS, INHERITEDSEQUENCE, NAMEVARIANTNO)
				select	distinct
					CN.CASEID,T.COPYTONAMETYPE,CN.NAMENO,isnull(CN2.SEQUENCE,-1)+CN.SEQUENCE+1,CN.CORRESPONDNAME,CN.ADDRESSCODE,CN.REFERENCENO,
					CN.ASSIGNMENTDATE,T.NEWEVENTDATE,NULL,CN.BILLPERCENTAGE,CN.INHERITED,CN.INHERITEDNAMENO,
					CN.INHERITEDRELATIONS,CN.INHERITEDSEQUENCE,CN.NAMEVARIANTNO
				from (	select CASEID, CHANGENAMETYPE, COPYTONAMETYPE, max(COPYFROMNAMETYPE) as COPYFROMNAMETYPE, max(NEWEVENTDATE) as NEWEVENTDATE
					from #TEMPCASEEVENT
					where [STATE] like 'I%'
					and OCCURREDFLAG=1
					/****
					and isnull(OLDEVENTDATE,'')<>isnull(NEWEVENTDATE,'')	-- SQA16962 comment code out
					****/
					and NEWEVENTDATE   is not null
					and CHANGENAMETYPE is not null
					and COPYTONAMETYPE is not null
					group by CASEID, CHANGENAMETYPE, COPYTONAMETYPE ) T
				join #TEMPCASES C	on (C.CASEID=T.CASEID
							and C.ERRORFOUND is null)
				join CASENAME CN 	on (CN.CASEID   =T.CASEID
			 				and CN.NAMETYPE =T.CHANGENAMETYPE
							and CN.EXPIRYDATE is null)
				left join CASENAME CN1	on (CN1.CASEID  =T.CASEID
							and CN1.NAMETYPE=T.COPYFROMNAMETYPE
							and CN1.NAMENO  =CN.NAMENO
							and CN1.EXPIRYDATE is null
							and (CN1.CORRESPONDNAME=CN.CORRESPONDNAME OR CN.CORRESPONDNAME is null))
				left join (select CASEID, NAMETYPE, isnull(max(SEQUENCE),-1) as SEQUENCE
					   from CASENAME
					   group by CASEID, NAMETYPE) CN2
							on (CN2.CASEID  =T.CASEID
							and CN2.NAMETYPE=T.COPYTONAMETYPE)
				where CN1.CASEID is null"-- Ignore entries where the change has already been applied

				exec @ErrorCode=sp_executesql @sSQLString
			End

			-------------------------------------------------------
			-- Need to get a default Case program which is required 
			-- by Global Name Change to determine what inherited 
			-- Name types are allowed
			-------------------------------------------------------
			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Select @sProgramId=left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8)
				from SITECONTROL S
				     join USERIDENTITY U        on (U.IDENTITYID=@pnUserIdentityId)
				left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=U.PROFILEID
								and PA.ATTRIBUTEID=2)	-- Default Cases Program
				where S.CONTROLID='Case Screen Default Program'"

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@sProgramId		nvarchar(8)	OUTPUT,
							  @pnUserIdentityId	int',
							  @sProgramId      =@sProgramId		OUTPUT,
							  @pnUserIdentityId=@pnUserIdentityId
			End

			---------------------------------------------------------
			-- CHANGENAMETYPE to replace COPYFROMNAMETYPE
			-- Use Global Name Change to apply all inheritance and
			-- standing instruciton rules
			---------------------------------------------------------

			-- Now loop through each Global Name Change to be performed 
			Set @nSequenceNo=0
					
			While @nSequenceNo<@nGlobalChanges
			  and @ErrorCode=0
			Begin
				-- Increment the sequence to get each Global Name Change to be performed
				Set @nSequenceNo=@nSequenceNo+1
			
				-- Extract the details for the specific global name change
				Set @sSQLString="
				Select	@sChangeNameType  =CHANGENAMETYPE,
					@sCopyFromNameType=COPYFROMNAMETYPE,
					@nCopyFromNameNo  =COPYFROMNAMENO,
					@nCopyFromAttn    =COPYFROMATTN,
					@sCopyFromRef     =COPYFROMREF,
					@dtCommenceDate	  =COMMENCEDATE,
					@nEDEBatchNo	  =EDEBATCHNO
				from #TEMPGLOBALNAMECHANGES
				where SEQUENCENO=@nSequenceNo"
			
				exec @ErrorCode=sp_executesql @sSQLString,
							N'@nSequenceNo		int,
							  @sChangeNameType	nvarchar(3)		OUTPUT,
							  @sCopyFromNameType	nvarchar(3)		OUTPUT,
							  @nCopyFromNameNo	int			OUTPUT,
							  @nCopyFromAttn	int			OUTPUT,
							  @sCopyFromRef		nvarchar(80)		OUTPUT,
							  @dtCommenceDate	datetime		OUTPUT,
							  @nEDEBatchNo		int			OUTPUT',
							  @nSequenceNo		=@nSequenceNo,
							  @sChangeNameType	=@sChangeNameType	OUTPUT,
							  @sCopyFromNameType	=@sCopyFromNameType	OUTPUT,
							  @nCopyFromNameNo	=@nCopyFromNameNo	OUTPUT,
							  @nCopyFromAttn	=@nCopyFromAttn		OUTPUT,
							  @sCopyFromRef		=@sCopyFromRef		OUTPUT,
							  @dtCommenceDate	=@dtCommenceDate	OUTPUT,
							  @nEDEBatchNo		=@nEDEBatchNo		OUTPUT

				-- Now we need to load a temporary table with the Cases that
				-- are to be updated by the global name change
				If @ErrorCode=0
				Begin
					Set @sSQLString="
					insert into #TEMPCASESFORNAMECHANGE(CASEID)
					select distinct T.CASEID
					from #TEMPCASEEVENT T
					join #TEMPCASES C on (C.CASEID=T.CASEID
							  and C.ERRORFOUND is null)
					join CASENAME CN on (CN.CASEID=T.CASEID
							 and CN.NAMETYPE=T.COPYFROMNAMETYPE
							 and CN.EXPIRYDATE is null)
					where T.[STATE] like 'I%'
					and T.OCCURREDFLAG=1
					and T.CHANGENAMETYPE  = @sChangeNameType
					and T.COPYFROMNAMETYPE= @sCopyFromNameType
					and CN.NAMENO         = @nCopyFromNameNo"
					-----------------------------------------------------------
					-- SQA18041 - Performance improvement rather than use an OR,
					-- change the constructed SQL depending on whether there is
					-- a value in the variable or not.
					-----------------------------------------------------------
					If @nCopyFromAttn is not null
						Set @sSQLString=@sSQLString+"
						and CN.CORRESPONDNAME = @nCopyFromAttn"
					Else
						Set @sSQLString=@sSQLString+"
						and CN.CORRESPONDNAME is null"
					
					If @sCopyFromRef is not null
						Set @sSQLString=@sSQLString+"
						and CN.REFERENCENO = @sCopyFromRef"
					Else
						Set @sSQLString=@sSQLString+"
						and CN.REFERENCENO is null"	
		/******* SQA19504 - force the global change even if the Name row exists as this will trigger any inheritance rules
					Set @sSQLString=@sSQLString+"
					-- Ignore entries where the change has already been applied
					and not exists
					(select 1 from CASENAME CN1
					 where CN1.CASEID=CN.CASEID
					 and CN1.NAMETYPE=T.CHANGENAMETYPE
					 and CN1.NAMENO=CN.NAMENO
					 and CN1.EXPIRYDATE is null)"
		 ******* SQA19504 ***************/
				
					exec @ErrorCode=sp_executesql @sSQLString,
							N'@sChangeNameType	nvarchar(3),
							  @sCopyFromNameType	nvarchar(3),
							  @nCopyFromNameNo	int,
							  @nCopyFromAttn	int,
							  @sCopyFromRef		nvarchar(80)',
							  @sChangeNameType	=@sChangeNameType,
							  @sCopyFromNameType	=@sCopyFromNameType,
							  @nCopyFromNameNo	=@nCopyFromNameNo,
							  @nCopyFromAttn	=@nCopyFromAttn,
							  @sCopyFromRef		=@sCopyFromRef

					Set @nCaseCount=@@Rowcount
				End

				-- Load the details for the global name change into the
				-- database to ensure that they are processed to completion.
				If  @ErrorCode=0
				and @nCaseCount>0
				Begin
					Set @nRequestNo=null

					------------------------------------------------
					-- SQA20912
					-- If there isn't an explicit EDEBATCHNO to use,
					-- then use the value provided as a parameter
					------------------------------------------------
					If @nEDEBatchNo is null
						Set @nEDEBatchNo=@pnEDEBatchNo

					Set @sSQLString="
					insert into CASENAMEREQUEST(PROGRAMID,NAMETYPE,NEWNAMENO,NEWATTENTION,
								    UPDATEFLAG,INSERTFLAG,DELETEFLAG,
								    KEEPREFERENCEFLAG,
								    INHERITANCEFLAG,NEWREFERENCE,COMMENCEDATE,ONHOLDFLAG,
								    EDEBATCHNO, LOGTRANSACTIONNO)
					values(	@sProgramId,@sChangeNameType,@nCopyFromNameNo,@nCopyFromAttn,
						1,1,0,
						CASE WHEN(@sCopyFromRef is null) THEN 2 ELSE 3 END,
						1,@sCopyFromRef,@dtCommenceDate,0,@nEDEBatchNo,@nTransNo)

					set @nRequestNo=SCOPE_IDENTITY()"
					
					exec @ErrorCode=sp_executesql @sSQLString,
							N'@sProgramId		nvarchar(8),
							  @sChangeNameType	nvarchar(3),
							  @nCopyFromNameNo	int,
							  @nCopyFromAttn	int,
							  @sCopyFromRef		nvarchar(80),
							  @dtCommenceDate	datetime,
							  @nEDEBatchNo		int,
							  @nTransNo		int,
							  @nRequestNo		int		OUTPUT',
							  @sProgramId		=@sProgramId,
							  @sChangeNameType	=@sChangeNameType,
							  @nCopyFromNameNo	=@nCopyFromNameNo,
							  @nCopyFromAttn	=@nCopyFromAttn,
							  @sCopyFromRef		=@sCopyFromRef,
							  @dtCommenceDate	=@dtCommenceDate,
							  @nEDEBatchNo		=@nEDEBatchNo,
							  @nTransNo		=@nTransNo,
							  @nRequestNo		=@nRequestNo	OUTPUT

					If @nRequestNo is not null
					and @ErrorCode=0
					Begin
						Set @sSQLString="
						insert into CASENAMEREQUESTCASES(REQUESTNO,CASEID,LOGTRANSACTIONNO)
						select @nRequestNo,CASEID,@nTransNo
						from #TEMPCASESFORNAMECHANGE"

						exec @ErrorCode=sp_executesql @sSQLString,
									N'@nRequestNo	int,
									  @nTransNo	int',
									  @nRequestNo=@nRequestNo,
									  @nTransNo  =@nTransNo
					End
				
					-- Clear out the Cases from the last global name change
					-- in preparation to reload with the next set of Cases to update
					If  @ErrorCode=0
					and @nSequenceNo<@nGlobalChanges
					Begin
						Set @sSQLString="delete from #TEMPCASESFORNAMECHANGE"
			
						exec @ErrorCode=sp_executesql @sSQLString
					End
				End
			End	-- end of loop through Global Name Changes
		End

		---------------------------------------------------------
		-- Delete the COPYFROMNAMETYPE
		---------------------------------------------------------

		-- If the COPYFROMNAMETYPE has been flagged to be removed
		-- then delete the CASENAME rows from the database
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			delete CASENAME
			from CASENAME CN
			join #TEMPCASES C	on (C.CASEID=CN.CASEID
						and C.ERRORFOUND is null)
			join #TEMPCASEEVENT T	on (T.CASEID=CN.CASEID
						and T.COPYFROMNAMETYPE=CN.NAMETYPE
						and T.DELCOPYFROMNAME =1)
			where T.[STATE] like 'I%'
			and T.OCCURREDFLAG=1"

			exec @ErrorCode=sp_executesql @sSQLString
		End
		
		--------------------------------------------
		-- Link the PriorArt rows to the Cases found 
		-- within the same extended family.
		--------------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Insert into CASESEARCHRESULT(FAMILYPRIORARTID,CASEID,PRIORARTID,STATUS,UPDATEDDATE,CASEFIRSTLINKEDTO,CASELISTPRIORARTID,NAMEPRIORARTID,ISCASERELATIONSHIP)
			select T.FAMILYPRIORARTID,T.CASEID,T.PRIORARTID,T.STATUS,T.UPDATEDDATE,T.CASEFIRSTLINKEDTO,T.CASELISTPRIORARTID,T.NAMEPRIORARTID,T.ISCASERELATIONSHIP
			from #TEMPCASESEARCHRESULT T
				    ----------------------------------
				    -- Now check to see prior art has
				    -- already been associated with
				    -- the case in the family.
				    ----------------------------------
			left join CASESEARCHRESULT CSR
						  on (CSR.PRIORARTID=T.PRIORARTID
						  and CSR.CASEID    =T.CASEID)
			Where CSR.CASEID is null"
		
			exec @ErrorCode=sp_executesql @sSQLString
		End
		
		---------------------------------------------
		-- Remove any duplicate Prior Art from a Case
		-- that has just been updated.
		---------------------------------------------
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			with CTE_CaseSearch (CASEID, PRIORARTID, FAMILYPRIORARTID, CASELISTPRIORARTID, NAMEPRIORARTID, CASEPRIORARTID)
				as (	select CASEID, PRIORARTID, FAMILYPRIORARTID, CASELISTPRIORARTID, NAMEPRIORARTID, MIN(CASEPRIORARTID)
					from CASESEARCHRESULT
					group by CASEID, PRIORARTID, FAMILYPRIORARTID, CASELISTPRIORARTID, NAMEPRIORARTID
					having COUNT(*) >1)
					
			delete CSR
			from CTE_CaseSearch CTE
			join #TEMPCASESEARCHRESULT T 
						  on (T.CASEID=CTE.CASEID)
			join CASESEARCHRESULT CSR on (CSR.CASEID            =CTE.CASEID
						  and CSR.PRIORARTID        =CTE.PRIORARTID
						  and(CSR.FAMILYPRIORARTID  =CTE.FAMILYPRIORARTID   OR (CSR.FAMILYPRIORARTID   is null and CTE.FAMILYPRIORARTID   is null))
						  and(CSR.CASELISTPRIORARTID=CTE.CASELISTPRIORARTID OR (CSR.CASELISTPRIORARTID is null and CTE.CASELISTPRIORARTID is null))
						  and(CSR.NAMEPRIORARTID    =CTE.NAMEPRIORARTID     OR (CSR.NAMEPRIORARTID     is null and CTE.NAMEPRIORARTID     is null))
						  and CSR.CASEPRIORARTID   <>CTE.CASEPRIORARTID)"
		
			exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Delete the successfully processed POLICING rows.  Note any errors for the same CASE will leave the 
		-- POLICING row on hold and unprocessed.

		if  @ErrorCode=0
		Begin
			Set @sSQLString="
			Delete POLICING
			from POLICING P
			left join #TEMPCASES C  on (C.CASEID=P.CASEID)
			join #TEMPPOLICING T	on (T.DATEENTERED  =P.DATEENTERED
						and T.POLICINGSEQNO=P.POLICINGSEQNO
						and T.TYPEOFREQUEST=P.TYPEOFREQUEST
						and T.SQLUSER      =P.SQLUSER
						and(T.CASEID       =P.CASEID       OR (T.CASEID       is null and P.CASEID       is NULL))
						and(T.ACTION       =P.ACTION       OR (T.ACTION       is null and P.ACTION       is NULL))
						and(T.EVENTNO      =P.EVENTNO      OR (T.EVENTNO      is null and P.EVENTNO      is NULL))
						and(T.CRITERIANO   =P.CRITERIANO   OR (T.CRITERIANO   is null and P.CRITERIANO   is NULL))
						and(T.CYCLE        =P.CYCLE        OR (T.CYCLE        is null and P.CYCLE        is NULL))
						and(T.COUNTRYFLAGS =P.COUNTRYFLAGS OR (T.COUNTRYFLAGS is null and P.COUNTRYFLAGS is NULL))
						and(T.FLAGSETON    =P.FLAGSETON    OR (T.FLAGSETON    is null and P.FLAGSETON    is NULL)))
			where P.SYSGENERATEDFLAG=1
			and   P.ONHOLDFLAG      >0
			and   C.ERRORFOUND is null"

			Exec @ErrorCode=sp_executesql @sSQLString

		End

		-- If any POLICING rows were created to act as a lock on Cases then they can now be removed.
		If  @ErrorCode=0
		and @pdtLockDateTime is not null
		Begin
			Set @sSQLString="
			Delete POLICING
			from POLICING P
			where P.DATEENTERED=@pdtLockDateTime
			and   P.POLICINGNAME like 'Generated%'
			and   P.SYSGENERATEDFLAG=1
			and   P.ONHOLDFLAG      >0"

			Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pdtLockDateTime	datetime',
						  @pdtLockDateTime=@pdtLockDateTime

		End

		-----------------------------------------------------------------------------
		-- Reset the ONHOLDFLAG to 0 the Case was marked with an ErrorFound but there
		-- were no explicit Policing Error rows written. This will indicate that the
		-- error was caused by a concurrency issue and so the Policing request should
		-- be reset to process again.
		-- Ensure a loop count error hasn't occurred as these are not yet written
		-- into #TEMPPOLICINGERRORS.
		-----------------------------------------------------------------------------

		If @ErrorCode=0
		Begin	
			Set @sSQLString="
			Update POLICING
			Set ONHOLDFLAG=0,
			    SPIDINPROGRESS=null
			from POLICING P
			     join #TEMPCASES C	on (C.CASEID=P.CASEID
						and C.ERRORFOUND=1)
			left join #TEMPPOLICINGERRORS E on (E.CASEID=P.CASEID)
			Where P.ONHOLDFLAG in (2,3,4)
			and P.SYSGENERATEDFLAG=1	
			and E.CASEID is null
			-- RFC 11723
			and not exists
			(select 1
			 from #TEMPCASEEVENT CE
			 join SITECONTROL S on (S.CONTROLID='Policing Loop Count')
			 where CE.CASEID=C.CASEID
			 and CE.LOOPCOUNT>isnull(S.COLINTEGER,25))"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Reset the ONHOLDFLAG to 4 where there are POLICINGERRORS for the Case.
		-- This indicates that no further attemps at processing are required.
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			Update POLICING
			set ONHOLDFLAG=4
			from POLICING P
			join #TEMPPOLICINGERRORS E on (E.CASEID=P.CASEID)
			Where P.ONHOLDFLAG in (2,3)"

			Exec @ErrorCode=sp_executesql @sSQLString
		End

		-- Insert new Policing Request rows where Case Events
		-- waiting on a Document Case Event have now been updated
		-- and need to trigger their own workflows.
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
						ONHOLDFLAG, EVENTNO, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
			select	getdate(), T.POLICINGSEQNO, 'POL-'+convert(varchar, getdate(),126)+convert(varchar,T.POLICINGSEQNO),1,
				0, T.EVENTNO, T.CASEID, T.CYCLE, T.TYPEOFREQUEST, T.SQLUSER, T.IDENTITYID
			from #TEMPPOLICINGREQUEST T
			
			delete #TEMPPOLICINGREQUEST"	-- RFC13662

			Exec @ErrorCode=sp_executesql @sSQLString
		End
			
		If @ErrorCode=0
		and @nQueueId is not null
		Begin
			------------------------------------
			-- When update queue control is in
			-- use, then update EndTime for this
			-- batch now that entry is processed
			------------------------------------
			UPDATE	dbo.POLICINGUPDATEQUEUE
			SET	ENDTIME = GETDATE()
			WHERE	QUEUEID = @nQueueId
			
			Set @ErrorCode=@@Error
		End	

		-- Commit or Rollback the transaction

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

			-- DR-49441 Add ERROR_LINE() & ERROR_PROCEDURE() to error message
			If ERROR_PROCEDURE() IS NOT NULL
			Begin 
				set @sErrorMessage = @sErrorMessage  + 
				'; Error Proc: ' + isnull(ERROR_PROCEDURE(), '') +
				'; Error line number: ' +  isnull(CAST(ERROR_LINE() AS VARCHAR(20)),0) 
			End
			-- Use RAISERROR inside the CATCH block to return error
			-- information about the original error that caused
			-- execution to jump to the CATCH block.
			RAISERROR ( @sErrorMessage,	-- Message text.
			            @nErrorSeverity,	-- Severity.
			            @nErrorState	-- State.
			           )
		End
		Else Begin
			-- Wait for 5 seconds before making the next attempt
			WAITFOR DELAY '00:00:05'
		End
	END CATCH
END -- While loop

If @nGlobalChanges>0
and @nTransNo is not null
and @ErrorCode=0
Begin
	-- RFC-39102 Use service broker instead of OLE Automation to run the command asynchronoulsly
	------------------------------------------------
	-- Build command line to run cs_GlobalNameChange 
	-- using service broker
	------------------------------------------------
	Select @sCommand = 'dbo.cs_GlobalNameChangeByTransNo @pnUserIdentityId='+CASE WHEN(@pnUserIdentityId is null) THEN 'null' ELSE cast(@pnUserIdentityId as varchar) END+',@pnTransNo='+cast(@nTransNo as varchar)
	exec @ErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				

End

If  @pnDebugFlag>0 
and @ErrorCode=0
Begin
	declare @sTimeStamp	nvarchar(24)
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	RAISERROR ('%s ip_PoliceUpdateDataBase',0,1,@sTimeStamp ) with NOWAIT
End

return @ErrorCode
go

grant execute on dbo.ip_PoliceUpdateDataBase  to public
go
