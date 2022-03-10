-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalNameChange
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_GlobalNameChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_GlobalNameChange.'
	drop procedure dbo.cs_GlobalNameChange
end
print '**** Creating procedure dbo.cs_GlobalNameChange...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.cs_GlobalNameChange 
as
  -- blank to create sp so the next ALTER statement will work with no warnings on self called execution.
go

ALTER PROCEDURE [dbo].[cs_GlobalNameChange]
	@pnNamesUpdatedCount		int		= 0	output,
	@pnNamesInsertedCount		int		= 0	output,
	@pnNamesDeletedCount		int		= 0	output,
	@pnUserIdentityId		int		= null,
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	-- Filter Parameters
	@psGlobalTempTable		nvarchar(32)	= null,	-- name of temporary table of CASEIDs to be reported on if @pnRequestNo not provided.
	@psProgramId			nvarchar(20)	= null,	-- the Name of the program calling the stored procedure, used for determining valid nametypes
	@psNameType			nvarchar(3)	= null,	-- the NameType
	@pnExistingNameNo		int		= null, -- the NameNo if a specific one is effected by the change
	@pnExistingCorrespondName	int		= null, -- a particular CorrespondName to be modified
	-- Change Details
	@pnNewNameNo			int		= null, -- the replacement Name.  If null then deletion is required.
	@pnNewCorrespondName		int		= null, -- the replacement Correspondence Name.
	@pbNewInheritedFlag		bit		= null, -- indicates that the Name has been inherited
	-- Path of how @pnNewNameNo was determined
	@psPathNameType			nvarchar(3)	= null, -- the NameType used to determine the current NameType being updated
	@pnPathNameNo			int		= null, -- the NameNo used to determine the NewNameNo from an AssociatedName
	@psPathRelationship		nvarchar(3)	= null, -- the Relationship used to determine the NewNameNo from an AssociatedName
	@pnPathSequence			smallint	= null, -- the Sequence used to determine the NewNameNo from an AssociatedName
	-- Options
	@pbUpdateName			bit		= 1,	-- indicates that existing Names are to be changed
	@pbInsertName			bit		= 0,	-- indicates that the Name is to be inserted if it does not already exist
	@pbDeleteName			bit		= 0,	-- indicates the name is to be removed from Cases
	@pbKeepCorrespondName		bit		= 0, 	-- when set on the existing Correspondence Name will not be changed.
	@pnKeepReferenceNo		smallint	= 2, 	-- when 1 the existing ReferenceNo will be retained.  when 2 the existing
								-- reference no will be cleared, when 3 new reference number will be received via
								-- @psReferenceNo
	@pbApplyInheritance		bit		= 0,	-- indicates that changed NameType is to have a cascading
								-- global name change effect based on inheritance rules.
								-- NOTE: The checkbox for this flag must only be enabled
								--       if the user has specified a NameType and has 
								--       NOT specified an ExistingNameNo.  This is to 
								--       allow inheritance to apply to all of the Cases
								--       in the temporary table.
	@psReferenceNo			nvarchar(80)	= null,	-- the new reference number for the new name.
	-- Flag
	@pbSuppressOutput		bit		= 0,
	-- SQA12315
	@pdtCommenceDate		datetime	= null,	-- used to indicate when the Name will take effect against the Case
	@pnAddressCode			int		= null,	-- allow a specific Address code to be applied
	@pbPoliceImmediately		bit		= 0,	-- Option to run Police Immediately
	@pnHomeNameNo			int		= null,
	@pnBatchNo			int		= null,
	@pnTransNo			int		= null,
	@pnRequestNo			int		= null,	-- Key to CASENAMEREQUEST table
	@pnTransReasonNo		int		= null,
	@pbCalledFromCentura		bit		= 1, 	-- 0 for Workbenches
	@pbForceInheritance		bit		= 0,	-- 1 indicates that inheritance will apply even if existing Name was not inherited
	@pbRemoveOrphans		bit		= 1,	-- Flag to control when the removal of orphan inherited CASENAMEs should occur.
	@pbAlerts			bit		= 1,	-- If updates are being applied then an option to apply changes to ALERTS table
	@pnExistingAddressKey		int		= null, -- a particular Address to be modified
	@pbResetAddress			bit		= 0,	-- Reset the addresses
	@pbResetAttention		bit		= 0,	-- Reset the attention
	@pbFromDefaultAttention		bit		= 0,	-- Change attention where the current attention is the default or null
	@pbFromDefaultAddress		bit		= 0	-- Change address where the current address is the default (null)

AS
-- PROCEDURE :	cs_GlobalNameChange  
-- VERSION:	96
-- DESCRIPTION:	Applies global name changes to the Cases included in the temporary table.
--		If @psNewNameNo is null the Names indicated will be deleted from the Cases.
--		If @psNewNameNo is not null then the Name will either be inserted for a particular
--		NameType or it will modify the matching Name for the NameType
--		NOTE :	This stored procedure is called recursively to enable a cascading effect of global
--			name changes to occur if the user has elected to apply inheritance rules.
-- CALLED BY :	cs_GlobalNameChange (recursive)
-- COPYRIGHT	Copyright 1993 - 2014 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05/01/2003	MF	7742		Procedure created
-- 05/03/2003	MF	7742		Return a separate count for Updated, Inserted and Deleted rows.
-- 12/03/2003	MF	7742		Allow for the CorrespondName to be cleared out.
-- 13/03/2003	MF	7742		When getting the NameTypes allowed for a Case ensure that NULLs are not returned.
-- 14/03/2003	MF	7742		Explicit flags are required as parameters to indicate when Update, Insert or Delete should occur.
-- 19/09/2003	MF	7742		Ensure that you can clear out an attention.
-- 19/09/2003	MF	7742		Introduced bug to UPDATE when adding a new attention
-- 19/03/2003	MB	7742		Commented SELECT @sUpdateString
-- 23/03/2003	MF	8554		When a new name is being added to a Case via Global Name Change then do 
--					not insert the Name if it will cause the maximum number of Names to be 
--					exceeded for that NameType and Case.  Also restrict deletion if the NameType
--					is mandatory.
-- 23/03/2003	MF	8555		If only the Attention is being changed against an Instructor then do not update the 
--					Local Client flag against the Case because the main name has not actually changed.
-- 26/03/2003	MF	8570		Global Name Change to also issue Policing recalculations when standing instructions 
--					are changed.
-- 29/05/2003	MF	8827		When global name change is applied only CASEEVENT for EVENTNO -14 is supposed to be
--					updated.  Error in code was allowing all Events to be changed.
-- 18/06/2003	MF	8827		Bugger.  I had to revisit this because there are two places where CASEEVENT is updated
--					and the second one was still not limiting the EVENTNO to -14.
-- 30 Sep 2003	MF	9213	3	Address details not changing when the Name is supposed to save the address.
-- 30 Sep 2003	MF	9309	3	Office is to be considered when getting the ScreenControl details of the Case
--					to check for the available NameTypes.
-- 26 Feb 2004	MF	9612	4	Do not clear out the Reference when the Attention is being removed.
-- 09 Jun 2004	MF	10163	5	Allow for the number of Policing requests generated to exceed smallint size
--					by changeing POLICINGSEQNO to int.
-- 05 Aug 2004	AB	8035	6	Add collate database_default to temp table definitions
-- 23 Aug 2004	VL	10149	7	REFERENCENO column to nvarchar(80)
-- 01 Mar 2005	RCT	11095	8	Corrected sql syntax error when applying inheritance. (Reviewed and tested by MF)
-- 26 May 2005	MF	8748	9	Allow a parameter that will suppress the output being returned.
-- 17 Aug 2005	MF	11756	10	When generating Policing requests as a result of a Standing Instruction change
--					the Cycle of the CaseEvent to be calculated should come from the OpenAction if
--					the Action the event belongs to is cyclic and the CaseEvent row does not already
--					exist.
-- 21 Oct 2005	KR	10615	11	Allow for global name change to accept a new reference.
-- 11 Nov 2005	MF	10782	11	Flag the global Case temporary table for those Cases that have had a change.
-- 16 Nov 2005	vql	9704	12	When updating POLICING table insert @pnUserIdentityId.
-- 08 Feb 2006	MF	12282	13	Allow for more than 32,000 Case Names to be inserted in the #TEMPCASENAMES table.
-- 23 Mar 2006	DR	9612	14	Remove work-around code setting @pnKeepReferenceNo=1 due to user interface error as UI has now been fixed.
-- 10 Apr 2006	MF	12537	15	Change of NAME should also apply to the Case level standing instructions
--					held in the NAMEINSTRUCITONS table.
-- 12 May 2006	DR	8911	16	Cater for new column CASENAME.DERIVEDCORRNAME which indicates whether or not
--					CORRESPONDNAME is derived or user-set.
-- 15 May 2006	MF	12537	17	Revisit.  Where multiple NAMEINSTRUCTIONS for different NAMENOs are being 
--					consolidated into a single NameNo then there was the potential for a 
--					duplicate key error to occur.
-- 30 May 2006	DR	8911	19	Set derived attention to main contact regardless of its property type or country.
-- 22 May 2006	MF	12315	19	NameTypes may be associated with an Event when a CASENAME row is inserted or
--					or the NameNo updated, the associated Event is to be inserted/updated and the
--					Policing request entered.
-- 30 May 2006	MF	12327	19	A NameType may now be flagged to indicate if a change in parent is to flow
--					down to any previously inherited names.  If the flag is off then the inheritance
--					will only occur when the child Name Type is initially determined for the Case.
-- 01 Jun 2006	MF	12317	19	Allow inheritance to occur from the Home Name.  If the inheritance can occur
--					from an associated Name of the parent Name Type then this will always take 
--					precedence over inheriting from the HomeName.
-- 01 Jun 2006	MF	12317	19	New code added to remove CASENAME rows that have been inherited however the
--					parent has subsequently ben removed.  E.g. Instructor has default rule to send
--					Copy of letters to another Name.  The Instructor may be changed to another 
--					Instructor that does not require Copy of letters.
--					Also code has been added to insert the Inheritance information where a name has
--					been explicitly entered against a Case with the same Name that would have 
--					have naturally inherited if inheritance had have linked the Name to the Case.
-- 06 Jun 2006	MF	12327	19	Any CaseName that do not have the inheritance pointers but whose data is in fact
--					identical to what would have been inherited are now being updated to set the
--					inheritance pointers.
-- 06 Jun 2006	MF	12327	19	To allow the cs_ApplyRecordal procedure to call cs_GlobalNameChange, this
--					procedure has been changed to accept a specific AddressCode as an input
--					parameter.
-- 15 Jun 2006	MF	12315	20	Revisit.  Commence Date from parent Case Name is not to inherit down.
-- 20 Jun 2006	DR	8911	21	If keeping the attention name, set 'attention derived' flag OFF.
-- 27 Jun 2006	MF	12898	22	Revisit of 12537.  Instead of updating the NameNo against the Case specific
--					standing instructions, the global name change will remove them if the name type
--					that derives the standing instruction now has a different NameNo.
-- 21 Jul 2006	MF	13018	23	New name was being inserted against a Case even though only changes were
--					supposed to occur.  The @pbInsertName flag was being set on in certain
--					circumstances.  This code has now been commented out however there may be
--					other implications of this.
-- 01 Aug 2006	MF	13021	24	If the parent of an inherited name is removed then the inherited child names
--					should also be removed unless they are marked as being mandatory.
-- 09 Oct 2006	MF	13580	25	Allow Event to be triggered by change of Name even if the EventDate is not
--					going to change.
-- 11 Dec 2006	DR	13785	26	Use DefaultNameNo in name type inheritance where appropriate.
-- 19 Jan 2007	DR	13785	27	Fix handling of Home Name inheritance option in clean up of orphan inherited
--					names and correction of parentage pointers.
-- 25 Jan 2007	DR	13785	28	If doing inheritance, only update names that are currently inherited.
-- 30 Jan 2007	DR	14172	29	Correct defaulting of attention names to only select the name main contact
--					if the 'Main Contact used as Attention' site control is TRUE.
-- 02 Feb 2007	DR	14023	29	Only set attention if name type flag indicates it is used, except for Instructor and Agent.
-- 15 Feb 2007	DR	14023	30	Sequence number for new records needs to be unique for case and name type (not including name no.).
-- 28 Feb 2007	PY	14425	31 	Reserved word [sequence]
-- 20 Apr 2007	MF	14707	32	CaseName updates that do not apply to a specific Name Type are to ignore CaseName
--					rows that have the ExpiryDate set to a date less than the system date.  This will
--					avoid global name changes being applied to historical CaseName records that are
--					saved under certain NameTypes (e.g. Previous Renewal Instructor).
-- 26 Apr 2007	JS	14323	33	Added CASENAME attention name derivation logic for Debtor/Renewal Debtor.
-- 17 May 2007	MF	12299	34	REFERENCENO was found to be getting set to an empty string instead of NULL.
-- 22 May 2007	MF	12299	35	Add option to allow Policing to be called immediately.
-- 09 Jul 2007	MF	15026	36	Performance improvement to CaseName update that sets the parent NameNo.
--					Store HomeNameNo as a variable to avoid joining to SITECONTROL.
--					Also do not insert CASENAME row with BILLINGPERCENTAGE if existing Billing
--					Percentage total is already 100.
-- 12 Jul 2007	MF	14032	37	Global Name Changes were not picking up the NameType defined in the "Additional
--					Internal Staff" sitecontrol and therefore that NameType could not be added.
-- 19 Nov 2007	MF	15544	38	If the NameType is flagged not to inherit after the initial inheritance then do
--					not insert new CASENAME rows for the NameType if that NameType already exists
--					against the Case.
-- 28 Nov 2007	MF	15635	38	Updates may cause all existing rows to be removed when no specific existing
--					Name has been identified for the update.  The code should keep at least one
--					row for the update to occur against.
-- 16 Jan 2008	MF	15635	39	Remove debug code.
-- 01 Apr 2008	MF	16176	38	SQL conversion error when no default name no is provided for an inheriting NameType.
-- 17 Apr 2008	MF	16267	40	If @pnNewCorrespondName is supplied with a Name but the @pbUpdateName parameter
--					is supplied turned OFF then it must be turned on for the global name change
--					to apply the change of Attention name
-- 07 May 2008	MF	16370	41	When determinining the Screen Control Criteria used for determining the valid
--					NameTypes, consideration needs to be given to taking user defined criteria in 
--					preference to system delivered criteria.
-- 09 May 2008	MF	16382	42	Related to 16267 however also need to consider when the Attention is being reset
--					to the default attention.
-- 20 May 2008	MF	16430	43	Provide for the Global Name Change request details to be held in a table. This
--					will provide a better assurance that all requests are seen through to successful
--					completion at which time the request will be deleted. It also provides a means
--					by which Global Name Changes that are part of other transactions (e.g. EDE or 
--					Policing) may raise the request and then start Global Name Change running in 
--					background.
-- 26 Jun 2008	MF	16610	44	Prefix the POLICING.POLICINGNAME colum with GNC to indicate that Global Name 
--					Change inserted the row. This is for debugging reasons.
-- 23 Jul 2008	MF	16739	45	To reduce the number of Events being sent to Policing as a result of potential
--					standing instruction changes, determine exactly what standing instructions have
--					changed as a result of the name change before creating the Policing requests.
-- 27 Aug 2008	MF	16846	46	Change of Instructor audit trail row does not keep batchno information.
-- 02 Sep 2008	MF	16867	47	Pass the transaction reason to use.
-- 03 Nov 2008  MS	RFC5698	48	GlobalNameChange for WorkBenches, added parameter @pbCalledFromCentura for WorkBenches. 
--					If this parameter is 0 then it is being called from WorkBenches. 
--					For WorkBenches, the IsUpdated, IsAdded and IsRemoved values are added to CASENAMEREQUEST table. 
-- 11 Dec 2008	MF	17136	49	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 07 Jan 2009  MS	RFC7371	50	Set the value of IDENTITYID column of CASENAMEREQUEST table 
-- 09 Feb 2009	MF	17274	51	Allow Reference against Name to be changed even if name itself does not change.
-- 10 Feb 2009	MF	17382	52	Apply name changes against the CASEEVENT rows that have an explicit responsible name 
--					that is being modified for the Name Type associated with the EventControl rule.
-- 24 Feb 2009	MF	17425	53	Policing requests not being raised when standing instruction that impacts Events changed.
-- 11 Mar 2009	MF	17433	54	Ensure that the Commence Date of any name changes is passed down to the inherited names as well.
-- 17 Mar 2009	MF	17489	55	Strategy to reduce potential for deadlocks by not proceeding with global name change
--					if there are outstanding GNC requests for any of the Cases about to be processed.
-- 25 Mar 2009  MS	RFC5703 56	For WorkBenches, Insert record into BACGROUNDPROCESS table and 
--					use PROCESSID for CASENAMEREQUEST REQUESTID
-- 07 Apr 2009	MS	RFC5703	57	Corrected issue of Message description for BACGROUNDPROCESS table.
-- 05 Jun 2009	MF	17765	58	Cater for a @psReferenceNo that has an embedded quote by replacing with 2 quotes.
-- 15 Sep 2009	MF	17983	59	Reverse code introduced with 17382 as this code has been moved into the database
--					triggers (td_CaseNameEvents, ti_CaseNameEvents and tu_CaseNameEvents)
-- 16 Sep 2009	MS    RFC100062	60	Delete the process rows from CASENAMEREQUEST and CASENAMEREQUESTCASES table in the 
--					transaction for WorkBenches if the Global Name Change process is successful
-- 15 Oct 2009	MF	18135	61	Global Name Change for draft cases needs to be based on actual case type when determining
--					if the Name Type is valid to be use.
-- 12 Nov 2009	MS    RFC100073	62	Introduce a new local temp table and insert data from globaltemptable to this table
--					and change the argument @psGlobalTemptabel to the newly created local temp table name for WorkBenches
-- 08 Dev 2009	MS    RFC100063	63	Add Global Name Change Counts and Changed Cases to tables GNCCOUNTRESULTS and GNCCHANGEDCASES respectively.
-- 13 Jan 2010	MF	17878	64	Revisit. Need to remove test on N.NAMENO from @sDeleteString.
-- 01 Jul 2010	MF	18758 	65	Increase the column size of Instruction Type to allow for expanded list.
-- 05 Jul 2010	MF	RFC9642	66	A new parameter @pbForceInheritance that when set on will force inheritance of Names even if an existing Name
--					for a NameType that can be inherited is flagged as having not been inherited.
-- 23 Nov 2010	MF	RFC9991	67	Crashing with SQL Error of "Subquery returned more than 1..." when REFERENCENO being updated
--					where a Case has the same Name attached multiple times for the one NameType.
-- 29 Nov 2010	MF	RFC10024 66	When called from web, get the screen Control criteria using the Purpose Code='W'
-- 30 Nov 2010	MF	RFC10024 67	Revisit for now and go back to using Purpose Code='S' for the time being.  Getting the NAMETYPE is actually
--					more complicated for the Web version so for now continue to use the client/server rules.
-- 21 Dec 2010	MF	RFC9969	68	A name that is being inherited for a particular Name Type must be allowed to be used as that NameType. If the
--					NameType is flagged as "Same Name Type" then only those Names that can be used for that Name Type are to be
--					inherited.  
-- 29-Jul-2011	MF	R11039	69	When determining the Case Events to recalculate as a result of a Standing Instruction change we need to consider
--					the possible Cycle(s) that may be calculated by looking at the calculation rules and consider referenced events
--					and their cycles.
-- 11-Jan-2012	MF	R11787	70	Always get the MAXIMUMALLOWED for NAMETYPE from the database and don't hardcode.
-- 12 Feb 2012	MF	R11919	71	When removing CaseNames that have been inherited from a parent that does not exist or was inherited
--					from the HOMENAMENO, only remove CaseNames that are relevant to the explicit Cases impacted by the current
--					parameters passed to this execution of cs_GlobalNameChange. Where global name changes for Associated Names
--					are being triggered we have had a situation where a change has been applied causing CASENAME rows to be
--					inserted and then when the next Associated Name is used to call cs_GlobalNameChange the row previously
--					inserted is then deleted. The parameter @pbRemoveOrphans has been introduced to control when deletion of
--					orphan names is allowed.
-- 03 Jul 2012	LP	R12446	72	Avoid use of global temp tables for storing CASEIDs as they are sometimes dropped before the processing begins.
--					CASENAMEREQUEST and CASENAMEREQUESTCASES records are now created from calling SP when called from the Web.
-- 06 Sep 2012	MF	R12686	73	When global name change is called from the Web the valid NameTypes to use should be determined from the web
--					screen control rules and not Client/Server.
-- 28 Nov 2012	MF	20912	74	If the EDEBATCHNO has been supplied then a new LOGTRANSACTIONNO will be used to ensuure the name changes are
--					linked to the EDE Batch.
-- 18 Dec 2012	MF	20912	75	Extended to set the TRANSACTIONREASONNO associated with the @pnBatchNo.
-- 08 Jan 2013	MF	R13095	76	Removing some debug code discovered when working on this RFC.
-- 18 Jul 2013	MF	R13663	77	Recalculate Events that require the existence of a Document Case for a given Name Type. The
--					change of Name against the Case for the given Name Type could now mean an Event can occur.
-- 24 Sep 2013	MF	21415	78	Provide a method for References to be kept for changes being made via the Future Name Type.

-- 18 Dec 2013	MF	S21826	79	SQL Error on Global Name Change when a Case appears in Case Summary result more than once.  This can be resolved by
--					only using a Distinct set of CASEIDs from the supplied global temporary table.
-- 19 Feb 2014	DL	21702	79	Name Type Restrictions is ignored in Global Name Change
-- 24 Feb 2014	DL	21916	80	Change Event is being triggered when attention changes
-- 17 Mar 2014	MF	S22011	81	Duplicate key on POLICING table.  Requires a DISTINCT clause.
-- 30 Apr 2014	MF	S22072	82	Duplicate key error on EMPLOYEEREMINDER insert for ALERTS.
-- 04 Aug 2014	AT	R36958	83	Add option to change specific address.
-- 04 Aug 2014	AT	R36958	84	Optimised repetitive code.
-- 05 Aug 2014	SS	36960	85	Move reminders to the new name based on the users choice
-- 07 Aug 2014	AT	R36959	86	Add ability to reset case name addresses.
-- 10 Oct 2014	vql	R40013	87	Ensure global temporary table ISMODIFIED is correctly updated.
-- 15 Oct 2014	AT	R39331	88	Add change where attention is default and change where address is default filter flags.
--					Add Reset Attention flag and allow reset attention regardless of change of name.
-- 09 Jan 2014	MF	R41513	89	Events triggered to recalculate the due date (Type of Request = 6) should also consider Events that are flagged with RECALCEVENTDATE=1
--					if the Site Control 'Policing Recalculates Event' is set to TRUE.
-- 29 Apr 2015	KR	12171	90	made to select distinct CASEID from @psGlobalTempTable as it has some duplictes when passed to the backend
-- 19 Aug 2015	MF	41124	91	Correct inheritance pointers irrespective of UPDATEFROMPARENT flag if no @pnNewNameNo is supplied.
-- 15 Dec 2015	MF	56369	92	Revisit of SQA21916.  The Name Type Restrictions were not being considered when the parent name was flagged to be
--					used for an inherited Name Type when there was no explicit associated name.
-- 02 Aug 2016	MF	64248	92	CaseEvent for EventNo -14 will now be updated by database trigger so no need to perform this directly.
-- 06 Feb 2017	MF	70564	93	All variables used in dynamic SQL construction to be set to nvarchar(max) to avoid truncation issues.
-- 05 Mar 2019	MF	DR-45386 94	Under certain circumstances a previoulsy inherited NameType was not being removed because the INHERITEDFLAG had just been turned off.  The removal
--					needed to occur before turning the INHERITEDFLAG off for those rows that are to remain.
-- 06 Mar 2019	MF	DR-46214 94	When a name is being directly added to Cases and the Apply Inhertance option (@pbApplyInheritance=1) is on, then if the name being added could have 
--					been inherted for the Case then we need to set the inhertance details on the CASENAME row so that the system believes it was inherited.
-- 07 Mar 2019	MF	DR-47315 94	If matching on a specific Correspondence Name, also match on the default contact for the Name if the default is in use.
-- 12 Mar 2019	MF	DR-46214 95	Revisit as a result of failed user testing.
-- 09 Aug 2019	MF	DR-49731 96	Inheritance flags not being corrected when NameType updated does not trigger other NameTypes changes (meaning the procedure was not called recursively).

set nocount on
set concat_null_yields_null off
set ansi_warnings off
 
 CREATE TABLE dbo.#TEMPCASENAMES (
        CASEID               int 	  NOT NULL,
        NAMETYPE             nvarchar(3)  collate database_default NOT NULL,
        NAMENO               int 	  NOT NULL,
        SEQUENCE             smallint 	  NULL,
        CORRESPONDNAME       int 	  NULL,
        ADDRESSCODE          int 	  NULL,
        REFERENCENO          nvarchar(80) collate database_default NULL,
        BILLPERCENTAGE       decimal(5,2) NULL,
        INHERITED            decimal(1,0) NULL,
        INHERITEDNAMENO      int 	  NULL,
        INHERITEDRELATIONS   nvarchar(3)  collate database_default NULL,
        INHERITEDSEQUENCE    smallint     NULL,
	COMMENCEDATE	     datetime	  NULL,
        DERIVEDCORRNAME      decimal(1,0) NOT NULL	-- 8911
 )

 CREATE TABLE dbo.#TEMPUPDATESANDDELETES (
	CASEID               int 	  NOT NULL,
	NAMETYPE             nvarchar(3)  collate database_default NOT NULL,
	INTERNALSEQUENCE     int	  identity(1,1)
 )

 CREATE TABLE dbo.#TEMPALERT (
	EMPLOYEENO           int 	  NOT NULL,
	ALERTSEQ             datetime     NOT NULL,
	NEWALERTSEQ	     datetime	  NULL,
	SEQUENCENO	     int	  identity(5,5)	-- Milliseconds to be added to system date to generate new unique time
 )


-- VARIABLES

