-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_FetchDefaultCaseName
-----------------------------------------------------------------------------------------------------------------------------
if exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_FetchDefaultCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_FetchDefaultCaseName.'
	drop procedure [dbo].[csw_FetchDefaultCaseName]
end
print '**** Creating Stored Procedure dbo.csw_FetchDefaultCaseName...'
print ''
go

set quoted_identifier off
go

Create procedure dbo.csw_FetchDefaultCaseName
(
	@pnRowCount			int		= 0 output,
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,
	@pnCaseKey			int,		-- Mandatory
	@ptXMLExistingCaseNames		ntext,
	@pbCalledFromCentura		bit		= 0,
	@pbDebugFlag			bit		= 0
)
as
-- PROCEDURE :	csw_FetchDefaultCaseName
-- VERSION :	19
-- DESCRIPTION:	This stored procedure returns default names against the specified Case 
--		according to rules defined in the NameType table.
--		It may return none, one or more rows.
--		The procedure is based on cs_GenerateCaseNames.  However this version 
--		receives the current case names as XML and can default from names not
--		yet saved to the database.
--		Note: it does assume that the CASES row is saved to the database.
--
-- COPYRIGHT:	Copyright 1993 - 2009 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 10 May 2006	JEK	RFC3840	1	Procedure created
-- 24 May 2006	JEK	RFC3840	2	Set CONCAT_NULL_YIELDS_NULL OFF
-- 08 Jun 2006	JEK	RFC3720	3	A new inheritance option against a NameType can indicate that a Name should
--					inherit from the Associated Name of the Home Name if no associated Name is
--					found against the parent NameType
-- 21 Jul 2006	JEK	RFC4183	4	Do not inherit from the home name unless the case name for the name type is present first.
-- 11 Jan 2007  PG	RFC4770 5	Correct usage of NAMETYPE.DEFAULTNAMENO
-- 24 Jan 2007  PG	RFC4770 6	Set INHERITEDNAMENO to point to Home Name when it is used to inherit by associated name
-- 15 Feb 2008	SF	RFC6211	7	Make @tbDefaultNames.SEQUENCE smallint rather than int.
-- 11 Dec 2008	MF	17136	8	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 24 Mar 2009	JC	RFC7756	9	Replace PurposeCode 'S' to 'W' and use fnw_ScreenCriteriaNameTypes
-- 31 Mar 2009	SF	RFC7474	10	use fnw_ScreenCriteriaNameTypes and enable case type checking to derive the correct program to use
-- 21 Sep 2009  LP      RFC8047 11      Pass ProfileKey as parameter to fn_GetCriteriaNo
-- 24 Oct 2011	ASH	R11460  12	Cast integer columns as nvarchar(11) data type.
-- 07 Sep 2012	DV      R12572  13	Renewal instruction reference not being from default Case Name
-- 21 Sep 2012	DL	R12763	14	Fix collation error by adding 'collate database_default' to character based columns in temp table definition.
-- 25 Jan 2013  SW	R13046	15	Fix defaulting of case names not respecting the Maximum Allowed against the Case for Name Type  
-- 04 Nov 2015	KR	R53910	16	Adjust formatted names logic (DR-15543)
-- 05 Jan 2016	DV	R55338	17	Copy the reference number only if the names are same
-- 20 Jul 2017	MF	71968	18	When determining the default Case program, first consider the Profile of the User.
-- 28 Oct 2019	vql	DR52932	19	When copying cases, not all Name Types are being defaulted correctly.


begin

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @nRowCount int
Declare @nTotalRowCount int
Declare @sLookupCulture	nvarchar(10)
Declare @nNameSequence 	int
Declare @sNameType	nvarchar(3)

Declare @idoc 		int -- Declare a document handle of the XML document in memory that is created by sp_xml_preparedocument.

Declare @nCriteriaNo 	int
Declare @sProgramKey	nvarchar(8)
Declare @nProfileKey    int

