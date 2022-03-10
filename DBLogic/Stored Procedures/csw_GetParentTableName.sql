-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_GetParentTableName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_GetParentTableName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_GetParentTableName.'
	Drop procedure [dbo].[csw_GetParentTableName]
	Print '**** Creating Stored Procedure dbo.csw_GetParentTableName...'
	Print ''
End
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_GetParentTableName
(	
	@psParentTableName		nvarchar(50)		OUTPUT,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pbCalledFromCentura	bit		= 0,
	@pnCaseKey		int		-- Mandatory
)
AS
-- PROCEDURE:	csw_GetParentTableName
-- VERSION:	1
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns ParentTableName on the basis of Casekey. Used in case there are no Attribute list 
-- returned on the Attribute Maintenance window.
-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 04-Dec-2009	DV		RFC100088	1	Procedure created


SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode 	int
Declare @sSQLString	nvarchar(500)

Set	@nErrorCode      = 0

If (@nErrorCode = 0)
Begin
	-- Return attributes for the case
	Set @sSQLString = "SELECT @psParentTableName = UPPER(CT.CASETYPEDESC) + '/' + UPPER(ISNULL(VP.PROPERTYNAME,P.PROPERTYNAME))
				FROM CASES C
				JOIN CASETYPE CT ON CT.CASETYPE = C.CASETYPE
				JOIN PROPERTYTYPE P ON (P.PROPERTYTYPE = C.PROPERTYTYPE)
				LEFT JOIN VALIDPROPERTY VP ON (VP.PROPERTYTYPE = C.PROPERTYTYPE
								AND VP.COUNTRYCODE = C.COUNTRYCODE)
				WHERE C.CASEID = @pnCaseKey"


	exec @nErrorCode=sp_executesql @sSQLString,
					N'	@psParentTableName	nvarchar(101) OUTPUT,
						@pnCaseKey	int',
						@psParentTableName	= @psParentTableName OUTPUT,
						@pnCaseKey	= @pnCaseKey

End

Return @nErrorCode
GO

Grant execute on dbo.csw_GetParentTableName to public
GO
