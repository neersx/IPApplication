-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ListCaseData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_ListCaseData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_ListCaseData.'
	Drop procedure [dbo].[cs_ListCaseData]
End
Print '**** Creating Stored Procedure dbo.cs_ListCaseData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE PROCEDURE dbo.cs_ListCaseData
(
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@psCaseKey			nvarchar(11)		-- Mandatory 
)
AS
-- VERSION :	65
-- DESCRIPTION:	Returns Case details for a given CaseKey passed as a parameter.
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 10/07/2002	SF			procedure created
-- 16/07/2002	SF			added CaseFamilyReference, CaseCategoryKey, CaseCategoryDescription in RelatedCase Population.
-- 16/07/2002	SF			added Attachment table population
-- 17/07/2002	SF			added US PTO link <Registration No>
-- 18/07/2002	SF			added CaseEvent.OpenActionCriteriaKey
-- 22/07/2002	SF			rewrite the population of the Attachment table.	BUG102 - Resolved.
-- 23/07/2002	SF			use ^ as delimiters on all rowkeys.
--					use http://www.uspto.gov when no OFFICIALNUMBER is return for the case.
-- 12/08/2002	SF			Change Related Case population from left join to full join on Case Relation.
-- 13/08/2002	SF			Stop Pay Reason Key is USERCODE instead of TABLECODE.
-- 21/08/2002	SF			1. use fn_FormatName instead of ipfn_FormatName
--					2. revision 0.17 add casetext.caseid and casetext.textno as part of classes row key.
-- 26/08/2002	SF			1. Change the way current official number is retrieved.
--					2. Implement revision 0.19 for population of Earliest Priority Date and Next Renewal Date in OfficialNumberDate table.
-- 28/08/2002	SF			Adjust calculation of earliest priority date to take into account claiming priority from multiple cases.
-- 05/09/2002	SF			Number Type order by is incorrect.
-- 09/09/2002	SF			Rev 0.21 When there are more than 1 convention claim from rows, it should retrieve info from RELATEDCASE.
-- 01/10/2002	SF	21		added NameCode in CaseName population.
-- 22 Oct 2002	JB	22		Implemented row level security
-- 23 Oct 2002	JB	23		Bug - not setting error number
-- 25 Oct 2002	JB	24		Now using cs_GetSecurityForCase
-- 13 Nov 2002	SF	25		Bug 264 fixed
-- 25 Nov 2002	JB	28		Implemented translations (backed out 31)
-- 28 Nov 2002	SF	29		Implemented TrademarkClassSequence (320)
-- 03 DEC 2002	SF	30		Multiple versions of Case Text (320 iteration)
-- 04 DEC 2002	JB	31		Temporarily backed out translations
-- 18 JAN 2003	SF	32		Return Internal vs External Status descriptions appropriately.
-- 11 FEB 2003	SF	33		populate 5 new fields in the cases table.
-- 03 MAR 2003	SF	34	RFC016 	Populate CaseName.AttentionNameKey field.
-- 10 MAR 2003	JEK	35	RFC082 	Localise stored procedure errors.
-- 19 MAR 2003	SF	36	RFC085 	Populate Case.RenewalType, Case.ExaminationType
-- 24 MAR 2003	SF	37	RFC015	Retrieve Earliest Priority Event Date Entered for a case
-- 14 MAR 2003	JEK	38	RFC003 	Case Workflow
-- 25 MAR 2003	JEK	39		More work on RFC003 Cas Workflow
-- 28 MAR 2003	JEK	40	RFC003 	CaseEvent should exclude due events against closed actions.
-- 31 MAR 2003	JEK	41	RFC003 	Sort open actions first, then use display sequence.
--				         Return IsDateDueSaved on ActionEvent and CaseEvent tables.
-- 01 APR 2003	JEK	42	RFC003 	Remove unnecessary DisplaySequence and add row keys.
-- 08 APR 2003	SF	43	RFC085 	Population of Case.RenewalTypeDescrption and 
--					Case.ExaminationTypeDescription were incorrect
-- 09 APR 2003	JEK	44	RFC003 	Left join to ValidAction when publishing Action results.
-- 15 APR 2003	JEK	45	RFC003 	Implement Entry.RequiresAtLeast1Event.
-- 15 MAY 2003  TM      46      RFC53  	Fixed bug - Multiple case text versions shown on copied cases.
--					Changes are made in the TEXT and CLASSES tables' population. 
-- 23 JUL 2003	TM	47	RFC300 	USPTO Web link not locating the intellectual property
-- 30 JUL 2003	TM	48	RFC266 	View InPro case attachments
-- 11 AUG 2003  TM	49	RFC224 	Office level rules. Return OfficeKey(Cases.OfficeId/Office.OfficeId)
--					and OfficeDescription(Office.Description) as part of the Case result set.
-- 22 AUG 2003	TM	50	RFC228 	Case Subclasses. Row Keys changed to CaseKey, TrademarkClassKey, 
--					TrademarkClassSequence. The Classes.TrademarkClassHeading column
--					and the join on the TMClass table were removed. Cases.LocalClasses
--					were used instead of TMClass.Class to join to the CaseText table. 
--					Added new Case.UsesClasses column. UsesClasses=1 if there is data in 
--					the TMClass table for the CountryCode and PropertyType of the Case.
-- 01 SEP 2003 TM	51	RFC385 	First Use dates by Class. Add two new columns - 'FirstUse' and 
--					'FirstUseInCommerce' to the CLASSES table in CaseData typed dataset. 
-- 18 Sep 2003 JEK	52	RFC114 	Cyclic events within non-cyclic actions.
--					Implement sp_excecutesql where easily done.
-- 16 Jan 2004	MF	53   		Increase EventDescription to 100 characters.
-- 18 Aug 2004	AB	54	8034	Add collate database_default syntax to temp tables.
-- 10 Jan 2006	TM	55	RFC3374	Modify the population of the OfficialNumber NumberTypeId = 4 to use application 
--					number instead of current official number. If Application Number does not exists 
--					then use Current Official Number.
-- 17 Jan 2006	TM	56	RFC3374	For the Earliest priority, use the following code to extract the official number:
--					coalesce(O.OFFICIALNUMBER, C.CURRENTOFFICIALNO, RC.OFFICIALNUMBER)
-- 11 Dec 2008	MF	57	17136	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Jul 2009	MF	58	16548	The DISPLAYEVENTNO or FROMEVENTNO will now identify the Event from a related Case for a given relationship.
-- 21 Sep 2009  LP      59      RFC8047 Pass ProfileKey as parameter for fn_GetCriteriaNo
-- 07 Jul 2011	DL	60	RFC10830 Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 20 Oct 2011  DV  61  R11439  Modify the join for Valid Property, Category, Basis and Sub Type 
-- 04 Nov 2011	ASH	62	R11460  Cast integer columns as nvarchar(11) data type.   
-- 11 Apr 2013	DV	63	R13270  Increase the length of nvarchar to 11 when casting or declaring integer
-- 04 Nov 2015	KR	64	R53910	Adjust formatted names logic (DR-15543)
-- 07 Sep 2018	AV	74738	65	Set isolation level to read uncommited.


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Declare variables
Declare @nErrorCode		int
Declare @nCaseId 		int
Declare @nCriteriaNo 		int
Declare @sLocalClasses		nvarchar(255)
Declare @sCountryCode		nvarchar(3)
Declare @sUSPTOUrl		varchar(2000)
Declare @bHasSelectRights 	bit
Declare @sAlertXML 		nvarchar(400)
Declare @sSQLString		nvarchar(4000)
-- RFC03 Case Work Flow
Declare @nRowCount 		int
Declare	@nHighestCycle		smallint
Declare @nCycle			smallint

Declare @nProfileKey            int

-- All the possible Actions for the case
Declare @tAction table
	(ACTION			nvarchar(2) 	collate database_default,
	 ACTIONNAME		nvarchar(50) 	collate database_default,
	 CYCLE			smallint,
	 CRITERIANO		int,
	 DISPLAYSEQUENCE	smallint,
	 ISNEW			bit,
	 ISOPEN			bit,
	 NUMCYCLESALLOWED	smallint )

-- The EntryCycles table contains a row
-- for each non-Cyclic Action and Entry combination
-- indicating whether cyclic entries (and Events) are required.
Declare @tEntryCycles table
	(CRITERIANO		int,
	 ENTRYNUMBER		smallint,
	 DEFAULTENTRYCYCLE	smallint,  -- The cycle of the entry to display by default
	 MAXENTRYCYCLE		smallint)  -- The maximum cycle currently permitted for the entry

