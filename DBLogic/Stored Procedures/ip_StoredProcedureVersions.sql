SET QUOTED_IDENTIFIER OFF
GO

-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_StoredProcedureVersions]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_StoredProcedureVersions.'
	Drop procedure [dbo].[ip_StoredProcedureVersions]
End
Print '**** Creating Stored Procedure dbo.ip_StoredProcedureVersions...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.ip_StoredProcedureVersions
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null	
)
-- PROCEDURE:	ip_StoredProcedureVersions
-- VERSION:	5
-- SCOPE:	CPA.net, InPro.net
-- DESCRIPTION:	Retrieve version numbers of all stored procedure used for this product

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 15-Nov-2002  SF	1	Procedure created
-- 13-DEC-2002	SF	2	1. Include "in" in the filter
--				2. Uses the fn_StripToFirstNumeric to extract the version number.
-- 06-JAN-2003	SF	3	The name refer in CPA.Net is different from the column alias selected from here.
-- 28-JUL-2003	TM	4	RFC278 - Not all Stored Procedures are listed on about page. Replace filtering stored  
--				procedure list based on the name prefixes with IsMSShipped = 0 objectproperty to filter out  
--				system stored procedures. Stored procedures that do not have a Version Number are 
--				also filtered out (and dbo.fn_GetStoredProcedureVersion(ROUTINE_NAME) <> '').
-- 28-JUL-2003	TM	5	RFC287 - Version number not shown for cs_UpdateCase. Replace logic that extracts Version Number
--				based on fn_StripToFirstNumeric with function fn_GetStoredProcedureVersion. 
as

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Set 	@nErrorCode = 0


If @nErrorCode = 0
Begin
	Select	ROUTINE_NAME as 'Stored Procedure Names',		
		dbo.fn_GetStoredProcedureVersion(ROUTINE_NAME) as Version
	from 	INFORMATION_SCHEMA.ROUTINES
	where OBJECTPROPERTY( object_id(ROUTINE_NAME),'IsMSShipped') = 0
	and dbo.fn_GetStoredProcedureVersion(ROUTINE_NAME) <> '' 
	order by ROUTINE_NAME

	Set @nErrorCode = @@ERROR
End

Return @nErrorCode
GO

Grant execute on dbo.ip_StoredProcedureVersions to public
GO


