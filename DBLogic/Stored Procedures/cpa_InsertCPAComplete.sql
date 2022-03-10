-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_InsertCPAComplete
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_InsertCPAComplete]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_InsertCPAComplete.'
	drop procedure dbo.cpa_InsertCPAComplete
end
print '**** Creating procedure dbo.cpa_InsertCPAComplete...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_InsertCPAComplete 
		@pnCaseId 		int		=null, 
		@psPropertyType		nvarchar(2)	=null,
		@pnNotProperty		tinyint		=null,
		@pnNewCases		tinyint		=null,
		@pnChangedCases		tinyint		=null,
		@pnPoliceEvents		tinyint		=null,
		@pbCheckInstruction	bit		=1,
		@psOfficeCPACode	nvarchar(3)	=null,
		@pnUserIdentityId	int		=null,
		@pnTestMode 		tinyint		=0
as
-- PROCEDURE :	cpa_InsertCPAComplete
-- VERSION :	108
-- DESCRIPTION:	Extract details of Cases to be sent to CPA
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS:
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 20/03/2002	MF			Procedure Created
-- 03/09/2002	MF			Restrict extraction of some of the official numbers depending upon Property Type
-- 25/09/2002	MF	8023		Reduce the locking level to the lowest level to ensure no blocks occur.
-- 18/10/2002	MF	8096		When CPA Interface extracts data to send to CPA, it is not inserting a CASEEVENT row 
--					to reflect that the case has been sent.
-- 21/10/2002	MF	8096		Revisited.
-- 08/11/2002	MF	8169		Names being reported as Divisions incorrectly due to coding error
-- 18/11/2002	MF	8237		Extract the PCT Filing Number by using an explicit relationship that has been defined 
--					by the user firm.
-- 20/11/2002	MF	8224		When a case is reported to CPA because its Stop Pay Reason 
--					is set, use previous info. sent to CPA and the Stop Pay Reason.
-- 25/11/2002	MF	8264		Exclude cases that match the data last received back from CPA
-- 01/12/2002	MF	8275		CPA would like InProma to report their CPA Account number for Clients and Invoicees.
-- 10/12/2002	MF	8307		Do not include the CPACLIENTNO and CPAINVOICEENO in the comparison agaist previously
--					sent data.  This is because these numbers are internal to CPA and changes of these 
--					alone should not generate a record to be sent to CPA.
-- 13/12/2002	MF			Modify the extraction of the Next Renewal Date so that the earliest future next
--					renewal date is used if no current Open Action exists to identify the specific Cycle.
-- 02/01/2003	MF	8334		The Batchdate for the data sent to CPA is to also include the time that the data was 
--					extracted.
-- 04/02/2003	MF	8436		Allow a new option to indicate that Standing Instructions should be checked.
--					The option will default ON.  It could be useful to turn this off in an initial extract
--					as the Standing Instruction check will slow the process down significantly.
-- 26/02/2003	MF	8460		If the very first CPA Send batch has been extracted and there already exists matching 
--					Cases on the CPA Portfolio then this indicates that the first batch is a dummy initialisation
--					batch.  In this situation automatically generate a matching EPL batch using a mixture of 
--					the sent data and data extracted from the Portfolio.
-- 28/02/2003	MF	8460		Revisited to cater for the possibility of a Case appearing more than once on the Portfolio.
-- 04/03/2003	MF	8486		If a Stop Pay Reason has been supplied for CPA but no Stop Pay Date then default to the 
--					current date.
-- 24/03/2003	MF	8556		SQL error being caused by code that should have been removed for StopPayDate.
-- 27/03/2003	MF	8580		Only report Attention names for new Cases reported to CPA.
-- 31/03/2003	MF	8582		When extracting data to be sent to CPA use the IPRURN from previously acknowledged data
--					received for that Case.
-- 21/05/2003	MF	8767		Ignore data comparison of Address fields except where the transaction is for the Client (04),
--					Division (05) or Invoicee (06).  Also if there is more than one CPACLIENTNO associated 
--					with a Name then report the CPACLIENTNO as null.
-- 21/05/2003	MF	8757		When extracting data if there is more than one CPA Client No associated with a Client
--					or Invoicee then do not return the CPA Client No to CPA.
-- 26/05/2003	MF	8779		Only report the Filing Agent if the Country of the case has a specific attribute.
-- 13/06/2003	MF	8907		Replace any embedded carriage returns for the Case Title by a SPACE.
-- 18/06/2003	MF	8767		Revisit.  If the InvoiceeCode is now NULL then ignore comparison against previous record.
-- 25 Jun 2003	MF	8874		If the Case being reported to CPA was previously rejected then send the NARRATIVE 
--					saved on the last batch record to CPA to explain why the Case was rejected.
-- 04 Jul 2003	MF	8953		If either the CPA Start Date or the CPA Stop date are defaulted then these dates
--					are to be back loaded into the CASEEVENT table.  This will then ensure that if the Case
--					is reextracted that the same date will be reported to CPA.
-- 11 Jul 2003	MF	8953		Revisit as problem found in testing.
-- 17 Jul 2003	MF	8993	10	Change columns defined as TINYINT to SMALLINT on temporary table #TEMPCPASEND.
-- 17 Jul 2003	MF	8994	10	A new Case is to be defined as one where the Case already exists on CPAPORTFOLIO.
-- 17 Jul 2003	MF	8996	11	A SQL Error was occurring if no Reject Event had been defined in Site Control.
-- 25 Aug 2003	MF	9151	12	Only extract the NRD if it is explicitly identified by an Open Action.
-- 30 Sep 2003	mf	9303	13	To more easily cater for firms with multiple offices that report their Cases to
--					CPA in a separate portfolio, get the SYSTEMID from the Office code.
-- 03 Oct 2003	MF	9326	14	CPA Interface crashed with duplicate key error when a Case appear more than 
--					once on the CPA Portfolio
-- 02 Dec 2003	MF	9510	15	Increase the size of POLICINGSEQNO to int to cater for large number of 
--					Policing requests on an initial CPA Interface extract.
-- 08 Jan 2004	MF	9556	16	Ensure that the Division Code does not exceed 6 characters and the ForeignAgentCode
--					does not exceed 8 characters.
-- 28 Jan 2004	MF	9643	17	Replace any embedded TAB character in the Case Tile by a Space.
-- 17 Mar 2004	MF	9820	18	Do not default the StartPayDate for TMs.  Do not send the Priority Date
--					for non convention cases.
-- 26 Mar 2004	MF	9820	19	Also only load the CPASTARTDATE if the Case is being reported as a new Case.
-- 18 Jun 2004	MF	10202	20	Ensure the CPA Sent Event is updated even when the Event has previously
--					occurred.
-- 16 Jul 2004	MF	10292	21	Remove the reporting of Attention details against Case records as CPA are not
--					able to store the information against a Case.
-- 05 Aug 2004	AB	8035	22	Add collate database_default to temp table definitions
-- 11 Oct 2004	MF	10528	23	Do not default the Start Pay Date
-- 11 Oct 2004	MF	10529	23	Allow the Number Types to be user defined in Site Controls.
-- 20 Oct 2004	MF	10566	24	Report Case specific SystemId in the AlternateOfficeCode column.
-- 04 Jan 2005	MF	10829	25	Cases with no Status are to be considered as Live when extracting.
-- 07 Feb 2005	MF	10977	26	Further restrictions to cater for CPA Portfolio having multiple entries for 
--					the one Case.
-- 29 Mar 2005	MF	10481	27	An option now exists to allow the CASEID to be recorded in the CPA database
--					instead of the IRN which may exceed the 15 character CPA limit.  This change will
--					consider this Site Control and join on CASEID when appropriate.
-- 23 Mar 2005	MF	11197	28	Reformat the PCT Filing number if it is in the format PCT/AAyyyy/999999
--					to PCT/AAyy/999999 so as to avoid CPA either truncating the number or
--					reformatting it.  This will avoid mismatches on this field when the EPL is
--					compared against the data sent.
-- 06 Apr 2005	MF	10482	29	Report the Case Category to CPA in the File Number field.
-- 27 Apr 2005	MF	11129	30	Use the MAINEMAIL pointer against the NAME to find the Email Address
--					to report to CPA.
-- 06 May 2005	MF	10731	31	Allow a filter on Office User Code.
-- 03 Jun 2005	MF	1148	32	Report a default Attention against the Client, Division and Invoicee,
--					records sent to CPA.  For some reason this extract had been commented out.
-- 08 Jun 2005	AB	9891	33	Collate database_default syntax added to #TEMPCPASEND.PROPERTYTYPE
-- 15 Jun 2005	MF	10731	34	Revisit.  Change Office User Code to Office CPA Code.
-- 01 Aug 2005	MF	10482	35	Revisit of 10482.  Exclude the FileNumber from the data comparison when
--					determining whether the Case information has changed since the last extract.
--					This change will stop excessive batches from being generated.
-- 24 Aug 2005	MF	11779	36	When extracting Address details, any address pointed to explicitly from the
--					Case should be considered.
-- 29 Aug 2005	MF	11798	37	Restrict reporting of Classes to Trademark cases.
-- 29 Aug 2005	MF	11799	37	Related case details should report the Application Number instead of the 
--					current official number.
-- 16 Nov 2005	vql	9704	38	When updating POLICING table insert @pnUserIdentityId.
--					Create @pnUserIdentityId also.
-- 03 Jan 2006	MF	12171	39	Allow a Site Control to indicate that the File Number to be reported to CPA
--					is to be extracted using a user defined Number Type.  If no value is specified
--					then the File Number will have the Case Category extracted into it.
-- 16 May 2006	MF	12680	40	Report the CPA Start Pay date if it has been modified since it was last reported
--					to CPA for the Case.
-- 31 Oct 2006	MF	13752	41	Allow an option whereby the employee associated with the Case is substituted as
--					the CPA client.
-- 06 Nov 2006	MF	13292	42	Delete rows from CPAUPDATE on completion of batch extract depending on the 
--					site control option.
-- 10 Nov 2006  MF	13731	43	Save the IRN in the FILENUMBER field if option set to do so.
-- 10 Nov 2006	MF	13777	43	It is possible to report a Case that is not on the CPASEND table that has a
--					stop pay reason.  In this situation we should extract the data as per a normal
--					case.
-- 23 Nov 2006	MF	13847	44	Copy the batch being sent into CPASENDCOMPARE table and also use CPASENDCOMPARE
--					in the final data comparison for determining what actual Cases are to be sent.
-- 31 Jan 2007	MF	13777	45	Revisit. Ensure the Renewal Type is determined even if the Stop Pay is set.
-- 06 Feb 2007	MF	13777	46	Revisit. Default the Stop Pay Date if a Stop Pay Reason is supplied even if
--					the Case has never been reported before.
-- 08 Feb 2007	MF	14255	47	Transaction Code for Invoicee record is 06 however the count is incorrectly
--					using code 07.
-- 22 Feb 2007	AvdA	14334	48	Enable a preview batch to be produced.
--					New parameter pnTestMode= 0 live batch, 1 preview batch, (reserve 2 test batch for future)
-- 21 Mar 2007	MF	14599	49	This SQA also varies the way in which 13752 will now work. The change is to allow
--					a determined CPA Account number to be reported when the standing instruction 
--					against the Case includes a flag (see 'CPA INTERCEPT FLAG') that indicates the 
--					Agent firm is to act as a go between that sits between CPA and the end client.
--					The CPA Account will be determined by checking for the Account in the following
--					order : Owner; Real Instructor; Attorney; Home Name
-- 22 Mar 2007	MF	13847	49	Revisit to remove rows from CPASENDCOMPARE that have now been superceded by
--					this batch just inserted.
-- 05 Apr 2007	MF	14659	50	For cases being reported because of a Stop Pay Reason, do not report the Start
--					Pay Date and Narrative from the previously reported batch record for that Case.
-- 01 May 2007	MF	14729	51	When batch is being run for a specific Office, check to see if this is the
--					first batch for that Office and if it is and Cases from that office already
--					exist on the Portfolio then generate a dummy EPL for the cases in the batch.
-- 07 Jun 2007	MF	14899	52	Certain data fields are not compared against CPARECEIVE when trying to determine
--					if the extracted Case details should actually be sent in the batch.  The fields
--					are excluded because CPA reformat the data and so it is never going to match.
--					By not comparing at all then it creates a greater liklihood that all other fields
--					will match and result in the case being removed.  To avoid this, the fields that
--					are not compared with CPARECEIVE are to be compared against the data last sent
--					for the case.
-- 11 Jul 2007	MF	15023	53	Improve performance by rewriting the DELETE of the CPASENDCOMPARE table.
-- 17 Jul 2007	MF	14998	54	The Alternate Office Code may be sent to CPA even if it is identical to the
--					System Code.
-- 16 Aug 2007	MF	15153	55	Leading zeroes are not being stripped from Classes reported to CPA in a 
--					consistent manner.
-- 07 Nov 2007	MF	15528	56	Also include Alternate Office Code on all Name transactions defaulted from SYSTEMID.
-- 13 Nov 2007	MF	15587	56	Always update the CPA Sent Event even if the Case has a Stop Pay Reason.
-- 15 Nov 2007	MF	15569	57	Duplicate key error due to duplicate Cases for the same Batch in CPARECEIVE.
-- 13 Dec 2007	MF	15736	58	The CPASENDCOMPARE table was incorrectly keeping the earliest batch record for
--					the Case when it should have been retaining the latest.
-- 30 Jan 2008	MF	15891	59	Rows are removed if the data extracted is identical to what was previously sent.
--					The remaining rows are then compared against the data last received back from 
--					CPA and removed if these are identical. This is to be refined so that only those
--					columns where a difference was found in the comparison against what was sent are
--					to undergo the second level comparison against what was received.
-- 03 Mar 2008	MF	16020	60	When sending details of Cases with a Stop Pay Date, send the current details of
--					the Case and not the last details previously sent.  Originally this was done to 
--					reduce the possibility of CPA triggering other Case changes however it has been
--					decided that we should always send the most up to date information even if the
--					Case is being stopped.
-- 07 May 2008	MF	16332	61	Prevent removal of case from batch if priority date is only change.
-- 07 May 2008	MF	16334	61	Collect the CPAAccountNo directly from the new NAMEADDRESSCPACLIENT table if 
--					site control indicates.
-- 08 May 2008	MF	16194	61	Names sent to CPA as a result of the Case being reported, are to also include
--					the Attention and Email details on the separate Name transaction even though
--					this is not embedded on the Case transaction.
-- 08 Jul 2008	AvdA	16672	62	Provide cyclic information for Next Affidavit, Next Dec of Use, Nominal Working.
-- 11 Dec 2008	MF	17136	63	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 29 Jan 2009	AvdA	17346	64	Avoid resending cases with a Stop Pay Date/Reason whenever other data changes.
-- 10 Feb 2009	vql	17368	65	CPA Interface not taking Office into account when clearing CPAUPDATE table.
-- 21 Jul 2009	MF	17879	66	Report Names referred to by a Case irrespecitve of whether the Case is being reported for the first time or as an update.
-- 18 Nov 2009	AvdA	18243	67	Provide option to pass IRN in CLIENTSREFERENCE field via CPA Clients Reference Type site control.
-- 02 Dec 2009	AvdA	18280	68	If site control CPA Division Code Truncation is set on, truncate long division codes to 6 characters.
-- 03 Dec 2009	AvdA	18287	69	Always simply send the main postal address for the instructor (rather than the address held at case level).
-- 18 Dec 2009	AvdA	17347	70	If site control CPA Consider All CPA Cases is set on then consider all cases 
--									with REPORTTOTHIRDPARTY on (or with a new STOPPAYREASON) rather than those in CPAUPDATE only.
--									Also clean up FAX and PHONE so always null if empty.
-- 28 Jan 2010	AvdA	18372	71	For Parent Number ignore relationships in CPA Parent Exclude.
-- 29 Jan 2010	AvdA	18402	72	Add possibility to send Name alias for Division Code.
-- 18 Mar 2010	MF	18556	73	Change the way in which the dynamically constructed procedure for extracting Cases to send is called so that the 
--					returned ErrorCode is loaded into @ErrorCode.
-- 03 May 2010	MF	18703	74	The CPA Account number is determined from a Name Alias.  This is to now take into consideration the CountryCode and Property
--					Type of the Case being reported to CPA.
-- 24 Jul 2010	MF	18915	75	Ensure the Priority Number reported has the earliest priority date.
-- 05 Aug 2010	MF	18915	76	Revisit after test failure.
-- 06 Aug 2010	MF	18915	76	Revisit after test failure.
-- 09 Aug 2010	MF	18915	77	Revisit with further minor adjustments.
-- 10 Aug 2010	AvdA	18716	78	Resend name record (only) if the Attention name changes. 
-- 30 Mar 2011	vql	18962	79	Collect Client Reference from a Doc Item.
-- 14 Sep 2011	AvdA	19683	80	Collect Name record email address from main contact email or main name email
-- 22 Dec 2011	AvdA	20198	81	Only collect Names that have not ceased for records 04, 05, 06
-- 22 Dec 2011	AvdA	20199	82	Ignore case level name addresses for Div and Inv records
-- 22 Dec 2011	AvdA	20231	83	Collect IPRURN from EPL before Portfolio (with extra check on status and responsible party)
-- 09 May 2012	AvdA	20480   84	Populate CPASEND with complete contents of CPARECEIVE for initialisation batch.
--			20571		Fix bug introduced 20231 (error when producing initialisation batch).
-- 12 Apr 2013	AvdA	21344	85	Collect PCT filing number from case official number if no PCT relationship exists.
-- 06 Jun 2013	MF	13552	86	Rework of 21344 to handle situation where PCT Filing Number has not been mapped in SiteControl.	
-- 20 Jan 2013	MF	S20008	87	Use the function fn_RemoveNoiseCharacters to strip out characters that should be ignored when considering
--					differences between data previously sent to CPA and what is a candidate to be sent.  This is to align 
--					the functionality with the procedure cpa_BatchComparison.
-- 27 Feb 2014	DL	S21508	88	Change variables and temp table columns that reference namecode to 20 characters
-- 28 Apr 2014	MF	S22073	89	Increase size of @sParentExclude to nvarchar(500) to cater for increased number of Relationships.
-- 15 May 2014  DL	S21580	90	Require a new Renewal Type of Micro and a new Entity Size of Micro with a code of M
-- 26 Sep 2014	MF	R39818	91	Wrong client information may be sent with stop pay reason.
-- 05 Jan 2015	AvdA	R42657	92	Tweak change 87 to also use function fn_RemoveNoiseCharacters in first part of delete comparison.
--					Also ignore leading zeroes in number comparison.
-- 02 Oct 2015	MF	R53541	93	Consider ISCURRENT flag in determining the Number Type.
-- 07 Jan 2016	MF	R53541	94	Consider the sequence in which the NumberTypes are listed in the CPA Number-xxxx sitecontrols so that the
--					sequence is used as the order of priority for deciding the number type to report to CPA.
-- 15 Jan 2016	MF	R56175	95	Remove the restriction that stop change of INVOICEECODE from being reported for anything other than TRANSACTIONCODE=06.
-- 16 Mar 2016	MF	R58169	96	Newly introduced EntitySize of 2604 to be reported to CPA as 'S' (small entity).
-- 05 Apr 2016	MF	R57212	97	Cases with multiple debtor are to have those debtors reported in a separate table.
-- 12 Apr 2016	MF	R57212	98	Also report any of the multiple debtors as an 06 TransactionCode record.
-- 22 Apr 2016	MF	R57212	99	Corrections after test failures.
-- 04 May 2016	MF	R57212	100	Further corrections.
-- 06 May 2016	MF	R57212	101	Improve code so that when considering last batch a Case was reported in, count the number of debtors whose BILLPERCENTAGE
--					was not 100.
-- 20 Jul 2016	Dw	R63207	102	Added final step to delete rows from CPASENDDEBTORS for cases whose property type is not specified in the 'CPA Multi Debtor File' site control.
-- 16 Mar 2017	MF	70809	103	When the 'CPA Multi Debtor File' site control was introduced in RFC63207 we did not take this into consideration when determining if a Case needs to be reported or not.
-- 30 Nov 2017	MF	73047	104	Strip any line feed characters from text fields that should not have them.
-- 16 May 2018	MF	74147	105	When extracting details from RELATEDCASE, take any associated date into consideration to cater for the possibility of
--					multiple related cases for any given relationship.  To determine the parent Case where the relationship is undefined 
--					we will use a dummy relationship of '???' to determine the best related case to use.
-- 14 Nov 2018  AV	DR-45358 106	Date conversion errors when creating cases and opening names in Chinese DB
-- 01 Apr 2019	MF	DR-47886 107	Revisit of RFC 74147.  When determining the Parent to report, the Relationship must be flagged as pointing to a parent.
-- 26 Mar 2020	DL	DR-58353 108 Performance enhancement: Unable to create a batch via the CPA Interface Not Responding




set nocount on
set concat_null_yields_null off
set ansi_warnings off

-- Table of cases to be extracted.

Create table	#TEMPDATATOSEND 
		(
			CASEID			int,
			NAMENO			int,
			INSTRUCTIONCODE		smallint
		)

-- Temporary table containing the CPA Renewal Type

Create table	#TEMPCASERENEWALTYPE 
		(
			CASEID			int,
			RENEWALTYPECODE		varchar(2) collate database_default
		)

Create table	#TEMPCPAUPDATETODELETE
		(
			NAMEID			int	null,
			CASEID			int	null
		)

-- Temporary table of the extracted data

Create table	#TEMPCPASEND
		(	SYSTEMID		varchar(3)	collate database_default NULL,
			PROPERTYTYPE		char(1)		collate database_default NULL,
			CASECODE		varchar(15)	collate database_default NULL,
			TRANSACTIONCODE		smallint	NULL,
			ALTOFFICECODE		varchar(3)	collate database_default NULL,
			CASEID			int		NULL,
			FILENUMBER		varchar(15)	collate database_default NULL,
			CLIENTSREFERENCE	varchar(35)	collate database_default NULL,
			CPACOUNTRYCODE		varchar(2)	collate database_default NULL,
			RENEWALTYPECODE		varchar(2)	collate database_default NULL,
			MARK			varchar(100)	collate database_default NULL,
			ENTITYSIZE		char(1)		collate database_default NULL,
			PRIORITYDATE		datetime	NULL,
			PARENTDATE		datetime	NULL,
			NEXTTAXDATE		datetime	NULL,
			NEXTDECOFUSEDATE	datetime	NULL,
			PCTFILINGDATE		datetime	NULL,
			ASSOCDESIGNDATE		datetime	NULL,
			NEXTAFFIDAVITDATE	datetime	NULL,
			APPLICATIONDATE		datetime	NULL,
			ACCEPTANCEDATE		datetime	NULL,
			PUBLICATIONDATE		datetime	NULL,
			REGISTRATIONDATE	datetime	NULL,
			RENEWALDATE		datetime	NULL,
			NOMINALWORKINGDATE	datetime	NULL,
			EXPIRYDATE		datetime	NULL,
			CPASTARTPAYDATE		datetime	NULL,
			CPASTOPPAYDATE		datetime	NULL,
			STOPPAYINGREASON	char(1)		collate database_default NULL,
			PRIORITYNO		varchar(30)	collate database_default NULL,
			PARENTNO		varchar(30)	collate database_default NULL,
			PCTFILINGNO		varchar(30)	collate database_default NULL,
			ASSOCDESIGNNO		varchar(30)	collate database_default NULL,
			APPLICATIONNO		varchar(30)	collate database_default NULL,
			ACCEPTANCENO		varchar(30)	collate database_default NULL,
			PUBLICATIONNO		varchar(30)	collate database_default NULL,
			REGISTRATIONNO		varchar(30)	collate database_default NULL,
			INTLCLASSES		varchar(150)	collate database_default NULL,
			LOCALCLASSES		varchar(150)	collate database_default NULL,
			NUMBEROFYEARS		smallint	NULL,
			NUMBEROFCLAIMS		smallint	NULL,
			NUMBEROFDESIGNS		smallint	NULL,
			NUMBEROFCLASSES		smallint	NULL,
			NUMBEROFSTATES		smallint	NULL,
			DESIGNATEDSTATES	varchar(200)	collate database_default NULL,
			OWNERNAMECODE		varchar(20)	collate database_default NULL,
			OWNERNAME		varchar(100)	collate database_default NULL,
			OWNADDRESSCODE		int		NULL,
			OWNADDRESSLINE1		varchar(50)	collate database_default NULL,
			OWNADDRESSLINE2		varchar(50)	collate database_default NULL,
			OWNADDRESSLINE3		varchar(50)	collate database_default NULL,
			OWNADDRESSLINE4		varchar(50)	collate database_default NULL,
			OWNADDRESSCOUNTRY	varchar(50)	collate database_default NULL,
			OWNADDRESSPOSTCODE	varchar(16)	collate database_default NULL,
			CLIENTCODE		varchar(15)	collate database_default NULL,
			CPACLIENTNO		int		NULL,
			CLIENTNAME		varchar(100)	collate database_default NULL,
			CLIENTATTENTION		varchar(50)	collate database_default NULL,
			CLTADDRESSCODE		int		NULL,
			CLTADDRESSLINE1		varchar(50)	collate database_default NULL,
			CLTADDRESSLINE2		varchar(50)	collate database_default NULL,
			CLTADDRESSLINE3		varchar(50)	collate database_default NULL,
			CLTADDRESSLINE4		varchar(50)	collate database_default NULL,
			CLTADDRESSCOUNTRY	varchar(50)	collate database_default NULL,
			CLTADDRESSPOSTCODE	varchar(16)	collate database_default NULL,
			CLIENTTELEPHONE		varchar(20)	collate database_default NULL,
			CLIENTFAX		varchar(20)	collate database_default NULL,
			CLIENTEMAIL		varchar(100)	collate database_default NULL,
			DIVISIONCODE		varchar(6)	collate database_default NULL,
			DIVISIONNAME		varchar(100)	collate database_default NULL,
			DIVISIONATTENTION	varchar(50)	collate database_default NULL,
			DIVADDRESSCODE		int		NULL,
			DIVADDRESSLINE1		varchar(50)	collate database_default NULL,
			DIVADDRESSLINE2		varchar(50)	collate database_default NULL,
			DIVADDRESSLINE3		varchar(50)	collate database_default NULL,
			DIVADDRESSLINE4		varchar(50)	collate database_default NULL,
			DIVADDRESSCOUNTRY	varchar(50)	collate database_default NULL,
			DIVADDRESSPOSTCODE	varchar(16)	collate database_default NULL,
			FOREIGNAGENTCODE	varchar(8)	collate database_default NULL,
			FOREIGNAGENTNAME	varchar(100)	collate database_default NULL,
			ATTORNEYCODE		varchar(8)	collate database_default NULL,
			ATTORNEYNAME		varchar(100)	collate database_default NULL,
			INVOICEECODE		varchar(15)	collate database_default NULL,
			CPAINVOICEENO		int		NULL,
			INVOICEENAME		varchar(100)	collate database_default NULL,
			INVOICEEATTENTION	varchar(50)	collate database_default NULL,
			INVADDRESSCODE		int		NULL,
			INVADDRESSLINE1		varchar(50)	collate database_default NULL,
			INVADDRESSLINE2		varchar(50)	collate database_default NULL,
			INVADDRESSLINE3		varchar(50)	collate database_default NULL,
			INVADDRESSLINE4		varchar(50)	collate database_default NULL,
			INVADDRESSCOUNTRY	varchar(50)	collate database_default NULL,
			INVADDRESSPOSTCODE	varchar(16)	collate database_default NULL,
			INVOICEETELEPHONE	varchar(20)	collate database_default NULL,
			INVOICEEFAX		varchar(20)	collate database_default NULL,
			INVOICEEEMAIL		varchar(100)	collate database_default NULL,
			INVOICEENAMETYPE	nvarchar(3)	collate database_default NULL,
			NARRATIVE		varchar(50)	collate database_default NULL,
			IPRURN			varchar(7)	collate database_default NULL,
			CONVENTION		tinyint		NULL,
			-- SQA14599 new columns required to determine the CPA Account to use
			INTERCEPTFLAG		bit		NULL,
			OWNERNAMENO		int		NULL,
			ATTORNEYNAMENO		int		NULL,
			REALCLIENTNAMENO	int		NULL,
			HOMENAMENO		int		NULL,
			DELETECANDIDATE		bit		default 0
 )
 
 -------------------------------------------------------------------------------------------------------------------
 -- RFC57212
 -- Temporary table that will report multi debtors.
 -- If the Case has more than one debtor they will all be reported in the CPASENDDEBTORS table.
 -- If the Case previously had more than one debtor but only 1 now then it will be reported in CPASENDDEBTORS table.
 -------------------------------------------------------------------------------------------------------------------
 CREATE TABLE dbo.#TEMPCPASENDDEBTORS (
 			CASEID			int		NOT NULL,
 			NAMETYPE		nvarchar(3)	collate database_default NOT NULL ,
 			INVOICEECODE		nvarchar(15)	collate database_default NULL ,
 			CPAINVOICEENO		int		NULL ,
 			BILLPERCENTAGE		decimal(5,2)	NULL 
 )

-- Need a temporary POLICING table to allocate a unique sequence number.

CREATE TABLE #TEMPPOLICING (
			POLICINGSEQNO		int	identity(0,1),
			CASEID			int
 )

CREATE TABLE #TEMPRELATEDCASE(
			CASEID			int		NOT NULL,
			RELATIONSHIP		nvarchar(3)	collate database_default NOT NULL,
			EARLIESTDATE		datetime	NULL,
			RELATEDCASEID		int		NULL,
			OFFICIALNUMBER		nvarchar(36)	collate database_default NULL,
			SEQUENCENO		int		identity(1,1)		
)

declare	@ErrorCode		int
declare @nDeletedCount		int
declare @RowCount		int
declare	@TranCountStart		int
declare	@sSQLString		nvarchar(4000)
declare	@sSQLString1		nvarchar(4000)
declare	@sSQLString2		nvarchar(4000)
declare	@sSQLString3		nvarchar(4000)
declare	@sSQLString4		nvarchar(4000)
declare	@sSQLString5		nvarchar(4000)
declare	@sSQLString6		nvarchar(4000)
declare	@sSQLString7		nvarchar(4000)
declare	@sSQLString8		nvarchar(4000)
declare @sDebtorPropertyTypes	nvarchar(254)
declare	@sProcedureName		varchar(30)
declare @nBatchNo		int
declare @sCPAUserCode		varchar(3)
declare @sCPANameType		varchar(3)
declare	@sAssocDesign		varchar(3)
declare	@sEarliestPriority	varchar(3)
declare @sPCTFiling		varchar(3)
declare @nCPAInterceptFlag	int
declare @nHomeNameNo		int
declare @bDummyBatchFlag	bit
declare @bAttorneyAsCPAClient	bit
declare @bNameAddressCPAClient	bit --SQA16334
declare @bDivisionCodeTruncation bit -- SQA18280
declare @bConsiderAllCPACases bit -- SQA17347
declare @bUseClientCaseCode	bit -- SQA20231

