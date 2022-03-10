-----------------------------------------------------------------------------------------------------------------------------
-- Creation of de_ListCaseComparisonData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[de_ListCaseComparisonData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.de_ListCaseComparisonData.'
	Drop procedure [dbo].[de_ListCaseComparisonData]
End
Print '**** Creating Stored Procedure dbo.de_ListCaseComparisonData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.de_ListCaseComparisonData
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psTableNameQualifier	nvarchar(15), 	-- A qualifier appended to the table names to ensure that they are unique.
	@pnCaseKey		int,		-- Mandatory
	@psMode			char(1)		-- I-Imported data, E-Existing data, P-Proposed
)
as
-- PROCEDURE:	de_ListCaseComparisonData
-- VERSION:	20
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns information comparing imported data to the existing case.

--		Note: assumes that imported data has already been loaded and matched
--		by a previous process.

--		@psMode
--		='I' for the data imported from the external system
--		='E' for the existing data on the database
--		='B' to return both 'I' and 'E' result sets
--		='P' for the proposed data.  This is used in a dataset merge with 'E' to
--		 identify changed rows.  It has the same rows as 'E' with the proposed
--		 new values included.


-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Aug 2005	JEK	RFC1324	1	Procedure created
-- 20 Sep 2005	JEK	RFC1324	2	Extend processing.
-- 23 Sep 2005	JEK	RFC1324	3	Extend processing.
-- 13 Oct 2005	JEK	RFC3007	4	Only return event description when there is a corresponding date.
-- 18 Oct 2005	TM	RFC3120	5	Modify to sort the output by IMP_RELATIONSHIPCODE and the new sequence attribute. 
-- 18 Oct 2005	TM	RFC3005	6	Correct the CaseEvents logic.
-- 25 Oct 2005	JEK	RFC3128	7	Display imported number type description.
-- 26 Oct 2005	TM	RFC2177	8	In the ImportedCaseName result set, return the NameTypeKey column. Also, change 
--					the NameTypeDescription to the value from InproTech instead of USPTO\PAIR.
-- 28 Oct 2005	TM	RFC3128	9	Use MAP_NAMETYPEKEY instead of the EX_NAMETYPEKEY to populate the NameTypeKey
--					column in the ImportedCaseName result set.
-- 06 Jan 2006	TM	RFC3375	10	Modify the population of the existing (@psMode = 'E') related cases to use 
--					Application No instead of RCC.CURRENTOFFICIALNO for the CurrentOfficialNo column.
-- 10 Jan 2006	TM	RFC3375	11	If Application Number does not exists then use Current Official Number for 
--					the CurrentOfficialNo column.
-- 12 May 2006	JEK	RFC3009	12	Implement proposed values result sets.
-- 18 May 2006	JEK	RFC3009	13	Implement new mode B that returns both 'I' and 'E' result sets.
-- 24 May 2006	JEK	RFC3009	14	Return EventKey is OfficialNumbers result set.
-- 06 Jun 2006	JEK	RFC3009 15	Proposed result set was not returning new rows.
-- 07 Jun 2006	JEK	RFC3009	16	Proposed Offical Numbers should used proposed ISCURRENT.
-- 17 Aug 2006	JEK	RFC4241	17	Add international classes.
-- 30 Aug 2006	AU	RFC4062	18	Check EARLIEST PRIORITY site control before returning application number as
--					CurrentOfficialNumber
-- 11 Dec 2008	MF	17136	19	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 08 Dec 2014	SF	14184	20	Do not return null for sync id for case names.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode		int
declare @sSQLString		nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

declare @sSenderTable		nvarchar(50)
declare @sCaseTable		nvarchar(50)
declare @sOfficialNumberTable	nvarchar(50)
declare @sRelatedCaseTable	nvarchar(50)
declare @sEventTable		nvarchar(50)
declare @sCaseNameTable		nvarchar(50)

-- Each element that is compared is assigned a Match confidence as follows:
declare @sMatchNotApplicable	char
declare @sMatchAbsent		char
declare @sMatchDifferent	char
declare @sMatchSimilar		char
declare @sMatchVerySimilar	char
declare @sMatchSame		char
declare @sMatchBoundary		char
Set @sMatchNotApplicable = null -- e.g. data is not present to match.
Set @sMatchAbsent = 0		-- Corresponding data does not exist in the system
Set @sMatchDifferent = 1	-- Data exists but is different
Set @sMatchSimilar = 3		-- Data exists and is similar
Set @sMatchVerySimilar = 4	-- Data exists and is very similar
Set @sMatchSame = 5		-- Data exists and is considered the same

