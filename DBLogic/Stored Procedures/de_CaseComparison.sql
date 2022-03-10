-----------------------------------------------------------------------------------------------------------------------------
-- Creation of de_CaseComparison
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[de_CaseComparison]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.de_CaseComparison.'
	Drop procedure [dbo].[de_CaseComparison]
End
Print '**** Creating Stored Procedure dbo.de_CaseComparison...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.de_CaseComparison
(
	@pnUserIdentityId	int,		-- Mandatory
	@pbCalledFromCentura	bit		= 0,
	@psTableNameQualifier	nvarchar(15), 	-- A qualifier appended to the table names to ensure that they are unique.
	@pnDebugFlag		tinyint		= 0 --0=off,1=trace execution,2=dump data
)
as
-- PROCEDURE:	de_CaseComparison
-- VERSION:	13
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Compares imported cases to cases on the database.
--
--		Note: assumes that the work tables have been created and loaded first:
--			de_CaseComparisonCreate (contains table definition)
--			de_CaseComparisonLoad

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 27 Aug 2005	JEK	RFC1324	1	Procedure created
-- 20 Sep 2005	JEK	RFC3007	2	Extend processing.
-- 22 Sep 2005	JEK	RFC3007	3	Extend processing.
-- 18 Oct 2005	TM	RFC3005	4	Correct the CaseEvents logic to suppress events with no event date.
-- 08 May 2006	JEK	RFC3692	5	Remove comma from comparison of individual names.
--					Also correct problem with incorrect matching for multiple names.
-- 11 May 2006	JEK	RFC3009	6	Implement proposed values and update flags for minimal information.
-- 07 Jun 2006	JEK	RFC3009	7	Don't check for IsCurrent when proposing new official numbers.
-- 17 Aug 2006	JEK	RFC4241	8	Add international classes.  Remove leading zeroes when matching classes.
-- 28 Feb 2007	PY	SQA14425 9 	Reserved word [cycle]
-- 07 May 2007	LP	RFC5103	10	Delete duplicate non-cyclic Events before allocating cycle numbers
-- 24 Jul 2009	MF	16548	11	The FROMEVENTNO will now identify the Event from a related Case that will be pushed
--					into the child Case.
-- 07 Apr 2016  MS      R52206  12      Added quotename before using table variables to avoid sql injection
-- 14 Nov 2018  AV  75198/DR-45358	13   Date conversion errors when creating cases and opening names in Chinese DB

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @nLastRowCount	int
declare @nRowsRemaining	int
declare @sSQLString	nvarchar(4000)
declare @sSQLString2	nvarchar(4000)
declare	@sTimeStamp	nvarchar(24)
declare @sAlertXML	nvarchar(400)
declare @sAlertXML2	nvarchar(400)

declare @nDataSourceKey int
declare @sSystemCode	nvarchar(20)
declare @nCommonShemeKey smallint

-- Each element that is compared is assigned a Match confidence as follows:
declare @sMatchNotApplicable	char
declare @sMatchAbsent		char
declare @sMatchDifferent	char
declare @sMatchSimilar		char
declare @sMatchVerySimilar	char
declare @sMatchSame		char
Set @sMatchNotApplicable = null -- e.g. data is not present to match.
Set @sMatchAbsent = 0		-- Corresponding data does not exist in the system
Set @sMatchDifferent = 1	-- Data exists but is different
Set @sMatchSimilar = 3		-- Data exists and is similar
Set @sMatchVerySimilar = 4	-- Data exists and is very similar
Set @sMatchSame = 5		-- Data exists and is considered the same

/**	Implementation postponed
-- Each proposed change is assigned an Update confidence as follows:
declare @nUpdateNone		tinyint
declare @nUpdateAmbiguous	tinyint
declare @nUpdateReview		tinyint
declare @nUpdateLikely		tinyint
declare @nUpdateDefinite	tinyint
Set @nUpdateNone = 0		-- No update required
Set @nUpdateAmbiguous = 1	-- Too ambigous to make a proposal
Set @nUpdateReview = 3		-- Requires user review
Set @nUpdateLikely = 4		-- Likely
Set @nUpdateDefinite = 5	-- Definitely
**/

-- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument
declare @idoc 			int


declare @sSenderTable		nvarchar(50)
declare @sCaseTable		nvarchar(50)
declare @sOfficialNumberTable	nvarchar(50)
declare @sRelatedCaseTable	nvarchar(50)
declare @sEventTable		nvarchar(50)
declare @sCaseNameTable		nvarchar(50)

-- Initialise variables
Set @nErrorCode = 0
Set @sSenderTable = quotename('CC_SENDER' + @psTableNameQualifier, '')
Set @sCaseTable = quotename('CC_CASE' + @psTableNameQualifier,'')
Set @sOfficialNumberTable = quotename('CC_OFFICIALNUMBER' + @psTableNameQualifier, '')
Set @sRelatedCaseTable = quotename('CC_RELATEDCASE' + @psTableNameQualifier, '')
Set @sEventTable = quotename('CC_CASEEVENT' + @psTableNameQualifier, '')
Set @sCaseNameTable = quotename('CC_CASENAME' + @psTableNameQualifier, '')

Set @nCommonShemeKey = -1 -- CPA Inpro Standard