-- The EventNos to be extrated
declare @nPriorityEventNo	int
declare @nParentEventNo		int
declare @nNextQuinTaxEventNo	int
declare @nNextDecOfUseEventNo	int
declare @nPCTFilingEventNo	int
declare @nAssocDesignEventNo	int
declare @nAffidavitEventNo	int
declare @nApplicationEventNo	int
declare @nAcceptanceEventNo	int
declare @nPublicationEventNo	int
declare @nNominalWorkingEventNo	int
declare @nRegistrationEventNo	int
declare @nNextRenewalEventNo	int
declare @nExpiryEventNo		int
declare @nCPAStartEventNo	int
declare @nCPAStopEventNo	int
declare	@nCPASentEventNo	int
declare @nCPARejectedEventNo	int

-- The NumberTypes to be extracted
declare @sApplicationNumberType	 nvarchar(20)
declare @sPublicationNumberType	 nvarchar(20)
declare	@sAcceptanceNumberType	 nvarchar(20)
declare @sRegistrationNumberType nvarchar(20)
declare @sFileNumberType	 nvarchar(3)
declare @sClientsReferenceType	 nvarchar(30) -- SQA18243
declare @sParentExclude		 nvarchar(500) -- SQA18372
declare @sDivisionCodeAliasType  nvarchar(2) -- SQA18402
declare @sClientsReferenceDocItem  nvarchar(4000) -- SQA18962
declare @sPCTFilingNumberType	 nvarchar(20) -- SQA21344


-- Flag to indicate that CPA hold the CASEID instead of the IRN
declare @bCaseIdFlag		bit

Select	@ErrorCode	=0
Select	@TranCountStart	=0

-- Reduce the isolation level to one that will not cause blocking if the 
-- process runs for an extended period of time.

set transaction isolation level read uncommitted

-- Get the name of the clients Stored Procedure for determining
-- the cases that will be sent to CPA.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Select	@sProcedureNameOUT=S.COLCHARACTER
	From	SITECONTROL S
	Where	S.CONTROLID = 'CPA Extract Proc'"

	Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@sProcedureNameOUT	varchar(30) OUTPUT',
					  @sProcedureNameOUT=@sProcedureName OUTPUT

End

-- Use the stored procedure identified by the Site Control to execute dynamically

If @ErrorCode=0
Begin
	If @psOfficeCPACode is not null
	Begin
		Set @sSQLString='Exec @ErrorCode='+@sProcedureName+' '
				+isnull(convert(varchar,@pnCaseId)      ,'NULL')+','
				+Case When(@psPropertyType is null) Then 'NULL' Else "'"+@psPropertyType+"'" End+','
				+isnull(convert(varchar,@pnNotProperty) ,'NULL')+','
				+isnull(convert(varchar,@pnNewCases)    ,'NULL')+','
				+isnull(convert(varchar,@pnChangedCases),'NULL')+','
				+isnull(convert(varchar,@pbCheckInstruction),'1')+','
				+"'"+@psOfficeCPACode+"'"
	
		Exec sp_executesql @sSQLString,
					N'@ErrorCode	int	output',
					  @ErrorCode=@ErrorCode	output
	End
	Else Begin
		Set @sSQLString='Exec @ErrorCode='+@sProcedureName+' '
				+isnull(convert(varchar,@pnCaseId)      ,'NULL')+','
				+Case When(@psPropertyType is null) Then 'NULL' Else "'"+@psPropertyType+"'" End+','
				+isnull(convert(varchar,@pnNotProperty) ,'NULL')+','
				+isnull(convert(varchar,@pnNewCases)    ,'NULL')+','
				+isnull(convert(varchar,@pnChangedCases),'NULL')+','
				+isnull(convert(varchar,@pbCheckInstruction),'1')
	End
	
	Exec sp_executesql @sSQLString,
				N'@ErrorCode	int	output',
				  @ErrorCode=@ErrorCode	output
End

-- If there no rows already in CPASEND and the CPAPORTFOLIO exists then turn on a flag
-- to indicate that a dummy EPL batch is to be generated and loaded into CPARECEIVE.  This
-- is part of the initialisation process to ensure that we have a record of Cases having been 
-- sent to CPA even if they were sent before the CPA Interface was implemented.

Set @bDummyBatchFlag=0

If @psOfficeCPACode is not null
begin
	If not exists (	select * from CPASEND CPA
			join CASES C  on (C.CASEID=CPA.CASEID)
			join OFFICE O on (O.OFFICEID=C.OFFICEID)
			where O.CPACODE=@psOfficeCPACode)
	and    exists ( select * from CPAPORTFOLIO CPA
			join CASES C  on (C.CASEID=CPA.CASEID)
			join OFFICE O on (O.OFFICEID=C.OFFICEID)
			where O.CPACODE=@psOfficeCPACode)
	Begin
		Set @bDummyBatchFlag=1
	End
End
Else Begin
	If not exists (select * from CPASEND)
	and    exists (select * from CPAPORTFOLIO)
	Begin
		Set @bDummyBatchFlag=1
	End
End


-- Get the client specific mappings from SITECONTROL

If @ErrorCode=0
Begin
	select @sSQLString="
	Select	@sCPAUserCodeOUT	=S1.COLCHARACTER,
		@nPriorityEventNoOUT	=S2.COLINTEGER,
		@nParentEventNoOUT	=S3.COLINTEGER,
		@nNextQuinTaxEventNoOUT	=S4.COLINTEGER,
		@nNextDecOfUseEventNoOUT=S0.COLINTEGER,
		@nPCTFilingEventNoOUT	=S5.COLINTEGER,
		@nAssocDesignEventNoOUT	=S6.COLINTEGER,
		@nAffidavitEventNoOUT	=S7.COLINTEGER,
		@nApplicationEventNoOUT	=S8.COLINTEGER,
		@nAcceptanceEventNoOUT	=S9.COLINTEGER,
		@nPublicationEventNoOUT	=S10.COLINTEGER,
		@nNominalWorkingEventNoOUT	=S11.COLINTEGER
	from	  SITECONTROL S1
	left join SITECONTROL S2  on (S2.CONTROLID ='CPA Date-Priority')
	left join SITECONTROL S3  on (S3.CONTROLID ='CPA Date-Parent')
	left join SITECONTROL S4  on (S4.CONTROLID ='CPA Date-Quin Tax')
	left join SITECONTROL S0  on (S0.CONTROLID ='CPA Date-Intent Use')
	left join SITECONTROL S5  on (S5.CONTROLID ='CPA Date-PCT Filing')
	left join SITECONTROL S6  on (S6.CONTROLID ='CPA Date-Assoc Des')
	left join SITECONTROL S7  on (S7.CONTROLID ='CPA Date-Affidavit')
	left join SITECONTROL S8  on (S8.CONTROLID ='CPA Date-Filing')
	left join SITECONTROL S9  on (S9.CONTROLID ='CPA Date-Acceptance')
	left join SITECONTROL S10 on (S10.CONTROLID='CPA Date-Publication')
	left join SITECONTROL S11 on (S11.CONTROLID='CPA Date-Nominal')
	where S1.CONTROLID='CPA User Code'
	"

	Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@sCPAUserCodeOUT		varchar(3)	OUTPUT,
					  @nPriorityEventNoOUT		int 		OUTPUT,
					  @nParentEventNoOUT		int 		OUTPUT,
					  @nNextQuinTaxEventNoOUT	int 		OUTPUT,
					  @nNextDecOfUseEventNoOUT	int		OUTPUT,
					  @nPCTFilingEventNoOUT		int 		OUTPUT,
					  @nAssocDesignEventNoOUT	int 		OUTPUT,
					  @nAffidavitEventNoOUT		int 		OUTPUT,
					  @nApplicationEventNoOUT	int 		OUTPUT,
					  @nAcceptanceEventNoOUT	int 		OUTPUT,
					  @nPublicationEventNoOUT	int 		OUTPUT,
					  @nNominalWorkingEventNoOUT	int 		OUTPUT',
					  @sCPAUserCodeOUT        =@sCPAUserCode	OUTPUT,
					  @nPriorityEventNoOUT    =@nPriorityEventNo	OUTPUT,
					  @nParentEventNoOUT      =@nParentEventNo	OUTPUT,
					  @nNextQuinTaxEventNoOUT =@nNextQuinTaxEventNo	OUTPUT,
					  @nNextDecOfUseEventNoOUT=@nNextDecOfUseEventNo OUTPUT,
					  @nPCTFilingEventNoOUT   =@nPCTFilingEventNo	OUTPUT,
					  @nAssocDesignEventNoOUT =@nAssocDesignEventNo	OUTPUT,
					  @nAffidavitEventNoOUT   =@nAffidavitEventNo	OUTPUT,
					  @nApplicationEventNoOUT =@nApplicationEventNo	OUTPUT,
					  @nAcceptanceEventNoOUT  =@nAcceptanceEventNo	OUTPUT,
					  @nPublicationEventNoOUT =@nPublicationEventNo	OUTPUT,
					  @nNominalWorkingEventNoOUT =@nNominalWorkingEventNo	OUTPUT
End

-- Get the second group of client specific mappings from SITECONTROL

If @ErrorCode=0
Begin
	select @sSQLString="
	Select	@nRegistrationEventNoOUT=S11.COLINTEGER,
		@nNextRenewalEventNoOUT =S12.COLINTEGER,
		@nExpiryEventNoOUT      =S13.COLINTEGER,
		@nCPAStartEventNoOUT    =S14.COLINTEGER,
		@nCPAStopEventNoOUT     =S15.COLINTEGER,
		@nCPASentEventNoOUT     =S16.COLINTEGER,
		@sCPANameTypeOUT	=S17.COLCHARACTER,
		@nCPAInterceptFlagOUT	=isnull(S18.COLINTEGER,99999),
		@nHomeNameNoOUT         =S19.COLINTEGER,
		@sAssocDesignOUT	=S20.COLCHARACTER,
		@sEarliestPriorityOUT	=S21.COLCHARACTER,
		@nCPARejectedEventNoOUT =S22.COLINTEGER,
		@sPCTFilingOUT		=S23.COLCHARACTER
	from	  SITECONTROL S1
	left join SITECONTROL S11 on (S11.CONTROLID='CPA Date-Registratn')
	left join SITECONTROL S12 on (S12.CONTROLID='CPA Date-Renewal')
	left join SITECONTROL S13 on (S13.CONTROLID='CPA Date-Expiry')
	left join SITECONTROL S14 on (S14.CONTROLID='CPA Date-Start')
	left join SITECONTROL S15 on (S15.CONTROLID='CPA Date-Stop')
	left join SITECONTROL S16 on (S16.CONTROLID='CPA Sent Event')
	left join SITECONTROL S17 on (S17.CONTROLID='CPA User Name Type')
	left join SITECONTROL S18 on (S18.CONTROLID='CPA Intercept Flag')
	left join SITECONTROL S19 on (S19.CONTROLID='HOMENAMENO')
	left join SITECONTROL S20 on (S20.CONTROLID='CPA Assoc Design')
	left join SITECONTROL S21 on (S21.CONTROLID='Earliest Priority')
	left join SITECONTROL S22 on (S22.CONTROLID='CPA Rejected Event')
	left join SITECONTROL S23 on (S23.CONTROLID='CPA PCT FILING')
	where S1.CONTROLID='CPA User Code'
	"

	Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@nRegistrationEventNoOUT	int 		OUTPUT,
					  @nNextRenewalEventNoOUT	int 		OUTPUT,
					  @nExpiryEventNoOUT		int 		OUTPUT,
					  @nCPAStartEventNoOUT		int 		OUTPUT,
					  @nCPAStopEventNoOUT		int 		OUTPUT,
					  @nCPASentEventNoOUT		int 		OUTPUT,
					  @sCPANameTypeOUT		varchar(3)	OUTPUT,
					  @nCPAInterceptFlagOUT		int		OUTPUT,
					  @nHomeNameNoOUT		int		OUTPUT,
					  @sAssocDesignOUT		varchar(3)	OUTPUT,
					  @sEarliestPriorityOUT		varchar(3)	OUTPUT,
					  @nCPARejectedEventNoOUT	int		OUTPUT,
					  @sPCTFilingOUT		varchar(3)	OUTPUT',
					  @nRegistrationEventNoOUT=@nRegistrationEventNo OUTPUT,
					  @nNextRenewalEventNoOUT =@nNextRenewalEventNo	OUTPUT,
					  @nExpiryEventNoOUT      =@nExpiryEventNo	OUTPUT,
					  @nCPAStartEventNoOUT    =@nCPAStartEventNo	OUTPUT,
					  @nCPAStopEventNoOUT     =@nCPAStopEventNo	OUTPUT,
					  @nCPASentEventNoOUT     =@nCPASentEventNo	OUTPUT,
					  @sCPANameTypeOUT        =@sCPANameType	OUTPUT,
					  @nCPAInterceptFlagOUT   =@nCPAInterceptFlag	OUTPUT,
					  @nHomeNameNoOUT         =@nHomeNameNo		OUTPUT,
					  @sAssocDesignOUT	  =@sAssocDesign	OUTPUT,
					  @sEarliestPriorityOUT	  =@sEarliestPriority	OUTPUT,
					  @nCPARejectedEventNoOUT =@nCPARejectedEventNo	OUTPUT,
					  @sPCTFilingOUT	  =@sPCTFiling		OUTPUT
End

-- Get the number types for client specific mappings from SITECONTROL
-- Also get the SiteControl to indicate that CASEID is to be sent to CPA instead of IRN

If @ErrorCode=0
Begin
	select @sSQLString="
	Select	@sApplicationNumberType ='6,'+isnull(S24.COLCHARACTER,'A'),
		@sAcceptanceNumberType  ='7,'+isnull(S25.COLCHARACTER,'C'),
		@sPublicationNumberType ='8,'+isnull(S26.COLCHARACTER,'P'),
		@sRegistrationNumberType='9,'+isnull(S27.COLCHARACTER,'R'),
		@bCaseIdFlag            =S28.COLBOOLEAN,
		@sFileNumberType        =S29.COLCHARACTER,
		@bAttorneyAsCPAClient	=S30.COLBOOLEAN,
		@bNameAddressCPAClient	=S31.COLBOOLEAN, --SQA16334
		@sClientsReferenceType  =S32.COLCHARACTER, -- SQA18243
		@bDivisionCodeTruncation=S33.COLBOOLEAN ,-- SQA18280
		@bConsiderAllCPACases   =S34.COLBOOLEAN, -- SQA17347
		@sParentExclude	        =dbo.fn_WrapQuotes(S35.COLCHARACTER,1,0), -- SQA18372
		@sDivisionCodeAliasType =S36.COLCHARACTER, -- SQA18402
		@bUseClientCaseCode	=S37.COLBOOLEAN, -- SQA20231
		@sPCTFilingNumberType	=dbo.fn_WrapQuotes(S38.COLCHARACTER,1,0) -- SQA21344
	from	  SITECONTROL S1
	left join SITECONTROL S24 on (S24.CONTROLID='CPA Number-Application')
	left join SITECONTROL S25 on (S25.CONTROLID='CPA Number-Acceptance')
	left join SITECONTROL S26 on (S26.CONTROLID='CPA Number-Publication')
	left join SITECONTROL S27 on (S27.CONTROLID='CPA Number-Registration')
	left join SITECONTROL S28 on (S28.CONTROLID='CPA Use CaseId as Case Code')
	left join SITECONTROL S29 on (S29.CONTROLID='CPA File Number Type')
	left join SITECONTROL S30 on (S30.CONTROLID='CPA Use Attorney as Client')
	left join SITECONTROL S31 on (S31.CONTROLID='CPA Use NameAddress CPA Client')
	left join SITECONTROL S32 on (S32.CONTROLID='CPA Clients Reference Type') 
	left join SITECONTROL S33 on (S33.CONTROLID='CPA Division Code Truncation')
	left join SITECONTROL S34 on (S34.CONTROLID='CPA Consider All CPA Cases')
	left join SITECONTROL S35 on (S35.CONTROLID='CPA Parent Exclude')
	left join SITECONTROL S36 on (S36.CONTROLID='CPA Division Code Alias Type')
	left join SITECONTROL S37 on (S37.CONTROLID='CPA-Use ClientCaseCode')
	left join SITECONTROL S38 on (S38.CONTROLID='CPA Number-PCTFiling')
	where S1.CONTROLID='CPA User Code'
	"

	Exec @ErrorCode=sp_executesql @sSQLString, 
					N'@sApplicationNumberType	nvarchar(20) 		OUTPUT,
					  @sAcceptanceNumberType	nvarchar(20) 		OUTPUT,
					  @sPublicationNumberType	nvarchar(20) 		OUTPUT,
					  @sRegistrationNumberType	nvarchar(20) 		OUTPUT,
					  @bCaseIdFlag	  		bit	 		OUTPUT,
					  @sFileNumberType		nvarchar(3)		OUTPUT,
					  @bAttorneyAsCPAClient		bit			OUTPUT,
					  @bNameAddressCPAClient	bit			OUTPUT,
					  @sClientsReferenceType	nvarchar(30)		OUTPUT,
					  @bDivisionCodeTruncation	bit			OUTPUT,
					  @bConsiderAllCPACases		bit			OUTPUT,
					  @sParentExclude		nvarchar(500)		OUTPUT,
					  @sDivisionCodeAliasType	nvarchar(2)		OUTPUT,
					  @bUseClientCaseCode		bit			OUTPUT,
					  @sPCTFilingNumberType		nvarchar(20) 		OUTPUT',
					  @sApplicationNumberType =@sApplicationNumberType	OUTPUT,
					  @sAcceptanceNumberType  =@sAcceptanceNumberType	OUTPUT,
					  @sPublicationNumberType =@sPublicationNumberType	OUTPUT,
					  @sRegistrationNumberType=@sRegistrationNumberType	OUTPUT,
					  @bCaseIdFlag            =@bCaseIdFlag			OUTPUT,
					  @sFileNumberType	  =@sFileNumberType		OUTPUT,
					  @bAttorneyAsCPAClient	  =@bAttorneyAsCPAClient	OUTPUT,
					  @bNameAddressCPAClient  =@bNameAddressCPAClient	OUTPUT,
					  @sClientsReferenceType  =@sClientsReferenceType	OUTPUT,
					  @bDivisionCodeTruncation=@bDivisionCodeTruncation	OUTPUT,
					  @bConsiderAllCPACases	  =@bConsiderAllCPACases	OUTPUT,
					  @sParentExclude	  =@sParentExclude		OUTPUT,
					  @sDivisionCodeAliasType = @sDivisionCodeAliasType 	OUTPUT,
					  @bUseClientCaseCode	  = @bUseClientCaseCode		OUTPUT,
					  @sPCTFilingNumberType	  = @sPCTFilingNumberType	OUTPUT
End

-- Get the CPA Renewal Type for each case to  be sent to CPA
-- This is done as a separate insert into a temporary table because SQLServer does 
-- not allow an Update where the SET contains an aggregate.

If @ErrorCode=0
Begin
	set @sSQLString="
	Insert into #TEMPCASERENEWALTYPE (CASEID, RENEWALTYPECODE)
	select	T.CASEID,
							-- To determine the best CPA Renewal Type a weighting is	
							-- given based on the existence of characteristics	
							-- found in the CRITERIA row.  The MAX function 
							-- returns the highest weighting to which the required	
							-- RENEWALTYPCODE has been concatenated.	
		substring(max (
		CASE WHEN(CR.PROPERTYTYPE 	is not null) THEN '1' ELSE '0' END +
		CASE WHEN(CR.COUNTRYCODE	is not null) THEN '1' ELSE '0' END +
		CASE WHEN(CR.CASECATEGORY	is not null) THEN '1' ELSE '0' END +
		CASE WHEN(CR.SUBTYPE		is not null) THEN '1' ELSE '0' END +
		CASE WHEN(CR.TABLECODE		is not null) THEN '1' ELSE '0' END +
		convert(nvarchar(2),TC.USERCODE)),6,2)
	From	#TEMPDATATOSEND T
	join	CASES C		on (C.CASEID=T.CASEID)
	join	PROPERTY P	on (P.CASEID=T.CASEID)
	join	CRITERIA CR	on ( CR.PURPOSECODE='A'
				and (CR.PROPERTYTYPE    =C.PROPERTYTYPE OR CR.PROPERTYTYPE        is NULL)
				and (CR.COUNTRYCODE     =C.COUNTRYCODE  OR CR.COUNTRYCODE         is NULL) 
				and (CR.CASECATEGORY    =C.CASECATEGORY OR CR.CASECATEGORY        is NULL)
				and (CR.SUBTYPE         =C.SUBTYPE      OR CR.SUBTYPE             is NULL)
				and (CR.TABLECODE       =P.RENEWALTYPE  OR CR.TABLECODE           is NULL) )
	join	TABLECODES TC	on ( TC.TABLECODE	=CR.RENEWALTYPE)
	group by T.CASEID"

	Execute @ErrorCode=sp_executesql @sSQLString

End

-- Load the CPASEND table for Cases with an initial INSERT followed by a series of UPDATEs

If @ErrorCode=0
Begin	
	-- SQA21580 Added "WHEN(C.ENTITYSIZE =-42846999)	THEN 'M'" for renewal type Micro Entity
	Set @sSQLString="
	insert into #TEMPCPASEND
		(SYSTEMID, ALTOFFICECODE, PROPERTYTYPE, CASECODE, TRANSACTIONCODE, CASEID, CLIENTSREFERENCE,
		CPACOUNTRYCODE,	RENEWALTYPECODE, MARK, ENTITYSIZE, INTLCLASSES,LOCALCLASSES,
		NUMBEROFYEARS, NUMBEROFCLAIMS, NUMBEROFDESIGNS, NUMBEROFCLASSES,
		CPACLIENTNO, CLIENTCODE, CLIENTNAME, CLTADDRESSCODE, CLIENTTELEPHONE, CLIENTFAX, CLIENTEMAIL, 
		IPRURN, CONVENTION, STOPPAYINGREASON,INTERCEPTFLAG,REALCLIENTNAMENO,HOMENAMENO)
	Select	distinct
		'"+@sCPAUserCode+"',
		left(isnull(NA.ALIAS,O.CPACODE),3),
		CASE WHEN(C.PROPERTYTYPE in ('T','D')) THEN C.PROPERTYTYPE ELSE 'P' END,"+char(10)+
		CASE WHEN(@bCaseIdFlag=1) 
			THEN "		cast(C.CASEID as varchar(15)),"
			ELSE "		left(C.IRN,15),"
		 END +"
		CASE WHEN(CPA.CASEID is null) THEN 12 ELSE 21 END,  T.CASEID,
		-- Use first 35 characters of the Case Title if no client reference
		CASE WHEN(C.PROPERTYTYPE='T') 
			THEN left(CI.REFERENCENO,35)
			ELSE left(isnull(CI.REFERENCENO, replace(replace(C.TITLE,char(13)+char(10),' '),char(9),' ')),35)
		END,
		left(isnull( CT.ALTERNATECODE, CT.COUNTRYCODE),2),
		left(isnull(TC.USERCODE, TR.RENEWALTYPECODE),2),
		CASE WHEN(C.PROPERTYTYPE='T') THEN left(replace(replace(C.TITLE,char(13)+char(10),' '),char(9),' '),100) END, 
		CASE WHEN(C.ENTITYSIZE=2601)                THEN 'L'
		     WHEN(C.ENTITYSIZE in (2602,2603,2604)) THEN 'S'
		     WHEN(C.ENTITYSIZE =-42846999)	    THEN 'M'
		END,
		CASE WHEN(C.PROPERTYTYPE='T') THEN
			CASE WHEN (C.INTCLASSES like '0%') 
				THEN substring(replace(C.INTCLASSES,',0',','),2,150)
				ELSE substring(replace(C.INTCLASSES,',0',','),1,150)
			END
		END,
		CASE WHEN(C.PROPERTYTYPE='T') THEN
			CASE WHEN (C.LOCALCLASSES like '0%')
				THEN substring(replace(C.LOCALCLASSES,',0',','),2,150)
				ELSE substring(replace(C.LOCALCLASSES,',0',','),1,150)
			END
		END,
		C.EXTENDEDRENEWALS, P.NOOFCLAIMS, C.NOINSERIES, C.NOOFCLASSES,
		CPACLIENTNO=CASE WHEN(ISNUMERIC(NC.ALIAS)=1) THEN CAST(NC.ALIAS as INT) END,
		NI.NAMECODE, 
		left(rtrim(CASE WHEN NI.FIRSTNAME is NULL THEN NI.NAME ELSE NI.NAME+','+NI.FIRSTNAME END),100),
		NI.POSTALADDRESS,"
--		SQA 18287 Simply pass the main postal address for the instructor. 
--		Do not send the address held at case level since CPA can only hold one address for an instructor.
--		CASE WHEN(CI.NAMENO=NI.NAMENO) THEN isnull(CI.ADDRESSCODE,NI.POSTALADDRESS) ELSE NI.POSTALADDRESS END,

	Set @sSQLString1="
		CASE WHEN(PH.TELECODE  is not null) THEN left(ltrim( PH.ISD+' '+CASE WHEN( PH.AREACODE is not null) THEN  PH.AREACODE+' 'END+ PH.TELECOMNUMBER),20) END,
		CASE WHEN(FAX.TELECODE is not null) THEN left(ltrim(FAX.ISD+' '+CASE WHEN(FAX.AREACODE is not null) THEN FAX.AREACODE+' 'END+FAX.TELECOMNUMBER),20) END,
		EM.TELECOMNUMBER, coalesce(CPA1.IPRURN, CPA2.IPRURN, CPA3.IPRURN), B.CONVENTION, C.STOPPAYREASON,
		CASE WHEN(NI.NAMENO="+convert(varchar,@nHomeNameNo)+") THEN 1 ELSE 0 END,
		CI.NAMENO,"+convert(varchar,@nHomeNameNo)+"
	From	#TEMPDATATOSEND T
	     join CASES C		on (C.CASEID=T.CASEID)
	     join COUNTRY CT		on (CT.COUNTRYCODE=C.COUNTRYCODE)
	left join OFFICE O		on (O.OFFICEID=C.OFFICEID)
	left join PROPERTY P		on (P.CASEID=C.CASEID)
	left join APPLICATIONBASIS B	on (B.BASIS=P.BASIS)
	left join TABLECODES TC		on (TC.TABLECODE=P.RENEWALTYPE)
	left join #TEMPCASERENEWALTYPE TR
					on (TR.CASEID=T.CASEID)
	left join CASENAME CN		on (CN.CASEID=C.CASEID
					and CN.NAMETYPE='"+@sCPANameType+"'
					and CN.EXPIRYDATE is null)
	left join NAMEALIAS NA		on (NA.NAMENO=CN.NAMENO
					and NA.ALIASTYPE='CP')    
	-- 20231 Collect relevant IPRURN. Change to collect from EPL if available, 
	-- then from Portfolio if responsibility matches (live first then other).
