-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ListMultipleCountries
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_ListMultipleCountries]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_ListMultipleCountries.'
	Drop procedure [dbo].[ip_ListMultipleCountries]
End
Print '**** Creating Stored Procedure dbo.ip_ListMultipleCountries...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ip_ListMultipleCountries
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psCountryKeys		nvarchar(4000)
)
as
-- PROCEDURE:	ip_ListMultipleCountries
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Given a list of comma delimited countryKeys, return matching countries as a result set.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24 AUG 2006	SF	RFC4121	1	Procedure created
-- 04 Feb 2010	DL	18430	2	Grant stored procedure to public


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Declare @sSQLString nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)
Declare @CommaString				nchar(2)	-- DataType(CS) to indicate a Comma Delimited String
Set	@CommaString				='CS'

Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

Set @nErrorCode = 0

Set @sSQLString='
Select	C.COUNTRYCODE 						as CountryKey,'+char(10)+
	dbo.fn_SqlTranslatedColumn('COUNTRY','COUNTRY',null,'C',@sLookupCulture,@pbCalledFromCentura)+' as CountryName'+char(10)+
'from	COUNTRY C
where	C.COUNTRYCODE'+dbo.fn_ConstructOperator(0,@CommaString,@psCountryKeys, null,@pbCalledFromCentura)



exec @nErrorCode=sp_executesql @sSQLString,
				N'@psCountryKeys		nvarchar(4000)',
				  @psCountryKeys		=@psCountryKeys


RETURN @nErrorCode
go

Grant execute on dbo.ip_ListMultipleCountries to public
GO
