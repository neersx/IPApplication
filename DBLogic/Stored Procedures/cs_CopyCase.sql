-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CopyCase
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_CopyCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	 Print '**** Drop Stored Procedure dbo.cs_CopyCase.'
	 Drop procedure [dbo].[cs_CopyCase]
End
Print '**** Creating Stored Procedure dbo.cs_CopyCase...'
Print ''
go

SET QUOTED_IDENTIFIER off
go

CREATE PROCEDURE dbo.cs_CopyCase
(
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@psCaseKey			nvarchar(11),	-- Mandatory
	@psProfileName			nvarchar(50),	-- Mandatory
	@psNewCaseKey			nvarchar(11)	output,
	@psCaseFamilyReference		nvarchar(20)	= null,
	@psCountryKey			nvarchar(3)	= null,
	@psCountryName			nvarchar(60)	= null,
	@psCaseCategoryKey		nvarchar(2)	= null,
	@psCaseCategoryDescription	nvarchar(50)	= null,
	@psSubTypeKey			nvarchar(2)	= null,
	@psSubTypeDescription		nvarchar(50)	= null,
	@psBasisKey                     nvarchar(4)     = null,
	@psCaseStatusKey		nvarchar(10)	= null,
	@psCaseStatusDescription	nvarchar(50)	= null,
	@psApplicationNumber		nvarchar(36)	= null,
	@pdtApplicationDate		datetime	= null,
	@pnNoOfClasses			int		= null,
	@psLocalClasses			nvarchar(254)	= null,
	@psIntClasses			nvarchar(254)	= null,
	@psRelationshipKey		nvarchar(10)	= null,
	@psPropertyTypeKey		nvarchar(2)	= null,
	@psShortTitle                   nvarchar(508)   = null,
	@pnPolicingBatchNo		int		= null,
	@psCaseReference		nvarchar(30)	= '<Generate Reference>', -- the Case Reference for the new case
	@pnOfficeKey                    int             = null,
	@pbDebug			bit		= 0,
	@psSequenceNumbers		nvarchar(100)	= null,
	@psStem				nvarchar(30)    = null,
	@psXmlCaseCopyData              nvarchar(max)	= null,
        @pnInstructorKey                int             = null,
        @pnOwnerKey                     int             = null,
        @pnStaffKey                     int             = null,
        @psProfitCentreCode		nvarchar(6)	= null,
	@psProgramId			nvarchar(8)	= null,
	@psCaseTypeKey			nvarchar(2)	= null
)
as
-- PROCEDURE :	cs_CopyCase
-- VERSION :	94
-- DESCRIPTION:	See cs_CopyCase.doc for details
-- NOTES:	The automatic procecessing does not take any account of NUMIERICKEY
-- COPYRIGHT:	Copyright 1993 - 2019 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	-----------------------------------------------
-- 23/07/2002	JB			Procedure created
-- 26/07/2002	SF			fnDateOnly should have been fn_DateOnly
-- 27/07/2002	SF			Comment application event creation due to conflict.
-- 30/07/2002	JB			Moved last policing request to before the COMMIT
--					Modified @tPolicingRequest loop to use identity column
-- 31/07/2002	JB			Various bug fixes. When @pbDebug = 1 print messages
-- 07/08/2002	SF			Added @pbProcessPriorityEvent output from cs_InsertRelatedCase
-- 08/08/2002	SF			Policing OnHold Flag incorrectly switched.
-- 13/08/2002	SF			1. (Bug 167) Insert Case Event using straight insert.
--					2. Case Location Implemented (rev 0.3)
-- 22-OCT-2002	JB		15	Modifications for row level security
-- 23 Oct 2002	JEK		16	Raise an error if multiple classes are copied to a single class country.
-- 25 Oct 2002	JB		17	Now using cs_GetSecurityForCase
-- 02 DEC 2002	SF		20	Implement new parameters to allow a single class to be copied (338).
-- 24 FEB 2003	SF	RFC57	21	Change @psCaseFamilyReference to size 20.
-- 25 FEB 2003	SF	RFC37	22	Add @pnPolicingBatchNo
-- 10 MAR 2003	JEK	RFC82	23	Localise stored procedure errors.
-- 17 MAR 2003	SF	RFC84	24	1. remove unnecessary parameters from the call to ip_InsertPolicing
--					2. remove police Immediately sitecontrol lookup
-- 25 Mar 2003	JEK	RFC37	25	Policing rows were not being written because the code
--					was incorrectly checking on old RowCount variable.
-- 28 Mar 2003	JEK		26	Adjust to call the new cs_InsertCaseEvent interface from RFC03 case workflow.
-- 02 May 2003	JEK	RFC121	27	Default case names from copied names.
-- 05 May 2003	JEK		28	Correct syntax
-- 22 May 2003  TM      RFC179	29      Name Code and Case Family Case Sensitivity
-- 26 Jun 2003	JEK	RFC250	30	Implemented @psCaseReference for automation of Maxim case creation.
-- 14 Jun 2003	TM	RFC26	31	Remove the existing logic to generate a dummy case reference. Implement the new cs_ApplyGeneratedReference instead of cs_GenerateCaseReference.
-- 18 Aug 2004	AB		32	Add collate database_default syntax to temp tables.
-- 27 May 2005	TM	RFC2584	33	Any CopyProfile rules where StopCopy = 1 should be excluded.
-- 07 Jul 2005	TM	RFC2329	34	Increase the size of all case category parameters and local variables to 2 characters.
-- 19 May 2006	IB	RFC3690	35	Derive case name attention.
-- 29 Jun 2006	IB	RFC4058	36	insert Goods and Services CASETEXT only if it does not exist already.
-- 					After insert update CASETEXT rows with �G� TEXTTYPE and no language
--					specified for the new case from the CASETEXT rows for the existing case.
-- 16 Jan 2007	SF	RFC4869	37	When inserting CASETEXT rows with 'G' TEXTTYPE generate the TEXTNO (SQA10856,SQA12913,SQA14009)
-- 26 Apr 2007	JS	14323	38	Pass new parameter NameType to fn_GetDerivedAttnNameNo.
-- 19 Nov 2007	LP	RFC5704	39	Added @psSequenceNumbers parameter to allow selection of case information to copy
-- 06 Feb 2008	LP	RFC3210	40	Added @psRelationshipKey parameter to insert new related case for parent case
-- 04 Jun 2008	LP	RFC6694	41	Insert Policing request for CREATEACTION
-- 03 Jul 2008	LP	RFC6754	42	Added @psPropertyTypeKey parameter to use Property Type specified
--					Added @psBasisKey parameter to use Application Basis specified
--					Added @psShortTitle parameter to use Short Title specified
-- 11 Dec 2008	MF	17136	43	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 29 Jan 2009  LP      R6373	44      Add @psXmlCaseCopyData to determine attributes to copy into the new case
-- 21 Sep 2009  LP      R8047	45      Pass ProfileKey parameter to fn_GetCriteriaNo
-- 05 Jan 2010  ASH     R8756	46      Open the default action even if the Copy Profile does not contain a Create Action attribute.
-- 24 Mar 2010  ASH     R100210 47	Correct the condition to insert a row in Policing table when @sAction is not equal to null.
-- 26 Jul 2010	LP	R9603	48	Do not insert Related Case if CASEID is null.
-- 29 Jul 2010	LP	R9619	49	Ensure policing request is inserted for newly created case when called from the Web Version.
-- 10 Aug 2010	LP	R9619	50	Fix issue with policing request not being created for new national phase cases.
-- 11 Oct 2010	LP	R100353	51	If Application Filing Date is to be copied, retrieve Application Date if not specified by caller.
-- 22 Oct 2010	LP	R100353	52	Do not copy case events that have not been selected by the copy profile or the user.
-- 09 Nov 2010	LP	R9936	53	Fix issue with action not being opened for newly created cases.
-- 24 Jan 2011  LP	R10185 	54	Remove code that forces Application Filing Date to be copied all the time.
-- 22 Feb 2011  LP	R9933 	55      Add @pnOfficeKey parameter to use as CaseOfficeId
-- 23 Feb 2011	DV	R10188 	56	Added a new @psStem parameter to be entered into the case.
-- 04 Mar 2011  MS      R100469	57	Add new parameters @pnInstructorKey, @pnOwnerKey and @pnStaffKey.
-- 16 May 2011  DV      R10640	58	Pass the @pnParentCaseKey to the stored procedure cs_ApplyGeneratedReference if @psStem is not null.
-- 13 Jul 2011	MF	R10973	59	Events that are not intended to be copied are also being copied. This was because the COPYPROFILE
--					table was not being filter by the supplied @psProfileName.
-- 24 Aug 2011  LP      R11212	60	Remove code that forces Application Filing Date to be copied all the time.
--						Events that are not intended to be copied are also being copied. This was because the COPYPROFILE
--						table was not being filter by the supplied @psProfileName.
-- 24 Oct 2011	ASH	R11460  61	Cast integer columns as nvarchar(11) data type.
-- 16 Dec 2011	LP	R11686	62	Ensure Events associated with reciprocal relationships are created against the new case.
--					Corresponding policing request rows must also be created for the above events.
-- 06 Jan 2012  DV      R11753  63      Fix issue where Case Images and Text was not getting copied.
-- 09 Jan 2012	MF	R11770	64	Calls to cs_UpdatePriorityEvents should pass the @pnPolicingBatchNo parameter.
-- 12 Jan 2012	LP	R11753	65	Allow customised Goods & Services text to be copied from parent instead of default class headings.
--					This was previously not happening if the copy profile does not have Goods & Services text available.
-- 15 Feb 2012	LP	R100678	66	Correct logic when creating case names based on COPYPROFILE.REPLACEMENTDATA
-- 23 Feb 2012	LP	R11726	67	Transaction now managed from the calling code. Remove TRANSACTION logic from this stored procedure.
-- 10 May 2012	LP	R11274	68	Corrected issue with Case Text and Case Images not being copied from parent case (RFC11753).
-- 21 jun 2012	DV	R100727 69	Removed duplicate @pnOfficeKey being sent to cs_CopyCaseGenInsertSQL
-- 29 Oct 2012	ASH	R12838	70	Fix issue with FILELOCATION not being copied for newly created case.
-- 26 Jul 2012	ASH	R12456	70	Delete default Text from New Case if it's not present in parent Case Class.
-- 12 Dec 2012	MF	R13017	71	After copy related case details from the copy from case, no considerations was being give as to whether
--					CaseEvent rows should be inserted/updated as a result of these relationships. The code to do this already
--					existed in the stored procedure cs_UpdatePriorityEvents however this stored procedure was not being called
--					in some situations when it should have been. The code has also be restructured to correct this.
-- 15 Apr 2013	DV	R13270	72	Increase the length of nvarchar to 11 when casting or declaring integer
-- 13 Jun 2013	AK	DR66	73	Increase the length of nvarchar to 254 of @psLocalClasses and @psIntClasses
-- 01 May 2014	KR	R13937	74	Modified the message displayed when no access profile setup to be in line with the csw_InsertCase
-- 06 May 2013	MS	R33700	75	Increase the length of nvarchar to 254 of @psLocalClasses and @psIntClasses
-- 18 Jul 2014	SF	R37446	76	Pass parent case in when generating reference
-- 22 Jul 2014	AT	R37446	77	Remove redundant check for parent stem when generating reference (Tech debt for 8.0.9).
-- 22 Sep 2014	MF	R39652	78	SQL Error when inserting Goods/Services text that does not have an associated class.
-- 20 Oct 2015	DV	R43744	79	Copy the Instructions if selected
-- 20 Jan 2016	MF	R55493	80	Cater for PROFITECENTRECODE column to be copied for CASES.
-- 02 Mar 2016	MF	R57708	81	When generating an IRN by calling cs_ApplyGeneratedReference, only pass the @pnParentCaseKey
--					if there is an explicit relationship being used to link the new case to the case being copied from.
-- 24 Aug 2016	MF	62043	82	Cater for TABLEATTRIBUTE rows to be copied.
-- 21 Jul 2017	MF	72007	83	The screen control rules for the Web should be considered instead of client/server when determining Action.
-- 14 Aug 2017	MF	72126	84	Failed testing on 72007.
-- 21 Jul 2017	MF	72007	83	The screen control rules for the Web should be considered instead of client/server when determining Action.
-- 14 Aug 2017	MF	72126	84	Failed testing on 72007.
-- 18 Oct 2017	LP	R40875	85	Use current logical program when deriving the action to open for the new case.
-- 24 Oct 2017	AK	R72645	86	Make compatible with case sensitive server with case insensitive database.
-- 05 Mar 2018  MS  R57162  87  Call priorityEventUpdate for new case after case reference generation to avoid policing row clash
-- 09 Oct 2018	DV	R74977	88	Copy Class Items if the classes are being copied.
-- 04 Sep 2019  LP  DR-49070 89 Title of Related Cases are propagated to the new Case Relationships
-- 10 Sep 2019	AK	DR18774	90	added additonal parameter casetype.
-- 28 Oct 2019	vql	DR52932	91	When copying cases, not all Name Types are being defaulted correctly.
-- 04 Feb 2020	MS	DR54941	92	Retain Instructor, Owner and Staffname if provided and their copy area is not selected.
-- 24 Mar 2020	LP	DR57760	93	Copy Case Checklist answers where specified.
-- 19 May 2020	DL	DR-58943 94	Ability to enter up to 3 characters for Number type code via client server	

