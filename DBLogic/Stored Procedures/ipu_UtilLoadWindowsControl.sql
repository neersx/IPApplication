-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_UtilLoadWindowsControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipu_UtilLoadWindowsControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipu_UtilLoadWindowsControl.'
	Drop procedure [dbo].[ipu_UtilLoadWindowsControl]
	Print '**** Creating Stored Procedure dbo.ipu_UtilLoadWindowsControl...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipu_UtilLoadWindowsControl
(
	@pnUserIdentityId	int,		-- Mandatory UserIdentityId
	@pbClearCurrentRules	bit	= 0	-- Flag to cause removal of existing Windows Control rules
)
as
-- PROCEDURE:	ipu_UtilLoadWindowsControl
-- VERSION:	4
-- SCOPE:	Inprotech
-- DESCRIPTION:	Web Windows and Tab controls are reset from the Screen Control rules
--		defined for use by the Case client/server program.
-- COPYRIGHT:	Copyright 1993 - 2011 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------------- 
-- 15 Dec 2010  MF	9688	1	Procedure created from a script originally delivered in RFC 6732
-- 26 Apr 2011	BSH	9688	2	Corrections on initial testing.
--					Extended to include TOPICDEFAULTSETTINGS.
-- 06 Jun 2011	Mf	10771	3	Ignore any WindowControl rows that are associated to Name controls.
-- 08 Jul 2011	LP	10665	4	Fix logic to prevent duplicate TOPICDEFAULTSETTINGS from being inserted.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
------------------------------------
-- Temporary table to store criteria
------------------------------------
Create Table #TEMPCRITERIA (
		OLDCRITERIANO		int		not null,
		CRITERIANO		int		null, 
		WINDOWCRITERIANO	int		null,			 
		PURPOSECODE		nchar(1)	collate database_default null, 
		CASETYPE		nchar(1)	collate database_default null,
		PROGRAMID		nvarchar(8)	collate database_default null, 
		PROPERTYTYPE		nchar(1)	collate database_default null,
		PROPERTYUNKNOWN		decimal(1,0)				 null, 
		COUNTRYCODE		nvarchar(3)	collate database_default null, 
		COUNTRYUNKNOWN		decimal(1,0)				 null, 
		CASECATEGORY		nvarchar(2)	collate database_default null, 
		CATEGORYUNKNOWN		decimal(1,0)				 null, 
		SUBTYPE			nvarchar(2)	collate database_default null, 
		SUBTYPEUNKNOWN		decimal(1,0)				 null,
		BASIS			nvarchar(2)	collate database_default null, 
		DATEOFACT		datetime	null, 
		USERDEFINEDRULE		decimal(1,0)	null,
		RULEINUSE		decimal(1,0)	null, 
		DESCRIPTION		nvarchar(254)	collate database_default null, 
		CASEOFFICEID		int		null, 
		ISPUBLIC		bit		null)

-------------------------------------------
-- Temporary table to store mapping between 
-- SCREENCONTROL and TOPICCONTROL
-------------------------------------------
Create Table #TEMPWINDOWCONTROL (
		ID			int		identity(1,1),
		WINDOWNAME		nvarchar(50)	collate database_default null, 
		OLDCRITERIANO		int					 not null,
		TOPICNAME		nvarchar(50)	collate database_default null, 
		TABTITLE		nvarchar(254)	collate database_default null, 
		OLDSEQUENCE		smallint	not null,
		NEWSEQUENCE		smallint	null,
		WINDOWCONTROLNO		int		null,
		TABCONTROLNO		int		null,
		INHERITED		bit		default 0)

-------------------------------------------
-- Temporary table user for generation of  
-- the NEWSEQUENCE
-------------------------------------------
Create Table #TEMPWINDOWCONTROLSEQUENCE (
		ID			int		not null,
		WINDOWCONTROLNO		int		null,
		OLDSEQUENCE		smallint	not null,
		TOPICNAME		nvarchar(50)	collate database_default null, 
		NEWSEQUENCE		smallint	null)

Declare @nErrorCode			int
Declare @nTranCountStart		int
Declare @nTransNo			int
Declare @nRowCount			int
Declare	@nCriteria			int	-- The number of Criteria being loaded
Declare @nStartCriteriaNo		int	-- Seed for CriteriaNo generation
Declare @nRetry				int
Declare @nSaveControlNo			int
Declare @nSequence			int
Declare	@bHexNumber			varbinary(128)
Declare	@nVersionRange			tinyint

Declare @sSQLString			nvarchar(max)

-----------------------
-- Initialise variables
-----------------------
Set @nErrorCode = 0
Set @nRowCount  = 0

If @nErrorCode=0
Begin
	select @nVersionRange=1 
	from SITECONTROL 
	where CONTROLID ='DB Release Version'
	and COLCHARACTER >='Release 6.2'
End

If @nErrorCode = 0
Begin
	----------------------------------------
	-- Populate the #TEMPCRITERIA table with 
	-- screen control criteria.
	-- We are not going to differentiate 
	-- between User Defined and Protected in
	-- terms of CRITERIANO to be allocated.
	----------------------------------------
	insert into #TEMPCRITERIA 
		(OLDCRITERIANO, PURPOSECODE, CASETYPE,  PROGRAMID, PROPERTYTYPE, PROPERTYUNKNOWN, 
		COUNTRYCODE, COUNTRYUNKNOWN, CASECATEGORY, CATEGORYUNKNOWN, SUBTYPE, SUBTYPEUNKNOWN,
		BASIS, DATEOFACT, USERDEFINEDRULE, RULEINUSE, DESCRIPTION, 
		CASEOFFICEID, ISPUBLIC)
	select	C.CRITERIANO, 'W', C.CASETYPE, C.PROGRAMID, C.PROPERTYTYPE,
		isnull(C.PROPERTYUNKNOWN,0), C.COUNTRYCODE, isnull(C.COUNTRYUNKNOWN,0), C.CASECATEGORY, isnull(C.CATEGORYUNKNOWN,0), C.SUBTYPE, isnull(C.SUBTYPEUNKNOWN,0),
		C.BASIS, C.DATEOFACT, C.USERDEFINEDRULE, C.RULEINUSE, C.DESCRIPTION, C.CASEOFFICEID, C.ISPUBLIC  
	FROM CRITERIA C
	JOIN CASETYPE CT on (CT.CASETYPE = C.CASETYPE 
			 and isnull(CT.CRMONLY,0) = 0)
	WHERE C.RULEINUSE  = 1
	and   C.PURPOSECODE='S'
	order by C.USERDEFINEDRULE, C.CRITERIANO

	Select @nErrorCode=@@Error, 
	       @nCriteria =@@RowCount