declare @ErrorCode		int
declare @TranCountStart		int
declare @nRowCount		int
declare @nAlertCount		int
declare @nUpdates		int
declare @nInserts		int
declare @nDeletes		int
declare	@nPolicingCount		int
declare @nPoliceBatchNo		int
declare @nProfileKey		int
declare @sUpdatedCasesString	nvarchar(max)
declare @sDeletedCasesString	nvarchar(max)
declare @sCorrectParentsString	nvarchar(max)
declare @sSQLString		nvarchar(max)
declare @sUpdateString		nvarchar(max)
declare @sInsertString		nvarchar(max)
declare @sDeleteString		nvarchar(max)
declare	@sFrom			nvarchar(max)	-- the SQL to list tables and joins
declare @sWhere			nvarchar(max) 	-- the SQL to filter
declare @sInheritedNameType	nvarchar(19)	-- 13785 increase size
declare @sInheritedNameTypeOUT	nvarchar(19)	-- 13785
declare @sNextNameType		nvarchar(3)
declare @sPathRelationship	nvarchar(3)
declare @bHierarchyFlag		bit
declare @bUseHomeNameRel	bit
declare @sAssociatedName	nvarchar(40)
declare @nInheritNameNo		int
declare @nParentNameNo		int
declare @nRelatedName		int
declare @nContact		int
declare @nRelatedSeq		smallint
declare	@bHexNumber		varbinary(128)

declare @nSequence		smallint
declare @nCaseId		int
declare	@nNameNo		int
declare	@sNameType		nvarchar(3)
declare	@sDelayLength		varchar(8)
declare @bDeriveCorrName	bit		-- 8911
declare @bIncludeBillPerc	bit		-- 8911
declare	@bGetCaseInstructions	bit
declare @bWaitLoop		bit
declare @bRecalcEvent		bit
declare @nDefaultNameNo		int		-- 13785
declare	@nNewCorrespondName	int		-- 14023
declare @nCaseNameRequestExists	int

declare @nBackgroundProcessId	int
declare @nErrorMessage		nvarchar(254)
declare @nSavedErrorCode	int
declare @sGlobalTempTableCentura nvarchar(254)

set @ErrorCode           =0
set @nRowCount		 =0
set @pnNamesUpdatedCount =0
set @pnNamesInsertedCount=0
set @pnNamesDeletedCount =0
set @bDeriveCorrName     =0
set @nBackgroundProcessId =0

---------------------------------------------------
-- Change @psGlobalTempTable argument to local temp 
-- table for avoiding the error in WorkBenches.
-- This only needs to be done when the procedure is
-- called externally (not recursively).
---------------------------------------------------
If  @psProgramId is not Null
and @pbCalledFromCentura in (0,1)
and @ErrorCode=0
Begin
	
	 CREATE TABLE dbo.#TEMPSELECTEDCASES (
		CASEID               int 	  NOT NULL
	 )

	if @pbCalledFromCentura = 1
	Begin
	----------------------------------------
		-- SQA21826
		-- Insert CaseIds from global temp table 
		-- into the temp table
		----------------------------------------
		Set @sSQLString = "INSERT INTO dbo.#TEMPSELECTEDCASES (CASEID)
				  Select distinct CASEID
				  from "+@psGlobalTempTable 			  	

		Exec @ErrorCode = sp_executesql @sSQLString
	End
	Else Begin
		-------------------------------------------
		-- Insert CaseIds from CASENAMEREQUESTCASES 
		-- into the temp table
		-------------------------------------------
		Set @sSQLString = "INSERT INTO dbo.#TEMPSELECTEDCASES (CASEID)
				  Select CASEID
				  From CASENAMEREQUESTCASES
				  where REQUESTNO = " + convert(nvarchar(10), @pnRequestNo) 			  	

		Exec @ErrorCode = sp_executesql @sSQLString
	End

	If @ErrorCode = 0
	Begin
		Set @sGlobalTempTableCentura = @psGlobalTempTable
		Set @psGlobalTempTable = '#TEMPSELECTEDCASES'
	End
END

----------------------------------------------
-- If the procedure has been called externally
-- (not recursively) then check to see if there
-- are any outstanding global name change
-- requests that modify any of the same Cases
-- and were raised before the current request
-- in the past 5 minutes
----------------------------------------------
If(@pnRequestNo is not null
or @psProgramId is not null)
and @ErrorCode=0
Begin	
	---------------------------------------
	-- Format the delay length used to wait
	-- between checking if the same Cases 
	-- are still being processed. 
	---------------------------------------
	Set @sDelayLength='0:0:10'
	
	If @pnRequestNo is not null
	Begin
		set @nBackgroundProcessId = @pnRequestNo
		
		While exists(	select 1
				from CASENAMEREQUESTCASES C1
				join CASENAMEREQUESTCASES C2	on (C2.CASEID=C1.CASEID
								and C2.REQUESTNO<C1.REQUESTNO)
				where C1.REQUESTNO=@pnRequestNo
				and C2.LOGDATETIMESTAMP>dateadd(mi,-5,getdate()))	-- Check for requests in the last 5 minutes
		Begin
			WAITFOR DELAY @sDelayLength
		End				
	End
	Else If @psProgramId is not null
	Begin
		Set @bWaitLoop=1
		
		While(@bWaitLoop=1
		and   @ErrorCode=0)
		Begin
			Set @bWaitLoop=0
			----------------------------------
			-- Compare the Cases passed in the 
			-- temporary table to see if any 
			-- of these are currently being
			-- processed.
			----------------------------------
			Set @sSQLString="
			Select @bWaitLoop=1
			from "+@psGlobalTempTable+" C1
			join CASENAMEREQUESTCASES C2 on (C2.CASEID=C1.CASEID)
			where C2.LOGDATETIMESTAMP>dateadd(mi,-5,getdate())"	-- Check for requests in the last 5 minutes

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@bWaitLoop		bit	OUTPUT',
						  @bWaitLoop   =@bWaitLoop	OUTPUT
			If  @bWaitLoop=1
			and @ErrorCode=0
				WAITFOR DELAY @sDelayLength
		End	
	End
End

----------------------------------------------
-- If the procedure has been called externally
-- (not recursively) then check to see if the
-- parameters for execution have been provided
-- in a table
----------------------------------------------

If(@pnRequestNo is not null
or @psProgramId is not null)
and @ErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	If @pnRequestNo is not null
	Begin
		Set @sSQLString="
		Update	CASENAMEREQUEST
		Set	@psProgramId			=PROGRAMID,
			@psNameType			=NAMETYPE,
			@pnExistingNameNo		=CURRENTNAMENO,
			@pnExistingCorrespondName	=CURRENTATTENTION,
			@pnExistingAddressKey		=CURRENTADDRESSCODE,
			@pnNewNameNo			=NEWNAMENO,
			@pnNewCorrespondName		=NEWATTENTION,
			@pbUpdateName			=UPDATEFLAG,
			@pbInsertName			=INSERTFLAG,
			@pbDeleteName			=DELETEFLAG,
			@pbKeepCorrespondName		=KEEPATTENTIONFLAG,
			@pnKeepReferenceNo		=KEEPREFERENCEFLAG,
			@pbApplyInheritance		=INHERITANCEFLAG,
			@psReferenceNo			=NEWREFERENCE,
			@pdtCommenceDate		=COMMENCEDATE,
			@pnAddressCode			=ADDRESSCODE,
			@pnBatchNo			=EDEBATCHNO,
			@pnTransNo			=LOGTRANSACTIONNO,
			@pbAlerts			=MOVEALERTSFLAG,
			@pbResetAddress			=RESETADDRESSFLAG,
			@pbResetAttention		=RESETATTENTIONFLAG,
			@pbFromDefaultAttention		=FROMDEFAULTATTENTIONFLAG,
			@pbFromDefaultAddress		=FROMDEFAULTADDRESSFLAG,
			ONHOLDFLAG			=1,
			IDENTITYID			=@pnUserIdentityId
		Where 	REQUESTNO=@pnRequestNo"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psProgramId			nvarchar(20)	OUTPUT,
					  @psNameType			nvarchar(3)	OUTPUT,
					  @pnExistingNameNo		int		OUTPUT,
					  @pnExistingCorrespondName	int		OUTPUT,
					  @pnExistingAddressKey		int		OUTPUT,
					  @pnNewNameNo			int		OUTPUT,
					  @pnNewCorrespondName		int		OUTPUT,
					  @pbNewInheritedFlag		bit		OUTPUT,
					  @pbUpdateName			bit		OUTPUT,
					  @pbInsertName			bit		OUTPUT,
					  @pbDeleteName			bit		OUTPUT,
					  @pbKeepCorrespondName		bit		OUTPUT,
					  @pnKeepReferenceNo		smallint	OUTPUT,
					  @pbApplyInheritance		bit		OUTPUT,
					  @psReferenceNo		nvarchar(80)	OUTPUT,
					  @pdtCommenceDate		datetime	OUTPUT,
					  @pnAddressCode		int		OUTPUT,
					  @pnBatchNo			int		OUTPUT,
					  @pnTransNo			int		OUTPUT,
					  @pbAlerts			bit		OUTPUT,
					  @pbResetAddress		bit		OUTPUT,
					  @pbResetAttention		bit		OUTPUT,
					  @pbFromDefaultAttention	bit		OUTPUT,
					  @pbFromDefaultAddress		bit		OUTPUT,
					  @pnRequestNo			int,
					  @pnUserIdentityId             int',
					  @psProgramId			=@psProgramId		OUTPUT,
					  @psNameType			=@psNameType		OUTPUT,
					  @pnExistingNameNo		=@pnExistingNameNo	OUTPUT,
					  @pnExistingCorrespondName	=@pnExistingCorrespondName OUTPUT,
					  @pnExistingAddressKey		=@pnExistingAddressKey	OUTPUT,
					  @pnNewNameNo			=@pnNewNameNo		OUTPUT,
					  @pnNewCorrespondName		=@pnNewCorrespondName	OUTPUT,
					  @pbNewInheritedFlag		=@pbNewInheritedFlag	OUTPUT,
					  @pbUpdateName			=@pbUpdateName		OUTPUT,
					  @pbInsertName			=@pbInsertName		OUTPUT,
					  @pbDeleteName			=@pbDeleteName		OUTPUT,
					  @pbKeepCorrespondName		=@pbKeepCorrespondName	OUTPUT,
					  @pnKeepReferenceNo		=@pnKeepReferenceNo	OUTPUT,
					  @pbApplyInheritance		=@pbApplyInheritance	OUTPUT,
					  @psReferenceNo		=@psReferenceNo		OUTPUT,
					  @pdtCommenceDate		=@pdtCommenceDate	OUTPUT,
					  @pnAddressCode		=@pnAddressCode		OUTPUT,
					  @pnBatchNo			=@pnBatchNo		OUTPUT,
					  @pnTransNo			=@pnTransNo		OUTPUT,
					  @pbAlerts			=@pbAlerts		OUTPUT,
					  @pbResetAddress		=@pbResetAddress	OUTPUT,
					  @pbResetAttention		=@pbResetAttention	OUTPUT,
					  @pbFromDefaultAttention	=@pbFromDefaultAttention OUTPUT,
					  @pbFromDefaultAddress		=@pbFromDefaultAddress	OUTPUT,
					  @pnRequestNo			=@pnRequestNo,
					  @pnUserIdentityId             =@pnUserIdentityId

		Set @nCaseNameRequestExists=@@rowcount
		
		If  @ErrorCode=0
		and @nCaseNameRequestExists=0
		Begin
			RAISERROR('CaseNameRequest row for @pnRequestNo not found', 14, 1)
			Set @ErrorCode = @@ERROR
		End
		
		----------------------------------------------
		-- SQA29012
		-- Clear out the TransNo if a BatchNo has been
		-- provided so that a new TransNo is generated
		-- that is linked to the BatchNo.
		----------------------------------------------
		If @pnBatchNo is not null
			set @pnTransNo=NULL
			
		----------------------------------
		-- Load the Cases for the specific 
		-- request into a temporary table 
		-- for the global name change.
		----------------------------------
		If @ErrorCode=0
		Begin
			Create Table dbo.#TEMPCASESFORNAMECHANGE(CASEID		int	NOT NULL)

			Set @psGlobalTempTable='#TEMPCASESFORNAMECHANGE'

			Set @sSQLString="
			insert into #TEMPCASESFORNAMECHANGE(CASEID)
			select CASEID
			from CASENAMEREQUESTCASES
			where REQUESTNO=@pnRequestNo"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnRequestNo	int',
						  @pnRequestNo=@pnRequestNo
		End
	End
	Else If @psProgramId is not NULL 
	Begin
		
		----------------------------------------------------------
		-- If the procedure has been called with the parameters 
		-- provided then load the parameters into the database
		-- so we can ensure the request is processed successfully.
		----------------------------------------------------------
		Set @sSQLString="
		insert into CASENAMEREQUEST(PROGRAMID,NAMETYPE,CURRENTNAMENO,CURRENTATTENTION,NEWNAMENO,NEWATTENTION,
					    UPDATEFLAG,INSERTFLAG,DELETEFLAG,KEEPATTENTIONFLAG,KEEPREFERENCEFLAG,
						    INHERITANCEFLAG,NEWREFERENCE,COMMENCEDATE,CURRENTADDRESSCODE,ADDRESSCODE,RESETADDRESSFLAG,RESETATTENTIONFLAG,
						    ONHOLDFLAG,IDENTITYID,MOVEALERTSFLAG,
						    FROMDEFAULTATTENTIONFLAG,FROMDEFAULTADDRESSFLAG)
		values(	@psProgramId,@psNameType,@pnExistingNameNo,@pnExistingCorrespondName,@pnNewNameNo,@pnNewCorrespondName,
			@pbUpdateName,@pbInsertName,@pbDeleteName,@pbKeepCorrespondName,@pnKeepReferenceNo,
				@pbApplyInheritance,@psReferenceNo,@pdtCommenceDate,@pnExistingAddressKey,@pnAddressCode,@pbResetAddress,@pbResetAttention,
				1,@pnUserIdentityId,@pbAlerts,
				@pbFromDefaultAttention,@pbFromDefaultAddress)

		set @pnRequestNo=SCOPE_IDENTITY()"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@psProgramId			nvarchar(20),
					  @psNameType			nvarchar(3),
					  @pnExistingNameNo		int,
					  @pnExistingCorrespondName	int,
					  @pnExistingAddressKey		int,
					  @pnNewNameNo			int,
					  @pnNewCorrespondName		int,
					  @pbNewInheritedFlag		bit,
					  @pbUpdateName			bit,
					  @pbInsertName			bit,
					  @pbDeleteName			bit,
					  @pbKeepCorrespondName		bit,
					  @pnKeepReferenceNo		smallint,
					  @pbApplyInheritance		bit,
					  @psReferenceNo		nvarchar(80),
					  @pdtCommenceDate		datetime,
					  @pnAddressCode		int,
					  @pbResetAddress		bit,
					  @pbResetAttention		bit,
					  @pnRequestNo			int	OUTPUT,
					  @pnUserIdentityId		int,
					  @pbAlerts			bit,
					  @pbFromDefaultAttention	bit,
					  @pbFromDefaultAddress		bit',
					  @psProgramId			=@psProgramId,
					  @psNameType			=@psNameType,
					  @pnExistingNameNo		=@pnExistingNameNo,
					  @pnExistingCorrespondName	=@pnExistingCorrespondName,
					  @pnExistingAddressKey		=@pnExistingAddressKey,
					  @pnNewNameNo			=@pnNewNameNo,
					  @pnNewCorrespondName		=@pnNewCorrespondName,
					  @pbNewInheritedFlag		=@pbNewInheritedFlag,
					  @pbUpdateName			=@pbUpdateName,
					  @pbInsertName			=@pbInsertName,
					  @pbDeleteName			=@pbDeleteName,
					  @pbKeepCorrespondName		=@pbKeepCorrespondName,
					  @pnKeepReferenceNo		=@pnKeepReferenceNo,
					  @pbApplyInheritance		=@pbApplyInheritance,
					  @psReferenceNo		=@psReferenceNo,
					  @pdtCommenceDate		=@pdtCommenceDate,
					  @pnAddressCode		=@pnAddressCode,
					  @pbResetAddress		=@pbResetAddress,
					  @pbResetAttention		=@pbResetAttention,
					  @pnRequestNo			=@pnRequestNo	OUTPUT,
					  @pnUserIdentityId		=@pnUserIdentityId,
					  @pbAlerts			=@pbAlerts,
					  @pbFromDefaultAttention	=@pbFromDefaultAttention,
					  @pbFromDefaultAddress		=@pbFromDefaultAddress					  

		------------------------------
		-- Load the Cases supplied in
		-- the temporary table for the
		-- request.
		------------------------------
		If  @ErrorCode=0
		and @pnRequestNo is not null
		Begin
			Set @sSQLString="
			Insert into CASENAMEREQUESTCASES(REQUESTNO,CASEID)
			select distinct @pnRequestNo,CASEID
			from "+@psGlobalTempTable

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnRequestNo	int',
						  @pnRequestNo=@pnRequestNo
		End
	End

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-----------------------------------------
-- SQA16267
-- Default the @pbUpdateName flag on
-- if a @pnNewCorrespondName or 
-- @pnExistingCorrespondName has been 
-- supplied but all flags are turned off.
-----------------------------------------
If (@pnNewCorrespondName is not null OR @pnExistingCorrespondName is not null OR @pbResetAttention = 1 OR @pnAddressCode is not null OR @pbResetAddress = 1)
and isnull(@pbUpdateName,0)=0
and isnull(@pbInsertName,0)=0
and isnull(@pbDeleteName,0)=0
Begin
	Set @pbUpdateName=1
End

