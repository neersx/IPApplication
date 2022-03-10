-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListOffices 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListOffices]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListOffices.'
	Drop procedure [dbo].[ipw_ListOffices]
	Print '**** Creating Stored Procedure dbo.ipw_ListOffices...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListOffices 
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pbCalledFromCentura	bit		= 0
)
AS
-- PROCEDURE:	ipw_ListOffices 
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Populates Office data table.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 28 Dec 2010  MS	RFC8297	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(4000)
Declare @sLookupCulture nvarchar(10)

Set @nErrorCode         = 0
Set @pnRowCount	        = 0
set @sLookupCulture     = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
	
-- Populating Office data table
If @nErrorCode = 0
Begin	
	Set @sSQLString = "
	Select  O.OFFICEID 	as OfficeKey,
                "+dbo.fn_SqlTranslatedColumn('OFFICE','DESCRIPTION',null,'O',@sLookupCulture,@pbCalledFromCentura)
				+ " as Description,
                O.USERCODE      as UserCode,
                O.COUNTRYCODE   as CountryCode,   
                "+dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)
				+ " as Country,             
                O.LANGUAGECODE  as LanguageCode,
                "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TL',@sLookupCulture,@pbCalledFromCentura)
				+ " as Language,     
                O.CPACODE       as CPACode,
                O.IRNCODE       as IRNCode,
		O.RESOURCENO	as ResourceCode,
                "+dbo.fn_SqlTranslatedColumn('RESOURCE','DESCRIPTION',null,'R',@sLookupCulture,@pbCalledFromCentura)
				+ " as Resource,  
                O.REGION        as RegionCode,
                "+dbo.fn_SqlTranslatedColumn('TABLECODES','DESCRIPTION',null,'TR',@sLookupCulture,@pbCalledFromCentura)
				+ " as Region,  
                O.ORGNAMENO     as OrganisationKey,
                N.NAMECODE      as OrganisationCode,
                "+dbo.fn_SqlTranslatedColumn('NAME','NAME',null,'N',@sLookupCulture,@pbCalledFromCentura)
				+ " as OrganisationName,               
		O.ITEMNOPREFIX	as ItemNoPrefix,
		O.ITEMNOFROM	as ItemNoFrom,
		O.ITEMNOTO 	as ItemNoTo,
                O.LASTITEMNO    as LastDebitNumber,
                O.LOGDATETIMESTAMP as ModifiedDate
	from OFFICE O
	left join COUNTRY C on (C.COUNTRYCODE = O.COUNTRYCODE)
        left join TABLECODES TL on (TL.TABLECODE = O.LANGUAGECODE)
        left join TABLECODES TR on (TR.TABLECODE = O.REGION)
        left join RESOURCE R on (R.RESOURCENO = O.RESOURCENO)
        left join NAME N on (N.NAMENO = O.ORGNAMENO)
	order by 2"

	exec @nErrorCode=sp_executesql @sSQLString

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListOffices to public
GO