End

If @nErrorCode = 0
and @nCriteria > 0
Begin
	---------------------------------------------
	-- Insert mapping into new temporary table
	-- Note: frmCaseTextSummry will create 3 new 
	--       records in TOPICCONTROL. Just create 
	--       the first topic for now.
	---------------------------------------------

	---------------------------------------------
	-- NOTE: The following client/server screens
	-- are not yet mapped:
	--	frmAgreementCases
	--	frmApplyAssignment
	--	frmAssignCases
	--	frmAttachments
	--	frmB2BEFiledPackages
	--	frmBudget
	--	frmCaseActivity
	--	frmCaseDetail
	--	frmChangeOwner
	--	frmCheckList
	--	frmCopyDetails
	--	frmDocuments
	--	frmExamination
	--	frmFileLocation				BSH 25.04.11 IMPLEMENTED for 7 Beta
	--	frmLetters
	--	frmMultiCaseSummary
	--	frmNameText
	--	frmRecCaseAffectedCases
	---------------------------------------------


	INSERT INTO #TEMPWINDOWCONTROL
	(WINDOWNAME, OLDCRITERIANO, TOPICNAME, TABTITLE, OLDSEQUENCE, INHERITED)
	SELECT	CASE SC.SCREENNAME
			WHEN 'dlgNewCase' THEN 'NewCaseForm'
					  ELSE 'CaseDetails'
		END,
		SC.CRITERIANO,
			--------------------------------
			-- Map the client/server Screens
			-- to the web Windows
			--------------------------------
		CASE SC.SCREENNAME
			WHEN 'dlgNewCase'		THEN 'Case_NamesTopic'

			WHEN 'frmAttributes'		THEN 'Attributes_Component'

			WHEN 'frmCaseDates'		THEN 'Events_Component'
			WHEN 'frmCaseHistory'		THEN CASE WHEN(@nVersionRange=1) THEN 'Actions_Component' ELSE 'Events_Component' END
--			WHEN 'frmCaseHistory'		THEN CASE WHEN(1=1) THEN 'Actions_Component' ELSE 'Events_Component' END
			WHEN 'frmCaseEventSummry'	THEN 'Events_Component'

			WHEN 'frmCaseLists'		THEN 'CaseList_Component'

			WHEN 'frmCaseTextSummry'	THEN '1 - Case_TextTopic'

			WHEN 'frmCheckList'		THEN 'Checklist_Component'

			WHEN 'frmClasses'		THEN 'Classes_Component'

			WHEN 'frmDesignElements'	THEN 'DesignElement_Component'

			WHEN 'frmDesignation'		THEN 'DesignatedCountries_Component'

			WHEN 'frmFirstUse'		THEN 'CaseFirstUse_Component'

			WHEN 'frmImage'			THEN 'Images_Component'

			WHEN 'frmInstructor'		THEN 'Names_Component'
			WHEN 'frmNameGrp'		THEN 'Names_Component'
			WHEN 'frmNames'			THEN 'Names_Component'

			WHEN 'frmJournal'		THEN 'CaseJournal_Component'

			WHEN 'frmKeyWords'		THEN 'CaseOtherDetails_Component'
			WHEN 'frmOtherDetails'		THEN 'CaseOtherDetails_Component'

			WHEN 'frmOfficialNo'		THEN 'OfficialNumbers_Component'

			WHEN 'frmPatentTermAdjustments'	THEN 'PTA_Component'

			WHEN 'frmSearchResults'		THEN 'PriorArt_Component'

			WHEN 'frmRelationships'		THEN 'RelatedCases_Component'

			WHEN 'frmRenewalCriticalFields'	THEN 'CaseRenewals_Component'
			WHEN 'frmRenewals'		THEN 'CaseRenewals_Component'

			WHEN 'frmStandingInst'		THEN 'CaseStandingInstructions_Component'

			WHEN 'frmText'			THEN 'Case_TextTopic'

			WHEN 'frmWIP'			THEN 'WIP_Component'

			WHEN 'frmFileLocation'		THEN 'FileLocations_Component'
		
							ELSE 'NO_WORKBENCH_EQUIVALENT'
		END,
		SC.SCREENTITLE,SC.DISPLAYSEQUENCE,isnull(SC.INHERITED,0)
	 FROM #TEMPCRITERIA C
	 JOIN SCREENCONTROL SC	on (SC.CRITERIANO = C.OLDCRITERIANO
				AND(SC.SCREENNAME IN (	'frmAttributes', 'frmCaseDates', 'frmCaseHistory', 'frmCaseLists', 'frmCaseEventSummry',
							'frmCaseTextSummry', 'frmClasses', 'frmDesignElements', 'frmDesignation', 'frmFirstUse',
							'frmImage', 'frmInstructor', 'frmJournal', 'frmKeyWords', 'frmNameGrp', 'frmNames',
							'frmOfficialNo', 'frmOtherDetails', 'frmPatentTermAdjustments', 'frmSearchResults',
							'frmRelationships', 'frmRenewalCriticalFields', 'frmRenewals', 'frmStandingInst',
							'frmText', 'frmWIP', 'dlgNewCase','frmFileLocation')
				 OR(SC.SCREENNAME IN (	'frmCheckList') AND  @nVersionRange=1)) )
--				 OR(SC.SCREENNAME IN (	'frmCheckList') AND  1=1)) )
	ORDER BY C.OLDCRITERIANO,SC.DISPLAYSEQUENCE

	Set @nErrorCode = @@Error
End