-- Locate the details of the source system
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select 	@nDataSourceKey = DS.DATASOURCEID,
		@sSystemCode = CC.IMP_SYSTEMCODE
	from 	"+@sSenderTable+" CC
	left join EXTERNALSYSTEM S	on (S.SYSTEMCODE=CC.IMP_SYSTEMCODE)
	left join DATASOURCE DS		on (DS.SYSTEMID=S.SYSTEMID
					and DS.SOURCENAMENO is null)"

	exec @nErrorCode = sp_executesql @sSQLString,
		N'@nDataSourceKey 	int OUTPUT,
		  @sSystemCode		nvarchar(20) OUTPUT',
		  @nDataSourceKey	= @nDataSourceKey OUTPUT,
		  @sSystemCode		= @sSystemCode OUTPUT

	If @nErrorCode = 0
	and @nDataSourceKey is null
	Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('DE5', 'The external system {0} is not recognised as a valid data source.',
						@sSystemCode, null, null, null, null)
		-- Processing error, cannot continue
		RAISERROR(@sAlertXML, 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

-- Map
If @nErrorCode = 0
Begin
	-- OfficialNumber: CPA Inpro number code
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.dm_ApplyMapping
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnMapStructureKey	= 1, -- Number Type
			@pnDataSourceKey	= @nDataSourceKey,
			@pnFromSchemeKey	= @nCommonShemeKey,
			@pnCommonSchemeKey	= @nCommonShemeKey,
			@psTableName		= @sOfficialNumberTable,
			@psCodeColumnName	= 'IMP_NUMBERTYPECODE',
			@psDescriptionColumnName = null,
			@psMappedColumn		= 'MAP_NUMBERTYPEKEY',
			@pnDebugFlag		= @pnDebugFlag
	End

	-- OfficialNumber: description literals
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.dm_ApplyMapping
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnMapStructureKey	= 1, -- Number Type
			@pnDataSourceKey	= @nDataSourceKey,
			@pnFromSchemeKey	= null,
			@pnCommonSchemeKey	= @nCommonShemeKey,
			@psTableName		= @sOfficialNumberTable,
			@psCodeColumnName	= null,
			@psDescriptionColumnName = 'IMP_NUMBERTYPEDESCRIPTION',
			@psMappedColumn		= 'MAP_NUMBERTYPEKEY',
			@pnDebugFlag		= @pnDebugFlag
	End

	-- RelatedCase - Relationship: CPA Inpro codes
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.dm_ApplyMapping
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnMapStructureKey	= 3, -- CaseRelation
			@pnDataSourceKey	= @nDataSourceKey,
			@pnFromSchemeKey	= @nCommonShemeKey,
			@pnCommonSchemeKey	= @nCommonShemeKey,
			@psTableName		= @sRelatedCaseTable,
			@psCodeColumnName	= 'IMP_RELATIONSHIPCODE',
			@psDescriptionColumnName = null,
			@psMappedColumn		= 'MAP_RELATIONSHIPKEY',
			@pnDebugFlag		= @pnDebugFlag
	End

	-- RelatedCase - Relationship: description literals
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.dm_ApplyMapping
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnMapStructureKey	= 3, -- CaseRelation
			@pnDataSourceKey	= @nDataSourceKey,
			@pnFromSchemeKey	= null,
			@pnCommonSchemeKey	= @nCommonShemeKey,
			@psTableName		= @sRelatedCaseTable,
			@psCodeColumnName	= null,
			@psDescriptionColumnName = 'IMP_RELATIONSHIPDESCRIPTION',
			@psMappedColumn		= 'MAP_RELATIONSHIPKEY',
			@pnDebugFlag		= @pnDebugFlag
	End

	-- RelatedCase - Country
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.dm_ApplyMapping
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnMapStructureKey	= 4, -- Country
			@pnDataSourceKey	= @nDataSourceKey,
			@pnFromSchemeKey	= null, -- Defaulted from data source
			@pnCommonSchemeKey	= @nCommonShemeKey,
			@psTableName		= @sRelatedCaseTable,
			@psCodeColumnName	= 'IMP_COUNTRYCODE',
			@psDescriptionColumnName = 'IMP_COUNTRYNAME',
			@psMappedColumn		= 'MAP_COUNTRYKEY',
			@pnDebugFlag		= @pnDebugFlag
	End

	-- Case Event
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.dm_ApplyMapping
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnMapStructureKey	= 5, -- Events
			@pnDataSourceKey	= @nDataSourceKey,
			@pnFromSchemeKey	= null,
			@pnCommonSchemeKey	= @nCommonShemeKey,
			@psTableName		= @sEventTable,
			@psCodeColumnName	= null,
			@psDescriptionColumnName = 'IMP_EVENTDESCRIPTION',
			@psMappedColumn		= 'MAP_EVENTKEY',
			@pnDebugFlag		= @pnDebugFlag
	End

	-- CaseName - NameType: CPA Inpro codes
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.dm_ApplyMapping
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnMapStructureKey	= 2, -- NameType
			@pnDataSourceKey	= @nDataSourceKey,
			@pnFromSchemeKey	= @nCommonShemeKey,
			@pnCommonSchemeKey	= @nCommonShemeKey,
			@psTableName		= @sCaseNameTable,
			@psCodeColumnName	= 'IMP_NAMETYPECODE',
			@psDescriptionColumnName = null,
			@psMappedColumn		= 'MAP_NAMETYPEKEY',
			@pnDebugFlag		= @pnDebugFlag
	End

	-- CaseName - Address Country: CPA Inpro codes
	If @nErrorCode = 0
	Begin
		exec @nErrorCode = dbo.dm_ApplyMapping
			@pnUserIdentityId	= @pnUserIdentityId,
			@pnMapStructureKey	= 4, -- Country
			@pnDataSourceKey	= @nDataSourceKey,
			@pnFromSchemeKey	= @nCommonShemeKey,
			@pnCommonSchemeKey	= @nCommonShemeKey,
			@psTableName		= @sCaseNameTable,
			@psCodeColumnName	= 'IMP_COUNTRYCODE',
			@psDescriptionColumnName = 'IMP_COUNTRYNAME',
			@psMappedColumn		= 'MAP_COUNTRYKEY',
			@pnDebugFlag		= @pnDebugFlag
	End
End

-- Allocate cycle to case events
If @nErrorCode = 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s de_CaseComparison-Commence allocating cycles to events',0,1,@sTimeStamp ) with NOWAIT
	End

	-- Delete any duplicate imported rows which are non-cyclic in Inpro
	-- We are only interested in the latest instance of the event
	Set @sSQLString2 = "
	delete from "+@sEventTable+"
	where MAP_EVENTKEY IS NOT NULL
	and IMP_CYCLE IS NULL
	and IMP_EVENTDATE NOT IN 
	(select MAX(IMP_EVENTDATE) from "+@sEventTable+" group by MAP_EVENTKEY)
	-- Event is non-cyclic
	and not exists
		(select 1
		from EVENTS E
		left join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)
		where 	E.EVENTNO=MAP_EVENTKEY
		and 	(E.NUMCYCLESALLOWED>1 or
		     	EC.NUMCYCLESALLOWED>1)
	)"
	exec @nErrorCode = sp_executesql @sSQLString2

	-- Now allocate cycle to the remaining events
	Set @sSQLString2 = "
	Select @nRowsRemaining = count(*) from "+@sEventTable+"
	where 	MAP_EVENTKEY is not null
	and	IMP_CYCLE is null"

	exec @nErrorCode = sp_executesql @sSQLString2,
		N'@nRowsRemaining 	int OUTPUT',
		  @nRowsRemaining	= @nRowsRemaining OUTPUT

	While @nErrorCode = 0
	and @nRowsRemaining > 0
	Begin
		Set @sSQLString = "
		Update "+@sEventTable+"
		Set	IMP_CYCLE = D.CYCLE+1
		from	(select C.CASEKEY,
				C.EVENTKEY,
				C.EVENTDATE,
				max(isnull(IMP_CYCLE,0)) as [CYCLE]
			from 	"+@sEventTable+"
			join 	(select EX_CASEKEY as CASEKEY,
					MAP_EVENTKEY as EVENTKEY, 
					min(IMP_EVENTDATE) as EVENTDATE
				from "+@sEventTable+"
				WHERE MAP_EVENTKEY is not null
				and IMP_CYCLE is null
				group by EX_CASEKEY, MAP_EVENTKEY) C on (C.CASEKEY=EX_CASEKEY
								     and C.EVENTKEY=MAP_EVENTKEY)
			group by C.CASEKEY, C.EVENTKEY, C.EVENTDATE
			) D
		where 	EX_CASEKEY = D.CASEKEY
		and	MAP_EVENTKEY = D.EVENTKEY
		and	IMP_EVENTDATE = D.EVENTDATE
		and	IMP_CYCLE is null"

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@nRowsRemaining 	int OUTPUT',
			  @nRowsRemaining	= @nRowsRemaining OUTPUT

		Set @nLastRowCount = @@ROWCOUNT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-event: %d rows updated for cycle',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
			if @nErrorCode > 0
			Begin
				print @sSQLString
			End
		End

		-- Count rows remaining
		If @nErrorCode = 0
		Begin
			exec @nErrorCode = sp_executesql @sSQLString2,
				N'@nRowsRemaining 	int OUTPUT',
				  @nRowsRemaining	= @nRowsRemaining OUTPUT
		End

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-event: %d rows remaining to update cycle',0,1,@sTimeStamp, @nRowsRemaining ) with NOWAIT
			if @nErrorCode > 0
			Begin
				print @sSQLString
			End
		End
	End
End