-------------------------------------------------------------------
-- If the stored procedure has been called with the @psProgramId
-- it indicates that the procedure has not been called recursively.
-------------------------------------------------------------------
If @psProgramId is not Null
and @ErrorCode=0
Begin
	-- If the Existing NameNo and the New NameNo
	-- are not the same then flag that Case Instructions
	-- need to be found so we can check if any changes
	-- have occurred after the global name change.
	If isnull(@pnExistingNameNo,'')<>isnull(@pnNewNameNo,'')
		Set @bGetCaseInstructions=1
	Else
		Set @bGetCaseInstructions=0

	-- The following tables are only created in the first level of the the
	-- Global Name Change procedure and are then able to be utilised in 
	-- subsequent recursive calls of the procedure.

	Create table dbo.#TEMPCASECRITERIA (
					CASEID			int		not null,
					CRITERIANO		int		null)

	Create table dbo.#TEMPCASENAMETYPES (
					CASEID			int		not null,
					NAMETYPE		nvarchar(3)	collate database_default not null,
					MANDATORYFLAG		bit		null,
					KEEPSTREETFLAG		bit		null,
					MAXIMUMALLOWED		int		null,
					CHANGEEVENTNO		int		null,
					UPDATEFROMPARENT	bit		null,
					COLUMNFLAGS		smallint	null,
					FUTURENAMETYPEOF	nvarchar(3)	collate database_default null,
					REFERENCENO		nvarchar(80)	collate database_default null)
					
	-- Table required for getting the Case standing instructions.
	CREATE TABLE #TEMPCASEINSTRUCTIONS (
					CASEID			int		NOT NULL, 
					INSTRUCTIONTYPE		nchar(1)	collate database_default NOT NULL,
					COMPOSITECODE		nchar(33) 	collate database_default NULL,
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
					ADJUSTTODATE		datetime	NULL)
					
	-- This table will hold the Case standing instructions as they were
	-- prior to any name changes against the Cases.
	Create table #TEMPOLDINSTRUCTIONS (
					CASEID			int		NOT NULL, 
					INSTRUCTIONTYPE		nchar(1)	collate database_default NOT NULL,
					COMPOSITECODE		nchar(33) 	collate database_default NULL,
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
					ADJUSTTODATE		datetime	NULL)
					
	-- Keep track of all the name change details that occur through the 
	-- entire set of recursively called global name changes.
	-- These will be used on completion to determine if an Standing 
	-- Instructions have been changed requiring Policing to recalculate events.
	CREATE TABLE dbo.#TEMPGLOBALCASENAMES (
					CASEID			int		NOT NULL,
					NAMETYPE		nvarchar(3)	collate database_default NOT NULL,
					NAMENO			int		NOT NULL)

	CREATE TABLE dbo.#TEMPGLOBALUPDATESANDDELETES (
					CASEID			int		NOT NULL,
					NAMETYPE		nvarchar(3)	collate database_default NOT NULL)

	CREATE TABLE dbo.#TEMPPOLICING (POLICINGSEQNO		int		identity,
					EVENTNO			int		NOT NULL,
					CASEID			int		NOT NULL,
					CRITERIANO		int		NULL,
					CYCLE			smallint 	NOT NULL,
					TYPEOFREQUEST		smallint	NOT NULL,
					EVENTDATE		datetime	NULL,
					INSTRUCTIONTYPE		nvarchar(2)	collate database_default NULL,
					FLAGNUMBER		smallint	NULL,
					CASEEVENTEXISTS		bit		default(0),
					CHECKDOCUMENTCASE	bit		default(0))
	
	
	-- Create tables required for getting Case standing instruction.  This allows
	-- us to utilise the Policing stored procedure that performs this same function.
	CREATE TABLE #TEMPCASES (	CASESEQUENCENO		int		identity(1,1),
					CASEID			int		NOT NULL,
					PROPERTYTYPE		nvarchar(2)	collate database_default NOT NULL,
					COUNTRYCODE		nvarchar(3)	collate database_default not NULL,
					INSTRUCTIONSLOADED	bit		default(0))
	If @bGetCaseInstructions=1
	Begin				
		Set @sSQLString="
		Insert into #TEMPCASES(CASEID,PROPERTYTYPE,COUNTRYCODE)
		select C.CASEID,C.PROPERTYTYPE,C.COUNTRYCODE
		from "+@psGlobalTempTable+" T
		join CASES C on (C.CASEID=T.CASEID)"
		
		exec @ErrorCode=sp_executesql @sSQLString

		-- Create the index after the table is loaded as this gives
		-- improved performance.
		CREATE UNIQUE CLUSTERED INDEX XPK1TEMPCASES ON #TEMPCASES
		(
			CASESEQUENCENO,
			CASEID,
			PROPERTYTYPE,
			COUNTRYCODE,
			INSTRUCTIONSLOADED
		)
		
		If @ErrorCode=0
		Begin
			-- This table is also required to exist so that we can use 
			-- the stored procedure ip_PoliceGetStandingInstructions
			CREATE TABLE #TEMPOPENACTION (CASEID	int	NOT NULL)
					
			Set @sSQLString="
			Insert into #TEMPOPENACTION(CASEID)
			select distinct T.CASEID
			from #TEMPCASES T
			join OPENACTION OA on (OA.CASEID=T.CASEID)
			where OA.POLICEEVENTS=1"
		
			exec @ErrorCode=sp_executesql @sSQLString
			-- If no open rows in OPENACTION then there
			-- is no need to check the standing instructions
			set @bGetCaseInstructions=cast(@@Rowcount as bit)

			-- Create the index after the table is loaded as this gives
			-- improved performance.
			If  @bGetCaseInstructions=1
			and @ErrorCode=0
				CREATE UNIQUE CLUSTERED INDEX XPK1TEMPOPENACTION ON #TEMPOPENACTION(CASEID)
		End
	End
	----------------------------------------------------------------------
	-- We need to determine what NAMETYPES are valid for each Case.
	-- We first must determine the Screen Control CriteriaNo for each case
	-- Get the best ScreenControl Criteria for each case.
	-- Create a temporary table only when the @psProgramId is known
	-- as we do not want to create the temporary table again when the 
	-- stored procedure is called recursively.
	----------------------------------------------------------------------
	
	If isnull(@pbCalledFromCentura,0)=0
	and @ErrorCode=0
	Begin
		------------------------------------------
		-- Get the ProfileKey for the current user
		------------------------------------------
		Select @nProfileKey = PROFILEID
		from USERIDENTITY
		where IDENTITYID = @pnUserIdentityId
	        
		Set @ErrorCode = @@ERROR
				
		------------------------------------------
		-- Get the default Case program for the 
		-- current user
		------------------------------------------
		If @ErrorCode = 0 
		and @nProfileKey is not null
		Begin
			Select @psProgramId = P.ATTRIBUTEVALUE
			from PROFILEATTRIBUTES P
			where P.PROFILEID = @nProfileKey
			and P.ATTRIBUTEID = 2 -- Default Case Program
			Set @ErrorCode = @@ERROR
		End
		
		If @ErrorCode = 0 
		and (@psProgramId is null or @psProgramId = '')
		Begin 
			Select @psProgramId = SC.COLCHARACTER
			from SITECONTROL SC
			where SC.CONTROLID = 'Case Screen Default Program'
			
			Set @ErrorCode = @@ERROR
		End
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString="Insert into #TEMPCASECRITERIA(CASEID,CRITERIANO)"+char(10)+
				"Select distinct C.CASEID,"+char(10)+
				"	(SELECT "+char(10)+
				"	convert(int,"+char(10)+
				"	substring("+char(10)+
				"	max ("+char(10)+
				"	CASE WHEN (CR.PROFILEID IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (CR.CASEOFFICEID IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (CR.CASETYPE IS NULL)		THEN '0'"+char(10)+
				"		ELSE CASE WHEN(CR.CASETYPE=CT.CASETYPE)	 THEN '2' ELSE '1' END"+char(10)+
				"	END +"+char(10)+  
				"	CASE WHEN (CR.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (CR.COUNTRYCODE IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (CR.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (CR.SUBTYPE IS NULL)		THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (CR.BASIS IS NULL)		THEN '0' ELSE '1' END +"+char(10)+
				"	CASE WHEN (isnull(CR.USERDEFINEDRULE,0)=0)"+char(10)+
				"						THEN '0' ELSE '1' END +"+char(10)+
				"	convert(varchar,CR.CRITERIANO)), 10,11))"+char(10)+
				"	FROM CRITERIA CR "+char(10)+
				"	join CASETYPE CT on (CT.CASETYPE=C.CASETYPE)"+char(10)+
				"	WHERE	CR.RULEINUSE		= 1"+char(10)+
				"	AND 	CR.PURPOSECODE		= CASE WHEN(@pbCalledFromCentura=1) THEN 'S' ELSE 'W' END"+char(10)+  
				"	AND	CR.PROGRAMID		= @psProgramId"+char(10)+
				"	AND	CR.PROPERTYUNKNOWN	= 0"+char(10)+
				"	AND	CR.COUNTRYUNKNOWN	= 0"+char(10)+
				"	AND	CR.CATEGORYUNKNOWN	= 0"+char(10)+
				"	AND	CR.SUBTYPEUNKNOWN	= 0"+char(10)+
				"	AND (	CR.CASETYPE	        = isnull(CT.ACTUALCASETYPE,CT.CASETYPE) OR CR.CASETYPE  IS NULL )"+char(10)+
				"	AND (   CR.PROFILEID            = @nProfileKey          OR CR.PROFILEID         IS NULL )"+char(10)+
				"	AND (	CR.CASEOFFICEID 	= C.OFFICEID	 	OR CR.CASEOFFICEID 	IS NULL )"+char(10)+
				"	AND (	CR.PROPERTYTYPE 	= C.PROPERTYTYPE 	OR CR.PROPERTYTYPE 	IS NULL )"+char(10)+
				"	AND (	CR.COUNTRYCODE 		= C.COUNTRYCODE 	OR CR.COUNTRYCODE 	IS NULL )"+char(10)+
				"	AND (	CR.CASECATEGORY 	= C.CASECATEGORY 	OR CR.CASECATEGORY 	IS NULL )"+char(10)+
				"	AND (	CR.SUBTYPE 		= C.SUBTYPE 		OR CR.SUBTYPE 		IS NULL )"+char(10)+
				"	AND (	CR.BASIS 		= P.BASIS 		OR CR.BASIS 		IS NULL ) )"+char(10)+
				"from "+@psGlobalTempTable+" T"+char(10)+
				"join CASES C         on (C.CASEID=T.CASEID)"+char(10)+
				"left join PROPERTY P on (P.CASEID=C.CASEID)"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@psProgramId		nvarchar(20),
						  @nProfileKey		int,
						  @pbCalledFromCentura	bit',
						  @psProgramId		=@psProgramId,
						  @nProfileKey		=@nProfileKey,
						  @pbCalledFromCentura	=@pbCalledFromCentura
	End

	If @ErrorCode=0
	Begin
		-- Remove any TEMPCASECRITERIA rows where the CriteriaNo is null

		set @sSQLString=
		"delete from #TEMPCASECRITERIA where CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End
	
	If @ErrorCode=0
	Begin
	
		-- Create the index after the table is loaded as this gives
		-- improved performance.
		CREATE UNIQUE CLUSTERED INDEX XPK1TEMPCASECRITERIA ON #TEMPCASECRITERIA
		(
			CASEID,
			CRITERIANO
		)
	End

	-----------------------------------------
	-- Find the NameTypes valid for each Case
	-----------------------------------------
	If @ErrorCode=0
	and @pbCalledFromCentura=1
	Begin
		----------------------------------------------------------------------------------------
		-- Load a unique set of NameTypes that are valid to be used with the Case. These are
		-- determined from the NameTypes that are assocated either directly or indirectly to the 
		-- ScreenControl definition.
		----------------------------------------------------------------------------------------
		set @sSQLString=
		"insert into #TEMPCASENAMETYPES(CASEID, NAMETYPE, MANDATORYFLAG, KEEPSTREETFLAG, MAXIMUMALLOWED, CHANGEEVENTNO, UPDATEFROMPARENT,COLUMNFLAGS, FUTURENAMETYPEOF, REFERENCENO)
		 select distinct T.CASEID, NT.NAMETYPE, NT.MANDATORYFLAG, NT.KEEPSTREETFLAG, NT.MAXIMUMALLOWED, NT.CHANGEEVENTNO, NT.UPDATEFROMPARENT, NT.COLUMNFLAGS, NT1.FUTURENAMETYPEOF, CN.REFERENCENO
		 from #TEMPCASECRITERIA T
		 join SCREENCONTROL SC    on (SC.CRITERIANO=T.CRITERIANO)
		 left join GROUPMEMBERS G on (G.NAMEGROUP=SC.NAMEGROUP)
		 join NAMETYPE NT         on (NT.NAMETYPE=isnull(G.NAMETYPE, SC.NAMETYPE))
		 left join (SELECT FUTURENAMETYPE, MIN(NAMETYPE) as FUTURENAMETYPEOF
			    from NAMETYPE
			    where MAXIMUMALLOWED=1
			    and @pnKeepReferenceNo=1
			    group by FUTURENAMETYPE
			    having COUNT(*)=1) NT1 on (NT1.FUTURENAMETYPE=NT.NAMETYPE)
		 left join CASENAME CN on (CN.CASEID=T.CASEID
		                       and CN.NAMETYPE=NT1.FUTURENAMETYPEOF)
		 where SC.SCREENNAME in ('frmNameGrp','frmNames')"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnKeepReferenceNo	smallint',
						  @pnKeepReferenceNo=@pnKeepReferenceNo
	End
	Else If @ErrorCode=0
	Begin
		----------------------------------------------------------------------------------------
		-- Load a unique set of NameTypes that are valid to be used with the Case. These are
		-- determined from the NameTypes associated with the web screen criteria.
		----------------------------------------------------------------------------------------
		set @sSQLString=
		"insert into #TEMPCASENAMETYPES(CASEID, NAMETYPE, MANDATORYFLAG, KEEPSTREETFLAG, MAXIMUMALLOWED, CHANGEEVENTNO, UPDATEFROMPARENT,COLUMNFLAGS)
		select distinct T.CASEID, NT.NAMETYPE, NT.MANDATORYFLAG, NT.KEEPSTREETFLAG, NT.MAXIMUMALLOWED, NT.CHANGEEVENTNO, NT.UPDATEFROMPARENT, NT.COLUMNFLAGS
		from #TEMPCASECRITERIA T
		join NAMETYPE NT on (NT.COLUMNFLAGS is not null)
			--------------------------------------------------------
			-- NOTE The following logic has been taken from the user
			--      defined function fnw_ScreenCriteriaNameTypes
			--------------------------------------------------------
		WHERE NT.NAMETYPE NOT IN (
			-- Return all NAMETYPEs for Single Name and Multiples Name topics
			SELECT TC.FILTERVALUE FROM TOPICCONTROL TC
				JOIN WINDOWCONTROL WC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO AND WC.CRITERIANO=T.CRITERIANO AND WC.WINDOWNAME='CaseNameMaintenance')
				WHERE TC.FILTERNAME='NameTypeCode'
				  AND TC.FILTERVALUE IS NOT NULL
				  AND TC.ISHIDDEN=1 
			UNION
			-- Return all NAMETYPEs for Staff Topic
			SELECT EC.FILTERVALUE FROM ELEMENTCONTROL EC
				JOIN TOPICCONTROL TC on (EC.TOPICCONTROLNO = TC.TOPICCONTROLNO) 
				JOIN WINDOWCONTROL WC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO AND WC.CRITERIANO=T.CRITERIANO AND WC.WINDOWNAME='CaseNameMaintenance')
				WHERE EC.FILTERNAME='NameTypeCode'
				  AND EC.FILTERVALUE IS NOT NULL
				  AND EC.ISHIDDEN=1 
			UNION
			-- Return all NAMETYPEs if the Staff Topic is hidden
			SELECT N.NAMETYPE 
				FROM NAMETYPE N
				JOIN WINDOWCONTROL WC on (WC.CRITERIANO=T.CRITERIANO AND WC.WINDOWNAME='CaseNameMaintenance')
				JOIN TOPICCONTROL TC on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO AND TC.TOPICNAME = 'Case_StaffTopic' AND TC.ISHIDDEN=1)
				WHERE Cast(N.COLUMNFLAGS & 4 as bit)    = 0
				  AND Cast(N.COLUMNFLAGS & 1 as bit)    = 0
				  AND Cast(N.COLUMNFLAGS & 2 as bit)    = 0
				  AND Cast(N.COLUMNFLAGS & 16 as bit)   = 0
				  AND Cast(N.COLUMNFLAGS & 32 as bit)   = 0
				  AND Cast(N.COLUMNFLAGS & 8 as bit)    = 0
				  AND Cast(N.COLUMNFLAGS & 128 as bit)  = 0
				  AND Cast(N.COLUMNFLAGS & 64 as bit)   = 0
				  AND Cast(N.COLUMNFLAGS & 512 as bit)  = 0
				  AND Cast(N.COLUMNFLAGS & 1024 as bit) = 0
				  AND Cast(N.COLUMNFLAGS & 2048 as bit) = 0
				  AND Cast(N.PICKLISTFLAGS & 2 as bit)  = 1
			)"
	
		Exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		-- Create the index after the table is loaded as this gives
		-- improved performance.
		CREATE UNIQUE CLUSTERED INDEX XPK1TEMPCASENAMETYPE ON #TEMPCASENAMETYPES
		(
			CASEID,
			NAMETYPE
		)
	End

	If @ErrorCode=0
	Begin
		---------------------------------------------------------------
		-- The NameTypes of EMP, SIG, I and A which appear directly on
		-- the frmInstructor window may not have already been specified 
		-- for the Case so we need to check directly against the Field
		-- Control rules to ensure they are not suppressed.
		---------------------------------------------------------------
		set @sSQLString=
		"insert into #TEMPCASENAMETYPES(CASEID, NAMETYPE, MANDATORYFLAG, KEEPSTREETFLAG, MAXIMUMALLOWED, CHANGEEVENTNO, UPDATEFROMPARENT,COLUMNFLAGS)"+char(10)+
		"select T.CASEID, 'EMP', CASE WHEN(F.ATTRIBUTES=2) THEN 1 ELSE 0 END, 0, NT.MAXIMUMALLOWED,NT.CHANGEEVENTNO, NT.UPDATEFROMPARENT, NT.COLUMNFLAGS"+char(10)+
		"from #TEMPCASECRITERIA T"+char(10)+
		"join NAMETYPE NT         on (NT.NAMETYPE='EMP')"+char(10)+
		"left join #TEMPCASENAMETYPES TC"+char(10)+
		"			  on (TC.CASEID=T.CASEID"+char(10)+
		"			  and TC.NAMETYPE=NT.NAMETYPE)"+char(10)+
		"left join FIELDCONTROL F on (F.CRITERIANO=T.CRITERIANO"+char(10)+
		"                         and F.SCREENNAME='frmInstructor'"+char(10)+
		"                         and F.FIELDNAME ='dfEmpCode')"+char(10)+
		"where (F.ATTRIBUTES<>32 OR F.ATTRIBUTES is null)"+char(10)+
		"and TC.CASEID is null"+char(10)+
		"UNION"+char(10)+
		"select T.CASEID, 'SIG', CASE WHEN(F.ATTRIBUTES=2) THEN 1 ELSE 0 END, 0, NT.MAXIMUMALLOWED, NT.CHANGEEVENTNO, NT.UPDATEFROMPARENT, NT.COLUMNFLAGS"+char(10)+
		"from #TEMPCASECRITERIA T"+char(10)+
		"join NAMETYPE NT         on (NT.NAMETYPE='SIG')"+char(10)+
		"left join #TEMPCASENAMETYPES TC"+char(10)+
		"			  on (TC.CASEID=T.CASEID"+char(10)+
		"			  and TC.NAMETYPE=NT.NAMETYPE)"+char(10)+
		"left join FIELDCONTROL F on (F.CRITERIANO=T.CRITERIANO"+char(10)+
		"                         and F.SCREENNAME='frmInstructor'"+char(10)+
		"                         and F.FIELDNAME ='dfSignatoryCode')"+char(10)+
		"where (F.ATTRIBUTES<>32 OR F.ATTRIBUTES is null)"+char(10)+
		"and TC.CASEID is null"+char(10)+
		"UNION"+char(10)+
		"select T.CASEID, 'I', CASE WHEN(F.ATTRIBUTES=2) THEN 1 ELSE 0 END, 0, NT.MAXIMUMALLOWED, NT.CHANGEEVENTNO, NT.UPDATEFROMPARENT, NT.COLUMNFLAGS"+char(10)+
		"from #TEMPCASECRITERIA T"+char(10)+
		"join NAMETYPE NT         on (NT.NAMETYPE='I')"+char(10)+
		"left join #TEMPCASENAMETYPES TC"+char(10)+
		"			  on (TC.CASEID=T.CASEID"+char(10)+
		"			  and TC.NAMETYPE=NT.NAMETYPE)"+char(10)+
		"left join FIELDCONTROL F on (F.CRITERIANO=T.CRITERIANO"+char(10)+
		"                         and F.SCREENNAME='frmInstructor'"+char(10)+
		"                         and F.FIELDNAME ='dfInstrCode')"+char(10)+
		"where (F.ATTRIBUTES<>32 OR F.ATTRIBUTES is null)"+char(10)+
		"and TC.CASEID is null"+char(10)+
		"UNION"+char(10)+
		"select T.CASEID, 'A', CASE WHEN(F.ATTRIBUTES=2) THEN 1 ELSE 0 END, 0, NT.MAXIMUMALLOWED, NT.CHANGEEVENTNO, NT.UPDATEFROMPARENT, NT.COLUMNFLAGS"+char(10)+
		"from #TEMPCASECRITERIA T"+char(10)+
		"join NAMETYPE NT         on (NT.NAMETYPE='A')"+char(10)+
		"left join #TEMPCASENAMETYPES TC"+char(10)+
		"			  on (TC.CASEID=T.CASEID"+char(10)+
		"			  and TC.NAMETYPE=NT.NAMETYPE)"+char(10)+
		"left join FIELDCONTROL F on (F.CRITERIANO=T.CRITERIANO"+char(10)+
		"                         and F.SCREENNAME='frmInstructor'"+char(10)+
		"                         and F.FIELDNAME ='dfAgentCode')"+char(10)+
		"where (F.ATTRIBUTES<>32 OR F.ATTRIBUTES is null)"+char(10)+
		"and TC.CASEID is null"+char(10)+
		-- SQA14032 Check to see if an Additional Internal Staff are allowed against the Case
		"UNION"+char(10)+
		"select T.CASEID, NT.NAMETYPE, CASE WHEN(F.ATTRIBUTES=2) THEN 1 ELSE 0 END, 0, NT.MAXIMUMALLOWED, NT.CHANGEEVENTNO, NT.UPDATEFROMPARENT, NT.COLUMNFLAGS"+char(10)+
		"from #TEMPCASECRITERIA T"+char(10)+
		"join SITECONTROL S	  on (S.CONTROLID='Additional Internal Staff')"+char(10)+
		"join NAMETYPE NT         on (NT.NAMETYPE=S.COLCHARACTER)"+char(10)+
		"left join #TEMPCASENAMETYPES TC"+char(10)+
		"			  on (TC.CASEID=T.CASEID"+char(10)+
		"			  and TC.NAMETYPE=NT.NAMETYPE)"+char(10)+
		"left join FIELDCONTROL F on (F.CRITERIANO=T.CRITERIANO"+char(10)+
		"                         and F.SCREENNAME='frmInstructor'"+char(10)+
		"                         and F.FIELDNAME ='dfAdditionalIntStaff')"+char(10)+
		"where (F.ATTRIBUTES<>32 OR F.ATTRIBUTES is null)"+char(10)+
		"and TC.CASEID is null"

		Exec @ErrorCode=sp_executesql @sSQLString
	End
	
	
	-- Load the current Case level Standing Instructions so these
	-- can be checked on completion of all of the global name changes.
	If  @ErrorCode=0
	and @bGetCaseInstructions=1
	Begin
		exec @ErrorCode=dbo.ip_PoliceGetStandingInstructions @pnDebugFlag=0
		
		If @ErrorCode=0
		Begin
			-- Load the Case level standing instructions into another
			-- table so we can compare against them at the end of processing
			Set @sSQLString="
			insert into #TEMPOLDINSTRUCTIONS 
			      (	CASEID,INSTRUCTIONTYPE,COMPOSITECODE,INSTRUCTIONCODE,
				PERIOD1TYPE,PERIOD1AMT,PERIOD2TYPE,PERIOD2AMT,PERIOD3TYPE,PERIOD3AMT,
				ADJUSTMENT,ADJUSTDAY,ADJUSTSTARTMONTH,ADJUSTDAYOFWEEK,ADJUSTTODATE)
			select	CASEID,INSTRUCTIONTYPE,COMPOSITECODE,INSTRUCTIONCODE,
				PERIOD1TYPE,PERIOD1AMT,PERIOD2TYPE,PERIOD2AMT,PERIOD3TYPE,PERIOD3AMT,
				ADJUSTMENT,ADJUSTDAY,ADJUSTSTARTMONTH,ADJUSTDAYOFWEEK,ADJUSTTODATE
			from #TEMPCASEINSTRUCTIONS"
			
			exec @ErrorCode=sp_executesql @sSQLString
		End
		
		If @ErrorCode=0
		Begin
			-- Now load the index
			CREATE CLUSTERED INDEX XPKTEMPOLDINSTRUCTIONS ON #TEMPOLDINSTRUCTIONS
 			(
        			CASEID,
				INSTRUCTIONTYPE
 			)
 		End
	End
	-- Get the HomeNameNo from the Site Control
	If @pnHomeNameNo is null
	and @ErrorCode=0
	Begin
		Set @sSQLString="
		Select @pnHomeNameNo=COLINTEGER
		from SITECONTROL
		where CONTROLID='HOMENAMENO'"

		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnHomeNameNo		int	OUTPUT',
						  @pnHomeNameNo=@pnHomeNameNo	OUTPUT
	End
End

-------------------------------------------------------------------------------------------
--
--	CONSTRUCT INSERT, UPDATE and DELETE
--
-------------------------------------------------------------------------------------------

