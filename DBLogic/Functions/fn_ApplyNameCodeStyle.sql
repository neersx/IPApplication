-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ApplyNameCodeStyle
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_ApplyNameCodeStyle]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop function dbo.fn_ApplyNameCodeStyle.'
	drop function [dbo].[fn_ApplyNameCodeStyle]
	print '**** Creating function dbo.fn_ApplyNameCodeStyle...'
	print ''
end
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE Function [dbo].[fn_ApplyNameCodeStyle]
			(
			  @psName			nvarchar(254),
			  @pdCodeDisplayFormat    decimal(1,0),
			  @psNameCode		nvarchar(20)
			)
Returns nvarchar(254)

-- FUNCTION :	fn_ApplyNameCodeStyle
-- VERSION :	1
-- DESCRIPTION:	This function accepts the components of a Name and applies the name code 
--		style to the formatted name.

-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 8 NOV 2013	SW		1	Function created


Begin
	declare @sFormattedName	nvarchar(254)

	-- The Address styles are hardcode values as follows :
	-- 1		Code is prepended 
	-- 2		Code is appended
	-- 0 or NULL	Code is not set

	If @pdCodeDisplayFormat = 1 and @psNameCode IS NOT NULL 
	Begin		
		Select @sFormattedName= '{' +  @psNameCode + '}' + SPACE(2) + @psName
	End
	Else If @pdCodeDisplayFormat = 2 and @psNameCode IS NOT NULL
	Begin
		Select @sFormattedName=	@psName + SPACE(2) + '{' +  @psNameCode + '}'
	End
	Else 
	Begin
		Select @sFormattedName= @psName
	End	

	Return ltrim(rtrim(@sFormattedName))
End

GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_ApplyNameCodeStyle to public
GO