------------
-- Settings
Set nocount on
Set concat_null_yields_null off

-- -----------------
-- Local variables
Declare @nErrorCode 		int
Declare @nRowCount 		int
Declare @nRelatedCaseCount	int
Declare @nCounter		int
Declare @nAttribRowCount        int

Declare @sRelatedCaseKey	nvarchar(11)
Declare @sRecipRelationship	nvarchar(3)
Declare	@sProgramId		nvarchar(8)

Declare @bProcessPriorityEvent	bit
Declare @bHasInsertRights	bit

Declare @dtToday 		datetime

Declare @nCaseKey		int		-- Orig case CASEID
Declare @nNewCaseKey		int		-- New case CASEID
Declare	@nParentCaseKey		int
Declare @nProfileKey            int

Declare @sAlertXML 		nvarchar(400)
Declare @idoc                   int
Declare @sRowPattern            nvarchar(100)

Declare @tblCaseCopyAttrib table (
				ATTRIBIDENTITY	        int		IDENTITY,
				PROFILENAME		nvarchar(100)	collate database_default,
				COPYAREA		nvarchar(60)	collate database_default,
		      		COPYAREAKEY	        nvarchar(20)	collate database_default,
		      		REPLACEDATA	        nvarchar(508)	collate database_default)

Declare @tReciprocal table (	IDENT			int		IDENTITY(1,1),
				RELATEDCASEID 		int,
				RECIPRELATIONSHIP	nvarchar(3)	collate database_default )

Declare @sSQLString nvarchar(max)

-- Initialise local variables

Set @nErrorCode = 0
Set @nRowCount = 0
Set @dtToday = dbo.fn_DateOnly(GETDATE())

-- Create a temp table from the specified attributes to be copied
Set @nAttribRowCount = 0
Set @sRowPattern = "//CaseCopyData/CopyData"
If @nErrorCode = 0
Begin

        exec sp_xml_preparedocument	@idoc OUTPUT, @psXmlCaseCopyData

        Insert into @tblCaseCopyAttrib
        Select	*
        from	OPENXML (@idoc, @sRowPattern, 2)
        WITH (
              PROFILENAME	        nvarchar(100)	'ProfileName/text()',
              COPYAREA		        nvarchar(60)	'CopyArea/text()',
              COPYAREAKEY		nvarchar(20)	'CopyAreaKey/text()',
              REPLACEDATA		nvarchar(508)	'ReplaceData/text()'
             )
        Set @nAttribRowCount = @@RowCount

        exec sp_xml_removedocument @idoc

        Set @nErrorCode=@@Error
End

If @pbDebug = 1
Begin
	select * from @tblCaseCopyAttrib
End

Set @psCaseFamilyReference = upper(@psCaseFamilyReference)	--Ensure case family reference is upper case

If @nErrorCode = 0
   and @nAttribRowCount > 0
Begin
        Set @psSequenceNumbers = NULL
End

-- Get ProfileKey of the current user
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId

        Set @nErrorCode = @@ERROR
End
-- -----------
-- Min Data

If @psCaseKey is null OR @psCaseKey = ''
	Set @nErrorCode = -1

Set @nCaseKey = Cast(@psCaseKey as int)

-- ----------------
-- Create Family
If @nErrorCode = 0 and @psCaseFamilyReference is not null
	and @psCaseFamilyReference != ''
	and not exists	(	Select *
				from CASEFAMILY
				where FAMILY = @psCaseFamilyReference
			)
Begin
	Insert into CASEFAMILY (FAMILY) values (@psCaseFamilyReference)
	Set @nErrorCode = @@ERROR
End

-- ------------------
-- Data preperation

If @nErrorCode = 0
Begin
	Exec @nErrorCode = ip_GetLastInternalCode
		@pnUserIdentityId,
		@psCulture,
		'CASES',
		@nNewCaseKey output
	Set @psNewCaseKey = CAST(@nNewCaseKey as nvarchar(11))
End

-- -------------
-- Insert Case

