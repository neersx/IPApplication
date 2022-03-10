-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_SplitTextOnCarriageReturn
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_SplitTextOnCarriageReturn') and xtype='FN')
begin
	print '**** Drop function dbo.fn_SplitTextOnCarriageReturn.'
	drop function dbo.fn_SplitTextOnCarriageReturn
end
print '**** Creating function dbo.fn_SplitTextOnCarriageReturn...'
print ''
go

Create Function dbo.fn_SplitTextOnCarriageReturn
			(
			@sInputString	nvarchar(max),
			@nLineNo	smallint	-- The line number to return
			)
Returns nvarchar(max)
as
-- FUNCTION :	fn_SplitTextOnCarriageReturn
-- VERSION :	2
-- DESCRIPTION:	Splits an input string up using the carriage return as an end of line marker
--		and returns the requested line.
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 18Jan2001	MF			Author
-- 14 Apr 2011	MF	RFC10475 2	Change nvarchar(4000) to nvarchar(max)

Begin
	declare @nCounter	smallint

	set	@nCounter	=1

	-- loop until each unrequired line has been removed from the input string.

	WHILE @nCounter < @nLineNo
	and   @sInputString is not null
	BEGIN
		if charindex(CHAR(13), @sInputString)=0
		 	set @sInputString=null
		else	
			set @sInputString=substring(@sInputString, CHARINDEX(CHAR(13),@sInputString)+2, datalength(@sInputString))
	
		set @nCounter=@nCounter+1
	END

	-- Now return the string from the begining of the remaining string up to the next
	-- carriage return if one exists otherwise return the entire string

	if charindex(CHAR(13), @sInputString)>0
		Return substring(@sInputString,1, CHARINDEX(CHAR(13),@sInputString)-1)

	Return @sInputString
End
go

GRANT execute ON dbo.fn_SplitTextOnCarriageReturn to PUBLIC
go
