-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_GetSiteControl
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_GetSiteControl]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_GetSiteControl.'
	Drop procedure [dbo].[ip_GetSiteControl]
	Print '**** Creating Stored Procedure dbo.ip_GetSiteControl...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_GetSiteControl
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psControlId		nvarchar(4000),	-- Case sensitive
	@psDelimiter		nvarchar(3)	= '^^^'
)
-- PROCEDURE:	ip_GetSiteControl
-- VERSION :	5
-- DESCRIPTION:	Given the Control Id (Case Sensitive), retrieve the Site Control

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15-OCT-2002  SF	1		Procedure created
-- 26-FEB-2003	SF	2		Return COLBOOLEAN as bit rather than decimal
-- 20 Jun 2004	JEK	3		Increase size of ControlID to 30 characters
--					and implement sp_executesql for performance.
-- 11 Dec 2008	MF	4	17136	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 26 Jul 2011	SF	5	11013	Allow multiple site controls to be queried and returned

as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)
Declare @sControlIdsInClause	nvarchar(4000)	-- RFC1717 variable to prepare a comma separated list of values
Declare @bCalledFromCentura	bit

-- Initialise variables
Set @nErrorCode = 0
Set @bCalledFromCentura = 0
 
If @nErrorCode = 0
and PATINDEX('%'+isnull(@psDelimiter, '^^^')+'%', @psControlId) > 0
Begin
	Set @sControlIdsInClause = null
	Set @psDelimiter = ISNULL(@psDelimiter, '^^^')
	
	Select @sControlIdsInClause = @sControlIdsInClause+ isnull(nullif(',', ',' + @sControlIdsInClause), '') 
		+ dbo.fn_WrapQuotes(Parameter,0,@bCalledFromCentura)
	from dbo.fn_Tokenise(@psControlId, @psDelimiter)
End
Else
Begin
	Set @sControlIdsInClause = dbo.fn_WrapQuotes(@psControlId,0,@bCalledFromCentura)
End

If @nErrorCode = 0
Begin
			
	Set @sSQLString = "
	Select 	CONTROLID	as 'ControlId',
		OWNER 		as 'Owner',
		DATATYPE 	as 'DataType',
		COLINTEGER 	as 'IntegerValue',
		COLCHARACTER	as 'StringValue',
		COLDECIMAL	as 'DecimalValue',
		COLDATE		as 'DateValue',		
		cast(COLBOOLEAN	as bit) as 'BooleanValue'
	from	SITECONTROL
	where	CONTROLID in (" + @sControlIdsInClause + ")"

print @sSQLString
	exec @nErrorCode=sp_executesql @sSQLString

End

Return @nErrorCode
GO

Grant execute on dbo.ip_GetSiteControl to public
GO