If @nErrorCode = 0
Begin
	Declare @psSql	nvarchar(4000)
	Declare @sSql	nvarchar(4000)
	Exec @nErrorCode = cs_CopyCaseGenInsertSQL
		@pnUserIdentityId 	= @pnUserIdentityId,
		@psCulture		= @psCulture,
		@psProfileName		= @psProfileName,
		@psCopyArea		= 'CASES',
		@psSql			= @sSql output,
		@pnOrigCaseId		= @nCaseKey,
		-- The following parameters only need to be passed for CASES
		@pnNewCaseKey		= @nNewCaseKey,
		@psNewCaseIrn		= @psCaseReference,
		@psCaseFamilyReference	= @psCaseFamilyReference,
		@psCountryKey		= @psCountryKey,
		@psPropertyTypeKey	= @psPropertyTypeKey,
		@psCaseCategoryKey	= @psCaseCategoryKey,
		@psSubTypeKey		= @psSubTypeKey,
		@psCaseStatusKey	= @psCaseStatusKey,
		@psShortTitle   	= @psShortTitle,
		@psLocalClasses		= @psLocalClasses,
		@psIntClasses		= @psIntClasses,
		@pnNoOfClasses		= @pnNoOfClasses,
		@psSequenceNumbers	= @psSequenceNumbers,
		@pnOfficeKey		= @pnOfficeKey,
		@psStem			= @psStem,
		@psProfitCentreCode	= @psProfitCentreCode,
		@psXmlCaseCopyData      = @psXmlCaseCopyData,
		@PsCaseTypeKey = @PsCaseTypeKey

	If @nErrorCode = 0
		Exec @nErrorCode = sp_executesql @sSql
	Else
		-- This is an acceptable error
		If @nErrorCode = -1
			Set @nErrorCode = 0
End

-- -----------
-- Property

If @nErrorCode = 0
Begin
	Exec @nErrorCode = cs_CopyCaseGenInsertSQL
	        @pnUserIdentityId 	= @pnUserIdentityId,
	        @psCulture		= @psCulture,
	        @psProfileName		= @psProfileName,
	        @psCopyArea		= 'PROPERTY',
	        @psSql 			= @sSql output,
	        @pnOrigCaseId		= @nCaseKey,
	        @pnNewCaseKey		= @nNewCaseKey,
	        @psBasisKey             = @psBasisKey,
	        @pnOfficeKey            = @pnOfficeKey,
	        @psSequenceNumbers	= @psSequenceNumbers,
	        @psXmlCaseCopyData      = @psXmlCaseCopyData

        If @nErrorCode = 0
        Begin
	        Exec @nErrorCode = sp_executesql @sSql
	End
        Else
        Begin
        -- This is an acceptable error
                If @nErrorCode = -1
                Begin
	                Set @nErrorCode = 0
	        End
	End
End

-- ------------
-- Key Words

If @nErrorCode = 0
Begin
        If (@nAttribRowCount > 0
               and exists (Select 1
			From @tblCaseCopyAttrib TAB
			left join COPYPROFILE C	on (C.COPYAREA=TAB.COPYAREA
						and C.PROFILENAME = @psProfileName)
			where TAB.COPYAREA like '%CASEWORDS'
			and isnull(C.STOPCOPY,0)=0 ))
	       or exists
		(Select 1
			From COPYPROFILE C
			join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
			where PROFILENAME = @psProfileName
			and COPYAREA = 'CASEWORDS'
			and isnull(C.STOPCOPY,0)=0)
	Begin
		-- Copy Key Words from parent if necessary
		Insert into CASEWORDS (CASEID, KEYWORDNO, FROMTITLE)
			Select @nNewCaseKey, KEYWORDNO, FROMTITLE
				from CASEWORDS where CASEID = @nCaseKey
		Set @nErrorCode = @@ERROR
	End
	Else
	Begin
		-- Create keywords from title if necessary
		If exists(Select * from CASES
			where CASEID = @nNewCaseKey
			and LEN(TITLE) > 0)
		Begin
			Exec @nErrorCode = cs_InsertKeyWordsFromTitle @nNewCaseKey
		End
	End
End

--------------------
-- Case Location
If @nErrorCode = 0
Begin
        If (@nAttribRowCount > 0
                and exists (Select 1
			From @tblCaseCopyAttrib TAB
			left join COPYPROFILE C	on (C.COPYAREA=TAB.COPYAREA
						and C.PROFILENAME = @psProfileName)
			where TAB.COPYAREA like '%CASELOCATION'
			and isnull(C.STOPCOPY,0)=0 ))
	        or exists
	        (select *
		        From COPYPROFILE C
		        join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
		        where 	PROFILENAME = @psProfileName
		        and	COPYAREA = 'CASELOCATION'
		        and    (STOPCOPY = 0
		        or      STOPCOPY is null))
        begin
	        insert into CASELOCATION
		        (CASEID, WHENMOVED, FILELOCATION)
		        select 	@nNewCaseKey, getdate(), FILELOCATION
			        from	CASELOCATION CL
			        where	CL.CASEID = @nCaseKey
			        and	CL.WHENMOVED = (select max(CL1.WHENMOVED)
						        from 	CASELOCATION CL1
						        where 	CL1.CASEID = CL.CASEID)


	        set @nErrorCode = @@ERROR
        end
End


--------------------
-- Table Attributes
If @nErrorCode = 0
Begin
        Declare @tTableTypes table (NUMERICKEY int)

        If (@nAttribRowCount > 0
                and exists (Select 1
			From @tblCaseCopyAttrib TAB
			where TAB.COPYAREA like '%TABLEATTRIBUTES'
			)
	)
	Begin
	        Insert into @tTableTypes(NUMERICKEY)
	        Select DISTINCT cast(TAB.COPYAREAKEY as int)
		From @tblCaseCopyAttrib TAB
		where TAB.COPYAREA like '%TABLEATTRIBUTES'
		and ISNUMERIC(TAB.COPYAREAKEY)=1
		and not exists (SELECT 1 from COPYPROFILE C
				where C.COPYAREA='TABLEATTRIBUTES'
				and C.PROFILENAME = @psProfileName
				and C.STOPCOPY = 1)

	        Set @nErrorCode = @@ERROR
	End
	Else Begin
		-- Identify TableTypes to be copied
	        Insert into @tTableTypes(NUMERICKEY)
	        Select distinct C.NUMERICKEY
	        From COPYPROFILE C
	        join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
	        where PROFILENAME = @psProfileName
	        and COPYAREA = 'TABLEATTRIBUTES'
	        and (STOPCOPY = 0
	        or   STOPCOPY is null)

	        Set @nErrorCode = @@ERROR
        End

        If @nErrorCode=0
        Begin
	        Insert into TABLEATTRIBUTES (PARENTTABLE, GENERICKEY, TABLECODE, TABLETYPE)
	        Select T.PARENTTABLE, @psNewCaseKey, T.TABLECODE, T.TABLETYPE
	        from TABLEATTRIBUTES T
	        join @tTableTypes TT on (TT.NUMERICKEY=T.TABLETYPE)
	        where T.GENERICKEY = @psCaseKey
	        and T.PARENTTABLE = 'CASES'

	        Set @nErrorCode = @@ERROR
        End
End

-- -----------
-- Case Text