-- Convert case title to mixed case if necessary
If @nErrorCode = 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s de_CaseComparison-Convert title to mixed case',0,1,@sTimeStamp ) with NOWAIT
	End

	Set @sSQLString = "
	UPDATE "+@sCaseTable+"
	SET 	IMP_SHORTTITLE=substring(upper(IMP_SHORTTITLE),1,1)+substring(lower(IMP_SHORTTITLE),2,len(IMP_SHORTTITLE))
	-- Only update if the title is in all upper case.
	-- Note: binary checksum required for case insensitive databases
	WHERE 	BINARY_CHECKSUM(IMP_SHORTTITLE)=BINARY_CHECKSUM(upper(IMP_SHORTTITLE))"

	exec @nErrorCode = sp_executesql @sSQLString
	
End

-- Match imported data to existing data
If @nErrorCode = 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),126)
		RAISERROR ('%s de_CaseComparison-Commence Matching',0,1,@sTimeStamp ) with NOWAIT
	End

	-- Cases
	--	CaseReference
	--		not imported		=> MatchNotApplicable
	-- 		case insensitive match	=> MatchSame
	--		else			=> MatchDifferent
	--	ShortTitle
	--		not imported		=> MatchNotApplicable
	-- 		case insensitive match	=> MatchSame
	--		else			=> MatchDifferent
	--	Term Adjustments
	--		not imported		=> MatchNotApplicable
	-- 		exact match		=> MatchSame
	--		else			=> MatchDifferent
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Commence matching case data',0,1,@sTimeStamp ) with NOWAIT
		End

		-- Load and match existing data, and match case reference
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			UPDATE "+@sCaseTable+"
			SET 	EX_CASEREFERENCE=C.IRN, 
				EX_SHORTTITLE=C.TITLE,
				EX_IPODELAYDAYS=C.IPODELAY,
				EX_APPLICANTDELAYDAYS=C.APPLICANTDELAY,
				EX_TOTALADJUSTMENTDAYS=C.IPOPTA,
				CASEREFERENCEMATCH = 
					case when IMP_CASEREFERENCE is null 
						then null -- @sMatchNotApplicable
					     when IMP_CASEREFERENCE=upper(C.IRN) 
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end,
				SHORTTITLEMATCH =    
					case when IMP_SHORTTITLE is null 
						then null -- @sMatchNotApplicable
					     when upper(IMP_SHORTTITLE)=upper(C.TITLE) 
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end,
				IPODELAYMATCH =
					case when IMP_IPODELAYDAYS is null 
						then null -- @sMatchNotApplicable
					     when IMP_IPODELAYDAYS=C.IPODELAY
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end,
				APPLICANTDELAYMATCH =
					case when IMP_APPLICANTDELAYDAYS is null 
						then null -- @sMatchNotApplicable
					     when IMP_APPLICANTDELAYDAYS=C.APPLICANTDELAY
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end,
				TOTALADJUSTMENTMATCH =
					case when IMP_TOTALADJUSTMENTDAYS is null 
						then null -- @sMatchNotApplicable
					     when IMP_TOTALADJUSTMENTDAYS=C.IPOPTA
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end
			FROM CASES C
			WHERE 	C.CASEID=EX_CASEKEY"

			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-case: %d rows loaded and matched',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End
	End

	-- Official Numbers
	--	OfficialNumber for this case:
	-- 		case insensitive match		=> MatchSame
	--		numeric only match		=> MatchVerySimilar
	--		number type does not exist	=> MatchAbsent
	--		else				=> MatchDifferent
	--	EventDate associated with Number type:
	--		not imported			=> MatchNotApplicable
	--		number type event does not exist=> MatchNotApplicable
	-- 		exact match			=> MatchSame
	--		else				=> MatchDifferent

	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @nRowsRemaining = count(*) from "+@sOfficialNumberTable

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@nRowsRemaining 	int OUTPUT',
			  @nRowsRemaining	= @nRowsRemaining OUTPUT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Commence matching %d official number rows',0,1,@sTimeStamp,@nRowsRemaining ) with NOWAIT
		End

		-- Load all rows, and look for matches on current official number
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sOfficialNumberTable+"
			set 	EX_OFFICIALNUMBER=O.OFFICIALNUMBER, 
				EX_NUMBERTYPEKEY=MAP_NUMBERTYPEKEY,
				EX_EVENTKEY=N.RELATEDEVENTNO,
				EX_EVENTDATE=CE.EVENTDATE,
				EX_ISCURRENT=O.ISCURRENT,
				OFFICIALNUMBERMATCH= 
					case when upper(IMP_OFFICIALNUMBER)=upper(O.OFFICIALNUMBER) 
						then "+@sMatchSame+"
					     when dbo.fn_StripNonNumerics(IMP_OFFICIALNUMBER) = dbo.fn_StripNonNumerics(O.OFFICIALNUMBER)
					     	then "+@sMatchVerySimilar+"
					     when O.CASEID is not null
						then "+@sMatchDifferent+"
					     else "+@sMatchAbsent+"
				     	end,
				EVENTDATEMATCH=
					case when (IMP_EVENTDATE is null or N.RELATEDEVENTNO is null)
						then null -- @nMatchNotApplicable
					     when IMP_EVENTDATE=CE.EVENTDATE 
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end
			from	"+@sOfficialNumberTable+"
			left join OFFICIALNUMBERS O	ON (O.CASEID=EX_CASEKEY
							and O.NUMBERTYPE=MAP_NUMBERTYPEKEY
							and O.ISCURRENT = 1)
			left join NUMBERTYPES N		ON (MAP_NUMBERTYPEKEY=N.NUMBERTYPE)
			left join CASEEVENT CE		ON (CE.CASEID=O.CASEID
							AND CE.EVENTNO=N.RELATEDEVENTNO
							AND CE.CYCLE=1)"
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-official number: %d rows loaded and matched',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Look for matches on non-current official number
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sOfficialNumberTable+"
			set 	EX_OFFICIALNUMBER=O.OFFICIALNUMBER, 
				EX_EVENTDATE=CE.EVENTDATE,
				EX_ISCURRENT=O.ISCURRENT,
				OFFICIALNUMBERMATCH= 
					case when upper(IMP_OFFICIALNUMBER)=upper(O.OFFICIALNUMBER) 
						then "+@sMatchSame+"
					     when dbo.fn_StripNonNumerics(IMP_OFFICIALNUMBER) = dbo.fn_StripNonNumerics(O.OFFICIALNUMBER)
					     	then "+@sMatchVerySimilar+"
					     else "+@sMatchAbsent+"
				     	end,
				EVENTDATEMATCH=
					case when (IMP_EVENTDATE is null or EX_EVENTKEY is null)
						then null -- @nMatchNotApplicable
					     when IMP_EVENTDATE=CE.EVENTDATE 
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end
			from	"+@sOfficialNumberTable+"
			join OFFICIALNUMBERS O		ON (O.CASEID=EX_CASEKEY
							and O.NUMBERTYPE=MAP_NUMBERTYPEKEY
							and isnull(O.ISCURRENT,0) = 0)
			left join CASEEVENT CE		ON (CE.CASEID=O.CASEID
							AND CE.EVENTNO=EX_EVENTKEY
							AND CE.CYCLE=1)
			where OFFICIALNUMBERMATCH = "+@sMatchAbsent
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-official number: %d rows matched to non-current official numbers',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End
	End

	-- Related Cases:
	-- In all official number matches, the country code must exist and match
	-- exactly.
	-- Official number matching uses number types issued by IP Office only.
	--	OfficialNumber on related CaseId with same relationship:
	-- 		case insensitive match		=> MatchSame
	--		numeric only match		=> MatchVerySimilar
	--	OfficialNumber on related country/official number rows with same relationship
	-- 		case insensitive match		=> MatchSame
	--		numeric only match		=> MatchVerySimilar
	--	OfficialNumber on related CaseId with different relationship:
	-- 		case insensitive match		=> MatchVerySimilar
	--		numeric only match		=> MatchSimilar
	--	OfficialNumber on related country/official number rows with different relationship
	-- 		case insensitive match		=> MatchVerySimilar
	--		numeric only match		=> MatchSimilar
	--	else					=> MatchAbsent
	--	EventDate associated with Relationship type:
	--		existing information has related case id => MatchNotApplicable
	--		not imported			=> MatchNotApplicable
	--		relationship event does not exist - ignore
	--			Always import the date.  Event decides how its treated.
	-- 		exact match			=> MatchSame
	--		else				=> MatchDifferent
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @nRowsRemaining = count(*) from "+@sRelatedCaseTable

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@nRowsRemaining 	int OUTPUT',
			  @nRowsRemaining	= @nRowsRemaining OUTPUT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Commence matching %d related case rows',0,1,@sTimeStamp,@nRowsRemaining ) with NOWAIT
		End

		-- Load Event Key and Country Key information
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sRelatedCaseTable+"
			set 	EX_RELATIONSHIPKEY=MAP_RELATIONSHIPKEY,
				MAP_EVENTKEY=R.FROMEVENTNO,
				EX_EVENTKEY=R.FROMEVENTNO,
				-- If a country has not been provided, assume it is the same as the main case
				MAP_COUNTRYKEY=isnull(MAP_COUNTRYKEY,C.COUNTRYCODE)
			from	"+@sRelatedCaseTable+"
			join CASERELATION R		ON (R.RELATIONSHIP=MAP_RELATIONSHIPKEY)
			left join CASES C		on (C.CASEID=EX_CASEKEY)"

			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-related case: %d rows loaded with event key information',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Locate matching related cases with related caseid information
		--	Same relationship
		--	Same country
		-- 	Same official number issued by IP Office
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sRelatedCaseTable+"
			set 	EX_RELATEDCASEKEY=RC.RELATEDCASEID,
				EX_RELATIONSHIPNO=RC.RELATIONSHIPNO,
				EX_COUNTRYKEY=C.COUNTRYCODE,
				RELATIONSHIPMATCH="+@sMatchSame+",
				OFFICIALNUMBERMATCH="+@sMatchSame+",
				EVENTDATEMATCH=null -- MatchNotApplicable
			from	"+@sRelatedCaseTable+"
			join RELATEDCASE RC		on (RC.CASEID=EX_CASEKEY
							and RC.RELATIONSHIP=MAP_RELATIONSHIPKEY)
			join CASES C			on (C.CASEID=RC.RELATEDCASEID)
			where 	OFFICIALNUMBERMATCH="+@sMatchAbsent+"
			and	C.COUNTRYCODE=MAP_COUNTRYKEY
			and	exists (select 1
					from	NUMBERTYPES N
					join 	OFFICIALNUMBERS O	on (O.NUMBERTYPE=N.NUMBERTYPE)
					where 	N.ISSUEDBYIPOFFICE=1
					and	O.CASEID=RC.RELATEDCASEID
					and 	(upper(O.OFFICIALNUMBER)= upper(IMP_OFFICIALNUMBER) or
						 upper(O.OFFICIALNUMBER)= upper(IMP_REGISTRATIONNUMBER))
					)"

			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT
			Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-related case: %d rows with exact official number match for related case id',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End

		End

		-- Locate matching related cases with related caseid information
		--	Same relationship
		--	Same country
		-- 	Numeric only official number issued by IP Office
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sRelatedCaseTable+"
			set 	EX_RELATEDCASEKEY=RC.RELATEDCASEID,
				EX_RELATIONSHIPNO=RC.RELATIONSHIPNO,
				EX_COUNTRYKEY=C.COUNTRYCODE,
				RELATIONSHIPMATCH="+@sMatchSame+",
				OFFICIALNUMBERMATCH= "+@sMatchVerySimilar+",
				EVENTDATEMATCH=null -- MatchNotApplicable
			from	"+@sRelatedCaseTable+"
			join RELATEDCASE RC		on (RC.CASEID=EX_CASEKEY
							and RC.RELATIONSHIP=MAP_RELATIONSHIPKEY)
			join CASES C			on (C.CASEID=RC.RELATEDCASEID)
			where 	OFFICIALNUMBERMATCH="+@sMatchAbsent+"
			and	C.COUNTRYCODE=MAP_COUNTRYKEY
			and	exists (select 1
					from	NUMBERTYPES N
					join 	OFFICIALNUMBERS O	on (O.NUMBERTYPE=N.NUMBERTYPE)
					where 	N.ISSUEDBYIPOFFICE=1
					and	O.CASEID=RC.RELATEDCASEID
					and 	(dbo.fn_StripNonNumerics(O.OFFICIALNUMBER)= dbo.fn_StripNonNumerics(IMP_OFFICIALNUMBER) or
						 dbo.fn_StripNonNumerics(O.OFFICIALNUMBER)= dbo.fn_StripNonNumerics(IMP_REGISTRATIONNUMBER))
					)"

			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT
			Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-related case: %d rows with numeric official number match for related case id',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Locate matching related cases with related country/officialno
		--	Same relationship
		--	Same country
		-- 	Same/similar official number
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sRelatedCaseTable+"
			set	EX_RELATIONSHIPNO=RC.RELATIONSHIPNO,
			 	EX_COUNTRYKEY=RC.COUNTRYCODE,
				EX_OFFICIALNUMBER=RC.OFFICIALNUMBER,
				EX_EVENTDATE=RC.PRIORITYDATE,
				RELATIONSHIPMATCH="+@sMatchSame+",
				OFFICIALNUMBERMATCH= 
					case when upper(RC.OFFICIALNUMBER)=upper(IMP_OFFICIALNUMBER)
						then "+@sMatchSame+"
					     when upper(RC.OFFICIALNUMBER)=upper(IMP_REGISTRATIONNUMBER)
						then "+@sMatchSame+"
					     else "+@sMatchVerySimilar+"
				     	end,
				EVENTDATEMATCH=
					case when IMP_EVENTDATE is null
						then null -- @nMatchNotApplicable
					     when IMP_EVENTDATE=RC.PRIORITYDATE
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end
			from	"+@sRelatedCaseTable+"
			join RELATEDCASE RC		on (RC.CASEID=EX_CASEKEY
							and RC.RELATIONSHIP=MAP_RELATIONSHIPKEY
							and RC.RELATEDCASEID is null)
			where 	OFFICIALNUMBERMATCH="+@sMatchAbsent+"
			and	RC.COUNTRYCODE=MAP_COUNTRYKEY
			and	(upper(RC.OFFICIALNUMBER)=upper(IMP_OFFICIALNUMBER) or
				 dbo.fn_StripNonNumerics(RC.OFFICIALNUMBER)=dbo.fn_StripNonNumerics(IMP_OFFICIALNUMBER) or
				upper(RC.OFFICIALNUMBER)=upper(IMP_REGISTRATIONNUMBER) or
				 dbo.fn_StripNonNumerics(RC.OFFICIALNUMBER)=dbo.fn_StripNonNumerics(IMP_REGISTRATIONNUMBER))"

			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT
			Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-related case: %d rows with any official number match for country/official no',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Locate matching related cases with related caseid information
		--	Different relationship
		--	Same country
		-- 	Same official number issued by IP Office
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sRelatedCaseTable+"
			set 	EX_RELATIONSHIPKEY=RC.RELATIONSHIP,
				EX_EVENTKEY=R.FROMEVENTNO,
				EX_RELATEDCASEKEY=RC.RELATEDCASEID,
				EX_RELATIONSHIPNO=RC.RELATIONSHIPNO,
				EX_COUNTRYKEY=C.COUNTRYCODE,
				RELATIONSHIPMATCH="+@sMatchDifferent+",
				OFFICIALNUMBERMATCH= "+@sMatchVerySimilar+",
				EVENTDATEMATCH=null -- MatchNotApplicable
			from	"+@sRelatedCaseTable+"
			join RELATEDCASE RC		on (RC.CASEID=EX_CASEKEY
							and RC.RELATIONSHIP<>MAP_RELATIONSHIPKEY)
			join CASES C			on (C.CASEID=RC.RELATEDCASEID)
			join CASERELATION R		ON (R.RELATIONSHIP=RC.RELATIONSHIP)
			where 	OFFICIALNUMBERMATCH="+@sMatchAbsent+"
			and	C.COUNTRYCODE=MAP_COUNTRYKEY
			and	exists (select 1
					from	NUMBERTYPES N
					join 	OFFICIALNUMBERS O	on (O.NUMBERTYPE=N.NUMBERTYPE)
					where 	N.ISSUEDBYIPOFFICE=1
					and	O.CASEID=RC.RELATEDCASEID
					and 	(upper(O.OFFICIALNUMBER)= upper(IMP_OFFICIALNUMBER) or
						 upper(O.OFFICIALNUMBER)= upper(IMP_REGISTRATIONNUMBER))
					)"

			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT
			Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-related case: %d rows with exact official number match for related case id with different relationship',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Locate matching related cases with related caseid information
		--	Different relationship
		--	Same country
		-- 	Numeric only official number issued by IP Office
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sRelatedCaseTable+"
			set 	EX_RELATIONSHIPKEY=RC.RELATIONSHIP,
				EX_RELATEDCASEKEY=RC.RELATEDCASEID,
				EX_RELATIONSHIPNO=RC.RELATIONSHIPNO,
				EX_COUNTRYKEY=C.COUNTRYCODE,
				RELATIONSHIPMATCH="+@sMatchDifferent+",
				OFFICIALNUMBERMATCH= "+@sMatchSimilar+",
				EVENTDATEMATCH=null -- MatchNotApplicable
			from	"+@sRelatedCaseTable+"
			join RELATEDCASE RC		on (RC.CASEID=EX_CASEKEY
							and RC.RELATIONSHIP<>MAP_RELATIONSHIPKEY)
			join CASES C			on (C.CASEID=RC.RELATEDCASEID)
			where 	OFFICIALNUMBERMATCH="+@sMatchAbsent+"
			and	C.COUNTRYCODE=MAP_COUNTRYKEY
			and	exists (select 1
					from	NUMBERTYPES N
					join 	OFFICIALNUMBERS O	on (O.NUMBERTYPE=N.NUMBERTYPE)
					where 	N.ISSUEDBYIPOFFICE=1
					and	O.CASEID=RC.RELATEDCASEID
					and 	(dbo.fn_StripNonNumerics(O.OFFICIALNUMBER)= dbo.fn_StripNonNumerics(IMP_OFFICIALNUMBER) or
						 dbo.fn_StripNonNumerics(O.OFFICIALNUMBER)= dbo.fn_StripNonNumerics(IMP_REGISTRATIONNUMBER))
					)"

			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT
			Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-related case: %d rows with numeric official number match for related case id with different relationship',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Locate matching related cases with related country/officialno
		--	Different relationship
		--	Same country
		-- 	Same/similar official number
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sRelatedCaseTable+"
			set	EX_RELATIONSHIPKEY=RC.RELATIONSHIP,
				EX_RELATIONSHIPNO=RC.RELATIONSHIPNO,
			 	EX_COUNTRYKEY=RC.COUNTRYCODE,
				EX_OFFICIALNUMBER=RC.OFFICIALNUMBER,
				EX_EVENTDATE=RC.PRIORITYDATE,
				RELATIONSHIPMATCH="+@sMatchDifferent+",
				OFFICIALNUMBERMATCH= 
					case when upper(RC.OFFICIALNUMBER)=upper(IMP_OFFICIALNUMBER)
						then "+@sMatchVerySimilar+"
					     when upper(RC.OFFICIALNUMBER)=upper(IMP_REGISTRATIONNUMBER)
						then "+@sMatchSame+"
					     else "+@sMatchSimilar+"
				     	end,
				EVENTDATEMATCH=
					case when IMP_EVENTDATE is null
						then null -- @nMatchNotApplicable
					     when IMP_EVENTDATE=RC.PRIORITYDATE
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end
			from	"+@sRelatedCaseTable+"
			join RELATEDCASE RC		on (RC.CASEID=EX_CASEKEY
							and RC.RELATIONSHIP<>MAP_RELATIONSHIPKEY
							and RC.RELATEDCASEID is null)
			where 	OFFICIALNUMBERMATCH="+@sMatchAbsent+"
			and	RC.COUNTRYCODE=MAP_COUNTRYKEY
			and	(upper(RC.OFFICIALNUMBER)=upper(IMP_OFFICIALNUMBER) or
				 dbo.fn_StripNonNumerics(RC.OFFICIALNUMBER)=dbo.fn_StripNonNumerics(IMP_OFFICIALNUMBER) or
				upper(RC.OFFICIALNUMBER)=upper(IMP_REGISTRATIONNUMBER) or
				 dbo.fn_StripNonNumerics(RC.OFFICIALNUMBER)=dbo.fn_StripNonNumerics(IMP_REGISTRATIONNUMBER))"

			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT
			Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-related case: %d rows with any official number match for country/official no with different relationship',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End
	End

	-- Remove any events that also appear as official number dates
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Remove duplicate events',0,1,@sTimeStamp ) with NOWAIT
		End
	
		Set @sSQLString = "
		delete "+@sEventTable+"
		from   "+@sOfficialNumberTable+"
		where 	"+@sOfficialNumberTable+".EX_EVENTKEY = "+@sEventTable+".MAP_EVENTKEY
		and	"+@sOfficialNumberTable+".IMP_EVENTDATE is not null"
	
		exec @nErrorCode = sp_executesql @sSQLString

		Set @nLastRowCount = @@ROWCOUNT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-official number events: %d duplicate events removed',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
			if @nErrorCode > 0
			Begin
				print @sSQLString
			End
		End

		
	End

	-- Case Events
	--	Event Date
	-- 		exact match			=> MatchSame
	--		event/cycle does not exist	=> MatchAbsent
	--		else				=> MatchDifferent
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @nRowsRemaining = count(*) from "+@sEventTable

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@nRowsRemaining 	int OUTPUT',
			  @nRowsRemaining	= @nRowsRemaining OUTPUT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Commence matching %d case event rows',0,1,@sTimeStamp,@nRowsRemaining ) with NOWAIT
		End

		-- Load all rows, and look for match on date
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sEventTable+"
			set 	EX_EVENTKEY=MAP_EVENTKEY,
				EX_EVENTDATE=CE.EVENTDATE,
				EX_CYCLE=CE.CYCLE,
				EVENTDATEMATCH=
					case when IMP_EVENTDATE=CE.EVENTDATE 
						then "+@sMatchSame+"
					     when CE.CASEID is null
						then "+@sMatchAbsent+"
					     else "+@sMatchDifferent+"
					end
			from	"+@sEventTable+"
			left join CASEEVENT CE		ON (CE.CASEID=EX_CASEKEY
							AND CE.EVENTNO=MAP_EVENTKEY
							AND CE.CYCLE=IMP_CYCLE
							AND CE.EVENTDATE IS NOT NULL)"
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-case event: %d rows loaded and matched',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End
	End

	-- CaseNames
	--	Name type that only has a single name:
	-- 		case insensitive match		=> MatchSame
	--		one name begins with the compared name
	--						=> MatchVerySimilar
	--		name type does not exist	=> MatchAbsent
	--		else				=> MatchDifferent
	--	Name type that can have multiple names:
	-- 		case insensitive match		=> MatchSame
	--		one name begins with the compared name
	--						=> MatchVerySimilar
	--		else				=> MatchAbsent
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @nRowsRemaining = count(*) from "+@sCaseNameTable

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@nRowsRemaining 	int OUTPUT',
			  @nRowsRemaining	= @nRowsRemaining OUTPUT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Commence matching %d case name rows',0,1,@sTimeStamp,@nRowsRemaining ) with NOWAIT
		End

		-- Load rows with a single name for the type, and look for match on name
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sCaseNameTable+"
			set 	EX_NAMETYPEKEY=CN.NAMETYPE,
				EX_NAMEKEY=CN.NAMENO,
				EX_SEQUENCENO=CN.SEQUENCE,
				EX_NAME=N.NAME,
				EX_FIRSTNAME=N.FIRSTNAME,
				NAMEMATCH=
					case when CN.CASEID is null
						then "+@sMatchAbsent+"
					     -- case insensitive match on whole name
					     when upper(N.NAME+' '+N.FIRSTNAME) = upper(IMP_NAME+' '+IMP_FIRSTNAME)
						then "+@sMatchSame+"
					     -- imported name begins with existing name
					     when upper(N.NAME+' '+N.FIRSTNAME) like upper(IMP_NAME+' '+IMP_FIRSTNAME)+'%'
						then "+@sMatchVerySimilar+"
					     -- existing name begins with imported name
					     when upper(IMP_NAME+' '+IMP_FIRSTNAME) like upper(N.NAME+' '+N.FIRSTNAME)+'%'
						then "+@sMatchVerySimilar+"
					     else "+@sMatchDifferent+"
					end
			from	"+@sCaseNameTable+"
			-- Only examine types that may only have 1 name
			join NAMETYPE NT		on (NT.NAMETYPE=MAP_NAMETYPEKEY
							and NT.MAXIMUMALLOWED=1)
			join CASENAME CN		on (CN.CASEID=EX_CASEKEY
							and CN.NAMETYPE=NT.NAMETYPE)
			left join NAME N		on (N.NAMENO=CN.NAMENO)"
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT
			Set @nRowsRemaining = @nRowsRemaining - @nLastRowCount

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-case name: %d single name rows loaded and matched',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Load rows with multiple names for the type, and look for match on name
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sCaseNameTable+"
			set 	EX_NAMETYPEKEY=MAP_NAMETYPEKEY,
				EX_NAMEKEY=N.NAMENO,
				EX_SEQUENCENO=cast(substring(D.MatchDetails,25,10) as int),
				EX_NAME=N.NAME,
				EX_FIRSTNAME=N.FIRSTNAME,
				NAMEMATCH=cast(substring(D.MatchDetails,1,1) as tinyint)
			from	"+@sCaseNameTable+"
			-- Only examine types that may have more than 1 name
			join NAMETYPE NT		on (NT.NAMETYPE=MAP_NAMETYPEKEY
							and (NT.MAXIMUMALLOWED>1 or
							     NT.MAXIMUMALLOWED is null) )
			join	(select max(case
					     -- case insensitive match on whole name
					     when upper(N.NAME+' '+N.FIRSTNAME) = upper(IMP_NAME+' '+IMP_FIRSTNAME)
						then '"+@sMatchSame+"'
					     else '"+@sMatchVerySimilar+"'
					end
				     +cast(CN.CASEID as char(10))
				     +cast(CN.NAMETYPE as char(3))
				     +cast(CN.NAMENO as char(10))
				     +cast(CN.SEQUENCE as char(10))
				     +cast(SYNCHID as char(10))
				    ) as MatchDetails
				from "+@sCaseNameTable+"
				join CASENAME CN	on (CN.CASEID=EX_CASEKEY
							and CN.NAMETYPE=MAP_NAMETYPEKEY)
				join NAME N		on (N.NAMENO=CN.NAMENO)
				where ( -- case insensitive match on whole name
					upper(N.NAME+' '+N.FIRSTNAME) = upper(IMP_NAME+' '+IMP_FIRSTNAME)
					-- imported name begins with existing name
				   or	upper(N.NAME+' '+N.FIRSTNAME) like upper(IMP_NAME+' '+IMP_FIRSTNAME)+'%'
					-- existing name begins with imported name
				   or	upper(IMP_NAME+' '+IMP_FIRSTNAME) like upper(N.NAME+' '+N.FIRSTNAME)+'%')
				and NAMEMATCH="+@sMatchAbsent+"
				group by SYNCHID, CN.CASEID,CN.NAMETYPE
				) D		on (cast(substring(D.MatchDetails,35,10) as int)=SYNCHID)
			left join NAME N	on (N.NAMENO=cast(substring(D.MatchDetails,15,10) as int))"


			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-case name: %d multi name rows loaded and matched',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End
	End

	-- Local Classifications
	-- Note formatted as comma separated list of <class>.<subclass>
	-- 	All classes match		=> MatchSame
	--	One or more classes different	=> MatchDifferent
	--	else				=> MatchAbsent
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @nRowsRemaining = count(*) from "+@sCaseTable

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@nRowsRemaining 	int OUTPUT',
			  @nRowsRemaining	= @nRowsRemaining OUTPUT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Commence matching %d local classification rows',0,1,@sTimeStamp,@nRowsRemaining ) with NOWAIT
		End


		-- Load existing classes and check for exact matches
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sCaseTable+"
			set 	EX_LOCALCLASSES=C.LOCALCLASSES,
				LOCALCLASSMATCH=
					case when IMP_LOCALCLASSES is null
						then null -- MatchNotApplicable
					     when IMP_LOCALCLASSES=EX_LOCALCLASSES
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end		
			from	CASES C		
			where	C.CASEID=EX_CASEKEY"
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-local classification: %d rows loaded and exact matched',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Look for matches where classes are out of sequence
		-- This is done separately because its slow
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sCaseTable+"
			set	LOCALCLASSMATCH="+@sMatchSame+"
			from	"+@sCaseTable+"
			where	LOCALCLASSMATCH="+@sMatchDifferent+"
			and	EX_LOCALCLASSES is not null
			and	dbo.fn_NumericListDedupeAndSort(IMP_LOCALCLASSES,',')
			       =dbo.fn_NumericListDedupeAndSort(EX_LOCALCLASSES,',')"
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-local classification: %d rows matched with dedupe and sort',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

	End

	-- International Classifications
	-- Note formatted as comma separated list of <class>.<subclass>
	-- 	All classes match		=> MatchSame
	--	One or more classes different	=> MatchDifferent
	--	else				=> MatchAbsent
	If @nErrorCode = 0
	Begin
		Set @sSQLString = "
		Select @nRowsRemaining = count(*) from "+@sCaseTable

		exec @nErrorCode = sp_executesql @sSQLString,
			N'@nRowsRemaining 	int OUTPUT',
			  @nRowsRemaining	= @nRowsRemaining OUTPUT

		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Commence matching %d int classification rows',0,1,@sTimeStamp,@nRowsRemaining ) with NOWAIT
		End


		-- Load existing classes and check for exact matches
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sCaseTable+"
			set 	EX_INTCLASSES=C.INTCLASSES,
				INTCLASSMATCH=
					case when IMP_INTCLASSES is null
						then null -- MatchNotApplicable
					     when IMP_INTCLASSES=EX_INTCLASSES
						then "+@sMatchSame+"
					     else "+@sMatchDifferent+"
					end		
			from	CASES C		
			where	C.CASEID=EX_CASEKEY"
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-int classification: %d rows loaded and exact matched',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Look for matches where classes are out of sequence
		-- This is done separately because its slow
		If @nErrorCode = 0
		and @nRowsRemaining > 0
		Begin
			Set @sSQLString = "
			update 	"+@sCaseTable+"
			set	INTCLASSMATCH="+@sMatchSame+"
			from	"+@sCaseTable+"
			where	INTCLASSMATCH="+@sMatchDifferent+"
			and	EX_INTCLASSES is not null
			and	dbo.fn_NumericListDedupeAndSort(IMP_INTCLASSES,',')
			       =dbo.fn_NumericListDedupeAndSort(EX_INTCLASSES,',')"
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-int classification: %d rows matched with dedupe and sort',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End
	End
