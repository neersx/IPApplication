-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_Clarify
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_Clarify') and xtype='FN')
Begin
	 Print '**** Drop function dbo.fn_Clarify.'
	 Drop function [dbo].[fn_Clarify]
End
Print '**** Creating function dbo.fn_Clarify...'
Print ''
go

CREATE function dbo.fn_Clarify 
(
	@psObscuredText 		nvarchar(254)
)
Returns nvarchar(254)
With ENCRYPTION
AS 
-- function :	fn_Clarify
-- VERSION :	1
-- DESCRIPTION:	Clarify the data obscured by fn_Obfuscate().
--
-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 14 May 2005	JEK	1	Function created.

Begin
-- Reverse all but the last two characters
-- Move the last character to the beginning
Return 	case when (len(@psObscuredText) > 1)
	then	substring(@psObscuredText, len(@psObscuredText), 1)+
		reverse(substring(@psObscuredText, 1, len(@psObscuredText)-2))+
		substring(@psObscuredText, len(@psObscuredText)-1, 1)
	else	@psObscuredText
	end
End

GO

Grant execute on dbo.fn_Clarify to public
GO