-- The PotentialCyclicEvents contains proforma data entry rows
-- for cyclic events belonging to non-cyclic actions.
Declare @tPotentialCyclicEvents table
	(CRITERIANO		int,
	 ENTRYNUMBER		smallint,
	 EVENTNO		int,
	 CYCLE			smallint,
	 EVENTDESCRIPTION	nvarchar(100)	collate database_default ,
	 DUEATTRIBUTE		smallint,
	 EVENTATTRIBUTE		smallint,
	 POLICINGATTRIBUTE	smallint,
	 PERIODATTRIBUTE	smallint,
	 DISPLAYSEQUENCE	smallint)

-- Table variable used to generate a sequence number for ad hoc reminders
Declare @tAdHoc table
	(IDENT		int identity(1,1),
	 EMPLOYEENO	int,
	 ALERTSEQ	datetime )

-- Initialise
Set @nErrorCode = 0
Set @nCaseId = CAST(@psCaseKey as int)

-- Check for row security
If @nErrorCode = 0
Begin
	Exec @nErrorCode = cs_GetSecurityForCase
		@pnUserIdentityId = @pnUserIdentityId,
		@psCulture = @psCulture,
		@pnCaseKey = @nCaseId,
		@pbCanSelect = @bHasSelectRights output

	If @nErrorCode = 0 and @bHasSelectRights = 0
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS1', 'User has insufficient security to access this case.',
			null, null, null, null, null)
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

-- Retrieve ProfileKey for the current user
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
                
        Set @nErrorCode = @@ERROR
End