Set @sMatchBoundary = @sMatchSimilar -- The match level below which an item is considered different

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @sSenderTable = 'CC_SENDER' + @psTableNameQualifier
Set @sCaseTable = 'CC_CASE' + @psTableNameQualifier
Set @sOfficialNumberTable = 'CC_OFFICIALNUMBER' + @psTableNameQualifier
Set @sRelatedCaseTable = 'CC_RELATEDCASE' + @psTableNameQualifier
Set @sEventTable = 'CC_CASEEVENT' + @psTableNameQualifier
Set @sCaseNameTable = 'CC_CASENAME' + @psTableNameQualifier

-- Sender
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	S.SYSTEMNAME 	as SystemName
	from 	"+@sSenderTable+" CC
	left join EXTERNALSYSTEM S	on (S.SYSTEMCODE=CC.IMP_SYSTEMCODE)"

	exec @nErrorCode = sp_executesql @sSQLString

End

-- Case
If @nErrorCode = 0
Begin
	If (@psMode = 'I' or @psMode = 'B' or @psMode is null)
	and @nErrorCode = 0
	Begin
		Set @sSQLString = "
		select	EX_CASEKEY		as CaseKey,
			IMP_CASEREFERENCE	as CaseReference,
			IMP_SHORTTITLE		as ShortTitle,
			IMP_CASESTATUSDESCRIPTION
						as StatusDescription,
			IMP_CASESTATUSDATE	as CaseStatusDate,
			IMP_LOCALCLASSES	as LocalClasses,
			IMP_INTCLASSES		as IntClasses,
			case when CASEREFERENCEMATCH < "+@sMatchBoundary+" then 1
			     when CASEREFERENCEMATCH is null then null
			     else 0
			end			as IsCaseReferenceDifferent,
			case when LOCALCLASSMATCH < "+@sMatchBoundary+" then 1
			     when LOCALCLASSMATCH is null then null
			     else 0
			end			as IsLocalClassesDifferent,
			case when INTCLASSMATCH < "+@sMatchBoundary+" then 1
			     when INTCLASSMATCH is null then null
			     else 0
			end			as IsIntClassesDifferent,
			case when SHORTTITLEMATCH < "+@sMatchBoundary+" then 1
			     when SHORTTITLEMATCH is null then null
			     else 0
			end			as IsShortTitleDifferent
		from "+@sCaseTable+"
		where EX_CASEKEY = @pnCaseKey"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey

	End

	If (@psMode = 'E' or @psMode = 'B' or @psMode is null)
	and @nErrorCode = 0   
	Begin
		Set @sSQLString = "
		select	EX_CASEKEY		as CaseKey,
			EX_CASEREFERENCE	as CaseReference,
			EX_SHORTTITLE		as ShortTitle,
			SHORTTITLEUPDATE	as IsShortTitleUpdateable,
			"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura) +"
						as StatusDescription,
			EX_LOCALCLASSES		as LocalClasses,
			EX_INTCLASSES		as IntClasses
		from "+@sCaseTable+"
		join	CASES C			on (EX_CASEKEY=C.CASEID)
		Left Join STATUS ST		on (ST.STATUSCODE=C.STATUSCODE)
		where EX_CASEKEY = @pnCaseKey"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End

	-- Produce with same result set as existing, with proposed changes made.
	If (@psMode = 'P' or @psMode is null)
	and @nErrorCode = 0   
	Begin
		Set @sSQLString = "
		select	EX_CASEKEY		as CaseKey,
			EX_CASEREFERENCE	as CaseReference,
			isnull(PR_SHORTTITLE,EX_SHORTTITLE)
						as ShortTitle,
			SHORTTITLEUPDATE	as IsShortTitleUpdateable,
			"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura) +"
						as StatusDescription,
			EX_LOCALCLASSES		as LocalClasses,
			EX_INTCLASSES		as IntClasses
		from "+@sCaseTable+"
		join	CASES C			on (EX_CASEKEY=C.CASEID)
		Left Join STATUS ST		on (ST.STATUSCODE=C.STATUSCODE)
		where EX_CASEKEY = @pnCaseKey"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End