If @nErrorCode = 0
Begin
        Declare @tTextTypes table (CHARACTERKEY nvarchar(2) collate database_default)
        If (@nAttribRowCount > 0
                and exists (Select 1
			From @tblCaseCopyAttrib TAB
			where TAB.COPYAREA like '%CASETEXT'
			)
	)
	Begin
	        Insert into @tTextTypes
		        Select COPYAREAKEY
			From @tblCaseCopyAttrib TAB
			where TAB.COPYAREA like '%CASETEXT'
			and (not exists (SELECT 1 from COPYPROFILE C
					where C.COPYAREA=TAB.COPYAREA
					and C.PROFILENAME = @psProfileName
					and (C.REPLACEMENTDATA IS NOT NULL or C.STOPCOPY = 1))
				OR
			TAB.COPYAREAKEY = 'G'
			)
	        Set @nErrorCode = @@ERROR
	End
	Else if exists
	        (Select *
		From COPYPROFILE C
		join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
		where PROFILENAME = @psProfileName
		and COPYAREA = 'CASETEXT'
		and REPLACEMENTDATA is null
		and (STOPCOPY = 0
		or   STOPCOPY is null))
        Begin
	-- Identify TextTypes to be copied
	        Insert into @tTextTypes
		        Select CHARACTERKEY
			        From COPYPROFILE C
			        join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
			        where PROFILENAME = @psProfileName
			        and COPYAREA = 'CASETEXT'
			        and REPLACEMENTDATA is null
			        and (STOPCOPY = 0
			        or   STOPCOPY is null)
	        Set @nErrorCode = @@ERROR
        End
        -- Prepare ClassList - using Tokenise (see below)

        -- Copy Text from parent if necessary
        If @nErrorCode = 0
        Begin
                Declare @sClasses nvarchar(254)
                Select @sClasses = REPLACE(LOCALCLASSES, '&', '')
	                from CASES
	                where CASEID = @nNewCaseKey

				-- Copy Class Items if the old case and the new case have the same jurisdiction and Items are configured for the property type
				INSERT INTO CASECLASSITEM (CASEID,CLASSITEMID)
				SELECT @nNewCaseKey, CCI.CLASSITEMID
				FROM CASECLASSITEM CCI
					left join CASES C1 on (C1.CASEID = @nNewCaseKey)
					left join CASES C2 on (C2.CASEID = @nCaseKey)
					join PROPERTYTYPE P on (C1.PROPERTYTYPE = P.PROPERTYTYPE)
				where CCI.CASEID = @nCaseKey
					and C1.COUNTRYCODE = C2.COUNTRYCODE
					and C1.PROPERTYTYPE = C2.PROPERTYTYPE
					and P.ALLOWSUBCLASS = 2
					and C1.LOCALCLASSES is not null

                Insert into CASETEXT (CASEID, TEXTTYPE, TEXTNO, CLASS,
		                LANGUAGE, MODIFIEDDATE, LONGFLAG, SHORTTEXT, [TEXT])
	                Select @nNewCaseKey, T.TEXTTYPE,
		                case T.TEXTTYPE
		                    when 'G' then
			                case
			                    when T.TEXTNO = 0 then isnull(MAXTEXT.MAXTEXTNO,0) + MAXTEXTORIGINAL.MAXTEXTNO + 1	-- RFC 39652 Use ISNULL to cater for null TEXTNO.
			                                      else isnull(MAXTEXT.MAXTEXTNO,0) + T.TEXTNO
			                end
		                    else T.TEXTNO
		                end, T.CLASS,
		                T.LANGUAGE,GETDATE(), T.LONGFLAG, T.SHORTTEXT, T.[TEXT]
		                from CASETEXT T
		                join CASES C 		on (C.CASEID = T.CASEID)
		                left join CASETEXT T2 	on (T2.CLASS = T.CLASS
					                and T2.TEXTTYPE = T.TEXTTYPE
					                and T2.LANGUAGE IS null
					                and T.LANGUAGE IS null
					                and T2.CASEID = @nNewCaseKey)
		                left join 	(Select MAX(TEXTNO) as MAXTEXTNO, TEXTTYPE
				                From 	CASETEXT
				                Where 	CASEID = @nNewCaseKey
				                Group by TEXTTYPE
				                ) MAXTEXT on (MAXTEXT.TEXTTYPE = T.TEXTTYPE)
		                left join 	(Select MAX(TEXTNO) as MAXTEXTNO, TEXTTYPE
				                from 	CASETEXT
				                where 	CASEID = @nCaseKey
				                group by 	TEXTTYPE
				                ) MAXTEXTORIGINAL on (MAXTEXTORIGINAL.TEXTTYPE = T.TEXTTYPE)
		                where T.CASEID = @nCaseKey
			                and T.TEXTTYPE IN (Select CHARACTERKEY from @tTextTypes)
			                and (
				                (
				                C.LOCALCLASSES is not null
				                and (
					                T.CLASS IN (Select Parameter
							                from dbo.fn_Tokenise (@sClasses, ','))
					                or T.CLASS is null
				                     )
			   	                )
				                or (C.LOCALCLASSES is null and T.CLASS is null)
			                     )
			                 and (T2.CASEID is null or ISNULL(T.SHORTTEXT,T.TEXT) is not null)
                Set @nErrorCode = @@ERROR
        End

        -- Update Text from parent if necessary
        If @nErrorCode = 0
        Begin
                Update CTN
                set 	SHORTTEXT = CT.SHORTTEXT,
	                TEXT = CT.TEXT,
	                LONGFLAG = CT.LONGFLAG
                from 	CASETEXT CTN
                join 	CASETEXT CT ON (CTN.CLASS = CT.CLASS
			                and CTN.TEXTTYPE = CT.TEXTTYPE
			                and CTN.LANGUAGE IS null
			                and CT.LANGUAGE IS null)
                where 	CTN.CASEID = @nNewCaseKey
	                and CT.CASEID = @nCaseKey
	                and CTN.TEXTTYPE = 'G'

                Set @nErrorCode = @@ERROR
        End

   If @nErrorCode = 0
	Begin
        Declare @tClass table (CASEID nvarchar(11) collate database_default,
                               CLASS nvarchar(100) collate database_default)

	        Insert into @tClass
		        Select Distinct @nNewCaseKey, CLASS FROM CASETEXT
							WHERE CASEID = @nCaseKey
			                and TEXTTYPE = 'G'
			                and (SHORTTEXT is null and TEXT is null)
			                and LANGUAGE IS null
			                and LANGUAGE IS null

	        Set @nErrorCode = @@ERROR
	End

    ---- Delete default Text (Which is inserted by trigger) from New Case if it's not present in parent Case Class
      If @nErrorCode = 0 and exists(Select 1 from @tClass)
        Begin
                Delete from CASETEXT
                Where CASEID in (Select CASEID FROM @tClass)
			          and CLASS not in (Select CLASS FROM @tClass)
			          and (SHORTTEXT is null and TEXT is null)
			          and LANGUAGE IS null

                Set @nErrorCode = @@ERROR
       End
       Else
        Begin
                Delete from CASETEXT
                Where CASEID = @nNewCaseKey
			     and (SHORTTEXT is null and TEXT is null)
			     and LANGUAGE IS null

			 Set @nErrorCode = @@ERROR
       End
End

-- ------------
-- CaseName

