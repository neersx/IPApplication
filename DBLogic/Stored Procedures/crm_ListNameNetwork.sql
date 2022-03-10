-----------------------------------------------------------------------------------------------------------------------------
-- Creation of crm_ListNameNetwork
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[crm_ListNameNetwork]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.crm_ListNameNetwork.'
	Drop procedure [dbo].[crm_ListNameNetwork]
End
Print '**** Creating Stored Procedure dbo.crm_ListNameNetwork...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.crm_ListNameNetwork
(
	@pnUserIdentityId			int,		-- Mandatory
	@psCulture					nvarchar(10) 	= null,
	@pbCalledFromCentura		bit		= 0,
	@pnNameKey					int, 
	@psRelationshipCodes		nvarchar(1000) = null, 
	@pnMaxDepth					int = 3,
	@pbIsSupportDataRequired	bit=0
)
as
-- PROCEDURE:	crm_ListNameNetwork
-- VERSION:	8
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns all Names that are directly or indirectly related to the this Name base on depth supplied.
--				Relationship is unfiltered but may be filtered by RELATIONSHIP if passed in.
--				NO Support for @pbCalledFromCentura=1

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Nov 2008	SF		RFC5757	1		Procedure for prototype created
-- 15 Jan 2009	SF		RFC5757	2		Use new CRM Default Network Filter site control, 
--										and return the name requested even if name has no associated names.
--										retrieve active associated names only (not-ceased)
-- 10 Mar 2009	SF		RFC5757	3		Return only associated names which are valid according to Name Relation Use By Name Type settings.
-- 12 Mar 2009	SF		RFC5757	4		The logic was too restrictive
-- 27 Mar 2009	SF		RFC5757 5		Duplicates are returned when there are multiple relationships between two names
--                                      and the depth is greater than 1.
-- 1 Apr 2009	SF		RFC5757	6		Agents, Leads and Opportunities are not identified correctly
--										The Associated Names result set must return in the way it is represented in DB
--										so the direction of the relationship can be established within the Network View.
--										Also return the name being requested for eventhough no relationships exists
-- 16 Apr 2009	SF		RFC5757	7		Returning related names incorrectly when depth is greater than 1
-- 04 Nov 2015	KR		R53910	8	Adjust formatted names logic (DR-15543)

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSQLString nvarchar(4000)
Declare @sLookupCulture nvarchar(10)
Declare @nRowCount	int
Declare @nDepth		int
Declare @sRelationshipCodes	nvarchar(1000)
Declare @bIsExternalUser bit
Declare @tbNames table
   (
	ID			int identity (1,1) NOT NULL,
        NAMENO			int	NOT NULL,
        RELATIONSHIP		nvarchar(3) collate database_default NULL,
	RELATEDNAME		int 	NULL,
	SEQUENCE		int 	NULL,
        DEPTH			int	NOT NULL
   )

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @sRelationshipCodes = @psRelationshipCodes
Set @nDepth=1

If @nErrorCode=0
Begin
	Set @sSQLString = "
		Select	@bIsExternalUser = isnull(ISEXTERNALUSER,0)
		from	USERIDENTITY 
		where	IDENTITYID = @pnUserIdentityId
	"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@bIsExternalUser	bit output,
			@pnUserIdentityId int',
			@bIsExternalUser	= @bIsExternalUser output,
			@pnUserIdentityId = @pnUserIdentityId
End

If @nErrorCode=0
and @bIsExternalUser=0  /* This is CRM functionality, external user should not be allowed to access this. */
and isnull(@sRelationshipCodes,'') ='' /* return only relationshipcode defined in CRM Default Network Filter if no specific relationship codes are provided */
Begin	

	Set @sSQLString = "	
		Select	@sRelationshipCodes=COLCHARACTER
		from	SITECONTROL
		where	CONTROLID = N'CRM Default Network Filter'"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@sRelationshipCodes	nvarchar(1000) output',			
			@sRelationshipCodes = @sRelationshipCodes output

	
	/* if CRM Default Network Filter is null or doesn't have any relationship codes specified, return all. */
	If @nErrorCode=0
	and isnull(@sRelationshipCodes,'') ='' 
	Begin	
		Set @sSQLString = "
			Select @sRelationshipCodes=nullif(@sRelationshipCodes+',', ',')+
						RELATIONSHIP
			from NAMERELATION"
		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@sRelationshipCodes	nvarchar(1000) output',			
				@sRelationshipCodes = @sRelationshipCodes output
	End
End
	