End

-- OfficialNumber
If @nErrorCode = 0
Begin
	If (@psMode = 'I'  or @psMode = 'B' or @psMode is null)
	and @nErrorCode = 0
	Begin
		Set @sSQLString = "
		select	SYNCHID			as SynchID,
			EX_CASEKEY		as CaseKey,
			isnull(IMP_NUMBERTYPEDESCRIPTION,
				"+dbo.fn_SqlTranslatedColumn('NUMBERTYPE','DESCRIPTION',null,'N',@sLookupCulture,@pbCalledFromCentura) +")
						as NumberTypeDescription,
			IMP_OFFICIALNUMBER	as OfficialNumber,
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) +"
						as EventDescription,
			IMP_EVENTDATE		as EventDate,
			case when OFFICIALNUMBERMATCH < "+@sMatchBoundary+" then 1
			     when OFFICIALNUMBERMATCH is null then null
			     else 0
			end			as IsOfficialNumberDifferent,
			case when EVENTDATEMATCH < "+@sMatchBoundary+" then 1
			     when EVENTDATEMATCH is null then null
			     else 0
			end			as IsEventDateDifferent,
			case when (OFFICIALNUMBERMATCH < "+@sMatchBoundary+" or
			           EVENTDATEMATCH < "+@sMatchBoundary+") then 1
			     else 0
			end			as IsDifferent
		from "+@sOfficialNumberTable+"
		left join NUMBERTYPES N		on (N.NUMBERTYPE=MAP_NUMBERTYPEKEY)
		left join EVENTS E		on (E.EVENTNO=EX_EVENTKEY
						and IMP_EVENTDATE is not null)
		where EX_CASEKEY = @pnCaseKey
		order by N.ISSUEDBYIPOFFICE DESC, N.DISPLAYPRIORITY"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End

	If (@psMode = 'E' or @psMode = 'B' or @psMode is null)
	and @nErrorCode = 0  
	Begin
		Set @sSQLString = "
		select	SYNCHID			as SynchID,
			EX_CASEKEY		as CaseKey,
			"+dbo.fn_SqlTranslatedColumn('NUMBERTYPE','DESCRIPTION',null,'N',@sLookupCulture,@pbCalledFromCentura) +"
						as NumberTypeDescription,
			EX_OFFICIALNUMBER	as OfficialNumber,
			OFFICIALNUMBERUPDATE	as IsOfficialNumberUpdateable,
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) +"
						as EventDescription,
			EX_EVENTDATE		as EventDate,
			EVENTDATEUPDATE		as IsEventDateUpdateable,
			EX_NUMBERTYPEKEY	as NumberTypeKey,
			EX_ISCURRENT		as IsCurrent,
			EX_EVENTKEY		as EventKey
		from "+@sOfficialNumberTable+"
		left join NUMBERTYPES N		on (N.NUMBERTYPE=MAP_NUMBERTYPEKEY)
		left join EVENTS E		on (E.EVENTNO=EX_EVENTKEY
						and EX_EVENTDATE is not null)
		where EX_CASEKEY = @pnCaseKey
		and   OFFICIALNUMBERMATCH<>"+@sMatchAbsent+"
		order by N.ISSUEDBYIPOFFICE DESC, N.DISPLAYPRIORITY"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End

	If (@psMode = 'P' or @psMode is null)
	and @nErrorCode = 0  
	Begin
		Set @sSQLString = "
		select	SYNCHID			as SynchID,
			EX_CASEKEY		as CaseKey,
			"+dbo.fn_SqlTranslatedColumn('NUMBERTYPE','DESCRIPTION',null,'N',@sLookupCulture,@pbCalledFromCentura) +"
						as NumberTypeDescription,
			isnull(PR_OFFICIALNUMBER,EX_OFFICIALNUMBER)
						as OfficialNumber,
			OFFICIALNUMBERUPDATE	as IsOfficialNumberUpdateable,
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) +"
						as EventDescription,
			isnull(PR_EVENTDATE,EX_EVENTDATE)
						as EventDate,
			EVENTDATEUPDATE		as IsEventDateUpdateable,
			MAP_NUMBERTYPEKEY	as NumberTypeKey,
			isnull(PR_ISCURRENT,EX_ISCURRENT)
						as IsCurrent,
			EX_EVENTKEY		as EventKey
		from "+@sOfficialNumberTable+"
		left join NUMBERTYPES N		on (N.NUMBERTYPE=MAP_NUMBERTYPEKEY)
		left join EVENTS E		on (E.EVENTNO=EX_EVENTKEY)
		where EX_CASEKEY = @pnCaseKey
		order by N.ISSUEDBYIPOFFICE DESC, N.DISPLAYPRIORITY"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End
