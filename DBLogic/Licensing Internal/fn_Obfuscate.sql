-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_Obfuscate
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_Obfuscate') and xtype='FN')
Begin
	 Print '**** Drop function dbo.fn_Obfuscate.'
	 Drop function [dbo].[fn_Obfuscate]
End
Print '**** Creating function dbo.fn_Obfuscate...'
Print ''
go

CREATE function dbo.fn_Obfuscate 
(
	@psClearText 		nvarchar(254)
)
Returns nvarchar(254)
With ENCRYPTION
AS 
-- function :	fn_Obfuscate
-- VERSION :	1
-- DESCRIPTION:	Obscure the data so that it is difficult to tell its meaning
-- NOTES:	See corresponding function fn_Clarify().
--
--		NOTE: DO NOT DELIVER THIS TO THE CLIENT
--
-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 14 May 2005	JEK	1	Function created.

Begin
-- Reverse all but the first and last characters
-- Move the first character.
Return 	case when (len(@psClearText) > 1)
	then
		reverse(substring(@psClearText, 2, len(@psClearText)-2))+
		substring(@psClearText, len(@psClearText), 1)+
		substring(@psClearText, 1,1)
	else	@psClearText
	end
End

GO

Grant execute on dbo.fn_Obfuscate to public
GO