If @nErrorCode = 0
Begin

	Set @nErrorCode = @@ERROR
	/* 
	 * populating CASE table in CaseData typed dataset 
	 *
	 */
	
	If @nErrorCode = 0
	Begin
		Set @sUSPTOUrl = 'http://patft.uspto.gov/netacgi/nph-Parser?Sect1=PTO1&Sect2=HITOFF&d=PALL&p=1&u=/netahtml/srchnum.htm&r=1&f=G&l=50&s1=<Registration No>.WKU.&OS=PN/<Registration No>&RS=PN/<Registration No>'

		Select 	@psCaseKey 		as 'CaseKey',
			C.IRN			as 'CaseReference',
			C.FAMILY		as 'CaseFamilyReference',
			C.CASETYPE		as 'CaseTypeKey',
			CT.CASETYPEDESC		as 'CaseTypeDescription',
			C.COUNTRYCODE		as 'CountryKey',
			COUNTRY.COUNTRY /* ISNULL(dbo.fn_TranslateData(COUNTRY.COUNTRY_TID, '" + @psCulture + "','" + @sOfficeCulture + "'), COUNTRY.COUNTRY) */ as 'CountryName',
			PT.PROPERTYTYPE		as 'PropertyTypeKey',
			PT.PROPERTYNAME		as 'PropertyTypeDescription',
			CASE WHEN PT.PROPERTYTYPE is null THEN null ELSE CC.CASECATEGORY END	as 'CaseCategoryKey',
			CASE WHEN PT.PROPERTYTYPE is null THEN null ELSE CC.CASECATEGORYDESC    END as 'CaseCategoryDescription',
			CASE WHEN (CC.CASECATEGORY is null or PT.PROPERTYTYPE is null) THEN null ELSE V.SUBTYPE END		as 'SubTypeKey',
			CASE WHEN (CC.CASECATEGORY is null or PT.PROPERTYTYPE is null) THEN null ELSE V.SUBTYPEDESC END /* ISNULL(dbo.fn_TranslateData(V.SUBTYPEDESC_TID, '" + @psCulture + "','" + @sOfficeCulture + "'), V.SUBTYPEDESC) */ as 'SubTypeDescription',
			Cast(C.STATUSCODE as varchar(10)) as 'StatusKey',
			Case when USERIDENTITY.ISEXTERNALUSER = 1 then S.EXTERNALDESC else S.INTERNALDESC end as 'StatusDescription',
			/* S.INTERNALDESC  ISNULL(dbo.fn_TranslateData(S.INTERNALDESC_TID, '" + @psCulture + "','" + @sOfficeCulture + "'), S.INTERNALDESC) as 'StatusDescription',*/ 
			C.TITLE /* ISNULL(dbo.fn_TranslateData(C.TITLE_TID, '" + @psCulture + "','" + @sOfficeCulture + "'), C.TITLE) */ as 'ShortTitle',
			C.REPORTTOTHIRDPARTY	as 'ReportToThirdParty',
			P.NOOFCLAIMS		as 'NoOfClaims',
			C.NOINSERIES		as 'NoInSeries',
			C.ENTITYSIZE		as 'EntitySizeKey',
			ES.DESCRIPTION /* ISNULL(dbo.fn_TranslateData(ES.DESCRIPTION_TID, '" + @psCulture + "','" + @sOfficeCulture + "'), ES.[DESCRIPTION]) */ as 'EntitySizeDescription',
			Cast(TF.TABLECODE as varchar(11)) as 'FileLocationKey',
			TF.DESCRIPTION /* ISNULL(dbo.fn_TranslateData(TF.DESCRIPTION_TID, '" + @psCulture + "','" + @sOfficeCulture + "'), TF.[DESCRIPTION]) */ as 'FileLocationDescription',
			C.STOPPAYREASON		as 'StopPayReasonKey',
			SPR.DESCRIPTION /* ISNULL(dbo.fn_TranslateData(SPR.DESCRIPTION_TID, '" + @psCulture + "','" + @sOfficeCulture + "'), SPR.[DESCRIPTION]) */ as 'StopPayReasonDescription',
			C.TYPEOFMARK		as 'TypeOfMarkKey',
			TM.DESCRIPTION /* ISNULL(dbo.fn_TranslateData(TM.DESCRIPTION_TID, '" + @psCulture + "','" + @sOfficeCulture + "'), TM.[DESCRIPTION]) */ as 'TypeOfMarkDescription',
			null			as 'InstructionsReceivedDate',
			case O.OFFICIALNUMBER
			   	when NULL 
				then 'http://www.uspto.gov'
			else
				replace(@sUSPTOUrl, '<Registration No>', 
					O.OFFICIALNUMBER /* ISNULL(dbo.fn_TranslateData(O.OFFICIALNUMBER_TID, '" + @psCulture + "','" + @sOfficeCulture + "'), O.OFFICIALNUMBER)*/
					)
			end			as 'IPOfficeHyperlink',
			VB.BASIS			as 'ApplicationBasisKey',
			VB.BASISDESCRIPTION	as 'ApplicationBasisDescription',
			C.LOCALCLIENTFLAG	as 'IsLocalClient',
			Case P.REGISTEREDUSERS 
				when 'B'	then 1
				when 'N'	then 1
				else 		0
			end 			as 'IsUseByOwner',
			Case P.REGISTEREDUSERS 
				when 'B'	then 1
				when 'Y'	then 1
				else 		0
			end 			as 'IsUseByOthers',
			P.EXAMTYPE		as 'ExaminationTypeKey',
			ET.DESCRIPTION		as 'ExaminationTypeDescription',
			P.RENEWALTYPE		as 'RenewalTypeKey',
			RT.DESCRIPTION		as 'RenewalTypeDescription',
			OFC.OFFICEID		as 'OfficeKey',
			OFC.DESCRIPTION		as 'OfficeDescription',
			Case when exists(select * 
				   	 from TMCLASS CL1
				   	 join CASES C1 on CL1.PROPERTYTYPE = C1.PROPERTYTYPE
				  	 where CL1.PROPERTYTYPE = C1.PROPERTYTYPE
				  	 and CL1.COUNTRYCODE in (C1.COUNTRYCODE, 'ZZZ')
				  	 and C1.CASEID = @nCaseId) then 1 
				 
			     else 0
			End			as 'UsesClasses'			
			
		from	CASES C
		left join OFFICE OFC 		on OFC.OFFICEID = C.OFFICEID 
		left join CASETYPE CT 		on C.CASETYPE = CT.CASETYPE 
		left join COUNTRY 		on C.COUNTRYCODE = COUNTRY.COUNTRYCODE
		left join STATUS S		on S.STATUSCODE = C.STATUSCODE
		left join OFFICIALNUMBERS O	on (O.NUMBERTYPE = 'R'
						and O.CASEID = @nCaseId
						and O.ISCURRENT=1 )	-- rev 0.19
		left join TABLECODES ES		on (ES.TABLETYPE = 26	/* EntitySizeDescription */
						and ES.TABLECODE = C.ENTITYSIZE)
		left join TABLECODES SPR	on (SPR.TABLETYPE = 65	/* StopPayReasonDescription */
						and SPR.USERCODE = C.STOPPAYREASON)
		left join TABLECODES TM		on (TM.TABLETYPE = 51	/* TypeOfMarkDescription */
						and TM.TABLECODE = C.TYPEOFMARK)
		left join PROPERTY P 		on P.CASEID = C.CASEID
		left join VALIDPROPERTY PT 	on (PT.PROPERTYTYPE = C.PROPERTYTYPE
							and PT.COUNTRYCODE = (select min(PT1.COUNTRYCODE)
										from VALIDPROPERTY PT1
										where PT1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
		left join VALIDCATEGORY CC	on (CC.CASETYPE = C.CASETYPE
							AND CC.PROPERTYTYPE = C.PROPERTYTYPE
							AND CC.CASECATEGORY = C.CASECATEGORY
							AND CC.COUNTRYCODE = (select min(CC1.COUNTRYCODE)
											from VALIDCATEGORY CC1
											where CC1.CASETYPE     =C.CASETYPE
											AND   CC1.PROPERTYTYPE =C.PROPERTYTYPE
											AND   CC1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
		left join VALIDSUBTYPE V	on (V.SUBTYPE = C.SUBTYPE
						 	AND V.PROPERTYTYPE = C.PROPERTYTYPE
			 				AND V.COUNTRYCODE = (select min(COUNTRYCODE)
						     					from VALIDSUBTYPE V1
										     	where 	V1.PROPERTYTYPE = C.PROPERTYTYPE
											AND 	V1.CASETYPE     = C.CASETYPE
											AND 	V1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
						 	AND V.CASETYPE = C.CASETYPE
			 				AND V.CASECATEGORY = C.CASECATEGORY
		left join VALIDBASIS VB	on (VB.BASIS = P.BASIS
						 	AND VB.PROPERTYTYPE = C.PROPERTYTYPE
			 				AND VB.COUNTRYCODE = (select min(COUNTRYCODE)
						     					from VALIDBASIS VB1
										     	where 	VB1.PROPERTYTYPE = C.PROPERTYTYPE
											AND 	VB1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
		left join TABLECODES TF		on TF.TABLECODE = (Select CL.FILELOCATION
								FROM CASELOCATION CL
								where CL.CASEID = C.CASEID
								and CL.WHENMOVED = (select max(CL.WHENMOVED)
										   	FROM CASELOCATION CL
											where CL.CASEID = C.CASEID))
		left join TABLECODES RT		on (RT.TABLETYPE = 17	/* RenewalTypeDescription */
						and RT.TABLECODE = P.RENEWALTYPE)
		left join TABLECODES ET		on (ET.TABLETYPE = 8	/* ExaminationTypeDescription */
						and ET.TABLECODE = P.EXAMTYPE)
		left join USERIDENTITY		on USERIDENTITY.IDENTITYID = @pnUserIdentityId
		where	C.CASEID = @nCaseId
	
		Set @nErrorCode = @@Error
	End

	/* 
	 * populating TEXT table in CaseData typed dataset 
	 *
	 */

	If @nErrorCode = 0 
	Begin
		Set @sSQLString="	
		Select 	@psCaseKey + '^' + 
			C1.TEXTTYPE  + '^' + 
			Cast(C1.TEXTNO as varchar(3)) 
							as 'TextRowKey',
			@psCaseKey			as 'CaseKey',
			case	C1.TEXTTYPE
			  when	'T'	then 0		/* Title 	*/
			  when	'R'	then 1		/* Remarks 	*/
			  when 	'CL'	then 2		/* Claims 	*/
			  when 	'A'	then 3		/* Abstract 	*/
			  when	'T1'	then 4		/* Text1 	*/
			  when 	'T2'	then 5		/* Text2 	*/
			  when	'T3'	then 6		/* Text3 	*/
			end				as 'TextTypeId',
			C1.TEXTNO				as 'TextSequence',
			case	C1.LONGFLAG
			  when 	1	then	TEXT
			  else	C1.SHORTTEXT
			end				as 'Text'
		from 	CASETEXT C1
		where	C1.TEXTTYPE in ('T','R','CL','A','T1','T2','T3')
		and	C1.CASEID = @nCaseId
		and	C1.LANGUAGE is null
		and  (  convert(nvarchar(24),C1.MODIFIEDDATE, 21)+cast(C1.TEXTNO as nvarchar(6)) ) 
			=
		     ( select max(convert(nvarchar(24), C2.MODIFIEDDATE, 21)+cast(C2.TEXTNO as nvarchar(6)) )
		       from CASETEXT C2
		       where C2.CASEID=C1.CASEID
		       and   C2.TEXTTYPE=C1.TEXTTYPE
		       and   C2.LANGUAGE is null)"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCaseKey	nvarchar(11),
				  @nCaseId	int',
				  @psCaseKey	=@psCaseKey,
				  @nCaseId	=@nCaseId

	End

	/* 
	 * populating ATTRIBUTE table in CaseData typed dataset 
	 *
	 */

	If @nErrorCode = 0
	Begin	
		Set @sSQLString="	
		Select 	T.GENERICKEY + '^' + 
			Cast(T.TABLECODE as varchar(11))
							as 'AttributeRowKey',
			T.GENERICKEY 			as 'CaseKey',
			case T.TABLETYPE
			  when	-3	then 1		/* AnalysisCode1 */
			  when	-498	then 2		/* AnalysisCode2 */
			  when	-4	then 3		/* AnalysisCode3 */
			  when	-5	then 4		/* AnalysisCode4 */
			  when	-6	then 5		/* AnalysisCode5 */
			end				as 'AttributeTypeId',
			T.TABLECODE			as 'AttributeKey',
			ATTR.DESCRIPTION		as 'AttributeDescription'
		from TABLEATTRIBUTES T
		left join TABLECODES ATTR 	on (T.TABLECODE = ATTR.TABLECODE)
		where 	T.PARENTTABLE	= 'CASES'
		and	T.TABLETYPE 	in (-3,-498,-4,-5,-6)
		and	T.GENERICKEY	= @psCaseKey"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCaseKey	nvarchar(11)',
				  @psCaseKey =@psCaseKey

	End

	/* 
	 * populating RELATEDCASE table in CaseData typed dataset 
	 *
	 */

	If @nErrorCode = 0
	Begin
		Set @sSQLString="	
		Select 	Cast(RC.RELATEDCASEID as varchar(11)) + '^' + 
			Cast(RC.RELATIONSHIPNO as varchar(11))
							as 'RelatedCaseRowKey',
			@psCaseKey			as 'CaseKey',
			RC.RELATIONSHIPNO		as 'RelationshipSequence',
			RC.RELATIONSHIP			as 'RelationshipKey',
			CR.RELATIONSHIPDESC /* ISNULL(dbo.fn_TranslateData(CR.RELATIONSHIPDESC_TID, @psCulture, @sOfficeCulture), CR.RELATIONSHIPDESC) */ as 'RelationshipDescription',
			Cast(RC.RELATEDCASEID as varchar(11))
							as 'RelatedCaseKey',
			C.IRN				as 'RelatedCaseReference',
			C.FAMILY			as 'CaseFamilyReference',
			CC.COUNTRYCODE			as 'CountryKey',
			CC.COUNTRY			as 'CountryName',
			isnull (C.CURRENTOFFICIALNO , RC.OFFICIALNUMBER) 
							as 'OfficialNumber', 
			PT.PROPERTYNAME			as 'PropertyTypeDescription',
			CT.CASETYPEDESC			as 'CaseTypeDescription',
			C.CASECATEGORY			as 'CaseCategoryKey',
			VC.CASECATEGORYDESC		as 'CaseCategoryDescription',
			S.INTERNALDESC 			as 'StatusDescription'
		from	RELATEDCASE RC
		join CASERELATION CR			on (CR.RELATIONSHIP=RC.RELATIONSHIP 
							and CR.SHOWFLAG=1)
		left join CASES C			on (C.CASEID = RC.RELATEDCASEID)
		left join COUNTRY CC on (CC.COUNTRYCODE=isnull(C.COUNTRYCODE, RC.COUNTRYCODE))
		left join CASETYPE CT 			on C.CASETYPE = CT.CASETYPE 
		left join STATUS S			on S.STATUSCODE = C.STATUSCODE
		left join PROPERTY P 			on P.CASEID = C.CASEID
		join VALIDPROPERTY PT 			on (PT.PROPERTYTYPE = C.PROPERTYTYPE
							and PT.COUNTRYCODE = (select min(PT1.COUNTRYCODE)
										from VALIDPROPERTY PT1
										where PT1.PROPERTYTYPE=C.PROPERTYTYPE
										and   PT1.COUNTRYCODE in (C.COUNTRYCODE, 'ZZZ')))
		left join VALIDCATEGORY VC	on (VC.CASETYPE = C.CASETYPE
						AND VC.PROPERTYTYPE = C.PROPERTYTYPE
						AND VC.CASECATEGORY = C.CASECATEGORY
						AND VC.COUNTRYCODE = (select min(VC1.COUNTRYCODE)
										from VALIDCATEGORY VC1
										where VC1.CASETYPE     =C.CASETYPE
										AND   VC1.PROPERTYTYPE =C.PROPERTYTYPE
										AND   VC1.CASECATEGORY =C.CASECATEGORY
										AND   VC1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))
		where	RC.CASEID 	= @nCaseId"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCaseKey	nvarchar(11),
				  @nCaseId	int',
				  @psCaseKey	=@psCaseKey,
				  @nCaseId	=@nCaseId
	End

	/* 
	 * populating CASENAME table in CaseData typed dataset 
	 *
	 */

	If @nErrorCode = 0
	Begin	
		Set @sSQLString="	
		Select 	@psCaseKey + '^' + 
			CN.NAMETYPE + '^' + 
			Cast(CN.NAMENO as varchar(11)) + '^' + 
			Cast(CN.SEQUENCE as varchar(10))
							as 'CaseNameRowKey',
			@psCaseKey			as 'CaseKey',
			null				as 'NameTypeId',
			CN.NAMETYPE			as 'NameTypeKey',
			NT.DESCRIPTION			as 'NameTypeDescription',
			cast(CN.NAMENO as varchar(11))	as 'NameKey',
			N.NAMECODE			as 'NameCode',
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) 
							as 'DisplayName',
			CN.SEQUENCE			as 'NameSequence',
			CN.REFERENCENO			as 'ReferenceNo',
			CN.CORRESPONDNAME		as 'AttentionNameKey',
			case	CN.NAMETYPE 		/* strictly only for orderby, not needed by CASEDATA */
			  when	'I'	then 0		/* Instructor */
			  when 	'A'	then 1		/* Agent */
			  when 	'O'	then 2		/* Owner */
			  when	'EMP'	then 3		/* Responsible Staff */
			  when	'SIG'	then 4		/* Signotory */
			else 5				/* others, order by description and sequence */
			end				as 'Bestfit'
		from 	CASENAME CN
		left join NAMETYPE NT			on CN.NAMETYPE = NT.NAMETYPE
		left join NAME N			on CN.NAMENO = N.NAMENO
		where	CN.CASEID = @nCaseId
		order by 'Bestfit', NT.DESCRIPTION, CN.SEQUENCE"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCaseKey	nvarchar(11),
				  @nCaseId	int',
				  @psCaseKey	=@psCaseKey,
				  @nCaseId	=@nCaseId
	End

		
	/* 
	 * populating OFFICIALNUMBERDATE table in CaseData typed dataset 
	 *
	 */
		
	If @nErrorCode = 0
	Begin
		Declare @tOfficialNumberDate table (
			CaseKey 	varchar(11) collate database_default not null,
			NumberTypeId 	int not null,
			OfficialNumber	nvarchar(36) collate database_default null,
			EventDate	datetime null)

		Set @nErrorCode = @@Error

		If @nErrorCode = 0
		Begin
			-- Get Official Numbers with Number Types A, P, R
			Insert into @tOfficialNumberDate (
				CaseKey, 
				NumberTypeId, 
				OfficialNumber, 
				EventDate)
			Select 	@psCaseKey,
				case NT.NUMBERTYPE
				   	when 'A' then 1
					when 'P' then 2
					when 'R' then 3
				end,
				O.OFFICIALNUMBER, 
				CE.EVENTDATE
			from 	NUMBERTYPES NT 
			left join OFFICIALNUMBERS O 		on (O.CASEID    =@nCaseId
			                    			and O.NUMBERTYPE=NT.NUMBERTYPE 
			                    			and O.ISCURRENT =1) 
			left join CASEEVENT CE      		on (CE.CASEID   =@nCaseId
			                    			and CE.EVENTNO  = NT.RELATEDEVENTNO
					    			and CE.CYCLE = 1) 
			where 	NT.NUMBERTYPE in ('A','P','R') 
			and 	(O.OFFICIALNUMBER is not null 
				 OR  CE.EVENTDATE     is not null)

			Set @nErrorCode = @@Error
		End

		If @nErrorCode = 0
		Begin
			-- Get 1st Priority Official Numbers and Dates
			Insert into @tOfficialNumberDate (
				CaseKey, 
				NumberTypeId, 
				OfficialNumber, 
				EventDate)
			Select 	top 1
				@psCaseKey,
				4,
				coalesce(O.OFFICIALNUMBER, C.CURRENTOFFICIALNO, RC.OFFICIALNUMBER),
				isnull(CE.EVENTDATE,RC.PRIORITYDATE)
			from 	RELATEDCASE RC
			join	SITECONTROL SC 			on (SC.COLCHARACTER=RC.RELATIONSHIP
								and SC.CONTROLID = 'Earliest Priority')
			join	CASERELATION CR 		on (CR.RELATIONSHIP=RC.RELATIONSHIP)
			left Join CASES C 			on (C.CASEID = RC.RELATEDCASEID)
			left Join CASEEVENT CE			on (CE.CASEID = RC.RELATEDCASEID	-- 09/09/2002
								and CE.EVENTNO = isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)
								and CE.CYCLE=1)
			left Join COUNTRY CT			on (CT.COUNTRYCODE=isnull(C.COUNTRYCODE, RC.COUNTRYCODE))
			left join OFFICIALNUMBERS O 		on (O.CASEID = RC.RELATEDCASEID
								and O.NUMBERTYPE = N'A'  
								and O.ISCURRENT = 1)
			where RC.CASEID = @nCaseId
			order by 4,3	-- 09/09/2002

			Set @nErrorCode = @@error
		End

		If @nErrorCode = 0
		Begin
			-- RFC015/RFC100 temporary change
			Declare @priorityEventDate datetime

			Select 	@priorityEventDate = CE.EVENTDATE
			from	CASEEVENT CE
			join 	SITECONTROL SC on (SC.CONTROLID = 'Earliest Priority')
			join	CASERELATION CR on (CR.RELATIONSHIP = SC.COLCHARACTER)
			where 	CE.CASEID = @nCaseId
			and	CE.EVENTNO = isnull(CR.DISPLAYEVENTNO,CR.FROMEVENTNO)
			and	CE.CYCLE = 1

			If @priorityEventDate is not null
			Begin
				if not exists( Select 	*
						from	@tOfficialNumberDate
						where 	NumberTypeId = 4)
				Begin
					Insert into @tOfficialNumberDate (
						CaseKey, 
						NumberTypeId, 
						OfficialNumber, 
						EventDate)
					Values 	(@psCaseKey,
						4,
						null,
						@priorityEventDate)
				End
				Else
				Begin
					Update 	@tOfficialNumberDate
					Set 	OfficialNumber = null,
						EventDate = @priorityEventDate
					where 	NumberTypeId = 4
					and	EventDate > @priorityEventDate	
				End
				Select @nErrorCode = @@Error
			End
		End

		If @nErrorCode = 0
		Begin
			-- Get Next Renewal Date
			Insert into @tOfficialNumberDate (
				CaseKey, 
				NumberTypeId, 
				OfficialNumber, 
				EventDate)
			select 	@psCaseKey,
				5,
				null,
				isnull(CE.EVENTDATE, CE.EVENTDUEDATE) as 'Next Renewal Date'
				from 	SITECONTROL SC
				join 	OPENACTION OA	on (OA.ACTION=SC.COLCHARACTER
							and OA.CYCLE= (	select min(OA1.CYCLE)
											from OPENACTION OA1
											where OA1.CASEID=OA.CASEID
											and   OA1.ACTION=OA.ACTION
											and   OA1.POLICEEVENTS=1))
				join 	CASEEVENT CE	on (CE.CASEID = OA.CASEID
							and CE.EVENTNO = -11
							and CE.CYCLE=OA.CYCLE)
				where 	SC.CONTROLID='Main Renewal Action'
				and 	OA.CASEID = @nCaseId

			Set @nErrorCode = @@error
		End

		If @nErrorCode = 0
		Begin
			-- output Official Number Dates
			Select 	CaseKey, NumberTypeId, OfficialNumber, EventDate
				from 	@tOfficialNumberDate
				order by NumberTypeId
				
			Set @nErrorCode = @@Error
		End
	End

	/* 
	 * populating DESIGNATEDCOUNTRY table in CaseData typed dataset 
	 *
	 */
	
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select 	@psCaseKey + '^' + 
			cast(RC.RELATIONSHIPNO as varchar(11)) + '^' + 
			CG.MEMBERCOUNTRY
							as 'DesignatedCountryRowKey',
			@psCaseKey			as 'CaseKey',
			RC.RELATIONSHIPNO 		as 'Sequence',
			MC.COUNTRYCODE 			as 'CountryKey',
			MC.COUNTRYCODE 			as 'CountryCode',
			MC.COUNTRY 			as 'CountryName',
			case 
			when RC.CASEID is NULL 	
			then 0 
			else 1 
			end 				as 'IsDesignated',
			isnull(CF.NATIONALALLOWED, 0) 	as 'IsNationalPhase'
		from CASES C
		join COUNTRYGROUP CG 			on (CG.TREATYCODE = C.COUNTRYCODE )
		join COUNTRY MC 			on (MC.COUNTRYCODE = CG.MEMBERCOUNTRY )
		join CASEEVENT CE 			on (CE.CASEID = C.CASEID 
							and CE.EVENTNO = -16 
							and (MC.DATECOMMENCED <= CE.EVENTDATE  or MC.DATECOMMENCED is null) 
							and (MC.DATECEASED > CE.EVENTDATE or MC.DATECEASED is null))
		left join RELATEDCASE RC 		on (C.CASEID = RC.CASEID 
							and RC.RELATIONSHIP = 'DC1' 
							and RC.COUNTRYCODE = CG.MEMBERCOUNTRY)
		left join COUNTRYFLAGS CF 		on (CF.COUNTRYCODE = C.COUNTRYCODE 
							and CF.FLAGNUMBER = RC.CURRENTSTATUS)
		where C.CASEID = @nCaseId"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCaseKey	nvarchar(11),
				  @nCaseId	int',
				  @psCaseKey	=@psCaseKey,
				  @nCaseId	=@nCaseId
	End
	
	/* 
	 * populating EXPENSE table in CaseData typed dataset 
	 *
	 */

	if @nErrorCode = 0
	begin
		Set @sSQLString = "
		select 	Cast(CTL.COSTID as varchar(11)) + '^' + 
			Cast(CTL.COSTLINENO as varchar(10))
							as 'ExpenseRowKey',
			@psCaseKey 			as 'CaseKey',
			CTL.COSTID 			as 'CostKey',
			CTL.COSTLINENO			as 'Sequence',
			WIPT.WIPTYPEID			as 'ExpenseTypeKey',
			WIP.DESCRIPTION			as 'ExpenseTypeDescription',
			CTL.WIPCODE			as 'ExpenseCategoryKey',
			WIPT.DESCRIPTION		as 'ExpenseCategoryDescription',
			Cast(CT.AGENTNO as varchar(11))	as 'SupplierKey',
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) 
							as 'SupplierDisplayName',
			CT.INVOICEDATE			as 'ExpenseDate',
			CT.INVOICEREF			as 'SupplierInvoiceNo',
			SC.COLCHARACTER				as 'CurrencyCode',
			CTL.LOCALAMT			as 'LocalAmount',
			isnull(CTL.SHORTNARRATIVE,CTL.LONGNARRATIVE)	
							as 'Notes'
		from	COSTTRACKLINE CTL
		left join WIPTEMPLATE WIPT 		on (WIPT.WIPCODE = CTL.WIPCODE)
		left join WIPTYPE WIP			on (WIPT.WIPTYPEID = WIP.WIPTYPEID)
		left join COSTTRACK CT			on (CTL.COSTID = CT.COSTID)
		left join NAME N			on (CT.AGENTNO = N.NAMENO)
		left join SITECONTROL SC		on (SC.CONTROLID = 'CURRENCY')
		where	CTL.CASEID = @nCaseId"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCaseKey	nvarchar(11),
				  @nCaseId	int',
				  @psCaseKey	=@psCaseKey,
				  @nCaseId	=@nCaseId
	end

	/* 
	 * populating CLASSES table in CaseData typed dataset 
	 *
	 */

	if @nErrorCode = 0
	begin
		select	@sLocalClasses=LOCALCLASSES,
			@sCountryCode =COUNTRYCODE
		from CASES
		where CASEID=@nCaseId

		set @nErrorCode = @@Error

		If @nErrorCode=0
		begin    
			Set @sSQLString = "
			select  cast(@nCaseId as varchar(11))     + '^' + 
				T.Parameter  			  + '^' + 
				cast(CT.TEXTNO as varchar(11))	as 'ClassesRowKey',
				@nCaseId			as 'CaseKey',
				T.Parameter 			as 'TrademarkClassKey',  
				CT.TEXTNO			as 'TrademarkClassSequence',
				T.Parameter 			as 'TrademarkClass',  
				case when (CT.LONGFLAG=1)		
					then 	TEXT
					else	SHORTTEXT		
				end				as 'TrademarkClassText',
				CL.FIRSTUSE			as 'FirstUse',
				CL.FIRSTUSEINCOMMERCE		as 'FirstUseInCommerce'
			from	dbo.fn_Tokenise(@sLocalClasses,',') T
			left join CASETEXT CT	   on (CT.CASEID = @nCaseId
						   and CT.TEXTTYPE = 'G'
						   and CT.CLASS = T.Parameter
						   and CT.LANGUAGE is null
						   and  (  convert(nvarchar(24),CT.MODIFIEDDATE, 21)+cast(CT.TEXTNO as nvarchar(6)) ) 
								 = 
						      ( select max(convert(nvarchar(24), CT2.MODIFIEDDATE, 21)+cast(CT2.TEXTNO as nvarchar(6)) )
						        from CASETEXT CT2
						        where CT2.CASEID=CT.CASEID
						        and   CT2.TEXTTYPE=CT.TEXTTYPE
						        and   CT2.LANGUAGE is null
						        and   CT2.CLASS=CT.CLASS
						      )
			                           )  			
			left join CLASSFIRSTUSE CL on (CL.CLASS = T.Parameter
						   and CL.CASEID = @nCaseId)
			order by T.Parameter"

			exec @nErrorCode = sp_executesql @sSQLString,
					N'@psCaseKey	nvarchar(11),
					  @nCaseId	int,
					  @sLocalClasses nvarchar(255),
					  @sCountryCode nvarchar(3)',
					  @psCaseKey	=@psCaseKey,
					  @nCaseId	=@nCaseId,
					  @sLocalClasses=@sLocalClasses,
					  @sCountryCode	=@sCountryCode
		end
	end

	
	/* 
	 * populating ATTACHMENT table in CaseData typed dataset 
	 *
	 */

	if @nErrorCode = 0
	begin
		Set @sSQLString = "
		select	@psCaseKey + '^' +
			cast(CI.IMAGEID as varchar(11)) + '^' +
			cast(CI.IMAGETYPE as varchar(11)) + '^' +
			cast(CI.IMAGESEQUENCE as varchar(10))
							as 'AttachmentRowKey',
			CI.CASEID 		as CaseKey,
			CI.IMAGEID 		as AttachmentKey,
			CI.IMAGETYPE 		as AttachmentTypeKey,
			CI.IMAGESEQUENCE 	as Sequence,
			ISNULL(CI.CASEIMAGEDESC, D.IMAGEDESC) as AttachmentName,
			NULL 			as FilePath
		FROM CASEIMAGE CI
		JOIN IMAGE I ON (CI.IMAGEID = I.IMAGEID)
		JOIN IMAGEDETAIL D ON (CI.IMAGEID = D.IMAGEID)
		WHERE CI.CASEID = @nCaseId
				
		UNION 
		
		-- this information is only returned if the CPA Inprostart Case Attachment
		-- site control is turned on.
		
		select	@psCaseKey + '^' +
			cast(A.CASEID as varchar(11)) + '^' +
			cast(A.ACTIVITYNO as varchar(11)) + '^' +
			cast(AA.SEQUENCENO as varchar(10))
							as 'AttachmentRowKey',
			A.CASEID 		as CaseKey,
			NULL 			as AttachmentKey,
			NULL 			as AttachmentTypeKey,
			NULL 			as Sequence,
			AA.ATTACHMENTNAME 	as AttachmentName,
			AA.FILENAME 		as FilePath
		FROM    ACTIVITY A
		JOIN	ACTIVITYATTACHMENT AA	ON (AA.ACTIVITYNO=A.ACTIVITYNO)
		JOIN	SITECONTROL SC ON SC.CONTROLID = 'CPA Inprostart Case Attachment'
		AND 	COLBOOLEAN = 1
		WHERE	A.CASEID = @nCaseId
		ORDER BY 5"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@psCaseKey	nvarchar(11),
				  @nCaseId	int',
				  @psCaseKey	=@psCaseKey,
				  @nCaseId	=@nCaseId
	end

-- RFC03 Case Workflow
	-- Load the actions that are available for the case
	If @nErrorCode = 0
	Begin
		Insert into @tAction (ACTION, ACTIONNAME, CYCLE, DISPLAYSEQUENCE, 
				CRITERIANO, ISNEW, ISOPEN, NUMCYCLESALLOWED)
		select  A.ACTION, 
			isnull(VA.ACTIONNAME,A.ACTIONNAME), 
			isnull(OA.CYCLE,1),
			VA.DISPLAYSEQUENCE,
			isnull(OA.CRITERIANO,dbo.fn_GetCriteriaNo(C.CASEID, 'E', A.ACTION, getdate(),@nProfileKey)),
			case when OA.ACTION is null then 1 else 0 end,
			case when OA.POLICEEVENTS = 1 then 1 else 0 end,
			A.NUMCYCLESALLOWED
		FROM	ACTIONS A
		join	CASES C		on (C.CASEID = @nCaseId)
		left join OPENACTION OA on (OA.CASEID = C.CASEID
					and OA.ACTION = A.ACTION)
		left join VALIDACTION VA on (VA.ACTION = A.ACTION 
		                       and VA.CASETYPE = C.CASETYPE
		                       and VA.PROPERTYTYPE = C.PROPERTYTYPE
		                       and VA.COUNTRYCODE = ( select min (VA1.COUNTRYCODE)
		                                              from  VALIDACTION VA1
		                                              where VA1.COUNTRYCODE in ('ZZZ', C.COUNTRYCODE)
		                                              and   VA1.PROPERTYTYPE = C.PROPERTYTYPE
		                                              and   VA1.CASETYPE = C.CASETYPE
		                                            )
					)
		WHERE 	(OA.ACTION IS NOT NULL OR
			 VA.ACTION IS NOT NULL)	
	
		Set @nErrorCode = @@ERROR
	End
	
	-- Remove any actions that don't have a criteria - they cannot be processed
	If @nErrorCode = 0
	Begin
		Delete from @tAction
		Where CRITERIANO is null
	
		Set @nErrorCode = @@ERROR
	End
	
	-- Produce the result set for Action
	If @nErrorCode = 0
	Begin
		select  A.ACTION       		as 'ActionKey',
		        A.CYCLE        		as 'Cycle',
			@psCaseKey		as 'CaseKey',
		        A.ACTIONNAME 		as 'ActionDescription',
		        A.CRITERIANO   		as 'CriteriaKey',
		        A.ISOPEN       		as 'IsOpen',
			A.ISNEW	       		as 'IsNew'
		from    @tAction A
		order by A.ISOPEN desc, A.DISPLAYSEQUENCE, A.ACTIONNAME, A.CYCLE
	
		select @nErrorCode = @@ERROR, @nRowCount = @@ROWCOUNT

		-- print 'Action rows = '+convert(nvarchar, @nRowCount)
	End

	-- Load cycle information for cyclic entries in a non-cyclic action
	If @nErrorCode = 0
	Begin
		Insert into @tEntryCycles(CRITERIANO, ENTRYNUMBER,
				DEFAULTENTRYCYCLE, 
				MAXENTRYCYCLE)
		select	D.CRITERIANO, D.ENTRYNUMBER,
		     	MAX(isnull(CE.CYCLE,1)),
			-- The maximum cycle is the lower of:
			--	the maximum cycle allowed
			--	the highest cycle already entered + 1
			case 	when MAX(isnull(CE.CYCLE,1))<MAX(EC.NUMCYCLESALLOWED)
				then MAX(isnull(CE.CYCLE+1,1))
				else MAX(EC.NUMCYCLESALLOWED)
			end
		from @tAction A
		join DETAILCONTROL D    on (D.CRITERIANO=A.CRITERIANO)
		join DETAILDATES DD	on (DD.CRITERIANO=D.CRITERIANO
		                     	and DD.ENTRYNUMBER=D.ENTRYNUMBER)
		-- EventControl tells us whether the events are cyclic
		Join EVENTCONTROL EC 	ON (EC.CRITERIANO=DD.CRITERIANO
					AND EC.EVENTNO=DD.EVENTNO)
		-- CaseEvent tells us which cycle we are up to
		Left Join CASEEVENT CE 	ON (CE.CASEID = @nCaseId
					AND CE.EVENTNO = DD.EVENTNO)
		where 	A.NUMCYCLESALLOWED = 1
		and 	EC.NUMCYCLESALLOWED > 1
		GROUP BY D.CRITERIANO, D.ENTRYNUMBER

		Set @nErrorCode = @@ERROR
	End

	-- Entry result set
	If @nErrorCode = 0
	Begin
		select  Cast(A.CRITERIANO As nvarchar(11))+'^'+Cast(D.ENTRYNUMBER As nvarchar(11))+'^'+A.ACTION+'^'+Cast(A.CYCLE As nvarchar(10)) as 'EntryRowKey',
			A.CRITERIANO 		as 'CriteriaKey',
			D.ENTRYNUMBER 		as 'EntryNumber',
		        A.ACTION       		as 'ActionKey',
			A.CYCLE     		as 'Cycle',
			@psCaseKey		as 'CaseKey',
			D.ENTRYDESC 		as 'EntryDescription',
			NT.NUMBERTYPE		as 'NumberTypeKey',
			NT.DESCRIPTION 		as 'NumberTypeDescription',
		        N.OFFICIALNUMBER	as 'OfficialNumber',
			case when (	(D.DISPLAYEVENTNO IS NOT NULL and SHOW.EVENTNO IS NULL)
				  OR	(D.HIDEEVENTNO IS NOT NULL AND HIDE.EVENTNO IS NOT NULL))
			then 1 else 0 end	as 'IsHiddenByWorkflow',
			case when (DIM.EVENTNO IS NOT NULL) then 1 else 0 end
						as 'IsDim',
			D.USERINSTRUCTION	as 'UserInstruction',
			D.ATLEAST1FLAG		as 'RequiresAtLeast1Event',
			isnull(TC.DEFAULTENTRYCYCLE,A.CYCLE)
						as 'DefaultEntryCycle',
			TC.MAXENTRYCYCLE	as 'MaxEntryCycle'
		from @tAction A
		join DETAILCONTROL D        	on (D.CRITERIANO=A.CRITERIANO)
		left join @tEntryCycles TC	on (TC.CRITERIANO=D.CRITERIANO
						and TC.ENTRYNUMBER=D.ENTRYNUMBER)
		left join NUMBERTYPES NT    	on (NT.NUMBERTYPE=D.NUMBERTYPE)
		left join OFFICIALNUMBERS N 	on (N.CASEID=@nCaseId
		                            	and N.NUMBERTYPE=NT.NUMBERTYPE
		                            	and N.ISCURRENT =1)
		left join CASEEVENT DIM		On (DIM.EVENTNO = D.DIMEVENTNO
						AND DIM.OCCURREDFLAG between 1 and 8
						AND DIM.CYCLE  = A.CYCLE
						AND DIM.CASEID = @nCaseId )
		left join CASEEVENT SHOW	On (SHOW.EVENTNO = D.DISPLAYEVENTNO
						AND SHOW.OCCURREDFLAG between 1 and 8
						AND SHOW.CYCLE  = A.CYCLE
						AND SHOW.CASEID = @nCaseId )
		left join CASEEVENT HIDE	On (HIDE.EVENTNO = D.HIDEEVENTNO
						AND HIDE.OCCURREDFLAG between 1 and 8
						AND HIDE.CYCLE  = A.CYCLE
						AND HIDE.CASEID = @nCaseId )
		order by A.ACTION, A.CYCLE, D.DISPLAYSEQUENCE, D.ENTRYNUMBER
	
		select @nErrorCode = @@ERROR, @nRowCount = @@ROWCOUNT

		-- print 'ActionEntry rows = '+convert(nvarchar, @nRowCount)
	End

	-- When there are cyclic events for non-cyclic actions, the normal
	-- SQL joins will locate potential events for Cycle 1.  They will also
	-- return the actual events for higher cycles already created.  However,
	-- we need to find out what events have not been entered in each of
	-- the existing cycles, and the new cycle, and provide proforma
	-- rows for them.
	If @nErrorCode = 0
	Begin
		select @nHighestCycle = max(MAXENTRYCYCLE)
		from @tEntryCycles

		set @nErrorCode = @@ERROR
	End

	Set @nCycle = 2
	While 	@nErrorCode = 0
	and	@nCycle<=@nHighestCycle
	Begin
		insert into @tPotentialCyclicEvents
			(CRITERIANO, ENTRYNUMBER, EVENTNO, CYCLE, 
			EVENTDESCRIPTION, 
			DUEATTRIBUTE, EVENTATTRIBUTE, 
			POLICINGATTRIBUTE, PERIODATTRIBUTE, DISPLAYSEQUENCE)
		select  
			DD.CRITERIANO, DD.ENTRYNUMBER,DD.EVENTNO, 
			@nCycle, isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION), 
			DD.DUEATTRIBUTE, DD.EVENTATTRIBUTE,
			DD.POLICINGATTRIBUTE, DD.PERIODATTRIBUTE, DD.DISPLAYSEQUENCE
		from @tEntryCycles TC
		join DETAILDATES DD	on (DD.CRITERIANO=TC.CRITERIANO
		                     	and DD.ENTRYNUMBER=TC.ENTRYNUMBER)
		join EVENTCONTROL EC 	on (EC.EVENTNO=DD.EVENTNO
		                        and EC.CRITERIANO=DD.CRITERIANO)
		join EVENTS E           on (E.EVENTNO=DD.EVENTNO)
		where TC.MAXENTRYCYCLE >= @nCycle
		and EC.NUMCYCLESALLOWED >= @nCycle
		and not exists
			(select 1
			from CASEEVENT CE
			where CE.CASEID=@nCaseId
                        and CE.EVENTNO=DD.EVENTNO
                        and CE.CYCLE=@nCycle)

		set @nErrorCode = @@ERROR

		set @nCycle = @nCycle + 1
	End

	-- Generate a display sequence for ad hoc reminders
	If @nErrorCode = 0
	Begin
		Insert into @tAdHoc (EMPLOYEENO, ALERTSEQ)
		select  EMPLOYEENO, ALERTSEQ
		from    ALERT
		Where 	CASEID = @nCaseId
		Order by DUEDATE
	End

	-- EntryEvent result set
	If @nErrorCode = 0
	Begin
		select  Cast(A.CRITERIANO As nvarchar(11))+'^'+Cast(D.ENTRYNUMBER As nvarchar(11))+'^'+A.ACTION+'^'+Cast(A.CYCLE As nvarchar(10))
				+'^'+Cast(DD.EVENTNO As nvarchar(11))+'^'+Cast(isnull(CE.CYCLE,A.CYCLE)As nvarchar(10)) 
							as 'EntryEventRowKey',
			A.CRITERIANO 			as 'CriteriaKey',
			D.ENTRYNUMBER	 		as 'EntryNumber',
 		        A.ACTION       			as 'ActionKey',
		        A.CYCLE     			as 'Cycle',
			@psCaseKey			as 'CaseKey',
			cast(DD.EVENTNO as nvarchar(11))as 'EventKey',
			isnull(CE.CYCLE,A.CYCLE)	as 'EventCycle',
			isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION) 
							as 'EventDescription',
			CE.EVENTDUEDATE 		as 'EventDueDate',
			DD.DUEATTRIBUTE			as 'DueDateAttribute',
			CE.EVENTDATE			as 'EventDate',
			DD.EVENTATTRIBUTE		as 'EventDateAttribute',
			cast(CE.OCCURREDFLAG as bit)	as 'IsStopPolicing',
			DD.POLICINGATTRIBUTE		as 'StopPolicingAttribute',
			CE.ENTEREDDEADLINE		as 'Period',
			CE.PERIODTYPE			as 'PeriodTypeKey',
			DD.PERIODATTRIBUTE		as 'PeriodAttribute',
			CE.DATEREMIND			as 'NextPoliceDate',
			DD.DISPLAYSEQUENCE		as 'DisplaySequence',
			case when CE.EVENTNO IS NULL then 1 else 0 end
							as 'IsNew',
			case when CE.LONGFLAG = 1 then CE.EVENTLONGTEXT else CE.EVENTTEXT end
							as 'EventText',
			null				as 'AlertEmployeeKey',
			null				as 'AlertDateCreated'
		from @tAction A
		join DETAILCONTROL D	on (D.CRITERIANO=A.CRITERIANO)
		join DETAILDATES DD	on (DD.CRITERIANO=D.CRITERIANO
		                     	and DD.ENTRYNUMBER=D.ENTRYNUMBER)
		join EVENTS E           on (E.EVENTNO=DD.EVENTNO) 
		left join CASEEVENT CE  on (CE.CASEID=@nCaseId
		                        and CE.EVENTNO=DD.EVENTNO
		                        and CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN A.CYCLE ELSE CE.CYCLE END)
		left join EVENTCONTROL EC on (EC.EVENTNO=DD.EVENTNO
		                          and EC.CRITERIANO=isnull(CE.CREATEDBYCRITERIA, DD.CRITERIANO))
		union all
		-- Potential cyclic events within non-cyclic actions
		select  Cast(A.CRITERIANO As nvarchar(11))+'^'+Cast(PE.ENTRYNUMBER As nvarchar(11))+'^'+A.ACTION+'^'+Cast(A.CYCLE As nvarchar(10))
				+'^'+Cast(PE.EVENTNO As nvarchar(11))+'^'+Cast(PE.CYCLE As nvarchar(10)) 
							as 'EntryEventRowKey',
			PE.CRITERIANO			as 'CriteriaKey',
			PE.ENTRYNUMBER			as 'EntryNumber',
		        A.ACTION       			as 'ActionKey',
		        A.CYCLE     			as 'Cycle',
			@psCaseKey			as 'CaseKey',
			cast(PE.EVENTNO as nvarchar(11))as 'EventKey',
			PE.CYCLE			as 'EventCycle',
			PE.EVENTDESCRIPTION		as 'EventDescription',
			NULL 				as 'EventDueDate',
			PE.DUEATTRIBUTE			as 'DueDateAttribute',
			NULL				as 'EventDate',
			PE.EVENTATTRIBUTE		as 'EventDateAttribute',
			0				as 'IsStopPolicing',
			PE.POLICINGATTRIBUTE		as 'StopPolicingAttribute',
			NULL				as 'Period',
			NULL				as 'PeriodTypeKey',
			PE.PERIODATTRIBUTE		as 'PeriodAttribute',
			NULL				as 'NextPoliceDate',
			PE.DISPLAYSEQUENCE		as 'DisplaySequence',
			1 				as 'IsNew',
			null				as 'EventText',
			null				as 'AlertEmployeeKey',
			null				as 'AlertDateCreated'
		from @tPotentialCyclicEvents PE
		join @tAction A	on (A.CRITERIANO = PE.CRITERIANO)
		union all
		-- Ad Hoc Reminders
		select  '1^'+Cast(AH.IDENT As nvarchar(11))+'^__^1^'+Cast(AH.EMPLOYEENO As nvarchar(11))+'^'+Convert(nvarchar(25), AH.ALERTSEQ, 126 ) 
							as 'EntryEventRowKey',
			1 				as 'CriteriaKey',
			1 				as 'EntryNumber',
			'__'				as 'ActionKey',
		        1		     		as 'Cycle',
			@psCaseKey			as 'CaseKey',
			cast(AH.IDENT as nvarchar(11))	as 'EventKey',
			1				as 'EventCycle',
			AL.ALERTMESSAGE			as 'EventDescription',
			AL.DUEDATE	 		as 'EventDueDate',
			3				as 'DueDateAttribute',	-- Optional
			AL.DATEOCCURRED			as 'EventDate',
			3				as 'EventDateAttribute', -- Optional
			cast(AL.OCCURREDFLAG as bit)	as 'IsStopPolicing',
			2				as 'StopPolicingAttribute',	-- Hidden
			null				as 'Period',
			null				as 'PeriodTypeKey',
			2				as 'PeriodAttribute',
			null				as 'NextPoliceDate',	-- Hidden
			AH.IDENT			as 'DisplaySequence',
			0				as 'IsNew',
			null				as 'EventText',
			cast(AL.EMPLOYEENO as nvarchar(11))
							as 'AlertEmployeeKey',
			AL.ALERTSEQ			as 'AlertDateCreated'
		from @tAdHoc AH
		JOIN ALERT AL ON 	(AL.EMPLOYEENO = AH.EMPLOYEENO
					AND AL.ALERTSEQ = AH.ALERTSEQ)
		-- Note it is not possible to sort this table because of the
		-- combination of the EventLongText defined as nText with a UNION
	
		select @nErrorCode = @@ERROR, @nRowCount = @@ROWCOUNT

		-- print 'EntryEvent rows = '+convert(nvarchar, @nRowCount)
	End
	
	-- ActionEvent result set
	If @nErrorCode = 0
	Begin
		select  A.ACTION+'^'+Cast(A.CYCLE As nvarchar(10))
				+'^'+@psCaseKey+'^'+Cast(EC.EVENTNO As nvarchar(11))
				+'^'+Cast(isnull(CE.CYCLE,A.CYCLE) As nvarchar(10)) as 'ActionEventRowKey',
			A.ACTION       			as 'ActionKey',
			A.CYCLE     			as 'Cycle',
			A.CRITERIANO 			as 'CriteriaKey',
			@psCaseKey			as 'CaseKey',
			cast(EC.EVENTNO as nvarchar(11))as 'EventKey',
			isnull(CE.CYCLE,A.CYCLE)	as 'EventCycle',
			isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION) 
							as 'EventDescription',
			CE.EVENTDUEDATE			as 'EventDueDate',
			CE.EVENTDATE			as 'EventDate',
			CE.DATEREMIND			as 'NextPoliceDate',
			EC.DISPLAYSEQUENCE		as 'DisplaySequence',
			case when CE.EVENTNO IS NULL then 1 else 0 end
							as 'IsNew',
			cast (CE.DATEDUESAVED as bit)	as 'IsDateDueSaved',
			case when CE.LONGFLAG = 1 then CE.EVENTLONGTEXT else CE.EVENTTEXT end
							as 'EventText',
			null				as 'AlertEmployeeKey',
			null				as 'AlertDateCreated'
		from @tAction A
		join EVENTCONTROL EC 	on (EC.CRITERIANO=A.CRITERIANO)
		join EVENTS E           on (E.EVENTNO=EC.EVENTNO)
		left join CASEEVENT CE  on (CE.CASEID=@nCaseId
		                        and CE.EVENTNO=EC.EVENTNO
		                        and CE.CYCLE=CASE WHEN(A.NUMCYCLESALLOWED>1) THEN A.CYCLE ELSE CE.CYCLE END
					and CE.OCCURREDFLAG < 9 )
		where	
			-- Exclude events that have only an occurred flag (Stop Police)
			((CE.EVENTNO IS NULL)
			or
			 (CE.EVENTDUEDATE IS NOT NULL OR
			  CE.EVENTDATE IS NOT NULL))
		union all
		select  '__^1^'+Cast(AH.EMPLOYEENO As nvarchar(11))+'^'+Convert(nvarchar(25), AH.ALERTSEQ, 126 ) as 'ActionEventRowKey',
			'__'				as 'ActionKey',
			1     				as 'Cycle',
			1 				as 'CriteriaKey',
			@psCaseKey			as 'CaseKey',
			cast(AH.IDENT as nvarchar(11))	as 'EventKey',
			1				as 'EventCycle',
			AL.ALERTMESSAGE			as 'EventDescription',
			AL.DUEDATE			as 'EventDueDate',
			AL.DATEOCCURRED			as 'EventDate',
			null				as 'NextPoliceDate',
			AH.IDENT			as 'DisplaySequence',
			0				as 'IsNew',
			1				as 'IsDateDueSaved',
			null				as 'EventText',
			cast(AL.EMPLOYEENO as nvarchar(11))
							as 'AlertEmployeeKey',
			AL.ALERTSEQ			as 'AlertDateCreated'
		from @tAdHoc AH
		JOIN ALERT AL ON 	(AL.EMPLOYEENO = AH.EMPLOYEENO
					AND AL.ALERTSEQ = AH.ALERTSEQ)
		-- Note it is not possible to sort this table because of the
		-- combination of the EventLongText defined as nText with a UNION

		select @nErrorCode = @@ERROR, @nRowCount = @@ROWCOUNT

		-- print 'ActionEvent rows = '+convert(nvarchar, @nRowCount)
	End

	/* 
	 * populating CASEEVENTS table in CaseData typed dataset 
	 *
	 */

	if @nErrorCode = 0
	begin

		Select 	@psCaseKey			as 'CaseKey',
			Cast(CE.EVENTNO as varchar(11))	as 'EventKey',
			CE.CYCLE			as 'Cycle',	
			isnull(EC.EVENTDESCRIPTION, E.EVENTDESCRIPTION) 
							as 'EventDescription',
			CE.EVENTDUEDATE			as 'EventDueDate',
			CE.EVENTDATE			as 'EventDate',
			CE.DATEREMIND			as 'NextPoliceDate',
			cast (CE.DATEDUESAVED as bit)	as 'IsDateDueSaved',
			case when CE.LONGFLAG = 1 then CE.EVENTLONGTEXT else CE.EVENTTEXT end
							as 'EventText',
			0				as 'IsAdHocReminder'
		from CASEEVENT CE
		left join EVENTCONTROL EC	on (EC.EVENTNO = CE.EVENTNO
						and EC.CRITERIANO = CE.CREATEDBYCRITERIA)
		join EVENTS E           	on (E.EVENTNO=CE.EVENTNO)
		where	CE.CASEID = @nCaseId
		and	(CE.OCCURREDFLAG < 9 OR CE.OCCURREDFLAG IS NULL)
		and	(CE.EVENTDATE IS NOT NULL OR CE.EVENTDUEDATE IS NOT NULL)
			-- Due events against closed actions are not relevant
		and	(CE.EVENTDATE IS NOT NULL
			or exists
				(select 1
				from OPENACTION OA
				join EVENTCONTROL OEC	on (OEC.EVENTNO = CE.EVENTNO
							and OEC.CRITERIANO = OA.CRITERIANO)
				where OA.CASEID = CE.CASEID
				and	OA.POLICEEVENTS = 1) 
			)
		union all	
		select  @psCaseKey			as 'CaseKey',
			cast(AH.IDENT as nvarchar(11))	as 'EventKey',
			1     				as 'Cycle',
			AL.ALERTMESSAGE			as 'EventDescription',
			AL.DUEDATE			as 'EventDueDate',
			AL.DATEOCCURRED			as 'EventDate',
			null				as 'NextPoliceDate',
			1				as 'IsDateDueSaved',
			null				as 'EventText',
			1				as 'IsAdHocReminder'
		from @tAdHoc AH
		JOIN ALERT AL ON 	(AL.EMPLOYEENO = AH.EMPLOYEENO
					AND AL.ALERTSEQ = AH.ALERTSEQ)
		-- Note it is not possible to sort this table because of the
		-- combination of the EventLongText defined as nText with a UNION

		select @nErrorCode = @@ERROR, @nRowCount = @@ROWCOUNT

		-- print 'CaseEvent rows = '+convert(nvarchar, @nRowCount)
	end	

	return @nErrorCode

end

GO

Grant execute on dbo.cs_ListCaseData to public
GO
SET QUOTED_IDENTIFIER OFF 
GO