If @nErrorCode = 0
Begin
        -- Identify NameTypes to be copied
        Declare @tNameTypes table (
	        CHARACTERKEY 	nvarchar(3) 	collate database_default, /* holds NAMETYPE */
	        REPLACEMENTDATA nvarchar(11) 	collate database_default, /* NAMENO */
	        ISCREATED	bit
	)

        If (@nAttribRowCount > 0
                and exists (Select 1
				From @tblCaseCopyAttrib TAB
				left join COPYPROFILE C	on (C.COPYAREA='CASENAME'
							and C.PROFILENAME = @psProfileName
							and C.CHARACTERKEY=TAB.COPYAREAKEY)
				where TAB.COPYAREA like '%CASENAME'
				and isnull(C.STOPCOPY,0)=0 ))
	Begin
	        Insert into @tNameTypes (CHARACTERKEY, REPLACEMENTDATA, ISCREATED)
		        Select TAB.COPYAREAKEY, TAB.REPLACEDATA, CASE WHEN TAB.REPLACEDATA IS NULL THEN 1 ELSE 0 END
				From @tblCaseCopyAttrib TAB
				left join COPYPROFILE C	on (C.COPYAREA='CASENAME'
							and C.PROFILENAME = @psProfileName
							and C.CHARACTERKEY=TAB.COPYAREAKEY)
				where TAB.COPYAREA like '%CASENAME'
				and isnull(C.STOPCOPY,0)=0

	        Set @nErrorCode = @@ERROR

	End
	Else If exists (
	        Select 1
		From COPYPROFILE C
		join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
		where C.PROFILENAME = @psProfileName
		and C.COPYAREA = 'CASENAME'
		and (C.STOPCOPY = 0
		 or  C.STOPCOPY is null))
        Begin
	        Insert into @tNameTypes (CHARACTERKEY, REPLACEMENTDATA, ISCREATED)
		        Select CHARACTERKEY, REPLACEMENTDATA, CASE WHEN REPLACEMENTDATA IS NULL THEN 1 ELSE 0 END
			        from COPYPROFILE
			        where PROFILENAME = @psProfileName
			        and COPYAREA = 'CASENAME'
			        and (STOPCOPY = 0
		 	         or  STOPCOPY is null)
	        Set @nErrorCode = @@ERROR
        End

        If @nErrorCode = 0
        Begin
	        -- Copy Names from parent if necessary
	        Insert into CASENAME ([SEQUENCE], NAMETYPE, NAMENO,
		        CASEID, ADDRESSCODE, ASSIGNMENTDATE,
		        BILLPERCENTAGE, COMMENCEDATE,
		        CORRESPONDNAME,
		        DERIVEDCORRNAME,
		        EXPIRYDATE, INHERITED, REFERENCENO)
		        Select [SEQUENCE], NAMETYPE, NAMENO,
			        @nNewCaseKey, ADDRESSCODE, ASSIGNMENTDATE,
			        BILLPERCENTAGE, COMMENCEDATE,
			        case
				        when DERIVEDCORRNAME = 0 then CORRESPONDNAME
				        else dbo.fn_GetDerivedAttnNameNo(NAMENO, @nCaseKey, NAMETYPE)
			        end,
			        DERIVEDCORRNAME,
			        EXPIRYDATE, INHERITED, REFERENCENO
			        from CASENAME
			        where CASEID = @nCaseKey
			        and NAMETYPE IN
			        (Select CHARACTERKEY from @tNameTypes
				        where REPLACEMENTDATA is null)
	        Set @nErrorCode = @@ERROR
        End

        If @nErrorCode = 0
        Begin
	        Declare @sNameTypeKey	nvarchar(10)
	        Declare @sNameKey	nvarchar(11)
	        Declare @sWholeKey	nvarchar(20)
	        Set @sWholeKey = ''

	        -- Need to use combined key to ensure uniqueness
	        While @nErrorCode = 0 and exists
		        (Select * from @tNameTypes
		        where ISCREATED = 0
		        and REPLACEMENTDATA is not null)
	        Begin
		        -- Identify NameType/NameNo combinations to be processed
		        Select 	top 1 	@sNameTypeKey = CHARACTERKEY,
				        @sNameKey = REPLACEMENTDATA
			        from @tNameTypes
			        where REPLACEMENTDATA IS NOT NULL
			        and ISCREATED = 0
			        order by CHARACTERKEY, REPLACEMENTDATA

		        -- For each combination located, create a new CaseName
		        Exec @nErrorCode = cs_InsertCaseName
			        @pnUserIdentityId = @pnUserIdentityId,
			        @psCulture = @psCulture,
			        @psCaseKey = @psNewCaseKey,
			        @psNameTypeKey = @sNameTypeKey,
			        @psNameKey = @sNameKey

		        Set @nErrorCode = @@ERROR

		        Update @tNameTypes
		        set ISCREATED = 1
		        where CHARACTERKEY = @sNameTypeKey
		        and REPLACEMENTDATA = @sNameKey
		        and REPLACEMENTDATA IS NOT NULL

	        End  -- While
        End -- @nErrorCode = 0

		If @nErrorCode= 0 and @pnInstructorKey is not null and not exists (Select 1 from @tNameTypes where CHARACTERKEY = 'I')
		Begin
			-- Add Instructor
			Insert into CASENAME ([SEQUENCE], NAMETYPE, NAMENO, CASEID)
			VALUES (0, 'I', @pnInstructorKey, @nNewCaseKey)

			Set @nErrorCode = @@ERROR
		End

		If @nErrorCode= 0 and @pnOwnerKey is not null and not exists (Select 1 from @tNameTypes where CHARACTERKEY = 'O')
		Begin
			-- Add Owner
			Insert into CASENAME ([SEQUENCE], NAMETYPE, NAMENO, CASEID)
			VALUES (0, 'O', @pnOwnerKey, @nNewCaseKey)

			Set @nErrorCode = @@ERROR
		End

		If @nErrorCode= 0 and @pnStaffKey is not null and not exists (Select 1 from @tNameTypes where CHARACTERKEY = 'EMP')
		Begin
			-- Add Staff
			Insert into CASENAME ([SEQUENCE], NAMETYPE, NAMENO, CASEID)
			VALUES (0, 'EMP', @pnStaffKey, @nNewCaseKey)

			Set @nErrorCode = @@ERROR
		End

	    -- Inherit new names
        If @nErrorCode = 0
        Begin
		declare @pnInsertedRowCount int
	        exec @nErrorCode = cs_GenerateCaseName
		        @pnUserIdentityId = @pnUserIdentityId,
		        @psCulture = @psCulture,
		        @pnCaseKey = @nNewCaseKey,
			@pnInsertedRowCount = @pnInsertedRowCount output


		While @pnInsertedRowCount > 0
		begin
			set @pnInsertedRowCount = 0

			exec @nErrorCode = cs_GenerateCaseName
		        @pnUserIdentityId = @pnUserIdentityId,
		        @psCulture = @psCulture,
		        @pnCaseKey = @nNewCaseKey,
			@pnInsertedRowCount = @pnInsertedRowCount output
		end
        End

End -- CASENAME

-- ----------------
-- OfficialNumbers

If @nErrorCode = 0
Begin
	-- Create structure to hold official numbers
	Declare @tOfficialNos table (
		CHARACTERKEY 	nvarchar(3)	collate database_default, -- NUMBERTYPE
		REPLACEMENTDATA nvarchar(36)	collate database_default) -- OFFICIALNUMBER

        If @nAttribRowCount > 0
        Begin
                Insert into @tOfficialNos
		Select TAB.COPYAREAKEY, TAB.REPLACEDATA
			From @tblCaseCopyAttrib TAB
			left join COPYPROFILE C	on (C.COPYAREA='OFFICIALNUMBERS'
						and C.PROFILENAME = @psProfileName
						and C.CHARACTERKEY=TAB.COPYAREAKEY)
			where TAB.COPYAREA like '%OFFICIALNUMBERS'
			and isnull(C.STOPCOPY,0)=0
        End
        Else
        Begin
                Insert into @tOfficialNos
		Select CHARACTERKEY, REPLACEMENTDATA
			From COPYPROFILE C
			join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
			where PROFILENAME = @psProfileName
			and COPYAREA = 'OFFICIALNUMBERS'
			and (STOPCOPY = 0
		 	 or  STOPCOPY is null)
        End

	-- Add/overwrite Application number if present
	If @psApplicationNumber is not null
	Begin
		If exists(SELECT * FROM @tOfficialNos where CHARACTERKEY = 'A')
	        Begin
			Update @tOfficialNos
				set REPLACEMENTDATA = @psApplicationNumber
				where CHARACTERKEY = 'A'
	        End
		Else
		Begin
			Insert into @tOfficialNos (CHARACTERKEY, REPLACEMENTDATA)
				values ('A', @psApplicationNumber)
	        End
		Set @nErrorCode = @@ERROR
	End
End

If @pbDebug = 1
	Select * from @tOfficialNos

If @nErrorCode = 0 and exists(Select *  from @tOfficialNos)
Begin
	-- Copy Official Numbers
	Insert into OFFICIALNUMBERS (CASEID, OFFICIALNUMBER, NUMBERTYPE, DATEENTERED, ISCURRENT)
		/* From the parent when blank */
	Select @nNewCaseKey, OFFICIALNUMBER, NUMBERTYPE, DATEENTERED, ISCURRENT
        from OFFICIALNUMBERS
	where CASEID = @nCaseKey
	and NUMBERTYPE IN (Select CHARACTERKEY
	                        from @tOfficialNos
                                where REPLACEMENTDATA is null)

        union /* otherwise from the table variable */

        Select @nNewCaseKey, REPLACEMENTDATA, CHARACTERKEY, null, 1
	from @tOfficialNos
	where REPLACEMENTDATA is not null

	Set @nErrorCode = @@ERROR

	-- Update Parent Reference if necessary
	If @nErrorCode = 0
	Begin
		Declare @sCurrOfficialNo nvarchar(36)
		Set @sCurrOfficialNo = dbo.fn_GetCurrentOfficialNo(@nNewCaseKey)
		If @sCurrOfficialNo is not null
			Update CASES
				Set CURRENTOFFICIALNO = @sCurrOfficialNo
			where	CASEID = @nNewCaseKey
		Set @nErrorCode = @@ERROR
	End
End

-- ------------------------
-- Create Events
-- 1) Date of Entry - again we may want to replace with another SP
if @nErrorCode = 0
begin
	insert into 	[CASEEVENT]
		(	[CASEID],
			[EVENTNO],
			[EVENTDATE],
			[CYCLE],
			[DATEDUESAVED],
			[OCCURREDFLAG]
		)
	values
		(	@nNewCaseKey,
			-13,
			@dtToday,  -- this needs to be date only!
			1,
			0,
			1
		)

	set @nErrorCode = @@error
end

-- 2) Instructions Received
if @nErrorCode = @@error
begin
	insert into 	[CASEEVENT]
		(	[CASEID],
			[EVENTNO],
			[EVENTDATE],
			[CYCLE],
			[DATEDUESAVED],
			[OCCURREDFLAG]
		)
	values	(	@nNewCaseKey,
			-16,
			@dtToday,
			1,
			0,
			1
		)

	set @nErrorCode = @@error
end

If @nErrorCode = 0
Begin
	-- Application Event No - used below
	Declare @nApplicationEventNo int
	Select @nApplicationEventNo = RELATEDEVENTNO
		from dbo.NUMBERTYPES
		where NUMBERTYPE = 'A'

	-- Identify events to be copied
	Declare @tEventToBeCopied table
		(	NUMERICKEY 	int	) -- EVENTNO

        If @nAttribRowCount > 0
        Begin
                Insert into @tEventToBeCopied
		Select DISTINCT cast(TAB.COPYAREAKEY as int)
			From @tblCaseCopyAttrib TAB
			left join COPYPROFILE C	on (C.COPYAREA='CASEEVENT'
						and C.PROFILENAME = @psProfileName
						and TAB.COPYAREAKEY = convert(nvarchar, C.NUMERICKEY))
			where TAB.COPYAREA like '%CASEEVENT'
			and isnumeric(TAB.COPYAREAKEY)=1
			and C.REPLACEMENTDATA is null
			and isnull(C.STOPCOPY,0)=0
        End
        Else
        Begin
	Insert into @tEventToBeCopied (NUMERICKEY)
		Select NUMERICKEY
			From COPYPROFILE C
			join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
			where PROFILENAME = @psProfileName
			and COPYAREA = 'CASEEVENT'
			and REPLACEMENTDATA is null
			and (STOPCOPY = 0
		 	 or  STOPCOPY is null)
        End
	Select @nErrorCode = @@ERROR, @nRowCount = @@ROWCOUNT