Declare @tbDefaultNames table (
	CASEID			int 		not null,
	NAMETYPE		nvarchar(3) 	collate database_default not null,
	NAMENO			int 		not null,
	SEQUENCE		smallint		not null,
	CORRESPONDNAME		int 		null, 
	ADDRESSCODE		int 		null,
	BILLPERCENTAGE		decimal(5,2) 	null,
	INHERITED		decimal(1,0) 	null,
	INHERITEDNAMENO		int 		null,
	INHERITEDRELATIONS	nvarchar(3) 	collate database_default null,
	INHERITEDSEQUENCE	smallint 	null,
	REFERENCENO     	nvarchar(80) 	collate database_default null,
	ISEXISTING		bit 		default 0
)

Set @nErrorCode = @@error

-- Load the existing names into the table variable, marking them as ISEXISTING=1.
If @nErrorCode = 0
Begin
	-- Create an XML document in memory and then retrieve the information 
	-- from the rowset using OPENXML
	exec sp_xml_preparedocument	@idoc OUTPUT, @ptXMLExistingCaseNames

	Insert into @tbDefaultNames
		(
			CASEID,
			NAMETYPE,
			NAMENO,
			SEQUENCE,
			CORRESPONDNAME,
			ADDRESSCODE,
			REFERENCENO,
			ISEXISTING
		)
	Select @pnCaseKey, NAMETYPE, NAMENO, 0, CORRESPONDNAME, ADDRESSCODE,REFERENCENO, 1
		FROM OPENXML (@idoc, '/CaseNameData/CaseNameDetails',2)
		WITH (
			NAMETYPE	nvarchar(3)	'NameTypeCode/text()',
		      	NAMENO		int		'NameKey/text()',
		      	CORRESPONDNAME	int		'AttentionKey/text()',
		      	ADDRESSCODE	int		'AddressKey/text()',
		      	REFERENCENO     nvarchar(80)    'ReferenceNo/text()'
		     )

	Select @nRowCount = @@rowcount, @nErrorCode = @@Error

	-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc

	If @pbDebugFlag>0
	Begin
		SELECT * FROM @tbDefaultNames
	End
End

Set @nTotalRowCount = 0