--'EMP,CON,LEA,REF,RES'

	
If @nErrorCode=0
and @bIsExternalUser=0
Begin
-- Insert all the names associated with @pnNameKey
	Insert into @tbNames (
				NAMENO,
				RELATIONSHIP,
				RELATEDNAME,
				SEQUENCE,
				DEPTH)
	Select	@pnNameKey as NAMENO,
		AN.RELATIONSHIP,
		CASE WHEN AN.NAMENO=@pnNameKey THEN AN.RELATEDNAME ELSE AN.NAMENO END,
		AN.SEQUENCE,
		@nDepth
	from (select @pnNameKey as NAMENO) N
	join ASSOCIATEDNAME AN on ((AN.CEASEDDATE is null 
					or AN.CEASEDDATE>getdate())									
					and (AN.NAMENO=N.NAMENO 
					or AN.RELATEDNAME=N.NAMENO))
	join dbo.fn_Tokenise(@sRelationshipCodes, ',') R on (AN.RELATIONSHIP = R.Parameter)
	union
	Select @pnNameKey as NAMENO,
		null,
		null,
		null,
		@nDepth
	from (select @pnNameKey as NAMENO) N

	select @nErrorCode=@@Error,
		   @nRowCount=@@Rowcount

	While	@nRowCount>0
	and		@nErrorCode=0
	and		@nDepth < @pnMaxDepth
	Begin
		Set @nDepth=@nDepth+1
		
		-- based on the maximum depth to query, 
		-- locate all names that is related by the relationship code that hasn't already been added.
		Insert into @tbNames (
			NAMENO,
			RELATIONSHIP,
			RELATEDNAME,
			SEQUENCE,
			DEPTH)
		Select	N.RELATEDNAME,
			AN.RELATIONSHIP,
			CASE WHEN AN.NAMENO=N.RELATEDNAME THEN AN.RELATEDNAME ELSE AN.NAMENO END,
			AN.SEQUENCE,
			@nDepth
		from (SELECT DISTINCT NAMENO, RELATEDNAME FROM @tbNames WHERE DEPTH = @nDepth -1) as N
		join ASSOCIATEDNAME AN on ((AN.CEASEDDATE is null or AN.CEASEDDATE>getdate())
						and (AN.NAMENO=N.RELATEDNAME
							or AN.RELATEDNAME=N.RELATEDNAME))
		join dbo.fn_Tokenise(@sRelationshipCodes, ',') R on (AN.RELATIONSHIP = R.Parameter)
		left join @tbNames N1 on (((N1.RELATEDNAME=AN.NAMENO and N1.NAMENO = AN.RELATEDNAME) 
						or(N1.RELATEDNAME = AN.RELATEDNAME and N1.NAMENO = AN.NAMENO))
						and N1.RELATIONSHIP=AN.RELATIONSHIP
						and N1.SEQUENCE=AN.SEQUENCE)
		where N1.NAMENO is null
		
		Select @nErrorCode=@@Error,
		       @nRowCount=@@Rowcount
	End
End

