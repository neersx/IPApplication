-----------------------------------------------------------------------------------------------------------------------------
-- Creation of naw_FetchAssociatedName									      
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[naw_FetchAssociatedName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.naw_FetchAssociatedName.'
	Drop procedure [dbo].[naw_FetchAssociatedName]
End
Print '**** Creating Stored Procedure dbo.naw_FetchAssociatedName...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.naw_FetchAssociatedName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@pnNameKey		int,		-- Mandatory
	@pbNewRow		bit		= 0,
	@psRelationshipCode	nvarchar(3)	= null,
	@pbIsIndividual		bit		= null,
	@pnAssociatedNameKey	int		= null
)
as
-- PROCEDURE:	naw_FetchAssociatedName
-- VERSION:	16
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Populate the AssociatedName business entity.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	-----------------------------------------------
-- 21 Apr 2006	IB	RFC3768	1	Procedure created
-- 02 May 2006	IB	RFC3768	2	Fixed the main contact selection.
-- 01 Mar 2007	PY	S14425	3	Reserved word [action]
-- 26 Oct 2007	PG	R3501	4	Set IsReverse=1 for Individuals when @pbNewRow=1
-- 30 Jun 2008	AT	RFC5787	5	Added IsCRMOnly flag
-- 25 Jun 2008	AT	RFC5714	6	Added filtering by relationship if specified
-- 06 May 2009	KR	RFC7791	7	Modified to get the entity type for associated names correctly
-- 30 Mar 2010  LP      RFC7276	8	Added BillFormatId to result set.
-- 01 Jul 2011	MF	R10923	9	Increase @sSQLString to nvarchar(max) to avoid exceeding 4000 character limit.
-- 21 Oct 2011  MS      R11438	10	Pass Namestyle in fn_FormatName call
-- 20 Jul 2012  ASH     R100733	11	Included Distict keyword in subquery for IsMainContact as the query is returning multiple same bool value.
-- 08 Apr 2013	DV	R13270	12	Increase the length of nvarchar to 11 when casting or declaring integer
-- 04 Oct 2013  MS      DR1390	13	Revert RFC11438 changes, pass namestyle as null in fn_FormatName call
-- 02 Nov 2015	vql	R53910	14	Adjust formatted names logic (DR-15543).
-- 29 Mar 2017	MF	70895	15	Only indicate the Main Contact flagged against the main name and ignore reverse relationships.	
-- 13 Mar 2019  MS      DR45458 16      Set IsReverse true only RelatedName equals to @pnNameKey and NameNo not equals to @pnNameKey

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode			int
Declare @sSQLString 			nvarchar(max)
Declare @sLookupCulture			nvarchar(10)
Declare @sRelationshipDescription	nvarchar(30)
Declare @bIsReverse			bit
Declare @sAssociatedName		nvarchar(254)
Declare @sAssociatedNameCode		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
Set @bIsReverse = null

