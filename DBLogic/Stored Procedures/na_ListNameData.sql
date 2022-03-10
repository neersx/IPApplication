-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.na_ListNameData
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListNameData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_ListNameData.'
	drop procedure [dbo].[na_ListNameData]
end
print '**** Creating Stored Procedure dbo.na_ListNameData...'
print ''
go

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.na_ListNameData
(
	@pnUserIdentityId	int, -- mandatory
	@psCulture		nvarchar(10) = null,
	@psNameKey		varchar(11)
)

-- PROCEDURE:	na_ListNameData
-- VERSION :	27
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 11/07/2002	SF 			Address Table should only display NAME.POSTAL is exists.
-- 22/07/2002	SF 			Use bit flag to determine the used as status.
-- 23/07/2002  	SF 			1. Test 0x0001 to find out individual or organisation.
-- 					2. disable row counts
-- 21/08/2002	SF 			use fn_FormatName instead of ipfn_FormatName
-- 01/10/2002	SF		13	added RelatedNameCode in AssociatedName population	
-- 11-OCT-2002	JB		14	Implemented IsCPAReportable
-- 15-OCT-2002	JB		15	Bug found with IsCPAReportable
-- 25-NOV-2002	JB		18	Implemented Translations (backed out 20)
-- 27-NOV-2002	SF		19	Cater for Staff/Client
-- 04-DEC-2002	JB		20	Backed out translations
-- 05-DEC-2002	SF		21	Return 0 for NameUsedAs if Name is not Client nor Staff/Company
-- 17-FEB-2003	SF		22	Cater for MainContact
-- 25-FEB-2004	TM	RFC867	23	In the Telecommunication table modify the logic extracting the 'Main Email' 
--					to use new Name.MainEmail column.
-- 26-NOV-2004	TM	RFC2059	24	Return the PostalName instead of Country as CountryName for the address result set.
-- 16 JAN 2008	Dw	SQA9782 25	TAXNO moved from Organisation to Name table.
-- 15 Apr 2013	DV	R13270  26	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Nov 2015	vql	R53910	27	Adjust formatted names logic (DR-15543).

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- declare variables
declare @ErrorCode	int
declare @nNameNo	int
declare @bIsCPAReportable bit
-- Declare @sOfficeCulture nvarchar(10)

-- Initialise
Set @nNameNo = Cast(@psNameKey as int)
-- Set @sOfficeCulture = dbo.fn_GetOfficeCulture()
Set @ErrorCode = 0

/* Skip Population if there is none */
if not exists(select * from NAME where NAMENO = @nNameNo)
begin
	select @ErrorCode = -1
end

/* IsCPAReportable */
if exists(Select * 
		from NAMEINSTRUCTIONS I
		join SITECONTROL S on S.COLINTEGER = I.INSTRUCTIONCODE 
			and S.CONTROLID = 'CPA Reportable Instr'
		where I.NAMENO = @nNameNo)
	Set @bIsCPAReportable = 1
else
	Set @bIsCPAReportable = 0

/*   NAME TABLE */	
if  @ErrorCode=0
Begin
	Select
		@psNameKey			as 'NameKey',	
		N.NAMECODE			as 'NameCode',
		Case N.USEDASFLAG & 0x0001 
			when 0x0001 then 2
			else	1
		end				as 'EntityType',