End

-- RelatedCase
If @nErrorCode = 0
Begin
	If (@psMode = 'I'  or @psMode = 'B' or @psMode is null)
	and @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select	SYNCHID			as SynchID,
			EX_CASEKEY		as CaseKey,
			isnull(IMP_RELATIONSHIPDESCRIPTION,
				"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'R',@sLookupCulture,@pbCalledFromCentura) +") 
						as RelationshipDescription,
			IMP_PARENTSTATUS	as RelatedCaseStatus,
			null			as CurrentOfficialNumber,
			IMP_OFFICIALNUMBER	as OfficialNumber,
			MAP_COUNTRYKEY		as CountryCode,
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) +"
						as EventDescription,
			IMP_EVENTDATE		as PriorityDate,
			IMP_REGISTRATIONNUMBER	as RegistrationNumber,
			case when RELATIONSHIPMATCH < "+@sMatchBoundary+" then 1
			     when RELATIONSHIPMATCH is null then null
			     else 0
			end			as IsRelationshipDifferent,
			case when OFFICIALNUMBERMATCH < "+@sMatchBoundary+" then 1
			     when OFFICIALNUMBERMATCH is null then null
			     else 0
			end			as IsOfficialNumberDifferent,
			case when EVENTDATEMATCH < "+@sMatchBoundary+" then 1
			     when EVENTDATEMATCH is null then null
			     else 0
			end			as IsEventDateDifferent,
			case when (OFFICIALNUMBERMATCH < "+@sMatchBoundary+" or
			           EVENTDATEMATCH < "+@sMatchBoundary+" or
			           RELATIONSHIPMATCH < "+@sMatchBoundary+") then 1
			     else 0
			end			as IsDifferent
		from "+@sRelatedCaseTable+"
		left join CASERELATION R	on (R.RELATIONSHIP=MAP_RELATIONSHIPKEY)
		left join EVENTS E		on (E.EVENTNO=MAP_EVENTKEY)
		where EX_CASEKEY = @pnCaseKey
		-- Order by IMP_RELATIONSHIPCODE is required to distinguish between SequenceNumbers 
		-- that may be the same on different web pages. 
		order by IMP_RELATIONSHIPCODE, IMP_SEQUENCENUMBER"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End

	-- Note: updates not implemented for related cases yet, so Existing and Proposed are the same.
	If (@psMode = 'E' or @psMode = 'B' or @psMode = 'P' or @psMode is null)
	and @nErrorCode = 0  
	Begin
		Set @sSQLString = "
		Select	SYNCHID			as SynchID,
			EX_CASEKEY		as CaseKey,
			"+dbo.fn_SqlTranslatedColumn('CASERELATION','RELATIONSHIPDESC',null,'R',@sLookupCulture,@pbCalledFromCentura) +"
						as RelationshipDescription,
			"+dbo.fn_SqlTranslatedColumn('STATUS','INTERNALDESC',null,'ST',@sLookupCulture,@pbCalledFromCentura) +"
						as RelatedCaseStatus,
			coalesce(EX_OFFICIALNUMBER,O.OFFICIALNUMBER, RCC.CURRENTOFFICIALNO)
						as CurrentOfficialNumber,
			null			as OfficialNumber,
			EX_COUNTRYKEY		as CountryCode,
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) +"
						as EventDescription,
			EX_EVENTDATE		as PriorityDate,
			NULL			as RegistrationNumber,
			EX_RELATIONSHIPNO	as RelationshipNo,
			EX_RELATIONSHIPKEY	as RelationshipKey,
			EX_RELATEDCASEKEY	as RelatedCaseKey,
			RCC.IRN			as RelatedCaseReference,
			EX_COUNTRYKEY		as CountryKey,
			EX_EVENTKEY		as EventKey
		from "+@sRelatedCaseTable+"
		left join CASERELATION R	on (R.RELATIONSHIP=EX_RELATIONSHIPKEY)
		left join EVENTS E		on (E.EVENTNO=MAP_EVENTKEY)
		left join CASES RCC		on (RCC.CASEID=EX_RELATEDCASEKEY)
		left Join STATUS ST		on (ST.STATUSCODE=RCC.STATUSCODE)
		left join SITECONTROL SC 	on (SC.CONTROLID = 'Earliest Priority')
		left join OFFICIALNUMBERS O	on (O.CASEID = EX_RELATEDCASEKEY
						and O.NUMBERTYPE = N'A'  
						and O.ISCURRENT = 1
						and EX_RELATIONSHIPKEY = SC.COLCHARACTER)
		where EX_CASEKEY = @pnCaseKey
		and   OFFICIALNUMBERMATCH<>"+@sMatchAbsent+"
		-- Order by IMP_RELATIONSHIPCODE is required to distinguish between SequenceNumbers 
		-- that may be the same on different web pages. 
		order by IMP_RELATIONSHIPCODE, IMP_SEQUENCENUMBER"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End