If @nErrorCode=0
Begin
	Select	distinct
			N.NAMENO												as NameKey,
			N.NAMECODE												as NameCode,
			dbo.fn_FormatNameUsingNameNo(N.NAMENO, Coalesce(N.NAMESTYLE, NAT.NAMESTYLE, 7101))	as DisplayName,
			cast((isnull(N.USEDASFLAG, 0) & 1) as bit)				as IsIndividual,
			~cast((isnull(N.USEDASFLAG, 0) & 1) as bit)				as IsOrganisation,
			cast((isnull(N.USEDASFLAG, 0) & 2) as bit)				as IsStaff,
			cast((isnull(N.USEDASFLAG, 0) & 4) as bit)				as IsClient,
			cast(isnull(N.SUPPLIERFLAG, 0) as bit) 					as IsSupplier,			
			cast(isnull(FI.IsAgent, 0) as bit) 						as IsAgent,
			cast(isnull(NTC.IsLead, 0) as bit) 						as IsLead,
			cast(isnull(CN.NAMENO, 0) as bit)						as HasOpportunities,
			dbo.fn_FormatTelecom(PHONE.TELECOMTYPE, PHONE.ISD, PHONE.AREACODE, PHONE.TELECOMNUMBER, PHONE.EXTENSION)
																	as Phone,
			dbo.fn_FormatTelecom(FAX.TELECOMTYPE, FAX.ISD, FAX.AREACODE, FAX.TELECOMNUMBER, FAX.EXTENSION)
																	as Fax,		
			dbo.fn_FormatTelecom(EMAIL.TELECOMTYPE, EMAIL.ISD, EMAIL.AREACODE, EMAIL.TELECOMNUMBER, EMAIL.EXTENSION)
																	as Email,		
			dbo.fn_FormatAddress(POSTAL.STREET1, POSTAL.STREET2, POSTAL.CITY, POSTAL.STATE, SP.STATENAME, POSTAL.POSTCODE, CP.POSTALNAME, CP.POSTCODEFIRST, CP.STATEABBREVIATED, CP.POSTCODELITERAL, CP.ADDRESSSTYLE)
																	as PostalAddress,		
			dbo.fn_FormatAddress(STREET.STREET1, STREET.STREET2, STREET.CITY, STREET.STATE, SS.STATENAME, STREET.POSTCODE, CS.POSTALNAME, CS.POSTCODEFIRST, CS.STATEABBREVIATED, CS.POSTCODELITERAL, CS.ADDRESSSTYLE)
																	as StreetAddress	 
	from	NAME N
	join	@tbNames Network on (	Network.NAMENO	= N.NAMENO 
						or Network.RELATEDNAME = N.NAMENO)
	left join TELECOMMUNICATION PHONE on (PHONE.TELECODE = N.MAINPHONE)
	left join TELECOMMUNICATION FAX on (FAX.TELECODE = N.FAX)
	left join TELECOMMUNICATION EMAIL on (EMAIL.TELECODE = N.MAINEMAIL)
	left join ADDRESS POSTAL 		on (POSTAL.ADDRESSCODE = N.POSTALADDRESS)
	left join COUNTRY NAT			on (NAT.COUNTRYCODE = N.NATIONALITY)
	left join COUNTRY CP			on (CP.COUNTRYCODE = POSTAL.COUNTRYCODE)
	left Join STATE SP				on (SP.COUNTRYCODE = POSTAL.COUNTRYCODE and SP.STATE = POSTAL.STATE)
	left join ADDRESS STREET 		on (STREET.ADDRESSCODE = N.STREETADDRESS)
	left join COUNTRY CS			on (CS.COUNTRYCODE = STREET.COUNTRYCODE)
	left Join STATE SS				on (SS.COUNTRYCODE = STREET.COUNTRYCODE and SS.STATE = STREET.STATE)
	left join	(
				select	FILESIN.NAMENO, 1 as IsAgent
				from	FILESIN
				) FI				on (FI.NAMENO = N.NAMENO)	
	left join	(
				select NAMETYPECLASSIFICATION.NAMENO, NAMETYPECLASSIFICATION.ALLOW as IsLead
				from	NAMETYPECLASSIFICATION
				where	NAMETYPECLASSIFICATION.NAMETYPE = '~LD'
				) NTC				on (NTC.NAMENO = N.NAMENO)
	left join  (
				select	CN.NAMENO, 1 as HasOpportunity
				from CASENAME CN
				Join SITECONTROL SC		on (CONTROLID = 'Property Type Opportunity')
				Join CASES C				on (C.CASETYPE = 'O' and C.PROPERTYTYPE = SC.COLCHARACTER)
				where C.CASEID = CN.CASEID 
				and CN.NAMETYPE in ('~PR','~LD') 				
				) CN				on (CN.NAMENO = N.NAMENO)
	
	where	(Network.NAMENO is not null or Network.RELATEDNAME is not null)
	or		N.NAMENO = @pnNameKey
	

	Select @nErrorCode=@@Error,
	       @nRowCount=@@Rowcount	
End