End

If @pbDebug = 1
	Print 'Copy Events from parent if necessary'

If 	@nErrorCode = 0
	and @nRowCount > 0
Begin
	Insert into [CASEEVENT]
		(CASEID, EVENTNO, CYCLE, EVENTDATE,
		EVENTDUEDATE, DATEDUESAVED, OCCURREDFLAG,
		DOCUMENTNO, DOCSREQUIRED, DOCSRECEIVED )
		Select @nNewCaseKey, EVENTNO, CYCLE, EVENTDATE,
			EVENTDUEDATE, DATEDUESAVED, OCCURREDFLAG,
			DOCUMENTNO, DOCSREQUIRED, DOCSRECEIVED
			from [CASEEVENT]
			where [CASEID] = @nCaseKey
			and [EVENTNO] in (Select NUMERICKEY from @tEventToBeCopied)
			and (	(EVENTDATE is not null)
				or (EVENTDUEDATE is not null
				and DATEDUESAVED = 1)
			     )
	Set @nErrorCode = @@ERROR
End

-- ------------
-- RelatedCase

If @pbDebug = 1
	Print 'Identify copied relationships that are valid in the context of the new Case.'

Declare @tRelationship table (RELATIONSHIP nvarchar(3) collate database_default )

If @nErrorCode = 0
Begin
	If @nAttribRowCount > 0
	Begin
	        Insert into @tRelationship (RELATIONSHIP)
		Select VR.RELATIONSHIP
			from CASES C
			join @tblCaseCopyAttrib TAB
						on (TAB.COPYAREA like '%RELATEDCASE'
			                        and TAB.REPLACEDATA is null)
			join VALIDRELATIONSHIPS VR
						on (VR.RELATIONSHIP=TAB.COPYAREAKEY
						and VR.PROPERTYTYPE=C.PROPERTYTYPE
						and VR.COUNTRYCODE = (	select min(VR1.COUNTRYCODE)
									from VALIDRELATIONSHIPS VR1
									where VR1.COUNTRYCODE in ('ZZZ',C.COUNTRYCODE)
									and VR1.PROPERTYTYPE=VR.PROPERTYTYPE
									and VR1.RELATIONSHIP=VR.RELATIONSHIP))
			left join COPYPROFILE P on (P.CHARACTERKEY=TAB.COPYAREAKEY
						and P.PROFILENAME = @psProfileName
						and P.COPYAREA = 'RELATEDCASE' )
			join CASERELATION R 	on (R.RELATIONSHIP = VR.RELATIONSHIP
						and R.SHOWFLAG = 1)
			where C.CASEID=@nNewCaseKey
			and isnull(P.STOPCOPY,0)=0
			and P.REPLACEMENTDATA is null
	End
	Else
	Begin
		-- Identify copied relationships that are valid in the context of the new Case
		Insert into @tRelationship (RELATIONSHIP)
		Select VR.RELATIONSHIP
			from VALIDRELATIONSHIPS VR
			join CASES C 		on (C.PROPERTYTYPE = VR.PROPERTYTYPE
						and C.CASEID = @nNewCaseKey)
			join COPYPROFILE P 	on (VR.RELATIONSHIP = P.CHARACTERKEY
						and P.PROFILENAME = @psProfileName
						and P.COPYAREA = 'RELATEDCASE'
						and P.REPLACEMENTDATA is null
						and (P.STOPCOPY = 0
		 	 			 or  P.STOPCOPY is null))
			join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = P.SEQUENCENO)
			join CASERELATION R 	on (R.RELATIONSHIP = VR.RELATIONSHIP
						and R.SHOWFLAG = 1)
			where VR.COUNTRYCODE =
				( 	select min( VR1.COUNTRYCODE )
					from VALIDRELATIONSHIPS VR1
					where VR1.COUNTRYCODE in ( 'ZZZ', C.COUNTRYCODE )
		 			and VR1.PROPERTYTYPE = C.PROPERTYTYPE
					AND VR1.RELATIONSHIP = VR.RELATIONSHIP
				)
        End
	Set @nErrorCode = @@ERROR
End

If @pbDebug = 1
Begin
	SELECT '@tRelationship:',* FROM @tRelationship
	Print 'Copy relationships from the parent if necessary.'
End

If @nErrorCode = 0
Begin
	If @pbDebug = 1
		Select 'keys', @nNewCaseKey, @nCaseKey

	If (@nNewCaseKey is not null)
	Begin
		Insert into RELATEDCASE
		(	CASEID, RELATIONSHIPNO, RELATIONSHIP,
			RELATEDCASEID, OFFICIALNUMBER, COUNTRYCODE,
			COUNTRYFLAGS, CLASS, QUOTE, TREATYCODE,
			ACCEPTANCEDETAILS, PRIORITYDATE, SEARCHDATE,
			RECORDALFLAGS, TITLE
		)
		Select DISTINCT	@nNewCaseKey, R.RELATIONSHIPNO+1, R.RELATIONSHIP,
			R.RELATEDCASEID, R.OFFICIALNUMBER, R.COUNTRYCODE,
			R.COUNTRYFLAGS, R.CLASS, R.QUOTE, R.TREATYCODE,
			R.ACCEPTANCEDETAILS, R.PRIORITYDATE, R.SEARCHDATE,
			R.RECORDALFLAGS, R.TITLE
			from RELATEDCASE R
			join @tRelationship T on (T.RELATIONSHIP=R.RELATIONSHIP)
			where R.CASEID = @nCaseKey

		Select	@nErrorCode = @@ERROR,
			@nRelatedCaseCount=@@ROWCOUNT
	End
End

-- Check to see if any Events should be copied as result of the
-- related cases. If so then set a flag on which will be used to
-- determine if cs_UpdatePriorityEvent needs to be called.
If  @nRelatedCaseCount > 0
and @nErrorCode = 0
Begin

	if exists(	select 1
			from 	RELATEDCASE R
			join	CASERELATION CR on (CR.RELATIONSHIP=R.RELATIONSHIP)
			left join
				CASEEVENT CE	on (CE.CASEID=R.RELATEDCASEID
						and CE.EVENTNO=CR.FROMEVENTNO
						and CE.CYCLE  =1)
			where 	R.CASEID = @nCaseKey
			and 	CR.EVENTNO is not null
			and    (CE.EVENTDATE is not null OR R.PRIORITYDATE is not null)
		   )
	begin
		set @bProcessPriorityEvent = 1
	end
End

If @pbDebug = 1
	Print 'Create Reciprocal relationships if necessary.'

If @nErrorCode = 0
Begin
	Insert into @tReciprocal (RELATEDCASEID, RECIPRELATIONSHIP)
	Select RC.RELATEDCASEID, VR.RECIPRELATIONSHIP
        from VALIDRELATIONSHIPS VR
        join CASES C on (C.CASEID = @nNewCaseKey
	                and C.PROPERTYTYPE = VR.PROPERTYTYPE)
        join RELATEDCASE RC on (RC.CASEID = C.CASEID
			and RC.RELATIONSHIP = VR.RELATIONSHIP)
	where VR.COUNTRYCODE =
			( select min(VR1.COUNTRYCODE)
				from VALIDRELATIONSHIPS VR1
				where VR1.COUNTRYCODE in ( 'ZZZ', C.COUNTRYCODE )
				and VR1.PROPERTYTYPE=C.PROPERTYTYPE
				and VR1.RELATIONSHIP = VR.RELATIONSHIP
			)
	and VR.RECIPRELATIONSHIP is not null

	Select	@nRowCount = @@ROWCOUNT,
		@nErrorCode = @@ERROR

	If @nRowCount > 0 and @nErrorCode = 0
	Begin
		Set @nCounter = 1
		While @nCounter <= @nRowCount and @nErrorCode = 0
		Begin

			Select 	@sRelatedCaseKey = CAST(RELATEDCASEID as nvarchar(11)),
				@sRecipRelationship = RECIPRELATIONSHIP
				from @tReciprocal
				where IDENT = @nCounter

			-- Create reciprocal relationships
			If (@sRelatedCaseKey is not null)
			Begin
				Exec @nErrorCode = dbo.cs_InsertRelatedCase
							@pnUserIdentityId = @pnUserIdentityId,
							@psCulture = @psCulture,
							@psCaseKey = @sRelatedCaseKey,
							@psRelationshipKey = @sRecipRelationship,
							@psRelatedCaseKey = @psNewCaseKey,
							@pbCreateReciprocal = 0,	-- Do not create reciprocal reciprocal relationships!
							@pbProcessPriorityEvent	= @bProcessPriorityEvent output -- to mark that this related case may need to process priority event.

				if  @nErrorCode = 0
				and @bProcessPriorityEvent =1
				Begin
					-- Check if Priority Events are required for the Related Case
					-- being created for the reciprocal relationship
					Exec @nErrorCode = dbo.cs_UpdatePriorityEvents
								@pnUserIdentityId	= @pnUserIdentityId,
								@psCulture		= @psCulture,
								@pnCaseKey		= @sRelatedCaseKey,
								@pnPolicingBatchNo	= @pnPolicingBatchNo
				End
			End
			Set @nCounter = @nCounter + 1

		End
	End