--		N.USEDASFLAG			as 'NameUsedAs',
		Case 
			when (N.USEDASFLAG & 0x0002 = 0x0002) 
			then 1
			when (N.USEDASFLAG & 0x0004 = 0x0004) 
			then 3
		else	
			0
		end				as 'NameUsedAs',
		N.NAME				as 'Name',
		N.FIRSTNAME			as 'GivenNames',
		N.TITLE /* ISNULL(dbo.fn_TranslateData(N.TITLE_TID, @psCulture, @sOfficeCulture), N.TITLE) */ as 'TitleKey',
		N.TITLE /* ISNULL(dbo.fn_TranslateData(N.TITLE_TID, @psCulture, @sOfficeCulture), N.TITLE) */ as 'TitleDescription',
		I.FORMALSALUTATION		as 'FormalSalutation',
		I.CASUALSALUTATION		as 'CasualSalutation',				
		O.INCORPORATED			as 'Incorporated',
		N.NATIONALITY			as 'NationalityKey',
		C.COUNTRYADJECTIVE /* ISNULL(dbo.fn_TranslateData(C.COUNTRYADJECTIVE_TID, @psCulture, @sOfficeCulture), C.COUNTRYADJECTIVE) */ as 'NationalityDescription',
		N.DATECEASED			as 'DateCeased',
		@bIsCPAReportable		as 'IsCPAReportable',	
		N.TAXNO				as 'TaxNumber',
		N.REMARKS /* ISNULL(dbo.fn_TranslateData(N.REMARKS_TID, @psCulture, @sOfficeCulture), N.REMARKS) */ as 'Remarks'
		FROM NAME N
		left join COUNTRY C		on C.COUNTRYCODE = N.NATIONALITY
		left join ORGANISATION O 	on O.NAMENO = N.NAMENO
		left join INDIVIDUAL I 		on I.NAMENO = N.NAMENO
	
		where	N.NAMENO=@nNameNo

	select @ErrorCode=@@Error
End

/* TELECOMMUNICATION TABLE */
If @ErrorCode=0
begin

	Select 
		@psNameKey 			as 'NameKey',
		CASE 	WHEN TEL.TELECODE = N.MAINPHONE THEN 1	/* Main Phone */
			WHEN TEL.TELECODE = N.FAX 	THEN 2	/* Main Fax */
			WHEN TEL.TELECODE = N.MAINEMAIL	THEN 3	/* Main Email */
			ELSE 	null	/* Undefined */ END
			as 'TelecomTypeId',
		Cast(NT.TELECODE as varchar(11))as 'TelecomKey',
		TEL.ISD				as 'TelecomISD',
		TEL.AREACODE			as 'TelecomAreaCode',
		TEL.TELECOMNUMBER		as 'TelecomNumber',
		TEL.EXTENSION			as 'TelecomExtension'
		from NAMETELECOM NT
		left join TELECOMMUNICATION TEL on (NT.TELECODE		= TEL.TELECODE)
		left join TABLECODES TELETYPE 	on (TEL.TELECOMTYPE	= TELETYPE.TABLECODE
						and TELETYPE.TABLETYPE 	= 19)
	
		left join NAME N		on (NT.NAMENO  		= N.NAMENO)
		
		where 	NT.NAMENO 		= @nNameNo
		and 	(TEL.TELECODE = N.MAINPHONE
				or	TEL.TELECODE = N.FAX
				or 	TEL.TELECODE = N.MAINEMAIL
			) 

	select @ErrorCode=@@Error
	
end
/* ADDRESS TABLE */
If @ErrorCode=0
begin

	select
		@psNameKey 			as 'NameKey',
		1				as 'AddressTypeId',
		Cast(N.POSTALADDRESS as varchar(11)) as 'AddressKey',
		null				as 'FreeFormAddress',
		A.STREET1			as 'Street',
		A.CITY /* ISNULL(dbo.fn_TranslateData(A.CITY_TID, @psCulture, @sOfficeCulture), A.CITY) */ as 'City',
		A.STATE /* ISNULL(dbo.fn_TranslateData(A.STATE_TID, @psCulture, @sOfficeCulture), A.STATE) */ as 'StateKey',
		S.STATENAME			as 'StateName',
		A.POSTCODE			as 'Postcode',
		A.COUNTRYCODE			as 'CountryKey',
		C.POSTALNAME /* ISNULL(dbo.fn_TranslateData(C.COUNTRY_TID, @psCulture, @sOfficeCulture), C.COUNTRY)*/ as 'CountryName'
		from NAME N
		join ADDRESS A		on (N.POSTALADDRESS	= A.ADDRESSCODE)
		left join STATE S	on (A.COUNTRYCODE	= S.COUNTRYCODE
						and A.STATE		= S.STATE)
	
		left join COUNTRY C	on (A.COUNTRYCODE	= C.COUNTRYCODE)
	
		where N.NAMENO = @nNameNo 	

	select @ErrorCode=@@Error

