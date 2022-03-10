-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetFirstOpenItemNumber
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetFirstOpenItemNumber') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetFirstOpenItemNumber'
	Drop function [dbo].[fn_GetFirstOpenItemNumber]
End
Print '**** Creating Function dbo.fn_GetFirstOpenItemNumber...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetFirstOpenItemNumber
(
	@psItemPrefix   	nvarchar(2), 	        -- Item Prefix
	@pnFirstOpenItemNo	decimal(10,0), 		-- First Open Item No Available
	@pnCountOpenItems	int = 1	                -- Count of Open Items         
) 
RETURNS decimal(10,0)
AS
-- Function :	fn_GetFirstOpenItemNumber
-- VERSION :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the Fisrt open item number to be used for debit note. 
--              Used for Debit note number generation logic based on office

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 29 DEC 2010	MS	RFC8297	1	Function created
-- 22 Mar 2011  MS      RFC100492 2     Changed the string comparison check from = to like for Credit notes.

Begin

	declare @nFirstOpenItemNo       decimal(10,0)
        declare @nLastOpenItemNo        decimal(10,0)        

	Set @nFirstOpenItemNo = @pnFirstOpenItemNo

        WHILE EXISTS (Select OPENITEMNO FROM OPENITEM where OPENITEMNO like @psItemPrefix + CAST(@nFirstOpenItemNo as nvarchar(10))+ '%') 
        Begin
        Set @nFirstOpenItemNo = @nFirstOpenItemNo + 1
        End

        Set @nLastOpenItemNo = @nFirstOpenItemNo + @pnCountOpenItems - 1
        
        WHILE EXISTS (Select OPENITEMNO FROM OPENITEM where OPENITEMNO like @psItemPrefix + CAST(@nLastOpenItemNo as nvarchar(10))+ '%')
        Begin
        Set @nLastOpenItemNo = @nLastOpenItemNo + 1
        End

        If @nLastOpenItemNo > @nFirstOpenItemNo + @pnCountOpenItems - 1
        Begin
	        Set @nFirstOpenItemNo = @nLastOpenItemNo 
        End

	return @nFirstOpenItemNo
End
GO

grant execute on dbo.fn_GetFirstOpenItemNumber to public
go
