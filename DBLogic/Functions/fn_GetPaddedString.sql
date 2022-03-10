-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetPaddedString
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetPaddedString') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetPaddedString'
	Drop function [dbo].[fn_GetPaddedString]
	Print '**** Creating Function dbo.fn_GetPaddedString...'
	Print ''
End
go

CREATE FUNCTION dbo.fn_GetPaddedString
(
	@psPadString 	nvarchar(100), 
	@pnLength 	int, 
	@psPadding 	char(1), 
	@pbStart 	tinyint
) 
returns nvarchar(100)

As
-- Function :	fn_GetPaddedString
-- VERSION :	1.0.0
-- DESCRIPTION:	Pad the string passed with the padding specified to the length specifed.
--		The padding may be added to either the start or the end.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 11/06/2003	CREDMAN	SQA8183		Function created
-- 
Begin
	Declare @sPadString nvarchar(100)
	Set @sPadString = @psPadString
	IF @pbStart = 1
	begin
		SELECT @sPadString=Replicate(@psPadding,@pnLength-len(@sPadString)) + @sPadString 
	end
	else
	begin
		SELECT @sPadString=@sPadString + Replicate(@psPadding, @pnLength-len(@sPadString)) 
	end
	return @sPadString
End
GO

grant execute on dbo.fn_GetPaddedString to public
go