If @nErrorCode = 0
Begin
	-- return names 
	Select
		Network.ID					as RowKey,
		AN.NAMENO					as NameKey,
		AN.RELATEDNAME				as RelatedNameKey,
		Network.RELATIONSHIP		as RelationshipCode,
		Network.SEQUENCE			as Sequence,
		dbo.fn_FormatNameUsingNameNo(CON.NAMENO,null) as ContactName,		
		dbo.fn_GetTranslation(TCJR.DESCRIPTION,null,TCJR.DESCRIPTION_TID,@sLookupCulture)
										as JobRole,
		dbo.fn_GetTranslation(P.PROPERTYNAME,null,P.PROPERTYNAME_TID,@sLookupCulture)
										as PropertyTypeDescription,
		dbo.fn_GetTranslation(C.COUNTRY,null,C.COUNTRY_TID,@sLookupCulture)
										as CountryName,	
		dbo.fn_GetTranslation(ACT.ACTIONNAME,null,ACT.ACTIONNAME_TID,@sLookupCulture)
										as [Action],
		dbo.fn_GetTranslation(TCPC.DESCRIPTION,null,TCPC.DESCRIPTION_TID,@sLookupCulture)
										as PositionCategory,
		dbo.fn_GetTranslation(AN.POSITION,null,AN.POSITION_TID,@sLookupCulture)
										as Position,
		dbo.fn_FormatTelecom(PHONE.TELECOMTYPE, PHONE.ISD, PHONE.AREACODE, PHONE.TELECOMNUMBER, PHONE.EXTENSION)
										as Phone,
		dbo.fn_FormatTelecom(FAX.TELECOMTYPE, FAX.ISD, FAX.AREACODE, FAX.TELECOMNUMBER, FAX.EXTENSION)
										as Fax,		
		dbo.fn_FormatAddress(POSTAL.STREET1, POSTAL.STREET2, POSTAL.CITY, POSTAL.STATE, SP.STATENAME, POSTAL.POSTCODE, CP.POSTALNAME, CP.POSTCODEFIRST, CP.STATEABBREVIATED, CP.POSTCODELITERAL, CP.ADDRESSSTYLE)
										as PostalAddress,		
		dbo.fn_FormatAddress(STREET.STREET1, STREET.STREET2, STREET.CITY, STREET.STATE, SS.STATENAME, STREET.POSTCODE, CS.POSTALNAME, CS.POSTCODEFIRST, CS.STATEABBREVIATED, CS.POSTCODELITERAL, CS.ADDRESSSTYLE)
										as StreetAddress,		
		AN.NOTES						as Notes,
		AN.CRMONLY						as IsCRMOnly
		from ASSOCIATEDNAME AN
		join @tbNames Network			on (((AN.NAMENO = Network.NAMENO and AN.RELATEDNAME = Network.RELATEDNAME)
								or (AN.NAMENO = Network.RELATEDNAME and AN.RELATEDNAME = Network.NAMENO))
								and AN.RELATIONSHIP = Network.RELATIONSHIP
								and AN.SEQUENCE = Network.SEQUENCE)
		left join PROPERTYTYPE 	P		on (P.PROPERTYTYPE = AN.PROPERTYTYPE)
		left join NAME CON on (CON.NAMENO=AN.CONTACT)
		left join COUNTRY C			on (C.COUNTRYCODE = AN.COUNTRYCODE)
		left join ADDRESS POSTAL 		on (POSTAL.ADDRESSCODE = AN.POSTALADDRESS)
		left join COUNTRY CP			on (CP.COUNTRYCODE = POSTAL.COUNTRYCODE)
		left Join STATE SP			on (SP.COUNTRYCODE = POSTAL.COUNTRYCODE and SP.STATE = POSTAL.STATE)
		left join ADDRESS STREET 		on (STREET.ADDRESSCODE = AN.STREETADDRESS)
		left join COUNTRY CS			on (CS.COUNTRYCODE = STREET.COUNTRYCODE)
		left Join STATE SS			on (SS.COUNTRYCODE = STREET.COUNTRYCODE and SS.STATE = STREET.STATE)
		left join ACTIONS ACT			on (ACT.ACTION = AN.ACTION)
		left join TABLECODES TCPC 		on (TCPC.TABLECODE = AN.POSITIONCATEGORY)
		left join TABLECODES TCJR 		on (TCJR.TABLECODE = AN.JOBROLE)
		left join TELECOMMUNICATION PHONE on (PHONE.TELECODE = AN.TELEPHONE)
		left join TELECOMMUNICATION FAX on (FAX.TELECODE = AN.FAX)
		ORDER BY Network.ID
		
	
	Select @nErrorCode=@@Error,
	       @nRowCount=@@Rowcount	
End

If @nErrorCode=0
Begin
	Select	NR.RELATIONSHIP				as RelationshipCode,
			dbo.fn_GetTranslation(RELATIONDESCR,null,RELATIONDESCR_TID,@sLookupCulture)
										as RelationshipDescription,
			dbo.fn_GetTranslation(REVERSEDESCR,null,REVERSEDESCR_TID,@sLookupCulture)
										as ReverseRelationshipDescription,
			isnull(SHOWFLAG,0)			as IsDisplayAllowed,						
			case when R.Parameter is not null then 1 else 0 end
										as IsSelected
	from NAMERELATION NR
	left join dbo.fn_Tokenise(@sRelationshipCodes, ',') R on (NR.RELATIONSHIP = R.Parameter)		
	where @pbIsSupportDataRequired=1

	Select @nErrorCode=@@Error
End

Return @nErrorCode
GO

Grant execute on dbo.crm_ListNameNetwork to public
GO