-- Construct the SQL if an Update, Insert or Delete has been specified.
-- If none of these have been indicated then the routine is being used to remove
-- any CaseName rows that no longer have a parent
If   @ErrorCode=0
and(@pbUpdateName=1 or @pbDeleteName=1 or @pbInsertName=1)
Begin

	Set @sWhere = char(10)+"Where 1=1"

	-- The @psGlobalTempTable identifies the table with the Cases to have the global change applied
	Set @sFrom = char(10)+"from CASENAME CN"+char(10)+
		   "join "+@psGlobalTempTable+" T on (T.CASEID=CN.CASEID)"+char(10)+
		   "left join #TEMPCASENAMETYPES NT on (NT.CASEID=CN.CASEID"+char(10)+
		   "                                and NT.NAMETYPE=CN.NAMETYPE)"
	
	-- Limit to a specific NameType
	If @psNameType is not Null
	Begin
		Set @sWhere = @sWhere+char(10)+"and CN.NAMETYPE='"+@psNameType+"'"
	End
	-- SQA14707
	-- If not limited to a specific NameType then 
	-- only update CASENAME rows that have not expired
	Else Begin
		Set @sWhere = @sWhere+char(10)+"and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())"
	End
	
	-- Limit to a specific NameNo
	If @pnExistingNameNo is not Null
	Begin
		Set @sWhere = @sWhere+char(10)+"and CN.NAMENO="+convert(varchar,@pnExistingNameNo)
	End
	-- If not limited to a specific NameNo then only alter those names that are different to the New NameNo or
	-- where the NameNo is the same but the Correspond Name has a value that is to be cleared out.
	Else If  @pnNewNameNo          is not Null
	     and @pnExistingCorrespondName is Null
	     and @pnNewCorrespondName      is Null
	     and @pbKeepCorrespondName=0
	Begin
		-- 8911 Only include non-derived Correspond Name (originally CN.CORRESPONDNAME is not null).
		Set @sWhere = @sWhere+char(10)+"and (CN.NAMENO<>"+convert(varchar,@pnNewNameNo)+" OR (CN.NAMENO="+convert(varchar,@pnNewNameNo)+" and CN.DERIVEDCORRNAME=0))"
	End
	
	-- Limit to a specific Correspondence Name.
	If @pnExistingCorrespondName is not Null
	Begin
		-------------------------------------------------------------
		-- DR-46198
		-- If matching on a specific Correspondence Name, also match
		-- on the default contact for the Name.
		-------------------------------------------------------------
		Set @sFrom = @sFrom+char(10)+
			     "join NAME NX on (NX.NAMENO=CN.NAMENO)"

		Set @sWhere = @sWhere+char(10)+"and isnull(CN.CORRESPONDNAME, NX.MAINCONTACT)="+convert(varchar,@pnExistingCorrespondName)
	End
	-- If there is a new Correspondence Name then limit to those that are different to the new Correspondence Name
	Else If @pnNewCorrespondName is not Null
	Begin
		-- 8911 Change condition from 'CORRESPONDNAME is Null' to 'DERIVEDCORRNAME=1'.
		Set @sWhere = @sWhere+char(10)+"and (CN.CORRESPONDNAME<>"+convert(varchar,@pnNewCorrespondName)+" OR CN.CORRESPONDNAME is null OR CN.DERIVEDCORRNAME=1"
					+ CASE WHEN(@pnNewNameNo is not null) THEN " OR CN.NAMENO<>N.NAMENO)" ELSE ")" END
	End
	
	-- Where the existing attention is null or default
	If @pbFromDefaultAttention = 1
	Begin
		Set @sWhere = @sWhere + CHAR(10) + "and CN.CORRESPONDNAME is null or CN.CORRESPONDNAME = '' or CN.DERIVEDCORRNAME = 1"
	End
	
	If @pnExistingAddressKey is not null and @pnExistingNameNo is not null
	Begin
		-- Only change specific addresses
		Set @sWhere = @sWhere+char(10)+"and CN.ADDRESSCODE = " + convert(varchar,@pnExistingAddressKey)
	End
	
	if @pbFromDefaultAddress = 1
	Begin
		Set @sWhere = @sWhere + CHAR(10) + "and CN.ADDRESSCODE is null or CN.ADDRESSCODE = ''"
	End
	
	If @pnPathNameNo is not null
	Begin
		-- 12327 Inheritance is to be applied either for new NameType against the Case
		-- or where the NameType has explicitly been flagged as being allowed to be updated by inheritance
		Set @sWhere = @sWhere+char(10)+"and (NT.CASEID is null OR NT.UPDATEFROMPARENT=1)"

		-- SQA13785 Only update names that are currently inherited.
		-- RFC9642  Unless the @pbForceInherited flag is on (set to 1).
		If @pbForceInheritance=0
			Set @sWhere = @sWhere+char(10)+"and CN.INHERITED=1"
	End
		
	-- If the Path NameNo and Relationship have beeen supplied as parameters then constuct the
	-- Update statement to take into account the best fit rules used where an inherited Name
	-- is being updated from an Associated Name derived from the NameType rule that indicated a 
	-- PathNameType and PathRelationship
	
	If @pnPathNameNo        is not Null
	and @psPathRelationship is not Null
	Begin
		Set @sFrom = @sFrom+char(10)+
			   "join CASES C on (C.CASEID=CN.CASEID)"+char(10)+
			   "join ASSOCIATEDNAME AN on (AN.NAMENO="+convert(varchar,@pnPathNameNo)+char(10)+
			   "                       and AN.RELATEDNAME="+convert(varchar,@pnNewNameNo)+char(10)+
			   "                       and AN.RELATIONSHIP='"+@psPathRelationship+"'"+char(10)+
			   "                       and(AN.PROPERTYTYPE=C.PROPERTYTYPE OR AN.PROPERTYTYPE is null)"+char(10)+
			   "                       and(AN.COUNTRYCODE =C.COUNTRYCODE  OR AN.COUNTRYCODE  is null))"+char(10)+
			   "left join ASSOCIATEDNAME AN2 on (AN2.NAMENO=AN.NAMENO"+char(10)+
		           "				 and AN2.RELATEDNAME=CN.NAMENO"+char(10)+
							 -- 8911 change 'CORRESPONDNAME is null' condition to 'DERIVEDCORRNAME=1'.
			   "				 and (AN2.CONTACT=CN.CORRESPONDNAME or (AN2.CONTACT is null and CN.DERIVEDCORRNAME=1))"+char(10)+
			   "                       	 and AN2.RELATIONSHIP=AN.RELATIONSHIP)"
	
		-- When an update has been generated as a result of a PathNameNo and PathRelationship 
		-- then the PropertytType and CountryCode of the Case must also be taken into consideration
		-- to ensure that the global Name change matches the Case it is being applied to.
		-- This match uses the standard "Best Fit" algorithm.
	
		Set @sWhere = @sWhere+char(10)+
				CASE WHEN(@pnNewCorrespondName is NULL)
					THEN "and AN.CONTACT is Null"
					ELSE "and AN.CONTACT="+convert(varchar,@pnNewCorrespondName)
				END +char(10)+
	
				-- this calculates the bestfit value of the current AssociatedName row
				-- and ensures it matches the best fit value for the specific case.
				"and (CASE WHEN(AN.PROPERTYTYPE is null) THEN '0' ELSE '1' END +"+char(10)+
				"     CASE WHEN(AN.COUNTRYCODE  is null) THEN '0' ELSE '1' END)"+char(10)+
				"      = (select max(CASE WHEN(AN1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +"+char(10)+
				"                    CASE WHEN(AN1.COUNTRYCODE  is null) THEN '0' ELSE '1' END )"+char(10)+
				"         from ASSOCIATEDNAME AN1"+char(10)+
				"         where AN1.NAMENO=AN.NAMENO"+char(10)+ 
				"         and  AN1.RELATIONSHIP=AN.RELATIONSHIP"+char(10)+
				"         and (AN1.CEASEDDATE is null OR AN1.CEASEDDATE>getdate())"+char(10)+
				"         and (AN1.PROPERTYTYPE=C.PROPERTYTYPE or AN1.PROPERTYTYPE is null)"+char(10)+
				"         and (AN1.COUNTRYCODE =C.COUNTRYCODE  or AN1.COUNTRYCODE  is null))"+char(10)+
	
				-- this code checks that the CASENAME row being updated is not a valid inherited
				-- Name.  It does this by seeing if an AssociatedName exists for the current
				-- NameNo and CorrespondName and if it does then it checks the bestfit value.  If
				-- no AssociatedName row exists or the best fit value is less than the best value
				-- then the update is allowed to proceed.
				-- Also allow the update to proceed if the NAMENO and CORRESPONDNAME being updated
				-- match the existing CaseName row.  This is so other columns on the CaseName can
				-- be corrected by the global name change.
	 
				"and (AN2.NAMENO is null"+char(10)+
				" OR (CN.NAMENO="+convert(varchar,@pnNewNameNo)+" and "+
				CASE WHEN(@pnNewCorrespondName is NULL)
					-- 8911 Change condition from 'CORRESPONDNAME is Null' to 'DERIVEDCORRNAME=1'.
					THEN "CN.DERIVEDCORRNAME=1)"
					ELSE "CN.CORRESPONDNAME="+convert(varchar,@pnNewCorrespondName)+")"
				END +char(10)+
				" OR (CASE WHEN(AN2.PROPERTYTYPE is null) THEN '0' ELSE '1' END +"+char(10)+
				"     CASE WHEN(AN2.COUNTRYCODE  is null) THEN '0' ELSE '1' END)"+char(10)+
				"     < (select max(CASE WHEN(AN3.PROPERTYTYPE is null) THEN '0' ELSE '1' END +"+char(10)+
				"                   CASE WHEN(AN3.COUNTRYCODE  is null) THEN '0' ELSE '1' END )"+char(10)+
				"        from ASSOCIATEDNAME AN3"+char(10)+
				"        where AN3.NAMENO=AN2.NAMENO"+char(10)+ 
				"        and  AN3.RELATIONSHIP=AN2.RELATIONSHIP"+char(10)+
				"        and (AN3.CEASEDDATE is null OR AN3.CEASEDDATE>getdate())"+char(10)+
				"        and (AN3.PROPERTYTYPE=C.PROPERTYTYPE or AN3.PROPERTYTYPE is null)"+char(10)+
				"        and (AN3.COUNTRYCODE =C.COUNTRYCODE  or AN3.COUNTRYCODE  is null)))"+char(10)+
	
				-- Ensure that the new values for the CaseName row don't already exist unless of
				-- course the NAMENO and CORRESPONDNAME in the update are identical to the existing
				-- CASENAME row.
				"and (not exists"+char(10)+
				"(select * from CASENAME CN1"+char(10)+
				" where CN1.CASEID=CN.CASEID"+char(10)+
				" and   CN1.NAMETYPE=CN.NAMETYPE"+char(10)+
				" and   CN1.NAMENO="+convert(varchar,@pnNewNameNo)+char(10)+
				CASE WHEN(@pnNewCorrespondName is NULL)
					-- 8911 Change condition from 'CORRESPONDNAME is Null' to 'DERIVEDCORRNAME=1'.
					THEN " and   CN1.DERIVEDCORRNAME=1) OR (CN.NAMENO="+convert(varchar,@pnNewNameNo)+" and CN.DERIVEDCORRNAME=1))"
					ELSE " and   CN1.CORRESPONDNAME="+convert(varchar,@pnNewCorrespondName)+") OR (CN.NAMENO="+convert(varchar,@pnNewNameNo)+" and CN.CORRESPONDNAME="+convert(varchar,@pnNewCorrespondName)+"))"
				END 
	End
	
	-- If a Path has been defined  then only update those Cases that have
	-- a NameNo of the required NameType
	
	If  @pnPathNameNo   is not Null
	and @psPathNameType is not Null
	and isnull(@pnHomeNameNo,'')<>isnull(@pnPathNameNo,'')
	Begin
		Set @sWhere = @sWhere+char(10)+
				"and exists"+char(10)+
				"(select *"+char(10)+
				" from CASENAME CN2"+char(10)+
				" where CN2.NAMENO="+convert(varchar,@pnPathNameNo)+char(10)+
				" and   CN2.NAMETYPE='"+@psPathNameType+"'"+char(10)+
				" and   CN2.CASEID=T.CASEID)"
	End
	
	If  @pnExistingNameNo is Null
	and @pnNewNameNo  is not Null
	and @psNameType   is not Null
	Begin
		-- If no Existing NameNo was specified then we need to delete the CASENAME rows that have more than
		-- 1 occurrence of the NameType.  This is to avoid the situation of multiple different names being changed 
		-- to 1 new name for the one Case. 
		-- This will automatically turn on the Insert flag so as to allow the new CaseName to be inserted
	
		If  @pbUpdateName=1
		Begin
			Set @sDeleteString=	"Delete CASENAME"+char(10)+@sFrom+char(10)+@sWhere+char(10)+
						"and exists"+char(10)+
						"(select 1"+char(10)+
						" from CASENAME CN2"+char(10)+
						" where CN2.CASEID  =CN.CASEID"+char(10)+
						" and   CN2.NAMETYPE=CN.NAMETYPE"+char(10)+
						" and  (CN2.SEQUENCE<CN.SEQUENCE"+char(10)+
						"   OR (CN2.SEQUENCE=CN.SEQUENCE AND CN2.NAMENO<CN.NAMENO)))"
	
		/***** SQA 13035 Commenting this code out as this is causing rows to be inserted incorrectly *********/
			-- Need to also turn the Insert flag on in this situation.
		--	Set @pbInsertName=1
		/***** SQA 13035 *************************************************************************************/
	
			-- Keep track of the Caseid and Nametype combinations that are deleted.
			
			Set @sDeletedCasesString="Insert into #TEMPUPDATESANDDELETES(CASEID, NAMETYPE)"+char(10)+
						"Select CN.CASEID, CN.NAMETYPE"+char(10)+
						@sFrom+char(10)+@sWhere+char(10)+
						"and exists"+char(10)+
						"(select 1"+char(10)+
						" from CASENAME CN2"+char(10)+
						" where CN2.CASEID  =CN.CASEID"+char(10)+
						" and   CN2.NAMETYPE=CN.NAMETYPE"+char(10)+
						" and  (CN2.SEQUENCE<CN.SEQUENCE"+char(10)+
						"   OR (CN2.SEQUENCE=CN.SEQUENCE AND CN2.NAMENO<CN.NAMENO)))"
		End
	End
	
	-- If no NewNameNo and no NewCorrespondName has been passed then CaseName rows are to be deleted as long 
	-- as either a NameType or an existing NameNo has been identified.

	If @pbDeleteName=1
	Begin
		-- Note this test is required to ensure that a mandatory Name Type is not
		-- completely removed from a Case.
		Set @sWhere = @sWhere+char(10)+
					"and (NT.MANDATORYFLAG=0"+char(10)+
					" or  NT.MANDATORYFLAG is null"+char(10)+
					" or  1<(select count(*)"+char(10)+
					"        from CASENAME CN1"+char(10)+
					"        where CN1.CASEID=CN.CASEID"+char(10)+
					"        and CN1.NAMETYPE=CN.NAMETYPE"+char(10)+
					"        and CN1.EXPIRYDATE is null))"

		Set @sDeleteString="Delete CASENAME"+char(10)+@sFrom+char(10)+@sWhere

		-- Keep track of the Caseid and Nametype combinations that are deleted.
		Set @sDeletedCasesString="Insert into #TEMPUPDATESANDDELETES(CASEID, NAMETYPE)"+char(10)+
					"Select CN.CASEID, CN.NAMETYPE"+char(10)+
					@sFrom+char(10)+@sWhere
	End
	
	If  @pbUpdateName=1
	and (@psNameType is not NULL OR @pnExistingNameNo is not NULL)
	and @pnNewNameNo is NULL
	and @pnExistingCorrespondName is not null
	and @pnNewCorrespondName is NULL 
	Begin
		-- Reset Attention to default (derived) if it's not already derived.
		-- 8911 Set derived flag on instead of setting correspond name to null.
		Set @sUpdateString="Update CASENAME"+char(10)+
				   "Set DERIVEDCORRNAME=1"
		Set @bDeriveCorrName=1

		-- If the user has not explicitly requested the Reference be retained then clear it out
	 	If @pnKeepReferenceNo=2 OR @pnKeepReferenceNo is Null
		Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					  "    REFERENCENO=NULL"
		End
		-- if a new Reference has been provided, update the record with the new reference number. 
		Else If @pnKeepReferenceNo=3
		Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					  "    REFERENCENO="+CASE WHEN(@psReferenceNo is null) THEN 'NULL' ELSE "'"+replace(@psReferenceNo,"'","''")+"'" END
		End

		Set @sWhere = @sWhere+char(10)+
			    -- 8911 Only include non-derived (user-set) correspond names (formerly CN.CORRESPONDNAME is not null).
			    "and CN.DERIVEDCORRNAME=0"
			
		Set @sUpdatedCasesString="Insert into #TEMPUPDATESANDDELETES(CASEID, NAMETYPE)"+char(10)+
					"Select CN.CASEID, CN.NAMETYPE"+char(10)+
					@sFrom+char(10)+@sWhere
	End
	
	-- If a NewNameNo has been passed then construct the UPDATE and also an Insert where
	-- no existing Name exists for the NameType	
	If @pnNewNameNo is not NULL
	Begin
		Set @sFrom = @sFrom+char(10)+
		   "join NAME N on (N.NAMENO="+convert(varchar, @pnNewNameNo)+")"
	
		Set @sUpdateString="Update CASENAME"+char(10)+
				   "Set NAMENO=N.NAMENO"
	
		-- If an explicit AddressCode has been passed then include it in the update
		If (@pbResetAddress = 1)
		Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					"    ADDRESSCODE=null"
		End
		else If @pnAddressCode is not null
		Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					"    ADDRESSCODE="+convert(varchar, @pnAddressCode)
		End
		Else Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					"    ADDRESSCODE=CASE WHEN(NT.KEEPSTREETFLAG=1) THEN N.STREETADDRESS ELSE NULL END"
		End
	
		-- If the NameNo being updated is identical to the NameNo
		-- it is inherited from then also inherit the REFERENCENO
		If  @pnNewNameNo=@pnPathNameNo
		and @psPathNameType is not null
		Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					  "    REFERENCENO=(select min(CN1.REFERENCENO) from CASENAME CN1 where CN1.CASEID=CN.CASEID and CN1.NAMENO=CN.NAMENO and CN1.NAMETYPE='"+@psPathNameType+"')" --RFC9991 use MIN() to handle multiple rows
		End
		-- If the ReferenceNo has not explicitly been requested to be kept 
		-- and it is not being inherited then it should be cleared out
		Else If @pnKeepReferenceNo=2
		     OR @pnKeepReferenceNo is Null
		Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					  "    REFERENCENO=NULL"
		End
	
		-- if a new Reference has been provided, update the record with the new reference number. 
	
		Else If @pnKeepReferenceNo=3
		Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					  "    REFERENCENO="+CASE WHEN(@psReferenceNo is null) THEN 'NULL' ELSE "'"+replace(@psReferenceNo,"'","''")+"'" END
		End
	
		-- If a Commence Date has been provided then modify the Update statement
		If  @pdtCommenceDate is not NULL
		Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					 "	COMMENCEDATE='"+convert(varchar,@pdtCommenceDate,112)+"'"
		End
	
		-- If a new Correspondence Name has been indicated then modify the Update statement
		If  @pnNewCorrespondName is not NULL
		Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					  -- 14023 Only set if name type indicates attention is used.
					  "    CORRESPONDNAME=CASE WHEN(convert(bit,NT.COLUMNFLAGS&1)=1 or CN.NAMETYPE in ('I','A'))"+char(10)+
					  "				THEN "+convert(varchar,@pnNewCorrespondName)+char(10)+
					  "				ELSE CN.CORRESPONDNAME END"

			-- 8911 If path relationship is null, new value comes from UI so need to set flag to 'not derived'.
			If @psPathRelationship is Null
				Set @sUpdateString=@sUpdateString+","+char(10)+
					  -- 14023 Only set if name type indicates attention is used.
					  "    DERIVEDCORRNAME=CASE WHEN(convert(bit,NT.COLUMNFLAGS&1)=1 or CN.NAMETYPE in ('I','A'))"+char(10)+
					  "				THEN 0 ELSE 1 END"
		End
		-- Unless the CorrespondName has been explicitly requested to be kept then clear out the
		-- existing CorrespondName
		Else If @pbKeepCorrespondName=0
		     OR @pbKeepCorrespondName is NULL
		Begin
			-- 8911 Set derived flag on instead of setting correspond name to null.
			Set @sUpdateString=@sUpdateString+","+char(10)+
					  "    DERIVEDCORRNAME=1"
			Set @bDeriveCorrName=1
		End
		-- 8911 If keeping the CorrespondName, set flag to 'not derived'.
		Else
		Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					  -- 14023 Only set if name type indicates attention is used.
					  "    DERIVEDCORRNAME=CASE WHEN(convert(bit,NT.COLUMNFLAGS&1)=1 or CN.NAMETYPE in ('I','A'))"+char(10)+
					  "				THEN 0 ELSE 1 END"
		End

		-- 13785 Path (parent) name must be present for inheritance to be valid.
		If @pbNewInheritedFlag=1
		and @pnPathNameNo is not null
		Begin
			-- 13785 Always set parent name pointer, even if its the same name.
			Set @sUpdateString=@sUpdateString+","+char(10)+
					  "    INHERITED=1,"+char(10)+
					  "    INHERITEDNAMENO="+convert(varchar,@pnPathNameNo)

			If  @psPathRelationship is not null
			Begin
				Set @sUpdateString=@sUpdateString+","+char(10)+
						  "    INHERITEDRELATIONS='"+@psPathRelationship+"'"

				If @pnPathSequence is not null
				Begin
					Set @sUpdateString=@sUpdateString+","+char(10)+
						  "    INHERITEDSEQUENCE="+convert(varchar,@pnPathSequence)
				End
				Else Begin
					Set @sUpdateString=@sUpdateString+","+char(10)+
						  "    INHERITEDSEQUENCE=NULL"
				End
			End
			Else Begin
				Set @sUpdateString=@sUpdateString+","+char(10)+
						  "    INHERITEDRELATIONS=NULL,"+char(10)+
						  "    INHERITEDSEQUENCE=NULL"
			End
		End
		Else Begin
			Set @sUpdateString=@sUpdateString+","+char(10)+
					  "    INHERITED=NULL,"+char(10)+
					  "    INHERITEDNAMENO=NULL,"+char(10)+
					  "    INHERITEDSEQUENCE=NULL,"+char(10)+
					  "    INHERITEDRELATIONS=NULL"
		End

		-- Safeguard against the situation of there already existing a CASENAME
		-- for the new NameNo of the same NameType.  This could cause a problem where
		-- there are multiple Names for the NameType

		If @pnKeepReferenceNo=2
		and @psReferenceNo is not null
			Set @psReferenceNo=null

		If  @pnKeepReferenceNo in (2,3) and @psReferenceNo is null
			Set @sWhere = @sWhere+char(10)+
					"and (CN.REFERENCENO is not null"+char(10)+	
					"or not exists"+char(10)+
					"(select * from CASENAME CN1"+char(10)+
					" where CN1.CASEID=CN.CASEID"+char(10)+
					" and   CN1.NAMETYPE=CN.NAMETYPE"+char(10)+
					" and   CN1.NAMENO="+convert(varchar,@pnNewNameNo)
		else If @pnKeepReferenceNo = 3 and @psReferenceNo is not null
			Set @sWhere = @sWhere+char(10)+
					"and (isnull(CN.REFERENCENO,'')<>'"+replace(@psReferenceNo,"'","''")+"'"+char(10)+	
					"or not exists"+char(10)+
					"(select * from CASENAME CN1"+char(10)+
					" where CN1.CASEID=CN.CASEID"+char(10)+
					" and   CN1.NAMETYPE=CN.NAMETYPE"+char(10)+
					" and   CN1.NAMENO="+convert(varchar,@pnNewNameNo)
		else
			Set @sWhere = @sWhere+char(10)+	
					"and not exists"+char(10)+
					"(select * from CASENAME CN1"+char(10)+
					" where CN1.CASEID=CN.CASEID"+char(10)+
					" and   CN1.NAMETYPE=CN.NAMETYPE"+char(10)+
					" and   CN1.NAMENO="+convert(varchar,@pnNewNameNo)

		If @pnNewCorrespondName is not null
			Set @sWhere = @sWhere+char(10)+
					" and   isnull(CN1.CORRESPONDNAME,'')="+char(10)+
					"		CASE WHEN(convert(bit,NT.COLUMNFLAGS&1)=1 or CN.NAMETYPE in ('I','A'))"+char(10)+
					"			THEN "+convert(varchar,@pnNewCorrespondName)+char(10)+
					"			ELSE isnull(CN1.CORRESPONDNAME,'') END"

		If @pnKeepReferenceNo in (2,3)
			Set @sWhere = @sWhere+"))"
		Else
			Set @sWhere = @sWhere+")"
			
	
		-- Keep track of each CASEID and NAMETYPE combination updated so we can issue Policing
		-- requests if standing instructions are effected.
		Set @sUpdatedCasesString="Insert into #TEMPUPDATESANDDELETES(CASEID, NAMETYPE)"+char(10)+
					"Select CN.CASEID, CN.NAMETYPE"+char(10)+
					@sFrom+char(10)+@sWhere
	
		-- Construct an INSERT only if there is a specific NameType and there is no ExistingNameNo
		-- and an option to specifically add the Name exists.
		If  @pbInsertName=1
		and @psNameType is not NULL
		and @pnExistingNameNo is NULL
		Begin
			If @psPathRelationship is Null
			Begin
				-- Insert the CaseName row for the NameType if the NameType is allowed for the Case.
	
				-- If the Path NameType and Path NameNo have beeen supplied then the INSERT is only to be 
				-- applied to those Cases that have a CASENAME that matches the PathNameType and PathNameNo
				
				If  @pnPathNameNo   is not Null
				and @psPathNameType is not Null
				Begin
					-- 8911 Include new column DERIVEDCORRNAME.
					-- 13785 Include INHERITEDNAMENO as appropriate.
					Set @sInsertString="Insert into #TEMPCASENAMES (CASEID,NAMETYPE,NAMENO,CORRESPONDNAME,DERIVEDCORRNAME,INHERITED,INHERITEDNAMENO,ADDRESSCODE,REFERENCENO,COMMENCEDATE)"+char(10)+
					 		   "Select distinct T.CASEID,@psNameType,N.NAMENO,@pnNewCorrespondName,"+char(10)+
							   -- 8911 If correspondname supplied, include and set flag to non-derived, otherwise will be derived later.
							   "CASE WHEN(@pnNewCorrespondName is not null) THEN 0 ELSE 1 END,"+char(10)+
							   "1,@pnPathNameNo,"+char(10)+
							   -- Check if the Street Address is to be saved
							   "CASE WHEN(T.KEEPSTREETFLAG=1 or @pnAddressCode is not null) THEN isnull(@pnAddressCode,N.STREETADDRESS) END,"+char(10)+
							   -- If the NameNo is the same as the NameNo from which it is inherited
							   -- then also inherit the REFERENCENO
							   "CASE WHEN(@pnNewNameNo=@pnPathNameNo) THEN CN.REFERENCENO END,"+char(10)+
							   "@pdtCommenceDate"+char(10)+
							   "From #TEMPCASENAMETYPES T"+char(10)+
							   "join CASENAME CN on (CN.CASEID=T.CASEID"+char(10)+
							   "                 and CN.NAMENO=@pnPathNameNo"+char(10)+
							   "                 and CN.NAMETYPE=@psPathNameType"+char(10)+
							   "                 and CN.SEQUENCE=(select min(CN1.SEQUENCE)"+char(10)+
							   "                                  from CASENAME CN1"+char(10)+
							   "                                  where CN1.CASEID=CN.CASEID"+char(10)+
							   "                                  and   CN1.NAMENO=CN.NAMENO"+char(10)+
	 						   "                                  and   CN1.NAMETYPE=CN.NAMETYPE))"+char(10)+
							   "join NAME N on (N.NAMENO=@pnNewNameNo)"+char(10)+
							   "left join CASENAME CN1 on (CN1.CASEID=T.CASEID"+char(10)+
							   "                       and CN1.NAMETYPE=T.NAMETYPE)"+char(10)+
							   "Where T.NAMETYPE=@psNameType"+char(10)+
							   "and (T.UPDATEFROMPARENT=1 OR CN1.CASEID is null)"+char(10)+
							   "and isnull(T.MAXIMUMALLOWED,999)>"+char(10)+
							   "               (select count(*) from CASENAME CN2"+char(10)+
							   "                where CN2.CASEID=T.CASEID"+char(10)+
							   "                and CN2.NAMETYPE=@psNameType"+char(10)+
							   "                and (CN2.EXPIRYDATE is null OR CN2.EXPIRYDATE>getdate()))"+char(10)+
							   "order by 1,2,3"
				End
				Else Begin
					-- 8911 Include new column DERIVEDCORRNAME.
					-- 13785 Include INHERITEDNAMENO as appropriate.
					Set @sInsertString="Insert into #TEMPCASENAMES (CASEID,NAMETYPE,NAMENO,CORRESPONDNAME,DERIVEDCORRNAME,INHERITED,INHERITEDNAMENO,ADDRESSCODE,REFERENCENO,COMMENCEDATE)"+char(10)+
							   "Select distinct T.CASEID,@psNameType,N.NAMENO,@pnNewCorrespondName,"+char(10)+
							   -- 8911 If correspondname supplied, include and set flag to non-derived, otherwise will be derived later.
							   "CASE WHEN(@pnNewCorrespondName is null) THEN 1 ELSE 0 END,"+char(10)+
							   "1,@pnPathNameNo,"+char(10)+
							   "CASE WHEN(T.KEEPSTREETFLAG=1 or @pnAddressCode is not null) THEN isnull(@pnAddressCode,N.STREETADDRESS) END,"+char(10)+
							   "CASE WHEN(@pnKeepReferenceNo=3)THEN @psReferenceNo" +char(10) +
							   "     WHEN(@pnKeepReferenceNo=1)THEN T.REFERENCENO  END," +char(10) +  -- Reference from 
							   "@pdtCommenceDate"+char(10)+
							   "From #TEMPCASENAMETYPES T"+char(10)+
							   "join NAME N on (N.NAMENO=@pnNewNameNo)"+char(10)+
							   "Where T.NAMETYPE=@psNameType"+char(10)+
							   "and isnull(T.MAXIMUMALLOWED,999)>"+char(10)+
							   "               (select count(*) from CASENAME CN2"+char(10)+
							   "                where CN2.CASEID=T.CASEID"+char(10)+
							   "                and CN2.NAMETYPE=@psNameType"+char(10)+
							   "                and (CN2.EXPIRYDATE is null OR CN2.EXPIRYDATE>getdate()))"+char(10)+
							   "order by 1,2,3"
				End
			End
			Else Begin
				-- When an Insert has been generated as a result of a PathNameNo and PathRelationship 
				-- then the PropertytType and CountryCode of the Case must also be taken into consideration
				-- to ensure that the global Name change matches the Case it is being applied to.
				-- This match uses the standard "Best Fit" algorithm.
				-- Note that the NameType being inserted must be a valid NameType for the Case.
	
				-- 8911 Include new column DERIVEDCORRNAME - always set to 1 for names inherited by relationship.
				Set @sInsertString="Insert into #TEMPCASENAMES (CASEID,NAMETYPE,NAMENO,CORRESPONDNAME,DERIVEDCORRNAME,INHERITED,INHERITEDNAMENO,INHERITEDRELATIONS,INHERITEDSEQUENCE,ADDRESSCODE,REFERENCENO,COMMENCEDATE)"+char(10)+
				 		"Select distinct T.CASEID, @psNameType,AN.RELATEDNAME,AN.CONTACT,1,1,@pnPathNameNo,@psPathRelationship,@pnPathSequence,"+char(10)+
							   "CASE WHEN(T.KEEPSTREETFLAG=1 or @pnAddressCode is not null) THEN isnull(@pnAddressCode,N.STREETADDRESS) END,"+char(10)+
						-- If the NameNo is the same as the NameNo from which it is inherited
						-- then also inherit the REFERENCENO
						"CASE WHEN(@pnNewNameNo=@pnPathNameNo) THEN CN.REFERENCENO END,"+char(10)+
						"@pdtCommenceDate"+char(10)+
						"From #TEMPCASENAMETYPES T"+char(10)+
						"left join CASENAME CN on (CN.CASEID=T.CASEID"+char(10)+
						"                      and CN.NAMENO=@pnPathNameNo"+char(10)+
						"                      and CN.NAMETYPE=@psPathNameType"+char(10)+
						"                      and CN.SEQUENCE=(select min(CN1.SEQUENCE)"+char(10)+
						"                                       from CASENAME CN1"+char(10)+
						"                                       where CN1.CASEID=CN.CASEID"+char(10)+
						"                                       and   CN1.NAMENO=CN.NAMENO"+char(10)+
						"                                       and   CN1.NAMETYPE=CN.NAMETYPE))"+char(10)+
						"join CASES C on (C.CASEID=T.CASEID)"+char(10)+
						"join ASSOCIATEDNAME AN on (AN.NAMENO=@pnPathNameNo"+char(10)+
						"                       and AN.RELATEDNAME=@pnNewNameNo"+char(10)+
						"                       and AN.RELATIONSHIP=@psPathRelationship"+char(10)+
						"			and(AN.PROPERTYTYPE=C.PROPERTYTYPE or AN.PROPERTYTYPE is null)"+char(10)+
						"			and(AN.COUNTRYCODE =C.COUNTRYCODE  or AN.COUNTRYCODE  is null))"+char(10)+
						"join NAME N on (N.NAMENO=AN.RELATEDNAME)"+char(10)+
						"left join CASENAME CN1 on (CN1.CASEID=T.CASEID"+char(10)+
						"                       and CN1.NAMETYPE=T.NAMETYPE)"+char(10)+
						"Where T.NAMETYPE=@psNameType"+char(10)+
						"and @pnPathNameNo=isnull(CN.NAMENO, @pnHomeNameNo)"+char(10)+
						"and (T.UPDATEFROMPARENT=1 OR CN1.CASEID is null)"+char(10)+
						-- 14023 Remove this condition as inserted attention processed further below.
						-- "and (AN.CONTACT=@pnNewCorrespondName or (AN.CONTACT is null and @pnNewCorrespondName is null))"+char(10)+
						-- this calculates the bestfit value of the current AssociatedName row
						-- and ensures it is matches the best fit value for the spcific case.
						"and (CASE WHEN(AN.PROPERTYTYPE is null) THEN '0' ELSE '1' END +"+char(10)+
						"     CASE WHEN(AN.COUNTRYCODE  is null) THEN '0' ELSE '1' END)"+char(10)+
						"      = (select max(CASE WHEN(AN1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +"+char(10)+
						"                    CASE WHEN(AN1.COUNTRYCODE  is null) THEN '0' ELSE '1' END )"+char(10)+
						"         from ASSOCIATEDNAME AN1"+char(10)+
						"         where AN1.NAMENO=AN.NAMENO"+char(10)+
						"	  and  AN1.RELATIONSHIP=@psPathRelationship"+char(10)+
						"         and (AN1.CEASEDDATE is null OR AN1.CEASEDDATE>getdate())"+char(10)+
						"         and (AN1.PROPERTYTYPE=C.PROPERTYTYPE or AN1.PROPERTYTYPE is null)"+char(10)+
						"         and (AN1.COUNTRYCODE =C.COUNTRYCODE  or AN1.COUNTRYCODE  is null))"+char(10)+
						"and isnull(T.MAXIMUMALLOWED,999)>"+char(10)+
						"               (select count(*) from CASENAME CN2"+char(10)+
						"                where CN2.CASEID=T.CASEID"+char(10)+
						"                and CN2.NAMETYPE=@psNameType"+char(10)+
						"                and (CN2.EXPIRYDATE is null OR CN2.EXPIRYDATE>getdate()))"+char(10)+
						"order by 1,2,3"
			End
		End
	
	End
	-- If only the CorrespondName is being changed then create the appropriate Update
	Else If @pnNewCorrespondName is not NULL or @pbResetAttention = 1 or @pnAddressCode is not null or @pbResetAddress = 1
	Begin
		Set @sUpdateString = null
		
		if (@pbResetAttention = 1)
		Begin
			if @sUpdateString is null
				Set @sUpdateString = "Update CASENAME" + char(10) + "Set "

			Set @sUpdateString = @sUpdateString+char(10)+"DERIVEDCORRNAME = 1"
			Set @bDeriveCorrName=1
						
		End
		Else if @pnNewCorrespondName is not null
		Begin
			Set @sUpdateString="Update CASENAME" + char(10) + "Set "
			
			-- 14023 Only set if name type indicates attention is used.
			Set @sUpdateString = @sUpdateString+char(10)+"CORRESPONDNAME=CASE WHEN(convert(bit,NT.COLUMNFLAGS&1)=1 or CN.NAMETYPE in ('I','A'))"+char(10)+
			"				THEN "+convert(varchar,@pnNewCorrespondName)+char(10)+
			"				ELSE CN.CORRESPONDNAME END"
	
	
			-- 8911 If path relationship is null, value is coming from UI so need to set flag to 'not derived'.
			If @psPathRelationship is Null
				Set @sUpdateString=@sUpdateString+","+char(10)+
						  -- 14023 Only set if name type indicates attention is used.
						  "	DERIVEDCORRNAME=CASE WHEN(convert(bit,NT.COLUMNFLAGS&1)=1 or CN.NAMETYPE in ('I','A'))"+char(10)+
						  "				THEN 0 ELSE CN.DERIVEDCORRNAME END"
		
			-- If the user has not explicitly requested the Reference be retained then clear it out
	 		If @pnKeepReferenceNo=2
			OR @pnKeepReferenceNo is Null
			Begin
				Set @sUpdateString=@sUpdateString+","+char(10)+
						  "    REFERENCENO=NULL"
			End
			-- if a new Reference has been provided, update the record with the new reference number. 
			Else If @pnKeepReferenceNo=3
			Begin
				Set @sUpdateString=@sUpdateString+","+char(10)+
						  "    REFERENCENO="+CASE WHEN(@psReferenceNo is null) THEN 'NULL' ELSE "'"+replace(@psReferenceNo,"'","''")+"'" END
			End
		End
		
		if (@pbResetAddress = 1)
		Begin
			if @sUpdateString is null
				Set @sUpdateString = "Update CASENAME" + char(10) + "Set "
			else
				Set @sUpdateString = @sUpdateString+","

			Set @sUpdateString = @sUpdateString+char(10)+"ADDRESSCODE = null"
		End
		else if @pnAddressCode is not null
		Begin
			if @sUpdateString is null
				Set @sUpdateString = "Update CASENAME" + char(10) + "Set "
			else
				Set @sUpdateString = @sUpdateString+","

			Set @sUpdateString = @sUpdateString+char(10)+"ADDRESSCODE = " + convert(varchar,@pnAddressCode)
		End
	
		-- For each Case and Nametype changed we will need to check to see if Policing
		-- requests need to be generated because of standing instruction changes.	
		Set @sUpdatedCasesString="Insert into #TEMPUPDATESANDDELETES(CASEID, NAMETYPE)"+char(10)+
					"Select CN.CASEID, CN.NAMETYPE"+char(10)+
					@sFrom+char(10)+@sWhere
	End
