-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_StringOccurrenceCount
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_StringOccurrenceCount') and xtype='FN')
begin
	print '**** Drop function dbo.fn_StringOccurrenceCount.'
	drop function dbo.fn_StringOccurrenceCount
	print '**** Creating function dbo.fn_StringOccurrenceCount...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_StringOccurrenceCount  
	(	@psSearchFor 		nvarchar(max), 
		@psSearchInString	nvarchar(max)
	)
Returns smallint

-- FUNCTION :	fn_StringOccurrenceCount
-- VERSION :	2
-- DESCRIPTION:	This function returns the number of occurrences of a string 
--		within another string.

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 06 Oct 2006	MF 	12413	1	Function created
-- 14 Apr 2011	MF	10475	2	Change nvarchar(4000) to nvarchar(max)
as
begin
declare @nStartFrom	smallint
declare	@nStringCount	smallint


Set @nStringCount = 0
Set @nStartFrom = charindex(@psSearchFor, @psSearchInString)

While @nStartFrom > 0
	select  @nStringCount = @nStringCount + 1,  
		@nStartFrom   = charindex(@psSearchFor, @psSearchInString, @nStartFrom+1)

return  @nStringCount
end

go

grant execute on dbo.fn_StringOccurrenceCount to public
GO
