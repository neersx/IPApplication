-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListCountryAttributeTypes
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListCountryAttributeTypes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListCountryAttributeTypes.'
	Drop procedure [dbo].[csw_ListCountryAttributeTypes]
End
Print '**** Creating Stored Procedure dbo.csw_ListCountryAttributeTypes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_ListCountryAttributeTypes
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	csw_ListCountryAttributeTypes
-- VERSION:	1
-- DESCRIPTION:	Populates the Country Attribute types dataset 

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 JUN 2013	MS	DR108	1	Procedure created.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString 	nvarchar(4000)

-- Initialise variables
Set @nErrorCode = 0

Set @sSQLString = " 
	Select  T.TABLETYPE	as AttributeTypeKey,
		T.TABLENAME	as AttributeType		
	from TABLETYPE T
	left join SELECTIONTYPES S on (S.TABLETYPE = T.TABLETYPE)
	where S.PARENTTABLE = 'COUNTRY'
	Order by AttributeType"		    

exec @nErrorCode=sp_executesql @sSQLString

Return @nErrorCode
GO

Grant execute on dbo.csw_ListCountryAttributeTypes to public
GO