End -- End of construction of the Update, Insert and Delete statements
-------------------------------------------------------------------------------------------
--
--	TRANSACTION BEGINS
--
-------------------------------------------------------------------------------------------

If  @pnTransNo is null
and @ErrorCode=0
Begin
	-- A separate database transaction will be used to insert the TRANSACTIONINFO
	-- row to ensure the lock on the database is kept to a minimum as this table
	-- will be used extensively by other processes.

	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE,BATCHNO, TRANSACTIONREASONNO, TRANSACTIONMESSAGENO)
			Select getdate(),@pnBatchNo, R.TRANSACTIONREASONNO, M.TRANSACTIONMESSAGENO
			from (select 1 as COL1) A
			left join EDESENDERDETAILS S   on (S.BATCHNO=@pnBatchNo)
			left join EDEREQUESTTYPE RT    on (RT.REQUESTTYPECODE=S.SENDERREQUESTTYPE)
			left join TRANSACTIONREASON  R on (R.TRANSACTIONREASONNO = COALESCE(@pnTransReasonNo, RT.TRANSACTIONREASONNO, CASE WHEN(@pnBatchNo is not null) THEN -1 END))
			left join TRANSACTIONMESSAGE M on (M.TRANSACTIONMESSAGENO=2)
			Set @pnTransNo=SCOPE_IDENTITY()"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@pnBatchNo		int,
				  @pnTransReasonNo	int,
				  @pnTransNo		int	OUTPUT',
				  @pnBatchNo      =@pnBatchNo,
				  @pnTransReasonNo=@pnTransReasonNo,
				  @pnTransNo      =@pnTransNo	OUTPUT

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @ErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

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
			substring(cast(isnull(@pnTransNo,'') as varbinary),1,4)+ 
			substring(cast(isnull(@pnBatchNo,'') as varbinary),1,4)
	SET CONTEXT_INFO @bHexNumber
	
	COMMIT TRANSACTION

	-- Execute the constructed SQL within a transaction
	-- This is done before cascading the changes caused by this global name change
	-- to other effected NameTypes as the cascaded global changes may be dependent
	-- on the existence of the higher level changes.

	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
End

-------------------------------------------------------------------------------------------
--
--	REMOVAL OF ORPHANS AND CORRECTION OF PARENTAGE POINTERS
--
-------------------------------------------------------------------------------------------
If  @psProgramId is null
and  @pbApplyInheritance=1
and @psNameType is not null
and @ErrorCode=0
Begin	
	-------------------------------------------------------------------------------------------
	-- If the procedure has been called recursively (@psProgramId is null)
	-- delete any inherited CaseName rows that no longer have a parent or 
	-- clear out the inherited pointer details from those previously inherited
	-- names that do not have a parent but are not required to be updated from
	-- the parent.
	If @pbRemoveOrphans=1
	Begin
		If @ErrorCode=0
		Begin
			-- Need to keep track of the CaseId and NameType combination that  
			-- are about to be deleted in order to trigger any standing instruction changes
			Set @sCorrectParentsString=
			"Insert into dbo.#TEMPUPDATESANDDELETES(CASEID,NAMETYPE)"+char(10)+
			"Select distinct CN.CASEID, CN.NAMETYPE"+char(10)+
			"from CASENAME CN"+char(10)+
			"join "+@psGlobalTempTable+" T on (T.CASEID=CN.CASEID)"+char(10)+
			"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
			"left join dbo.#TEMPUPDATESANDDELETES D on (D.CASEID=CN.CASEID"+char(10)+
			"					and D.NAMETYPE=CN.NAMETYPE)"+char(10)+
			"where NT.PATHNAMETYPE is not null"+char(10)+
			"and NT.UPDATEFROMPARENT=1"+char(10)+
			-- 13785 Don't exclude records which can default from home name.
			-- "and isnull(NT.USEHOMENAMEREL,0)=0"+char(10)+
			"and D.CASEID is null"+char(10)+
			"and CN.NAMETYPE=@psNameType"+char(10)+
			-- RFC9642 If inheritance is being forced then uninherited Names for NameTypes that
			--         have inheritance rules will be removed.
			CASE WHEN(@pbForceInheritance=0)
				THEN "and CN.INHERITED=1"
				ELSE ""
			END +char(10)+
			"and CN.EXPIRYDATE is null"+char(10)+
			-- Delete the inherited CaseName if the parent is missing
			-- 13785 Also delete if it was inherited from the home name.
			"and (CN.INHERITEDNAMENO=@pnHomeNameNo"+char(10)+
			"     or not exists ("+char(10)+
			"	 select 1"+char(10)+
			"	 from CASENAME CN1"+char(10)+
			"	 where CN1.CASEID  =CN.CASEID"+char(10)+
			"	 and   CN1.NAMETYPE=NT.PATHNAMETYPE"+char(10)+
			"	 and   CN1.NAMENO  =isnull(CN.INHERITEDNAMENO,CN.NAMENO)))"
			-- If the NameType is mandatory don't delete the last CaseName entry
			-- 13785 This condition not necessary as we are inserting a name when applying inheritance.
			-- "and (isnull(NT.MANDATORYFLAG,0)=0"+char(10)+
			-- " or  1<(select count(*)"+char(10)+
			-- "        from CASENAME CN2"+char(10)+
			-- "        where CN2.CASEID=CN.CASEID"+char(10)+
			-- "        and CN2.NAMETYPE=CN.NAMETYPE"+char(10)+
			-- "        and CN2.EXPIRYDATE is null))"
	
			Exec @ErrorCode=sp_executesql @sCorrectParentsString,
					N'@psNameType	nvarchar(3),
					  @pnHomeNameNo	int',
					  @psNameType=@psNameType,
					  @pnHomeNameNo=@pnHomeNameNo
		End

		If @ErrorCode=0
		Begin
			Set @sCorrectParentsString=
			"Delete CASENAME"+char(10)+
			"from CASENAME CN"+char(10)+
			"join "+@psGlobalTempTable+" T on (T.CASEID=CN.CASEID)"+char(10)+
			"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
			"where NT.PATHNAMETYPE is not null"+char(10)+
			"and NT.UPDATEFROMPARENT=1"+char(10)+
			-- 13785 Don't exclude records which can default from home name.
			-- "and isnull(NT.USEHOMENAMEREL,0)=0"+char(10)+
			"and CN.NAMETYPE=@psNameType"+char(10)+
			-- RFC9642 If inheritance is being forced then uninherited Names for NameTypes that
			--         have inheritance rules will be removed.
			CASE WHEN(@pbForceInheritance=0)
				THEN "and CN.INHERITED=1"
				ELSE ""
			END +char(10)+
			"and CN.EXPIRYDATE is null"+char(10)+
			-- Delete the inherited CaseName if the parent is missing
			-- 13785 Also delete if it was inherited from the home name.
			"and (CN.INHERITEDNAMENO=@pnHomeNameNo"+char(10)+
			"     or not exists ("+char(10)+
			"	 select 1"+char(10)+
			"	 from CASENAME CN1"+char(10)+
			"	 where CN1.CASEID  =CN.CASEID"+char(10)+
			"	 and   CN1.NAMETYPE=NT.PATHNAMETYPE"+char(10)+
			"	 and   CN1.NAMENO  =isnull(CN.INHERITEDNAMENO,CN.NAMENO)))"
			-- If the NameType is mandatory don't delete the last CaseName entry
			-- 13785 This condition not necessary as we are inserting a name when applying inheritance.
			-- "and (isnull(NT.MANDATORYFLAG,0)=0"+char(10)+
			-- " or  1<(select count(*)"+char(10)+
			-- "        from CASENAME CN2"+char(10)+
			-- "        where CN2.CASEID=CN.CASEID"+char(10)+
			-- "        and CN2.NAMETYPE=CN.NAMETYPE"+char(10)+
			-- "        and CN2.EXPIRYDATE is null))"
			
			Exec @ErrorCode=sp_executesql @sCorrectParentsString,
					N'@psNameType	nvarchar(3),
					  @pnHomeNameNo	int',
					  @psNameType=@psNameType,
					  @pnHomeNameNo=@pnHomeNameNo
			
			Set @pnNamesDeletedCount=@pnNamesDeletedCount+@@Rowcount
		End
	End

	-- Clear out the pointers if no parent exists and the rule for the NameType
	-- indicates that after the initial inheritance the child is no longer
	-- to be affected by changes to the parent

	If @ErrorCode=0
	Begin
		Set @sCorrectParentsString=
			"Update CASENAME"+char(10)+
			"Set INHERITED         =NULL,"+char(10)+
			"    INHERITEDNAMENO   =NULL,"+char(10)+
			"    INHERITEDRELATIONS=NULL,"+char(10)+
			"    INHERITEDSEQUENCE =NULL"+char(10)+
			"from CASENAME CN"+char(10)+
			"join "+@psGlobalTempTable+" T on (T.CASEID=CN.CASEID)"+char(10)+
			"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
			"where CN.NAMETYPE=@psNameType"+char(10)+
			"and((NT.UPDATEFROMPARENT=0 and @pnNewNameNo is not null) OR @pnNewNameNo is null)"+char(10)+	-- RFC41124 Correct inheritance pointers irrespective of UPDATEFROMPARENT flag if no @pnNewNameNo is supplied.
			"and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())"+char(10)+
			-- 13785 Include records which can default from home name but haven't.
			"and (isnull(NT.USEHOMENAMEREL,0)=0 or isnull(CN.INHERITEDNAMENO,'')<>isnull(@pnHomeNameNo,''))"+char(10)+
			"and(CN.INHERITED=1"+char(10)+
			" or CN.INHERITEDNAMENO is not null"+char(10)+
			" or CN.INHERITEDRELATIONS is not null"+char(10)+
			" or CN.INHERITEDSEQUENCE  is not null)"+char(10)+
			-- Update the inherited CaseName if the parent is missing
			"and not exists"+char(10)+
			"(select 1"+char(10)+
			" from CASENAME CN1"+char(10)+
			" where CN1.CASEID  =CN.CASEID"+char(10)+
			" and   CN1.NAMETYPE=NT.PATHNAMETYPE"+char(10)+
			" and   CN1.NAMENO  =isnull(CN.INHERITEDNAMENO,CN.NAMENO))"
			
		Exec @ErrorCode=sp_executesql @sCorrectParentsString,
					N'@psNameType	nvarchar(3),
					  @pnHomeNameNo	int,
					  @pnNewNameNo	int',
					  @psNameType=@psNameType,
					  @pnHomeNameNo=@pnHomeNameNo,
					  @pnNewNameNo =@pnNewNameNo
		
		Set @pnNamesUpdatedCount=@pnNamesUpdatedCount+@@Rowcount
	End
End

-------------------------------------------------------------------------------------------
--
--	UPDATE REQUEST PROCESSING
--
-------------------------------------------------------------------------------------------

If  @sUpdateString is not NULL
and @pbUpdateName=1
and @ErrorCode=0
Begin
	-- 8911 If need to derive the Correspond Name, add the best fit derivation sql.
	If @bDeriveCorrName=1
	Begin
		Set @sUpdateString=@sUpdateString+","+char(10)+
				  -- 14023 Set attention to null if debtor/renewal debtor or name type indicates it is not used, except for instructor/agent.
				  "    CORRESPONDNAME=CASE WHEN(convert(bit,NT.COLUMNFLAGS&1)=0 and CN.NAMETYPE not in ('I','A')) THEN null"+char(10)+
				  -- If the new NameNo is not given, check associated name contact first.
				  CASE WHEN(@pnNewNameNo is null) THEN
				  "		     WHEN (AN.CONTACT is not null) THEN AN.CONTACT"+char(10) ELSE "" END+
				  -- 14172 Change logic so only select name main contact if site control is TRUE.
				  "		     WHEN (SC.COLBOOLEAN=1) THEN N.MAINCONTACT"+char(10)+
				  "		     WHEN (CN.NAMETYPE in ('D','Z')) THEN ("+char(10)+
			  	  "			    select	isnull( AN5.CONTACT, N2.MAINCONTACT )"+char(10)+
				  "			    from NAME N2"+char(10)+
				  "			    left join ASSOCIATEDNAME AN5 on ( AN5.NAMENO = N2.NAMENO"+char(10)+
				  "						and AN5.RELATIONSHIP = 'BIL'"+char(10)+
				  "						and AN5.CEASEDDATE is null"+char(10)+
				  "						and AN5.NAMENO = AN5.RELATEDNAME )"+char(10)+
				  "			    where N2.NAMENO = N.NAMENO)"+char(10)+				  
				  "		     ELSE ("+char(10)+
				  "		   	select convert(int,substring("+char(10)+
				  "			    min(CASE WHEN(AN4.PROPERTYTYPE is not null) THEN '0' ELSE '1' END+"+char(10)+
				  "				CASE WHEN(AN4.COUNTRYCODE is not null) THEN '0' ELSE '1' END+"+char(10)+
				  "				CASE WHEN(AN4.RELATEDNAME=N1.MAINCONTACT) THEN '0' ELSE '1' END+"+char(10)+
				  "				replicate('0',6-datalength(convert(varchar(6),AN4.SEQUENCE)))+"+char(10)+
				  "				convert(varchar(6),AN4.SEQUENCE)+"+char(10)+
				  "				convert(varchar,AN4.RELATEDNAME)),10,19))"+char(10)+
				  "			from CASES C1"+char(10)+
				  "			join NAME N1 on (N1.NAMENO=N.NAMENO)"+char(10)+
				  "			join ASSOCIATEDNAME AN4 on (AN4.NAMENO=N.NAMENO"+char(10)+
				  "		   				and AN4.RELATIONSHIP='EMP'"+char(10)+
				  "		   				and AN4.CEASEDDATE is null"+char(10)+
				  "		   				and (AN4.PROPERTYTYPE is not null"+char(10)+
				  "		   					or AN4.COUNTRYCODE is not null"+char(10)+
				  "		   					or AN4.RELATEDNAME=N1.MAINCONTACT)"+char(10)+
				  "		   				and (AN4.PROPERTYTYPE=C1.PROPERTYTYPE or AN4.PROPERTYTYPE is null )"+char(10)+
				  "		   				and (AN4.COUNTRYCODE=C1.COUNTRYCODE or AN4.COUNTRYCODE  is null ) )"+char(10)+
				  "			where C1.CASEID=CN.CASEID) END"

		-- Add Name table and Associated Name relationship joins if new name not given.
		If @pnNewNameNo is NULL
			Set @sFrom = @sFrom+char(10)+
			   "join NAME N on (N.NAMENO=CN.NAMENO)"+char(10)+
			   "left join ASSOCIATEDNAME AN on (AN.NAMENO=CN.INHERITEDNAMENO"+char(10)+
			   "				and AN.RELATEDNAME=CN.NAMENO"+char(10)+
			   "				and AN.RELATIONSHIP=CN.INHERITEDRELATIONS"+char(10)+
			   "				and AN.SEQUENCE=CN.INHERITEDSEQUENCE)"

		-- 14172 Move join on SITECONTROL out of imbedded select above.
		Set @sFrom = @sFrom+char(10)+
			"left join SITECONTROL SC on (SC.CONTROLID='Main Contact used as Attention')"
	End

	-- Insert a row into a temporary table to keep track of each CASEID and NAMETYPE combination updated
	-- The contents of the temporary table will later be used to determine any Policing required for 
	-- potential standing instruction changes

	exec(@sUpdatedCasesString)
	Set @ErrorCode=@@Error

	-- If the NameType being updated is the Instructor ("I") then also update
	-- the LOCALCLIENTFLAG of any Cases that are actually going to have the 
	-- Instructor changed.

	If @psNameType='I'
	and @pnNewNameNo is not null
	and @ErrorCode=0
	Begin
		Set @sSQLString=
			"update CASES"+char(10)+
			"set LOCALCLIENTFLAG=IP.LOCALCLIENTFLAG"+char(10)+
			"from CASES C"+char(10)+
			"join "+@psGlobalTempTable+" T on (T.CASEID=C.CASEID)"+char(10)+
			"join CASENAME CN on ( CN.CASEID=C.CASEID"+char(10)+
			"                 and  CN.NAMETYPE='I'"+char(10)+
			"                 and (CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"+char(10)+
			"join IPNAME IP on (IP.NAMENO=@pnNewNameNo)"+char(10)+
			"where C.LOCALCLIENTFLAG<>IP.LOCALCLIENTFLAG"+char(10)+
			"and CN.NAMENO<>IP.NAMENO"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnNewNameNo		int',
					  @pnNewNameNo=@pnNewNameNo
	End

	If  @ErrorCode=0
	and @sDeleteString is not null
	Begin
		-- Remove some code not required at this point
		set @sDeletedCasesString=replace(@sDeletedCasesString,' OR CN.NAMENO<>N.NAMENO)',')')	--SQA17878
		set @sDeleteString      =replace(@sDeleteString,      ' OR CN.NAMENO<>N.NAMENO)',')')	--SQA17878
		exec(@sDeletedCasesString)
		Select	@ErrorCode=@@Error,
			@nRowCount=@@Rowcount
		
		-- Only bother with the Delete if there are rows to actually delete
		If  @ErrorCode=0
		and @nRowCount>0
		Begin	
			exec(@sDeleteString)
			
			Select @ErrorCode=@@Error,
			       @pnNamesDeletedCount=@@Rowcount
		End
	End

	-- Don't need to do the update if all of the CaseName rows
	-- have just been deleted.
	If  @ErrorCode=0
	Begin
		exec(@sUpdateString+@sFrom+@sWhere)

		Select @ErrorCode=@@Error,
		       @pnNamesUpdatedCount=@@Rowcount
	End

	-- SQA12537
	-- If the NameType being updated is used to determine a Standing Instruction and there are Case
	-- specific standing instructions then delete those NameInstruction rows so that the
	-- instructions for the Case will drop back to the default

	If  @pnNewNameNo is not null
	and @ErrorCode=0
	Begin
		Set @sSQLString=
		/***********SQA12898 decided to delete the case specific standing instruction if the Name has changed
			"Update NAMEINSTRUCTIONS"+char(10)+
			"Set NAMENO=@pnNewNameNo,"+char(10)+
			"    INTERNALSEQUENCE=isnull(X.INTERNALSEQUENCE,-1)+T.INTERNALSEQUENCE,"+char(10)+
			"    COUNTRYCODE=null,"+char(10)+
			"    PROPERTYTYPE=null"+char(10)+
			"From NAMEINSTRUCTIONS NI"+char(10)+
			-- Join on CASEID so only Case level Standing Instrucitons are changed
			"join #TEMPUPDATESANDDELETES T  on (T.CASEID=NI.CASEID)"+char(10)+
			"join INSTRUCTIONS I 		on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)"+char(10)+
			-- Only process the Standing Instructions where NameType in the global change
			-- is being modified.
			"join INSTRUCTIONTYPE IT 	on (IT.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE"+char(10)+
			"				and IT.NAMETYPE=T.NAMETYPE)"+char(10)+
			"left join (	Select NAMENO, max(INTERNALSEQUENCE) as INTERNALSEQUENCE"+char(10)+
			"		from NAMEINSTRUCTIONS"+char(10)+
			"		group by NAMENO) X on (X.NAMENO=@pnNewNameNo)"+char(10)+
			"Where NI.NAMENO<>@pnNewNameNo"
		******/
			"Delete NAMEINSTRUCTIONS"+char(10)+
			"From NAMEINSTRUCTIONS NI"+char(10)+
			-- Join on CASEID so only Case level Standing Instrucitons are delete
			"join #TEMPUPDATESANDDELETES T  on (T.CASEID=NI.CASEID)"+char(10)+
			"join INSTRUCTIONS I 		on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)"+char(10)+
			-- Only delete the Standing Instructions where NameType in the global change
			-- is being modified.
			"join INSTRUCTIONTYPE IT 	on (IT.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE"+char(10)+
			"				and IT.NAMETYPE=T.NAMETYPE)"+char(10)+
			"Where NI.NAMENO<>@pnNewNameNo"+char(10)+
			"and not exists"+char(10)+
			"(select 1 from CASENAME CN" +char(10)+
			" where CN.CASEID=NI.CASEID" +char(10)+
			" and CN.NAMETYPE=T.NAMETYPE"+char(10)+
			" and CN.NAMENO  =NI.NAMENO" +char(10)+
			" and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate()))"
		
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnNewNameNo	int',
					  @pnNewNameNo=@pnNewNameNo
	End
	
	If  @pbAlerts=1
	and @pnNewNameNo <> @pnExistingNameNo
	and @ErrorCode=0
	Begin
		---------------------------------------------------
		-- RFC13351
		-- Take a copy of the ALERT primary keys for those
		-- rows to be moved to the New Name.
		---------------------------------------------------
		Set @sSQLString="
		insert into #TEMPALERT (EMPLOYEENO, ALERTSEQ)
		select EMPLOYEENO, ALERTSEQ
		from "+@psGlobalTempTable+" T 
		join ALERT A on (A.CASEID=T.CASEID)
		where A.EMPLOYEENO=@pnExistingNameNo"
		
		Exec @ErrorCode=sp_executesql @sSQLString,
					N'@pnExistingNameNo	int',
					  @pnExistingNameNo=@pnExistingNameNo
					  
		Set @nAlertCount=@@ROWCOUNT
					
		If @nAlertCount>0
		Begin
			If @ErrorCode=0
			Begin
				--------------------------------
				-- Generate a new ALERTSEQ value
				--------------------------------
				Set @sSQLString="
				Update #TEMPALERT
				Set NEWALERTSEQ=dateadd(ms, SEQUENCENO, getdate())"
				
				Exec @ErrorCode=sp_executesql @sSQLString
			End
						  
			If @ErrorCode=0
			Begin
				-----------------------------------
				-- Now insert rows into ALERT table
				-- for the new Name
				-----------------------------------
				Set @sSQLString="
				insert into ALERT(EMPLOYEENO, ALERTSEQ, CASEID, ALERTMESSAGE, REFERENCE, ALERTDATE, DUEDATE, 
						  DATEOCCURRED, OCCURREDFLAG, DELETEDATE, STOPREMINDERSDATE, MONTHLYFREQUENCY,
						  MONTHSLEAD, DAILYFREQUENCY, DAYSLEAD, SEQUENCENO, SENDELECTRONICALLY, EMAILSUBJECT, 
						  NAMENO, EMPLOYEEFLAG, SIGNATORYFLAG,CRITICALFLAG, NAMETYPE, RELATIONSHIP, TRIGGEREVENTNO, EVENTNO, CYCLE, IMPORTANCELEVEL,
						  FROMCASEID)
				select	@pnNewNameNo, A.NEWALERTSEQ, T.CASEID, T.ALERTMESSAGE, T.REFERENCE, T.ALERTDATE, T.DUEDATE, T.DATEOCCURRED, T.OCCURREDFLAG, 
					T.DELETEDATE, T.STOPREMINDERSDATE, T.MONTHLYFREQUENCY, T.MONTHSLEAD, T.DAILYFREQUENCY, T.DAYSLEAD, T.SEQUENCENO, 
					T.SENDELECTRONICALLY, T.EMAILSUBJECT, T.NAMENO, T.EMPLOYEEFLAG, T.SIGNATORYFLAG, T.CRITICALFLAG, T.NAMETYPE, T.RELATIONSHIP, 
					T.TRIGGEREVENTNO, T.EVENTNO, T.CYCLE, T.IMPORTANCELEVEL, T.FROMCASEID
				from #TEMPALERT A
				join ALERT T	   on (T.EMPLOYEENO =A.EMPLOYEENO
						   and T.ALERTSEQ   =A.ALERTSEQ)
				left join ALERT T1 on (T1.EMPLOYEENO=A.EMPLOYEENO
						   and T1.ALERTSEQ  =A.NEWALERTSEQ)
				where T1.EMPLOYEENO is null"

				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnNewNameNo		int',
								  @pnNewNameNo=@pnNewNameNo
			End
		  
			If @ErrorCode=0
			Begin
				-----------------------------------
				-- Now redirect the previously
				-- generated Employee Reminders to 
				-- the new Name.
				-----------------------------------
				Set @sSQLString="
				INSERT INTO EMPLOYEEREMINDER(EMPLOYEENO, MESSAGESEQ, CASEID, REFERENCE, EVENTNO, CYCLENO, DUEDATE, REMINDERDATE, READFLAG, SOURCE, HOLDUNTILDATE, 
							     DATEUPDATED, SHORTMESSAGE, LONGMESSAGE, COMMENTS, SEQUENCENO, NAMENO, ALERTNAMENO)
				Select A.EMPLOYEENO, A.ALERTSEQ, E.CASEID, E.REFERENCE, E.EVENTNO, E.CYCLENO, E.DUEDATE, E.REMINDERDATE, E.READFLAG, E.SOURCE, E.HOLDUNTILDATE, 
				       E.DATEUPDATED, E.SHORTMESSAGE, E.LONGMESSAGE, E.COMMENTS, E.SEQUENCENO, E.NAMENO, A.EMPLOYEENO
				From #TEMPALERT T
				join ALERT A		on (A.EMPLOYEENO=@pnNewNameNo
							and A.ALERTSEQ  =T.NEWALERTSEQ)
				join EMPLOYEEREMINDER E	on (E.EMPLOYEENO =T.EMPLOYEENO
							and E.ALERTNAMENO=T.EMPLOYEENO
							and E.CASEID=A.CASEID
							and E.SEQUENCENO=A.SEQUENCENO )
				-- Avoid duplicate reminders
				left join EMPLOYEEREMINDER R	
							on (R.CASEID     =E.CASEID
							and R.EMPLOYEENO =A.EMPLOYEENO
							and(R.REFERENCE  =E.REFERENCE OR (R.REFERENCE is null and E.REFERENCE is null))
							and(R.EVENTNO    =E.EVENTNO   OR (R.EVENTNO   is null and E.EVENTNO   is null))
							and(R.CYCLENO    =E.CYCLENO   OR (R.CYCLENO   is null and E.CYCLENO   is null))
							and R.SEQUENCENO =E.SEQUENCENO
							and R.ALERTNAMENO=A.EMPLOYEENO )
				Where E.SOURCE=1
				and   R.CASEID is null"

				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnNewNameNo	int',
								  @pnNewNameNo=@pnNewNameNo
			End
				  
			If @ErrorCode=0
			Begin
				-----------------------------------
				-- Now delete the EMPLOYEEREMINDER
				-- just copied
				-----------------------------------
				Set @sSQLString="
				Delete E
				From #TEMPALERT T
				join ALERT A		on (A.EMPLOYEENO =@pnNewNameNo
							and A.ALERTSEQ   =T.NEWALERTSEQ)
				join EMPLOYEEREMINDER E	on (E.EMPLOYEENO =T.EMPLOYEENO
							and E.ALERTNAMENO=T.EMPLOYEENO
							and E.CASEID     =A.CASEID
							and E.SEQUENCENO =A.SEQUENCENO )
				join EMPLOYEEREMINDER N	on (N.EMPLOYEENO =A.EMPLOYEENO
							and N.MESSAGESEQ =A.ALERTSEQ
							and N.ALERTNAMENO=A.EMPLOYEENO
							and N.CASEID     =A.CASEID
							and N.SEQUENCENO =A.SEQUENCENO 
							and N.SOURCE     =1)
							
				Where E.SOURCE=1"

				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnNewNameNo	int',
								  @pnNewNameNo=@pnNewNameNo
			End
						  
			If @ErrorCode=0
			Begin
				-----------------------------------
				-- Now delete the ALERT rows that
				-- are still pointing to the old 
				-- name.
				-----------------------------------
				Set @sSQLString="
				Delete OLD
				From #TEMPALERT T
				join ALERT OLD	on (OLD.EMPLOYEENO=T.EMPLOYEENO
						and OLD.ALERTSEQ  =T.ALERTSEQ)
				join ALERT NEW	on (NEW.EMPLOYEENO=@pnNewNameNo
						and NEW.ALERTSEQ  =T.NEWALERTSEQ)"

				Exec @ErrorCode=sp_executesql @sSQLString,
								N'@pnNewNameNo	int',
								  @pnNewNameNo=@pnNewNameNo
			End
		End	-- @nAlertCount>0
	End		-- @pbAlerts=1		
