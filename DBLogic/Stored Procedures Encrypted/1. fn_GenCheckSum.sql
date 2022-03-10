-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GenCheckSum
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id('dbo.fn_GenCheckSum') and xtype='FN')
Begin
	 Print '**** Drop function dbo.fn_GenCheckSum.'
	 Drop function [dbo].[fn_GenCheckSum]
End
Print '**** Creating function dbo.fn_GenCheckSum...'
Print ''
go

CREATE function dbo.fn_GenCheckSum 
(
	@psText 		nvarchar(4000)
)
Returns int
With ENCRYPTION
AS 
-- function :	fn_GenCheckSum
-- VERSION :	1
-- DESCRIPTION:	Create a checksum
-- NOTES:	This is not very complicated / sophisticated as it does not need to be
--
--		NOTE: DO NOT DELIVER THIS TO THE CLIENT - DO NOT CHECK IN TO CLEARCASE
--
-- MODIFICATIONS :
-- Date		Who	Version	Change
-- ------------	-------	-------	----------------------------------------------- 
-- 27/04/2004	JB		function created
Begin

Declare @nCheckSum int  -- The result
Declare @nCount int

Set @nCheckSum = 0
Set @nCount = 1


While @nCount <= LEN( @psText )
Begin
	Set @nCheckSum = @nCheckSum + ASCII( SUBSTRING(@psText, @nCount, 1) )
	Set @nCount = @nCount + 1
End

Return @nCheckSum
End

GO

Grant execute on dbo.fn_GenCheckSum to public
GO