/*	
	-- There is a possibility that CPA will have more than one entry on the
	-- portfolio for a Case.  We will take the lowest IPRURN.
	left join (	select CASEID, min(IPRURN) as IPRURN
			from CPAPORTFOLIO
			group by CASEID) CPA1
					on (CPA1.CASEID=C.CASEID)
*/
	-- Collect IPRURN from most recent CPARECEIVE
	left join ( select C1.CASEID, CR.IPRURN
			from CASES C1
			join CPARECEIVE CR on (CR.CASEID = C1.CASEID
				and CR.BATCHNO = (select max (BATCHNO)
								  from CPARECEIVE
								  where CASEID = CR.CASEID))
			where CR.IPRURN is not null) CPA1
					on (CPA1.CASEID=C.CASEID)
	-- Or from live portfolio record where responsible party is consistent
	left join (	select CASEID, min(IPRURN) as IPRURN
			from CPAPORTFOLIO
			where STATUSINDICATOR = 'L'
			and " + CASE WHEN (@bUseClientCaseCode = 1)
			THEN " RESPONSIBLEPARTY = 'C' " ELSE " RESPONSIBLEPARTY = 'A' " END + "
			group by CASEID) CPA2
					on (CPA2.CASEID=C.CASEID)
	-- Or from dead portfolio record where responsible party is consistent
	left join (	select CASEID, min(IPRURN) as IPRURN
			from CPAPORTFOLIO
			where STATUSINDICATOR <> 'L'
			and " + CASE WHEN (@bUseClientCaseCode = 1)
			THEN " RESPONSIBLEPARTY = 'C' " ELSE " RESPONSIBLEPARTY = 'A' " END + "
			group by CASEID) CPA3
					on (CPA3.CASEID=C.CASEID)
	-- This just to determine new 12 or changed 21
			left join (	select distinct CASEID
					from CPAPORTFOLIO) CPA
					on (CPA.CASEID=C.CASEID)
	-- 
	left join CASENAME CI		on (CI.CASEID=C.CASEID
					and CI.EXPIRYDATE is null
					and CI.NAMETYPE=(select max(CI1.NAMETYPE)
							 from CASENAME CI1
							 where CI1.CASEID=C.CASEID
							 and CI1.EXPIRYDATE is null
							 and CI1.NAMETYPE in ('R','I')))"

	Set @sSQLString2="
							-- Get the Client information for CPA to contact
							-- If the Standing Instruction is one that has been
							-- flagged as requiring the Agent to act for the Agent
							-- then substitute the Agent details for the client
	left join NAME NI		on (NI.NAMENO=	CASE When(Exists (Select * from INSTRUCTIONFLAG I where I.INSTRUCTIONCODE=T.INSTRUCTIONCODE and I.FLAGNUMBER="+convert(varchar,@nCPAInterceptFlag)+"))
								THEN "+convert(varchar,@nHomeNameNo)+"
								ELSE CI.NAMENO
							END)
	left join NAME AT		on (AT.NAMENO=	CASE When(NI.NAMENO=CI.NAMENO)
								Then isnull(CI.CORRESPONDNAME,NI.MAINCONTACT)
								Else NI.MAINCONTACT
							END)
	left join TELECOMMUNICATION PH	on (PH.TELECODE =NI.MAINPHONE)
	left join TELECOMMUNICATION FAX	on (FAX.TELECODE=NI.FAX)
	left join TELECOMMUNICATION EM	on (EM.TELECODE=isnull(AT.MAINEMAIL, NI.MAINEMAIL))
	left join NAMEALIAS NC		on (NC.NAMENO	=NI.NAMENO
					and NC.ALIASTYPE='_C'
							-- SQA18703
							-- Use best fit to determine ALIAS for the Case
							-- characteristics of CountryCode and PropertyType
					and NC.ALIAS    =(select substring(max(	CASE WHEN(NC1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
										CASE WHEN(NC1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
										NC1.ALIAS),3,30)
							  from NAMEALIAS NC1
							  where NC1.NAMENO=NC.NAMENO
							  and NC1.ALIASTYPE=NC.ALIASTYPE
							  and(NC1.COUNTRYCODE =C.COUNTRYCODE  OR NC1.COUNTRYCODE  is null)
							  and(NC1.PROPERTYTYPE=C.PROPERTYTYPE OR NC1.PROPERTYTYPE is null)))"

	Exec (@sSQLString+@sSQLString1+@sSQLString2)

	Select	@ErrorCode=@@Error,
		@RowCount =@@Rowcount
End

If @ErrorCode=0
Begin
	Set @sSQLString=" 
	Update	#TEMPCPASEND
		set	DIVISIONCODE =	CASE WHEN ((@bDivisionCodeTruncation) = 1) 
							THEN substring(coalesce (DA.ALIAS, ND.NAMECODE),1,6) 
							ELSE (CASE WHEN(LEN(coalesce (DA.ALIAS, ND.NAMECODE))<=6)
									THEN coalesce (DA.ALIAS, ND.NAMECODE) END) END,
		DIVISIONNAME		=substring(rtrim(CASE WHEN ND.FIRSTNAME is NULL THEN ND.NAME ELSE ND.NAME+','+ND.FIRSTNAME END), 1, 100), 
--		SQA 20199 Simply pass the main postal address for the division. 
--		Do not send the address held at case level since CPA can only hold one address for an entity.
--		DIVADDRESSCODE		=CASE WHEN(CD.NAMENO=ND.NAMENO) THEN isnull(CD.ADDRESSCODE,ND.POSTALADDRESS) ELSE ND.POSTALADDRESS END,
		DIVADDRESSCODE		=ND.POSTALADDRESS,

		OWNERNAMECODE		=CASE WHEN(T.PROPERTYTYPE='T') THEN NO.NAMECODE END, 
		OWNERNAME		=substring(rtrim(CASE WHEN NO.FIRSTNAME is NULL THEN NO.NAME ELSE NO.NAME+','+NO.FIRSTNAME END), 1, 100),
		OWNADDRESSCODE		=CASE WHEN(T.PROPERTYTYPE='T') THEN isnull(CO.ADDRESSCODE, NO.STREETADDRESS) END,
		OWNERNAMENO		=NO.NAMENO"

	Set @sSQLString=@sSQLString+"
	From	#TEMPCPASEND T
	left join CASES C		on (C.CASEID=T.CASEID)
	left join CASENAME CD		on (CD.CASEID=T.CASEID
					and CD.EXPIRYDATE is null
					and CD.NAMETYPE='DIV'
					and CD.SEQUENCE=(select min(CD1.SEQUENCE)
							 from  CASENAME CD1
							 where CD1.CASEID=CD.CASEID
							 and   CD1.EXPIRYDATE is null
							 and   CD1.NAMETYPE=CD.NAMETYPE))
	left join NAME ND		on (ND.NAMENO=CD.NAMENO)
	left join NAME AT		on (AT.NAMENO=isnull(CD.CORRESPONDNAME, ND.MAINCONTACT))

	left join CASENAME CO		on (CO.CASEID=T.CASEID
					and CO.EXPIRYDATE is null
					and CO.NAMETYPE='O'
					and CO.SEQUENCE=(select min(CO1.SEQUENCE)
							 from  CASENAME CO1
							 where CO1.CASEID=CO.CASEID
							 and   CO1.EXPIRYDATE is null
							 and   CO1.NAMETYPE=CO.NAMETYPE))
	left join NAME NO		on (NO.NAMENO=CO.NAMENO)
	left join NAMEALIAS DA on (DA.NAMENO = ND.NAMENO
							and DA.ALIASTYPE = @sDivisionCodeAliasType )
"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@bDivisionCodeTruncation		bit,
					  @sDivisionCodeAliasType		nvarchar(2)',
					  @bDivisionCodeTruncation,
					  @sDivisionCodeAliasType
End


-- DR-58353 performance enhancement: UPDATE ATTORNEY in separate SQL to enhance performance
If @ErrorCode=0
Begin
	Set @sSQLString=" 
	Update	#TEMPCPASEND
		set	ATTORNEYCODE		=CASE WHEN(LEN(NA.NAMECODE)<=8) THEN NA.NAMECODE END, 
		ATTORNEYNAME		=substring(rtrim(CASE WHEN NA.FIRSTNAME is NULL THEN NA.NAME ELSE NA.NAME+','+NA.FIRSTNAME END), 1, 100),
		ATTORNEYNAMENO		=NA.NAMENO
		"

	-- SQA13752
	-- Get Attorney details to substitute as the CPA Client
	If @bAttorneyAsCPAClient=1
	Begin
		Set @sSQLString=@sSQLString+",
		CPACLIENTNO		=CASE WHEN(ISNUMERIC(NC.ALIAS)=1) THEN CAST(NC.ALIAS as INT) END, 
		CLIENTCODE		=NA.NAMECODE, 
		CLIENTNAME		=substring(rtrim(CASE WHEN NA.FIRSTNAME is NULL THEN NA.NAME ELSE NA.NAME+','+NA.FIRSTNAME END), 1, 100), 
		CLTADDRESSCODE		=NULL,	
		CLIENTTELEPHONE		=CASE WHEN(PH.TELECODE  is not null) THEN substring(ltrim( PH.ISD+' '+CASE WHEN( PH.AREACODE is not null) THEN  PH.AREACODE+' 'END+ PH.TELECOMNUMBER),1,20) END,
		CLIENTFAX		=CASE WHEN(FAX.TELECODE is not null) THEN substring(ltrim(FAX.ISD+' '+CASE WHEN(FAX.AREACODE is not null) THEN FAX.AREACODE+' 'END+FAX.TELECOMNUMBER),1,20) END,
		CLIENTEMAIL		=EM.TELECOMNUMBER"
	End

	Set @sSQLString=@sSQLString+"
	From	#TEMPCPASEND T
	left join CASENAME CA		on (CA.CASEID=T.CASEID
					and CA.EXPIRYDATE is null
					and CA.NAMETYPE='EMP')
	left join NAME NA		on (NA.NAMENO=CA.NAMENO)

"

	-- SQA13752
	-- Get Attorney details to substitute as the CPA Client
	If @bAttorneyAsCPAClient=1
	Begin
		Set @sSQLString=@sSQLString+"
		left join NAMEALIAS NC		on (NC.NAMENO	=CA.NAMENO
						and NC.ALIASTYPE='_C'
								-- SQA18703
								-- Use best fit to determine ALIAS for the Case
								-- characteristics of CountryCode and PropertyType
						and NC.ALIAS    =(select substring(max(	CASE WHEN(NC1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
											CASE WHEN(NC1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
											NC1.ALIAS),3,30)
								  from NAMEALIAS NC1
								  where NC1.NAMENO=NC.NAMENO
								  and NC1.ALIASTYPE=NC.ALIASTYPE
								  and(NC1.COUNTRYCODE =C.COUNTRYCODE  OR NC1.COUNTRYCODE  is null)
								  and(NC1.PROPERTYTYPE=C.PROPERTYTYPE OR NC1.PROPERTYTYPE is null)))
		left join TELECOMMUNICATION PH	on (PH.TELECODE =NA.MAINPHONE)
		left join TELECOMMUNICATION FAX	on (FAX.TELECODE=NA.FAX)
		left join TELECOMMUNICATION EM	on (EM.TELECODE=NA.MAINEMAIL)"
	End

	Exec @ErrorCode=sp_executesql @sSQLString
End


-- SQA14599
-- For Cases that have a standing instruction flagged to be intercepted so that the actual client
-- is substituted with the home name we are now going to get an explicit CPA Account by checking based
-- on the following hierarchy : Owner; Real Client; Attorney; Home Nameno
If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPCPASEND
	Set	CPACLIENTNO=	CASE WHEN(ISNUMERIC(N_O.ALIAS)=1) 
				   THEN CAST(N_O.ALIAS as INT)
				   ELSE CASE WHEN(ISNUMERIC(N_C.ALIAS)=1) 
					   THEN CAST(N_C.ALIAS as INT)
					   ELSE CASE WHEN(ISNUMERIC(N_A.ALIAS)=1) 
						   THEN CAST(N_A.ALIAS as INT)
						   ELSE CASE WHEN(ISNUMERIC(N_H.ALIAS)=1) 
								THEN CAST(N_H.ALIAS as INT)
								ELSE T.CPACLIENTNO 
							END
						END
					END
				END
	From	#TEMPCPASEND T
	left join CASES C	on (C.CASEID=T.CASEID)

	left join NAMEALIAS N_O	on (N_O.NAMENO	=T.OWNERNAMENO
				and N_O.ALIASTYPE='_C'
						-- SQA18703
						-- Use best fit to determine ALIAS for the Case
						-- characteristics of CountryCode and PropertyType
				and N_O.ALIAS    =(select substring(max(CASE WHEN(N_O1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
									CASE WHEN(N_O1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
									N_O1.ALIAS),3,30)
						  from NAMEALIAS N_O1
						  where N_O1.NAMENO=N_O.NAMENO
						  and N_O1.ALIASTYPE=N_O.ALIASTYPE
						  and ISNUMERIC(N_O1.ALIAS)=1
						  and(N_O1.COUNTRYCODE =C.COUNTRYCODE  OR N_O1.COUNTRYCODE  is null)
						  and(N_O1.PROPERTYTYPE=C.PROPERTYTYPE OR N_O1.PROPERTYTYPE is null)))

	left join NAMEALIAS N_A	on (N_A.NAMENO	=T.ATTORNEYNAMENO
				and @bAttorneyAsCPAClient=1  -- Attorney substitute only required if Site Control is on
				and N_A.ALIASTYPE='_C'
						-- SQA18703
						-- Use best fit to determine ALIAS for the Case
						-- characteristics of CountryCode and PropertyType
				and N_A.ALIAS    =(select substring(max(CASE WHEN(N_A1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
									CASE WHEN(N_A1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
									N_A1.ALIAS),3,30)
						  from NAMEALIAS N_A1
						  where N_A1.NAMENO=N_A.NAMENO
						  and N_A1.ALIASTYPE=N_A.ALIASTYPE
						  and ISNUMERIC(N_A1.ALIAS)=1
						  and(N_A1.COUNTRYCODE =C.COUNTRYCODE  OR N_A1.COUNTRYCODE  is null)
						  and(N_A1.PROPERTYTYPE=C.PROPERTYTYPE OR N_A1.PROPERTYTYPE is null)))

	left join NAMEALIAS N_C	on (N_C.NAMENO	=T.REALCLIENTNAMENO
				and N_C.ALIASTYPE='_C'
						-- SQA18703
						-- Use best fit to determine ALIAS for the Case
						-- characteristics of CountryCode and PropertyType
				and N_C.ALIAS    =(select substring(max(CASE WHEN(N_C1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
									CASE WHEN(N_C1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
									N_C1.ALIAS),3,30)
						  from NAMEALIAS N_C1
						  where N_C1.NAMENO=N_C.NAMENO
						  and N_C1.ALIASTYPE=N_C.ALIASTYPE
						  and ISNUMERIC(N_C1.ALIAS)=1
						  and(N_C1.COUNTRYCODE =C.COUNTRYCODE  OR N_C1.COUNTRYCODE  is null)
						  and(N_C1.PROPERTYTYPE=C.PROPERTYTYPE OR N_C1.PROPERTYTYPE is null)))

	left join NAMEALIAS N_H	on (N_H.NAMENO	=T.HOMENAMENO
				and N_H.ALIASTYPE='_C'
						-- SQA18703
						-- Use best fit to determine ALIAS for the Case
						-- characteristics of CountryCode and PropertyType
				and N_H.ALIAS    =(select substring(max(CASE WHEN(N_H1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
									CASE WHEN(N_H1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
									N_H1.ALIAS),3,30)
						  from NAMEALIAS N_H1
						  where N_H1.NAMENO=N_H.NAMENO
						  and N_H1.ALIASTYPE=N_H.ALIASTYPE
						  and ISNUMERIC(N_H1.ALIAS)=1
						  and(N_H1.COUNTRYCODE =C.COUNTRYCODE  OR N_H1.COUNTRYCODE  is null)
						  and(N_H1.PROPERTYTYPE=C.PROPERTYTYPE OR N_H1.PROPERTYTYPE is null)))
	Where T.INTERCEPTFLAG=1"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@bAttorneyAsCPAClient		bit',
					  @bAttorneyAsCPAClient=@bAttorneyAsCPAClient
End

-- SQA16334
-- Work out Client Account number substitution from Name Address CPA Client combination
-- If CPACLIENTNO previously populated, replace with Name Address CPA Client combination if found
-- Leave CPACLIENTNO untouched if no Name Address CPA Client combination found
If @bNameAddressCPAClient=1 
and @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPCPASEND
	Set	CPACLIENTNO = NAC.CPACLIENTNO	-- the value from new account number column
	From	#TEMPCPASEND T
	-- here the join should collect the casename record for the case renewal instructor or instructor
	join CASENAME CI	on (CI.CASEID=T.CASEID
				and CI.EXPIRYDATE is null
				and CI.NAMETYPE=(select max(CI1.NAMETYPE)
						 from CASENAME CI1
						 where CI1.CASEID=T.CASEID
						 and CI1.EXPIRYDATE is null
						 and CI1.NAMETYPE in ('R','I')))
	-- it should get the nameno and the addressno from the casename record, 
	-- the propertytype from the case record
	-- to join to the new NAMEADDRESSCPACLIENT table to collect the account number
	join NAMEADDRESSCPACLIENT NAC	on (NAC.NAMENO = CI.NAMENO
					and NAC.ADDRESSCODE = CI.ADDRESSCODE
					and NAC.ALIASTYPE=CASE WHEN(T.PROPERTYTYPE='T') THEN '_T' ELSE '_C' END)
	"
	Exec @ErrorCode=sp_executesql @sSQLString 
End

-- Update the Foreign Agent details only for those Countries that require this information

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCPASEND
	set	FOREIGNAGENTCODE	=substring(N.NAMECODE,1,8), 
		FOREIGNAGENTNAME	=substring(rtrim(CASE WHEN N.FIRSTNAME is NULL THEN N.NAME ELSE N.NAME+','+N.FIRSTNAME END), 1, 100)
	From	#TEMPCPASEND T
	join	CASES C			on (C.CASEID=T.CASEID)
	join	TABLEATTRIBUTES TA	on (TA.PARENTTABLE='COUNTRY'
					and TA.GENERICKEY =C.COUNTRYCODE
					and TA.TABLECODE=CASE WHEN(T.PROPERTYTYPE='D') THEN 5010 ELSE 5009 END)
	join 	CASENAME CN		on (CN.CASEID=T.CASEID
					and CN.EXPIRYDATE is null
					and CN.NAMETYPE='A')
	join 	NAME N			on (N.NAMENO=CN.NAMENO)
	where T.PROPERTYTYPE <>'T'"

	Exec @ErrorCode=sp_executesql @sSQLString

End

-- Get the Invoicee data either by getting the Renewal Debtor name type ('Z') if it exists
-- or by using the Debtor name type ('D') if there is not Renewal Debtor defined.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCPASEND
	set	INVOICEECODE		=N.NAMECODE,
		CPAINVOICEENO		=CASE WHEN(ISNUMERIC(NA.ALIAS)=1) THEN CAST(NA.ALIAS as INT) END,
		INVOICEENAME		=substring(rtrim(CASE WHEN N.FIRSTNAME is NULL THEN N.NAME ELSE N.NAME+','+N.FIRSTNAME END), 1, 100), 
--		SQA 20199 Simply pass the main postal address for the invoicee. 
--		Do not send the address held at case level since CPA can only hold one address for an entity.
--		INVADDRESSCODE		=CASE WHEN(CZ.NAMENO=N.NAMENO) THEN isnull(CZ.ADDRESSCODE,N.POSTALADDRESS) WHEN(CD.NAMENO=N.NAMENO) THEN isnull(CD.ADDRESSCODE,N.POSTALADDRESS) ELSE N.POSTALADDRESS END,
		INVADDRESSCODE		=N.POSTALADDRESS,
		INVOICEETELEPHONE	=CASE WHEN( PH.TELECODE is not null) THEN substring(ltrim( PH.ISD+' '+CASE WHEN( PH.AREACODE is not null) THEN  PH.AREACODE+' 'END+ PH.TELECOMNUMBER),1,20) END,
		INVOICEEFAX		=CASE WHEN(FAX.TELECODE is not null) THEN substring(ltrim(FAX.ISD+' '+CASE WHEN(FAX.AREACODE is not null) THEN FAX.AREACODE+' 'END+FAX.TELECOMNUMBER),1,20) END,
		INVOICEEEMAIL		=EM.TELECOMNUMBER, 
		INVOICEENAMETYPE	=CASE(N.NAMENO)
						WHEN(CZ.NAMENO) THEN 'Z'
						WHEN(CD.NAMENO) THEN 'D'
								ELSE NULL
					END
	From	#TEMPCPASEND T
	     join #TEMPDATATOSEND DS	on (DS.CASEID=T.CASEID)
	left join CASES C		on ( C.CASEID=T.CASEID)
	left join CASENAME CZ		on (CZ.CASEID=T.CASEID
					and CZ.EXPIRYDATE is null
					and CZ.NAMETYPE='Z'
					and CZ.SEQUENCE=(select min(CZ1.SEQUENCE)
							 from  CASENAME CZ1
							 where CZ1.CASEID=CZ.CASEID
							 and   CZ1.EXPIRYDATE is null
							 and   CZ1.NAMETYPE=CZ.NAMETYPE))
	left join CASENAME CD		on (CD.CASEID=T.CASEID
					and CZ.CASEID is null	-- Only require Debtor if no Renewal Debtor
					and CD.EXPIRYDATE is null
					and CD.NAMETYPE='D'
					and CD.SEQUENCE=(select min(CD1.SEQUENCE)
							 from  CASENAME CD1
							 where CD1.CASEID=CD.CASEID
							 and   CD1.EXPIRYDATE is null
							 and   CD1.NAMETYPE=CD.NAMETYPE))

							-- Get the Client information for CPA to contact
							-- If the Standing Instruction is one that has been
							-- flagged as requiring the Agent to act for the Agent
							-- then substitute the Agent details for the client
	join NAME N			on (N.NAMENO=	CASE When(Exists (Select * from INSTRUCTIONFLAG I where I.INSTRUCTIONCODE=DS.INSTRUCTIONCODE and I.FLAGNUMBER="+convert(varchar,@nCPAInterceptFlag)+"))
								THEN "+convert(varchar,@nHomeNameNo)+"
								ELSE isnull(CZ.NAMENO,CD.NAMENO)
							END)

	left join NAMEALIAS NA	on (NA.NAMENO	=N.NAMENO
				and NA.ALIASTYPE='_C'
						-- SQA18703
						-- Use best fit to determine ALIAS for the Case
						-- characteristics of CountryCode and PropertyType
				and NA.ALIAS    =(select substring(max(	CASE WHEN(NA1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
									CASE WHEN(NA1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
									NA1.ALIAS),3,30)
						  from NAMEALIAS NA1
						  where NA1.NAMENO=NA.NAMENO
						  and NA1.ALIASTYPE=NA.ALIASTYPE
						  and ISNUMERIC(NA1.ALIAS)=1
						  and(NA1.COUNTRYCODE =C.COUNTRYCODE  OR NA1.COUNTRYCODE  is null)
						  and(NA1.PROPERTYTYPE=C.PROPERTYTYPE OR NA1.PROPERTYTYPE is null)))

	left join NAME AT		on (AT.NAMENO=	CASE When(N.NAMENO=isnull(CZ.NAMENO,CD.NAMENO))
								Then isnull(isnull(CZ.CORRESPONDNAME,CD.CORRESPONDNAME), N.MAINCONTACT)
								Else N.MAINCONTACT
							END)
	left join TELECOMMUNICATION PH	on (PH.TELECODE =N.MAINPHONE)
	left join TELECOMMUNICATION FAX	on (FAX.TELECODE=N.FAX)
	left join TELECOMMUNICATION EM	on (EM.TELECODE=isnull(AT.MAINEMAIL,N.MAINEMAIL))
	-- Only require the Invoicee details if they are different from the Client
	where N.NAMECODE  <>T.CLIENTCODE
	or N.POSTALADDRESS<>T.CLTADDRESSCODE
	or isnull(CZ.BILLPERCENTAGE, CD.BILLPERCENTAGE)<>100.00"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
and @pnChangedCases=1
Begin
	---------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- RFC39818
	-- Problem:
	-- If agent (Inprotech firm) is acting as renewals instructor on behalf of instructor then agent name code and address is passed into batch as CLIENT. 
	-- This is controlled by standing instruction.
	-- If case payments are to stop, user enters stop pay reason and changes standing instruction to a non-cpa instruction (eg Renewals Handled Elsewhere).
	-- System sends the case with the stop pay reason but because the SI has changed it will now collect the instructor as the renewals instructor 
	-- instead of the agent. This causes CPA to think it is a new name, create a new account and treat this as a new case.
	--
	-- Solution:
	-- When batch creation occurs and a case is collected because it has a stop pay reason, the code should:
	-- 1.	Copy the CPACLIENTNO from the previously sent row for this case (no exception).
	-- 2.	Copy the CLIENTCODE from the previously sent row for this case AND use this code to freshly determine the address 
	--	which should be passed in the batch. Note that the previous address cannot be used as this may have changed (via a name record) 
	--	since the case was previously sent. In the past the previous name and address was sent and this caused confusion and problems with client addresses.
	--	
	-- Potential problem:
	-- The CLIENTCODE column is not mandatory and may in fact be empty. But if it is empty then a Name record with a different address could not have been sent. 
	-- So if the previous CLIENTCODE column is empty then simply copy the previous values for CLIENTNAME , CLIENTATTENTION, CLTADDRESSLINE1, CLTADDRESSLINE2, 
	-- CLTADDRESSLINE3, CLTADDRESSLINE4, CLTADDRESSCOUNTRY, CLTADDRESSPOSTCODE, CLIENTTELEPHONE, CLIENTFAX, CLIENTEMAIL.
	---------------------------------------------------------------------------------------------------------------------------------------------------------------
	Set @sSQLString="
	Update T
	Set CLIENTCODE		=C1.CLIENTCODE, 
	
	    CPACLIENTNO		=C1.CPACLIENTNO, 
	
	    CLIENTNAME		=CASE WHEN(N.NAMENO is null) THEN C1.CLTADDRESSLINE1    ELSE substring(rtrim(CASE WHEN N.FIRSTNAME is NULL THEN N.NAME ELSE N.NAME+','+N.FIRSTNAME END), 1, 100) END, 
	    CLIENTATTENTION	=CASE WHEN(N.NAMENO is null) THEN C1.CLIENTATTENTION    ELSE NULL END,
	
	    CLTADDRESSCODE	=N.POSTALADDRESS,	
	    CLTADDRESSLINE1	=CASE WHEN(N.NAMENO is null) THEN C1.CLTADDRESSLINE1    ELSE NULL END,
	    CLTADDRESSLINE2	=CASE WHEN(N.NAMENO is null) THEN C1.CLTADDRESSLINE2    ELSE NULL END,
	    CLTADDRESSLINE3	=CASE WHEN(N.NAMENO is null) THEN C1.CLTADDRESSLINE3    ELSE NULL END,
	    CLTADDRESSLINE4	=CASE WHEN(N.NAMENO is null) THEN C1.CLTADDRESSLINE4    ELSE NULL END,
	    CLTADDRESSCOUNTRY	=CASE WHEN(N.NAMENO is null) THEN C1.CLTADDRESSCOUNTRY  ELSE NULL END,
	    CLTADDRESSPOSTCODE	=CASE WHEN(N.NAMENO is null) THEN C1.CLTADDRESSPOSTCODE ELSE NULL END,
	
	    CLIENTTELEPHONE	=CASE WHEN(N.NAMENO is NULL) THEN C1.CLIENTTELEPHONE    ELSE CASE WHEN(PH.TELECODE  is not null) THEN substring(ltrim( PH.ISD+' '+CASE WHEN( PH.AREACODE is not null) THEN  PH.AREACODE+' 'END+ PH.TELECOMNUMBER),1,20) END END,
	    CLIENTFAX		=CASE WHEN(N.NAMENO is NULL) THEN C1.CLIENTFAX          ELSE CASE WHEN(FAX.TELECODE is not null) THEN substring(ltrim(FAX.ISD+' '+CASE WHEN(FAX.AREACODE is not null) THEN FAX.AREACODE+' 'END+FAX.TELECOMNUMBER),1,20) END END,
	    CLIENTEMAIL		=CASE WHEN(N.NAMENO is NULL) THEN C1.CLIENTEMAIL        ELSE EM.TELECOMNUMBER END
	From #TEMPCPASEND T
	join CASES CS on (CS.CASEID=T.CASEID)
	--------------------------------------------
	-- Get details of the last time the case was
	-- reported to CPA.
	--------------------------------------------
	join CPASEND C1	on (C1.CASEID=T.CASEID
	                and C1.BATCHNO=(select MAX(C2.BATCHNO)
	                                from CPASEND C2
	                                where C2.CASEID=T.CASEID))
	left join NAME N on (N.NAMECODE=C1.CLIENTCODE)		
	left join TELECOMMUNICATION PH	on (PH.TELECODE =N.MAINPHONE)
	left join TELECOMMUNICATION FAX	on (FAX.TELECODE=N.FAX)
	left join TELECOMMUNICATION EM	on (EM.TELECODE	=N.MAINEMAIL)
	Where T.STOPPAYINGREASON is not null
	and  C1.STOPPAYINGREASON is null"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Get the non cyclic dates to be reported to CPA

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCPASEND
	set	PRIORITYDATE		=CASE WHEN(CPA.CONVENTION=1) THEN CE1.EVENTDATE END,	-- only report the priority date for Convention cases.
		PARENTDATE		=CE2.EVENTDATE,
		PCTFILINGDATE		=CASE WHEN(CPA.PROPERTYTYPE='P') THEN CE5.EVENTDATE END,
		ASSOCDESIGNDATE		=CASE WHEN(CPA.PROPERTYTYPE='D') THEN CE6.EVENTDATE END,
		APPLICATIONDATE		=CE8.EVENTDATE,
		ACCEPTANCEDATE		=CASE WHEN(CPA.PROPERTYTYPE='D') THEN CE9.EVENTDATE END,
		PUBLICATIONDATE		=CASE WHEN(CPA.PROPERTYTYPE='P') THEN CE10.EVENTDATE END,
		REGISTRATIONDATE	=CE11.EVENTDATE,
		EXPIRYDATE		=CASE WHEN(CPA.PROPERTYTYPE in ('D','P')) THEN isnull(CE12.EVENTDATE,CE12.EVENTDUEDATE) END,
		CPASTARTPAYDATE		=CASE WHEN(CPA.TRANSACTIONCODE=12
						OR CPA1.CPASTARTPAYDATE<>isnull(CE13.EVENTDATE,CE13.EVENTDUEDATE)
						OR CPA1.CPASTARTPAYDATE is null)
					      THEN isnull(CE13.EVENTDATE,CE13.EVENTDUEDATE)
					 END,
		CPASTOPPAYDATE		=CASE WHEN(isnull(CE14.EVENTDATE, CE14.EVENTDUEDATE) is not null)
						THEN isnull(CE14.EVENTDATE, CE14.EVENTDUEDATE)
					      WHEN(CPA.STOPPAYINGREASON is not null)
						THEN convert(varchar,getdate(),112) --SQA13777 default if Stop Paying Reason is set
					 END

	from	#TEMPCPASEND CPA
	left join CPASEND CPA1		on (CPA1.CASEID=CPA.CASEID
					and CPA1.BATCHNO=(select max(CPA2.BATCHNO)
							  from CPASEND CPA2
							  where CPA2.CASEID=CPA.CASEID
							  and CPA2.CPASTARTPAYDATE is not null) )
	left join CASEEVENT CE1		on (CE1.CASEID=CPA.CASEID
					and CE1.CYCLE =1
					and CE1.EVENTNO=@nPriorityEventNo)
	left join CASEEVENT CE2		on (CE2.CASEID=CPA.CASEID
					and CE2.CYCLE =1
					and CE2.EVENTNO=@nParentEventNo)
	left join CASEEVENT CE5		on (CE5.CASEID=CPA.CASEID
					and CE5.CYCLE =1
					and CE5.EVENTNO=@nPCTFilingEventNo)
	left join CASEEVENT CE6		on (CE6.CASEID=CPA.CASEID
					and CE6.CYCLE =1
					and CE6.EVENTNO=@nAssocDesignEventNo)
	left join CASEEVENT CE8		on (CE8.CASEID=CPA.CASEID
					and CE8.CYCLE =1
					and CE8.EVENTNO=@nApplicationEventNo)
	left join CASEEVENT CE9		on (CE9.CASEID=CPA.CASEID
					and CE9.CYCLE =1
					and CE9.EVENTNO=@nAcceptanceEventNo)
	left join CASEEVENT CE10	on (CE10.CASEID=CPA.CASEID
					and CE10.CYCLE =1
					and CE10.EVENTNO=@nPublicationEventNo)
	left join CASEEVENT CE11	on (CE11.CASEID=CPA.CASEID
					and CE11.CYCLE =1
					and CE11.EVENTNO=@nRegistrationEventNo)
	left join CASEEVENT CE12	on (CE12.CASEID=CPA.CASEID
					and CE12.CYCLE =1
					and CE12.EVENTNO=@nExpiryEventNo)
	left join CASEEVENT CE13	on (CE13.CASEID=CPA.CASEID
					and CE13.CYCLE =1
					and CE13.EVENTNO=@nCPAStartEventNo)
	left join CASEEVENT CE14	on (CE14.CASEID=CPA.CASEID
					and CE14.CYCLE =1
					and CE14.EVENTNO=@nCPAStopEventNo)"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nPriorityEventNo	int,
					  @nParentEventNo	int,
					  @nPCTFilingEventNo	int,
					  @nAssocDesignEventNo	int,
					  @nApplicationEventNo	int,
					  @nAcceptanceEventNo	int,
					  @nPublicationEventNo	int,
					  @nRegistrationEventNo	int,
					  @nExpiryEventNo	int,
					  @nCPAStartEventNo	int,
					  @nCPAStopEventNo	int',
					  @nPriorityEventNo,
					  @nParentEventNo,
					  @nPCTFilingEventNo,
					  @nAssocDesignEventNo,
					  @nApplicationEventNo,
					  @nAcceptanceEventNo,
					  @nPublicationEventNo,
					  @nRegistrationEventNo,
					  @nExpiryEventNo,
					  @nCPAStartEventNo,
					  @nCPAStopEventNo
End

-- Get the cyclic Quinquenial date to be reported to CPA by using the lowest
-- cycle openaction for the cyclic action that references it.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCPASEND
	set	NEXTTAXDATE = isnull(CE.EVENTDATE,CE.EVENTDUEDATE)
	from	#TEMPCPASEND CPA
	-- Get the best Action and cycle for the Event
	-- noting that the Action that calculated the Event may not 
	-- in itself be the best one to use. 
	-- Where multiple Actions exist for the event then the preferred
	-- action is where multiple cycles are allowed.
	--
	-- To get the lowest open Cycle against the Action that allows
	-- the most cycles requires the use of MAX and a 9's complement
	-- of the cycle (to get the lowest cycle)
	Left Join (	select OA.CASEID,
				max(
				convert(char(5), A.NUMCYCLESALLOWED)+
				convert(char(5),99999-OA.CYCLE)+
				OA.ACTION) as BestAction
			from EVENTCONTROL EC
			join OPENACTION OA on (OA.CRITERIANO=EC.CRITERIANO)
			join ACTIONS A     on (A.ACTION=OA.ACTION)
			where EC.EVENTNO=@nNextQuinTaxEventNo
			and OA.POLICEEVENTS=1
			group by OA.CASEID) BA on (BA.CASEID=CPA.CASEID)

	join CASEEVENT CE	on (CE.CASEID=CPA.CASEID
				and CE.EVENTNO=@nNextQuinTaxEventNo
				and CE.CYCLE=	CASE WHEN( (convert(int,substring(BA.BestAction,1,5))>1) ) 
							THEN 99999-convert(int,substring(BA.BestAction,6,5)) 
							ELSE (select max(CE1.CYCLE)
								From CASEEVENT CE1
								where CE1.CASEID=CE.CASEID
								and CE1.EVENTNO=CE.EVENTNO)
			      			END)
	Where CPA.PROPERTYTYPE='T'"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nNextQuinTaxEventNo	int',
					  @nNextQuinTaxEventNo
End

-- 16672 Get the cyclic Next Affidavit date to be reported to CPA by using 
-- the lowest cycle openaction for the cyclic action that references it.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCPASEND
	set	NEXTAFFIDAVITDATE = isnull(CE.EVENTDATE,CE.EVENTDUEDATE)
	from	#TEMPCPASEND CPA
	-- Get the best Action and cycle for the Event
	-- noting that the Action that calculated the Event may not 
	-- in itself be the best one to use. 
	-- Where multiple Actions exist for the event then the preferred
	-- action is where multiple cycles are allowed.
	--
	-- To get the lowest open Cycle against the Action that allows
	-- the most cycles requires the use of MAX and a 9's complement
	-- of the cycle (to get the lowest cycle)
	Left Join (	select OA.CASEID,
				max(
				convert(char(5), A.NUMCYCLESALLOWED)+
				convert(char(5),99999-OA.CYCLE)+
				OA.ACTION) as BestAction
			from EVENTCONTROL EC
			join OPENACTION OA on (OA.CRITERIANO=EC.CRITERIANO)
			join ACTIONS A     on (A.ACTION=OA.ACTION)
			where EC.EVENTNO=@nAffidavitEventNo
			and OA.POLICEEVENTS=1
			group by OA.CASEID) BA on (BA.CASEID=CPA.CASEID)

	join CASEEVENT CE	on (CE.CASEID=CPA.CASEID
				and CE.EVENTNO=@nAffidavitEventNo
				and CE.CYCLE=	CASE WHEN( (convert(int,substring(BA.BestAction,1,5))>1) ) 
							THEN 99999-convert(int,substring(BA.BestAction,6,5)) 
							ELSE (select max(CE1.CYCLE)
								From CASEEVENT CE1
								where CE1.CASEID=CE.CASEID
								and CE1.EVENTNO=CE.EVENTNO)
			      			END)
	Where CPA.PROPERTYTYPE='T'"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nAffidavitEventNo	int',
					  @nAffidavitEventNo
End

-- 16672 Get the cyclic Next Declaration of Use date to be reported to CPA by using 
-- the lowest cycle openaction for the cyclic action that references it.
If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCPASEND
	set	NEXTDECOFUSEDATE = isnull(CE.EVENTDATE,CE.EVENTDUEDATE)
	from	#TEMPCPASEND CPA
	-- Get the best Action and cycle for the Event
	-- noting that the Action that calculated the Event may not 
	-- in itself be the best one to use. 
	-- Where multiple Actions exist for the event then the preferred
	-- action is where multiple cycles are allowed.
	--
	-- To get the lowest open Cycle against the Action that allows
	-- the most cycles requires the use of MAX and a 9's complement
	-- of the cycle (to get the lowest cycle)
	Left Join (	select OA.CASEID,
				max(
				convert(char(5), A.NUMCYCLESALLOWED)+
				convert(char(5),99999-OA.CYCLE)+
				OA.ACTION) as BestAction
			from EVENTCONTROL EC
			join OPENACTION OA on (OA.CRITERIANO=EC.CRITERIANO)
			join ACTIONS A     on (A.ACTION=OA.ACTION)
			where EC.EVENTNO=@nNextDecOfUseEventNo
			and OA.POLICEEVENTS=1
			group by OA.CASEID) BA on (BA.CASEID=CPA.CASEID)

	join CASEEVENT CE	on (CE.CASEID=CPA.CASEID
				and CE.EVENTNO=@nNextDecOfUseEventNo
				and CE.CYCLE=	CASE WHEN( (convert(int,substring(BA.BestAction,1,5))>1) ) 
							THEN 99999-convert(int,substring(BA.BestAction,6,5)) 
							ELSE (select max(CE1.CYCLE)
								From CASEEVENT CE1
								where CE1.CASEID=CE.CASEID
								and CE1.EVENTNO=CE.EVENTNO)
			      			END)
	Where CPA.PROPERTYTYPE='T'"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nNextDecOfUseEventNo	int',
					  @nNextDecOfUseEventNo
End


-- 16672 Get the cyclic Nominal Working date to be reported to CPA by using 
-- the lowest cycle openaction for the cyclic action that references it.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCPASEND
	set	NOMINALWORKINGDATE = isnull(CE.EVENTDATE,CE.EVENTDUEDATE)
	from	#TEMPCPASEND CPA
	-- Get the best Action and cycle for the Event
	-- noting that the Action that calculated the Event may not 
	-- in itself be the best one to use. 
	-- Where multiple Actions exist for the event then the preferred
	-- action is where multiple cycles are allowed.
	--
	-- To get the lowest open Cycle against the Action that allows
	-- the most cycles requires the use of MAX and a 9's complement
	-- of the cycle (to get the lowest cycle)
	Left Join (	select OA.CASEID,
				max(
				convert(char(5), A.NUMCYCLESALLOWED)+
				convert(char(5),99999-OA.CYCLE)+
				OA.ACTION) as BestAction
			from EVENTCONTROL EC
			join OPENACTION OA on (OA.CRITERIANO=EC.CRITERIANO)
			join ACTIONS A     on (A.ACTION=OA.ACTION)
			where EC.EVENTNO=@nNominalWorkingEventNo
			and OA.POLICEEVENTS=1
			group by OA.CASEID) BA on (BA.CASEID=CPA.CASEID)

	join CASEEVENT CE	on (CE.CASEID=CPA.CASEID
				and CE.EVENTNO=@nNominalWorkingEventNo
				and CE.CYCLE=	CASE WHEN( (convert(int,substring(BA.BestAction,1,5))>1) ) 
							THEN 99999-convert(int,substring(BA.BestAction,6,5)) 
							ELSE (select max(CE1.CYCLE)
								From CASEEVENT CE1
								where CE1.CASEID=CE.CASEID
								and CE1.EVENTNO=CE.EVENTNO)
			      			END)
	Where CPA.PROPERTYTYPE='T'"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nNominalWorkingEventNo	int',
					  @nNominalWorkingEventNo

End

-- Get the current Next Renewal date to be reported to CPA by using 
-- the lowest openaction for the action that created it.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCPASEND
	set	RENEWALDATE =isnull(CE.EVENTDATE,CE.EVENTDUEDATE)
	from	#TEMPCPASEND CPA
	join CASEEVENT CE	on (CE.CASEID=CPA.CASEID
				and CE.EVENTNO=@nNextRenewalEventNo)
	join SITECONTROL SC	on (SC.CONTROLID='Main Renewal Action')
	join OPENACTION OA	on (OA.CASEID=CPA.CASEID
				and OA.ACTION=SC.COLCHARACTER
				and OA.CYCLE =CE.CYCLE
				and OA.CYCLE  = (select min(OA1.CYCLE)
						from OPENACTION OA1
						where OA1.CASEID=OA.CASEID
						and   OA1.ACTION=OA.ACTION
						and   OA1.POLICEEVENTS=1))"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@nNextRenewalEventNo	int',
					  @nNextRenewalEventNo

End


-- Get the main official numbers for the cases being reported.  If there is a
-- CPA Formatted version of the numbers then use those in preference.  This is
-- because sometime CPA modify the format to match a format provided by the 
-- IP Office of the country.

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCPASEND
	set	APPLICATIONNO	=substring(A.OFFICIALNUMBER,1,30),
		ACCEPTANCENO	=substring(C.OFFICIALNUMBER,1,30),
		PUBLICATIONNO	=substring(P.OFFICIALNUMBER,1,30),
		REGISTRATIONNO	=substring(R.OFFICIALNUMBER,1,30)
	from	#TEMPCPASEND CPA
	left join OFFICIALNUMBERS A	on (A.CASEID=CPA.CASEID
					and A.NUMBERTYPE=(	select TOP 1 A6.NUMBERTYPE
								from dbo.fn_Tokenise('"+@sApplicationNumberType+"',',') NT
								join OFFICIALNUMBERS A6 on (A6.CASEID=A.CASEID
											and A6.ISCURRENT=1
											and A6.NUMBERTYPE=NT.Parameter)
								ORDER BY NT.InsertOrder)
					and A.ISCURRENT=1
					and A.OFFICIALNUMBER=(	select max(A1.OFFICIALNUMBER)
								from OFFICIALNUMBERS A1
								where A1.CASEID=A.CASEID
								and   A1.NUMBERTYPE=A.NUMBERTYPE	
								and   A1.ISCURRENT=1))
	left join OFFICIALNUMBERS C	on (C.CASEID=CPA.CASEID
					and C.NUMBERTYPE=(	select TOP 1 C7.NUMBERTYPE
								from dbo.fn_Tokenise('"+@sAcceptanceNumberType+"',',') NT
								join OFFICIALNUMBERS C7 on (C7.CASEID=C.CASEID
											and C7.ISCURRENT=1
											and C7.NUMBERTYPE=NT.Parameter)
								ORDER BY NT.InsertOrder)
					and C.ISCURRENT=1
					and C.OFFICIALNUMBER=(	select max(C1.OFFICIALNUMBER)
								from OFFICIALNUMBERS C1
								where C1.CASEID=C.CASEID
								and   C1.NUMBERTYPE=C.NUMBERTYPE	
								and   C1.ISCURRENT=1))
	left join OFFICIALNUMBERS P	on (P.CASEID=CPA.CASEID
					and P.NUMBERTYPE=(	select TOP 1 P8.NUMBERTYPE
								from dbo.fn_Tokenise('"+@sPublicationNumberType+"',',') NT
								join OFFICIALNUMBERS P8 on (P8.CASEID=P.CASEID
											and P8.ISCURRENT=1
											and P8.NUMBERTYPE=NT.Parameter)
								ORDER BY NT.InsertOrder)
					and P.ISCURRENT=1
					and P.OFFICIALNUMBER=(	select max(P1.OFFICIALNUMBER)
								from OFFICIALNUMBERS P1
								where P1.CASEID=P.CASEID
								and   P1.NUMBERTYPE=P.NUMBERTYPE	
								and   P1.ISCURRENT=1))
	left join OFFICIALNUMBERS R	on (R.CASEID=CPA.CASEID
					and R.NUMBERTYPE=(	select TOP 1 R9.NUMBERTYPE
								from dbo.fn_Tokenise('"+@sRegistrationNumberType+"',',') NT
								join OFFICIALNUMBERS R9 on (R9.CASEID=R.CASEID
											and R9.ISCURRENT=1
											and R9.NUMBERTYPE=NT.Parameter)
								ORDER BY NT.InsertOrder)
					and R.ISCURRENT=1
					and R.OFFICIALNUMBER=(	select max(R1.OFFICIALNUMBER)
								from OFFICIALNUMBERS R1
								where R1.CASEID=R.CASEID
								and   R1.NUMBERTYPE=R.NUMBERTYPE	
								and   R1.ISCURRENT=1))"

	Exec @ErrorCode=sp_executesql @sSQLString

End

-- SQA18915
-- Interim step required to get the Official number 
-- associated with the Related Cases. 
-- This step is to handle multiple relationships
-- by considering any associated date.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRELATEDCASE(CASEID, RELATIONSHIP, RELATEDCASEID, OFFICIALNUMBER, EARLIESTDATE)
	select RC.CASEID, RC.RELATIONSHIP, RC.RELATEDCASEID, RC.OFFICIALNUMBER, coalesce(CE.EVENTDATE,RC.PRIORITYDATE,getdate()) as EARLIESTDATE
	from #TEMPCPASEND CPA
	join RELATEDCASE RC	on (RC.CASEID=CPA.CASEID)
	join CASERELATION CR	on (CR.RELATIONSHIP=RC.RELATIONSHIP)
	left join CASEEVENT CE	on (CE.CASEID=RC.RELATEDCASEID
				and CE.CYCLE =1
				and CE.EVENTNO=coalesce(CR.FROMEVENTNO, CR.DISPLAYEVENTNO, CR.EVENTNO))
	order by RC.CASEID, EARLIESTDATE, RC.RELATIONSHIPNO"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Interim step required to get the Official number 
-- of the parent Case.  
-- This step is to handle multiple relationships
-- by considering any associated date.
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPRELATEDCASE(CASEID, RELATIONSHIP, RELATEDCASEID, OFFICIALNUMBER, EARLIESTDATE)
	select RC.CASEID, '???', RC.RELATEDCASEID, RC.OFFICIALNUMBER, coalesce(CE.EVENTDATE,RC.PRIORITYDATE,getdate()) as EARLIESTDATE
	from #TEMPCPASEND CPA
	join RELATEDCASE RC	on (RC.CASEID=CPA.CASEID)
	join CASERELATION CR	on (CR.RELATIONSHIP=RC.RELATIONSHIP
				and CR.POINTERTOPARENT=1)
	left join CASEEVENT CE	on (CE.CASEID=RC.RELATEDCASEID
				and CE.CYCLE =1
				and CE.EVENTNO=coalesce(CR.FROMEVENTNO, CR.DISPLAYEVENTNO, CR.EVENTNO))
	where RC.RELATIONSHIP not in ("+CASE WHEN(@sParentExclude is not null) THEN @sParentExclude ELSE "@sEarliestPriority,@sPCTFiling" END +")
	order by RC.CASEID, EARLIESTDATE, RC.RELATIONSHIPNO"

	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sEarliestPriority	nvarchar(3),
				  @sPCTFiling		nvarchar(3)',
				  @sEarliestPriority	=@sEarliestPriority,
				  @sPCTFiling		=@sPCTFiling
End

-- Get information from Related Cases

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update	#TEMPCPASEND
	set	PRIORITYNO	=substring(coalesce(O1.OFFICIALNUMBER,C1.CURRENTOFFICIALNO,RC1.OFFICIALNUMBER),1,30),
		ASSOCDESIGNNO	=substring(coalesce(O2.OFFICIALNUMBER,C2.CURRENTOFFICIALNO,RC2.OFFICIALNUMBER),1,30),
		PARENTNO	=substring(coalesce(O3.OFFICIALNUMBER,C3.CURRENTOFFICIALNO,RC3.OFFICIALNUMBER),1,30),
		PCTFILINGNO	=substring(coalesce(O4.OFFICIALNUMBER,C4.CURRENTOFFICIALNO,RC4.OFFICIALNUMBER,PCT.OFFICIALNUMBER),1,30)
	from	#TEMPCPASEND CPA
	-- SQA18915 Ensure the Priority Number reported has the earliest priority date.
	left join #TEMPRELATEDCASE RC1	on (RC1.CASEID=CPA.CASEID
					and RC1.RELATIONSHIP=@sEarliestPriority
					and RC1.SEQUENCENO=(	select min(RX1.SEQUENCENO)
								from #TEMPRELATEDCASE RX1
								where RX1.CASEID=RC1.CASEID
								and   RX1.RELATIONSHIP=RC1.RELATIONSHIP) )
	left join OFFICIALNUMBERS O1	on (O1.CASEID=RC1.RELATEDCASEID
					and O1.NUMBERTYPE='A'
					and O1.ISCURRENT=1)
	left join CASES C1		on (C1.CASEID=RC1.RELATEDCASEID)

	left join #TEMPRELATEDCASE RC2	on (RC2.CASEID=CPA.CASEID
					and RC2.RELATIONSHIP=@sAssocDesign
					and RC2.SEQUENCENO=(	select min(RX2.SEQUENCENO)
								from  #TEMPRELATEDCASE RX2
								where RX2.CASEID=RC2.CASEID
								and   RX2.RELATIONSHIP=RC2.RELATIONSHIP))
	left join OFFICIALNUMBERS O2	on (O2.CASEID=RC2.RELATEDCASEID
					and O2.NUMBERTYPE='A'
					and O2.ISCURRENT=1)
	left join CASES C2		on (C2.CASEID=RC2.RELATEDCASEID)

	left join #TEMPRELATEDCASE RC3	on (RC3.CASEID=CPA.CASEID
					and RC3.RELATIONSHIP='???'
					and RC3.SEQUENCENO=(	select min(RX3.SEQUENCENO)
								from  #TEMPRELATEDCASE RX3
								where RX3.CASEID=RC3.CASEID
								and   RX3.RELATIONSHIP=RC3.RELATIONSHIP))
	left join OFFICIALNUMBERS O3	on (O3.CASEID=RC3.RELATEDCASEID
					and O3.NUMBERTYPE='A'
					and O3.ISCURRENT=1)
	left join CASES C3		on (C3.CASEID=RC3.RELATEDCASEID)

	left join #TEMPRELATEDCASE RC4	on (RC4.CASEID=CPA.CASEID
					and RC4.RELATIONSHIP=@sPCTFiling
					and RC4.SEQUENCENO=(	select min(RX4.SEQUENCENO)
								from  #TEMPRELATEDCASE RX4
								where RX4.CASEID=RC4.CASEID
								and   RX4.RELATIONSHIP=RC4.RELATIONSHIP))
	left join OFFICIALNUMBERS O4	on (O4.CASEID=RC4.RELATEDCASEID
					and O4.NUMBERTYPE='A'
					and O4.ISCURRENT=1)
	left join CASES C4		on (C4.CASEID=RC4.RELATEDCASEID)
	--SQA21344 collect PCT from existing case if relationship not found
	left join OFFICIALNUMBERS PCT	on (PCT.CASEID=CPA.CASEID
					and PCT.NUMBERTYPE=(	select min(NUMBERTYPE)
								from OFFICIALNUMBERS
								where CASEID=PCT.CASEID
								and   NUMBERTYPE in ("+isnull(@sPCTFilingNumberType,'NULL')+"))
					and PCT.ISCURRENT=1
					and PCT.OFFICIALNUMBER=(	select max(OFFICIALNUMBER)
								from OFFICIALNUMBERS
								where CASEID=PCT.CASEID
								and   NUMBERTYPE=PCT.NUMBERTYPE	
								and   ISCURRENT=1))
	"

	Exec @ErrorCode=sp_executesql @sSQLString,
					N'@sEarliestPriority	nvarchar(3),
					  @sAssocDesign		nvarchar(3),
					  @sPCTFiling		nvarchar(3)',
					  @sEarliestPriority=@sEarliestPriority,
					  @sAssocDesign     =@sAssocDesign,
					  @sPCTFiling       =@sPCTFiling

End

-- SQA11197 Reformat the PCT Filing Number
If @ErrorCode=0
begin
	Set @sSQLString="
	Update #TEMPCPASEND
	Set PCTFILINGNO=substring(PCTFILINGNO,1,6)+substring(PCTFILINGNO,9,21)
	where substring(PCTFILINGNO,1,4)='PCT/'
	and Substring(PCTFILINGNO,5,1) between 'A' and 'Z'
	and Substring(PCTFILINGNO,6,1) between 'A' and 'Z'
	and Substring(PCTFILINGNO,7,4) between '1900' and '2100'
	and Substring(PCTFILINGNO,11,1)='/'"

	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	If @sFileNumberType='IRN'
	begin
		-- SQA13731 Save the IRN in the FILENUMBER field if option set to do so.
		Set @sSQLString="
		Update #TEMPCPASEND
		Set FILENUMBER=left(C.IRN,15)
		From #TEMPCPASEND CPA
		join CASES C		on (C.CASEID=CPA.CASEID)"
	
		exec @ErrorCode=sp_executesql @sSQLString
	end
	Else If @sFileNumberType='CAT'
	begin
		-- SQA10482 Get the Case Category description and save it in the FileNumber column
		--	    if a specific Number Type has not been defined as a Site Control.
		Set @sSQLString="
		Update #TEMPCPASEND
		Set FILENUMBER=left(VC.CASECATEGORYDESC,15)
		From #TEMPCPASEND CPA
		join CASES C		on (C.CASEID=CPA.CASEID)
		join VALIDCATEGORY VC	on (VC.PROPERTYTYPE=C.PROPERTYTYPE
					and VC.CASETYPE=C.CASETYPE
					and VC.CASECATEGORY=C.CASECATEGORY
					and VC.COUNTRYCODE=(select min(VC1.COUNTRYCODE)
							    from VALIDCATEGORY VC1
							    where VC1.PROPERTYTYPE=C.PROPERTYTYPE
							    and VC1.CASETYPE=C.CASETYPE
							    and VC1.CASECATEGORY=C.CASECATEGORY
							    and VC1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)))"
	
		exec @ErrorCode=sp_executesql @sSQLString
	end

	-- If this site has specified a particular Number Type to use for the File Number
	-- then extract this into the FILENUMBER field
	Else If @sFileNumberType is not null
	Begin
		Set @sSQLString="
		Update #TEMPCPASEND
		Set FILENUMBER=left(O.OFFICIALNUMBER,15)
		From #TEMPCPASEND CPA
		join OFFICIALNUMBERS O	on (O.CASEID=CPA.CASEID
					and O.NUMBERTYPE=@sFileNumberType
					and O.ISCURRENT=1
					and O.OFFICIALNUMBER=(	select max(O1.OFFICIALNUMBER)
								from OFFICIALNUMBERS O1
								where O1.CASEID=O.CASEID
								and   O1.NUMBERTYPE=O.NUMBERTYPE	
								and   O1.ISCURRENT=1))"
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sFileNumberType	nchar(1)',
						  @sFileNumberType=@sFileNumberType
	End
End

-- SQA 18243  Save the IRN in the CLIENTSREFERENCE field if option set to do so.

If @ErrorCode=0
Begin
	If @sClientsReferenceType='IRN'
	begin
		Set @sSQLString="
		Update #TEMPCPASEND
		Set CLIENTSREFERENCE=left(C.IRN,35)
		From #TEMPCPASEND CPA
		join CASES C		on (C.CASEID=CPA.CASEID)"
	
		exec @ErrorCode=sp_executesql @sSQLString
	end
-- SQA18962 Use the DocItem if set.
	Else If @sClientsReferenceType<>'IRN' and @sClientsReferenceType is not null
	begin
		select @sClientsReferenceDocItem=SQL_QUERY
		from ITEM
		where ITEM_NAME = @sClientsReferenceType
		
		If @sClientsReferenceDocItem is not null
		begin
			Set @sClientsReferenceDocItem=replace(@sClientsReferenceDocItem,':gstrEntryPoint', 'C.IRN')
			
			Set @sSQLString="
			Update #TEMPCPASEND
			Set CLIENTSREFERENCE=left(("+@sClientsReferenceDocItem+"),35)
			From #TEMPCPASEND CPA
			join CASES C on (C.CASEID=CPA.CASEID)"
			
			exec @ErrorCode=sp_executesql @sSQLString
		end
	end
End


-- Load any Designated Countries as a single string of country codes with no separator
-- and also load the number of designations per case.

If @ErrorCode=0
begin
	Exec @ErrorCode=cpa_UpdateWithDesignatedCountries
end

-- A Name record is to be reported for each different Client/Address combination embedded within a Case.
-- If these have been previously reported then they will be removed before the final extract.

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPCPASEND
		(SYSTEMID, TRANSACTIONCODE, ALTOFFICECODE, 
		CLIENTCODE, CLIENTNAME, CLTADDRESSCODE,
		CLIENTTELEPHONE, CLIENTFAX,
		CLIENTATTENTION, CLIENTEMAIL)
	select	distinct
		T.SYSTEMID, 04, T.SYSTEMID,
		T.CLIENTCODE, T.CLIENTNAME, T.CLTADDRESSCODE,
		T.CLIENTTELEPHONE, T.CLIENTFAX,
		CASE WHEN (AT.NAME is not null) THEN (substring(ltrim(AT.TITLE+' '+CASE WHEN(AT.FIRSTNAME is not null) THEN AT.FIRSTNAME+' ' END+AT.NAME), 1,50)) END,
		EM.TELECOMNUMBER
	from #TEMPCPASEND T
	--left join NAME NI		on (NI.NAMECODE=T.CLIENTCODE)
	left join NAME NI		on (NI.NAMECODE=T.CLIENTCODE 
							and NI.DATECEASED is null)  --20198
	--left join NAME AT		on (AT.NAMENO=NI.MAINCONTACT) 
	left join NAME AT		on (AT.NAMENO=NI.MAINCONTACT
							and AT.DATECEASED is null)  --20198
	left join TELECOMMUNICATION EM	on (EM.TELECODE=isnull(AT.MAINEMAIL,NI.MAINEMAIL))  -- SQA 19683 
	where T.CLIENTCODE is not null
	and   T.TRANSACTIONCODE in (12,21)"

	exec (@sSQLString)

	Select  @ErrorCode=@@Error,
		@RowCount =@RowCount+isnull(@@Rowcount,0)
End

-- A Name record is to be reported for each different Division/Address combination embedded within a Case.
-- If these have been previously reported then they will be removed before the final extract.

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPCPASEND
		(SYSTEMID, TRANSACTIONCODE, ALTOFFICECODE, 
		DIVISIONCODE, DIVISIONNAME, DIVADDRESSCODE,
		DIVISIONATTENTION)
	select	distinct
		T.SYSTEMID, 05, T.SYSTEMID,
		T.DIVISIONCODE, T.DIVISIONNAME, T.DIVADDRESSCODE,
		CASE WHEN (AT.NAME is not null) THEN (substring(ltrim(AT.TITLE+' '+CASE WHEN(AT.FIRSTNAME is not null) THEN AT.FIRSTNAME+' ' END+AT.NAME), 1,50)) END
	from #TEMPCPASEND T
	--left join NAME NI	on (NI.NAMECODE=T.DIVISIONCODE)
	left join NAME NI		on (NI.NAMECODE=T.DIVISIONCODE 
							and NI.DATECEASED is null)  --20198
	--left join NAME AT		on (AT.NAMENO=NI.MAINCONTACT) 
	left join NAME AT		on (AT.NAMENO=NI.MAINCONTACT
							and AT.DATECEASED is null)  --20198
	where T.DIVISIONCODE is not null
	and   T.TRANSACTIONCODE in (12,21)"

	exec (@sSQLString)

	Select  @ErrorCode=@@Error,
		@RowCount =@RowCount+isnull(@@Rowcount,0)
End

-- Load the CPASEND table with details of Names that the system has detected as being needed to be 
-- reported to CPA and have been used on a CPA reportable case as an Instructor or Renewal Instructor.


If @bConsiderAllCPACases <> 1
Begin
	If @ErrorCode=0
	-- 17347 This section becomes irrelevant if considering all Cases as Names will have been collected from Case records
	--		 Set the Phone/Fax to return null if empty so that not showing as different from those inserted from case
	--		 Set the Attention to return null if empty for consistency (although not compared), also in sections above
	Begin	
		Set @sSQLString="
		insert into #TEMPCPASEND
			(SYSTEMID, TRANSACTIONCODE, ALTOFFICECODE, 
			CLIENTCODE, CLIENTNAME, CLIENTATTENTION, CLTADDRESSCODE,
			CLIENTTELEPHONE, CLIENTFAX, CLIENTEMAIL)
		Select	distinct
			'"+@sCPAUserCode+"',
			04,
			'"+@sCPAUserCode+"',
			NI.NAMECODE, 
			substring(rtrim(CASE WHEN NI.FIRSTNAME is NULL THEN NI.NAME ELSE NI.NAME+','+NI.FIRSTNAME END), 1, 100),
			CASE WHEN (AT.NAME is not null) THEN (substring(ltrim(AT.TITLE+' '+CASE WHEN(AT.FIRSTNAME is not null) THEN AT.FIRSTNAME+' ' END+AT.NAME), 1,50)) END,
			NI.POSTALADDRESS,
			CASE WHEN(PH.TELECODE  is not null) THEN left(ltrim( PH.ISD+' '+CASE WHEN( PH.AREACODE is not null) THEN  PH.AREACODE+' 'END+ PH.TELECOMNUMBER),20) END,
			CASE WHEN(FAX.TELECODE is not null) THEN left(ltrim(FAX.ISD+' '+CASE WHEN(FAX.AREACODE is not null) THEN FAX.AREACODE+' 'END+FAX.TELECOMNUMBER),20) END,
			EM.TELECOMNUMBER
		From	#TEMPDATATOSEND T
			 join NAME NI		on (NI.NAMENO=T.NAMENO)
		left join NAME AT		on (AT.NAMENO=NI.MAINCONTACT)
		left join TELECOMMUNICATION PH	on (PH.TELECODE =NI.MAINPHONE)
		left join TELECOMMUNICATION FAX	on (FAX.TELECODE=NI.FAX)
		left join TELECOMMUNICATION EM	on (EM.TELECODE=isnull(AT.MAINEMAIL,NI.MAINEMAIL))  -- SQA 19683 

		-- If the default Standing Instruction against the Name is one that has been
		-- flagged as requiring the Agent to act for the Agent then don't bother
		-- reporting these details to CPA.
		where not exists 
		(Select * from INSTRUCTIONFLAG I 
		 where I.INSTRUCTIONCODE=T.INSTRUCTIONCODE 
		 and   I.FLAGNUMBER="+convert(varchar,@nCPAInterceptFlag)+")
		-- Do not report Names already reported in this batch
		and not exists
		(select * from #TEMPCPASEND T1
		 where T1.SYSTEMID       ='"+@sCPAUserCode+"'
		 and   T1.TRANSACTIONCODE=04
		 and   T1.CLIENTCODE     =NI.NAMECODE)
		-- Only report Names that have previously been reported to CPA
		and exists
		(select * from CPASEND CPA
		 where CPA.CLIENTCODE=NI.NAMECODE)
		-- Only report Names that have been used on a live CPA reportable case.
		and exists
		(select * 
		 from CASENAME CI
		 join CASES C  on (C.CASEID=CI.CASEID)
		 left join STATUS S on (S.STATUSCODE=C.STATUSCODE)
		 where CI.NAMENO=T.NAMENO
		 and CI.EXPIRYDATE is null
		 and CI.NAMETYPE in ('R','I')
		 and isnull(S.LIVEFLAG,1)=1
		 and C.REPORTTOTHIRDPARTY=1)"

		Exec (@sSQLString)

		Select	@ErrorCode=@@Error,
			@RowCount =@RowCount+isnull(@@Rowcount,0)
	End


	-- Load the CPASEND table with details of Names that the system has detected as being needed to be 
	-- reported to CPA and have been used on a CPA reportable case as a Division

	If @ErrorCode=0
	Begin	
		Set @sSQLString="
		insert into #TEMPCPASEND
			(SYSTEMID, TRANSACTIONCODE, ALTOFFICECODE, 
			DIVISIONCODE, DIVISIONNAME, DIVISIONATTENTION, DIVADDRESSCODE)
		Select	distinct
			'"+@sCPAUserCode+"',
			05,
			'"+@sCPAUserCode+"',
			substring(NI.NAMECODE,1,6), 
			substring(rtrim(CASE WHEN NI.FIRSTNAME is NULL THEN NI.NAME ELSE NI.NAME+','+NI.FIRSTNAME END), 1, 100),
			CASE WHEN (AT.NAME is not null) THEN (substring(ltrim(AT.TITLE+' '+CASE WHEN(AT.FIRSTNAME is not null) THEN AT.FIRSTNAME+' ' END+AT.NAME), 1,50)) END,
			NI.POSTALADDRESS
		From	#TEMPDATATOSEND T
			 join NAME NI		on (NI.NAMENO=T.NAMENO)
		left join NAME AT		on (AT.NAMENO=NI.MAINCONTACT)
		-- Do not report Names already reported in this batch
		Where not exists
		(select * from #TEMPCPASEND T1
		 where T1.SYSTEMID       ='"+@sCPAUserCode+"'
		 and   T1.TRANSACTIONCODE=05
		 and   T1.DIVISIONCODE   =substring(NI.NAMECODE,1,6))
		-- Only report Names that have previously been reported to CPA
		and exists
		(select * from CPASEND CPA
		 where CPA.DIVISIONCODE=substring(NI.NAMECODE,1,6))
		-- Only report Names that have been used on a live CPA reportable case.
		and exists
		(select * 
		 from CASENAME CI
		 join CASES C  on (C.CASEID=CI.CASEID)
		 left join STATUS S on (S.STATUSCODE=C.STATUSCODE)
		 where CI.NAMENO=T.NAMENO
		 and CI.EXPIRYDATE is null
		 and CI.NAMETYPE='DIV'
		 and isnull(S.LIVEFLAG,1)=1
		 and C.REPORTTOTHIRDPARTY=1)"

		Exec (@sSQLString)

		Select	@ErrorCode=@@Error,
			@RowCount =@RowCount+isnull(@@Rowcount,0)
	End

	-- Load the CPASEND table with details of Names that the system has detected as being needed to be 
	-- reported to CPA and has been used on a CPA Reportable case as a Renewal Debtor

	If @ErrorCode=0
	Begin	
		Set @sSQLString="
		insert into #TEMPCPASEND
			(SYSTEMID, TRANSACTIONCODE, ALTOFFICECODE, 
			INVOICEECODE, INVOICEENAME, INVOICEEATTENTION, INVADDRESSCODE,
			INVOICEETELEPHONE, INVOICEEFAX, INVOICEEEMAIL)
		Select	distinct
			'"+@sCPAUserCode+"',
			06,
			'"+@sCPAUserCode+"',
			NI.NAMECODE, 
			substring(rtrim(CASE WHEN NI.FIRSTNAME is NULL THEN NI.NAME ELSE NI.NAME+','+NI.FIRSTNAME END), 1, 100),
			CASE WHEN (AT.NAME is not null) THEN (substring(ltrim(AT.TITLE+' '+CASE WHEN(AT.FIRSTNAME is not null) THEN AT.FIRSTNAME+' ' END+AT.NAME), 1,50)) END,
			NI.POSTALADDRESS,
			CASE WHEN(PH.TELECODE  is not null) THEN left(ltrim( PH.ISD+' '+CASE WHEN( PH.AREACODE is not null) THEN  PH.AREACODE+' 'END+ PH.TELECOMNUMBER),20) END,
			CASE WHEN(FAX.TELECODE is not null) THEN left(ltrim(FAX.ISD+' '+CASE WHEN(FAX.AREACODE is not null) THEN FAX.AREACODE+' 'END+FAX.TELECOMNUMBER),20) END,
			EM.TELECOMNUMBER
		From	#TEMPDATATOSEND T
			 join NAME NI		on (NI.NAMENO=T.NAMENO)
		left join NAME AT		on (AT.NAMENO=NI.MAINCONTACT)
		left join TELECOMMUNICATION PH	on (PH.TELECODE =NI.MAINPHONE)
		left join TELECOMMUNICATION FAX	on (FAX.TELECODE=NI.FAX)
		left join TELECOMMUNICATION EM	on (EM.TELECODE=isnull(AT.MAINEMAIL,NI.MAINEMAIL))  -- SQA 19683 

		-- If the default Standing Instruction against the Name is one that has been
		-- flagged as requiring the Agent to act for the Agent then don't bother
		-- reporting these details to CPA.
		where not exists 
		(Select * from INSTRUCTIONFLAG I 
		 where I.INSTRUCTIONCODE=T.INSTRUCTIONCODE 
		 and   I.FLAGNUMBER="+convert(varchar,@nCPAInterceptFlag)+")
		-- Do not report Names already reported in this batch
		and not exists
		(select * from #TEMPCPASEND T1
		 where T1.SYSTEMID       ='"+@sCPAUserCode+"'
		 and   T1.TRANSACTIONCODE=06
		 and   T1.INVOICEECODE   =NI.NAMECODE)
		-- Only report Names that have previously been reported to CPA
		and exists
		(select * from CPASEND CPA
		 where CPA.INVOICEECODE=NI.NAMECODE)
		-- Only report Names that have been used on a live CPA reportable case.
		and exists
		(select * 
		 from CASENAME CI
		 join CASES C  on (C.CASEID=CI.CASEID)
		 left join STATUS S on (S.STATUSCODE=C.STATUSCODE)
		 where CI.NAMENO=T.NAMENO
		 and CI.EXPIRYDATE is null
		 and CI.NAMETYPE in ('D','Z')
		 and isnull(S.LIVEFLAG,1)=1
		 and C.REPORTTOTHIRDPARTY=1)"

		Exec (@sSQLString)

		Select	@ErrorCode=@@Error,
			@RowCount =@RowCount+isnull(@@Rowcount,0)
	End
End

-----------------------------------------------------------------------------------
-- SQA17346  Now remove any extracted cases with a StopPayReason where the 
--           StopPayReason and StopPayDate (only - ie send if these two fields 
--           are different - all other changes are irrelevant) are identical to 
--           the last record sent to CPA.
--           This is to avoid sending non relevant changes to CPA.

If @ErrorCode=0
begin
	set @sSQLString="
	delete #TEMPCPASEND
	from #TEMPCPASEND T
	join CPASENDCOMPARE S
			on ((S.CASECODE=T.CASECODE 
			 OR (S.CASECODE is null and T.CASECODE is null and S.CLIENTCODE  =T.CLIENTCODE)
			 OR (S.CASECODE is null and T.CASECODE is null and S.DIVISIONCODE=T.DIVISIONCODE)
			 OR (S.CASECODE is null and T.CASECODE is null and S.INVOICEECODE=T.INVOICEECODE)))
	where	(S.CPASTOPPAYDATE = T.CPASTOPPAYDATE )
	and	(S.STOPPAYINGREASON = T.STOPPAYINGREASON 
	and S.STOPPAYINGREASON is not null 
	and T.STOPPAYINGREASON is not null)"

	Exec (@sSQLString)

	Select 	@ErrorCode=@@Error,
		@RowCount =@RowCount-@@RowCount	
end
--------------------------------------------------------------------
-- RFC57212
-- Any Case that has multiple debtors are to be extracted into a 
-- separate table along with the percentage of the bill each debtor 
-- is responsible for.
--------------------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPCPASENDDEBTORS (CASEID, NAMETYPE, INVOICEECODE, CPAINVOICEENO, BILLPERCENTAGE)
	Select CN.CASEID, 
	       CN.NAMETYPE,
	       N.NAMECODE,
	       CASE WHEN(ISNUMERIC(NA.ALIAS)=1) THEN CAST(NA.ALIAS as INT) END,
	       CN.BILLPERCENTAGE
	from #TEMPCPASEND T
	join CASES C	 on ( C.CASEID=T.CASEID)
	join (	select CASEID, NAMETYPE, count(*) as TotalInvoicees
		from CASENAME
		where EXPIRYDATE is null
		group by CASEID, NAMETYPE
		having count(*)>1) CC on (CC.CASEID=T.CASEID
				      and CC.NAMETYPE=T.INVOICEENAMETYPE)
	join CASENAME CN on (CN.CASEID=T.CASEID
			 and CN.NAMETYPE=T.INVOICEENAMETYPE
			 and CN.EXPIRYDATE is null)
	join NAME N	 on (N.NAMENO=CN.NAMENO)

	left join NAMEALIAS NA	on (NA.NAMENO	=N.NAMENO
				and NA.ALIASTYPE='_C'
						-- Use best fit to determine ALIAS for the Case
						-- characteristics of CountryCode and PropertyType
				and NA.ALIAS    =(select substring(max(	CASE WHEN(NA1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
									CASE WHEN(NA1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
									NA1.ALIAS),3,30)
						  from NAMEALIAS NA1
						  where NA1.NAMENO =NA.NAMENO
						  and NA1.ALIASTYPE=NA.ALIASTYPE
						  and ISNUMERIC(NA1.ALIAS)=1
						  and(NA1.COUNTRYCODE =C.COUNTRYCODE  OR NA1.COUNTRYCODE  is null)
						  and(NA1.PROPERTYTYPE=C.PROPERTYTYPE OR NA1.PROPERTYTYPE is null)))"
	Exec @ErrorCode=sp_executesql @sSQLString
End

--------------------------------------------------------------------
-- RFC57212
-- Any Case that is being reported in this batch that when last sent
-- to CPA had multiple debtors reported, should still report the
-- current debtor separately even if the Case now only has a single
-- debtor.
--------------------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPCPASENDDEBTORS (CASEID, NAMETYPE, INVOICEECODE, CPAINVOICEENO, BILLPERCENTAGE)
	Select T.CASEID, 
	       isnull(CZ.NAMETYPE,CD.NAMETYPE),
	       N.NAMECODE,
	       CASE WHEN(ISNUMERIC(NA.ALIAS)=1) THEN CAST(NA.ALIAS as INT) END,
	       100.00
	       
	from #TEMPCPASEND T
	join CASES C		on (  C.CASEID=T.CASEID)
	join CPASENDCOMPARE CSC on (CSC.CASEID=T.CASEID)
	---------------------------------
	-- Find details of the last batch
	-- the Case was reported in.
	---------------------------------
	join CPASEND CPA        on (CPA.SYSTEMID=CSC.SYSTEMID
				and CPA.BATCHNO =CSC.BATCHNO
				and CPA.CASECODE=CSC.CASECODE)
	----------------------------------
	-- Now find the ROWID in the batch
	-- where multiple debtors were
	-- reported
	----------------------------------
	join (	Select CPASENDROWID
		from CPASENDDEBTORS
		where BILLPERCENTAGE<100
		group by CPASENDROWID
		having count(*)>1) CN1
				on (CN1.CPASENDROWID=CPA.ROWID)
				
	left join CASENAME CZ	on (CZ.CASEID=T.CASEID
				and CZ.EXPIRYDATE is null
				and CZ.NAMETYPE='Z')
	left join CASENAME CD	on (CD.CASEID=T.CASEID
				and CD.EXPIRYDATE is null
				and CD.NAMETYPE='D'
				and CZ.CASEID is null)	-- Only require Debtor if no Renewal Debtor
	       
	join NAME N	 on (N.NAMENO=isnull(CZ.NAMENO,CD.NAMENO))
	---------------------------------
	-- Check that we have not already 
	-- reported the debtors in this
	-- batch
	---------------------------------
	left join #TEMPCPASENDDEBTORS CSD
				on (CSD.CASEID=T.CASEID)

	left join NAMEALIAS NA	on (NA.NAMENO	=N.NAMENO
				and NA.ALIASTYPE='_C'
						-- Use best fit to determine ALIAS for the Case
						-- characteristics of CountryCode and PropertyType
				and NA.ALIAS    =(select substring(max(	CASE WHEN(NA1.COUNTRYCODE  is null) THEN '0' ELSE '1' END +
									CASE WHEN(NA1.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
									NA1.ALIAS),3,30)
						  from NAMEALIAS NA1
						  where NA1.NAMENO =NA.NAMENO
						  and NA1.ALIASTYPE=NA.ALIASTYPE
						  and ISNUMERIC(NA1.ALIAS)=1
						  and(NA1.COUNTRYCODE =C.COUNTRYCODE  OR NA1.COUNTRYCODE  is null)
						  and(NA1.PROPERTYTYPE=C.PROPERTYTYPE OR NA1.PROPERTYTYPE is null)))
	Where CSD.CASEID is null
	and (CZ.BILLPERCENTAGE=100.00 OR (CZ.CASEID is null and CD.BILLPERCENTAGE =100.00))"
	
	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	-----------------------------------------------------
	-- A Name record is to be reported for each different 
	-- Invoicee combination embedded within a Case.
	-- If these have been previously reported then they 
	-- will be removed before the final extract.
	-----------------------------------------------------
	Set @sSQLString="
	insert into #TEMPCPASEND
		(SYSTEMID, TRANSACTIONCODE, ALTOFFICECODE, 
		INVOICEECODE, INVOICEENAME, INVADDRESSCODE,
		INVOICEETELEPHONE, INVOICEEFAX,
		INVOICEEATTENTION, INVOICEEEMAIL)
	
	select  T.SYSTEMID, 06, T.SYSTEMID,
		T.INVOICEECODE, T.INVOICEENAME, T.INVADDRESSCODE,
		T.INVOICEETELEPHONE, T.INVOICEEFAX,
		CASE WHEN (AT.NAME is not null) THEN (substring(ltrim(AT.TITLE+' '+CASE WHEN(AT.FIRSTNAME is not null) THEN AT.FIRSTNAME+' ' END+AT.NAME), 1,50)) END,
		EM.TELECOMNUMBER
	from #TEMPCPASEND T
	left join NAME NI		on (NI.NAMECODE=T.INVOICEECODE 
					and NI.DATECEASED is null)  --20198
	left join NAME AT		on (AT.NAMENO=NI.MAINCONTACT
					and AT.DATECEASED is null)  --20198
	left join TELECOMMUNICATION EM	on (EM.TELECODE=isnull(AT.MAINEMAIL,NI.MAINEMAIL))  -- SQA 19683 
	where T.INVOICEECODE is not null
	and   T.TRANSACTIONCODE in (12,21)
	
	UNION
	--------------------------------------------------------
	-- Neeed to also report any INVOICEE name details that
	-- is being included as a subsequent debtor on the Case.
	--------------------------------------------------------
	Select	'"+@sCPAUserCode+"',
		06,
		'"+@sCPAUserCode+"',
		T.INVOICEECODE, 
		substring(rtrim(CASE WHEN NI.FIRSTNAME is NULL THEN NI.NAME ELSE NI.NAME+','+NI.FIRSTNAME END), 1, 100),
		NI.POSTALADDRESS,
		CASE WHEN(PH.TELECODE  is not null) THEN left(ltrim( PH.ISD+' '+CASE WHEN( PH.AREACODE is not null) THEN  PH.AREACODE+' 'END+ PH.TELECOMNUMBER),20) END,
		CASE WHEN(FAX.TELECODE is not null) THEN left(ltrim(FAX.ISD+' '+CASE WHEN(FAX.AREACODE is not null) THEN FAX.AREACODE+' 'END+FAX.TELECOMNUMBER),20) END,
		CASE WHEN (AT.NAME is not null) THEN (substring(ltrim(AT.TITLE+' '+CASE WHEN(AT.FIRSTNAME is not null) THEN AT.FIRSTNAME+' ' END+AT.NAME), 1,50)) END,
		EM.TELECOMNUMBER
	From	#TEMPCPASENDDEBTORS T
	join NAME NI		        on (NI.NAMECODE=T.INVOICEECODE)
	left join NAME AT		on (AT.NAMENO=NI.MAINCONTACT)
	left join TELECOMMUNICATION PH	on (PH.TELECODE =NI.MAINPHONE)
	left join TELECOMMUNICATION FAX	on (FAX.TELECODE=NI.FAX)
	left join TELECOMMUNICATION EM	on (EM.TELECODE=isnull(AT.MAINEMAIL,NI.MAINEMAIL))  -- SQA 19683 

	-- Do not report Names already reported in this batch
	Where not exists
	(select * from #TEMPCPASEND T1
	 where T1.SYSTEMID       ='"+@sCPAUserCode+"'
	 and   T1.TRANSACTIONCODE=06
	 and   T1.INVOICEECODE   =NI.NAMECODE)"
	 
	exec (@sSQLString)

	Select  @ErrorCode=@@Error,
		@RowCount =@RowCount+isnull(@@Rowcount,0)
End

-----------------------------------------------------------------------------
-- C L E A N U P 
-- A final cleanup of the data extracted is required to remove any characters
-- that the CPA system is not expected to be able to handle.
-- The address fields were already handled in cpa_FormatAddresses.
-----------------------------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPCPASEND
	Set	FILENUMBER		=replace(replace(FILENUMBER,       char(13)+char(10),' '),char(9),''),
		CLIENTSREFERENCE	=replace(replace(CLIENTSREFERENCE, char(13)+char(10),' '),char(9),''),
		MARK			=replace(replace(MARK,             char(13)+char(10),' '),char(9),''),
		PRIORITYNO		=replace(replace(PRIORITYNO,       char(13)+char(10),' '),char(9),''),
		PARENTNO		=replace(replace(PARENTNO,         char(13)+char(10),' '),char(9),''),
		PCTFILINGNO		=replace(replace(PCTFILINGNO,      char(13)+char(10),' '),char(9),''),
		ASSOCDESIGNNO		=replace(replace(ASSOCDESIGNNO,    char(13)+char(10),' '),char(9),''),
		APPLICATIONNO		=replace(replace(APPLICATIONNO,    char(13)+char(10),' '),char(9),''),
		ACCEPTANCENO		=replace(replace(ACCEPTANCENO,     char(13)+char(10),' '),char(9),''),
		PUBLICATIONNO		=replace(replace(PUBLICATIONNO,    char(13)+char(10),' '),char(9),''),
		REGISTRATIONNO		=replace(replace(REGISTRATIONNO,   char(13)+char(10),' '),char(9),''),
		OWNERNAME		=replace(replace(OWNERNAME,        char(13)+char(10),' '),char(9),''),
		CLIENTNAME		=replace(replace(CLIENTNAME,       char(13)+char(10),' '),char(9),''),
		CLIENTATTENTION		=replace(replace(CLIENTATTENTION,  char(13)+char(10),' '),char(9),''),
		CLIENTTELEPHONE		=replace(replace(CLIENTTELEPHONE,  char(13)+char(10),' '),char(9),''),
		CLIENTFAX		=replace(replace(CLIENTFAX,        char(13)+char(10),' '),char(9),''),
		CLIENTEMAIL		=replace(replace(CLIENTEMAIL,      char(13)+char(10),' '),char(9),''),
		DIVISIONNAME		=replace(replace(DIVISIONNAME,     char(13)+char(10),' '),char(9),''),
		DIVISIONATTENTION	=replace(replace(DIVISIONATTENTION,char(13)+char(10),' '),char(9),''),
		FOREIGNAGENTNAME	=replace(replace(FOREIGNAGENTNAME, char(13)+char(10),' '),char(9),''),
		ATTORNEYNAME		=replace(replace(ATTORNEYNAME,     char(13)+char(10),' '),char(9),''),
		INVOICEENAME		=replace(replace(INVOICEENAME,     char(13)+char(10),' '),char(9),''),
		INVOICEEATTENTION	=replace(replace(INVOICEEATTENTION,char(13)+char(10),' '),char(9),''),
		INVOICEETELEPHONE	=replace(replace(INVOICEETELEPHONE,char(13)+char(10),' '),char(9),''),
		INVOICEEFAX		=replace(replace(INVOICEEFAX,      char(13)+char(10),' '),char(9),''),
		INVOICEEEMAIL		=replace(replace(INVOICEEEMAIL,    char(13)+char(10),' '),char(9),''),
		NARRATIVE		=replace(replace(NARRATIVE,        char(13)+char(10),' '),char(9),'')"

	Exec (@sSQLString)

	Select 	@ErrorCode=@@Error
End
---------------------
-- Load the addresses
---------------------
If @ErrorCode=0
begin
	Exec @ErrorCode=cpa_FormatAddresses
end
-------------------------------------------------------------------------------------
-- Now remove any extracted cases where the information extracted is identical to 
-- the last record sent to CPA about this Case UNLESS there is a Reject Event showing
-- that the Case has been rejected and we are still expecting a validated Case.  
-- This is to avoid sending non relevant changes to CPA.
-- RFC57212
-- This will now need to be performed in two steps so that consideration can be given
-- to the reporting of multiple debtors associated with the Case.
-------------------------------------------------------------------------------------

If @ErrorCode=0
begin
	set @sSQLString="
	Update T
	Set DELETECANDIDATE=1
	from #TEMPCPASEND T
	join CPASENDCOMPARE S
			on ((S.CASECODE=T.CASECODE 
			 or (S.CASECODE is null and T.CASECODE is null and S.CLIENTCODE  =T.CLIENTCODE)
			 or (S.CASECODE is null and T.CASECODE is null and S.DIVISIONCODE=T.DIVISIONCODE)
			 or  (S.CASECODE is null and T.CASECODE is null and S.INVOICEECODE=T.INVOICEECODE)))
	where	(S.TRANSACTIONCODE   =T.TRANSACTIONCODE    or (S.TRANSACTIONCODE=12 and T.TRANSACTIONCODE=21))
	and	(S.PROPERTYTYPE      =T.PROPERTYTYPE       or (S.PROPERTYTYPE       is null and T.PROPERTYTYPE       is null))
	and	(S.ALTOFFICECODE     =T.ALTOFFICECODE      or (S.ALTOFFICECODE      is null and T.ALTOFFICECODE      is null))
--	and	(S.FILENUMBER        =T.FILENUMBER         or (S.FILENUMBER         is null and T.FILENUMBER         is null))
	and	(S.CLIENTSREFERENCE  =T.CLIENTSREFERENCE   or (S.CLIENTSREFERENCE   is null and T.CLIENTSREFERENCE   is null))
	and	(S.CPACOUNTRYCODE    =T.CPACOUNTRYCODE     or (S.CPACOUNTRYCODE     is null and T.CPACOUNTRYCODE     is null))
	and	(S.RENEWALTYPECODE   =T.RENEWALTYPECODE    or (S.RENEWALTYPECODE    is null and T.RENEWALTYPECODE    is null))
	and	(S.MARK              =T.MARK               or (S.MARK               is null and T.MARK               is null))
	and	(S.ENTITYSIZE        =T.ENTITYSIZE         or (S.ENTITYSIZE         is null and T.ENTITYSIZE         is null))
	and	(S.PRIORITYDATE      =T.PRIORITYDATE       or (S.PRIORITYDATE       is null and T.PRIORITYDATE       is null) OR T.CONVENTION=0)	-- SQA16332
	and	(S.PARENTDATE        =T.PARENTDATE         or (S.PARENTDATE         is null and T.PARENTDATE         is null))
	and	(S.NEXTTAXDATE       =T.NEXTTAXDATE        or (S.NEXTTAXDATE        is null and T.NEXTTAXDATE        is null))
	and	(S.NEXTDECOFUSEDATE  =T.NEXTDECOFUSEDATE   or (S.NEXTDECOFUSEDATE   is null and T.NEXTDECOFUSEDATE   is null))
	and	(S.PCTFILINGDATE     =T.PCTFILINGDATE      or (S.PCTFILINGDATE      is null and T.PCTFILINGDATE      is null))
	and	(S.ASSOCDESIGNDATE   =T.ASSOCDESIGNDATE    or (S.ASSOCDESIGNDATE    is null and T.ASSOCDESIGNDATE    is null))
	and	(S.NEXTAFFIDAVITDATE =T.NEXTAFFIDAVITDATE  or (S.NEXTAFFIDAVITDATE  is null and T.NEXTAFFIDAVITDATE  is null))
	and	(S.APPLICATIONDATE   =T.APPLICATIONDATE    or (S.APPLICATIONDATE    is null and T.APPLICATIONDATE    is null))
	and	(S.ACCEPTANCEDATE    =T.ACCEPTANCEDATE     or (S.ACCEPTANCEDATE     is null and T.ACCEPTANCEDATE     is null))
	and	(S.PUBLICATIONDATE   =T.PUBLICATIONDATE    or (S.PUBLICATIONDATE    is null and T.PUBLICATIONDATE    is null))
	and	(S.REGISTRATIONDATE  =T.REGISTRATIONDATE   or (S.REGISTRATIONDATE   is null and T.REGISTRATIONDATE   is null))
	-- Exclude the comparison of the Renewal Date as a trigger for reporting the Case to CPA as CPA
	-- may actually calculate a different Renewal Date.
--	and	(S.RENEWALDATE       =T.RENEWALDATE        or (S.RENEWALDATE        is null and T.RENEWALDATE        is null))
	and	(S.NOMINALWORKINGDATE=T.NOMINALWORKINGDATE or (S.NOMINALWORKINGDATE is null and T.NOMINALWORKINGDATE is null))
	and	(S.EXPIRYDATE        =T.EXPIRYDATE         or (S.EXPIRYDATE         is null and T.EXPIRYDATE         is null))
	and	(S.CPASTARTPAYDATE   =T.CPASTARTPAYDATE    or (                                 T.CPASTARTPAYDATE    is null))
	and	(S.CPASTOPPAYDATE    =T.CPASTOPPAYDATE     or (S.CPASTOPPAYDATE     is null and T.CPASTOPPAYDATE     is null))
	and	(S.STOPPAYINGREASON  =T.STOPPAYINGREASON   or (S.STOPPAYINGREASON   is null and T.STOPPAYINGREASON   is null))"

	set @sSQLString1="
	-- SDR-14800 Use fn_RemoveNoiseCharacters here too and also remove leading zeros for comparison.
	and	(dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.PRIORITYNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.PRIORITYNO))),LEN(ltrim(rtrim(S.PRIORITYNO)))))=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(T.PRIORITYNO)),PATINDEX('%[^0]%',ltrim(rtrim(T.PRIORITYNO))),LEN(ltrim(rtrim(T.PRIORITYNO)))))
		 or (S.PRIORITYNO is null and T.PRIORITYNO is null))
	and	(dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.PARENTNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.PARENTNO))),LEN(ltrim(rtrim(S.PARENTNO)))))=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(T.PARENTNO)),PATINDEX('%[^0]%',ltrim(rtrim(T.PARENTNO))),LEN(ltrim(rtrim(T.PARENTNO))))) 
		or (S.PARENTNO is null and T.PARENTNO is null))
	and	(dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.PCTFILINGNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.PCTFILINGNO))),LEN(ltrim(rtrim(S.PCTFILINGNO)))))=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(T.PCTFILINGNO)),PATINDEX('%[^0]%',ltrim(rtrim(T.PCTFILINGNO))),LEN(ltrim(rtrim(T.PCTFILINGNO))))) 
		or (S.PCTFILINGNO is null and T.PCTFILINGNO is null))
	and	(dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.ASSOCDESIGNNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.ASSOCDESIGNNO))),LEN(ltrim(rtrim(S.ASSOCDESIGNNO)))))=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(T.ASSOCDESIGNNO)),PATINDEX('%[^0]%',ltrim(rtrim(T.ASSOCDESIGNNO))),LEN(ltrim(rtrim(T.ASSOCDESIGNNO))))) 
		or (S.ASSOCDESIGNNO is null and T.ASSOCDESIGNNO is null))
	and	(dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.APPLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.APPLICATIONNO))),LEN(ltrim(rtrim(S.APPLICATIONNO)))))=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(T.APPLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(T.APPLICATIONNO))),LEN(ltrim(rtrim(T.APPLICATIONNO))))) 
		or (S.APPLICATIONNO is null and T.APPLICATIONNO is null))
	and	(dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.ACCEPTANCENO)),PATINDEX('%[^0]%',ltrim(rtrim(S.ACCEPTANCENO))),LEN(ltrim(rtrim(S.ACCEPTANCENO)))))=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(T.ACCEPTANCENO)),PATINDEX('%[^0]%',ltrim(rtrim(T.ACCEPTANCENO))),LEN(ltrim(rtrim(T.ACCEPTANCENO))))) 
		or (S.ACCEPTANCENO is null and T.ACCEPTANCENO is null))
	and	(dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.PUBLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.PUBLICATIONNO))),LEN(ltrim(rtrim(S.PUBLICATIONNO)))))=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(T.PUBLICATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(T.PUBLICATIONNO))),LEN(ltrim(rtrim(T.PUBLICATIONNO))))) 
		or (S.PUBLICATIONNO is null and T.PUBLICATIONNO is null))
	and	(dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(S.REGISTRATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(S.REGISTRATIONNO))),LEN(ltrim(rtrim(S.REGISTRATIONNO)))))=dbo.fn_RemoveNoiseCharacters(SUBSTRING(ltrim(rtrim(T.REGISTRATIONNO)),PATINDEX('%[^0]%',ltrim(rtrim(T.REGISTRATIONNO))),LEN(ltrim(rtrim(T.REGISTRATIONNO))))) 
		or (S.REGISTRATIONNO is null and T.REGISTRATIONNO is null))"

	set @sSQLString2="
	and	(S.INTLCLASSES       =T.INTLCLASSES        or (S.INTLCLASSES        is null and T.INTLCLASSES        is null))
	and	(S.LOCALCLASSES      =T.LOCALCLASSES       or (S.LOCALCLASSES       is null and T.LOCALCLASSES       is null))
	and	(S.NUMBEROFYEARS     =T.NUMBEROFYEARS      or (S.NUMBEROFYEARS      is null and T.NUMBEROFYEARS      is null))
	and	(S.NUMBEROFCLAIMS    =T.NUMBEROFCLAIMS     or (S.NUMBEROFCLAIMS     is null and T.NUMBEROFCLAIMS     is null))
	and	(S.NUMBEROFDESIGNS   =T.NUMBEROFDESIGNS    or (S.NUMBEROFDESIGNS    is null and T.NUMBEROFDESIGNS    is null))
	and	(S.NUMBEROFCLASSES   =T.NUMBEROFCLASSES    or (S.NUMBEROFCLASSES    is null and T.NUMBEROFCLASSES    is null))
	and	(S.NUMBEROFSTATES    =T.NUMBEROFSTATES     or (S.NUMBEROFSTATES     is null and T.NUMBEROFSTATES     is null))
	and	(S.DESIGNATEDSTATES  =T.DESIGNATEDSTATES   or (S.DESIGNATEDSTATES   is null and T.DESIGNATEDSTATES   is null))
	and	(replace(replace(replace(replace(upper(S.OWNERNAME),       ' ',''),'.',''),'-',''),',','') =replace(replace(replace(replace(upper(T.OWNERNAME),       ' ',''),'.',''),'-',''),',','') or (S.OWNERNAME          is null and T.OWNERNAME          is null))
	and	(replace(replace(replace(replace(upper(S.CLIENTNAME),      ' ',''),'.',''),'-',''),',','') =replace(replace(replace(replace(upper(T.CLIENTNAME),      ' ',''),'.',''),'-',''),',','') or (S.CLIENTNAME         is null and T.CLIENTNAME         is null) OR T.TRANSACTIONCODE<>04)
	and	(replace(replace(replace(replace(upper(S.DIVISIONNAME),    ' ',''),'.',''),'-',''),',','') =replace(replace(replace(replace(upper(T.DIVISIONNAME),    ' ',''),'.',''),'-',''),',','') or (S.DIVISIONNAME       is null and T.DIVISIONNAME       is null) OR T.TRANSACTIONCODE<>05)"


	set @sSQLString3="
	and	(replace(replace(replace(replace(upper(S.FOREIGNAGENTNAME),' ',''),'.',''),'-',''),',','') =replace(replace(replace(replace(upper(T.FOREIGNAGENTNAME),' ',''),'.',''),'-',''),',','') or (T.FOREIGNAGENTNAME   is null) OR T.PROPERTYTYPE='T')
	and	(replace(replace(replace(replace(upper(S.INVOICEENAME),    ' ',''),'.',''),'-',''),',','') =replace(replace(replace(replace(upper(T.INVOICEENAME),    ' ',''),'.',''),'-',''),',','') or (S.INVOICEENAME       is null and T.INVOICEENAME       is null) OR T.TRANSACTIONCODE<>06)
	and	(S.OWNERNAMECODE=T.OWNERNAMECODE                                     or (S.OWNERNAMECODE      is null and T.OWNERNAMECODE      is null))
	and	(replace(S.OWNADDRESSLINE1,' ','')=replace(T.OWNADDRESSLINE1,' ','') or (S.OWNADDRESSLINE1    is null and T.OWNADDRESSLINE1    is null))
	and	(replace(S.OWNADDRESSLINE2,' ','')=replace(T.OWNADDRESSLINE2,' ','') or (S.OWNADDRESSLINE2    is null and T.OWNADDRESSLINE2    is null))
	and	(replace(S.OWNADDRESSLINE3,' ','')=replace(T.OWNADDRESSLINE3,' ','') or (S.OWNADDRESSLINE3    is null and T.OWNADDRESSLINE3    is null))
	and	(replace(S.OWNADDRESSLINE4,' ','')=replace(T.OWNADDRESSLINE4,' ','') or (S.OWNADDRESSLINE4    is null and T.OWNADDRESSLINE4    is null))
	and	(S.OWNADDRESSCOUNTRY =T.OWNADDRESSCOUNTRY  or (S.OWNADDRESSCOUNTRY  is null and T.OWNADDRESSCOUNTRY  is null))
	and	(S.OWNADDRESSPOSTCODE=T.OWNADDRESSPOSTCODE or (S.OWNADDRESSPOSTCODE is null and T.OWNADDRESSPOSTCODE is null))
	and	(S.CLIENTCODE        =T.CLIENTCODE         or (S.CLIENTCODE         is null and T.CLIENTCODE         is null))
	and	(S.CLIENTATTENTION		=T.CLIENTATTENTION  or (S.CLIENTATTENTION  is null and T.CLIENTATTENTION  is null) OR T.TRANSACTIONCODE<>04)
	and	(replace(replace(S.CLTADDRESSLINE1,  ' ',''),',','')=replace(replace(T.CLTADDRESSLINE1,  ' ',''),',','')   or (S.CLTADDRESSLINE1    is null and T.CLTADDRESSLINE1    is null) OR T.TRANSACTIONCODE<>04)
	and	(replace(replace(S.CLTADDRESSLINE2,  ' ',''),',','')=replace(replace(T.CLTADDRESSLINE2,  ' ',''),',','')   or (S.CLTADDRESSLINE2    is null and T.CLTADDRESSLINE2    is null) OR T.TRANSACTIONCODE<>04)
	and	(replace(replace(S.CLTADDRESSLINE3,  ' ',''),',','')=replace(replace(T.CLTADDRESSLINE3,  ' ',''),',','')   or (S.CLTADDRESSLINE3    is null and T.CLTADDRESSLINE3    is null) OR T.TRANSACTIONCODE<>04)
	and	(replace(replace(S.CLTADDRESSLINE4,  ' ',''),',','')=replace(replace(T.CLTADDRESSLINE4,  ' ',''),',','')   or (S.CLTADDRESSLINE4    is null and T.CLTADDRESSLINE4    is null) OR T.TRANSACTIONCODE<>04)
	and	(S.CLTADDRESSCOUNTRY =T.CLTADDRESSCOUNTRY  or (S.CLTADDRESSCOUNTRY  is null and T.CLTADDRESSCOUNTRY  is null) OR T.TRANSACTIONCODE<>04)
	and	(S.CLTADDRESSPOSTCODE=T.CLTADDRESSPOSTCODE or (S.CLTADDRESSPOSTCODE is null and T.CLTADDRESSPOSTCODE is null) OR T.TRANSACTIONCODE<>04)
	and	(S.CLIENTTELEPHONE   =T.CLIENTTELEPHONE    or (S.CLIENTTELEPHONE    is null and T.CLIENTTELEPHONE    is null) OR T.TRANSACTIONCODE<>04)
	and	(S.CLIENTFAX         =T.CLIENTFAX          or (S.CLIENTFAX          is null and T.CLIENTFAX          is null) OR T.TRANSACTIONCODE<>04)
	and	(S.CLIENTEMAIL       =T.CLIENTEMAIL        or (S.CLIENTEMAIL        is null and T.CLIENTEMAIL        is null) OR T.TRANSACTIONCODE<>04)"

	set @sSQLString4="
	and	(S.DIVISIONCODE      =T.DIVISIONCODE       or (S.DIVISIONCODE       is null and T.DIVISIONCODE       is null))
		and	(S.DIVISIONATTENTION=T.DIVISIONATTENTION or (S.DIVISIONATTENTION is null and T.DIVISIONATTENTION is null) OR T.TRANSACTIONCODE<>05)
	and	(replace(replace(S.DIVADDRESSLINE1,  ' ',''),',','')=replace(replace(T.DIVADDRESSLINE1,  ' ',''),',','')   or (S.DIVADDRESSLINE1    is null and T.DIVADDRESSLINE1    is null) OR T.TRANSACTIONCODE<>05)
	and	(replace(replace(S.DIVADDRESSLINE2,  ' ',''),',','')=replace(replace(T.DIVADDRESSLINE2,  ' ',''),',','')   or (S.DIVADDRESSLINE2    is null and T.DIVADDRESSLINE2    is null) OR T.TRANSACTIONCODE<>05)
	and	(replace(replace(S.DIVADDRESSLINE3,  ' ',''),',','')=replace(replace(T.DIVADDRESSLINE3,  ' ',''),',','')   or (S.DIVADDRESSLINE3    is null and T.DIVADDRESSLINE3    is null) OR T.TRANSACTIONCODE<>05)
	and	(replace(replace(S.DIVADDRESSLINE4,  ' ',''),',','')=replace(replace(T.DIVADDRESSLINE4,  ' ',''),',','')   or (S.DIVADDRESSLINE4    is null and T.DIVADDRESSLINE4    is null) OR T.TRANSACTIONCODE<>05)
	and	(S.DIVADDRESSCOUNTRY =T.DIVADDRESSCOUNTRY  or (S.DIVADDRESSCOUNTRY  is null and T.DIVADDRESSCOUNTRY  is null) OR T.TRANSACTIONCODE<>05)
	and	(S.DIVADDRESSPOSTCODE=T.DIVADDRESSPOSTCODE or (S.DIVADDRESSPOSTCODE is null and T.DIVADDRESSPOSTCODE is null) OR T.TRANSACTIONCODE<>05)
	and	(S.FOREIGNAGENTCODE  =T.FOREIGNAGENTCODE   or (T.FOREIGNAGENTCODE   is null) OR T.PROPERTYTYPE='T')"

	set @sSQLString5="
	and	(S.INVOICEECODE      =T.INVOICEECODE      or (S.INVOICEECODE      is null and T.INVOICEECODE      is null)) -- RFC56175 Removed TRANSACTIONCODE restriction so changes will be reported
	and	(S.INVOICEEATTENTION =T.INVOICEEATTENTION or (S.INVOICEEATTENTION is null and T.INVOICEEATTENTION is null) OR T.TRANSACTIONCODE<>06)
	and	(replace(replace(S.INVADDRESSLINE1,  ' ',''),',','')=replace(replace(T.INVADDRESSLINE1,  ' ',''),',','')   or (S.INVADDRESSLINE1    is null and T.INVADDRESSLINE1    is null) OR T.TRANSACTIONCODE<>06)
	and	(replace(replace(S.INVADDRESSLINE2,  ' ',''),',','')=replace(replace(T.INVADDRESSLINE2,  ' ',''),',','')   or (S.INVADDRESSLINE2    is null and T.INVADDRESSLINE2    is null) OR T.TRANSACTIONCODE<>06)
	and	(replace(replace(S.INVADDRESSLINE3,  ' ',''),',','')=replace(replace(T.INVADDRESSLINE3,  ' ',''),',','')   or (S.INVADDRESSLINE3    is null and T.INVADDRESSLINE3    is null) OR T.TRANSACTIONCODE<>06)
	and	(replace(replace(S.INVADDRESSLINE4,  ' ',''),',','')=replace(replace(T.INVADDRESSLINE4,  ' ',''),',','')   or (S.INVADDRESSLINE4    is null and T.INVADDRESSLINE4    is null) OR T.TRANSACTIONCODE<>06)
	and	(S.INVADDRESSCOUNTRY =T.INVADDRESSCOUNTRY  or (S.INVADDRESSCOUNTRY  is null and T.INVADDRESSCOUNTRY  is null) OR T.TRANSACTIONCODE<>06)
	and	(S.INVADDRESSPOSTCODE=T.INVADDRESSPOSTCODE or (S.INVADDRESSPOSTCODE is null and T.INVADDRESSPOSTCODE is null) OR T.TRANSACTIONCODE<>06)
	and	(S.INVOICEETELEPHONE =T.INVOICEETELEPHONE  or (S.INVOICEETELEPHONE  is null and T.INVOICEETELEPHONE  is null) OR T.TRANSACTIONCODE<>06)
	and	(S.INVOICEEFAX       =T.INVOICEEFAX        or (S.INVOICEEFAX        is null and T.INVOICEEFAX        is null) OR T.TRANSACTIONCODE<>06)
	and	(S.INVOICEEEMAIL     =T.INVOICEEEMAIL      or (S.INVOICEEEMAIL      is null and T.INVOICEEEMAIL      is null) OR T.TRANSACTIONCODE<>06)"+
	CASE WHEN(@nCPARejectedEventNo is not null)
		THEN "	and not exists
			(select * from CASEEVENT CE
			 where CE.CASEID=T.CASEID
			 and CE.EVENTDATE is not null
			 and CE.EVENTNO="+convert(varchar,@nCPARejectedEventNo)+")"
	END

	Exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString5)

	Set @ErrorCode=@@Error