End

-------------------------------------------------------------------------------------------
--
--	INSERT REQUEST PROCESSING
--
-------------------------------------------------------------------------------------------

If  @sInsertString is not NULL
and @pbInsertName=1
and @ErrorCode=0
Begin
	-- Load a temporary CASENAME table as an interim step.  This is required to allow a sequence to
	-- be generated.

	exec @ErrorCode=sp_executesql @sInsertString,
				N'@psNameType			nvarchar(3),
				  @pnNewNameNo			int,
				  @pnNewCorrespondName		int,
				  @pbNewInheritedFlag		bit,
				  @psPathNameType		nvarchar(3),
				  @pnPathNameNo			int,
				  @psPathRelationship		nvarchar(3),
				  @pnPathSequence		smallint,
				  @pnKeepReferenceNo		smallint,
				  @psReferenceNo		nvarchar(80),
				  @pdtCommenceDate		datetime,
				  @pnAddressCode		int,
				  @pnHomeNameNo			int',
				  @psNameType			=@psNameType,
				  @pnNewNameNo			=@pnNewNameNo,
				  @pnNewCorrespondName		=@pnNewCorrespondName,
				  @pbNewInheritedFlag		=@pbNewInheritedFlag,
				  @psPathNameType		=@psPathNameType,
				  @pnPathNameNo			=@pnPathNameNo,
				  @psPathRelationship		=@psPathRelationship,
				  @pnPathSequence		=@pnPathSequence,
				  @pnKeepReferenceNo		=@pnKeepReferenceNo,
				  @psReferenceNo		=@psReferenceNo,
				  @pdtCommenceDate		=@pdtCommenceDate,
				  @pnAddressCode		=@pnAddressCode,
				  @pnHomeNameNo			=@pnHomeNameNo
			
	If @ErrorCode=0
	Begin
		-- Increment the Sequence number on the #TEMPCASENAMES table for each row that has
		-- the same CASEID, NAMETYPE and NAMENO and reset to 1 on each control break
		-- 14023 - Sequence should only be unique for CASEID and NAMETYPE.
		Set @nCaseId=''

		Set @sSQLString="
		Update #TEMPCASENAMES
		Set 	@nSequence = 
			Case When (@nCaseId=CASEID and @sNameType=NAMETYPE)
				Then @nSequence + 1
				Else 1
			End,
			SEQUENCE = @nSequence,
			@nCaseId=CASEID,
			@sNameType=NAMETYPE"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nSequence	smallint,
					  @nCaseId	int,
					  @sNameType	nvarchar(3)',
					  @nSequence=@nSequence,
					  @nCaseId=@nCaseId,
					  @sNameType=@sNameType
	End

	-- Now load the CASENAME rows if they do not already exist
	If @ErrorCode=0
	Begin
		-- If the NameType being inserted requires the Bill Percentage to be set then ensure the percentage does
		-- not exceed 100 for the sum of all of the CASENAME rows for the case
		-- 8911 Use a local flag to indicate if bill percentage is to be included, and adjust sql accordingly.
		If exists (Select * from NAMETYPE where NAMETYPE=@psNameType and COLUMNFLAGS&64=64)
			Set @bIncludeBillPerc=1
		Else
			Set @bIncludeBillPerc=0

		-- 8911 Include new column DERIVEDCORRNAME.
		If @bIncludeBillPerc=1
			Set @sInsertString=
				"Insert into CASENAME (CASEID,NAMETYPE,NAMENO,SEQUENCE,ADDRESSCODE,CORRESPONDNAME,DERIVEDCORRNAME,INHERITED,INHERITEDNAMENO,INHERITEDRELATIONS,INHERITEDSEQUENCE,BILLPERCENTAGE,REFERENCENO,COMMENCEDATE)"
		Else
			Set @sInsertString=
				"Insert into CASENAME (CASEID,NAMETYPE,NAMENO,SEQUENCE,ADDRESSCODE,CORRESPONDNAME,DERIVEDCORRNAME,INHERITED,INHERITEDNAMENO,INHERITEDRELATIONS,INHERITEDSEQUENCE,REFERENCENO,COMMENCEDATE)"

		Set @sInsertString=@sInsertString+char(10)+
			"select distinct T.CASEID,T.NAMETYPE,T.NAMENO,"+char(10)+
			-- 14023 - Sequence should only be unique for CASEID and NAMETYPE.
			-- "	T.SEQUENCE+(select isnull(max(SEQUENCE),-1) from CASENAME CN1 where CN1.CASEID=T.CASEID and CN1.NAMETYPE=T.NAMETYPE and CN1.NAMENO=T.NAMENO),"+char(10)+
			"	T.SEQUENCE+(select isnull(max(SEQUENCE),-1) from CASENAME CN1 where CN1.CASEID=T.CASEID and CN1.NAMETYPE=T.NAMETYPE),"+char(10)+
			"	T.ADDRESSCODE,"+char(10)+
			-- 8911 Add derivation of Correspond Name
			-- 14023 Set to null if name type indicates attention is not used, except for instructor/agent.
			"	CASE WHEN (convert(bit,NT.COLUMNFLAGS&1)=0 and T.NAMETYPE not in ('I','A')) THEN null"+char(10)+
			"	     WHEN (T.CORRESPONDNAME is not null and (AN.CONTACT is null or T.CORRESPONDNAME<>AN.CONTACT)) THEN T.CORRESPONDNAME"+char(10)+
			"	     WHEN (AN.CONTACT is not null) THEN AN.CONTACT"+char(10)+
			-- 14172 Change logic so only select name main contact if site control is TRUE.
			"	     WHEN (SC.COLBOOLEAN=1) THEN N.MAINCONTACT"+char(10)+
			"	     WHEN (T.NAMETYPE in ('D','Z')) THEN ("+char(10)+
			"		    select	isnull( AN2.CONTACT, N2.MAINCONTACT )"+char(10)+
			"		    from NAME N2"+char(10)+
			"		    left join ASSOCIATEDNAME AN2 on ( AN2.NAMENO = N2.NAMENO"+char(10)+
			"					and AN2.RELATIONSHIP = 'BIL'"+char(10)+
			"					and AN2.CEASEDDATE is null"+char(10)+
			"					and AN2.NAMENO = AN2.RELATEDNAME )"+char(10)+
			"		    where N2.NAMENO = T.NAMENO)"+char(10)+
			"	     ELSE (select convert(int,substring("+char(10)+
			"			    min(CASE WHEN(AN1.PROPERTYTYPE is not null) THEN '0' ELSE '1' END+"+char(10)+
			"				CASE WHEN(AN1.COUNTRYCODE is not null)  THEN '0' ELSE '1' END+"+char(10)+
			"				CASE WHEN(AN1.RELATEDNAME=N1.MAINCONTACT)  THEN '0' ELSE '1' END+"+char(10)+
			"				replicate('0',6-datalength(convert(varchar(6),AN1.SEQUENCE)))+"+char(10)+
			"				convert(varchar(6),AN1.SEQUENCE)+"+char(10)+
			"				convert(varchar,AN1.RELATEDNAME)),10,19))"+char(10)+
			"		   from CASES C"+char(10)+
			"		   join NAME N1 on (N1.NAMENO=T.NAMENO)"+char(10)+
			"		   join ASSOCIATEDNAME AN1 on (AN1.NAMENO=N1.NAMENO"+char(10)+
			"		   				and AN1.RELATIONSHIP='EMP'"+char(10)+
			"		   				and AN1.CEASEDDATE is null"+char(10)+
			"		   				and (AN1.PROPERTYTYPE is not null"+char(10)+
			"		   					or AN1.COUNTRYCODE is not null"+char(10)+
			"		   					or AN1.RELATEDNAME=N1.MAINCONTACT)"+char(10)+
			"		   				and (AN.PROPERTYTYPE=C.PROPERTYTYPE or AN1.PROPERTYTYPE is null )"+char(10)+
			"		   				and (AN.COUNTRYCODE=C.COUNTRYCODE or AN1.COUNTRYCODE  is null ) )"+char(10)+
			"		   where C.CASEID=T.CASEID) END,"+char(10)+
			-- 14023 Set derived attention flag to 1 if name type indicates attention is not used, except for instructor/agent.
			"	CASE WHEN (convert(bit,NT.COLUMNFLAGS&1)=0 and T.NAMETYPE not in ('I','A')) THEN 1"+char(10)+
			"	     ELSE T.DERIVEDCORRNAME END,"+char(10)+
			"       CASE WHEN(T.INHERITEDNAMENO is not NULL) THEN 1 ELSE 0 END,"+char(10)+
			"	T.INHERITEDNAMENO,T.INHERITEDRELATIONS,T.INHERITEDSEQUENCE,"

		If @bIncludeBillPerc=1
			Set @sInsertString=@sInsertString+char(10)+
				"       100-isnull(P.TOTALPERCENTAGE,0),"+char(10)+"T.REFERENCENO, T.COMMENCEDATE"+char(10)+
				"from #TEMPCASENAMES T"+char(10)+
				-- this is used to get the total BILLPERCENTAGE value to ensure that the total
				-- does not exceed 100 percent
				"left join (select CASEID as CASEID, sum(isnull(BILLPERCENTAGE,0)) as TOTALPERCENTAGE"+char(10)+
				"           from CASENAME"+char(10)+
				"           where NAMETYPE=@psNameType"+char(10)+
				"           and (EXPIRYDATE is null or EXPIRYDATE>getdate())"+char(10)+
				"           group by CASEID) P on (P.CASEID=T.CASEID)"
		Else
			Set @sInsertString=@sInsertString+char(10)+
				"	T.REFERENCENO, T.COMMENCEDATE"+char(10)+
				"from #TEMPCASENAMES T"

		-- 14172 Move join on SITECONTROL out of imbedded select above, and add join to NAME for Main Contact.
		Set @sInsertString=@sInsertString+char(10)+
			"join NAME N on (N.NAMENO=T.NAMENO)"+char(10)+
			"join NAMETYPE NT on (NT.NAMETYPE=T.NAMETYPE)"+char(10)+
			"left join ASSOCIATEDNAME AN on (AN.NAMENO      =T.INHERITEDNAMENO"+char(10)+
			"                            and AN.RELATEDNAME =T.NAMENO"+char(10)+
			"                            and AN.RELATIONSHIP=T.INHERITEDRELATIONS"+char(10)+
			"                            and AN.SEQUENCE    =T.INHERITEDSEQUENCE)"+char(10)+
			"left join SITECONTROL SC on (SC.CONTROLID='Main Contact used as Attention')"+char(10)+
			"where not exists"+char(10)+
			"(select * from CASENAME CN"+char(10)+
			" where CN.CASEID=T.CASEID"+char(10)+
			" and   CN.NAMETYPE=T.NAMETYPE"+char(10)+
			" and   CN.NAMENO  =T.NAMENO"+char(10)+
			-- 8911 Replace 'CORRESPONDNAME is null' with 'DERIVEDCORRNAME=1'.
			" and  (CN.CORRESPONDNAME=T.CORRESPONDNAME OR (CN.DERIVEDCORRNAME=1 AND T.DERIVEDCORRNAME=1)))"

		-- Do not insert a CaseName row if the Billing Percentage is already 100 for the name type
		If @bIncludeBillPerc=1
			Set @sInsertString=@sInsertString+char(10)+
				"and isnull(P.TOTALPERCENTAGE,0)<100"

		exec @ErrorCode=sp_executesql @sInsertString,
					N'@psNameType	nvarchar(3)',
					  @psNameType=@psNameType

		Set @pnNamesInsertedCount=@@Rowcount
	End

	If @pbApplyInheritance = 1
	and @ErrorCode = 0
	Begin
		--------------------------------------------------------------------------
		-- DR-46214
		-- Need to check the CASENAME rows that have inheritance rules.  If the
		-- CASENAME is not showing any Inheritance pointers however the actual
		-- data matches what would have inherited based on the rules then set the
		-- pointers.
		-- This situation might arise where a global name change is issued for a 
		-- NameType to explicitly assign a Name against a Case even though the 
		-- Name is exactly what would have inherited down to the Case.
		--------------------------------------------------------------------------

		Set @sCorrectParentsString=
		"Update CASENAME"+char(10)+
		"Set INHERITED         =1,"+char(10)+
		"    INHERITEDNAMENO   =isnull(XN.PARENTNAMENO,XN.NAMENO),"+char(10)+
		"    INHERITEDRELATIONS=XN.RELATIONSHIP,"+char(10)+
		"    INHERITEDSEQUENCE =XN.SEQUENCE"+char(10)+
		"from CASENAME CN"+char(10)+
		"join #TEMPCASENAMES T on (T.CASEID=CN.CASEID and T.NAMETYPE=CN.NAMETYPE and T.NAMENO=CN.NAMENO)"+char(10)+
		"join CASES C     on (C.CASEID=CN.CASEID)"+char(10)+
		"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
		"join (	select 	CN.CASEID, CN.NAMENO, CN.NAMETYPE,"+char(10)+
		"		isnull(AN.NAMENO, AN1.NAMENO) as PARENTNAMENO,"+char(10)+
		"		isnull(AN.RELATIONSHIP, AN1.RELATIONSHIP) as RELATIONSHIP,"+char(10)+
		"		CASE WHEN(AN.NAMENO is not null) THEN AN.RELATEDNAME  ELSE AN1.RELATEDNAME  END as RELATEDNAME,"+char(10)+
		"		CASE WHEN(AN.NAMENO is not null) THEN AN.SEQUENCE     ELSE AN1.SEQUENCE     END as [SEQUENCE],"+char(10)+
		"		CASE WHEN(AN.NAMENO is not null) THEN AN.PROPERTYTYPE ELSE AN1.PROPERTYTYPE END as PROPERTYTYPE,"+char(10)+
		"		CASE WHEN(AN.NAMENO is not null) THEN AN.COUNTRYCODE  ELSE AN1.COUNTRYCODE  END as COUNTRYCODE"+char(10)+
		"	from NAMETYPE NT"+char(10)+
		"	join CASENAME CN 	on (CN.NAMETYPE=NT.PATHNAMETYPE"+char(10)+
		"			 	and CN.EXPIRYDATE is null)"+char(10)+
		"	join CASES C	 	on (C.CASEID=CN.CASEID)"+char(10)+
		"	left join ASSOCIATEDNAME AN on (AN.NAMENO      =CN.NAMENO"+char(10)+
		"				    and AN.RELATIONSHIP=NT.PATHRELATIONSHIP"+char(10)+
		"				    and(AN.PROPERTYTYPE=C.PROPERTYTYPE or AN.PROPERTYTYPE is null)"+char(10)+
		"				    and(AN.COUNTRYCODE =C.COUNTRYCODE  or AN.COUNTRYCODE  is null)"+char(10)+
		"				    and(AN.CEASEDDATE is null or AN.CEASEDDATE>getdate()))"+char(10)+
		"	left join ASSOCIATEDNAME AN1 on (AN1.NAMENO      =@pnHomeNameNo"+char(10)+
		"				     and AN.NAMENO is null"+char(10)+	-- inherit from Home Name only if
		"				     and NT.USEHOMENAMEREL=1"+char(10)+	-- NameType allows and Path Name not found 
		"				     and AN1.RELATIONSHIP=NT.PATHRELATIONSHIP"+char(10)+
		"				     and(AN1.PROPERTYTYPE=C.PROPERTYTYPE or AN1.PROPERTYTYPE is null)"+char(10)+
		"				     and(AN1.COUNTRYCODE =C.COUNTRYCODE  or AN1.COUNTRYCODE  is null)"+char(10)+
		"				     and(AN1.CEASEDDATE is null or AN1.CEASEDDATE>getdate()))"+char(10)+
		"	Where (isnull(NT.HIERARCHYFLAG,0)=0 and isnull(AN.RELATIONSHIP,AN1.RELATIONSHIP) is not null)"+char(10)+
		"	or NT.HIERARCHYFLAG=1 ) XN"+char(10)+
		"			on (XN.CASEID=C.CASEID"+char(10)+
		"			and XN.NAMETYPE=NT.PATHNAMETYPE"+char(10)+
		"			and(XN.RELATIONSHIP=NT.PATHRELATIONSHIP or (XN.RELATIONSHIP is null and NT.PATHRELATIONSHIP is null)))"+char(10)+
		"where CN.INHERITEDNAMENO is null"+char(10)+
		"and CN.NAMETYPE=@psNameType"+char(10)+
		"and CN.NAMENO=CASE WHEN(NT.HIERARCHYFLAG=1) THEN isnull(XN.RELATEDNAME, XN.NAMENO) ELSE XN.RELATEDNAME END"+char(10)+
		"and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())"+char(10)+
		-- this calculates the bestfit value of the current AssociatedName row
		-- and ensures it matches the best fit value for the specific case.
		"and (XN.RELATEDNAME is null"+char(10)+
		" or (CASE WHEN(XN.PROPERTYTYPE is null) THEN '0' ELSE '1' END +"+char(10)+
		"     CASE WHEN(XN.COUNTRYCODE  is null) THEN '0' ELSE '1' END)"+char(10)+
		"      = (select max(CASE WHEN(AN1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +"+char(10)+
		"                    CASE WHEN(AN1.COUNTRYCODE  is null) THEN '0' ELSE '1' END )"+char(10)+
		"         from ASSOCIATEDNAME AN1"+char(10)+
		"         where AN1.NAMENO=XN.PARENTNAMENO"+char(10)+ 
		"         and  AN1.RELATIONSHIP=XN.RELATIONSHIP"+char(10)+
		"         and (AN1.CEASEDDATE is null OR AN1.CEASEDDATE>getdate())"+char(10)+
		"         and (AN1.PROPERTYTYPE=C.PROPERTYTYPE or AN1.PROPERTYTYPE is null)"+char(10)+
		"         and (AN1.COUNTRYCODE =C.COUNTRYCODE  or AN1.COUNTRYCODE  is null)))"

		Exec @ErrorCode=sp_executesql @sCorrectParentsString,
						N'@psNameType	nvarchar(3),
						  @pnHomeNameNo	int',
						  @psNameType=@psNameType,
						  @pnHomeNameNo=@pnHomeNameNo
	End
End

-------------------------------------------------------------------------------------------
--
--	DELETE REQUEST PROCESSING
--
-------------------------------------------------------------------------------------------

If  @pbDeleteName=1
and @sDeleteString is not NULL
and @ErrorCode=0
Begin
	-- Remove some code not required at this point
	set @sDeletedCasesString=replace(@sDeletedCasesString,' OR CN.NAMENO<>N.NAMENO)',')')	--SQA17878
	set @sDeleteString      =replace(@sDeleteString,      ' OR CN.NAMENO<>N.NAMENO)',')')	--SQA17878
	
	-- Insert a row into a temporary table to keep track of each CASEID and NAMETYPE combination deleted
	-- The contents of the temporary table will later be used to determine any Policing required for 
	-- potential standing instruction changes
	exec(@sDeletedCasesString)
	Set @ErrorCode=@@Error
	
	exec(@sDeleteString)

	Select @ErrorCode=@@Error,
	       @pnNamesDeletedCount=@@Rowcount
End

-------------------------------------------------------------------------------------------
--
--	CORRECTION OF PARENTAGE POINTERS
--
-------------------------------------------------------------------------------------------