End

-- CaseEvent
If @nErrorCode = 0
Begin
	If (@psMode = 'I'  or @psMode = 'B' or @psMode is null)
	and @nErrorCode = 0
	Begin
		Set @sSQLString = "
		select	SYNCHID			as SynchID,
			EX_CASEKEY		as CaseKey,
			isnull(IMP_EVENTDESCRIPTION,
				"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) +")
						as EventDescription,
			IMP_EVENTDATE		as EventDate,
			IMP_CYCLE		as Cycle,
			case when EVENTDATEMATCH < "+@sMatchBoundary+" then 1
			     else 0
			end			as IsDifferent
		from "+@sEventTable+"
		left join EVENTS E		on (E.EVENTNO=EX_EVENTKEY)
		where EX_CASEKEY = @pnCaseKey
		order by IMP_EVENTDATE desc, IMP_EVENTDESCRIPTION"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End

	If (@psMode = 'E' or @psMode = 'B' or @psMode is null)
	and @nErrorCode = 0  
	Begin
		Set @sSQLString = "
		select	SYNCHID			as SynchID,
			EX_CASEKEY		as CaseKey,
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) +"
						as EventDescription,
			EX_EVENTDATE		as EventDate,
			EX_CYCLE		as Cycle,
			EVENTDATEUPDATE		as IsUpdateable,
			EX_EVENTKEY		as EventKey
		from "+@sEventTable+"
		left join EVENTS E		on (E.EVENTNO=EX_EVENTKEY)
		where EX_CASEKEY = @pnCaseKey
		and   EVENTDATEMATCH<>"+@sMatchAbsent+"
		order by IMP_EVENTDATE desc, IMP_EVENTDESCRIPTION"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey

	End

	If (@psMode = 'P' or @psMode is null)
	and @nErrorCode = 0  
	Begin
		Set @sSQLString = "
		select	SYNCHID			as SynchID,
			EX_CASEKEY		as CaseKey,
			"+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura) +"
						as EventDescription,
			isnull(PR_EVENTDATE,EX_EVENTDATE)
						as EventDate,
			isnull(PR_CYCLE,EX_CYCLE)
						as Cycle,
			EVENTDATEUPDATE		as IsUpdateable,
			EX_EVENTKEY		as EventKey
		from "+@sEventTable+"
		left join EVENTS E		on (E.EVENTNO=EX_EVENTKEY)
		where EX_CASEKEY = @pnCaseKey
		order by IMP_EVENTDATE desc, IMP_EVENTDESCRIPTION"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey

	End
End

