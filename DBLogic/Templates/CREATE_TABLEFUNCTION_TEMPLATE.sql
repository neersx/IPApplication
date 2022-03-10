-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_MyFuncWithTableVariableWithTableVariable
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_MyFuncWithTableVariable') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_MyFuncWithTableVariable'
	Drop function [dbo].[fn_MyFuncWithTableVariable]
End
Print '**** Creating Function dbo.fn_MyFuncWithTableVariable...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE FUNCTION dbo.fn_MyFuncWithTableVariable
			(@pInput	int
			 @pInput2	int
			) 
RETURNS @tbVariableName TABLE
   (
        NCHARTYPE            nchar(1)		collate database_default NOT NULL,
        NVARCHARTYPE         nvarchar(50)	collate database_default NULL
   )

AS
-- Function :	fn_MyFuncWithTableVariable
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Function description here

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- dd MMM YYYY	AP	####	1	Function created

Begin

	-- function body
End
GO

grant REFERENCES, SELECT on dbo.fn_MyFuncWithTableVariable to public
go
