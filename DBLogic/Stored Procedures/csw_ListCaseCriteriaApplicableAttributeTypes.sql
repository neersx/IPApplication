-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCaseCriteriaApplicableAttributeTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCaseCriteriaApplicableAttributeTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCaseCriteriaApplicableAttributeTypes.'
	Drop procedure [dbo].[csw_ListCaseCriteriaApplicableAttributeTypes]
End
Print '**** Creating Stored Procedure dbo.csw_ListCaseCriteriaApplicableAttributeTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.csw_ListCaseCriteriaApplicableAttributeTypes
(
	@pnRowCount			int output,
	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnCriteriaKey		int	 -- Mandatory
)
as
-- PROCEDURE:	csw_ListCaseCriteriaApplicableAttributeTypes
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the Applicable Attribute Types for the Case Criteria.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 Mar 2010	PS	RFC7285	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON

Declare @nErrorCode		int
declare @sSQLString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode			= 0


Declare @sCaseType nvarchar(254)
Declare @sPropertyType nvarchar(254)

if @nErrorCode = 0 
begin
	set @sSQLString = "select 
	@sCaseType =  CT.CASETYPEDESC, 
	@sPropertyType = 
	CASE WHEN VP.PROPERTYNAME is not null THEN VP.PROPERTYNAME 
	ELSE PT.PROPERTYNAME  END
	from CRITERIA C 
	left join CASETYPE CT on (C.CASETYPE = CT.CASETYPE)
	left join PROPERTYTYPE PT on (C.PROPERTYTYPE = PT.PROPERTYTYPE)
	left join VALIDPROPERTY VP on (C.PROPERTYTYPE = VP.PROPERTYTYPE and C.COUNTRYCODE = VP.COUNTRYCODE)
	where CRITERIANO = @pnCriteriaKey"
	
	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnCriteriaKey	int,
			  @sCaseType		nvarchar(254) output,
			  @sPropertyType	nvarchar(254) output',
			  @pnCriteriaKey	= @pnCriteriaKey,
			  @sCaseType 		= @sCaseType output,
			  @sPropertyType	= @sPropertyType output
	
end

if @nErrorCode = 0 and @sCaseType is not null and @sPropertyType is not null
begin
	set @sSQLString = "select 
	TT.TABLENAME as AttributeType, 
	CASE WHEN ST.MINIMUMALLOWED > 0 THEN CAST(1 as bit) ELSE CAST(0 as bit) END as IsMandatory,
	ST.MINIMUMALLOWED as MinimumAllowed,
	ST.MAXIMUMALLOWED as MaximumAllowed
	from SELECTIONTYPES ST
	left join TABLETYPE TT on (ST.TABLETYPE = TT.TABLETYPE)
	where ST.PARENTTABLE = upper(@sCaseType) + '/' + upper(@sPropertyType)"
	
	exec @nErrorCode=sp_executesql @sSQLString,
		N'@sCaseType		nvarchar(254),
		  @sPropertyType	nvarchar(254)',
		  @sCaseType 	= @sCaseType,
		  @sPropertyType = @sPropertyType
end

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCaseCriteriaApplicableAttributeTypes to public
GO