end
-----------------------------------------------------
-- Now complete the delete of #TEMPCPASEND rows
-- if they are marked as a candidate to be removed
-- AND there is no discrepancy between the invoiceees
-- being reported and what was reported in the last
-- batch the case was reported in.
-----------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString="
	With NamesCompare (CASEID)
		as (	--------------------------------------------------
			-- Compare debtors being reported in this batch
			-- against debtors reported the last time the Case
			-- was reported and if there is any discrepancy
			-- return the CASEID
			--------------------------------------------------
			select CN1.CASEID
			from #TEMPCPASENDDEBTORS CN1
			left join CPASENDCOMPARE CSC on (CSC.CASEID=CN1.CASEID)
			left join CPASEND CPA        on (CPA.SYSTEMID=CSC.SYSTEMID
						     and CPA.BATCHNO =CSC.BATCHNO
						     and CPA.CASECODE=CSC.CASECODE)
			left join CPASENDDEBTORS CN2 on (CN2.CPASENDROWID  =CPA.ROWID
						     and(CN2.INVOICEECODE  =CN1.INVOICEECODE  OR (CN2.INVOICEECODE  is null and CN1.INVOICEECODE  is null))
						     and(CN2.CPAINVOICEENO =CN1.CPAINVOICEENO OR (CN2.CPAINVOICEENO is null and CN1.CPAINVOICEENO is null))
						     and CN2.BILLPERCENTAGE=CN1.BILLPERCENTAGE)
			Where CN2.ROWID is null
			UNION
			--------------------------------------------------
			-- Cases being reported in this batch should now
			-- compare the debtors reported the last time the
			-- Case was reported, against the debtors being 
			-- reported for the Case in this batch and report
			-- CASEID if there is any discrepancy.
			-- This will pick up where less debtors are being
			-- reported in this batch.
			--------------------------------------------------
			select T.CASEID
			from #TEMPCPASEND T
			join CPASENDCOMPARE CSC on (CSC.CASEID=T.CASEID)
			join CPASEND CPA        on (CPA.SYSTEMID=CSC.SYSTEMID
						and CPA.BATCHNO =CSC.BATCHNO
						and CPA.CASECODE=CSC.CASECODE)
			join CPASENDDEBTORS CN1 on (CN1.CPASENDROWID=CPA.ROWID)
			left join #TEMPCPASENDDEBTORS CN2
						on (CN2.CASEID=CPA.CASEID
						and(CN2.INVOICEECODE  =CN1.INVOICEECODE  OR (CN2.INVOICEECODE  is null and CN1.INVOICEECODE  is null))
						and(CN2.CPAINVOICEENO =CN1.CPAINVOICEENO OR (CN2.CPAINVOICEENO is null and CN1.CPAINVOICEENO is null))
						and CN2.BILLPERCENTAGE=CN1.BILLPERCENTAGE)
			left join #TEMPCPASENDDEBTORS CN3
						on (CN3.CASEID=CPA.CASEID)
			Where T.DELETECANDIDATE=1
			and CN2.CASEID is null					-- indicates a mismatch
			and NOT (CN1.BILLPERCENTAGE=100 and CN3.CASEID is null)	-- exclude where debtor last reported as 100 percent and not reported in this batch
		)
	Delete T
	from #TEMPCPASEND T
	left join NamesCompare NC on (NC.CASEID=T.CASEID)
	where T.DELETECANDIDATE=1
	and NC.CASEID is null"
	
	Exec @ErrorCode=sp_executesql @sSQLString
	
	Select	@nDeletedCount=@@ROWCOUNT,
		@RowCount =@RowCount-@@RowCount	