End

If @pbDebug = 1
	Print 'Create relationship from parent to child if necessary.'

-- Locate Relationship
-- Add new Related Case to Parent Case if specified
Declare @sParentRelationship nvarchar(3)
If @nAttribRowCount > 0
Begin
        Select @sParentRelationship = P.CHARACTERKEY
	from COPYPROFILE P
	join @tblCaseCopyAttrib TAB on (TAB.COPYAREA like +'%'+ P.COPYAREA)
	where P.COPYAREA = 'ADD_RELATIONSHIP'
	and  P.PROFILENAME = @psProfileName
	and (P.STOPCOPY = 0
	 or  P.STOPCOPY is null)
End
Else
Begin
        Select @sParentRelationship = P.CHARACTERKEY
	from COPYPROFILE P
	join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = P.SEQUENCENO)
	where P.PROFILENAME = @psProfileName
	and	P.COPYAREA = 'ADD_RELATIONSHIP'
	and (P.STOPCOPY = 0
	 or  P.STOPCOPY is null)
End

If @nErrorCode = 0
and @sParentRelationship is not null
and @psCaseKey is not null
Begin
	Exec @nErrorCode = dbo.cs_InsertRelatedCase
				@pnUserIdentityId 	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@psCaseKey		= @psCaseKey,
				@psRelationshipKey	= @sParentRelationship,
				@psRelatedCaseKey	= @psNewCaseKey,
				@pbProcessPriorityEvent = @bProcessPriorityEvent output

End

If @nErrorCode = 0
and @psRelationshipKey is not null
and @psCaseKey is not null
Begin
	Exec @nErrorCode = dbo.cs_InsertRelatedCase
				@pnUserIdentityId 	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@psCaseKey		= @psCaseKey,
				@psRelationshipKey	= @psRelationshipKey,
				@psRelatedCaseKey	= @psNewCaseKey,
				@pbProcessPriorityEvent = @bProcessPriorityEvent output
End

If @pbDebug = 1
	Print 'CaseImage'

------------
-- CaseImage
If @nErrorCode = 0
Begin
        If (@nAttribRowCount > 0
                and exists (Select 1
			From @tblCaseCopyAttrib TAB
			left join COPYPROFILE C	on (C.COPYAREA='CASEIMAGE'
						and C.PROFILENAME = @psProfileName)
			where TAB.COPYAREA like '%CASEIMAGE'
			and isnull(C.STOPCOPY,0)=0 ))


		or exists
	        (Select * from COPYPROFILE C
		join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
		where PROFILENAME = @psProfileName
		and COPYAREA = 'CASEIMAGE'
		and (STOPCOPY = 0
	 	 or  STOPCOPY is null))
        Begin
	        Insert into CASEIMAGE (CASEID, IMAGEID, IMAGETYPE, IMAGESEQUENCE, CASEIMAGEDESC)
                Select @nNewCaseKey, IMAGEID, IMAGETYPE, IMAGESEQUENCE, CASEIMAGEDESC
		from CASEIMAGE C
		where CASEID = @nCaseKey

	        Set @nErrorCode = @@ERROR
        End
End

-- ------------
-- Instructions

If @nErrorCode = 0
Begin
	-- Identify instructions to be copied
	Declare @tInstructionsToBeCopied table
		(	COPYAREAKEY 	nvarchar(3),
			NAMENO		int) -- INSTRUCTIONCODE

        If @nAttribRowCount > 0
        Begin
                Insert into @tInstructionsToBeCopied (COPYAREAKEY)
		Select DISTINCT TAB.COPYAREAKEY
			From @tblCaseCopyAttrib TAB
			left join COPYPROFILE C	on (C.COPYAREA='INSTRUCTIONS'
						and C.PROFILENAME = @psProfileName
						and TAB.COPYAREAKEY = C.CHARACTERKEY)
			where TAB.COPYAREA like '%INSTRUCTIONS'
			and C.REPLACEMENTDATA is null
			and isnull(C.STOPCOPY,0)=0
        End
        Else
        Begin
	Insert into @tInstructionsToBeCopied (COPYAREAKEY)
		Select CHARACTERKEY
			From COPYPROFILE C
			join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
			where PROFILENAME = @psProfileName
			and COPYAREA = 'INSTRUCTIONS'
			and REPLACEMENTDATA is null
			and (STOPCOPY = 0
		 	 or  STOPCOPY is null)
        End
	Select @nErrorCode = @@ERROR, @nRowCount = @@ROWCOUNT

		UPDATE @tInstructionsToBeCopied
			SET NAMENO = CN.NAMENO
			from @tInstructionsToBeCopied T
			join INSTRUCTIONTYPE IT		on (IT.INSTRUCTIONTYPE = T.COPYAREAKEY)
			join NAMETYPE NT 		on (NT.NAMETYPE = IT.NAMETYPE)
			left join CASENAME CN		on (CN.CASEID 	= @nNewCaseKey)
						and (CN.NAMETYPE = IT.NAMETYPE)
						and(CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate())
						and CN.SEQUENCE =(Select MIN(CN.SEQUENCE)
									from CASENAME CN
									where 	CN.CASEID	= @nNewCaseKey
									and 	CN.NAMETYPE	= IT.NAMETYPE
									and	(CN.EXPIRYDATE is null or CN.EXPIRYDATE > getdate()))
	Select @nErrorCode = @@ERROR, @nRowCount = @@ROWCOUNT
End

If @pbDebug = 1
	Print 'Copy Instructions from parent if necessary'

If 	@nErrorCode = 0
	and @nRowCount > 0
Begin
		Insert into [NAMEINSTRUCTIONS]
			(CASEID, NAMENO, INTERNALSEQUENCE, RESTRICTEDTONAME, INSTRUCTIONCODE, COUNTRYCODE, PROPERTYTYPE, PERIOD1AMT, PERIOD1TYPE,
			PERIOD2AMT,PERIOD2TYPE, PERIOD3AMT, PERIOD3TYPE, ADJUSTDAY, ADJUSTDAYOFWEEK, ADJUSTMENT,
			ADJUSTSTARTMONTH, ADJUSTTODATE, STANDINGINSTRTEXT)
		SELECT  @nNewCaseKey, T.NAMENO,
			isnull((MI.MAXSEQUENCE +  row_number()over (PARTITION by (select NI.NAMENO) ORDER BY (select null))), 0),
			RESTRICTEDTONAME, NI.INSTRUCTIONCODE, COUNTRYCODE, PROPERTYTYPE, PERIOD1AMT, PERIOD1TYPE,
			PERIOD2AMT,PERIOD2TYPE, PERIOD3AMT, PERIOD3TYPE, ADJUSTDAY, ADJUSTDAYOFWEEK, ADJUSTMENT,
			ADJUSTSTARTMONTH, ADJUSTTODATE, STANDINGINSTRTEXT
		FROM    NAMEINSTRUCTIONS NI
			JOIN INSTRUCTIONS I on (I.INSTRUCTIONCODE = NI.INSTRUCTIONCODE)
			JOIN @tInstructionsToBeCopied T on (T.COPYAREAKEY = I.INSTRUCTIONTYPE and T.NAMENO is not null)
			LEFT JOIN
			(   SELECT  MAX(N2.INTERNALSEQUENCE) AS MAXSEQUENCE, N2.NAMENO
			    FROM    NAMEINSTRUCTIONS  N2
			    GROUP BY N2.NAMENO
			) MI ON MI.NAMENO = T.NAMENO
		WHERE NI.CASEID = @nCaseKey



	Set @nErrorCode = @@ERROR
End