-- CaseName
If @nErrorCode = 0
Begin
	If (@psMode = 'I'  or @psMode = 'B' or @psMode is null)
	and @nErrorCode = 0
	Begin
		Set @sSQLString = "
		select	SYNCHID			as SynchID,
			EX_CASEKEY		as CaseKey,
			"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura) +"
						as NameTypeDescription,
			dbo.fn_FormatName(IMP_NAME, IMP_FIRSTNAME, null, null)
						as DisplayName,
			dbo.fn_FormatAddress(IMP_STREET, null, IMP_CITY, S.STATE, coalesce(IMP_STATENAME,S.STATENAME,IMP_STATECODE),
				IMP_POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
					as Address,
			MAP_NAMETYPEKEY		as NameTypeKey,
			case when NAMEMATCH < "+@sMatchBoundary+" then 1
			     else 0
			end			as IsDifferent
		from "+@sCaseNameTable+"
		left join NAMETYPE NT		on (NT.NAMETYPE=MAP_NAMETYPEKEY)
		left join COUNTRY CT		on (CT.COUNTRYCODE=MAP_COUNTRYKEY)
		left join STATE S		on (S.COUNTRYCODE=MAP_COUNTRYKEY
						and S.STATE=IMP_STATECODE)
		where EX_CASEKEY = @pnCaseKey
		order by MAP_NAMETYPEKEY, IMP_NAME, IMP_FIRSTNAME"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End

	-- Note: updates not implemented for case names yet, so Existing and Proposed are the same.
	If (@psMode = 'E' or @psMode = 'B' or @psMode = 'P' or @psMode is null)
	and @nErrorCode = 0  
	Begin
		Set @sSQLString = "
		select	SYNCHID			as SynchID,
			EX_CASEKEY		as CaseKey,
			"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura) +"
						as NameTypeDescription,
			dbo.fn_FormatName(EX_NAME, EX_FIRSTNAME, null, null)
						as DisplayName,
			dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
						as Address,
			EX_NAMETYPEKEY		as NameTypeKey,
			EX_NAMEKEY		as NameKey,
			EX_SEQUENCENO		as SequenceNo
		from  "+@sCaseNameTable+"
		left join CASENAME CN		on (CN.CASEID=EX_CASEKEY
						and CN.NAMETYPE=EX_NAMETYPEKEY
						and CN.NAMENO=EX_NAMEKEY
						and CN.SEQUENCE=EX_SEQUENCENO)
		left join NAMETYPE NT		on (NT.NAMETYPE=CN.NAMETYPE)
		left join NAME N 		on (N.NAMENO = CN.NAMENO)
		left join ADDRESS A		on (A.ADDRESSCODE=coalesce(CN.ADDRESSCODE,N.POSTALADDRESS,N.STREETADDRESS))
		left join COUNTRY CT		on (CT.COUNTRYCODE=A.COUNTRYCODE)
		left join STATE S		on (S.COUNTRYCODE=A.COUNTRYCODE
						and S.STATE=A.STATE)
		where EX_CASEKEY = @pnCaseKey
		and   NAMEMATCH<>"+@sMatchAbsent+"
		-- Show other names of this type for reference
		union all
		select	isnull(SYNCHID, -1 * ROW_NUMBER() OVER(ORDER BY CN.SEQUENCE DESC)) 		as SynchID,
			CN.CASEID		as CaseKey,
			"+dbo.fn_SqlTranslatedColumn('NAMETYPE','DESCRIPTION',null,'NT',@sLookupCulture,@pbCalledFromCentura) +"
						as NameTypeDescription,
			dbo.fn_FormatName(N.NAME, N.FIRSTNAME, null, null)
						as DisplayName,
			dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)					
						as Address,
			CN.NAMETYPE		as NameTypeKey,
			CN.NAMENO		as NameKey,
			CN.SEQUENCE		as SequenceNo
		from  CASENAME CN
		left join "+@sCaseNameTable+"	on (EX_CASEKEY=CN.CASEID
						and EX_NAMETYPEKEY=CN.NAMETYPE
						and EX_NAMEKEY=CN.NAMENO
						and EX_SEQUENCENO=CN.SEQUENCE)
		left join NAMETYPE NT		on (NT.NAMETYPE=CN.NAMETYPE)
		left join NAME N 		on (N.NAMENO = CN.NAMENO)
		left join ADDRESS A		on (A.ADDRESSCODE=coalesce(CN.ADDRESSCODE,N.POSTALADDRESS,N.STREETADDRESS))
		left join COUNTRY CT		on (CT.COUNTRYCODE=A.COUNTRYCODE)
		left join STATE S		on (S.COUNTRYCODE=A.COUNTRYCODE
						and S.STATE=A.STATE)
		where CN.CASEID = @pnCaseKey
		-- Data for the name type was imported
		and exists(select 1 from "+@sCaseNameTable+" I
			where I.EX_CASEKEY=CN.CASEID
			and I.MAP_NAMETYPEKEY=CN.NAMETYPE)
		-- Not matched to imported data
		and EX_CASEKEY is null
		order by NameTypeKey, SYNCHID desc, DisplayName"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey

	End
