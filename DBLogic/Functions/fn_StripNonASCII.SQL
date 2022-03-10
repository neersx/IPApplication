-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_StripNonASCII
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_StripNonASCII') and xtype in (N'FN', N'IF', N'TF'))
Begin
	Print '**** Drop Function dbo.fn_StripNonASCII'
	Drop function [dbo].[fn_StripNonASCII]
End
Print '**** Creating Function dbo.fn_StripNonASCII...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE FUNCTION fn_StripNonASCII(@sStringWithASCII nvarchar(max))
RETURNS varchar(max)

AS
-- Function :	fn_StripNonASCII
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Strips out the non ASCII character and returns the remaining text.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 12 Sep 2014	MF		1	Function created
BEGIN

    DECLARE @sResult	varchar(max)
    DECLARE @sChar	nvarchar(1)
    DECLARE @nPosition	int
    
    SET @sResult = ''

    SET @nPosition = 1
    
    WHILE @nPosition <= LEN(@sStringWithASCII)
    BEGIN
        SET @sChar = SUBSTRING(@sStringWithASCII, @nPosition, 1)
        --Unicode & ASCII are the same from 1 to 255.
        --Only Unicode goes beyond 255
        --0 to 31 are non-printable characters
        IF UNICODE(@sChar) between 32 and 255
            SET @sResult = @sResult + @sChar
        SET @nPosition = @nPosition + 1
    END

    RETURN @sResult

END
GO

grant execute on dbo.fn_StripNonASCII to public
go