-- Default the names into the table variable with ISEXISTING=0
If @nErrorCode = 0 and @nRowCount > 0
begin
	-- Only locate the criteria for the case once.

	-- Default @psProgramKey to 'Case Screen Default Program' Site Control value
	if @nErrorCode = 0
	Begin
		Select @sProgramKey = left(isnull(PA.ATTRIBUTEVALUE,S.COLCHARACTER),8),
		       @nProfileKey = U.PROFILEID 
		from  SITECONTROL S
		join USERIDENTITY U             on (U.IDENTITYID= @pnUserIdentityId)
		join CASES C                    on (C.CASEID    = @pnCaseKey)
		join CASETYPE CT                on (C.CASETYPE  = CT.CASETYPE)
		left join PROFILEATTRIBUTES PA  on (PA.PROFILEID=U.PROFILEID
						and PA.ATTRIBUTEID=2)	-- Default Cases Program
		where S.CONTROLID = CASE WHEN CT.CRMONLY=1 THEN 'CRM Screen Control Program'
			                                   ELSE 'Case Screen Default Program' 
				    END

		Set @nErrorCode = @@ERROR
	End

	-- Locate screen control criteria for the case.
	if @nErrorCode = 0
	Begin
		-- Get the Criteria No associated with the current case given the correct purpose code and program key
		Select @nCriteriaNo = dbo.fn_GetCriteriaNo(@pnCaseKey, 'W', @sProgramKey, null, @nProfileKey)
	End

	If @pbDebugFlag>0
	Begin
		SELECT * FROM dbo.fnw_ScreenCriteriaNameTypes(@nCriteriaNo)
	End

	-- Loop around defaulting more names from those already in the table variable
	-- until there are no more names to default.
	While	@nRowCount > 0
	and	@nErrorCode = 0
	begin	
		-- The following logic is the same as cs_GenerateCaseName with the following
		-- variations:
		-- * Selects from the temp table of names instead of CASENAME (CN)
		-- * Checks for existing names in the temp table instead of CASENAME (CN1)
		-- * Derived attention logic is not implemented because this is handled
		--   when the name is saved to the database
		-- * Consquently, checks the name type for the attention flag before inheriting attention
		-- * Any specific address entered on the existing case name is automatically inherited
		-- * CHANGEEVENTNO is not required (events are created on save)

		-- get all default names and insert it into the temp table
		Insert into @tbDefaultNames
			(
				CASEID,
				NAMETYPE,
				NAMENO,
				[SEQUENCE],
				CORRESPONDNAME,
				ADDRESSCODE,
				BILLPERCENTAGE,
				INHERITED,
				INHERITEDNAMENO,
				INHERITEDRELATIONS,
				INHERITEDSEQUENCE,
				REFERENCENO
			)
		select 	distinct
			CS.CASEID, 
			NT.NAMETYPE,
			N.NAMENO as NAMENO,
			0 as [SEQUENCE],
			-- If the Name Type requires a contact name then return the appropriate one
			case when convert(bit, NT.COLUMNFLAGS & 1) = 1
				then 
					CASE	WHEN (A.CONTACT is not null) THEN A.CONTACT
						WHEN (NT.HIERARCHYFLAG=1
							and CN.NAMENO is not null)
								THEN CN.CORRESPONDNAME
						WHEN (NT.USEHOMENAMEREL=1 and AH.RELATEDNAME is not null)
								THEN CASE WHEN(AH.CONTACT is not null)       THEN AH.CONTACT
								     END
					END
			END as CORRESPONDNAME,
			-- Save address code if the Name Type requires one.
			CASE WHEN NT.KEEPSTREETFLAG = 1
			     	THEN N.STREETADDRESS
			     -- If inherited from a case name with a specific address, use that.
			     when A.RELATEDNAME is null and CN.NAMENO is not null
				then CN.ADDRESSCODE
			END  as ADDRESSCODE, 			
			-- If the bill percent flag is on, default to 100
			CASE WHEN convert(bit, NT.COLUMNFLAGS & 64) = 1 THEN 100 ELSE null END as BILLPERCENTAGE,
			1 as INHERITED,
			CASE WHEN (NT.PATHRELATIONSHIP is null
				or A.RELATEDNAME is not null
				or NT.USEHOMENAMEREL=0
				or AH.RELATEDNAME is null) THEN CN.NAMENO
			     ELSE S.COLINTEGER
			END as INHERITEDNAMENO,

			isnull(A.RELATIONSHIP,AH.RELATIONSHIP) as INHERITEDRELATIONS,
			isnull(A.SEQUENCE,AH.SEQUENCE) as INHERITEDSEQUENCE,
			CASE WHEN N.NAMENO = CN.NAMENO THEN CN.REFERENCENO ELSE null END as REFERENCENO
		from 	NAMETYPE NT 
		-- Only default relevant name types from screen control
		join	dbo.fnw_ScreenCriteriaNameTypes(@nCriteriaNo) SC
				on (SC.NAMETYPE=NT.NAMETYPE)
	     	join CASES CS 	on (CS.CASEID = @pnCaseKey)
		-- The CaseName that acts as the starting point - may be existing or defaulted
		left join @tbDefaultNames CN	on (CN.CASEID = CS.CASEID
				    		and CN.NAMETYPE = NT.PATHNAMETYPE) 
		-- Pick up the CaseName's associated Name
	     	left join ASSOCIATEDNAME A 
					on (A.NAMENO = CN.NAMENO 
					and A.RELATIONSHIP = NT.PATHRELATIONSHIP
					and(A.PROPERTYTYPE = CS.PROPERTYTYPE or A.PROPERTYTYPE is null)
					and(A.COUNTRYCODE  = CS.COUNTRYCODE  or A.COUNTRYCODE  is null)
					-- There may be multiple AssociatedNames.  
					-- A best fit against the Case attributes is required to determine
					-- the characteristics of the Associated Name that best match the Case.
					-- This then allows for all of the associated names with the best
					-- characteristics for the Case to be returned.
					and CASE WHEN(A.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
					    CASE WHEN(A.COUNTRYCODE  is null) THEN '0' ELSE '1' END
						=	(	select
								max (	case when (A1.PROPERTYTYPE is null) then '0' else '1' end +    			
									case when (A1.COUNTRYCODE  is null) then '0' else '1' end)
								from ASSOCIATEDNAME A1
								where A1.NAMENO=A.NAMENO
								and   A1.RELATIONSHIP=A.RELATIONSHIP
								and  (A1.PROPERTYTYPE=CS.PROPERTYTYPE OR A1.PROPERTYTYPE is null)
								and  (A1.COUNTRYCODE =CS.COUNTRYCODE  OR A1.COUNTRYCODE  is null)))
		-- Get the Home NameNo if no associated Name found and inheritance
		-- is to also consider the Home Name
		left join SITECONTROL S	on (S.CONTROLID='HOMENAMENO'
					and A.RELATEDNAME is null
					and NT.USEHOMENAMEREL=1) 
		-- Pick up the Home Name's associated Name
	     	left join ASSOCIATEDNAME AH 
					on (AH.NAMENO = S.COLINTEGER 
					and AH.RELATIONSHIP = NT.PATHRELATIONSHIP
					and(AH.PROPERTYTYPE = CS.PROPERTYTYPE or AH.PROPERTYTYPE is null)
					and(AH.COUNTRYCODE  = CS.COUNTRYCODE  or AH.COUNTRYCODE  is null)
					-- There may be multiple AssociatedNames.  
					-- A best fit against the Case attributes is required to determine
					-- the characteristics of the Associated Name that best match the Case.
					-- This then allows for all of the associated names with the best
					-- characteristics for the Case to be returned.
					
					and CASE WHEN(AH.PROPERTYTYPE is null) THEN '0' ELSE '1' END +
					    CASE WHEN(AH.COUNTRYCODE  is null) THEN '0' ELSE '1' END
						=	(	select
								max (	case when (AH1.PROPERTYTYPE is null) then '0' else '1' end +    			
									case when (AH1.COUNTRYCODE  is null) then '0' else '1' end)
								from ASSOCIATEDNAME AH1
								where AH1.NAMENO=AH.NAMENO
								and   AH1.RELATIONSHIP=AH.RELATIONSHIP
								and  (AH1.PROPERTYTYPE=CS.PROPERTYTYPE OR AH1.PROPERTYTYPE is null)
								and  (AH1.COUNTRYCODE =CS.COUNTRYCODE  OR AH1.COUNTRYCODE  is null)))
				-- Choose the name to add
	     	join NAME N  on (N.NAMENO= 	CASE WHEN (NT.PATHNAMETYPE is not null and NT.PATHRELATIONSHIP is null)THEN CN.NAMENO
						     WHEN(A.RELATEDNAME is not null) THEN A.RELATEDNAME
						     -- RFC4770 Only default to parent name if hierarchy flag set on.
						     WHEN(NT.HIERARCHYFLAG=1)        THEN CN.NAMENO
						     -- RFC4770 Use Default Name if relationship not there for home name.
						     WHEN(NT.USEHOMENAMEREL=1)       THEN isnull(AH.RELATEDNAME, NT.DEFAULTNAMENO)
						     -- RFC4770 Use Default Name if nothing else found.
					     	     ELSE NT.DEFAULTNAMENO

						END)
		-- Only default if the name type if it is not already present (either existing or defaulted)
		and	not exists
				(select * from @tbDefaultNames CN1
				 where 	CN1.CASEID = CS.CASEID and
					CN1.NAMETYPE = NT.NAMETYPE)
		-- RFC4183 Only default from the home name if the case name we're falling back from is present
		and ( CN.NAMENO is not null or (CN.NAMENO is null and NT.DEFAULTNAMENO is not null) )
		Order by NT.NAMETYPE
	
	
		Select @nRowCount = @@rowcount, @nErrorCode = @@Error
		Set @nTotalRowCount = @nTotalRowCount+@nRowCount

		If @pbDebugFlag>0
		Begin
			Select * from @tbDefaultNames
		End
	end		
end

-- Allocate the SEQUENCE number for the CASENAME rows.  The number is reset
-- on each change of NAMETYPE.  This is a very fast way of incrementing a sequence
-- that needs to be reset on a control break.
If  @nErrorCode=0
and @nTotalRowCount > 1	-- only need to do this if more than 1 row was inserted
Begin	
	Set @sNameType=''

	Update @tbDefaultNames
	Set @nNameSequence=CASE WHEN(@sNameType=NAMETYPE)
				THEN @nNameSequence+1
				ELSE [SEQUENCE]
			   END,
	[SEQUENCE]=@nNameSequence,
	@sNameType=NAMETYPE
	where ISEXISTING=0

	Set @nErrorCode=@@Error

	If @pbDebugFlag>0
	Begin
		select 'After sequence generation...'
		Select * from @tbDefaultNames
	End
End

-- Return the defaulted names as a result set
If @nErrorCode=0
Begin
	Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

	Select
	CAST(C.CASEID as nvarchar(11))+'^'+
	C.NAMETYPE+'^'+
	CAST(C.NAMENO as nvarchar(11))+'^'+
	CAST(C.SEQUENCE	as nvarchar(10))
				as RowKey,
	C.CASEID		as CaseKey,
	C.NAMETYPE		as NameTypeCode,
	dbo.fn_GetTranslation(NT.DESCRIPTION,null,NT.DESCRIPTION_TID,@sLookupCulture)
				as NameTypeDescription,
	C.NAMENO		as NameKey,
	dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
				as FormattedName,
	N.NAMECODE		as NameCode,
	C.SEQUENCE		as Sequence,
	C.CORRESPONDNAME	as AttentionNameKey,
	dbo.fn_FormatNameUsingNameNo(N1.NAMENO, null)
				as AttentionNameFormatted,
	N1.NAMECODE		as AttentionNameCode,
	C.ADDRESSCODE		as AddressKey,
	dbo.fn_FormatAddress(A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME, A.POSTCODE, CT.POSTALNAME, CT.POSTCODEFIRST, CT.STATEABBREVIATED, CT.POSTCODELITERAL, CT.ADDRESSSTYLE)
				as AddressFormatted,
	C.BILLPERCENTAGE	as BillPercent,
	C.INHERITED		as IsInherited,
	C.INHERITEDNAMENO	as InheritedNameKey,
	C.INHERITEDRELATIONS 	as InheritedRelationshipCode,
	C.INHERITEDSEQUENCE	as InheritedSequence,
	DS.ACTIONFLAG		as RestrictionActionKey,
	dbo.fn_GetTranslation(DS.DEBTORSTATUS,null,DS.DEBTORSTATUS_TID,@sLookupCulture)
				as Restriction,
	C.REFERENCENO           as ReferenceNo
	from @tbDefaultNames C
	join NAME N 		on (N.NAMENO = C.NAMENO)
	join NAMETYPE NT 	on (NT.NAMETYPE = C.NAMETYPE)
	left join NAME N1	on (N1.NAMENO = C.CORRESPONDNAME)	
	left join ADDRESS A	on (A.ADDRESSCODE = C.ADDRESSCODE)
	left join COUNTRY CT	on (CT.COUNTRYCODE = A.COUNTRYCODE)
	left join STATE S	on (S.COUNTRYCODE = A.COUNTRYCODE
				and S.STATE = A.STATE)
	left join IPNAME IP	on (IP.NAMENO = N.NAMENO)
	left join DEBTORSTATUS DS
				on (DS.BADDEBTOR = IP.BADDEBTOR)
	where C.ISEXISTING=0 AND (C.SEQUENCE < NT.MAXIMUMALLOWED OR NT.MAXIMUMALLOWED is null)
	order by CaseKey, NameTypeDescription, NameTypeCode, Sequence

	Select @pnRowCount = @@rowcount, @nErrorCode = @@Error
End

Return @nErrorCode

End
go

Grant execute on dbo.csw_FetchDefaultCaseName to public
go