End

--------------------------------------------
-- RFC70809
-- A site control was introduced to indicate
-- what property types are allowed to report
-- multiple debtors.  If the Case to be sent
-- to CPA is not one of the property types
-- listed in the SiteControl, then rows that
-- are marked for removal can be removed
-- irrespective of whether the debtors have
-- changed.
--------------------------------------------
If @ErrorCode=0
Begin
	
	Set @sSQLString="
	Select @sDebtorPropertyTypes=S.COLCHARACTER
	from SITECONTROL S
	where S.CONTROLID='CPA Multi Debtor File'"
	
	Exec @ErrorCode=sp_executesql @sSQLString,
				N'@sDebtorPropertyTypes	nvarchar(254)		output',
				  @sDebtorPropertyTypes=@sDebtorPropertyTypes	OUTPUT
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Delete T
	from #TEMPCPASEND T
	where T.DELETECANDIDATE=1"

	If @sDebtorPropertyTypes is not null
	Begin
		Set @sSQLString=@sSQLString+" and T.PROPERTYTYPE not in ("+@sDebtorPropertyTypes+")"
	End

	Exec @ErrorCode=sp_executesql @sSQLString
End

-----------------------------------------
-- Remove any rows in #TEMPCPASENDDEBTORS
-- where the parent Case has been removed
-- because no difference is detected.
-----------------------------------------
If @ErrorCode=0
and @nDeletedCount>0
Begin
	Set @sSQLString="
	Delete T
	from #TEMPCPASENDDEBTORS T
	left join #TEMPCPASEND CPA on (CPA.CASEID=T.CASEID)
	where CPA.CASEID is null"
	
	Exec @ErrorCode=sp_executesql @sSQLString