End

-- TermAdjustments
If @nErrorCode = 0
Begin
	If (@psMode = 'I' or @psMode = 'B' or @psMode is null)
	and @nErrorCode = 0
	Begin
		Set @sSQLString = "
		select	EX_CASEKEY		as CaseKey,
			IMP_IPODELAYDAYS	as IpoDelayDays,
			IMP_APPLICANTDELAYDAYS	as ApplicantDelayDays,
			IMP_TOTALADJUSTMENTDAYS	as TotalAdjustmentDays,
			case when IPODELAYMATCH < "+@sMatchBoundary+" then 1
			     when IPODELAYMATCH is null then null
			     else 0
			end			as IsIpoDelayDaysDifferent,
			case when APPLICANTDELAYMATCH < "+@sMatchBoundary+" then 1
			     when APPLICANTDELAYMATCH is null then null
			     else 0
			end			as IsApplicantDelayDaysDifferent,
			case when TOTALADJUSTMENTMATCH < "+@sMatchBoundary+" then 1
			     when TOTALADJUSTMENTMATCH is null then null
			     else 0
			end			as IsTotalAdjustmentDaysDifferent
		from "+@sCaseTable+"
		where EX_CASEKEY = @pnCaseKey
		and  (	IMP_IPODELAYDAYS is not null
		or	IMP_APPLICANTDELAYDAYS is not null
		or	IMP_TOTALADJUSTMENTDAYS is not null)"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey

	End

	If (@psMode = 'E' or @psMode = 'B' or @psMode is null)
	and @nErrorCode = 0   
	Begin
		Set @sSQLString = "
		select	EX_CASEKEY		as CaseKey,
			EX_IPODELAYDAYS		as IpoDelayDays,
			IPODELAYUPDATE		as IsIpoDelayDaysUpdateable,
			EX_APPLICANTDELAYDAYS	as ApplicantDelayDays,
			APPLICANTDELAYUPDATE	as IsApplicantDelayDaysUpdateable,
			EX_TOTALADJUSTMENTDAYS	as TotalAdjustmentDays,
			TOTALADJUSTMENTUPDATE	as IsTotalAdjustmentDaysUpdateable
		from "+@sCaseTable+"
		join	CASES C			on (EX_CASEKEY=C.CASEID)
		where EX_CASEKEY = @pnCaseKey
		and  (	IMP_IPODELAYDAYS is not null
		or	IMP_APPLICANTDELAYDAYS is not null
		or	IMP_TOTALADJUSTMENTDAYS is not null)"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End

	If (@psMode = 'P' or @psMode is null)
	and @nErrorCode = 0   
	Begin
		Set @sSQLString = "
		select	EX_CASEKEY		as CaseKey,
			isnull(PR_IPODELAYDAYS,EX_IPODELAYDAYS)
						as IpoDelayDays,
			IPODELAYUPDATE		as IsIpoDelayDaysUpdateable,
			isnull(PR_APPLICANTDELAYDAYS,EX_APPLICANTDELAYDAYS)
						as ApplicantDelayDays,
			APPLICANTDELAYUPDATE 	as IsApplicantDelayDaysUpdateable,
			isnull(PR_TOTALADJUSTMENTDAYS,EX_TOTALADJUSTMENTDAYS)
						as TotalAdjustmentDays,
			TOTALADJUSTMENTUPDATE	as IsTotalAdjustmentDaysUpdateable
		from "+@sCaseTable+"
		join	CASES C			on (EX_CASEKEY=C.CASEID)
		where EX_CASEKEY = @pnCaseKey
		and  (	IMP_IPODELAYDAYS is not null
		or	IMP_APPLICANTDELAYDAYS is not null
		or	IMP_TOTALADJUSTMENTDAYS is not null)"

		exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey			int',
				  @pnCaseKey			= @pnCaseKey
	End
End

Return @nErrorCode
GO

Grant execute on dbo.de_ListCaseComparisonData to public
GO
