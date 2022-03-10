-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_IsCaseListDuplicate 
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_IsCaseListDuplicate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_IsCaseListDuplicate.'
	Drop procedure [dbo].[csw_IsCaseListDuplicate]
End
Print '**** Creating Stored Procedure dbo.csw_IsCaseListDuplicate...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.csw_IsCaseListDuplicate
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pbCalledFromCentura	bit		= 0,
	@psListName			nvarchar(100)
)
as
-- PROCEDURE:	csw_IsCaseListDuplicate
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Checks if the list already exists

-- MODIFICATIONS :
-- Date			Who		Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 MAR 2011	KR		RFC6563	1		Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int

-- Initialise variables 
Set @nErrorCode = 0

If @nErrorCode = 0
Begin

	If exists (Select 1 from CASELIST where CASELISTNAME = @psListName)
	begin 
		Select 1 as tinyint
	end
	else
	begin 
		Select 0 as tinyint
	end	
	
	Set @nErrorCode = @@Error
End

Return @nErrorCode
GO

Grant execute on dbo.csw_IsCaseListDuplicate to public
GO