End
------------------------------------------------------------------------------------
-- Now remove any extracted cases where the information extracted matches
-- the last record received from CPA for this Case.  
-- The idea of this is to not send updates to CPA where they
-- already have matching information despite the fact that our last batch might
-- be different to what we are now trying to send.
--
-- As an additional refinement, only the columns where a difference was detected
-- against what was previously sent will be considered.

-- Note here that the CPASENDCOMPARE join allows for name records, but these would
-- be eliminated by the CPARECEIVE join because null CASECODEs are not considered.
-- However currently CPA do not return name records in CPARECEIVE. To be correct,
-- the join to the CPASENDCOMPARE, and the comparison between these three tables,
-- could be simplified to assume only case record comparison. Sleeping dogs.
------------------------------------------------------------------------------------
If @ErrorCode=0
begin
	set @sSQLString="
	delete #TEMPCPASEND
	from #TEMPCPASEND T
	join CPARECEIVE S	on (S.CASECODE=T.CASECODE
				and S.BATCHNO=(	select max(S1.BATCHNO)
						from CPARECEIVE S1
						where S1.CASECODE=T.CASECODE))
	-----------------------------------------------------------------
	-- RFC57212
	-- Do not delete Cases where multiple debtors are being reported.
	-- This is because we cannot determine what CPA are holding for 
	-- multiple debtors against what we are reporting.
	-----------------------------------------------------------------
	left join #TEMPCPASENDDEBTORS D
				on (D.CASEID=T.CASEID)
	left join CPASENDCOMPARE C
			on ((C.CASECODE=T.CASECODE 
			 OR (C.CASECODE is null and T.CASECODE is null and C.CLIENTCODE  =T.CLIENTCODE)
			 OR (C.CASECODE is null and T.CASECODE is null and C.DIVISIONCODE=T.DIVISIONCODE)
			 OR (C.CASECODE is null and T.CASECODE is null and C.INVOICEECODE=T.INVOICEECODE)))
	where D.CASEID is null
	and  (S.TRANSACTIONCODE=T.TRANSACTIONCODE    or (S.TRANSACTIONCODE=12 and T.TRANSACTIONCODE=21))
	and ((checksum(S.PROPERTYTYPE)      =checksum(T.PROPERTYTYPE)      and checksum(C.PROPERTYTYPE)      <>checksum(T.PROPERTYTYPE)		) OR checksum(C.PROPERTYTYPE)      =checksum(T.PROPERTYTYPE))
	and ((checksum(S.ALTOFFICECODE)     =checksum(T.ALTOFFICECODE)     and checksum(C.ALTOFFICECODE)     <>checksum(T.ALTOFFICECODE)	) OR checksum(C.ALTOFFICECODE)     =checksum(T.ALTOFFICECODE))
	and ((checksum(S.CLIENTSREFERENCE)  =checksum(T.CLIENTSREFERENCE)  and checksum(C.CLIENTSREFERENCE)  <>checksum(T.CLIENTSREFERENCE)	) OR checksum(C.CLIENTSREFERENCE)  =checksum(T.CLIENTSREFERENCE))
	and ((checksum(S.CPACOUNTRYCODE)    =checksum(T.CPACOUNTRYCODE)    and checksum(C.CPACOUNTRYCODE)    <>checksum(T.CPACOUNTRYCODE)	) OR checksum(C.CPACOUNTRYCODE)    =checksum(T.CPACOUNTRYCODE))
	and ((checksum(S.RENEWALTYPECODE)   =checksum(T.RENEWALTYPECODE)   and checksum(C.RENEWALTYPECODE)   <>checksum(T.RENEWALTYPECODE)	) OR checksum(C.RENEWALTYPECODE)   =checksum(T.RENEWALTYPECODE))
	and ((checksum(S.MARK        )      =checksum(T.MARK)              and checksum(C.MARK)              <>checksum(T.MARK)			) OR checksum(C.MARK)              =checksum(T.MARK))
	and ((checksum(S.ENTITYSIZE  )      =checksum(T.ENTITYSIZE)        and checksum(C.ENTITYSIZE  )      <>checksum(T.ENTITYSIZE)		) OR checksum(C.ENTITYSIZE  )      =checksum(T.ENTITYSIZE))
	and ((checksum(S.PRIORITYDATE)      =checksum(T.PRIORITYDATE)      and checksum(C.PRIORITYDATE)      <>checksum(T.PRIORITYDATE)		) OR checksum(C.PRIORITYDATE)      =checksum(T.PRIORITYDATE))
	and ((checksum(S.PARENTDATE  )      =checksum(T.PARENTDATE)        and checksum(C.PARENTDATE  )      <>checksum(T.PARENTDATE)		) OR checksum(C.PARENTDATE  )      =checksum(T.PARENTDATE))
	and ((checksum(S.NEXTTAXDATE )      =checksum(T.NEXTTAXDATE)       and checksum(C.NEXTTAXDATE )      <>checksum(T.NEXTTAXDATE)		) OR checksum(C.NEXTTAXDATE )      =checksum(T.NEXTTAXDATE))"

	set @sSQLString1="
	and ((checksum(S.NEXTDECOFUSEDATE)  =checksum(T.NEXTDECOFUSEDATE)  and checksum(C.NEXTDECOFUSEDATE)  <>checksum(T.NEXTDECOFUSEDATE)	) OR checksum(C.NEXTDECOFUSEDATE)  =checksum(T.NEXTDECOFUSEDATE))
	and ((checksum(S.PCTFILINGDATE)     =checksum(T.PCTFILINGDATE)     and checksum(C.PCTFILINGDATE)     <>checksum(T.PCTFILINGDATE)	) OR checksum(C.PCTFILINGDATE)     =checksum(T.PCTFILINGDATE))
	and ((checksum(S.ASSOCDESIGNDATE)   =checksum(T.ASSOCDESIGNDATE)   and checksum(C.ASSOCDESIGNDATE)   <>checksum(T.ASSOCDESIGNDATE)	) OR checksum(C.ASSOCDESIGNDATE)   =checksum(T.ASSOCDESIGNDATE))
	and ((checksum(S.NEXTAFFIDAVITDATE) =checksum(T.NEXTAFFIDAVITDATE) and checksum(C.NEXTAFFIDAVITDATE) <>checksum(T.NEXTAFFIDAVITDATE)	) OR checksum(C.NEXTAFFIDAVITDATE) =checksum(T.NEXTAFFIDAVITDATE))
	and ((checksum(S.APPLICATIONDATE)   =checksum(T.APPLICATIONDATE)   and checksum(C.APPLICATIONDATE)   <>checksum(T.APPLICATIONDATE)	) OR checksum(C.APPLICATIONDATE)   =checksum(T.APPLICATIONDATE))
	and ((checksum(S.ACCEPTANCEDATE)    =checksum(T.ACCEPTANCEDATE)    and checksum(C.ACCEPTANCEDATE)    <>checksum(T.ACCEPTANCEDATE)	) OR checksum(C.ACCEPTANCEDATE)    =checksum(T.ACCEPTANCEDATE))
	and ((checksum(S.PUBLICATIONDATE)   =checksum(T.PUBLICATIONDATE)   and checksum(C.PUBLICATIONDATE)   <>checksum(T.PUBLICATIONDATE)	) OR checksum(C.PUBLICATIONDATE)   =checksum(T.PUBLICATIONDATE))
	and ((checksum(S.REGISTRATIONDATE)  =checksum(T.REGISTRATIONDATE)  and checksum(C.REGISTRATIONDATE)  <>checksum(T.REGISTRATIONDATE)	) OR checksum(C.REGISTRATIONDATE)  =checksum(T.REGISTRATIONDATE))
	and ((checksum(S.NOMINALWORKINGDATE)=checksum(T.NOMINALWORKINGDATE)and checksum(C.NOMINALWORKINGDATE)<>checksum(T.NOMINALWORKINGDATE)	) OR checksum(C.NOMINALWORKINGDATE)=checksum(T.NOMINALWORKINGDATE))
	and ((checksum(S.EXPIRYDATE  )      =checksum(T.EXPIRYDATE)        and checksum(C.EXPIRYDATE  )      <>checksum(T.EXPIRYDATE)		) OR checksum(C.EXPIRYDATE  )      =checksum(T.EXPIRYDATE))
	and ((checksum(S.CPASTARTPAYDATE)   =checksum(T.CPASTARTPAYDATE)   and checksum(C.CPASTARTPAYDATE)   <>checksum(T.CPASTARTPAYDATE)	) OR checksum(C.CPASTARTPAYDATE)   =checksum(T.CPASTARTPAYDATE))
	and ((checksum(S.CPASTOPPAYDATE)    =checksum(T.CPASTOPPAYDATE)    and checksum(C.CPASTOPPAYDATE)    <>checksum(T.CPASTOPPAYDATE)	) OR checksum(C.CPASTOPPAYDATE)    =checksum(T.CPASTOPPAYDATE))
	and ((checksum(S.STOPPAYINGREASON)  =checksum(T.STOPPAYINGREASON)  and checksum(C.STOPPAYINGREASON)  <>checksum(T.STOPPAYINGREASON)	) OR checksum(C.STOPPAYINGREASON)  =checksum(T.STOPPAYINGREASON))"

	set @sSQLString2="
	and ((checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(S.PRIORITYNO,PATINDEX('%[^0]%',S.PRIORITYNO),LEN(S.PRIORITYNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PRIORITYNO,PATINDEX('%[^0]%',T.PRIORITYNO),LEN(T.PRIORITYNO))))
	and   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.PRIORITYNO,PATINDEX('%[^0]%',C.PRIORITYNO),LEN(C.PRIORITYNO))))<>checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PRIORITYNO,PATINDEX('%[^0]%',T.PRIORITYNO),LEN(T.PRIORITYNO)))))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.PRIORITYNO,PATINDEX('%[^0]%',C.PRIORITYNO),LEN(C.PRIORITYNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PRIORITYNO,PATINDEX('%[^0]%',T.PRIORITYNO),LEN(T.PRIORITYNO)))))
	and ((checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(S.PARENTNO,PATINDEX('%[^0]%',S.PARENTNO),LEN(S.PARENTNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PARENTNO,PATINDEX('%[^0]%',T.PARENTNO),LEN(T.PARENTNO))))
	and   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.PARENTNO,PATINDEX('%[^0]%',C.PARENTNO),LEN(C.PARENTNO))))<>checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PARENTNO,PATINDEX('%[^0]%',T.PARENTNO),LEN(T.PARENTNO)))))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.PARENTNO,PATINDEX('%[^0]%',C.PARENTNO),LEN(C.PARENTNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PARENTNO,PATINDEX('%[^0]%',T.PARENTNO),LEN(T.PARENTNO)))))
	and ((checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(S.PCTFILINGNO,PATINDEX('%[^0]%',S.PCTFILINGNO),LEN(S.PCTFILINGNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PCTFILINGNO,PATINDEX('%[^0]%',T.PCTFILINGNO),LEN(T.PCTFILINGNO))))
	and   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.PCTFILINGNO,PATINDEX('%[^0]%',C.PCTFILINGNO),LEN(C.PCTFILINGNO))))<>checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PCTFILINGNO,PATINDEX('%[^0]%',T.PCTFILINGNO),LEN(T.PCTFILINGNO)))))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.PCTFILINGNO,PATINDEX('%[^0]%',C.PCTFILINGNO),LEN(C.PCTFILINGNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PCTFILINGNO,PATINDEX('%[^0]%',T.PCTFILINGNO),LEN(T.PCTFILINGNO)))))
	and ((checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(S.ASSOCDESIGNNO,PATINDEX('%[^0]%',S.ASSOCDESIGNNO),LEN(S.ASSOCDESIGNNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.ASSOCDESIGNNO,PATINDEX('%[^0]%',T.ASSOCDESIGNNO),LEN(T.ASSOCDESIGNNO))))
	and   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.ASSOCDESIGNNO,PATINDEX('%[^0]%',C.ASSOCDESIGNNO),LEN(C.ASSOCDESIGNNO))))<>checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.ASSOCDESIGNNO,PATINDEX('%[^0]%',T.ASSOCDESIGNNO),LEN(T.ASSOCDESIGNNO)))))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.ASSOCDESIGNNO,PATINDEX('%[^0]%',C.ASSOCDESIGNNO),LEN(C.ASSOCDESIGNNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.ASSOCDESIGNNO,PATINDEX('%[^0]%',T.ASSOCDESIGNNO),LEN(T.ASSOCDESIGNNO)))))"


	set @sSQLString3="
	and ((checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(S.APPLICATIONNO,PATINDEX('%[^0]%',S.APPLICATIONNO),LEN(S.APPLICATIONNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.APPLICATIONNO,PATINDEX('%[^0]%',T.APPLICATIONNO),LEN(T.APPLICATIONNO))))
	and   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.APPLICATIONNO,PATINDEX('%[^0]%',C.APPLICATIONNO),LEN(C.APPLICATIONNO))))<>checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.APPLICATIONNO,PATINDEX('%[^0]%',T.APPLICATIONNO),LEN(T.APPLICATIONNO)))))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.APPLICATIONNO,PATINDEX('%[^0]%',C.APPLICATIONNO),LEN(C.APPLICATIONNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.APPLICATIONNO,PATINDEX('%[^0]%',T.APPLICATIONNO),LEN(T.APPLICATIONNO)))))
	and ((checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(S.ACCEPTANCENO,PATINDEX('%[^0]%',S.ACCEPTANCENO),LEN(S.ACCEPTANCENO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.ACCEPTANCENO,PATINDEX('%[^0]%',T.ACCEPTANCENO),LEN(T.ACCEPTANCENO))))
	and   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.ACCEPTANCENO,PATINDEX('%[^0]%',C.ACCEPTANCENO),LEN(C.ACCEPTANCENO))))<>checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.ACCEPTANCENO,PATINDEX('%[^0]%',T.ACCEPTANCENO),LEN(T.ACCEPTANCENO)))))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.ACCEPTANCENO,PATINDEX('%[^0]%',C.ACCEPTANCENO),LEN(C.ACCEPTANCENO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.ACCEPTANCENO,PATINDEX('%[^0]%',T.ACCEPTANCENO),LEN(T.ACCEPTANCENO)))))
	and ((checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(S.PUBLICATIONNO,PATINDEX('%[^0]%',S.PUBLICATIONNO),LEN(S.PUBLICATIONNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PUBLICATIONNO,PATINDEX('%[^0]%',T.PUBLICATIONNO),LEN(T.PUBLICATIONNO))))
	and   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.PUBLICATIONNO,PATINDEX('%[^0]%',C.PUBLICATIONNO),LEN(C.PUBLICATIONNO))))<>checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PUBLICATIONNO,PATINDEX('%[^0]%',T.PUBLICATIONNO),LEN(T.PUBLICATIONNO)))))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.PUBLICATIONNO,PATINDEX('%[^0]%',C.PUBLICATIONNO),LEN(C.PUBLICATIONNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.PUBLICATIONNO,PATINDEX('%[^0]%',T.PUBLICATIONNO),LEN(T.PUBLICATIONNO)))))
	and ((checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(S.REGISTRATIONNO,PATINDEX('%[^0]%',S.REGISTRATIONNO),LEN(S.REGISTRATIONNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.REGISTRATIONNO,PATINDEX('%[^0]%',T.REGISTRATIONNO),LEN(T.REGISTRATIONNO))))
	and   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.REGISTRATIONNO,PATINDEX('%[^0]%',C.REGISTRATIONNO),LEN(C.REGISTRATIONNO))))<>checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.REGISTRATIONNO,PATINDEX('%[^0]%',T.REGISTRATIONNO),LEN(T.REGISTRATIONNO)))))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(C.REGISTRATIONNO,PATINDEX('%[^0]%',C.REGISTRATIONNO),LEN(C.REGISTRATIONNO)))) =checksum(dbo.fn_RemoveNoiseCharacters(SUBSTRING(T.REGISTRATIONNO,PATINDEX('%[^0]%',T.REGISTRATIONNO),LEN(T.REGISTRATIONNO)))))"

	set @sSQLString4="
	and ((checksum(S.INTLCLASSES )      =checksum(T.INTLCLASSES)       and checksum(C.INTLCLASSES )      <>checksum(T.INTLCLASSES)		) OR checksum(C.INTLCLASSES )      =checksum(T.INTLCLASSES))
	and ((checksum(S.LOCALCLASSES)      =checksum(T.LOCALCLASSES)      and checksum(C.LOCALCLASSES)      <>checksum(T.LOCALCLASSES)		) OR checksum(C.LOCALCLASSES)      =checksum(T.LOCALCLASSES))
	and ((checksum(S.NUMBEROFYEARS)     =checksum(T.NUMBEROFYEARS)     and checksum(C.NUMBEROFYEARS)     <>checksum(T.NUMBEROFYEARS)	) OR checksum(C.NUMBEROFYEARS)     =checksum(T.NUMBEROFYEARS))
	and ((checksum(S.NUMBEROFCLAIMS)    =checksum(T.NUMBEROFCLAIMS)    and checksum(C.NUMBEROFCLAIMS)    <>checksum(T.NUMBEROFCLAIMS)	) OR checksum(C.NUMBEROFCLAIMS)    =checksum(T.NUMBEROFCLAIMS))
	and ((checksum(S.NUMBEROFDESIGNS)   =checksum(T.NUMBEROFDESIGNS)   and checksum(C.NUMBEROFDESIGNS)   <>checksum(T.NUMBEROFDESIGNS)	) OR checksum(C.NUMBEROFDESIGNS)   =checksum(T.NUMBEROFDESIGNS))
	and ((checksum(S.NUMBEROFCLASSES)   =checksum(T.NUMBEROFCLASSES)   and checksum(C.NUMBEROFCLASSES)   <>checksum(T.NUMBEROFCLASSES)	) OR checksum(C.NUMBEROFCLASSES)   =checksum(T.NUMBEROFCLASSES))
	and ((checksum(S.NUMBEROFSTATES)    =checksum(T.NUMBEROFSTATES)    and checksum(C.NUMBEROFSTATES)    <>checksum(T.NUMBEROFSTATES)	) OR checksum(C.NUMBEROFSTATES)    =checksum(T.NUMBEROFSTATES))
	and ((checksum(S.DESIGNATEDSTATES)  =checksum(T.DESIGNATEDSTATES)  and checksum(C.DESIGNATEDSTATES)  <>checksum(T.DESIGNATEDSTATES)	) OR checksum(C.DESIGNATEDSTATES)  =checksum(T.DESIGNATEDSTATES))
	and ((checksum(dbo.fn_RemoveNoiseCharacters(S.OWNERNAME)   ) =checksum(dbo.fn_RemoveNoiseCharacters(T.OWNERNAME))
	and   checksum(dbo.fn_RemoveNoiseCharacters(C.OWNERNAME)   )<>checksum(dbo.fn_RemoveNoiseCharacters(T.OWNERNAME))   )
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(C.OWNERNAME)   ) =checksum(dbo.fn_RemoveNoiseCharacters(T.OWNERNAME))   )
	and ((checksum(dbo.fn_RemoveNoiseCharacters(S.CLIENTNAME)  ) =checksum(dbo.fn_RemoveNoiseCharacters(T.CLIENTNAME))
	and   checksum(dbo.fn_RemoveNoiseCharacters(C.CLIENTNAME)  )<>checksum(dbo.fn_RemoveNoiseCharacters(T.CLIENTNAME))  )
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(C.CLIENTNAME)  ) =checksum(dbo.fn_RemoveNoiseCharacters(T.CLIENTNAME))  )
	and ((checksum(dbo.fn_RemoveNoiseCharacters(S.DIVISIONNAME)) =checksum(dbo.fn_RemoveNoiseCharacters(T.DIVISIONNAME))
	and   checksum(dbo.fn_RemoveNoiseCharacters(C.DIVISIONNAME))<>checksum(dbo.fn_RemoveNoiseCharacters(T.DIVISIONNAME)))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(C.DIVISIONNAME)) =checksum(dbo.fn_RemoveNoiseCharacters(T.DIVISIONNAME)))"

	set @sSQLString5="
	and ((checksum(dbo.fn_RemoveNoiseCharacters(S.FOREIGNAGENTNAME)) =checksum(dbo.fn_RemoveNoiseCharacters(T.FOREIGNAGENTNAME))
	and   checksum(dbo.fn_RemoveNoiseCharacters(C.FOREIGNAGENTNAME))<>checksum(dbo.fn_RemoveNoiseCharacters(T.FOREIGNAGENTNAME)))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(C.FOREIGNAGENTNAME)) =checksum(dbo.fn_RemoveNoiseCharacters(T.FOREIGNAGENTNAME)))
	and ((checksum(dbo.fn_RemoveNoiseCharacters(S.INVOICEENAME)    ) =checksum(dbo.fn_RemoveNoiseCharacters(T.INVOICEENAME))
	and   checksum(dbo.fn_RemoveNoiseCharacters(C.INVOICEENAME)    )<>checksum(dbo.fn_RemoveNoiseCharacters(T.INVOICEENAME)))
	 OR   checksum(dbo.fn_RemoveNoiseCharacters(C.INVOICEENAME)    ) =checksum(dbo.fn_RemoveNoiseCharacters(T.INVOICEENAME)))
	and ((checksum(S.OWNERNAMECODE)=checksum(T.OWNERNAMECODE)                                     and checksum(C.OWNERNAMECODE)<>checksum(T.OWNERNAMECODE)						) OR checksum(C.OWNERNAMECODE)=checksum(T.OWNERNAMECODE))
	and ((checksum(replace(S.OWNADDRESSLINE1,' ',''))=checksum(replace(T.OWNADDRESSLINE1,' ','')) and checksum(replace(C.OWNADDRESSLINE1,' ',''))<>checksum(replace(T.OWNADDRESSLINE1,' ',''))	) OR checksum(replace(C.OWNADDRESSLINE1,' ',''))=checksum(replace(T.OWNADDRESSLINE1,' ','')))
	and ((checksum(replace(S.OWNADDRESSLINE2,' ',''))=checksum(replace(T.OWNADDRESSLINE2,' ','')) and checksum(replace(C.OWNADDRESSLINE2,' ',''))<>checksum(replace(T.OWNADDRESSLINE2,' ',''))	) OR checksum(replace(C.OWNADDRESSLINE2,' ',''))=checksum(replace(T.OWNADDRESSLINE2,' ','')))
	and ((checksum(replace(S.OWNADDRESSLINE3,' ',''))=checksum(replace(T.OWNADDRESSLINE3,' ','')) and checksum(replace(C.OWNADDRESSLINE3,' ',''))<>checksum(replace(T.OWNADDRESSLINE3,' ',''))	) OR checksum(replace(C.OWNADDRESSLINE3,' ',''))=checksum(replace(T.OWNADDRESSLINE3,' ','')))
	and ((checksum(replace(S.OWNADDRESSLINE4,' ',''))=checksum(replace(T.OWNADDRESSLINE4,' ','')) and checksum(replace(C.OWNADDRESSLINE4,' ',''))<>checksum(replace(T.OWNADDRESSLINE4,' ',''))	) OR checksum(replace(C.OWNADDRESSLINE4,' ',''))=checksum(replace(T.OWNADDRESSLINE4,' ','')))
	and ((checksum(S.OWNADDRESSCOUNTRY) =checksum(T.OWNADDRESSCOUNTRY)  and checksum(C.OWNADDRESSCOUNTRY) <>checksum(T.OWNADDRESSCOUNTRY)	) OR checksum(C.OWNADDRESSCOUNTRY) =checksum(T.OWNADDRESSCOUNTRY))
	and ((checksum(S.OWNADDRESSPOSTCODE)=checksum(T.OWNADDRESSPOSTCODE) and checksum(C.OWNADDRESSPOSTCODE)<>checksum(T.OWNADDRESSPOSTCODE)	) OR checksum(C.OWNADDRESSPOSTCODE)=checksum(T.OWNADDRESSPOSTCODE))
	and ((checksum(S.CLIENTCODE  )      =checksum(T.CLIENTCODE)         and checksum(C.CLIENTCODE  )      <>checksum(T.CLIENTCODE)		) OR checksum(C.CLIENTCODE  )      =checksum(T.CLIENTCODE))
	and ((checksum(S.CPACLIENTNO )      =checksum(T.CPACLIENTNO)        and checksum(C.CPACLIENTNO )      <>checksum(T.CPACLIENTNO)		) OR checksum(C.CPACLIENTNO )      =checksum(T.CPACLIENTNO))"

	set @sSQLString6="
	and ((checksum(S.DIVISIONCODE)      =checksum(T.DIVISIONCODE)       and checksum(C.DIVISIONCODE)      <>checksum(T.DIVISIONCODE)	) OR checksum(C.DIVISIONCODE)      =checksum(T.DIVISIONCODE))
	and ((checksum(S.FOREIGNAGENTCODE)  =checksum(T.FOREIGNAGENTCODE)   and checksum(C.FOREIGNAGENTCODE)  <>checksum(T.FOREIGNAGENTCODE)	) OR checksum(C.FOREIGNAGENTCODE)  =checksum(T.FOREIGNAGENTCODE))
	and ((checksum(S.INVOICEECODE)      =checksum(T.INVOICEECODE)       and checksum(C.INVOICEECODE)      <>checksum(T.INVOICEECODE)	) OR checksum(C.INVOICEECODE)      =checksum(T.INVOICEECODE))
	and ((checksum(S.CPAINVOICEENO)     =checksum(T.CPAINVOICEENO)      and checksum(C.CPAINVOICEENO)     <>checksum(T.CPAINVOICEENO)	) OR checksum(C.CPAINVOICEENO)     =checksum(T.CPAINVOICEENO))"

	set @sSQLString7="
	and	(checksum(C.CLIENTATTENTION )      =checksum(T.CLIENTATTENTION)        OR T.TRANSACTIONCODE<>04)
	and	(checksum(replace(replace(C.CLTADDRESSLINE1,  ' ',''),',',''))=checksum(replace(replace(T.CLTADDRESSLINE1,  ' ',''),',','')) OR T.TRANSACTIONCODE<>04)
	and	(checksum(replace(replace(C.CLTADDRESSLINE2,  ' ',''),',',''))=checksum(replace(replace(T.CLTADDRESSLINE2,  ' ',''),',','')) OR T.TRANSACTIONCODE<>04)
	and	(checksum(replace(replace(C.CLTADDRESSLINE3,  ' ',''),',',''))=checksum(replace(replace(T.CLTADDRESSLINE3,  ' ',''),',','')) OR T.TRANSACTIONCODE<>04)
	and	(checksum(replace(replace(C.CLTADDRESSLINE4,  ' ',''),',',''))=checksum(replace(replace(T.CLTADDRESSLINE4,  ' ',''),',','')) OR T.TRANSACTIONCODE<>04)
	and	(checksum(C.CLTADDRESSCOUNTRY) =checksum(T.CLTADDRESSCOUNTRY)  OR T.TRANSACTIONCODE<>04)
	and	(checksum(C.CLTADDRESSPOSTCODE)=checksum(T.CLTADDRESSPOSTCODE) OR T.TRANSACTIONCODE<>04)
	and	(checksum(C.CLIENTTELEPHONE)   =checksum(T.CLIENTTELEPHONE)    OR T.TRANSACTIONCODE<>04)
	and	(checksum(C.CLIENTFAX   )      =checksum(T.CLIENTFAX)          OR T.TRANSACTIONCODE<>04)
	and	(checksum(C.CLIENTEMAIL )      =checksum(T.CLIENTEMAIL)        OR T.TRANSACTIONCODE<>04)
	and	(checksum(C.DIVISIONATTENTION) =checksum(T.DIVISIONATTENTION ) OR T.TRANSACTIONCODE<>05)
	and	(checksum(replace(replace(C.DIVADDRESSLINE1,  ' ',''),',',''))=checksum(replace(replace(T.DIVADDRESSLINE1,  ' ',''),',','')) OR T.TRANSACTIONCODE<>05)
	and	(checksum(replace(replace(C.DIVADDRESSLINE2,  ' ',''),',',''))=checksum(replace(replace(T.DIVADDRESSLINE2,  ' ',''),',','')) OR T.TRANSACTIONCODE<>05)
	and	(checksum(replace(replace(C.DIVADDRESSLINE3,  ' ',''),',',''))=checksum(replace(replace(T.DIVADDRESSLINE3,  ' ',''),',','')) OR T.TRANSACTIONCODE<>05)
	and	(checksum(replace(replace(C.DIVADDRESSLINE4,  ' ',''),',',''))=checksum(replace(replace(T.DIVADDRESSLINE4,  ' ',''),',','')) OR T.TRANSACTIONCODE<>05)
	and	(checksum(C.DIVADDRESSCOUNTRY) =checksum(T.DIVADDRESSCOUNTRY ) OR T.TRANSACTIONCODE<>05)
	and	(checksum(C.DIVADDRESSPOSTCODE)=checksum(T.DIVADDRESSPOSTCODE) OR T.TRANSACTIONCODE<>05)"

	set @sSQLString8="
		and	(checksum(C.INVOICEEATTENTION ) =checksum(T.INVOICEEATTENTION) OR T.TRANSACTIONCODE<>06)
	and	(checksum(replace(replace(C.INVADDRESSLINE1,  ' ',''),',',''))=checksum(replace(replace(T.INVADDRESSLINE1,  ' ',''),',','')) OR T.TRANSACTIONCODE<>06)
	and	(checksum(replace(replace(C.INVADDRESSLINE2,  ' ',''),',',''))=checksum(replace(replace(T.INVADDRESSLINE2,  ' ',''),',','')) OR T.TRANSACTIONCODE<>06)
	and	(checksum(replace(replace(C.INVADDRESSLINE3,  ' ',''),',',''))=checksum(replace(replace(T.INVADDRESSLINE3,  ' ',''),',','')) OR T.TRANSACTIONCODE<>06)
	and	(checksum(replace(replace(C.INVADDRESSLINE4,  ' ',''),',',''))=checksum(replace(replace(T.INVADDRESSLINE4,  ' ',''),',','')) OR T.TRANSACTIONCODE<>06)
	and	(checksum(C.INVADDRESSCOUNTRY) =checksum(T.INVADDRESSCOUNTRY)  OR T.TRANSACTIONCODE<>06)
	and	(checksum(C.INVADDRESSPOSTCODE)=checksum(T.INVADDRESSPOSTCODE) OR T.TRANSACTIONCODE<>06)
	and	(checksum(C.INVOICEETELEPHONE) =checksum(T.INVOICEETELEPHONE)  OR T.TRANSACTIONCODE<>06)
	and	(checksum(C.INVOICEEFAX )      =checksum(T.INVOICEEFAX)        OR T.TRANSACTIONCODE<>06)
	and	(checksum(C.INVOICEEEMAIL)      =checksum(T.INVOICEEEMAIL)     OR T.TRANSACTIONCODE<>06)"

	Exec (@sSQLString+@sSQLString1+@sSQLString2+@sSQLString3+@sSQLString4+@sSQLString5+@sSQLString6+@sSQLString7+@sSQLString8)

	Select 	@ErrorCode=@@Error,
		@RowCount =@RowCount-@@RowCount	