If  @pbApplyInheritance=1
and @psNameType is not null
and @ErrorCode=0
Begin		
	-- Need to check the CASENAME rows that have inheritance rules.  If the
	-- CASENAME is not showing any Inheritance pointers however the actual
	-- data matches what would have inherited based on the rules then set the
	-- pointers.
	-- This situation might arise where a global name change is issued for a 
	-- NameType to explicitly assign a Name against a Case even though the 
	-- Name is exactly what would have inherited down to the Case.

	Set @sCorrectParentsString=
	"Update CASENAME"+char(10)+
	"Set INHERITED         =1,"+char(10)+
	"    INHERITEDNAMENO   =isnull(XN.PARENTNAMENO,XN.NAMENO),"+char(10)+
	"    INHERITEDRELATIONS=XN.RELATIONSHIP,"+char(10)+
	"    INHERITEDSEQUENCE =XN.SEQUENCE"+char(10)+
	"from CASENAME CN"+char(10)+
	"join "+@psGlobalTempTable+" T on (T.CASEID=CN.CASEID)"+char(10)+
	"join CASES C     on (C.CASEID=CN.CASEID)"+char(10)+
	"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
	"join (	select 	CN.CASEID, CN.NAMENO, CN.NAMETYPE,"+char(10)+
	"		isnull(AN.NAMENO, AN1.NAMENO) as PARENTNAMENO,"+char(10)+
	"		isnull(AN.RELATIONSHIP, AN1.RELATIONSHIP) as RELATIONSHIP,"+char(10)+
	"		CASE WHEN(AN.NAMENO is not null) THEN AN.RELATEDNAME  ELSE AN1.RELATEDNAME  END as RELATEDNAME,"+char(10)+
	"		CASE WHEN(AN.NAMENO is not null) THEN AN.SEQUENCE     ELSE AN1.SEQUENCE     END as [SEQUENCE],"+char(10)+
	"		CASE WHEN(AN.NAMENO is not null) THEN AN.PROPERTYTYPE ELSE AN1.PROPERTYTYPE END as PROPERTYTYPE,"+char(10)+
	"		CASE WHEN(AN.NAMENO is not null) THEN AN.COUNTRYCODE  ELSE AN1.COUNTRYCODE  END as COUNTRYCODE"+char(10)+
	"	from NAMETYPE NT"+char(10)+
	"	join CASENAME CN 	on (CN.NAMETYPE=NT.PATHNAMETYPE"+char(10)+
	"			 	and CN.EXPIRYDATE is null)"+char(10)+
	"	join CASES C	 	on (C.CASEID=CN.CASEID)"+char(10)+
	"	left join ASSOCIATEDNAME AN on (AN.NAMENO      =CN.NAMENO"+char(10)+
	"				    and AN.RELATIONSHIP=NT.PATHRELATIONSHIP"+char(10)+
	"				    and(AN.PROPERTYTYPE=C.PROPERTYTYPE or AN.PROPERTYTYPE is null)"+char(10)+
	"				    and(AN.COUNTRYCODE =C.COUNTRYCODE  or AN.COUNTRYCODE  is null)"+char(10)+
	"				    and(AN.CEASEDDATE is null or AN.CEASEDDATE>getdate()))"+char(10)+
	"	left join ASSOCIATEDNAME AN1 on (AN1.NAMENO      =@pnHomeNameNo"+char(10)+
	"				     and AN.NAMENO is null"+char(10)+	-- inherit from Home Name only if
	"				     and NT.USEHOMENAMEREL=1"+char(10)+	-- NameType allows and Path Name not found 
	"				     and AN1.RELATIONSHIP=NT.PATHRELATIONSHIP"+char(10)+
	"				     and(AN1.PROPERTYTYPE=C.PROPERTYTYPE or AN1.PROPERTYTYPE is null)"+char(10)+
	"				     and(AN1.COUNTRYCODE =C.COUNTRYCODE  or AN1.COUNTRYCODE  is null)"+char(10)+
	"				     and(AN1.CEASEDDATE is null or AN1.CEASEDDATE>getdate()))"+char(10)+
	"	Where (isnull(NT.HIERARCHYFLAG,0)=0 and isnull(AN.RELATIONSHIP,AN1.RELATIONSHIP) is not null)"+char(10)+
	"	or NT.HIERARCHYFLAG=1 ) XN"+char(10)+
	"			on (XN.CASEID=C.CASEID"+char(10)+
	"			and XN.NAMETYPE=NT.PATHNAMETYPE"+char(10)+
	"			and(XN.RELATIONSHIP=NT.PATHRELATIONSHIP or (XN.RELATIONSHIP is null and NT.PATHRELATIONSHIP is null)))"+char(10)+
	"where CN.INHERITEDNAMENO is null"+char(10)+
	"and CN.NAMETYPE=@psNameType"+char(10)+
	"and CN.NAMENO=CASE WHEN(NT.HIERARCHYFLAG=1) THEN isnull(XN.RELATEDNAME, XN.NAMENO) ELSE XN.RELATEDNAME END"+char(10)+
	"and(CN.EXPIRYDATE is null or CN.EXPIRYDATE>getdate())"+char(10)+
	-- this calculates the bestfit value of the current AssociatedName row
	-- and ensures it matches the best fit value for the specific case.
	"and (XN.RELATEDNAME is null"+char(10)+
	" or (CASE WHEN(XN.PROPERTYTYPE is null) THEN '0' ELSE '1' END +"+char(10)+
	"     CASE WHEN(XN.COUNTRYCODE  is null) THEN '0' ELSE '1' END)"+char(10)+
	"      = (select max(CASE WHEN(AN1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +"+char(10)+
	"                    CASE WHEN(AN1.COUNTRYCODE  is null) THEN '0' ELSE '1' END )"+char(10)+
	"         from ASSOCIATEDNAME AN1"+char(10)+
	"         where AN1.NAMENO=XN.PARENTNAMENO"+char(10)+ 
	"         and  AN1.RELATIONSHIP=XN.RELATIONSHIP"+char(10)+
	"         and (AN1.CEASEDDATE is null OR AN1.CEASEDDATE>getdate())"+char(10)+
	"         and (AN1.PROPERTYTYPE=C.PROPERTYTYPE or AN1.PROPERTYTYPE is null)"+char(10)+
	"         and (AN1.COUNTRYCODE =C.COUNTRYCODE  or AN1.COUNTRYCODE  is null)))"

	Exec @ErrorCode=sp_executesql @sCorrectParentsString,
					N'@psNameType	nvarchar(3),
					  @pnHomeNameNo	int',
					  @psNameType=@psNameType,
					  @pnHomeNameNo=@pnHomeNameNo
End
-------------------------------------------------------------------------------------------
--
--	CLEAN UP PROCESSING
--
-------------------------------------------------------------------------------------------

-- Update the global temporary table to indicate that the Case has been modified.

If @ErrorCode=0
and exists(SELECT * FROM tempdb.INFORMATION_SCHEMA.COLUMNS 
	   WHERE TABLE_NAME = @sGlobalTempTableCentura
	   AND COLUMN_NAME = 'ISMODIFIED')
Begin
	Set @sSQLString="Update "+@sGlobalTempTableCentura+char(10)+
			"Set ISMODIFIED=1"+char(10)+
			"From "+@sGlobalTempTableCentura+" T"+char(10)+
			"join #TEMPUPDATESANDDELETES C on (C.CASEID=T.CASEID)"+char(10)+
			"Where isnull(T.ISMODIFIED,0)=0"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Keep track of each distinct CaseId, NameType processed
-- throughout the entire global name change. This
-- will later be used to determine if any Standing
-- Instructions have changed requiring Policing
-- to recalculate events.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into dbo.#TEMPGLOBALCASENAMES (CASEID, NAMETYPE, NAMENO)
	select distinct T.CASEID, T.NAMETYPE, T.NAMENO
	from dbo.#TEMPCASENAMES T
	left join dbo.#TEMPGLOBALCASENAMES G	on (G.CASEID  =T.CASEID
						and G.NAMETYPE=T.NAMETYPE
						and G.NAMENO  =T.NAMENO)
	where G.CASEID is null"
	
	exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into dbo.#TEMPGLOBALUPDATESANDDELETES (CASEID, NAMETYPE)
	select distinct T.CASEID, T.NAMETYPE
	from dbo.#TEMPUPDATESANDDELETES T
	left join dbo.#TEMPGLOBALUPDATESANDDELETES G	on (G.CASEID  =T.CASEID
							and G.NAMETYPE=T.NAMETYPE)
	where G.CASEID is null"
	
	exec @ErrorCode=sp_executesql @sSQLString
End		

-- Drop the temporary tables so as not to conflict when the
-- procedure is called recursively.

If @ErrorCode=0
Begin
	drop table dbo.#TEMPCASENAMES
	drop table dbo.#TEMPUPDATESANDDELETES
End 

-- Commit the transaction if it has successfully completed

If @@TranCount > @TranCountStart
Begin
	If @ErrorCode = 0
		COMMIT TRANSACTION
	Else
		ROLLBACK TRANSACTION
End

-------------------------------------------------------------------------------------------
--
--	RECURSIVE CALLS FOR INHERITANCE
--
-------------------------------------------------------------------------------------------

-- We need to determine if the NameType that has just been globally changed will have 
-- an impact on other inherited Names against the same Cases. This only occurs if the 
-- user has explicitly requested inheritance rules to apply.

If  @pbApplyInheritance=1
and @ErrorCode=0
Begin
	-- In order for inheritance to effectively work the
	-- insert name flag must be turned on
	set @pbInsertName=1

	-- Set the parameter that indicates that the Name updates are to be flagged
	-- as inherited names.

	Set @pbNewInheritedFlag=1

	-- For the NameType just updated we need to get a list of any other NameTypes
	-- that may be affected by the change and for each of these NameTypes another
	-- global change may occur.

	-- NOTE : The looping technique used is to avoid the use of inefficient CURSORS

	Set @sSQLString="
	select @sInheritedNameType =
		min(	convert(nchar(3), NT.NAMETYPE)+ 
			convert(nchar(3), isnull(NT.PATHRELATIONSHIP, space(3)))+ 
			convert(nchar(1), isnull(NT.HIERARCHYFLAG,    0))+
			convert(nchar(1), isnull(NT.USEHOMENAMEREL,   0))+
			convert(nchar(11),NT.DEFAULTNAMENO))
	from NAMETYPE NT
	Where NT.PATHNAMETYPE=@psNameType
	and exists
	(select 1 from #TEMPCASENAMETYPES T
	 where T.NAMETYPE=NT.NAMETYPE)"

	exec @ErrorCode=sp_executesql @sSQLString, 
				N'@sInheritedNameType	nvarchar(19) OUTPUT,
				  @psNameType		nvarchar(3)',
				  @sInheritedNameType=@sInheritedNameType OUTPUT,
				  @psNameType        =@psNameType

	-- Now loop through each NameType returned so that a global Name Change can be applied.
	
	While @sInheritedNameType is not NULL
	and @ErrorCode=0
	Begin
		-- Extract the components of the inherited NameType that were previously
		-- concatenated together.

		set @sNextNameType	= rtrim(substring(@sInheritedNameType, 1,3))
		set @sPathRelationship	= rtrim(substring(@sInheritedNameType, 4,3))
		set @bHierarchyFlag	= convert(bit, substring(@sInheritedNameType, 7,1))
		set @bUseHomeNameRel	= convert(bit, substring(@sInheritedNameType, 8,1))

		--SQA16176 Test the DefaultNameNo is numeric before converting
		If isnumeric(substring(@sInheritedNameType, 9,11))=1
			set @nDefaultNameNo = convert(int, substring(@sInheritedNameType, 9,11))
		else
			set @nDefaultNameNo = null

		-- If no Path Relationship has been specified then perform a global
		-- change using the same Name as in the parent NameType.
		-- This is a recursive call of the stored procedure.

		If @sPathRelationship is NULL
		OR @sPathRelationship = space(3)
		Begin
			-- 13785 Use default name if it is not null, otherwise the current name.
			If @nDefaultNameNo is NULL
			OR @nDefaultNameNo = 0
				set @nDefaultNameNo = @pnNewNameNo

			exec @ErrorCode=dbo.cs_GlobalNameChange
							@pnNamesUpdatedCount =@nUpdates output,
							@pnNamesInsertedCount=@nInserts output,
							@pnNamesDeletedCount =@nDeletes output,
							@pnUserIdentityId    =@pnUserIdentityId,
							@psCulture           =@psCulture,
							@psGlobalTempTable   =@psGlobalTempTable,
							@psNameType          =@sNextNameType,
							@pnNewNameNo         =@nDefaultNameNo,		-- 13785 Use default name.
							@pnNewCorrespondName =@pnNewCorrespondName,
							@pbNewInheritedFlag  =@pbNewInheritedFlag,
							@psPathNameType      =@psNameType,
							@pnPathNameNo        =@pnNewNameNo,
							@pbUpdateName        =@pbUpdateName,
							@pbInsertName        =@pbInsertName,
							@pbKeepCorrespondName=@pbKeepCorrespondName,
							@pnKeepReferenceNo   =@pnKeepReferenceNo,
							@pbApplyInheritance  =1,
							@psReferenceNo	     =@psReferenceNo,
							@pdtCommenceDate     =@pdtCommenceDate,
							@pnAddressCode       =@pnAddressCode,
							@pnHomeNameNo	     =@pnHomeNameNo,
							@pnBatchNo	     =@pnBatchNo,
							@pnTransNo	     =@pnTransNo,
							@pnTransReasonNo     =@pnTransReasonNo,
							@pbForceInheritance  =@pbForceInheritance,
							@pbAlerts	     =0				-- Alerts do not need to be checked on recursive calls

			If @ErrorCode=0
			Begin
				Set @pnNamesUpdatedCount =@pnNamesUpdatedCount +@nUpdates
				Set @pnNamesInsertedCount=@pnNamesInsertedCount+@nInserts
				Set @pnNamesDeletedCount =@pnNamesDeletedCount +@nDeletes
			End
		End
		Else Begin
			-- If a Path Relationship has been defined to be used in inheritance
			-- then we need to get each of the associated Names of this relationship to 
			-- apply the change.
			-- This requires another loop through all of the possible AssociatedNames 
			-- for the given relationship
			-- SQA12317
			-- If the flag to use the Home Name is on then attempt to get the 
			-- related name from the Home Name if there is no specific related name
			-- found.
			
			-- NOTE : The looping technique used is to avoid the use of inefficient CURSORS

			Set @sSQLString="
			select @sAssociatedName =
				min(	AN.NAMEFLAG+
					convert(nchar(11), AN.NAMENO) +
					convert(nchar(11), AN.RELATEDNAME)+ 
					convert(nchar(6),  AN.SEQUENCE)+ 
					CASE WHEN(AN.CONTACT is null) THEN space(11) ELSE convert(nchar(11),AN.CONTACT) END)
			from (	select '1' as NAMEFLAG, A.NAMENO, A.RELATEDNAME, A.SEQUENCE, A.CONTACT, A.PROPERTYTYPE, A.COUNTRYCODE
				from ASSOCIATEDNAME A
				join NAMETYPE NT	on (NT.NAMETYPE=@sNextNameType)
				-- RFC9969
				-- Ensure Name to inherit is allowed to be used as NameType
				join NAMETYPECLASSIFICATION NTC
							on (NTC.NAMENO  =A.RELATEDNAME
							and NTC.NAMETYPE=CASE WHEN((NT.PICKLISTFLAGS & 16) =  16) THEN NT.NAMETYPE ELSE '~~~' END
							and NTC.ALLOW   =1)
				where A.NAMENO=@pnNewNameNo
				and A.RELATIONSHIP=@sPathRelationship
				and (A.CEASEDDATE is null or A.CEASEDDATE>getdate())
				UNION
				select '0',A1.NAMENO, A1.RELATEDNAME, A1.SEQUENCE, A1.CONTACT, A1.PROPERTYTYPE, A1.COUNTRYCODE
				from ASSOCIATEDNAME A1
				join NAMETYPE NT	on (NT.NAMETYPE=@sNextNameType)
				-- RFC9969
				-- Ensure Name to inherit is allowed to be used as NameType
				join NAMETYPECLASSIFICATION NTC1
							on (NTC1.NAMENO  =A1.RELATEDNAME
							and NTC1.NAMETYPE=CASE WHEN((NT.PICKLISTFLAGS & 16) =  16) THEN NT.NAMETYPE ELSE '~~~' END
							and NTC1.ALLOW   =1)
				left join ASSOCIATEDNAME A2	
							on (A2.NAMENO=@pnNewNameNo
							and A2.RELATIONSHIP=@sPathRelationship
							and(A2.PROPERTYTYPE=A1.PROPERTYTYPE or(A2.PROPERTYTYPE is null and A1.PROPERTYTYPE is null))
							and(A2.COUNTRYCODE =A1.COUNTRYCODE  or(A2.COUNTRYCODE  is null and A1.COUNTRYCODE  is null))
							and(A2.CEASEDDATE is null or A2.CEASEDDATE>getdate()) )
				left join NAMETYPECLASSIFICATION NTC2
							on (NTC2.NAMENO  =A2.RELATEDNAME
							and NTC2.NAMETYPE=CASE WHEN((NT.PICKLISTFLAGS & 16) =  16) THEN NT.NAMETYPE ELSE '~~~' END
							and NTC2.ALLOW   =1)
				where A1.NAMENO=@pnHomeNameNo
				and A1.RELATIONSHIP=@sPathRelationship
				and (A1.CEASEDDATE is null or A1.CEASEDDATE>getdate())
				and NTC2.NAMENO is null
				and @bUseHomeNameRel=1 ) AN
			where exists
			(select 1 from "+@psGlobalTempTable+" T
			 join CASES C on (C.CASEID=T.CASEID)
			 where (C.PROPERTYTYPE=AN.PROPERTYTYPE or AN.PROPERTYTYPE is null)
			 and   (C.COUNTRYCODE =AN.COUNTRYCODE  or AN.COUNTRYCODE  is null) )"

			exec @ErrorCode=sp_executesql @sSQLString, 
						N'@sAssociatedName	nvarchar(40) OUTPUT,
						  @pnNewNameNo		int,
						  @sPathRelationship	nvarchar(3),
						  @bUseHomeNameRel	bit,
						  @pnHomeNameNo		int,
						  @sNextNameType	nvarchar(3)',
						  @sAssociatedName  =@sAssociatedName OUTPUT,
						  @pnNewNameNo      =@pnNewNameNo,
						  @sPathRelationship=@sPathRelationship,
						  @bUseHomeNameRel  =@bUseHomeNameRel,
						  @pnHomeNameNo     =@pnHomeNameNo,
						  @sNextNameType    =@sNextNameType

			-- For the first Associated Name processed
			-- removal of orphan inherited names is allowed
			Set @pbRemoveOrphans=1

			-- If there are no associated Names however the rule for the NameType indicates
			-- that the Path Name is to be used then apply a global name change using the
			-- Name attached to the Path Name Type.

			If @sAssociatedName is null
			and @ErrorCode=0
			Begin
				-- If the flag that indicates that the parent name is to be used
				-- is turned off then we still need to call cs_GlobalNameChange 
				-- recursively but with no NewNamenNo so as to ensure that any
				-- inherited child name types are removed.
				-- 13785 Use default name if not null and hierarchy flag not set.
				-- 14023 Can only propagate new attention name if same name.
				If @bHierarchyFlag=1
					    --------------------------------
					    -- RFC56369
					    -- Check that the parent name is 
					    -- allowed to be used for the 
					    -- next name type.
					    --------------------------------
				and exists (select 1
					    from NAMETYPE NT
					    join NAMETYPECLASSIFICATION NTC
							on (NTC.NAMENO  =@pnNewNameNo
							and NTC.NAMETYPE=CASE WHEN((NT.PICKLISTFLAGS & 16) =  16) THEN NT.NAMETYPE ELSE '~~~' END
							and NTC.ALLOW   =1)
					    where NT.NAMETYPE=@sNextNameType)
				Begin
					set @nInheritNameNo=@pnNewNameNo
					set @nNewCorrespondName=@pnNewCorrespondName
				End
				Else If @nDefaultNameNo is not NULL AND @nDefaultNameNo != 0
				Begin
					set @nInheritNameNo=@nDefaultNameNo
					set @nNewCorrespondName=null
				End
				Else
				Begin
					set @nInheritNameNo=null
					set @nNewCorrespondName=null
				End
				----------------------------------------------------
				-- The Global Name Change must either be called with
				-- an inherited NameNo or the NameType is not set as
				-- mandatory. This is to avoid removing a Name that
				-- is mandatory.
				----------------------------------------------------
				If @nInheritNameNo is not null
				OR not exists(select 1
				              from NAMETYPE
				              where NAMETYPE=@sNextNameType
				              and   MANDATORYFLAG=1)
				Begin
					exec @ErrorCode=dbo.cs_GlobalNameChange
								@pnNamesUpdatedCount =@nUpdates output,
								@pnNamesInsertedCount=@nInserts output,
								@pnNamesDeletedCount =@nDeletes output,
								@pnUserIdentityId    =@pnUserIdentityId,
								@psCulture           =@psCulture,
								@psGlobalTempTable   =@psGlobalTempTable,
								@psNameType          =@sNextNameType,
								@pnNewNameNo         =@nInheritNameNo,
								@pnNewCorrespondName =@nNewCorrespondName,
								@pbNewInheritedFlag  =@pbNewInheritedFlag,
								@psPathNameType      =@psNameType,
								@pnPathNameNo        =@pnNewNameNo,
								-- 8911 Don't include path relationship as not relevant
								--	if associated name is null.
								-- @psPathRelationship  =@psPathRelationship,
								@pnPathSequence      =@pnPathSequence,
								@pbUpdateName        =@pbUpdateName,
								@pbInsertName        =@pbInsertName,
								@pbKeepCorrespondName=@pbKeepCorrespondName,
								@pnKeepReferenceNo   =@pnKeepReferenceNo,
								@pbApplyInheritance  =1,
								@psReferenceNo	     =@psReferenceNo,
								@pdtCommenceDate     =@pdtCommenceDate,
								@pnAddressCode       =@pnAddressCode,
								@pnHomeNameNo	     =@pnHomeNameNo,
								@pnBatchNo	     =@pnBatchNo,
								@pnTransNo	     =@pnTransNo,
								@pnTransReasonNo     =@pnTransReasonNo,
								@pbForceInheritance  =@pbForceInheritance,
								@pbRemoveOrphans     =@pbRemoveOrphans,
								@pbAlerts	     =0				-- Alerts do not need to be checked on recursive calls
					If @ErrorCode=0
					Begin
						Set @pnNamesUpdatedCount =@pnNamesUpdatedCount +@nUpdates
						Set @pnNamesInsertedCount=@pnNamesInsertedCount+@nInserts
						Set @pnNamesDeletedCount =@pnNamesDeletedCount +@nDeletes
						
						Set @pbRemoveOrphans=0
					End
				End
			End

		
			-- Now loop through each Associated Name returned so that a global Name Change can be applied.
			
			While @sAssociatedName is not NULL
			and @ErrorCode=0
			Begin

				-- Extract the components of the Associated Name that were previously
				-- concatenated together.

				set @nParentNameNo=convert(     int,substring(@sAssociatedName, 2,11))
				set @nRelatedName =convert(     int,substring(@sAssociatedName,13,11))		
				set @nRelatedSeq  =convert(smallint,substring(@sAssociatedName, 24,6))
				set @nContact	  =CASE WHEN(ISNUMERIC(substring(@sAssociatedName,30,11))=1) 
							THEN convert(int,substring(@sAssociatedName,29,11))
							ELSE NULL
						   END

				exec @ErrorCode=dbo.cs_GlobalNameChange
								@pnNamesUpdatedCount =@nUpdates output,
								@pnNamesInsertedCount=@nInserts output,
								@pnNamesDeletedCount =@nDeletes output,
								@pnUserIdentityId    =@pnUserIdentityId,
								@psCulture           =@psCulture,
								@psGlobalTempTable   =@psGlobalTempTable,
								@psNameType          =@sNextNameType,
								@pnNewNameNo         =@nRelatedName,
								@pnNewCorrespondName =@nContact,
								@pbUpdateName        =@pbUpdateName,
								@pbInsertName        =@pbInsertName,
								@pbNewInheritedFlag  =@pbNewInheritedFlag,
								@pbKeepCorrespondName=@pbKeepCorrespondName,
								@pnKeepReferenceNo   =2,
								@pbApplyInheritance  =1,
								@psPathNameType      =@psNameType,
								@pnPathNameNo        =@nParentNameNo,
								@psPathRelationship  =@sPathRelationship,
								@pnPathSequence      =@nRelatedSeq,
								@psReferenceNo	     =@psReferenceNo,
								@pdtCommenceDate     =@pdtCommenceDate,
								@pnAddressCode       =null,
								@pnHomeNameNo	     =@pnHomeNameNo,
								@pnBatchNo	     =@pnBatchNo,
								@pnTransNo	     =@pnTransNo,
								@pnTransReasonNo     =@pnTransReasonNo,
								@pbForceInheritance  =@pbForceInheritance,
								@pbRemoveOrphans     =@pbRemoveOrphans,
								@pbAlerts	     =0				-- Alerts do not need to be checked on recursive calls
				If @ErrorCode=0
				Begin
					Set @pnNamesUpdatedCount =@pnNamesUpdatedCount +@nUpdates
					Set @pnNamesInsertedCount=@pnNamesInsertedCount+@nInserts
					Set @pnNamesDeletedCount =@pnNamesDeletedCount +@nDeletes
					
					Set @pbRemoveOrphans=0
				End

				-- Now get the next Associated Name
				If @ErrorCode=0
				Begin					
					Set @sSQLString="
					select @sAssociatedNameOUT =
							min(	AN.NAMEFLAG+
								convert(nchar(11), AN.NAMENO) +
								convert(nchar(11), AN.RELATEDNAME)+ 
								convert(nchar(6),  AN.SEQUENCE)+ 
								CASE WHEN(AN.CONTACT is null) THEN space(11) ELSE convert(nchar(11),AN.CONTACT) END)
					from (	select '1' as NAMEFLAG, A.NAMENO, A.RELATEDNAME, A.SEQUENCE, A.CONTACT, A.PROPERTYTYPE, A.COUNTRYCODE
						from ASSOCIATEDNAME A
						join NAMETYPE NT	on (NT.NAMETYPE=@sNextNameType)
						-- RFC9969
						-- Ensure Name to inherit is allowed to be used as NameType
						join NAMETYPECLASSIFICATION NTC
									on (NTC.NAMENO  =A.RELATEDNAME
									and NTC.NAMETYPE=CASE WHEN((NT.PICKLISTFLAGS & 16) =  16) THEN NT.NAMETYPE ELSE '~~~' END
									and NTC.ALLOW   =1)
						where A.NAMENO=@pnNewNameNo
						and A.RELATIONSHIP=@sPathRelationship
						and (A.CEASEDDATE is null or A.CEASEDDATE>getdate())
						UNION
						select '0',A1.NAMENO, A1.RELATEDNAME, A1.SEQUENCE, A1.CONTACT, A1.PROPERTYTYPE, A1.COUNTRYCODE
						from ASSOCIATEDNAME A1
						join NAMETYPE NT	on (NT.NAMETYPE=@sNextNameType)
						-- RFC9969
						-- Ensure Name to inherit is allowed to be used as NameType
						join NAMETYPECLASSIFICATION NTC
									on (NTC.NAMENO  =A1.RELATEDNAME
									and NTC.NAMETYPE=CASE WHEN((NT.PICKLISTFLAGS & 16) =  16) THEN NT.NAMETYPE ELSE '~~~' END
									and NTC.ALLOW   =1)
						left join ASSOCIATEDNAME A2	
									on (A2.NAMENO=@pnNewNameNo
									and A2.RELATIONSHIP=@sPathRelationship
									and(A2.PROPERTYTYPE=A1.PROPERTYTYPE or(A2.PROPERTYTYPE is null and A1.PROPERTYTYPE is null))
									and(A2.COUNTRYCODE =A1.COUNTRYCODE  or(A2.COUNTRYCODE  is null and A1.COUNTRYCODE  is null))
									and(A2.CEASEDDATE is null or A2.CEASEDDATE>getdate()) )
						join NAMETYPECLASSIFICATION NTC2
									on (NTC2.NAMENO  =A2.RELATEDNAME
									and NTC2.NAMETYPE=CASE WHEN((NT.PICKLISTFLAGS & 16) =  16) THEN NT.NAMETYPE ELSE '~~~' END
									and NTC2.ALLOW   =1)
						where A1.NAMENO=@pnHomeNameNo
						and A1.RELATIONSHIP=@sPathRelationship
						and (A1.CEASEDDATE is null or A1.CEASEDDATE>getdate())
						and NTC2.NAMENO is null
						and @bUseHomeNameRel=1 ) AN
					where ( AN.NAMEFLAG+
						convert(nchar(11), AN.NAMENO)+
						convert(nchar(11), AN.RELATEDNAME)+ 
						convert(nchar(6),  AN.SEQUENCE)) > @sAssociatedName
					and exists
					(select 1 from "+@psGlobalTempTable+" T
					 join CASES C on (C.CASEID=T.CASEID)
					 where (C.PROPERTYTYPE=AN.PROPERTYTYPE or AN.PROPERTYTYPE is null)
					 and   (C.COUNTRYCODE =AN.COUNTRYCODE  or AN.COUNTRYCODE  is null) )"

					exec @ErrorCode=sp_executesql @sSQLString, 
								N'@sAssociatedNameOUT	nvarchar(40) OUTPUT,
								  @pnNewNameNo		int,
								  @sPathRelationship	nvarchar(3),
								  @bUseHomeNameRel	bit,
								  @sAssociatedName	nvarchar(40),
								  @pnHomeNameNo		int,
								  @sNextNameType	nvarchar(3)',
								  @sAssociatedNameOUT=@sAssociatedName OUTPUT,
								  @pnNewNameNo       =@pnNewNameNo,
								  @sPathRelationship =@sPathRelationship,
								  @bUseHomeNameRel   =@bUseHomeNameRel,
								  @sAssociatedName   =@sAssociatedName,
								  @pnHomeNameNo      =@pnHomeNameNo,
								  @sNextNameType     =@sNextNameType
				End
			End
		End

		-- Now get the next inherited Name Type to continue the loop
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			select @sInheritedNameTypeOUT =
				min(	convert(nchar(3), NT.NAMETYPE)+ 
					convert(nchar(3), isnull(NT.PATHRELATIONSHIP, space(3)))+ 
					convert(nchar(1), isnull(NT.HIERARCHYFLAG,    0))+
					convert(nchar(1), isnull(NT.USEHOMENAMEREL,   0))+
					convert(nchar(11),NT.DEFAULTNAMENO))
			from NAMETYPE NT
			Where NT.PATHNAMETYPE=@psNameType
			and NT.NAMETYPE>substring(@sInheritedNameType, 1,3)
			and exists
			(select 1 from #TEMPCASENAMETYPES T
			 where T.NAMETYPE=NT.NAMETYPE)"


			exec @ErrorCode=sp_executesql @sSQLString, 
						N'@sInheritedNameTypeOUT nvarchar(19) OUTPUT,
						  @sInheritedNameType	 nvarchar(19),
						  @psNameType		 nvarchar(3)',
						  @sInheritedNameTypeOUT=@sInheritedNameType OUTPUT,
						  @sInheritedNameType   =@sInheritedNameType,
						  @psNameType           =@psNameType
		End
	End
	
