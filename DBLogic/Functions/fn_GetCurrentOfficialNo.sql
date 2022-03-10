-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCurrentOfficialNo
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_GetCurrentOfficialNo]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop Function dbo.fn_GetCurrentOfficialNo.'
	drop function [dbo].[fn_GetCurrentOfficialNo]
	print '**** Creating Function dbo.fn_GetCurrentOfficialNo...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetCurrentOfficialNo
	(
		@pnCaseId int
	)
Returns nvarchar(36)
-- FUNCTION :	fn_GetCurrentOfficialNo
-- VERSION :	3
-- DESCRIPTION:	Gets the current official number for the selected case

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 14/07/2002	JB	Function created
-- 
AS
Begin
	Declare @sCurrentOfficialNo nvarchar(36)
	-- This comes from FCDBOfficialNumberX.cfDBRetreieveByNumTypeCurrCase():
	SELECT  TOP 1 @sCurrentOfficialNo = O.[OFFICIALNUMBER] 
		FROM	[OFFICIALNUMBERS] O
		JOIN 	[NUMBERTYPES] NT  ON NT.[NUMBERTYPE] = O.[NUMBERTYPE]
		WHERE 	O.[CASEID] = @pnCaseId 
		AND 	NT.[ISSUEDBYIPOFFICE] = 1
		AND 	O.[ISCURRENT] =  1
		ORDER BY NT.[DISPLAYPRIORITY] ASC, O.[DATEENTERED] DESC

	Return @sCurrentOfficialNo
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_GetCurrentOfficialNo to public
GO