If @nErrorCode = 0
and @pbNewRow = 1
Begin
	If @pbIsIndividual = 1
	Begin
		Set @bIsReverse = 1
	End
	Else
	Begin
		If @pnNameKey is not null
		Begin
		-- UsedAsFlag&1 is checking whether the name is an individual
			Set @sSQLString = "Select 
				@bIsReverse =
					CASE cast(N.USEDASFLAG as int)&1	
					WHEN 1 THEN 1
					ELSE 0
					END
			from NAME N
			where N.NAMENO = @pnNameKey"

			exec @nErrorCode=sp_executesql @sSQLString,
					N'
					@bIsReverse	bit 		output,
					@pnNameKey	int',
					@bIsReverse	= @bIsReverse	output,
					@pnNameKey	= @pnNameKey
		End
	End
	
	If @nErrorCode = 0
	and @bIsReverse is null
	Begin
		Set @bIsReverse = 0
	End
	
	If @nErrorCode = 0
	and @psRelationshipCode is not null
	Begin
		Set @sSQLString = "Select 
			@sRelationshipDescription =
			CASE @bIsReverse	
			WHEN 0 THEN 
			"+dbo.fn_SqlTranslatedColumn('NAMERELATION','RELATIONDESCR',null,'NR',
							@sLookupCulture,@pbCalledFromCentura)+"
			ELSE 
			"+dbo.fn_SqlTranslatedColumn('NAMERELATION','REVERSEDESCR',null,'NR',
							@sLookupCulture,@pbCalledFromCentura)+"
			END	
		from NAMERELATION NR
		where NR.RELATIONSHIP = @psRelationshipCode"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@psRelationshipCode		nvarchar(3),
				@sRelationshipDescription	nvarchar(30) output,
				@bIsReverse			bit',
				@psRelationshipCode		= @psRelationshipCode,
				@sRelationshipDescription	= @sRelationshipDescription output,
				@bIsReverse			= @bIsReverse
	End	
	
	If @nErrorCode = 0
	and @pnAssociatedNameKey is not null
	Begin
		Set @sSQLString = "Select 
			@sAssociatedName = dbo.fn_FormatNameUsingNameNo(N.NAMENO, null),
			@sAssociatedNameCode = N.NAMECODE	
		from NAME N
		where N.NAMENO = @pnAssociatedNameKey"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'
				@pnAssociatedNameKey		int,
				@sAssociatedName		nvarchar(254) output,
				@sAssociatedNameCode		nvarchar(10) output',
				@pnAssociatedNameKey		= @pnAssociatedNameKey,
				@sAssociatedName		= @sAssociatedName output,
				@sAssociatedNameCode		= @sAssociatedNameCode output
	End	
	
	If @nErrorCode = 0
	Begin
		Select
			@pnNameKey			as NameKey,
			@psRelationshipCode 		as RelationshipCode,
			@sRelationshipDescription	as RelationshipDescription,
			@bIsReverse			as IsReverse,
			@pnAssociatedNameKey		as AssociatedNameKey,
			@sAssociatedName		as AssociatedName,
			@sAssociatedNameCode		as AssociatedNameCode 
	End
End

