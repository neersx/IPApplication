-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipn_ListOffices
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipn_ListOffices]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.ipn_ListOffices.'
	drop procedure [dbo].[ipn_ListOffices]
	print '**** Creating Stored Procedure dbo.ipn_ListOffices...'
	print ''
end
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ipn_ListOffices
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null
)
AS
-- PROCEDURE:	ipn_ListOffices
-- VERSION:	1
-- DESCRIPTION:	List Offices
-- SCOPE:	CPA.net

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 11 Aug 2003	TM	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Set     @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select 	Office.OFFICEID		as 'OfficeKey',
		Office.DESCRIPTION      as 'OfficeDescription',
	 	Office.USERCODE 	as 'OfficeCode'
	from    OFFICE 			as Office	
	order by DESCRIPTION

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ipn_ListOffices to public
GO