End

-- Propose changes to existing data
If @nErrorCode = 0
Begin
	-- Case
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Commence proposing case data changes',0,1,@sTimeStamp ) with NOWAIT
		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			UPDATE "+@sCaseTable+"
			SET 	PR_SHORTTITLE=
					case when SHORTTITLEMATCH<"+@sMatchSimilar+"
						then IMP_SHORTTITLE
						else null
					end,
				SHORTTITLEUPDATE =
					case when SHORTTITLEMATCH<"+@sMatchSimilar+"
						then 1
						else 0
					end,
				PR_IPODELAYDAYS=
					case when IPODELAYMATCH<"+@sMatchSimilar+"
						then IMP_IPODELAYDAYS
						else null
					end,
				IPODELAYUPDATE =
					case when IPODELAYMATCH<"+@sMatchSimilar+"
						then 1
						else 0
					end,
				PR_APPLICANTDELAYDAYS=
					case when APPLICANTDELAYMATCH<"+@sMatchSimilar+"
						then IMP_APPLICANTDELAYDAYS
						else null
					end,
				APPLICANTDELAYUPDATE=
					case when APPLICANTDELAYMATCH<"+@sMatchSimilar+"
						then 1
						else 0
					end,
				PR_TOTALADJUSTMENTDAYS=
					case when TOTALADJUSTMENTMATCH<"+@sMatchSimilar+"
						then IMP_TOTALADJUSTMENTDAYS
						else null
					end,
				TOTALADJUSTMENTUPDATE =
					case when TOTALADJUSTMENTMATCH<"+@sMatchSimilar+"
						then 1
						else 0
					end"

			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-case: %d rows loaded proposed case data changes',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End
	End

	-- Official Numbers
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Commence proposing official number data changes',0,1,@sTimeStamp ) with NOWAIT
		End

		-- Number portion
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			update 	"+@sOfficialNumberTable+"
			set 	PR_OFFICIALNUMBER=IMP_OFFICIALNUMBER,
				PR_ISCURRENT=1,
				OFFICIALNUMBERUPDATE=1
			where 	OFFICIALNUMBERMATCH<"+@sMatchSimilar+"
			-- For existing numbers, only update if they are the current number of that type
			and	(EX_ISCURRENT=1 OR OFFICIALNUMBERMATCH="+@sMatchAbsent+")"
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-official number: %d rows proposed for update',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

		-- Date portion
		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			update 	"+@sOfficialNumberTable+"
			set 	PR_EVENTDATE=IMP_EVENTDATE,
				EVENTDATEUPDATE=1
			where EVENTDATEMATCH<"+@sMatchSimilar+"
			-- Event is non-cyclic
			and not exists
				(select 1
				from EVENTS E
				left join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)
				where 	E.EVENTNO=EX_EVENTKEY
				and 	(E.NUMCYCLESALLOWED>1 or
				     	EC.NUMCYCLESALLOWED>1)
				)"
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison-official number date: %d rows proposed for update',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

	End

	-- Events
	If @nErrorCode = 0
	Begin
		If  @pnDebugFlag>0
		Begin
			set 	@sTimeStamp=convert(nvarchar,getdate(),126)
			RAISERROR ('%s de_CaseComparison-Commence proposing event data changes',0,1,@sTimeStamp ) with NOWAIT
		End

		If @nErrorCode = 0
		Begin
			Set @sSQLString = "
			update 	"+@sEventTable+"
			set 	PR_EVENTDATE=IMP_EVENTDATE,
				PR_CYCLE=1,
				EVENTDATEUPDATE=1
			where EVENTDATEMATCH<"+@sMatchSimilar+"
			-- Event is non-cyclic
			and not exists
				(select 1
				from EVENTS E
				left join EVENTCONTROL EC	on (EC.EVENTNO=E.EVENTNO)
				where 	E.EVENTNO=MAP_EVENTKEY
				and 	(E.NUMCYCLESALLOWED>1 or
				     	EC.NUMCYCLESALLOWED>1)
				)"
	
			exec @nErrorCode = sp_executesql @sSQLString

			Set @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),126)
				RAISERROR ('%s de_CaseComparison: %d rows proposed for event update',0,1,@sTimeStamp, @nLastRowCount ) with NOWAIT
				if @nErrorCode > 0
				Begin
					print @sSQLString
				End
			End
		End

	End