If @nErrorCode = 0
and @pbNewRow <> 1
Begin
	Set @sSQLString = "Select

	CAST(A.NAMENO as nvarchar(11))+'^'+
	A.RELATIONSHIP+'^'+
	CAST(A.RELATEDNAME as nvarchar(11))+'^'+
	CAST(A.SEQUENCE as nvarchar(10))
					as RowKey,
	CASE A.NAMENO	
	WHEN @pnNameKey THEN A.NAMENO
	ELSE A.RELATEDNAME
	END				as NameKey,
	A.RELATIONSHIP			as RelationshipCode,
	CASE A.NAMENO	
	WHEN @pnNameKey THEN 
	"+dbo.fn_SqlTranslatedColumn('NAMERELATION','RELATIONDESCR',null,'NR',
					@sLookupCulture,@pbCalledFromCentura)+"
	ELSE 
	"+dbo.fn_SqlTranslatedColumn('NAMERELATION','REVERSEDESCR',null,'NR',
					@sLookupCulture,@pbCalledFromCentura)+"
	END				as RelationshipDescription,
	CASE A.NAMENO	
	WHEN @pnNameKey THEN A.RELATEDNAME
	ELSE A.NAMENO
	END				as AssociatedNameKey,
	CASE A.NAMENO	
	WHEN @pnNameKey THEN dbo.fn_FormatNameUsingNameNo(AN.NAMENO, null)
	ELSE dbo.fn_FormatNameUsingNameNo(N.NAMENO, null)
	END				as AssociatedName,
	CASE A.NAMENO	
	WHEN @pnNameKey THEN AN.NAMECODE
	ELSE N.NAMECODE
	END				as AssociatedNameCode,
	A.SEQUENCE			as Sequence,
	CASE WHEN (A.RELATEDNAME = @pnNameKey and  A.NAMENO <> @pnNameKey) 
                THEN cast(1 as bit)
	        ELSE cast(0 as bit)
	END				as IsReverse,
	CASE WHEN (N.NAMENO=@pnNameKey and N.MAINCONTACT=A.RELATEDNAME)
		THEN cast(1 as bit) 
		ELSE cast(0 as bit)
	END				as IsMainContact,
	A.PROPERTYTYPE			as PropertyTypeCode,
	"+dbo.fn_SqlTranslatedColumn('PROPERTYTYPE','PROPERTYNAME',null,'P',
					@sLookupCulture,@pbCalledFromCentura)+"
					as PropertyTypeDescription,
	A.COUNTRYCODE			as CountryCode,
	"+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',
					@sLookupCulture,@pbCalledFromCentura)+"
					as CountryName,
	A.ACTION			as ActionCode,
	"+dbo.fn_SqlTranslatedColumn('ACTIONS','ACTIONNAME',null,'ACT',
					@sLookupCulture,@pbCalledFromCentura)+"
					as [Action],
	A.CONTACT			as AttentionKey,
	dbo.fn_FormatNameUsingNameNo(ATT.NAMENO, null)
					as AttentionName,
	A.JOBROLE			as JobRoleKey,
	cast(A.USEINMAILING as bit)	as UseInMailing,
	A.CEASEDDATE			as CeaseDate,
	A.POSITIONCATEGORY		as PositionCategoryKey,
	"+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TCPC',
					@sLookupCulture,@pbCalledFromCentura)+"
					as PositionCategory,
	"+dbo.fn_SqlTranslatedColumn('ASSOCIATEDNAME','POSITION',null,'A',
					@sLookupCulture,@pbCalledFromCentura)+"
					as Position,
	A.TELEPHONE			as PhoneKey,
	A.FAX				as FaxKey,
	A.POSTALADDRESS			as PostalAddressKey,
	A.STREETADDRESS			as StreetAddressKey,
	cast(A.USEINFORMAL as bit)	as UseInformalSalutation,
	A.VALEDICTION			as ValedictionKey,
	A.NOTES				as Notes,
	A.CRMONLY			as IsCRMOnly,
	A.FORMATPROFILEID               as BillFormatProfileKey,
	BFP.FORMATDESC                  as BillFormatProfile,

	CASE A.RELATEDNAME	
	WHEN @pnNameKey THEN cast((isnull(N.USEDASFLAG, 0) & 1) as bit)	
	ELSE cast((isnull(AN.USEDASFLAG, 0) & 1) as bit)
	END as IsIndividual,

	CASE A.RELATEDNAME	
	WHEN @pnNameKey THEN ~cast((isnull(N.USEDASFLAG, 0) & 1) as bit)
	ELSE ~cast((isnull(AN.USEDASFLAG, 0) & 1) as bit)	
	END as IsOrganisation,

	CASE A.RELATEDNAME	
	WHEN @pnNameKey THEN cast((isnull(N.USEDASFLAG, 0) & 2) as bit)
	ELSE cast((isnull(AN.USEDASFLAG, 0) & 2) as bit)	
	END as IsStaff,

	CASE A.RELATEDNAME	
	WHEN @pnNameKey THEN cast((isnull(N.USEDASFLAG, 0) & 4) as bit)	
	ELSE cast((isnull(AN.USEDASFLAG, 0) & 4) as bit)
	END as IsClient,

	CASE A.RELATEDNAME	
	WHEN @pnNameKey THEN cast(isnull(N.SUPPLIERFLAG, 0) as bit) 		
	ELSE cast(isnull(AN.SUPPLIERFLAG, 0) as bit)
	END as IsSupplier


	from ASSOCIATEDNAME A
	join NAME 		N 	on (N.NAMENO = A.NAMENO)
	join NAME 		AN 	on (AN.NAMENO = A.RELATEDNAME)
	join NAMERELATION	NR 	on (NR.RELATIONSHIP = A.RELATIONSHIP)
	left join PROPERTYTYPE 	P	on (P.PROPERTYTYPE = A.PROPERTYTYPE)
	left join COUNTRY 	C	on (C.COUNTRYCODE = A.COUNTRYCODE)
	left join ACTIONS 	ACT	on (ACT.ACTION = A.ACTION)
	left join NAME 		ATT 	on (ATT.NAMENO	= A.CONTACT)
	left join TABLECODES 	TCPC 	on (TCPC.TABLECODE = A.POSITIONCATEGORY)
	left join FORMATPROFILE BFP     on (BFP.FORMATID = A.FORMATPROFILEID)
	where 	(A.NAMENO = @pnNameKey 
		or A.RELATEDNAME = @pnNameKey)"

	if (@psRelationshipCode != '')
	Begin
		Set @sSQLString = @sSQLString + "
		and A.RELATIONSHIP = @psRelationshipCode"
	End

	Set @sSQLString = @sSQLString + "
	order by NameKey, 
		 RelationshipDescription, 
		 IsMainContact desc,
		 AssociatedName,
		 AssociatedNameCode, 
		 AssociatedNameKey"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'
			@pnNameKey	int,
			@psRelationshipCode nvarchar(3)',
			@pnNameKey	= @pnNameKey,
			@psRelationshipCode = @psRelationshipCode
End

Return @nErrorCode
GO

Grant execute on dbo.naw_FetchAssociatedName to public
GO