end
-- If the Case being reported to CPA currently has the Event indicating it was rejected in the last batch
-- then report the Narrative either held in the CaseEvent row for the Reject Event or go to the CPASEND row 
-- for the last batch this case was reported in and extract the NARRATIVE and send it to CPA.  
-- The NARRATIVE will explain to CPA the reason why the record was rejected in the last batch.

If @ErrorCode=0
and @nCPARejectedEventNo is not null
begin
	Set @sSQLString="
	update #TEMPCPASEND
	set NARRATIVE=isnull(substring(CE.EVENTTEXT,1,50), S.NARRATIVE)
	from #TEMPCPASEND T
	join CASEEVENT CE on (CE.CASEID=T.CASEID
			  and CE.EVENTNO=@nCPARejectedEventNo
			  and CE.OCCURREDFLAG=1)
	join (	select max(BATCHNO) as BATCHNO, CASEID
		from CPARECEIVE
		group by CASEID) R on (R.CASEID=T.CASEID)
	join CPASEND S	on (S.BATCHNO=R.BATCHNO
			and S.CASEID =T.CASEID)
	where T.NARRATIVE is null
	and  isnull(CE.EVENTTEXT, S.NARRATIVE) is not null"

	exec @ErrorCode=sp_executesql @sSQLString,
				N'@nCPARejectedEventNo	int',
				  @nCPARejectedEventNo
end
--14334 AvdA @pnTestMode = 1 (this is Preview mode)
If @pnTestMode=1
and @ErrorCode=0
begin
	-- Hard code the batchno to 0
	Select @nBatchNo = 0
	-- Select prepared batch information as result set.
	If  @ErrorCode=0
	begin
		Set @sSQLString="
		select distinct	SYSTEMID,
				@nBatchNo as BATCHNO,
				getdate() as BATCHDATE,
				PROPERTYTYPE,
				CASECODE,
				TRANSACTIONCODE,
				ALTOFFICECODE,
				CASEID,
				FILENUMBER,
				CLIENTSREFERENCE,
				CPACOUNTRYCODE,
				RENEWALTYPECODE,
				MARK,
				ENTITYSIZE,
				PRIORITYDATE,
				PARENTDATE,
				NEXTTAXDATE,
				NEXTDECOFUSEDATE,
				PCTFILINGDATE,
				ASSOCDESIGNDATE,
				NEXTAFFIDAVITDATE,
				APPLICATIONDATE,
				ACCEPTANCEDATE,
				PUBLICATIONDATE,
				REGISTRATIONDATE,
				RENEWALDATE,
				NOMINALWORKINGDATE,
				EXPIRYDATE,
				CPASTARTPAYDATE,
				CPASTOPPAYDATE,
				STOPPAYINGREASON,
				PRIORITYNO,
				PARENTNO,
				PCTFILINGNO,
				ASSOCDESIGNNO,
				APPLICATIONNO,
				ACCEPTANCENO,
				PUBLICATIONNO,
				REGISTRATIONNO,
				INTLCLASSES,
				LOCALCLASSES,
				NUMBEROFYEARS,
				NUMBEROFCLAIMS,
				NUMBEROFDESIGNS,
				NUMBEROFCLASSES,
				NUMBEROFSTATES,
				DESIGNATEDSTATES,
				OWNERNAME,
				OWNERNAMECODE,
				OWNADDRESSLINE1,
				OWNADDRESSLINE2,
				OWNADDRESSLINE3,
				OWNADDRESSLINE4,
				OWNADDRESSCOUNTRY,
				OWNADDRESSPOSTCODE,
				CLIENTCODE,
				CPACLIENTNO,
				CLIENTNAME,
				CLIENTATTENTION	,
				CLTADDRESSLINE1	,
				CLTADDRESSLINE2	,
				CLTADDRESSLINE3	,
				CLTADDRESSLINE4,
				CLTADDRESSCOUNTRY,
				CLTADDRESSPOSTCODE,
				CLIENTTELEPHONE,
				CLIENTFAX,
				CLIENTEMAIL,
				DIVISIONCODE,
				DIVISIONNAME,
				DIVISIONATTENTION,
				DIVADDRESSLINE1	,
				DIVADDRESSLINE2	,
				DIVADDRESSLINE3	,
				DIVADDRESSLINE4	,
				DIVADDRESSCOUNTRY,
				DIVADDRESSPOSTCODE,
				FOREIGNAGENTCODE,
				FOREIGNAGENTNAME,
				ATTORNEYCODE,
				ATTORNEYNAME,
				INVOICEECODE,
				CPAINVOICEENO,
				INVOICEENAME,
				INVOICEEATTENTION,
				INVADDRESSLINE1	,
				INVADDRESSLINE2	,
				INVADDRESSLINE3	,
				INVADDRESSLINE4	,
				INVADDRESSCOUNTRY,
				INVADDRESSPOSTCODE,
				INVOICEETELEPHONE,
				INVOICEEFAX,
				INVOICEEEMAIL,
				NARRATIVE,
				IPRURN
			from #TEMPCPASEND"
	
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nBatchNo	int',
						  @nBatchNo
	end
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		select	CSD.*
		from #TEMPCPASEND T
		join #TEMPCPASENDDEBTORS CSD
				 on (CSD.CASEID=T.CASEID)
		order by CSD.CASEID, CSD.BILLPERCENTAGE desc"

		exec @ErrorCode=sp_executesql @sSQLString
	End
