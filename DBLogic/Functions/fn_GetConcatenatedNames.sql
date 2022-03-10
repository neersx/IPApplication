-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedNames') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetConcatenatedNames.'
	drop function dbo.fn_GetConcatenatedNames
	print '**** Creating function dbo.fn_GetConcatenatedNames...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetConcatenatedNames
	(
		@pnCaseId		int,
		@psNameType		nvarchar(3),
		@psSeparator		nvarchar(10), 
		@pdtToday		datetime,
		@pnNameStyle		int
	)
Returns nvarchar(max)

-- FUNCTION :	fn_GetConcatenatedNames
-- VERSION :	7
-- DESCRIPTION:	This function accepts a CaseId and NameType and gets the formatted 
--		names and concatenates them with the Separator between each name.

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 24 Sep 2002	MF 			Function created
-- 23 Jun 2004	MF	1586	4	Simplify code by removing WHILE loop to make perform faster
-- 14 Apr 2011	MF	10475	5	Change nvarchar(4000) to nvarchar(max)
-- 02 Nov 2015	vql	53910	6	Adjust formatted names logic (DR-15543).
-- 10 Oct 2016	MF	69539	7	Cater for components that contain nulls and default the @psSeparator if one is not supplied.

AS
Begin
	-- Get the Item with the lowest value from the delimited string
	Declare @sFormattedNameList	nvarchar(max)
	
	----------------------------------------
	-- If no explicit value is supplied for
	-- @psSeparator, then default it to ';'.
	----------------------------------------
	If @psSeparator is null
		Set @psSeparator=';'

	Select @sFormattedNameList=CASE WHEN(@sFormattedNameList is not null) THEN @sFormattedNameList + @psSeparator ELSE '' END
	                          +dbo.fn_FormatNameUsingNameNo(N.NAMENO, @pnNameStyle) 
	From CASENAME CN
	Join NAME N on (N.NAMENO=CN.NAMENO)
	Where CN.CASEID  =@pnCaseId
	and   CN.NAMETYPE=@psNameType
	and  (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>@pdtToday)
	order by CN.SEQUENCE, CN.NAMENO

Return @sFormattedNameList
End
go

grant execute on dbo.fn_GetConcatenatedNames to public
GO