End


/** Implementation postponed - Note code has not been completed/tested.
-- Propose changes to existing data
If @nErrorCode = 0
Begin
	If  @pnDebugFlag>0
	Begin
		set 	@sTimeStamp=convert(nvarchar,getdate(),113)
		RAISERROR ('%s de_CaseComparison-Commence proposing changes',0,1,@sTimeStamp ) with NOWAIT
	End

	-- Case
	--		Match=	n/a	Not Found	Different	Similar	V.Similar
	--              -----------------------------------------------------------------
	--	ShortTitle	-	Definite	Definite	-	-
	If @nErrorCode = 0
	Begin
		If @nErrorCode = 0
		Begin
			-- Describe the proposed change
			Set @sAlertXML = dbo.fn_GetAlertXML('DE?', 'Change case title to {0}',
							'#1', null, null, null, null)
	
			UPDATE #TEMPCASES
			SET 	SHORTTITLEUPDATE=case SHORTTITLEMATCH
							when @sMatchDifferent then @nUpdateDefinite
							else @nUpdateReview
							end,
				PR_SHORTTITLE = IMP_SHORTTITLE,
				SHORTTITLEUPDATEALERT = replace(@sAlertXML,'#1',IMP_SHORTTITLE)
			WHERE 	SHORTTITLEMATCH<@sMatchSimilar
	
			Select @nErrorCode = @@ERROR, @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),113)
				RAISERROR ('%s de_CaseComparison-Case: %d rows with short title update',0,1,@sTimeStamp,@nLastRowCount ) with NOWAIT
			End
		End
	End

	-- Official Numbers
	-- Assuming that data source is likely to have official number in a better
	-- format than existing data.
	--		Official number found but is not current for that type
	--						Event Match
	--	Official Number Match	n/a		Different	Same
	--	---------------------	--------------------------------------
	--	Not exist		-		-		-
	--	Different		Review		Review		Review
	--	Similar			Review		Review		Review
	--	Very Similar		Review		Review		Review
	--	Same			-		Review		-
	--
	--		Remainder
	--						Event Match
	--	Official Number Match	n/a		Different	Same
	--	---------------------	--------------------------------------
	--	Not exist		Definite 	-		-
	--	Different		Definite	Definite	Definite
	--	Similar			Review		Review		Review
	--	Very Similar		Likely		Likely		Likely
	--	Same			-		Review		-

	If @nErrorCode = 0
	Begin
		-- Add, or update the current row
		If @nErrorCode = 0
		Begin
			-- Describe the proposed change
			Set @sAlertXML = dbo.fn_GetAlertXML('DE?', 'Set official number to {0}',
							'#1', null, null, null, null)
			Set @sAlertXML2 = dbo.fn_GetAlertXML('DE?', 'Set official number to {0} and date to {1}:d',
							'#1', '#2', null, null, null)

			Update	#TEMPOFFICIALNUMBERS
			Set 	ROWUPDATE=case 	when OFFICIALNUMBERMATCH<=@sMatchDifferent
							then @nUpdateDefinite
					       	when OFFICIALNUMBERMATCH=@sMatchSimilar
							then @nUpdateReview
						else @nUpdateLikely
						end,
				PR_OFFICIALNUMBER = IMP_OFFICIALNUMBER,
				PR_ISCURRENT = 1,
				PR_EVENTDATE = case when EVENTDATEMATCH<@sMatchSimilar
							then IMP_EVENTDATE
							else EX_EVENTDATE
							end,
				ROWUPDATEALERT = case when EVENTDATEMATCH<@sMatchSimilar 
							then replace(replace(@sAlertXML2,'#1',IMP_OFFICIALNUMBER),'#2',convert(nvarchar(11),IMP_EVENTDATE,106))
							else replace(@sAlertXML,'#1',IMP_OFFICIALNUMBER)
							end
				-- <@sMatchSame to pick up formatting from imported site
			where 	OFFICIALNUMBERMATCH<@sMatchSame
				-- Either a new row, or is the current official number for the type
			and	((EX_OFFICIALNUMBER is null) or (EX_ISCURRENT=1))
	
			Select @nErrorCode = @@ERROR, @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),113)
				RAISERROR ('%s de_CaseComparison-Offical numbers: %d new or current rows updated',0,1,@sTimeStamp,@nLastRowCount ) with NOWAIT
			End
		End

		-- Number found, but is not the current official number
		If @nErrorCode = 0
		Begin
			-- Describe the proposed change
			Set @sAlertXML = dbo.fn_GetAlertXML('DE?', 'Make {0} the current official number',
							'#1', null, null, null, null)

			Set @sAlertXML2 = dbo.fn_GetAlertXML('DE?', 'Make {0} the current official number and set date to {1):d',
							'#1', '#2', null, null, null)	
			Update	#TEMPOFFICIALNUMBERS
			Set 	ROWUPDATE=@nUpdateReview,
				PR_OFFICIALNUMBER = EX_OFFICIALNUMBER,
				PR_ISCURRENT = 1,
				PR_EVENTDATE = case when EVENTDATEMATCH<@sMatchSimilar
							then IMP_EVENTDATE
							else EX_EVENTDATE
							end,
				ROWUPDATEALERT = case when EVENTDATEMATCH<@sMatchSimilar 
							then replace(replace(@sAlertXML2,'#1',IMP_OFFICIALNUMBER),'#2',convert(nvarchar(11),IMP_EVENTDATE,106))
							else replace(@sAlertXML,'#1',IMP_OFFICIALNUMBER)
							end
			where 	OFFICIALNUMBERMATCH>=@sMatchSimilar
				-- not the current number for the number type
			and	((EX_ISCURRENT is null) or (EX_ISCURRENT<>1))
			and	ROWUPDATE=@nUpdateNone
	
			Select @nErrorCode = @@ERROR, @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),113)
				RAISERROR ('%s de_CaseComparison-Offical numbers: %d rows changed to current',0,1,@sTimeStamp,@nLastRowCount ) with NOWAIT
			End
		End

		-- Only date is different
		If @nErrorCode = 0
		Begin
			-- Describe the proposed change
			Set @sAlertXML = dbo.fn_GetAlertXML('DE?', 'Set the date for official number {0} to {1}:d',
							'#1', '#2', null, null, null)

			Update	#TEMPOFFICIALNUMBERS
			Set 	ROWUPDATE=@nUpdateReview,
				PR_OFFICIALNUMBER = EX_OFFICIALNUMBER,
				PR_ISCURRENT = EX_ISCURRENT,
				PR_EVENTDATE = IMP_EVENTDATE,
				ROWUPDATEALERT = replace(replace(@sAlertXML,'#1',EX_OFFICIALNUMBER),'#2',convert(nvarchar(11),IMP_EVENTDATE,106))
			where 	OFFICIALNUMBERMATCH=@sMatchSame
			and	EVENTDATEMATCH<=@sMatchSimilar
			and	ROWUPDATE=@nUpdateNone
	
			Select @nErrorCode = @@ERROR, @nLastRowCount = @@ROWCOUNT

			If  @pnDebugFlag>0
			Begin
				set 	@sTimeStamp=convert(nvarchar,getdate(),113)
				RAISERROR ('%s de_CaseComparison-Offical numbers: %d rows with event date changed',0,1,@sTimeStamp,@nLastRowCount ) with NOWAIT
			End
		End
	End

	-- Related Cases
	--		For an existing row related to a CaseKey
	--	We won't change the related case because it can be processed itself.
	--				
	--	Official Number Match	
	--	---------------------	
	--	Very Similar		Likely
	--	Same			Definite
	--		Remainder
	-- 	Assuming that data source is likely to have official number in a better
	-- 	format than existing data.
	--						Event Match
	--	Official Number Match	Action	n/a		Different	Same
	--	---------------------	----------------------------------------------
	--	Not exist		Add	Definite 	Definite	-
	--	Similar			Add	Definite	Definite	-
	--				Update	-		-		Likely
	--	Very Similar		Add	-		Likely		-
	--				Update	Likely		-		Likely
	--	Same			Update	-		Likely		-

End
**/

-- Dump tables for debugging
If  @nErrorCode = 0
and @pnDebugFlag>1
Begin
	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparison-'+'Contents of '+@sCaseTable+':'
	Set @sSQLString = "select * from "+@sCaseTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparison-'+'Contents of '+@sOfficialNumberTable+':'
	Set @sSQLString = "select * from "+@sOfficialNumberTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparison-'+'Contents of '+@sRelatedCaseTable+':'
	Set @sSQLString = "select * from "+@sRelatedCaseTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparison-'+'Contents of '+@sEventTable+':'
	Set @sSQLString = "select * from "+@sEventTable
	exec sp_executesql @sSQLString

	set 	@sTimeStamp=convert(nvarchar,getdate(),126)
	select	@sTimeStamp+' de_CaseComparison-'+'Contents of '+@sCaseNameTable+':'
	Set @sSQLString = "select * from "+@sCaseNameTable
	exec sp_executesql @sSQLString

End

Return @nErrorCode
GO

Grant execute on dbo.de_CaseComparison to public
GO