end
Else If @ErrorCode=0
-- 14334 AvdA Testmode = 0 (this is Live mode)
begin
	-- For each Case being reported to CPA a Policing row is to be inserted.  Initially
	-- write to a temporary table to allocate a unique sequence number.
	-- Do not insert a row if the Case is flagged as a Stop Pay
	If  @ErrorCode=0
	and @pnPoliceEvents=1
	and @nCPASentEventNo is not null
	begin
		Set @sSQLString="
		insert into #TEMPPOLICING(CASEID)
		select CASEID
		from #TEMPCPASEND
		where CASEID is not null"
	
		exec @ErrorCode=sp_executesql @sSQLString
	End
	
	-- Increase the transaction isolation level before performing the database updates
	
	set transaction isolation level read committed
	
	-- Get the Batch Number to use only if there are actual rows to send to CPA.
	-- Keep the transaction as short as possible to avoid causing system blocks 
	-- on this widely used table.

	If  @ErrorCode=0
	and exists(select 1 from #TEMPCPASEND)
	Begin
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		select @sSQLString="
		Update LASTINTERNALCODE
		set INTERNALSEQUENCE=INTERNALSEQUENCE+1,
		@nBatchNoOUT=isnull(INTERNALSEQUENCE,0) + 1
		from LASTINTERNALCODE 
		where TABLENAME='CPASEND'"
	
		Exec @ErrorCode=sp_executesql @sSQLString, 
						N'@nBatchNoOUT		int OUTPUT',
						  @nBatchNoOUT=@nBatchNo OUTPUT
	
	
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
	
	If  @ErrorCode=0
	begin
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION
	
		Set @sSQLString="
		insert into CPASEND (
				SYSTEMID,
				BATCHNO,
				BATCHDATE,
				PROPERTYTYPE,
				CASECODE,
				TRANSACTIONCODE,
				ALTOFFICECODE,
				CASEID,
				FILENUMBER,
				CLIENTSREFERENCE,
				CPACOUNTRYCODE,
				RENEWALTYPECODE,
				MARK,
				ENTITYSIZE,
				PRIORITYDATE,
				PARENTDATE,
				NEXTTAXDATE,
				NEXTDECOFUSEDATE,
				PCTFILINGDATE,
				ASSOCDESIGNDATE,
				NEXTAFFIDAVITDATE,
				APPLICATIONDATE,
				ACCEPTANCEDATE,
				PUBLICATIONDATE,
				REGISTRATIONDATE,
				RENEWALDATE,
				NOMINALWORKINGDATE,
				EXPIRYDATE,
				CPASTARTPAYDATE,
				CPASTOPPAYDATE,
				STOPPAYINGREASON,
				PRIORITYNO,
				PARENTNO,
				PCTFILINGNO,
				ASSOCDESIGNNO,
				APPLICATIONNO,
				ACCEPTANCENO,
				PUBLICATIONNO,
				REGISTRATIONNO,
				INTLCLASSES,
				LOCALCLASSES,
				NUMBEROFYEARS,
				NUMBEROFCLAIMS,
				NUMBEROFDESIGNS,
				NUMBEROFCLASSES,
				NUMBEROFSTATES,
				DESIGNATEDSTATES,
				OWNERNAME,
				OWNERNAMECODE,
				OWNADDRESSLINE1,
				OWNADDRESSLINE2,
				OWNADDRESSLINE3,
				OWNADDRESSLINE4,
				OWNADDRESSCOUNTRY,
				OWNADDRESSPOSTCODE,
				CLIENTCODE,
				CPACLIENTNO,
				CLIENTNAME,
				CLIENTATTENTION	,
				CLTADDRESSLINE1	,
				CLTADDRESSLINE2	,
				CLTADDRESSLINE3	,
				CLTADDRESSLINE4,
				CLTADDRESSCOUNTRY,
				CLTADDRESSPOSTCODE,
				CLIENTTELEPHONE,
				CLIENTFAX,
				CLIENTEMAIL,
				DIVISIONCODE,
				DIVISIONNAME,
				DIVISIONATTENTION,
				DIVADDRESSLINE1	,
				DIVADDRESSLINE2	,
				DIVADDRESSLINE3	,
				DIVADDRESSLINE4	,
				DIVADDRESSCOUNTRY,
				DIVADDRESSPOSTCODE,
				FOREIGNAGENTCODE,
				FOREIGNAGENTNAME,
				ATTORNEYCODE,
				ATTORNEYNAME,
				INVOICEECODE,
				CPAINVOICEENO,
				INVOICEENAME,
				INVOICEEATTENTION,
				INVADDRESSLINE1	,
				INVADDRESSLINE2	,
				INVADDRESSLINE3	,
				INVADDRESSLINE4	,
				INVADDRESSCOUNTRY,
				INVADDRESSPOSTCODE,
				INVOICEETELEPHONE,
				INVOICEEFAX,
				INVOICEEEMAIL,
				NARRATIVE,
				IPRURN)
		select distinct	SYSTEMID,
				@nBatchNo,
				getdate(),
				PROPERTYTYPE,
				CASECODE,
				TRANSACTIONCODE,
				ALTOFFICECODE,
				CASEID,
				FILENUMBER,
				CLIENTSREFERENCE,
				CPACOUNTRYCODE,
				RENEWALTYPECODE,
				MARK,
				ENTITYSIZE,
				PRIORITYDATE,
				PARENTDATE,
				NEXTTAXDATE,
				NEXTDECOFUSEDATE,
				PCTFILINGDATE,
				ASSOCDESIGNDATE,
				NEXTAFFIDAVITDATE,
				APPLICATIONDATE,
				ACCEPTANCEDATE,
				PUBLICATIONDATE,
				REGISTRATIONDATE,
				RENEWALDATE,
				NOMINALWORKINGDATE,
				EXPIRYDATE,
				CPASTARTPAYDATE,
				CPASTOPPAYDATE,
				STOPPAYINGREASON,
				PRIORITYNO,
				PARENTNO,
				PCTFILINGNO,
				ASSOCDESIGNNO,
				APPLICATIONNO,
				ACCEPTANCENO,
				PUBLICATIONNO,
				REGISTRATIONNO,
				INTLCLASSES,
				LOCALCLASSES,
				NUMBEROFYEARS,
				NUMBEROFCLAIMS,
				NUMBEROFDESIGNS,
				NUMBEROFCLASSES,
				NUMBEROFSTATES,
				DESIGNATEDSTATES,
				OWNERNAME,
				OWNERNAMECODE,
				OWNADDRESSLINE1,
				OWNADDRESSLINE2,
				OWNADDRESSLINE3,
				OWNADDRESSLINE4,
				OWNADDRESSCOUNTRY,
				OWNADDRESSPOSTCODE,
				CLIENTCODE,
				CPACLIENTNO,
				CLIENTNAME,
				CLIENTATTENTION	,
				CLTADDRESSLINE1	,
				CLTADDRESSLINE2	,
				CLTADDRESSLINE3	,
				CLTADDRESSLINE4,
				CLTADDRESSCOUNTRY,
				CLTADDRESSPOSTCODE,
				CLIENTTELEPHONE,
				CLIENTFAX,
				CLIENTEMAIL,
				DIVISIONCODE,
				DIVISIONNAME,
				DIVISIONATTENTION,
				DIVADDRESSLINE1	,
				DIVADDRESSLINE2	,
				DIVADDRESSLINE3	,
				DIVADDRESSLINE4	,
				DIVADDRESSCOUNTRY,
				DIVADDRESSPOSTCODE,
				FOREIGNAGENTCODE,
				FOREIGNAGENTNAME,
				ATTORNEYCODE,
				ATTORNEYNAME,
				INVOICEECODE,
				CPAINVOICEENO,
				INVOICEENAME,
				INVOICEEATTENTION,
				INVADDRESSLINE1	,
				INVADDRESSLINE2	,
				INVADDRESSLINE3	,
				INVADDRESSLINE4	,
				INVADDRESSCOUNTRY,
				INVADDRESSPOSTCODE,
				INVOICEETELEPHONE,
				INVOICEEFAX,
				INVOICEEEMAIL,
				NARRATIVE,
				IPRURN
			from #TEMPCPASEND"
	
		Exec @ErrorCode=sp_executesql @sSQLString,
						N'@nBatchNo	int',
						  @nBatchNo		
			  
		-- RFC57212
		-- Now insert rows into CPASENDDEBTORS
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			insert into CPASENDDEBTORS (
				CPASENDROWID,
				NAMETYPE,
				INVOICEECODE,
				CPAINVOICEENO,
				BILLPERCENTAGE 
				)
			select	CPA.ROWID,
				coalesce(T.INVOICEENAMETYPE, CN.NAMETYPE, 'Z'),
				CSD.INVOICEECODE,
				CSD.CPAINVOICEENO,
				CSD.BILLPERCENTAGE
			from #TEMPCPASEND T
			join CPASEND CPA on (CPA.SYSTEMID=T.SYSTEMID
					 and CPA.BATCHNO =@nBatchNo
					 and CPA.CASEID  =T.CASEID)
			join #TEMPCPASENDDEBTORS CSD
					 on (CSD.CASEID=T.CASEID)
			left join (select CASEID, max(NAMETYPE) as NAMETYPE
				   from CASENAME
				   where NAMETYPE in ('D','Z')
				   and EXPIRYDATE is null
				   group by CASEID) CN on (CN.CASEID=T.CASEID)
			order by CPA.ROWID, CSD.BILLPERCENTAGE desc"

			exec @ErrorCode=sp_executesql @sSQLString,
						N'@nBatchNo	int',
						  @nBatchNo
		End
	
		-- Now load the CPASENDCOMPARE table
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			insert into CPASENDCOMPARE (
				SYSTEMID,
				BATCHNO,
				BATCHDATE,
				PROPERTYTYPE,
				CASECODE,
				TRANSACTIONCODE,
				ALTOFFICECODE,
				CASEID,
				FILENUMBER,
				CLIENTSREFERENCE,
				CPACOUNTRYCODE,
				RENEWALTYPECODE,
				MARK,
				ENTITYSIZE,
				PRIORITYDATE,
				PARENTDATE,
				NEXTTAXDATE,
				NEXTDECOFUSEDATE,
				PCTFILINGDATE,
				ASSOCDESIGNDATE,
				NEXTAFFIDAVITDATE,
				APPLICATIONDATE,
				ACCEPTANCEDATE,
				PUBLICATIONDATE,
				REGISTRATIONDATE,
				RENEWALDATE,
				NOMINALWORKINGDATE,
				EXPIRYDATE,
				CPASTARTPAYDATE,
				CPASTOPPAYDATE,
				STOPPAYINGREASON,
				PRIORITYNO,
				PARENTNO,
				PCTFILINGNO,
				ASSOCDESIGNNO,
				APPLICATIONNO,
				ACCEPTANCENO,
				PUBLICATIONNO,
				REGISTRATIONNO,
				INTLCLASSES,
				LOCALCLASSES,
				NUMBEROFYEARS,
				NUMBEROFCLAIMS,
				NUMBEROFDESIGNS,
				NUMBEROFCLASSES,
				NUMBEROFSTATES,
				DESIGNATEDSTATES,
				OWNERNAME,
				OWNERNAMECODE,
				OWNADDRESSLINE1,
				OWNADDRESSLINE2,
				OWNADDRESSLINE3,
				OWNADDRESSLINE4,
				OWNADDRESSCOUNTRY,
				OWNADDRESSPOSTCODE,
				CLIENTCODE,
				CPACLIENTNO,
				CLIENTNAME,
				CLIENTATTENTION	,
				CLTADDRESSLINE1	,
				CLTADDRESSLINE2	,
				CLTADDRESSLINE3	,
				CLTADDRESSLINE4,
				CLTADDRESSCOUNTRY,
				CLTADDRESSPOSTCODE,
				CLIENTTELEPHONE,
				CLIENTFAX,
				CLIENTEMAIL,
				DIVISIONCODE,
				DIVISIONNAME,
				DIVISIONATTENTION,
				DIVADDRESSLINE1	,
				DIVADDRESSLINE2	,
				DIVADDRESSLINE3	,
				DIVADDRESSLINE4	,
				DIVADDRESSCOUNTRY,
				DIVADDRESSPOSTCODE,
				FOREIGNAGENTCODE,
				FOREIGNAGENTNAME,
				ATTORNEYCODE,
				ATTORNEYNAME,
				INVOICEECODE,
				CPAINVOICEENO,
				INVOICEENAME,
				INVOICEEATTENTION,
				INVADDRESSLINE1	,
				INVADDRESSLINE2	,
				INVADDRESSLINE3	,
				INVADDRESSLINE4	,
				INVADDRESSCOUNTRY,
				INVADDRESSPOSTCODE,
				INVOICEETELEPHONE,
				INVOICEEFAX,
				INVOICEEEMAIL,
				NARRATIVE,
				IPRURN)
		select distinct	SYSTEMID,
				@nBatchNo,
				getdate(),
				PROPERTYTYPE,
				CASECODE,
				TRANSACTIONCODE,
				ALTOFFICECODE,
				CASEID,
				FILENUMBER,
				CLIENTSREFERENCE,
				CPACOUNTRYCODE,
				RENEWALTYPECODE,
				MARK,
				ENTITYSIZE,
				PRIORITYDATE,
				PARENTDATE,
				NEXTTAXDATE,
				NEXTDECOFUSEDATE,
				PCTFILINGDATE,
				ASSOCDESIGNDATE,
				NEXTAFFIDAVITDATE,
				APPLICATIONDATE,
				ACCEPTANCEDATE,
				PUBLICATIONDATE,
				REGISTRATIONDATE,
				RENEWALDATE,
				NOMINALWORKINGDATE,
				EXPIRYDATE,
				CPASTARTPAYDATE,
				CPASTOPPAYDATE,
				STOPPAYINGREASON,
				PRIORITYNO,
				PARENTNO,
				PCTFILINGNO,
				ASSOCDESIGNNO,
				APPLICATIONNO,
				ACCEPTANCENO,
				PUBLICATIONNO,
				REGISTRATIONNO,
				INTLCLASSES,
				LOCALCLASSES,
				NUMBEROFYEARS,
				NUMBEROFCLAIMS,
				NUMBEROFDESIGNS,
				NUMBEROFCLASSES,
				NUMBEROFSTATES,
				DESIGNATEDSTATES,
				OWNERNAME,
				OWNERNAMECODE,
				OWNADDRESSLINE1,
				OWNADDRESSLINE2,
				OWNADDRESSLINE3,
				OWNADDRESSLINE4,
				OWNADDRESSCOUNTRY,
				OWNADDRESSPOSTCODE,
				CLIENTCODE,
				CPACLIENTNO,
				CLIENTNAME,
				CLIENTATTENTION	,
				CLTADDRESSLINE1	,
				CLTADDRESSLINE2	,
				CLTADDRESSLINE3	,
				CLTADDRESSLINE4,
				CLTADDRESSCOUNTRY,
				CLTADDRESSPOSTCODE,
				CLIENTTELEPHONE,
				CLIENTFAX,
				CLIENTEMAIL,
				DIVISIONCODE,
				DIVISIONNAME,
				DIVISIONATTENTION,
				DIVADDRESSLINE1	,
				DIVADDRESSLINE2	,
				DIVADDRESSLINE3	,
				DIVADDRESSLINE4	,
				DIVADDRESSCOUNTRY,
				DIVADDRESSPOSTCODE,
				FOREIGNAGENTCODE,
				FOREIGNAGENTNAME,
				ATTORNEYCODE,
				ATTORNEYNAME,
				INVOICEECODE,
				CPAINVOICEENO,
				INVOICEENAME,
				INVOICEEATTENTION,
				INVADDRESSLINE1	,
				INVADDRESSLINE2	,
				INVADDRESSLINE3	,
				INVADDRESSLINE4	,
				INVADDRESSCOUNTRY,
				INVADDRESSPOSTCODE,
				INVOICEETELEPHONE,
				INVOICEEFAX,
				INVOICEEEMAIL,
				NARRATIVE,
				IPRURN
			from #TEMPCPASEND"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nBatchNo	int',
							  @nBatchNo
		End
	
		-- Now remove rows from CPASENDCOMPARE that have a later verion of the same record
		-- Note the separate DELETEs are for performance reasons
		If @ErrorCode=0
		Begin
			Set @sSQLString="
			delete CPASENDCOMPARE
			from CPASENDCOMPARE C1
			join (select BATCHNO, CASECODE from CPASENDCOMPARE) C2
				on (C2.BATCHNO>C1.BATCHNO
				and C2.CASECODE=C1.CASECODE)
			
			delete CPASENDCOMPARE
			from CPASENDCOMPARE C1
			join (	select BATCHNO, CLIENTCODE from CPASENDCOMPARE
				where CASECODE is null
				and CLIENTCODE is not null) C2
					on (C2.BATCHNO>C1.BATCHNO
					and C2.CLIENTCODE =C1.CLIENTCODE)
			where C1.CASECODE is null
			
			delete CPASENDCOMPARE
			from CPASENDCOMPARE C1
			join (	select BATCHNO, DIVISIONCODE from CPASENDCOMPARE
				where CASECODE is null
				and DIVISIONCODE is not null) C2
					on (C2.BATCHNO>C1.BATCHNO
					and C2.DIVISIONCODE =C1.DIVISIONCODE)
			where C1.CASECODE is null
			
			delete CPASENDCOMPARE
			from CPASENDCOMPARE C1
			join (	select BATCHNO, INVOICEECODE from CPASENDCOMPARE
				where CASECODE is null
				and INVOICEECODE is not null) C2
					on (C2.BATCHNO>C1.BATCHNO
					and C2.INVOICEECODE =C1.INVOICEECODE)
			where C1.CASECODE is null"

			Exec @ErrorCode=sp_executesql @sSQLString
		End
	
		-- Generate a dummy EPL batch for each of the first CPASEND batch details. This
		-- is part of the initialisation process to ensure that we have a record of Cases having been 
		-- sent to CPA even if they were sent before the CPA Interface was implemented.
	
		If @bDummyBatchFlag=1
		and @ErrorCode=0
		Begin
		-- 20571/20480 Populate CPASEND with complete contents of CPARECEIVE for initialisation batch.
			Set @sSQLString="
			insert into CPARECEIVE (
					SYSTEMID,BATCHNO,BATCHDATE,PROPERTYTYPE,CASECODE,TRANSACTIONCODE,ALTOFFICECODE,CASEID,
					FILENUMBER,CLIENTSREFERENCE,CPACOUNTRYCODE,RENEWALTYPECODE,MARK,ENTITYSIZE,PRIORITYDATE,
					PARENTDATE,NEXTTAXDATE,NEXTDECOFUSEDATE,PCTFILINGDATE,ASSOCDESIGNDATE,NEXTAFFIDAVITDATE,
					APPLICATIONDATE,ACCEPTANCEDATE,PUBLICATIONDATE,REGISTRATIONDATE,RENEWALDATE,NOMINALWORKINGDATE,
					EXPIRYDATE,CPASTARTPAYDATE,CPASTOPPAYDATE,STOPPAYINGREASON,PRIORITYNO,PARENTNO,PCTFILINGNO,
					ASSOCDESIGNNO,APPLICATIONNO,ACCEPTANCENO,PUBLICATIONNO,REGISTRATIONNO,INTLCLASSES,
					LOCALCLASSES,NUMBEROFYEARS,NUMBEROFCLAIMS,NUMBEROFDESIGNS,NUMBEROFCLASSES,NUMBEROFSTATES,
					DESIGNATEDSTATES,OWNERNAME,OWNERNAMECODE,OWNADDRESSLINE1,OWNADDRESSLINE2,OWNADDRESSLINE3,
					OWNADDRESSLINE4,OWNADDRESSCOUNTRY,OWNADDRESSPOSTCODE,CLIENTCODE,CPACLIENTNO,CLIENTNAME,
					CLTADDRESSLINE1,CLTADDRESSLINE2,CLTADDRESSLINE3,CLTADDRESSLINE4,CLTADDRESSCOUNTRY,
					CLTADDRESSPOSTCODE,CLIENTTELEPHONE,CLIENTFAX,CLIENTEMAIL,DIVISIONCODE,DIVISIONNAME,
					DIVADDRESSLINE1,DIVADDRESSLINE2	,DIVADDRESSLINE3,DIVADDRESSLINE4,DIVADDRESSCOUNTRY,DIVADDRESSPOSTCODE,
					FOREIGNAGENTCODE,FOREIGNAGENTNAME,ATTORNEYCODE,ATTORNEYNAME,INVOICEECODE,CPAINVOICEENO,INVOICEENAME,
					INVADDRESSLINE1,INVADDRESSLINE2,INVADDRESSLINE3,INVADDRESSLINE4,INVADDRESSCOUNTRY,
					INVADDRESSPOSTCODE,INVOICEETELEPHONE,INVOICEEFAX,INVOICEEEMAIL,NARRATIVE) --,IPRURN)
			select distinct	S.SYSTEMID,S.BATCHNO,getdate(),
	 				S.PROPERTYTYPE,S.CASECODE,S.TRANSACTIONCODE,S.ALTOFFICECODE,S.CASEID,S.FILENUMBER,
					S.CLIENTSREFERENCE,S.CPACOUNTRYCODE,S.RENEWALTYPECODE,
					S.MARK,S.ENTITYSIZE,S.PRIORITYDATE,S.PARENTDATE,S.NEXTTAXDATE,S.NEXTDECOFUSEDATE,
					S.PCTFILINGDATE,S.ASSOCDESIGNDATE,S.NEXTAFFIDAVITDATE,S.APPLICATIONDATE,S.ACCEPTANCEDATE,
					S.PUBLICATIONDATE,S.REGISTRATIONDATE,S.RENEWALDATE,S.NOMINALWORKINGDATE,
					S.EXPIRYDATE,S.CPASTARTPAYDATE,S.CPASTOPPAYDATE,S.STOPPAYINGREASON,
					S.PRIORITYNO,S.PARENTNO,S.PCTFILINGNO,S.ASSOCDESIGNNO,S.APPLICATIONNO,S.ACCEPTANCENO,
					S.PUBLICATIONNO,S.REGISTRATIONNO,S.INTLCLASSES,S.LOCALCLASSES,S.NUMBEROFYEARS,
					S.NUMBEROFCLAIMS,S.NUMBEROFDESIGNS,S.NUMBEROFCLASSES,S.NUMBEROFSTATES,S.DESIGNATEDSTATES,
					S.OWNERNAME,
					S.OWNERNAMECODE,S.OWNADDRESSLINE1,S.OWNADDRESSLINE2,
					S.OWNADDRESSLINE3,S.OWNADDRESSLINE4,S.OWNADDRESSCOUNTRY,S.OWNADDRESSPOSTCODE,S.CLIENTCODE,
					S.CPACLIENTNO,S.CLIENTNAME,S.CLTADDRESSLINE1,S.CLTADDRESSLINE2,
					S.CLTADDRESSLINE3,S.CLTADDRESSLINE4,S.CLTADDRESSCOUNTRY,S.CLTADDRESSPOSTCODE,S.CLIENTTELEPHONE,
					S.CLIENTFAX, S.CLIENTEMAIL,S.DIVISIONCODE,S.DIVISIONNAME,
					S.DIVADDRESSLINE1,S.DIVADDRESSLINE2,
					S.DIVADDRESSLINE3,S.DIVADDRESSLINE4,S.DIVADDRESSCOUNTRY,S.DIVADDRESSPOSTCODE,S.FOREIGNAGENTCODE,
					S.FOREIGNAGENTNAME,S.ATTORNEYCODE,S.ATTORNEYNAME,S.INVOICEECODE,S.CPAINVOICEENO,
					S.INVOICEENAME,S.INVADDRESSLINE1,S.INVADDRESSLINE2,S.INVADDRESSLINE3,
					S.INVADDRESSLINE4,S.INVADDRESSCOUNTRY,S.INVADDRESSPOSTCODE,S.INVOICEETELEPHONE,S.INVOICEEFAX,
					S.INVOICEEEMAIL,S.NARRATIVE --,S.IPRURN do not populate IPRURN to avoid perpetuating an assumption
				from CPASEND S
				where S.BATCHNO=@nBatchNo"
		
/*	20571/20480 This section removed to avoid assumptions. 
				Simply use CPASEND data to populate CPARECEIVE and remove filter on L.
			Set @sSQLString="
			insert into CPARECEIVE (
					SYSTEMID,BATCHNO,BATCHDATE,PROPERTYTYPE,CASECODE,TRANSACTIONCODE,ALTOFFICECODE,CASEID,
					FILENUMBER,CLIENTSREFERENCE,CPACOUNTRYCODE,RENEWALTYPECODE,MARK,ENTITYSIZE,PRIORITYDATE,
					PARENTDATE,NEXTTAXDATE,NEXTDECOFUSEDATE,PCTFILINGDATE,ASSOCDESIGNDATE,NEXTAFFIDAVITDATE,
					APPLICATIONDATE,ACCEPTANCEDATE,PUBLICATIONDATE,REGISTRATIONDATE,RENEWALDATE,NOMINALWORKINGDATE,
					EXPIRYDATE,CPASTARTPAYDATE,CPASTOPPAYDATE,STOPPAYINGREASON,PRIORITYNO,PARENTNO,PCTFILINGNO,
					ASSOCDESIGNNO,APPLICATIONNO,ACCEPTANCENO,PUBLICATIONNO,REGISTRATIONNO,INTLCLASSES,
					LOCALCLASSES,NUMBEROFYEARS,NUMBEROFCLAIMS,NUMBEROFDESIGNS,NUMBEROFCLASSES,NUMBEROFSTATES,
					DESIGNATEDSTATES,OWNERNAME,OWNERNAMECODE,OWNADDRESSLINE1,OWNADDRESSLINE2,OWNADDRESSLINE3,
					OWNADDRESSLINE4,OWNADDRESSCOUNTRY,OWNADDRESSPOSTCODE,CLIENTCODE,CPACLIENTNO,CLIENTNAME,
					CLTADDRESSLINE1,CLTADDRESSLINE2,CLTADDRESSLINE3,CLTADDRESSLINE4,CLTADDRESSCOUNTRY,
					CLTADDRESSPOSTCODE,CLIENTTELEPHONE,CLIENTFAX,CLIENTEMAIL,DIVISIONCODE,DIVISIONNAME,
					DIVADDRESSLINE1,DIVADDRESSLINE2	,DIVADDRESSLINE3,DIVADDRESSLINE4,DIVADDRESSCOUNTRY,DIVADDRESSPOSTCODE,
					FOREIGNAGENTCODE,FOREIGNAGENTNAME,ATTORNEYCODE,ATTORNEYNAME,INVOICEECODE,CPAINVOICEENO,INVOICEENAME,
					INVADDRESSLINE1,INVADDRESSLINE2,INVADDRESSLINE3,INVADDRESSLINE4,INVADDRESSCOUNTRY,
					INVADDRESSPOSTCODE,INVOICEETELEPHONE,INVOICEEFAX,INVOICEEEMAIL,NARRATIVE) --,IPRURN)
			select distinct	S.SYSTEMID,S.BATCHNO,getdate(),
	 				S.PROPERTYTYPE,S.CASECODE,S.TRANSACTIONCODE,S.ALTOFFICECODE,S.CASEID,S.FILENUMBER,
					P.CLIENTREF,P.IPCOUNTRYCODE,S.RENEWALTYPECODE,
					S.MARK,S.ENTITYSIZE,P.FIRSTPRIORITYDATE,P.PARENTDATE,S.NEXTTAXDATE,S.NEXTDECOFUSEDATE,
					P.PCTFILINGDATE,S.ASSOCDESIGNDATE,S.NEXTAFFIDAVITDATE,P.APPLICATIONDATE,S.ACCEPTANCEDATE,
					P.PUBLICATIONDATE,P.GRANTDATE,P.NEXTRENEWALDATE,S.NOMINALWORKINGDATE,
					P.EXPIRYDATE,S.CPASTARTPAYDATE,S.CPASTOPPAYDATE,S.STOPPAYINGREASON,
					P.FIRSTPRIORITYNO,P.PARENTNO,P.PATENTPCTNO,S.ASSOCDESIGNNO,P.APPLICATIONNO,S.ACCEPTANCENO,
					P.PUBLICATIONNO,P.REGISTRATIONNO,S.INTLCLASSES,S.LOCALCLASSES,S.NUMBEROFYEARS,
					S.NUMBEROFCLAIMS,S.NUMBEROFDESIGNS,S.NUMBEROFCLASSES,S.NUMBEROFSTATES,S.DESIGNATEDSTATES,
					P.PROPRIETOR,
					S.OWNERNAMECODE,S.OWNADDRESSLINE1,S.OWNADDRESSLINE2,
					S.OWNADDRESSLINE3,S.OWNADDRESSLINE4,S.OWNADDRESSCOUNTRY,S.OWNADDRESSPOSTCODE,S.CLIENTCODE,
					S.CPACLIENTNO,S.CLIENTNAME,S.CLTADDRESSLINE1,S.CLTADDRESSLINE2,
					S.CLTADDRESSLINE3,S.CLTADDRESSLINE4,S.CLTADDRESSCOUNTRY,S.CLTADDRESSPOSTCODE,S.CLIENTTELEPHONE,
					S.CLIENTFAX, S.CLIENTEMAIL,P.DIVISIONCODE,P.DIVISIONNAME,
					S.DIVADDRESSLINE1,S.DIVADDRESSLINE2,
					S.DIVADDRESSLINE3,S.DIVADDRESSLINE4,S.DIVADDRESSCOUNTRY,S.DIVADDRESSPOSTCODE,S.FOREIGNAGENTCODE,
					S.FOREIGNAGENTNAME,S.ATTORNEYCODE,S.ATTORNEYNAME,S.INVOICEECODE,S.CPAINVOICEENO,
					S.INVOICEENAME,S.INVADDRESSLINE1,S.INVADDRESSLINE2,S.INVADDRESSLINE3,
					S.INVADDRESSLINE4,S.INVADDRESSCOUNTRY,S.INVADDRESSPOSTCODE,S.INVOICEETELEPHONE,S.INVOICEEFAX,
					S.INVOICEEEMAIL,S.NARRATIVE --,P.IPRURN do not populate IPRURN to avoid perpetuating an assumption
				from CPASEND S
				-- Cater for multiple entries in the CPA Portfolio for the one Case by taking the 
				-- lowest IPRURN value for that Case.
				join (	select CASEID, min(IPRURN) as IPRURN
					from CPAPORTFOLIO
					where IPRURN is not null
					group by CASEID) CPA
							on (CPA.CASEID=S.CASEID)
				join CPAPORTFOLIO P	on (P.CASEID=S.CASEID
					    		and P.IPRURN=CPA.IPRURN)
				where S.BATCHNO=@nBatchNo
				and P.STATUSINDICATOR='L'"*/
		
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nBatchNo	int',
							  @nBatchNo
		End
	
		-- Insert an Event for CPA Stop if the extract has defaulted a date and the
		-- Event does not already exist on the database.  This will ensure that the same
		-- CPA Stop Date is reported should the case be reextracted.
	
		If  @nCPAStopEventNo is not null
		and @ErrorCode=0
		Begin
			-- Now insert the CASEEVENT rows to indicate that CPA have received the case	
			-- for all cases not rejected
			Set @sSQLString=
			"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)"+char(10)+
			"select CASEID, E.EVENTNO, 1, CPA.CPASTOPPAYDATE, 1"+char(10)+
			"from CPASEND CPA"+char(10)+
			"join EVENTS E on (E.EVENTNO=@nCPAStopEventNo)"+char(10)+
			"where CPA.BATCHNO=@nBatchNo"+char(10)+
			"and   CPA.CASEID is not null"+char(10)+
			"and   CPA.STOPPAYINGREASON is not null"+char(10)+
			"and   CPA.CPASTOPPAYDATE   is not null"+char(10)+
			"and not exists"+char(10)+
			"(select * from CASEEVENT CE"+char(10)+
			" where CE.CASEID=CPA.CASEID"+char(10)+
			" and   CE.EVENTNO=E.EVENTNO)"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCPAStopEventNo	int,
							  @nBatchNo		int',
							  @nCPAStopEventNo,
							  @nBatchNo
		End
	
		
		-- Insert or update an Event for Cases to indicate that the Case has been sent to CPA
	
		If  @nCPASentEventNo is not null
		and @ErrorCode=0
		Begin
			-- Now update the CASEEVENT rows to indicate that CPA have received the case	
			Set @sSQLString=
			"Update CASEEVENT"+char(10)+
			"set EVENTDATE=convert(varchar,getdate(),112),"+char(10)+
			"    OCCURREDFLAG=1"+char(10)+
			"from CASEEVENT CE"+char(10)+
			"join CPASEND CPA on (CPA.CASEID=CE.CASEID)"+char(10)+
			"where CE.EVENTNO=@nCPASentEventNo"+char(10)+
			"and (CE.EVENTDATE<>convert(varchar,getdate(),112) or CE.EVENTDATE is null)"+char(10)+
			"and  CPA.BATCHNO=@nBatchNo"
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCPASentEventNo	int,
							  @nBatchNo		int',
							  @nCPASentEventNo,
							  @nBatchNo
	
			-- Alternatively insert the CASEEVENT rows to indicate that CPA have been sent the case.
			-- This handles the situation where the CaseEvent row does not exist already.
			If @ErrorCode=0
			Begin
				Set @sSQLString=
				"insert into CASEEVENT (CASEID, EVENTNO, CYCLE, EVENTDATE, OCCURREDFLAG)"+char(10)+
				"select CASEID, @nCPASentEventNo, 1, convert(varchar,getdate(),112), 1"+char(10)+
				"from CPASEND CPA"+char(10)+
				"join EVENTS E on (E.EVENTNO=@nCPASentEventNo)"+char(10)+
				"where CPA.BATCHNO=@nBatchNo"+char(10)+
				"and   CPA.CASEID is not null"+char(10)+
				"and not exists"+char(10)+
				"(select * from CASEEVENT CE"+char(10)+
				" where CE.CASEID=CPA.CASEID"+char(10)+
				" and   CE.EVENTNO=@nCPASentEventNo)"
	
				Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCPASentEventNo	int,
							  @nBatchNo		int',
							  @nCPASentEventNo,
							  @nBatchNo
			End
		End
	
		-- Insert a Policing request for each CASEID.  If Smart Policing is not on then insert the
		-- Policing requests with the On Hold Flag set ON. 
		
		If  @ErrorCode     =0
		and @pnPoliceEvents=1
		begin
			Set @sSQLString="
			insert into POLICING (	DATEENTERED, POLICINGSEQNO, POLICINGNAME, SYSGENERATEDFLAG, 
						ONHOLDFLAG, EVENTNO, CASEID, CYCLE, TYPEOFREQUEST, SQLUSER, IDENTITYID)
			select	getdate(), T.POLICINGSEQNO, convert(varchar, getdate(),126)+convert(varchar,T.POLICINGSEQNO),1,
				CASE WHEN(S.COLBOOLEAN=1) THEN 0 ELSE 1 END,
				@nCPASentEventNo, CASEID, 1, 3, substring(SYSTEM_USER,1,18), @pnUserIdentityId
			from #TEMPPOLICING T
			left join SITECONTROL S on (S.CONTROLID='Smart Policing')"
	
	
			Exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCPASentEventNo	int,
							  @pnUserIdentityId	int',
							  @nCPASentEventNo,
							  @pnUserIdentityId = @pnUserIdentityId
		end
	
	
		-- Delete any rows from the CPAUPDATE table that have just been extracted
		If exists(select 1 from SITECONTROL where CONTROLID='CPA Clear Batch' and COLBOOLEAN=1)
		    -- Delete all possible row from CPAUPDATE
		    If @psOfficeCPACode is not null
		    Begin
			Set @sSQLString="
			Delete CPAUPDATE
			from CPAUPDATE CPA
			left join #TEMPCPAUPDATETODELETE T	on (T.CASEID=CPA.CASEID
								OR  T.NAMEID=CPA.NAMEID)
			left join CASES C on (C.CASEID = CPA.CASEID)
			left join OFFICE O on (O.OFFICEID = C.OFFICEID)
			where (T.CASEID is not null and O.CPACODE = @psOfficeCPACode)
			OR T.NAMEID is not null
			OR (CPA.CASEID is null and CPA.NAMEID is null)"

			If @ErrorCode=0
			Begin
				Exec @ErrorCode=sp_executesql @sSQLString,
											N'@psOfficeCPACode nvarchar(3)',
											@psOfficeCPACode = @psOfficeCPACode
			End		    
		    End
		    Else
		    Begin
			Set @sSQLString="
			Delete CPAUPDATE
			from CPAUPDATE CPA
			left join #TEMPCPAUPDATETODELETE T	on (T.CASEID=CPA.CASEID
							    OR  T.NAMEID=CPA.NAMEID)
			where T.CASEID is not null
			OR T.NAMEID is not null
			OR (CPA.CASEID is null and CPA.NAMEID is null)"

			If @ErrorCode=0
			Begin
				Exec @ErrorCode=sp_executesql @sSQLString
			End
		    End
		Else
		    Begin
			-- Delete only the CPAUPDATE rows that were eligible to send
			Set @sSQLString="
			Delete CPAUPDATE
			from CPAUPDATE CPA
			join #TEMPDATATOSEND T	on (T.CASEID=CPA.CASEID
						OR  T.NAMENO=CPA.NAMEID)"

			If @ErrorCode=0
			Begin
				Exec @ErrorCode=sp_executesql @sSQLString
			End
		    End
		
		
		-- RFC63207 Delete rows from CPASENDDEBTORS where cases are excluded by 'CPA Multi Debtor File' site control.
		-- Note that Cases that are not Patents, Trademarks or Designs are handled the same way as Patents and
		-- enabled by the same site control setting ('P').

		If @ErrorCode=0
		Begin
			Set @sSQLString="
			delete from CPASENDDEBTORS
			where CPASENDROWID in
				(select	ROWID
				from CPASEND
				where BATCHNO=@nBatchNo	
				and (charindex( PROPERTYTYPE,@sDebtorPropertyTypes) = 0
				  or charindex( PROPERTYTYPE,@sDebtorPropertyTypes) is null))"
		    		    
			exec @ErrorCode=sp_executesql @sSQLString,
					N'@nBatchNo	int,
					@sDebtorPropertyTypes	nvarchar(254)',
					@nBatchNo = @nBatchNo,
					@sDebtorPropertyTypes = @sDebtorPropertyTypes
		End
		
	
		-- Commit the transaction if it has successfully completed
	
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
	End
	
	-- The Result Set should return the Batch Number plus the totals to be used in the 
	-- header record to be sent to CPA
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="
		select 
		@ErrorCode	as ErrorCode,
		BATCHNO		as BatchNo,
		BATCHDATE	as BatchDate,
		sum(CASE WHEN(TRANSACTIONCODE in (12,21) and PROPERTYTYPE='P') THEN 1 ELSE 0 END) as PatentCount,
		sum(CASE WHEN(TRANSACTIONCODE in (12,21) and PROPERTYTYPE='D') THEN 1 ELSE 0 END) as DesignCount,
		sum(CASE WHEN(TRANSACTIONCODE in (12,21) and PROPERTYTYPE='T') THEN 1 ELSE 0 END) as TMCount,
		sum(CASE WHEN(TRANSACTIONCODE =04) THEN 1 ELSE 0 END) as ClientCount,
		sum(CASE WHEN(TRANSACTIONCODE =05) THEN 1 ELSE 0 END) as DivisionCount,
		sum(CASE WHEN(TRANSACTIONCODE =06) THEN 1 ELSE 0 END) as InvoiceeCount
		from CPASEND
		where BATCHNO=@nBatchNo
		group by BATCHNO, BATCHDATE"
		
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@nBatchNo	int,
						  @ErrorCode	int',
						  @nBatchNo,
						  @ErrorCode
	End
	Else 
	Begin
		Set @sSQLString="
		select	@ErrorCode	as ErrorCode,
			null		as BatchNo,
			null		as BatchDate,
			null		as PatentCount,
			null		as DesignCount,
			null		as TMCount,
			null		as ClientCount,
			null		as DivisionCount,
			null		as InvoiceeCount"
		
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@ErrorCode	int',
						  @ErrorCode
	End
End

drop table #TEMPDATATOSEND
drop table #TEMPCASERENEWALTYPE
drop table #TEMPCPASEND

Return @ErrorCode
go

grant execute on dbo.cpa_InsertCPAComplete to public
go
