-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListCriteria
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListCriteria]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListCriteria.'
	Drop procedure [dbo].[ipw_ListCriteria]
End
Print '**** Creating Stored Procedure dbo.ipw_ListCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ipw_ListCriteria
(
	@pnRowCount		int		= null	output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pbCalledFromCentura	bit		= 0,
	@psType			nvarchar(10)	= 'Case'
)
as
-- PROCEDURE:	ipw_ListCriteria
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the list of Criteria for Case and Name
--		If @psType = 'Case' then Case Criteria list will be returned
--		If @psType = 'Name' then Name Criteria list will be returned
--		If @psType = 'Checklist' then Checklist Criteria list will be returned

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 21 JAN 2010	MS	RFC7329	1	Procedure created
-- 31 MAR 2010	MS	RFC7329	2	Added Description and Code field in Criteria picklist
-- 10 DEC 2010	KR	RFC9193	3	Extended for checklist

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode	int
Declare @sSql		nvarchar(1000)

-- Initialise variables
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	Select @sSql =
		Case upper(@psType)
			When 'NAME' Then
				"Select NAMECRITERIANO as CriteriaKey,
				Cast(NAMECRITERIANO as nvarchar(11)) as CriteriaCode,
				DESCRIPTION as CriteriaDesc 
				from NAMECRITERIA
				where PURPOSECODE = CASE WHEN @pbCalledFromCentura = 0 THEN 'W' else 'S' end
				order by NAMECRITERIANO"
			When 'CASE' Then
				"Select CRITERIANO as CriteriaKey,
				Cast(CRITERIANO as nvarchar(11)) as CriteriaCode,
				DESCRIPTION as CriteriaDesc  
				from CRITERIA
				where PURPOSECODE = CASE WHEN @pbCalledFromCentura = 0 THEN 'W' else 'S' end
				order by CRITERIANO"
			When 'CHECKLIST' Then
				"Select CRITERIANO as CriteriaKey,
				Cast(CRITERIANO as nvarchar(11)) as CriteriaCode,
				DESCRIPTION as CriteriaDesc  
				from CRITERIA
				where PURPOSECODE = CASE WHEN @pbCalledFromCentura = 0 THEN 'C' end
				order by CRITERIANO"
		End

	exec @nErrorCode= sp_executesql @sSql,
			N'@pbCalledFromCentura	bit',
			@pbCalledFromCentura	= @pbCalledFromCentura

	Set @pnRowCount = @@Rowcount
End

Return @nErrorCode
GO

Grant execute on dbo.ipw_ListCriteria to public
GO