If  @nErrorCode=0
and @nCriteria >0
Begin
	---------------------------------------------------------------------------------
	-- Now start a new transaction
	-- NOTE : We want to keep the execution of this transaction as short as practical
	--	  to avoid leaving extensive locks on the LASTINTERNALCODE table which is
	--	  a widely used table
	---------------------------------------------------------------------------------
	Select @nTranCountStart = @@TranCount
	BEGIN TRANSACTION
		
	-- Allocate a transaction id that can be
	-- accessed by the audit logs for inclusion.

	Insert into TRANSACTIONINFO(TRANSACTIONDATE) values(getdate())
	Select	@nTransNo=SCOPE_IDENTITY(),
		@nErrorCode=@@Error
	
	--------------------------------------------------------------
	-- Load a common area accessible from the database server with
	-- the TransactionNo just generated and other details.
	-- This will be used by the audit logs.
	--------------------------------------------------------------

	set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4) + 
			substring(cast(isnull(@nTransNo,'') as varbinary),1,4)
	SET CONTEXT_INFO @bHexNumber

	If  @nErrorCode=0
	and @pbClearCurrentRules=1
	Begin
		-----------------------------------
		-- Requested to clear out 
		-- all existing Window Control
		-- criteria. This will cascade
		-- down to the WindowControl table.
		-----------------------------------
		-- DO NOT CLEAR CRM as this was not
		-- converted from the client server 
		-- set up.
		-----------------------------------
		-- WARNING 
		-- I suspect this DELETE may be 
		-- slow to execute
		-----------------------------------
		Delete C
		From CRITERIA C
		LEFT JOIN CASETYPE CT on (CT.CASETYPE = C.CASETYPE)
		where C.PURPOSECODE='W'
		and isnull(CT.CRMONLY,0) = 0

		Set @nErrorCode=0
	End
	Else If @nErrorCode=0
	Begin
		------------------------------------------
		-- If WindowsControl rules are not being
		-- cleared then  try and find a matching 
		-- Criteria for Window Control
		------------------------------------------
		Update T
		Set WINDOWCRITERIANO=C.CRITERIANO
		from #TEMPCRITERIA T
		join CRITERIA C	on (C.PURPOSECODE    = 'W'
					and C.RULEINUSE      = 1
					and C.PROPERTYUNKNOWN= T.PROPERTYUNKNOWN
					and C.COUNTRYUNKNOWN = T.COUNTRYUNKNOWN
					and C.CATEGORYUNKNOWN= T.CATEGORYUNKNOWN
					and C.SUBTYPEUNKNOWN = T.SUBTYPEUNKNOWN
					and C.USERDEFINEDRULE= T.USERDEFINEDRULE
					and(C.CASETYPE       = T.CASETYPE     OR (C.CASETYPE     is null and T.CASETYPE     is null))
					and(C.PROGRAMID      = T.PROGRAMID    OR (C.PROGRAMID    is null and T.PROGRAMID    is null))
					and(C.PROPERTYTYPE   = T.PROPERTYTYPE OR (C.PROPERTYTYPE is null and T.PROPERTYTYPE is null))
					and(C.COUNTRYCODE    = T.COUNTRYCODE  OR (C.COUNTRYCODE  is null and T.COUNTRYCODE  is null))
					and(C.CASECATEGORY   = T.CASECATEGORY OR (C.CASECATEGORY is null and T.CASECATEGORY is null))
					and(C.SUBTYPE        = T.SUBTYPE      OR (C.SUBTYPE      is null and T.SUBTYPE      is null))
					and(C.BASIS          = T.BASIS        OR (C.BASIS        is null and T.BASIS        is null))
					and(C.DATEOFACT      = T.DATEOFACT    OR (C.DATEOFACT    is null and T.DATEOFACT    is null))
					and(C.CASEOFFICEID   = T.CASEOFFICEID OR (C.CASEOFFICEID is null and T.CASEOFFICEID is null))
					and(C.ISPUBLIC       = T.ISPUBLIC     OR (C.ISPUBLIC     is null and T.ISPUBLIC     is null)) )

		Select	@nErrorCode=@@Error

		-----------------------------
		-- Get the number of Criteria
		-- that need to be inserted
		-----------------------------
		If @nErrorCode=0
		Begin
			Select @nCriteria=count(*)
			from #TEMPCRITERIA
			where WINDOWCRITERIANO is null

			Select	@nErrorCode=@@Error,
				@nCriteria =@@Rowcount	-- Number of rows that need a CriteriaNo allocated
		End


	End 

	-------------------------------------------------
	-- Now reserve a CRITERIANO for each new Criteria
	-- by updating the LASTINTERNALCODE table.
	-------------------------------------------------
	If  @nCriteria>0
	and @nErrorCode=0
	Begin
		UPDATE LASTINTERNALCODE 
		SET @nStartCriteriaNo = INTERNALSEQUENCE,
		    INTERNALSEQUENCE  = INTERNALSEQUENCE + @nCriteria
		WHERE  TABLENAME = 'CRITERIA'

		Set @nErrorCode=@@Error
	End

	If @nErrorCode=0
	Begin
		-------------------------------------
		-- Allocate a CRITERIANO for each row 
		-- that does not already match an 
		-- existing Criteria or use a 
		-- previously found CriteriaNo.
		-------------------------------------

		Update T
		Set @nStartCriteriaNo=CASE WHEN(WINDOWCRITERIANO is null) THEN @nStartCriteriaNo+1 ELSE @nStartCriteriaNo END,
		    CRITERIANO=isnull(WINDOWCRITERIANO,@nStartCriteriaNo)
		from #TEMPCRITERIA T

		Set @nErrorCode=@@Error
	End

	If  @nCriteria>0
	and @nErrorCode=0
	Begin
		------------------------
		-- Load the new Criteria
		------------------------
		Insert into CRITERIA(	
			CRITERIANO,PURPOSECODE,CASETYPE,PROGRAMID,PROPERTYTYPE,PROPERTYUNKNOWN,
			COUNTRYCODE,COUNTRYUNKNOWN,CASECATEGORY,CATEGORYUNKNOWN,SUBTYPE,SUBTYPEUNKNOWN,	
			BASIS,DATEOFACT,USERDEFINEDRULE,RULEINUSE,DESCRIPTION,CASEOFFICEID,ISPUBLIC)
		
		Select	CRITERIANO,PURPOSECODE,CASETYPE,PROGRAMID,PROPERTYTYPE,PROPERTYUNKNOWN,
			COUNTRYCODE,COUNTRYUNKNOWN,CASECATEGORY,CATEGORYUNKNOWN,SUBTYPE,SUBTYPEUNKNOWN,	
			BASIS,DATEOFACT,USERDEFINEDRULE,RULEINUSE,DESCRIPTION,CASEOFFICEID,ISPUBLIC
		From #TEMPCRITERIA
		where WINDOWCRITERIANO is null

		Set @nErrorCode=@@Error
	End

	If @nErrorCode = 0
	Begin
		---------------------------------
		-- insert records into INHERITS
		-- by translating the CriteriaNo
		-- imported from Client/Server
		---------------------------------
		INSERT INTO INHERITS (CRITERIANO, FROMCRITERIA)
		Select C.CRITERIANO, P.CRITERIANO
		From #TEMPCRITERIA C
		Join INHERITS I		on (I.CRITERIANO   =C.OLDCRITERIANO)
		Join #TEMPCRITERIA P	on (P.OLDCRITERIANO=I.FROMCRITERIA)
		Left Join INHERITS I1	on (I1.CRITERIANO=C.CRITERIANO
					and I1.FROMCRITERIA=P.CRITERIANO)
		where I1.CRITERIANO is null
		UNION
		Select C.CRITERIANO, P.CRITERIANO
		From #TEMPCRITERIA P
		Join INHERITS I		on (I.FROMCRITERIA=P.OLDCRITERIANO)
		Join #TEMPCRITERIA C	on (C.OLDCRITERIANO =I.CRITERIANO)
		Left Join INHERITS I1	on (I1.CRITERIANO=C.CRITERIANO
					and I1.FROMCRITERIA=P.CRITERIANO)
		where I1.CRITERIANO is null

		Set @nErrorCode=@@Error
	End

	If @nErrorCode = 0
	Begin
		----------------------------------
		-- Insert records to WINDOWCONTROL
		-- and set the INHERITED flag on
		-- if parent window exists.
		----------------------------------
		Insert into WINDOWCONTROL(CRITERIANO, WINDOWNAME, ISINHERITED)
		SELECT DISTINCT C.CRITERIANO, T.WINDOWNAME, CASE WHEN(T1.WINDOWNAME is not null) THEN 1 ELSE 0 END
		FROM #TEMPWINDOWCONTROL T
		join #TEMPCRITERIA C		on ( C.OLDCRITERIANO=T.OLDCRITERIANO)
		left join INHERITS I		on ( I.CRITERIANO=C.CRITERIANO)
		left join #TEMPCRITERIA C1	on (C1.CRITERIANO=I.FROMCRITERIA)
		left join #TEMPWINDOWCONTROL T1	on (T1.OLDCRITERIANO=C1.OLDCRITERIANO
						and T1.WINDOWNAME   =T.WINDOWNAME)
		left join WINDOWCONTROL WC	on (WC.CRITERIANO=C.CRITERIANO
						and WC.WINDOWNAME=T.WINDOWNAME)
		where WC.CRITERIANO is null	-- row to be inserted must not already exist

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		--------------------------------------------
		-- Update #TEMPWINDOWCONTROL.WINDOWCONTROLNO
		-- with the value generated for the live
		-- WINDOWCONTROL row.
		--------------------------------------------

		UPDATE T 
		SET WINDOWCONTROLNO = W.WINDOWCONTROLNO 
		FROM #TEMPWINDOWCONTROL T
		join #TEMPCRITERIA C on C.OLDCRITERIANO = T.OLDCRITERIANO
		join WINDOWCONTROL W on (W.CRITERIANO = C.CRITERIANO
				     and W.WINDOWNAME = T.WINDOWNAME)
		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		------------------------------
		-- Insert 2nd topic if 
		-- frmCaseTextSummry was found
		------------------------------
		INSERT INTO #TEMPWINDOWCONTROL
		(WINDOWNAME, OLDCRITERIANO, TOPICNAME, TABTITLE, OLDSEQUENCE, WINDOWCONTROLNO)
		SELECT WINDOWNAME, OLDCRITERIANO, '2 - RelatedCases_Component', 'Related Cases', OLDSEQUENCE, WINDOWCONTROLNO
		FROM #TEMPWINDOWCONTROL 
		WHERE TOPICNAME = '1 - Case_TextTopic'

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		------------------------------
		-- Insert last topic if 
		-- frmCaseTextSummry was found
		------------------------------
		INSERT INTO #TEMPWINDOWCONTROL
		(WINDOWNAME, OLDCRITERIANO, TOPICNAME, TABTITLE, OLDSEQUENCE, WINDOWCONTROLNO)
		SELECT WINDOWNAME, OLDCRITERIANO, '3 - OfficialNumbers_Component', 'Official Numbers', OLDSEQUENCE, WINDOWCONTROLNO
		FROM #TEMPWINDOWCONTROL 
		WHERE TOPICNAME = '1 - Case_TextTopic'

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		-------------------------------
		-- Insert CaseBilling_Component
		-- tab at the end for all Case 
		-- Types
		-------------------------------
		INSERT INTO #TEMPWINDOWCONTROL
		(WINDOWNAME, OLDCRITERIANO, TOPICNAME, TABTITLE, OLDSEQUENCE, WINDOWCONTROLNO)
		SELECT DISTINCT T.WINDOWNAME, T.OLDCRITERIANO, 'CaseBilling_Component', 'Billing', 9998, T.WINDOWCONTROLNO
		FROM #TEMPWINDOWCONTROL T

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		---------------------------------------
		-- Insert BillingInstructions_Component
		-- tab at the end for all Case Types
		-- except CRM (note that CRM will not
		-- exist in #TEMPWINDOWCONTROL)
		---------------------------------------
		INSERT INTO #TEMPWINDOWCONTROL
		(WINDOWNAME, OLDCRITERIANO, TOPICNAME, TABTITLE, OLDSEQUENCE, WINDOWCONTROLNO)
		SELECT DISTINCT T.WINDOWNAME, T.OLDCRITERIANO, 'BillingInstructions_Component', 'Billing Instructions', 9999, T.WINDOWCONTROLNO
		FROM #TEMPWINDOWCONTROL T

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		-----------------------------
		-- Update SEQUENCE by copying
		-- rows to another table in 
		-- the order that they will 
		-- be sequenced
		-----------------------------
		insert into #TEMPWINDOWCONTROLSEQUENCE (ID, WINDOWCONTROLNO, OLDSEQUENCE, TOPICNAME)
		select ID, WINDOWCONTROLNO, OLDSEQUENCE, TOPICNAME
		from #TEMPWINDOWCONTROL
		ORDER BY WINDOWCONTROLNO, OLDSEQUENCE, TOPICNAME

		Set @nErrorCode=@@Error
		
		If @nErrorCode=0
		Begin
			Set @nSaveControlNo = ''

			-----------------------------
			-- The following Update will
			-- efficiently resequence the
			-- rows and reset back to 0
			-- on each change of Window.
			-----------------------------
			Update #TEMPWINDOWCONTROLSEQUENCE
			Set @nSequence= CASE WHEN(@nSaveControlNo=WINDOWCONTROLNO) 
						THEN @nSequence+1 
						ELSE 0 
					END,
			    @nSaveControlNo=WINDOWCONTROLNO,
			    NEWSEQUENCE    =@nSequence

			Set @nErrorCode=@@Error
		End
		
		If @nErrorCode=0
		Begin
			-----------------------------
			-- Now update the temp table
			-- with the new sequence.
			-----------------------------
			Update T
			Set NEWSEQUENCE=T1.NEWSEQUENCE
			from #TEMPWINDOWCONTROL T
			join #TEMPWINDOWCONTROLSEQUENCE T1 on (T1.ID=T.ID)

			Set @nErrorCode=@@Error
		End
	End

	If @nErrorCode = 0
	Begin
		-------------------------------
		-- Modify name of topics when 
		-- frmCaseTextSummry was found
		-------------------------------
		UPDATE #TEMPWINDOWCONTROL 
		SET TOPICNAME = 'Case_TextTopic' 
		WHERE TOPICNAME = '1 - Case_TextTopic'

		Set @nErrorCode = @@Error

		If @nErrorCode = 0
		Begin
			UPDATE #TEMPWINDOWCONTROL 
			SET TOPICNAME = 'RelatedCases_Component' 
			WHERE TOPICNAME = '2 - RelatedCases_Component'

			Set @nErrorCode = @@Error
		End


		If @nErrorCode = 0
		Begin
			UPDATE #TEMPWINDOWCONTROL 
			SET TOPICNAME = 'OfficialNumbers_Component' 
			WHERE TOPICNAME = '3 - OfficialNumbers_Component'

			Set @nErrorCode = @@Error
		End
	End

	If @nErrorCode = 0
	Begin
		--------------------------
		-- Delete duplicate topics
		-- and retain the one with 
		-- the lowest ID
		--------------------------
		Delete T
		from #TEMPWINDOWCONTROL T
		join (select * from #TEMPWINDOWCONTROL) T1 
				on (T1.WINDOWCONTROLNO=T.WINDOWCONTROLNO
				and T1.TOPICNAME=T.TOPICNAME)
		where T.ID>T1.ID

		Set @nErrorCode = @@Error

		If @nErrorCode=0
		Begin
			----------------------------------
			-- Delete any of the rows used for
			-- sequencing in preparation of
			-- performing a further resequence
			----------------------------------
			Delete TS
			from #TEMPWINDOWCONTROLSEQUENCE TS
			left join #TEMPWINDOWCONTROL T on (T.ID=TS.ID)
			where T.ID is null

			Set @nErrorCode=@@Error
		End
	End
		
	If @nErrorCode = 0
	Begin
		Set @nSaveControlNo = ''

		-----------------------------
		-- The following Update will
		-- efficiently resequence the
		-- rows a second time after 
		-- the deletes.
		-----------------------------
		Update #TEMPWINDOWCONTROLSEQUENCE
		Set @nSequence= CASE WHEN(@nSaveControlNo=WINDOWCONTROLNO) 
					THEN @nSequence+1 
					ELSE 0 
				END,
		    @nSaveControlNo=WINDOWCONTROLNO,
		    NEWSEQUENCE    =@nSequence

		Set @nErrorCode=@@Error
			
		If @nErrorCode=0
		Begin
			-----------------------------
			-- Now update the temp table
			-- with the new sequence.
			-----------------------------
			Update T
			Set NEWSEQUENCE=T1.NEWSEQUENCE
			from #TEMPWINDOWCONTROL T
			join #TEMPWINDOWCONTROLSEQUENCE T1 on (T1.ID=T.ID)
			Where T.NEWSEQUENCE<>T1.NEWSEQUENCE

			Set @nErrorCode=@@Error
		End
	End

	If @nErrorCode = 0
	Begin
		-------------------------------
		-- Copied from original RFC6732
		-- Not sure of reason for this.
		-------------------------------
		UPDATE #TEMPWINDOWCONTROL 
		SET TABTITLE = 'Events' 
		WHERE TOPICNAME = 'Events_Component'

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		--------------------------------------
		-- Copied from original RFC6732
		-- Not sure of reason for this.
		--------------------------------------
		-- Temporary: 
		-- REMOVE when filter of Event and 
		-- Text topics in WB is implemented
		--------------------------------------
		UPDATE #TEMPWINDOWCONTROL 
		SET TABTITLE = 'Text' 
		WHERE TOPICNAME = 'Case_TextTopic'

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		--------------------------------------
		-- Copied from original RFC6732
		-- Not sure of reason for this.
		--------------------------------------
		UPDATE #TEMPWINDOWCONTROL 
		SET TABTITLE = 'Names' 
		WHERE TOPICNAME = 'Names_Component'

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		-----------------------------------------------
		-- Insert records to TABCONTROL (NON-INHERITED)
		-----------------------------------------------
		INSERT INTO TABCONTROL (WINDOWCONTROLNO, TABNAME, DISPLAYSEQUENCE, TABTITLE, ISINHERITED)
		SELECT DISTINCT WC.WINDOWCONTROLNO, WC.TOPICNAME, isnull(WC.NEWSEQUENCE,0), WC.TABTITLE, WC.INHERITED
		FROM #TEMPWINDOWCONTROL WC
		LEFT JOIN TABCONTROL TC ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
					AND TC.TABNAME = WC.TOPICNAME)
		WHERE WC.WINDOWNAME = 'CaseDetails'
		AND WC.INHERITED = 0
		AND TC.WINDOWCONTROLNO is NULL

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		-------------------------------------------
		-- Insert records to TABCONTROL (INHERITED)
		-------------------------------------------
		INSERT INTO TABCONTROL (WINDOWCONTROLNO, TABNAME, DISPLAYSEQUENCE, TABTITLE, ISINHERITED)
		SELECT DISTINCT WC.WINDOWCONTROLNO, WC.TOPICNAME, isnull(WC.NEWSEQUENCE,0), WC.TABTITLE, WC.INHERITED
		FROM #TEMPWINDOWCONTROL WC 
		LEFT JOIN TABCONTROL TC ON (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO
					AND TC.TABNAME = WC.TOPICNAME)			
		WHERE WC.WINDOWNAME = 'CaseDetails'
		AND WC.INHERITED = 1
		AND TC.WINDOWCONTROLNO IS NULL

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		-- Turn off the ISINHERITED flag if
		-- parent  not found
		UPDATE TABCONTROL 
		SET ISINHERITED = 0
		FROM TABCONTROL T
		WHERE EXISTS (	SELECT * FROM WINDOWCONTROL W
				 WHERE W.WINDOWCONTROLNO=T.WINDOWCONTROLNO
				 and W.ISINHERITED=0)

		Set @nErrorCode = @@Error
	End
		
	If @nErrorCode = 0
	Begin
		-- Insert records to TOPICCONTROL
		INSERT INTO TOPICCONTROL (WINDOWCONTROLNO, TOPICNAME, TABCONTROLNO, ISINHERITED, ISMANDATORY, ISHIDDEN)
		SELECT  B.WINDOWCONTROLNO, B.TABNAME, B.TABCONTROLNO, B.ISINHERITED, 0, 0 
		FROM TABCONTROL B
		left join TOPICCONTROL TC	on (TC.WINDOWCONTROLNO=B.WINDOWCONTROLNO
						and TC.TOPICNAME      =B.TABNAME)
		join WINDOWCONTROL WC		on (WC.WINDOWCONTROLNO=B.WINDOWCONTROLNO)
		where TC.WINDOWCONTROLNO is null
		and   WC.NAMECRITERIANO  is null

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		--Insert records to TOPICCONTROL for New Case window
		INSERT INTO TOPICCONTROL(WINDOWCONTROLNO, TOPICNAME, ISINHERITED, ISMANDATORY, ISHIDDEN)
		SELECT DISTINCT WC.WINDOWCONTROLNO, 'Case_NamesTopic', WC.ISINHERITED, 0, 0
		FROM WINDOWCONTROL WC 
		JOIN #TEMPWINDOWCONTROL TMP	on (TMP.WINDOWCONTROLNO=WC.WINDOWCONTROLNO)
		LEFT JOIN TOPICCONTROL TC	on (TC.WINDOWCONTROLNO=WC.WINDOWCONTROLNO
						and TC.TOPICNAME      ='Case_NamesTopic')
		WHERE WC.WINDOWNAME = 'NewCaseForm'
		and   WC.NAMECRITERIANO  is null
		and   TC.WINDOWCONTROLNO is null
		AND EXISTS (	SELECT * FROM FIELDCONTROL FC
				JOIN SCREENCONTROL S	on (S.CRITERIANO = TMP.OLDCRITERIANO 
							and FC.CRITERIANO = S.CRITERIANO 
							and S.SCREENNAME = 'dlgNewCase')
				WHERE FC.FIELDNAME in ('dfInstructor','dfOwner','dfStaff') 
				and FC.ATTRIBUTES&2=2)

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		INSERT INTO ELEMENTCONTROL (TOPICCONTROLNO, ELEMENTNAME, ISMANDATORY, ISINHERITED)
		SELECT DISTINCT TC.TOPICCONTROLNO, 
			CASE FC.FIELDNAME
				WHEN 'dfInstructor' THEN 'pkInstructorName'
				WHEN 'dfOwner' THEN 'pkOwnerName'
				WHEN 'dfStaff' THEN 'pkStaffName'
			END, 1, TC.ISINHERITED
		FROM TOPICCONTROL TC
		JOIN WINDOWCONTROL WC	on (TC.WINDOWCONTROLNO = WC.WINDOWCONTROLNO 
					and WC.WINDOWNAME = 'NewCaseForm')
		JOIN #TEMPWINDOWCONTROL TMP
					on (TMP.WINDOWCONTROLNO = WC.WINDOWCONTROLNO)
		JOIN FIELDCONTROL FC	on (FC.FIELDNAME in ('dfInstructor','dfOwner','dfStaff') 
					and FC.ATTRIBUTES&2=2)
		JOIN SCREENCONTROL S	on (S.CRITERIANO = TMP.OLDCRITERIANO 
					and FC.CRITERIANO = S.CRITERIANO 
					and S.SCREENNAME = 'dlgNewCase')
		LEFT JOIN ELEMENTCONTROL EC
					on (EC.TOPICCONTROLNO=TC.TOPICCONTROLNO
					and EC.ELEMENTNAME=CASE FC.FIELDNAME
								WHEN 'dfInstructor' THEN 'pkInstructorName'
								WHEN 'dfOwner' THEN 'pkOwnerName'
								WHEN 'dfStaff' THEN 'pkStaffName'
							   END)
		WHERE TC.TOPICNAME = 'Case_NamesTopic'
		and EC.TOPICCONTROLNO is null
		and WC.NAMECRITERIANO is null

		Set @nErrorCode = @@Error
	End

	If @nErrorCode = 0
	Begin
		-----------------------------------
		-- Insert hidden topics or fields 
		-- for Case Name Maintenance window
		-----------------------------------

		----------------------------------------------
		-- Load a WINDOWCONTROL row under which we can
		-- attach a TOPICCONTROL for each NAMETYPE to 
		-- be hidden
		----------------------------------------------	 
		INSERT INTO WINDOWCONTROL(CRITERIANO, WINDOWNAME, ISINHERITED)		
		SELECT DISTINCT C.CRITERIANO, 'CaseNameMaintenance', isnull(SC.INHERITED,0)
		FROM #TEMPWINDOWCONTROL WC
		join #TEMPCRITERIA C on (C.OLDCRITERIANO=WC.OLDCRITERIANO)
		join (	select CRITERIANO, max(INHERITED) as INHERITED
			from SCREENCONTROL
			group by CRITERIANO) SC on (SC.CRITERIANO=WC.OLDCRITERIANO)

		join (	select CRITERIANO, count(*) as UsedNameTypes
			from dbo.fn_ScreenCriteriaNameTypesDetails(default)
			group by CRITERIANO) NT1 on (NT1.CRITERIANO=WC.OLDCRITERIANO)
		cross join 
		     (	select count(*) as TotalNameTypes
			from NAMETYPE) NT2
		WHERE WC.WINDOWNAME = 'CaseDetails'
		and isnull(NT1.UsedNameTypes,0)<NT2.TotalNameTypes

		Select @nErrorCode=@@Error,
			@nRowCount=@@Rowcount

		If  @nErrorCode=0
		and @nRowCount >0
		Begin
			Insert into TOPICCONTROL (WINDOWCONTROLNO, TOPICNAME, ISHIDDEN, FILTERNAME, FILTERVALUE, ISINHERITED, ISMANDATORY)
			select distinct W.WINDOWCONTROLNO, 'CaseNameTopic_' + Cast(N.NAMETYPEID as varchar),1, 'NameTypeCode', N.NAMETYPE, W.ISINHERITED, 0
			FROM #TEMPWINDOWCONTROL T
			join #TEMPCRITERIA C	on (C.OLDCRITERIANO=T.OLDCRITERIANO)
			join WINDOWCONTROL W	on (W.CRITERIANO   =C.CRITERIANO
						and W.WINDOWNAME   ='CaseNameMaintenance')
			cross join NAMETYPE N
			left  join dbo.fn_ScreenCriteriaNameTypesDetails(default) NT
						on (NT.CRITERIANO=T.OLDCRITERIANO
						and NT.NAMETYPE  =N.NAMETYPE)
			left join TOPICCONTROL TC	
						on (TC.WINDOWCONTROLNO=W.WINDOWCONTROLNO
						and TC.TOPICNAME      ='CaseNameTopic_' + Cast(N.NAMETYPEID as varchar))
			WHERE T.WINDOWNAME = 'CaseDetails'
			and W.NAMECRITERIANO   is null
			and TC.WINDOWCONTROLNO is null
			and NT.NAMETYPE is null -- Nametype did not exist in ScreenControl
			and(N.COLUMNFLAGS>0 OR (N.COLUMNFLAGS=0 and Cast(N.PICKLISTFLAGS & 2 as bit) = 0))
		
			Set @nErrorCode = @@Error

			If @nErrorCode = 0
			Begin
				-----------------------------
				-- Load a topic for the Staff
				-----------------------------
				insert into TOPICCONTROL (WINDOWCONTROLNO, TOPICNAME, ISINHERITED, ISMANDATORY)
				select distinct W.WINDOWCONTROLNO, 'Case_StaffTopic',W.ISINHERITED, 1
				FROM #TEMPWINDOWCONTROL T
				join #TEMPCRITERIA C	on (C.OLDCRITERIANO=T.OLDCRITERIANO)
				join WINDOWCONTROL W	on (W.CRITERIANO   =C.CRITERIANO
							and W.WINDOWNAME   ='CaseNameMaintenance')
				left join TOPICCONTROL TC	
							on (TC.WINDOWCONTROLNO=W.WINDOWCONTROLNO
							and TC.TOPICNAME      ='Case_StaffTopic')
				WHERE T.WINDOWNAME = 'CaseDetails'
				and TC.WINDOWCONTROLNO is null
				and W.NAMECRITERIANO   is null
				and exists
				(select 1
				 from NAMETYPE N
				 left  join dbo.fn_ScreenCriteriaNameTypesDetails(default) NT
							on (NT.CRITERIANO=T.OLDCRITERIANO
							and NT.NAMETYPE  =N.NAMETYPE)
				 where NT.NAMETYPE is null			-- Nametype did not exist in ScreenControl
				 and N.COLUMNFLAGS=0				-- All columns are off
				 and Cast(N.PICKLISTFLAGS & 2 as bit) = 1)	-- Staff picklist is on

				Select @nErrorCode = @@Error,
					@nRowCount = @@Rowcount

				If @nErrorCode = 0
				and @nRowCount > 0
				Begin
					--------------------------------
					-- Now create the ELEMENTCONTROL 
					-- to hide the Name picklist
					--------------------------------
					insert into ELEMENTCONTROL (TOPICCONTROLNO, ELEMENTNAME, ISHIDDEN, FILTERNAME, FILTERVALUE, ISINHERITED)
					select distinct TC.TOPICCONTROLNO, 'pkName_' + Cast(N.NAMETYPEID as varchar),1, 'NameTypeCode', N.NAMETYPE, TC.ISINHERITED
					FROM #TEMPWINDOWCONTROL T
					join #TEMPCRITERIA C	on (C.OLDCRITERIANO=T.OLDCRITERIANO)
					join WINDOWCONTROL W	on (W.CRITERIANO   =C.CRITERIANO
								and W.WINDOWNAME   ='CaseNameMaintenance')
					join TOPICCONTROL TC	on (TC.WINDOWCONTROLNO=W.WINDOWCONTROLNO
								and TC.TOPICNAME='Case_StaffTopic')
					cross join NAMETYPE N
					left  join dbo.fn_ScreenCriteriaNameTypesDetails(default) NT
								on (NT.CRITERIANO=T.OLDCRITERIANO
								and NT.NAMETYPE  =N.NAMETYPE)
					left join ELEMENTCONTROL EC
								on (EC.TOPICCONTROLNO=TC.TOPICCONTROLNO
								and EC.ELEMENTNAME='pkName_' + Cast(N.NAMETYPEID as varchar))			
					WHERE T.WINDOWNAME = 'CaseDetails'
					and W.NAMECRITERIANO  is null
					and EC.TOPICCONTROLNO is null
					and NT.NAMETYPE is null				-- Nametype did not exist in ScreenControl
					 and N.COLUMNFLAGS=0				-- All columns are off
					 and Cast(N.PICKLISTFLAGS & 2 as bit) = 1	-- Staff picklist is on

					Set @nErrorCode = @@Error
				End
			End
		End
	End

	-----------------------------------------
	-- Copy details into TOPICDEFAULTSETTINGS
	-----------------------------------------
	If @nErrorCode=0
	Begin
		-------------
		-- CaseAction
		-------------
		INSERT INTO TOPICDEFAULTSETTINGS (CRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE)
		select
			distinct MAP.CRITERIANO, 'Actions_Component', 'CaseAction', SC.CREATEACTION
		from
			SCREENCONTROL SC
			join #TEMPCRITERIA MAP on MAP.OLDCRITERIANO = SC.CRITERIANO
		where
			SC.CREATEACTION is not null
		and	SC.SCREENNAME = 'frmCaseHistory'
		and	SC.ENTRYNUMBER is null

		Set @nErrorCode = @@Error
	End

	If @nErrorCode=0
	Begin
		----------------
		-- NewCaseAction
		----------------
		INSERT INTO TOPICDEFAULTSETTINGS (CRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE)
		select
			distinct MAP.CRITERIANO, 'Actions_Component', 'NewCaseAction', SC.CREATEACTION
		from
			SCREENCONTROL SC
			join #TEMPCRITERIA MAP on MAP.OLDCRITERIANO = SC.CRITERIANO
		where
			SC.CREATEACTION is not null
		and	SC.SCREENNAME = 'frmCaseHistory'
		and	SC.ENTRYNUMBER is null

		Set @nErrorCode = @@Error
	End

	If @nErrorCode=0
	Begin
		------------
		-- NameTypes
		------------

		----------------------------------------------------------------
		-- RFC6547
		-- Ensure any screen criterion with mandatory name types 
		-- will have the Name step when creating a Case.
		--
		-- Find all criteria where CaseNameMaintenance has been defined, 
		-- and locate if there are any default settings to be inserted.
		----------------------------------------------------------------
		
		Insert TOPICDEFAULTSETTINGS (CRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE)
		Select	distinct WC.CRITERIANO, 'Case_NamesTopic', 'CaseNameStepDisplaySequence', ISNULL(MaxDisplaySequence,0)+1
		from	WINDOWCONTROL WC 
		left join (
			-- get largest display sequence from the topic default settings of this criteria
			Select	CRITERIANO, MAX(cast(FILTERVALUE as int)) as MaxDisplaySequence
			from	TOPICDEFAULTSETTINGS
			where	FILTERNAME like '%DisplaySequence' 
			group by CRITERIANO) TDSMax on (TDSMax.CRITERIANO = WC.CRITERIANO)
		where 	WC.CRITERIANO is not null
		and exists (
			-- any of the name types applicable for this screen criterion is mandatory
			Select * 
			from NAMETYPE NT
			join dbo.fnw_ScreenCriteriaNameTypes(WC.CRITERIANO) SNT on (SNT.NAMETYPE = NT.NAMETYPE and NT.MANDATORYFLAG = 1)
		) 
		and not exists (
			-- the topic default settings for name step for this criteria already exists
			Select	* 
			from	TOPICDEFAULTSETTINGS TDS
			where	TDS.CRITERIANO = WC.CRITERIANO
			and	TDS.FILTERNAME = 'CaseNameStepDisplaySequence'
			and	TDS.TOPICNAME  = 'Case_NamesTopic'
		)

		Set @nErrorCode = @@Error
	End

	If @nErrorCode=0
	Begin
		----------------
		-- Relationships
		----------------

		INSERT INTO TOPICDEFAULTSETTINGS (CRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE)
		select
			distinct MAP.CRITERIANO, 'Case_RelatedCaseTopic', 'CaseRelatedCases', SC.RELATIONSHIP
		from
			SCREENCONTROL SC
			join #TEMPCRITERIA MAP on MAP.OLDCRITERIANO = SC.CRITERIANO
		where
			SC.SCREENNAME = 'frmRelationships' 
		and	SC.RELATIONSHIP is not null

		Set @nErrorCode = @@Error

		If @nErrorCode=0
		Begin
			Insert TOPICDEFAULTSETTINGS (CRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE)
			select	distinct WC.CRITERIANO, 'Case_RelatedCaseTopic', 'CaseRelatedCasesDisplaySequence', ISNULL(MaxDisplaySequence,0)+1
			from	WINDOWCONTROL WC 
			left join (
				-- get largest display sequence from the topic default settings of this criteria
				Select	CRITERIANO, MAX(cast(FILTERVALUE as int)) as MaxDisplaySequence
				from	TOPICDEFAULTSETTINGS
				where	FILTERNAME like '%DisplaySequence' 
				group by CRITERIANO) TDSMax on (TDSMax.CRITERIANO = WC.CRITERIANO)
			where 	WC.CRITERIANO is not null
				and not exists (
					-- the topic default settings for name step for this criteria already exists
					Select	* 
					from	TOPICDEFAULTSETTINGS TDS
					where	TDS.CRITERIANO = WC.CRITERIANO
					and	TDS.FILTERNAME = 'CaseRelatedCasesDisplaySequence'
					and	TDS.TOPICNAME  = 'Case_RelatedCaseTopic'
				)
				and exists (
					-- the topic default settings for name step for this criteria already exists
					Select	* 
					from	TOPICDEFAULTSETTINGS TDS
					where	TDS.CRITERIANO = WC.CRITERIANO
					and	TDS.FILTERNAME = 'CaseRelatedCases'
					and	TDS.TOPICNAME  = 'Case_RelatedCaseTopic'
				)

			Set @nErrorCode = @@Error
		End
	End

	If @nErrorCode=0
	Begin
		----------
		-- Classes
		----------

		INSERT INTO TOPICDEFAULTSETTINGS (CRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE)
		select
			distinct MAP.CRITERIANO, 'Case_ClassesTopic', 'CaseClasses', 'TRUE'
		from
			SCREENCONTROL SC
			join FIELDCONTROL FC on FC.CRITERIANO = SC.CRITERIANO AND SC.SCREENNAME = FC.SCREENNAME AND SC.SCREENID = FC.SCREENID
			join #TEMPCRITERIA MAP ON MAP.OLDCRITERIANO = SC.CRITERIANO
		where
			SC.SCREENNAME = 'frmClasses'
			and FC.FIELDNAME = 'dfClass'

		Set @nErrorCode = @@Error

		If @nErrorCode=0
		Begin
			Insert TOPICDEFAULTSETTINGS (CRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE)
			select	distinct WC.CRITERIANO, 'Case_ClassesTopic', 'CaseClassesDisplaySequence', ISNULL(MaxDisplaySequence,0)+1
			from	WINDOWCONTROL WC 
			left join (
				-- get largest display sequence from the topic default settings of this criteria
				Select	CRITERIANO, MAX(cast(FILTERVALUE as int)) as MaxDisplaySequence
				from	TOPICDEFAULTSETTINGS
				where	FILTERNAME like '%DisplaySequence' 
				group by CRITERIANO) TDSMax on (TDSMax.CRITERIANO = WC.CRITERIANO)
			where 	WC.CRITERIANO is not null
				and not exists (
				-- the topic default settings for name step for this criteria already exists
				Select	* 
				from	TOPICDEFAULTSETTINGS TDS
				where	TDS.CRITERIANO = WC.CRITERIANO
				and		TDS.FILTERNAME = 'CaseClassesDisplaySequence'
				and		TDS.TOPICNAME = 'Case_ClassesTopic'
			)
				and exists (
				Select	* 
				from	TOPICDEFAULTSETTINGS TDS
				where	TDS.CRITERIANO = WC.CRITERIANO
				and	TDS.FILTERNAME = 'CaseClasses'
				and	TDS.TOPICNAME  = 'Case_ClassesTopic'
			)

			Set @nErrorCode = @@Error
		End

		If @nErrorCode=0
		Begin
			INSERT INTO TOPICDEFAULTSETTINGS (CRITERIANO, TOPICNAME, FILTERNAME, FILTERVALUE)
			select
				distinct MAP.CRITERIANO, 'Case_ClassesTopic', 'CaseClasses', 'FALSE'
			from
				#TEMPCRITERIA MAP
			where
				not exists (
					-- the topic default settings for name step for this criteria already exists
					Select	* 
					from	TOPICDEFAULTSETTINGS TDS
					where	TDS.CRITERIANO = MAP.CRITERIANO
					and	TDS.FILTERNAME = 'CaseClassesDisplaySequence'
					and	TDS.TOPICNAME  = 'Case_ClassesTopic'
				)

			Set @nErrorCode = @@Error
		End
	End
	
	-------------------------------------
	-- Commit or Rollback the transaction
	-------------------------------------
	If @@TranCount > @nTranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End

End

Return @nErrorCode
GO

Grant execute on dbo.ipu_UtilLoadWindowsControl to public
GO