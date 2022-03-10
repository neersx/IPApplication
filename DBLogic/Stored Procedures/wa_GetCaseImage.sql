-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_GetCaseImage
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_GetCaseImage]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_GetCaseImage'
	drop procedure [dbo].[wa_GetCaseImage]
	print '**** Creating procedure dbo.wa_GetCaseImage...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.wa_GetCaseImage
(
	@pnCaseId		int			
)
-- PROCEDURE:	wa_GetCaseImage
-- VERSION:	1
-- SCOPE:	Web Access Module
-- DESCRIPTION:	Returns the image for the specified CASEID

-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 28-APR-2003  JB	1	Procedure created

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode int
Set @nErrorCode = 0

If @nErrorCode = 0
Begin
	Select I.IMAGEDATA
		from IMAGE I
		where I.IMAGEID=( 
			select min(CI.IMAGEID)
			from CASEIMAGE CI
			where CI.CASEID = @pnCaseId
			)

	Set @nErrorCode = @@ERROR
End
GO

Grant execute on dbo.wa_GetCaseImage to public
GO