--------------------
-- Case Checklist
If @nErrorCode = 0
Begin
    Declare @tChecklistTypes table (NUMERICKEY int)

    If (@nAttribRowCount > 0
        and exists (Select 1 From @tblCaseCopyAttrib TAB where TAB.COPYAREA like '%CASECHECKLIST'))
    Begin
        Insert into @tChecklistTypes (NUMERICKEY)
        Select DISTINCT cast(TAB.COPYAREAKEY as int)
        From @tblCaseCopyAttrib TAB
        where TAB.COPYAREA like '%CASECHECKLIST'
        and ISNUMERIC(TAB.COPYAREAKEY)=1
        and not exists (SELECT 1
                        from COPYPROFILE C
                        where C.COPYAREA='CASECHECKLIST'
                        and C.PROFILENAME = @psProfileName
                        and C.STOPCOPY = 1)

        Set @nErrorCode = @@ERROR
    End
    Else Begin
        Insert into @tChecklistTypes(NUMERICKEY)
        Select distinct C.NUMERICKEY
        From COPYPROFILE C
        join dbo.fn_Tokenise(@psSequenceNumbers, ',') TAB on (TAB.[Parameter] = C.SEQUENCENO)
        where PROFILENAME = @psProfileName
        and COPYAREA = 'CASECHECKLIST'
        and (STOPCOPY = 0 or STOPCOPY is null)

        Set @nErrorCode = @@ERROR
    End

    If @nErrorCode=0
    Begin
        Insert into CASECHECKLIST (CASEID, QUESTIONNO, CHECKLISTTYPE, CRITERIANO, TABLECODE, YESNOANSWER, COUNTANSWER, VALUEANSWER, CHECKLISTTEXT, EMPLOYEENO, PROCESSEDFLAG, PRODUCTCODE)
        Select @psNewCaseKey, QUESTIONNO, CHECKLISTTYPE, CRITERIANO, TABLECODE, YESNOANSWER, COUNTANSWER, VALUEANSWER, CHECKLISTTEXT, EMPLOYEENO, PROCESSEDFLAG, PRODUCTCODE
        from CASECHECKLIST C
        join @tChecklistTypes TT on (TT.NUMERICKEY = C.CHECKLISTTYPE)
        where C.CASEID = @psCaseKey

        Set @nErrorCode = @@ERROR
    End
End

-- ---------------------
-- Generate Case Reference

-- Now that all the data for the case has been written to the database, generate the case reference from that information.  If Cases.IRN = <Generate Reference>
If @nErrorCode = 0
and @psCaseReference = '<Generate Reference>'
Begin
		If @psRelationshipKey is not null
			Set @nParentCaseKey = @nCaseKey

		Exec @nErrorCode = cs_ApplyGeneratedReference
			@psCaseReference	= @psCaseReference	OUTPUT,
			@pnUserIdentityId	= @pnUserIdentityId,
			@psCulture 		= @psCulture,
			@pnCaseKey		= @nNewCaseKey,
			@pnParentCaseKey	= @nParentCaseKey
End

-- Update priority events for new case
if @nErrorCode = 0
and @bProcessPriorityEvent = 1
Begin
	Exec @nErrorCode = dbo.cs_UpdatePriorityEvents
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture		= @psCulture,
				@pnCaseKey		= @psNewCaseKey,
				@pnPolicingBatchNo	= @pnPolicingBatchNo
End

-- Policing
-- Request policing to open Action
-- Only executed when called from Web Version
If @nErrorCode = 0
Begin
	Declare @sAction nvarchar(10)
	Declare @bCalledFromWeb bit

	Set @bCalledFromWeb = 0
	-- First check if XML Copy Data is present
	-- If so, then get the Action from the selection
	If @nAttribRowCount > 0
	Begin
		Set @bCalledFromWeb = 1

		Select @sAction = TAB.COPYAREAKEY
		from @tblCaseCopyAttrib TAB
		where TAB.COPYAREA like +'%ACTIONS'

		Set @nErrorCode = @@ERROR
	End

        -- If there is no XML Copy Data, i.e. from Designated Countries
        -- Get the Action from the Copy Profile
	If  @nErrorCode = 0
	and @sAction is null
	and @psSequenceNumbers is not null
	Begin

		Set @bCalledFromWeb = 1

		Set @sSQLString = "
		Select @sAction = P.CHARACTERKEY
		from COPYPROFILE P
		join dbo.fn_Tokenise('"+@psSequenceNumbers+"', ',') TAB on (TAB.[Parameter] = P.SEQUENCENO)
		where P.PROFILENAME = '" + @psProfileName + "'" + CHAR(10) +
		"and P.COPYAREA = 'ACTIONS'
		and (STOPCOPY = 0 or  STOPCOPY is null)"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@sAction	nvarchar(2)	OUTPUT',
					  @sAction = @sAction	OUTPUT
	End

	-- If Action has not been specified from calling code
        -- Try getting the Default Action from Screen Control using the specified logical program
	If @nErrorCode = 0
	and @sAction is null
	and @psProgramId is not null
	and @bCalledFromWeb = 1
	Begin
		Set @sSQLString = "
		Select @sAction = TD.FILTERVALUE
		from TOPICDEFAULTSETTINGS TD
		where TD.CRITERIANO = dbo.fn_GetCriteriaNo(convert(int,@psNewCaseKey), 'W', @psProgramId, getdate(), @nProfileKey)
		and TD.TOPICNAME ='Actions_Component'
		and TD.FILTERNAME='NewCaseAction'
		and TD.FILTERVALUE is not null"

		exec @nErrorCode = sp_executesql @sSQLString,
					N'@sAction	nvarchar(2)	OUTPUT,
						@psNewCaseKey	nvarchar(11),
						@psProgramId	nvarchar(8),
						@nProfileKey  int',
						@sAction = @sAction OUTPUT,
						@psNewCaseKey	= @psNewCaseKey,
						@psProgramId  = @psProgramId,
						@nProfileKey  = @nProfileKey
	End

        -- If Action has not been specified from calling code
	-- and logical program was not specified
        -- Get the Default Action from Screen Control
	If @nErrorCode = 0
	and @sAction is null
	and @bCalledFromWeb = 1
	Begin
		Set @sSQLString="
		Select @sProgramId=left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8)
		from SITECONTROL S
		left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=@nProfileKey
						and PA.ATTRIBUTEID=2)	-- Default Cases Program
		where S.CONTROLID='Case Screen Default Program'"

		exec @nErrorCode=sp_executesql @sSQLString,
					N'@sProgramId		nvarchar(8)	OUTPUT,
					  @nProfileKey		int',
					  @sProgramId		=@sProgramId	OUTPUT,
					  @nProfileKey		=@nProfileKey

		If @nErrorCode=0
		Begin
			Set @sSQLString = "
			Select @sAction = TD.FILTERVALUE
			from TOPICDEFAULTSETTINGS TD
			where TD.CRITERIANO = dbo.fn_GetCriteriaNo(convert(int,@psNewCaseKey),
								  'W',				-- web screen control
								  @sProgramId,
								  getdate(),
								  @nProfileKey)
			and TD.TOPICNAME ='Actions_Component'
			and TD.FILTERNAME='NewCaseAction'
			and TD.FILTERVALUE is not null"

			exec @nErrorCode = sp_executesql @sSQLString,
						N'@sAction	nvarchar(2)	OUTPUT,
						  @psNewCaseKey	nvarchar(11),
						  @sProgramId	nvarchar(8),
						  @nProfileKey  int',
						  @sAction = @sAction		OUTPUT,
						  @psNewCaseKey	= @psNewCaseKey,
						  @sProgramId   = @sProgramId,
						  @nProfileKey  = @nProfileKey
		End
	End

	-- Now insert the Policing request to open the action
	If @nErrorCode = 0
	and @sAction is not null
	and @bCalledFromWeb = 1
	Begin
		-- Add OpenAction Policing request
		If @nErrorCode = 0 and @sAction is not null
		Begin
			Exec @nErrorCode = ip_InsertPolicing
				@pnUserIdentityId	= @pnUserIdentityId,
				@psCulture 		= @psCulture,
				@psCaseKey 		= @psNewCaseKey,
				@psSysGeneratedFlag	= 1,
				@psAction		= @sAction,
				@pnTypeOfRequest	= 1,
				@pnPolicingBatchNo	= @pnPolicingBatchNo
		End
	End

End

-- Row level security

If @nErrorCode = 0
and (@psSequenceNumbers is null or @nAttribRowCount <= 0) -- Inprostart only
Begin
	Exec @nErrorCode = cs_GetSecurityForCase
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pnCaseKey = @nNewCaseKey,
		@pbCanInsert = @bHasInsertRights output

	If @nErrorCode = 0 and @bHasInsertRights = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS2', 'User has insufficient privileges to create this case. Please contact your system administrator.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

If @nErrorCode <> 0
Begin
	set @psNewCaseKey = null
End

Return @nErrorCode
GO

Grant execute on dbo.cs_CopyCase to public
GO