End

-------------------------------------------------------------------------------------------
--
--	END OF PROCESSING
--
-------------------------------------------------------------------------------------------
Set @nPolicingCount=0

-- Use @psProgramId to determine if the procedure was 
-- called recursively or not.
If  @psProgramId is not Null
Begin

	If @ErrorCode=0
	Begin
		Select @bRecalcEvent=COLBOOLEAN
		from SITECONTROL
		where CONTROLID='Policing Recalculates Event'
		
		Set @ErrorCode=@@ERROR
	End
	
	If @bGetCaseInstructions=1
	and @ErrorCode=0
	Begin
		-------------------------------------------------------------------------------
		-- Check the NAMETYPEs that have been included in the global name change
		-- to see if they might have had an impact on Case level standing instructions
		-- by loading the candidates for Policing
		-------------------------------------------------------------------------------

		Set @sSQLString="
		Insert into #TEMPPOLICING(CASEID,EVENTNO,CYCLE,CRITERIANO,TYPEOFREQUEST,INSTRUCTIONTYPE,FLAGNUMBER,CASEEVENTEXISTS)
		select	T.CASEID, EC.EVENTNO, 
			isnull(	CASE WHEN(A.NUMCYCLESALLOWED>1) 
					THEN OA.CYCLE 
					ELSE Case DD.RELATIVECYCLE
						WHEN (0) Then CE1.CYCLE
						WHEN (1) Then CE1.CYCLE+1
						WHEN (2) Then CE1.CYCLE-1
							 Else isnull(DD.CYCLENUMBER,1)
					     End
				END,1), 
			EC.CRITERIANO, 6, EC.INSTRUCTIONTYPE, EC.FLAGNUMBER,
			CASE WHEN(CE2.CASEID is null) THEN 0 ELSE 1 END
		from #TEMPGLOBALUPDATESANDDELETES T
		join INSTRUCTIONTYPE IT on (IT.NAMETYPE=T.NAMETYPE
					or  IT.RESTRICTEDBYTYPE=T.NAMETYPE)
		join OPENACTION OA      on (OA.CASEID=T.CASEID
					and OA.POLICEEVENTS=1)
		join ACTIONS A          on (A.ACTION=OA.ACTION)
		join EVENTCONTROL EC    on (EC.CRITERIANO=OA.CRITERIANO
					and EC.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
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
		left join (select NI.CASEID, I.INSTRUCTIONTYPE
			   from NAMEINSTRUCTIONS NI
			   join INSTRUCTIONS I on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
			   where NI.CASEID is not null) CI
					on (CI.CASEID=T.CASEID
					and CI.INSTRUCTIONTYPE=EC.INSTRUCTIONTYPE)
		where ((isnull(CE2.OCCURREDFLAG,0)=0 and isnull(CE2.DATEDUESAVED,0)=0)
		 or (@bRecalcEvent=1 and EC.RECALCEVENTDATE=1 and EC.SAVEDUEDATE between 2 and 5))
		and CI.CASEID is null 
		UNION
		select	T.CASEID, EC.EVENTNO, 
			isnull(	CASE WHEN(A.NUMCYCLESALLOWED>1) 
					THEN OA.CYCLE 
					ELSE Case DD.RELATIVECYCLE
						WHEN (0) Then CE1.CYCLE
						WHEN (1) Then CE1.CYCLE+1
						WHEN (2) Then CE1.CYCLE-1
							 Else isnull(DD.CYCLENUMBER,1)
					     End
				END,1),
			EC.CRITERIANO, 6, EC.INSTRUCTIONTYPE, EC.FLAGNUMBER,
			CASE WHEN(CE2.CASEID is null) THEN 0 ELSE 1 END
		from #TEMPGLOBALCASENAMES T
		join INSTRUCTIONTYPE IT on (IT.NAMETYPE=T.NAMETYPE
					or  IT.RESTRICTEDBYTYPE=T.NAMETYPE)
		join OPENACTION OA      on (OA.CASEID=T.CASEID
					and OA.POLICEEVENTS=1)
		join ACTIONS A          on (A.ACTION=OA.ACTION)
		join EVENTCONTROL EC    on (EC.CRITERIANO=OA.CRITERIANO
					and EC.INSTRUCTIONTYPE=IT.INSTRUCTIONTYPE)
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
		left join (select NI.CASEID, I.INSTRUCTIONTYPE
			   from NAMEINSTRUCTIONS NI
			   join INSTRUCTIONS I on (I.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)
			   where NI.CASEID is not null) CI
					on (CI.CASEID=T.CASEID
					and CI.INSTRUCTIONTYPE=EC.INSTRUCTIONTYPE)
		where ((isnull(CE2.OCCURREDFLAG,0)=0 and isnull(CE2.DATEDUESAVED,0)=0)
		    or (@bRecalcEvent=1 and EC.RECALCEVENTDATE=1 and EC.SAVEDUEDATE between 2 and 5))
		and CI.CASEID is null"
		 
		exec @ErrorCode=sp_executesql @sSQLString,
					     N'@bRecalcEvent	bit',
					       @bRecalcEvent	= @bRecalcEvent
		
		Set @nPolicingCount=@@Rowcount

		-----------------------------------------------------
		-- If there are candidate Policing rows to calculate, 
		-- get the current Case Instructions since the
		-- name changes have been applied.
		-----------------------------------------------------
		If @ErrorCode=0
		Begin
			If @nPolicingCount=0
			Begin
				Set @bGetCaseInstructions=0
			End
			Else Begin
				-- Clear out the previous Case Instructions
				-- from before the Name changes.
			
				set @sSQLString='delete from #TEMPCASEINSTRUCTIONS
				
						 update #TEMPCASES
						 set INSTRUCTIONSLOADED=0'
						 
				exec @ErrorCode=sp_executesql @sSQLString
				
				If  @ErrorCode=0
				Begin
					exec @ErrorCode=dbo.ip_PoliceGetStandingInstructions @pnDebugFlag=0
				End	
				
				If @ErrorCode=0
				Begin
					-- Now load the index	
					CREATE CLUSTERED INDEX XPKTEMPCASEINSTRUCTIONS ON #TEMPCASEINSTRUCTIONS
 					(
        					CASEID,
						INSTRUCTIONTYPE
 					)
 				End
			End
		End
	End	

	-- SQA21916 Only raise policing request for change of name.  i.e. Exclude change of attention.
	-- add filter 'and @pnNewNameNo is not NULL'
	If @ErrorCode=0 and @pnNewNameNo is not NULL
	Begin
		--------------------------------------------------------------------------------
		-- Nametypes may be associated with an Event to indicate that the CaseEvent 
		-- is to be Updated or Inserted whenever the CaseName for that NameType has its
		-- NameNo changed or inserted.  These will be loaded into the temporary Policing 
		-- first and then from that table we will then update or insert into CASEEVENT
		--------------------------------------------------------------------------------
		Set @sSQLString="		
		Insert into #TEMPPOLICING(CASEID,EVENTNO,CYCLE,TYPEOFREQUEST,EVENTDATE,CASEEVENTEXISTS)
		select T.CASEID, TC.CHANGEEVENTNO, 1, 3,isnull(CN.COMMENCEDATE,convert(varchar,getdate(),112)), 1
		from #TEMPGLOBALUPDATESANDDELETES T
		join CASENAME CN	on (CN.CASEID=T.CASEID
					and CN.NAMETYPE=T.NAMETYPE)
		join #TEMPCASENAMETYPES TC on (TC.CASEID=T.CASEID
					   and TC.NAMETYPE=T.NAMETYPE)
		left join CASEEVENT CE	on (CE.CASEID=T.CASEID
					and CE.EVENTNO=TC.CHANGEEVENTNO
					and CE.CYCLE=1)
		where TC.CHANGEEVENTNO is not null
		UNION
		select T.CASEID, TC.CHANGEEVENTNO, 1, 3,isnull(CN.COMMENCEDATE,convert(varchar,getdate(),112)),1
		from #TEMPGLOBALCASENAMES T
		join CASENAME CN	on (CN.CASEID=T.CASEID
					and  CN.NAMENO=T.NAMENO
					and CN.NAMETYPE=T.NAMETYPE)
		join #TEMPCASENAMETYPES TC on (TC.CASEID=T.CASEID
					   and TC.NAMETYPE=T.NAMETYPE)
		left join CASEEVENT CE	on (CE.CASEID=T.CASEID
					and CE.EVENTNO=TC.CHANGEEVENTNO
					and CE.CYCLE=1)
		where TC.CHANGEEVENTNO is not null"

		Exec @ErrorCode=sp_executesql @sSQLString

		Set @nPolicingCount=@nPolicingCount+@@Rowcount
	End


	If @ErrorCode=0
	Begin
		------------------------------------------------
		-- RFC13663
		-- Recalculate Events that require the existence
		-- of a Document Case for a given Name Type. The
		-- change of Name against the Case for the given
		-- Name Type could now mean an Event can occur.
		------------------------------------------------
		Set @sSQLString="		
		Insert into #TEMPPOLICING(CASEID,EVENTNO,CYCLE,TYPEOFREQUEST,CHECKDOCUMENTCASE)
		select CE.CASEID, CE.EVENTNO, CE.CYCLE, 6, 1
		from #TEMPGLOBALUPDATESANDDELETES T
		join OPENACTION OA	on (OA.CASEID=T.CASEID)
		join ACTIONS A		on (A.ACTION=OA.ACTION)
		join EVENTCONTROLNAMEMAP EC
					on (EC.CRITERIANO=OA.CRITERIANO
					and T.NAMETYPE=isnull(EC.SUBSTITUTENAMETYPE,EC.APPLICABLENAMETYPE))
		join CASEEVENT CE	on (CE.CASEID =OA.CASEID
					and CE.EVENTNO=EC.EVENTNO
					and CE.CYCLE  =CASE WHEN(A.NUMCYCLESALLOWED>1) 
								THEN OA.CYCLE 
								ELSE CE.CYCLE
							END)
		where OA.POLICEEVENTS=1
		and isnull(CE.OCCURREDFLAG,0)=0"

		Exec @ErrorCode=sp_executesql @sSQLString

		Set @nPolicingCount=@nPolicingCount+@@Rowcount
	End

	If  @ErrorCode=0
	and @nPolicingCount>0
	and @pbPoliceImmediately=1
	Begin
		------------------------------------------------
		-- Keep this transaction as short as possible to 
		-- avoid locking the LASTINTERNALCODE table
		------------------------------------------------
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION
		
		------------------------------------------------------
		-- Get the Batchnumber to use for Police Immediately.
		-- BatchNumber is relatively shortlived so reset it
		-- by incrementing the maximum BatchNo on the Policing
		-- table.
		------------------------------------------------------

		Set @sSQLString="
		Update LASTINTERNALCODE
		set INTERNALSEQUENCE=P.BATCHNO+1,
		    @nPoliceBatchNo =P.BATCHNO+1
		from LASTINTERNALCODE L
		cross join (select max(isnull(BATCHNO,0)) as BATCHNO
			    from POLICING) P
		where TABLENAME='POLICINGBATCH'"

		exec @ErrorCode=sp_executesql @sSQLString,
					N'@nPoliceBatchNo		int	OUTPUT',
					  @nPoliceBatchNo=@nPoliceBatchNo	OUTPUT

		Set @nRowCount=@@Rowcount

		If  @ErrorCode=0
		and @nRowCount=0
		Begin
			Set @sSQLString="
			Insert into LASTINTERNALCODE(TABLENAME, INTERNALSEQUENCE)
			values ('POLICINGBATCH', 0)"

			exec @ErrorCode=sp_executesql @sSQLString
			
			set @nPoliceBatchNo=0
		End

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End

	If @ErrorCode=0
	Begin
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION
		
		-------------------------------------------
		-- Now Update or insert the CASEEVENT rows
		-- that have been triggered by the NameType
		-- change against the Case.
		-------------------------------------------
		If @nPolicingCount>0
		Begin
			-- Now load the live Policing table from the temporary table.

			If  @ErrorCode=0
			Begin
				Set @sSQLString="
				insert into POLICING(DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, ONHOLDFLAG, EVENTNO, CASEID, CRITERIANO, CYCLE, TYPEOFREQUEST, BATCHNO, SQLUSER, IDENTITYID)
				select distinct getdate(), T.POLICINGSEQNO, 'GNC'+convert(varchar, getdate(), 121)+' '+convert(varchar,T.POLICINGSEQNO), 1, @pbPoliceImmediately, T.EVENTNO, T.CASEID, T.CRITERIANO, T.CYCLE, T.TYPEOFREQUEST, @nPoliceBatchNo, SYSTEM_USER, @pnUserIdentityId
				from #TEMPPOLICING T
				left join #TEMPOLDINSTRUCTIONS O
							on (O.CASEID=T.CASEID
							and O.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
				left join #TEMPCASEINSTRUCTIONS C
							on (C.CASEID=T.CASEID
							and C.INSTRUCTIONTYPE=T.INSTRUCTIONTYPE)
				left join INSTRUCTIONFLAG IF2
							on (IF2.INSTRUCTIONCODE=C.INSTRUCTIONCODE
							and IF2.FLAGNUMBER     =T.FLAGNUMBER)
				left join POLICING P	on (P.CASEID=T.CASEID
							and P.EVENTNO=T.EVENTNO
							and P.CYCLE=T.CYCLE
							and P.TYPEOFREQUEST=T.TYPEOFREQUEST)
				where P.CASEID is null
				and ( T.TYPEOFREQUEST=3
				 or   T.CHECKDOCUMENTCASE=1					-- Change of Name for NameType may allow Document Case to be found
				 or  (T.CASEEVENTEXISTS=1 and IF2.FLAGNUMBER is null)		-- Event will no longer be able to be calculated
				 or  (T.CASEEVENTEXISTS=0 and IF2.FLAGNUMBER is not null)	-- Event can now be calculated
				      -- Event exists but date calculated may change
				 or  (T.CASEEVENTEXISTS=1 and checksum(O.PERIOD1TYPE,O.PERIOD1AMT,O.PERIOD2TYPE,O.PERIOD2AMT,O.PERIOD3TYPE,O.PERIOD3AMT,O.ADJUSTMENT,O.ADJUSTDAY,O.ADJUSTSTARTMONTH,O.ADJUSTDAYOFWEEK,O.ADJUSTTODATE)
							   <> checksum(C.PERIOD1TYPE,C.PERIOD1AMT,C.PERIOD2TYPE,C.PERIOD2AMT,C.PERIOD3TYPE,C.PERIOD3AMT,C.ADJUSTMENT,C.ADJUSTDAY,C.ADJUSTSTARTMONTH,C.ADJUSTDAYOFWEEK,C.ADJUSTTODATE))
					)"

				Exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnUserIdentityId		int,
							  @pbPoliceImmediately		bit,
							  @nPoliceBatchNo		int',
							  @pnUserIdentityId   = @pnUserIdentityId,
							  @pbPoliceImmediately=@pbPoliceImmediately,
							  @nPoliceBatchNo     =@nPoliceBatchNo
							  
				Set @nPolicingCount=@@Rowcount
			End
			
			If @nPolicingCount>0
			Begin
				If @ErrorCode=0
				Begin
					Set @sSQLString="
					Update CASEEVENT
					Set EVENTDATE=T.EVENTDATE,
					    OCCURREDFLAG=1
					from CASEEVENT CE
					join #TEMPPOLICING T	on (T.CASEID=CE.CASEID
								and T.EVENTNO=CE.EVENTNO
								and T.CYCLE=CE.CYCLE
								and T.TYPEOFREQUEST=3)
					where T.EVENTDATE is not null"

					Exec @ErrorCode=sp_executesql @sSQLString
				End

				If @ErrorCode=0
				Begin
					Set @sSQLString="
					insert into CASEEVENT(CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)
					Select T.CASEID, T.EVENTNO, T.CYCLE, T.EVENTDATE, 1
					from #TEMPPOLICING T
					left join CASEEVENT CE	on (CE.CASEID=T.CASEID
								and CE.EVENTNO=T.EVENTNO
								and CE.CYCLE=T.CYCLE)
					where CE.CASEID is null
					and T.TYPEOFREQUEST=3
					and T.EVENTDATE is not null"

					Exec @ErrorCode=sp_executesql @sSQLString
				End
			End
		End


		If  @pnRequestNo is not null
		and @ErrorCode=0
		Begin
			--------------------------------
			-- Delete the global name change
			-- request details on successful
			-- completion of the process
			--------------------------------
			Set @sSQLString="
			Delete CASENAMEREQUESTCASES
			where REQUESTNO=@pnRequestNo"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@pnRequestNo	int',
						  @pnRequestNo=@pnRequestNo

			If @ErrorCode=0
			Begin
				Set @sSQLString="
				Delete	CASENAMEREQUEST
				where REQUESTNO=@pnRequestNo"

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@pnRequestNo	int',
							  @pnRequestNo=@pnRequestNo
			End
		End

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End

	------------------------------------------------
	-- Police Immediately
	-- If the Police Immediately option has been
	-- selected then run Policing within its own
	-- transacation.  This is safe to do because
	-- the Policing rows have already been committed
	-- to the database so any failure will ensure
	-- that the unprocessed requests will remain.
	-- A separate transaction will reduce the chance
	-- of extended locks on the database.
	------------------------------------------------
	If  @ErrorCode=0
	and @nPolicingCount>0
	and @pbPoliceImmediately=1
	Begin
		exec @ErrorCode=dbo.ipu_Policing
					@pnBatchNo=@nPoliceBatchNo,
					@pnUserIdentityId=@pnUserIdentityId

		Set @nPolicingCount=0
	End
End -- @psProgramId is not Null
--------------------------------------------------------------------------------------------------
-- Finally if this execution of the stored procedure was not called recursively then check 
-- the Cases updated and report any of the Cases where a NameType that requires Billing Percentage
-- does not have a total percentage of 100
--------------------------------------------------------------------------------------------------
If  @psProgramId is not Null
and @pbSuppressOutput=0
and @ErrorCode=0
Begin

	Set @sSQLString=
		"select @pnNamesUpdatedCount as 'Names Updated Count',"+char(10)+
		"@pnNamesInsertedCount as 'Names Inserted Count',"+char(10)+
		"@pnNamesDeletedCount  as 'Names Deleted Count'"

	exec sp_executesql  @sSQLString,
				N'@pnNamesUpdatedCount	int,
				  @pnNamesInsertedCount int,
				  @pnNamesDeletedCount  int',
				  @pnNamesUpdatedCount,
				  @pnNamesInsertedCount,
				  @pnNamesDeletedCount

	Set @sSQLString=
		"select distinct"+char(10)+
		"C.IRN, NT.DESCRIPTION as 'Type Description',"+char(10)+
		"CN1.TotalPercentage as 'Total Percentage',"+char(10)+
		"C.CURRENTOFFICIALNO as 'Official No',"+char(10)+
		"C.TITLE, CT.CASETYPEDESC, CY.COUNTRY,PROPERTYNAME"+char(10)+
		"from CASES C"+char(10)+
		"join CASENAME CN on (CN.CASEID=C.CASEID"+char(10)+
		"		 and (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>getdate()))"+char(10)+
		"join (select CX.CASEID, CX.NAMETYPE, SUM(isnull(CX.BILLPERCENTAGE,0)) as TotalPercentage"+char(10)+
		"      from "+@psGlobalTempTable+" T"+char(10)+
		"      join CASENAME CX on (CX.CASEID=T.CASEID)"+char(10)+
		"      where (CX.EXPIRYDATE is null OR CX.EXPIRYDATE>getdate())"+char(10)+
		"      group by CX.CASEID, CX.NAMETYPE) CN1 on (CN1.CASEID=CN.CASEID"+char(10)+
		"					    and CN1.NAMETYPE=CN.NAMETYPE)"+char(10)+
		"join NAMETYPE NT on (NT.NAMETYPE=CN.NAMETYPE)"+char(10)+
		"join CASETYPE CT on (CT.CASETYPE=C.CASETYPE)"+char(10)+
		"join COUNTRY  CY on (CY.COUNTRYCODE=C.COUNTRYCODE)"+char(10)+
		"join VALIDPROPERTY VP on (VP.PROPERTYTYPE=C.PROPERTYTYPE"+char(10)+
		"                      and VP.COUNTRYCODE=(select min(COUNTRYCODE)"+char(10)+
		"                                          from VALIDPROPERTY VP1"+char(10)+
		"                                          where VP1.PROPERTYTYPE=VP.PROPERTYTYPE"+char(10)+
		"                                          and   VP1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))"+char(10)+
		"where NT.COLUMNFLAGS&64=64"+char(10)+
		"and (isnull(CN.BILLPERCENTAGE,0)=0 OR CN1.TotalPercentage<>100)"+char(10)+
		"order by C.IRN, NT.DESCRIPTION"

	exec sp_executesql  @sSQLString
End

Set @nSavedErrorCode = @ErrorCode

---------------------------------------
-- drop the temporary table @psGlobalTempTable after use
---------------------------------------
IF @ErrorCode=0 and @pbCalledFromCentura=0
Begin

	---------------------------------------
	-- Drop temporary table 
	---------------------------------------	
	Set @sSQLString = "Drop table "+CHAR(10)+ @psGlobalTempTable
	exec @ErrorCode = sp_executesql @sSQLString,
				N'@psGlobalTempTable	nvarchar(100)',
				@psGlobalTempTable  = @psGlobalTempTable		
End

---------------------------------------
-- Update BACKGROUNDPROCESS table 
---------------------------------------	
If @pnRequestNo is not null and @pbCalledFromCentura=0
Begin
	If @nSavedErrorCode = 0
	Begin
		Set @sSQLString = "Update BACKGROUNDPROCESS
				Set STATUS = 2,
				    STATUSDATE = getdate()
				Where PROCESSID = @nBackgroundProcessId"

		exec sp_executesql @sSQLString,
			N'@nBackgroundProcessId	int',
			@nBackgroundProcessId  = @nBackgroundProcessId	
		
		-- Add Process Row for counts in GNCCOUNTRESULT table
		Set @sSQLString = "INSERT INTO GNCCOUNTRESULT(PROCESSID, NOUPDATEDROWS, NOINSERTEDROWS, NODELETEDROWS)
				   VALUES (@nBackgroundProcessId, @pnNamesUpdatedCount, @pnNamesInsertedCount, @pnNamesDeletedCount)"				

		Exec @ErrorCode= sp_executesql @sSQLString,
			N'@nBackgroundProcessId		int,
			  @pnNamesUpdatedCount		int,
			  @pnNamesInsertedCount		int,
			  @pnNamesDeletedCount		int',
			  @nBackgroundProcessId		= @nBackgroundProcessId,
			  @pnNamesUpdatedCount		= @pnNamesUpdatedCount,
			  @pnNamesInsertedCount		= @pnNamesInsertedCount,
			  @pnNamesDeletedCount		= @pnNamesDeletedCount

		-- Add Changed Cases in GNCCHANGEDCASES table
		If @ErrorCode = 0
		Begin
			Set @sSQLString = "INSERT INTO GNCCHANGEDCASES(PROCESSID, CASEID)
				   SELECT DISTINCT @nBackgroundProcessId, C.CASEID FROM 
					(SELECT CASEID FROM #TEMPGLOBALCASENAMES  
						UNION 
					 SELECT CASEID from #TEMPGLOBALUPDATESANDDELETES ) as C"				

			Exec @ErrorCode= sp_executesql @sSQLString,
				N'@nBackgroundProcessId	int',
				@nBackgroundProcessId  = @nBackgroundProcessId	
		End
	End
	Else
	Begin
		Set @sSQLString="Select @nErrorMessage = description
			from master..sysmessages
			where error=@nSavedErrorCode
			and msglangid=(SELECT msglangid FROM master..syslanguages WHERE name = @@LANGUAGE)"

		Exec @ErrorCode=sp_executesql @sSQLString,
			N'@nErrorMessage	nvarchar(254) output,
			  @nSavedErrorCode	int',
			  @nErrorMessage	= @nErrorMessage output,
			  @nSavedErrorCode	= @nSavedErrorCode

		---------------------------------------
		-- Update BACKGROUNDPROCESS table 
		---------------------------------------	
		Set @sSQLString = "Update BACKGROUNDPROCESS
					Set STATUS = 3,
					    STATUSDATE = getdate(),
					    STATUSINFO = @nErrorMessage
					Where PROCESSID = @nBackgroundProcessId"

		exec sp_executesql @sSQLString,
			N'@nBackgroundProcessId	int,
			  @nErrorMessage	nvarchar(254)',
			  @nBackgroundProcessId = @nBackgroundProcessId,
			  @nErrorMessage	= @nErrorMessage
		End
End

If  @psProgramId is not Null
     and @pbSuppressOutput=0 and @ErrorCode=1
Begin
	Select @ErrorCode as 'ErrorCode'
End

RETURN @ErrorCode
go

grant execute on dbo.cs_GlobalNameChange  to public
go