End

/* ASSOCIATEDNAME TABLE */
If @ErrorCode=0
begin
	
	select 
		--@psNameKey+'^2^'+Cast(AN.RELATEDNAME 	as varchar(10)) as 'AssociatedNameRowKey',
		@psNameKey				as 'NameKey',
		2 					as 'RelationshipTypeId',
		Cast(AN.RELATEDNAME 	as varchar(11))	as 'RelatedNameKey',
		dbo.fn_FormatNameUsingNameNo(N.NAMENO, null) as 'RelatedDisplayName',
		AN.SEQUENCE				as 'RelatedNameSequence',
		AN.POSITION 				as 'Position',
		0					as 'IsReverseRelationship',
		case when AN.RELATEDNAME = N2.MAINCONTACT 
			then 1
			else 0
		end					as 'IsMainContact'
	from 	ASSOCIATEDNAME AN
	left join NAME N 				on (AN.RELATEDNAME = N.NAMENO)
	left join NAME N2				on (AN.NAMENO = N2.NAMENO)	where 	AN.NAMENO = @nNameNo
	and	AN.RELATIONSHIP = 'EMP'
	--and	AN.NAMENO = REL.MAINCONTACT
	union
	select 
		--@psNameKey+'^1^'+Cast(AN.NAMENO 	as varchar(10)) as 'AssociatedNameRowKey',
		@psNameKey 				as 'NameKey',
		1 					as 'RelationshipTypeId',
		Cast(AN.NAMENO 	as varchar(11))		as 'RelatedNameKey',
		dbo.fn_FormatNameUsingNameNo(REL.NAMENO, null) as 'RelatedDisplayName',
		AN.SEQUENCE				as 'RelatedNameSequence',
		AN.POSITION 				as 'Position',			
		1					as 'IsReverseRelationship',
		case when AN.RELATEDNAME = REL.MAINCONTACT 
			then 1
			else 0
		end					as 'IsMainContact'		
	from 	ASSOCIATEDNAME AN
	left 	join NAME REL 				on AN.NAMENO = REL.NAMENO
	where 	AN.RELATEDNAME = @nNameNo
	and	AN.RELATIONSHIP = 'EMP'

	select @ErrorCode=@@Error

End

/* ATTRIBUTE TABLE */
If @ErrorCode=0
begin

	select 	T.GENERICKEY			as 'NameKey',
		CASE T.TABLETYPE
			when -1	then 1		/* AnalysisCode1 */
			when -2 then 2		/* AnalysisCode2 */
			when 26 then 3		/* EntitySize */
			when 40 then 4		/* Valediction */
		else 
			null			
		end				as 'AttributeTypeId',
		ATTR.TABLECODE			as 'AttributeKey',
		ATTR.DESCRIPTION		as 'AttributeDescription'
		from 	TABLEATTRIBUTES T
		left join TABLETYPE ATTRTYPE 	on (T.TABLETYPE = ATTRTYPE.TABLETYPE)
		left join TABLECODES ATTR 	on (T.TABLECODE = ATTR.TABLECODE)
		where 	T.PARENTTABLE = 'NAME'
		and	T.TABLETYPE in (-1,-2,26,40)	/* see explanation above) */
		and	T.GENERICKEY = @psNameKey

	select @ErrorCode=@@Error

End

/* ALIAS TABLE */
If @ErrorCode=0
begin
	select	@psNameKey			as 'NameKey',
		Case A.ALIASTYPE	
			when '_C' then 1	/* CPA Account Number 		*/
			when '_G' then 2	/* General Authorization Number */
			when '_P' then 3	/* Patent Office Number 	*/
		end 				as 'AliasTypeId',
		NA.ALIAS			as 'Alias'
		from 	NAMEALIAS NA
		left join ALIASTYPE A	on (NA.ALIASTYPE = A.ALIASTYPE)
		where 	NA.NAMENO = @nNameNo
		and	A.ALIASTYPE in ('_C','_G','_P') /*  see explanation above */

	select @ErrorCode=@@Error

End

RETURN @ErrorCode
go

grant execute on dbo.na_ListNameData to public
go
