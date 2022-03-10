-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedNameVariants
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedNameVariants') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetConcatenatedNameVariants.'
	drop function dbo.fn_GetConcatenatedNameVariants
	print '**** Creating function dbo.fn_GetConcatenatedNameVariants...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetConcatenatedNameVariants
	(
		@pnCaseId		int,
		@psNameType		nvarchar(3),
		@psSeparator		nvarchar(10), 
		@pdtToday		datetime,
		@pnNameStyle		int
	)
Returns nvarchar(max)

-- FUNCTION :	fn_GetConcatenatedNameVariants
-- VERSION :	2
-- DESCRIPTION:	This function accepts a CaseId and NameType and gets the formatted 
--		names and concatenates them with the Separator between each name.

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 15 Nov 2005	MF 		1	Function created
-- 14 Apr 2011	MF	RFC10475 2	Change nvarchar(4000) to nvarchar(max)

AS
Begin
	-- Get the Item with the lowest value from the delimited string
	Declare @sFormattedNameList	nvarchar(max)


	Select @sFormattedNameList=nullif(@sFormattedNameList+@psSeparator, @psSeparator)+
					dbo.fn_FormatName(N.NAMEVARIANT, N.FIRSTNAMEVARIANT, NULL, @pnNameStyle) 
	From CASENAME CN
	Join NAMEVARIANT N on (N.NAMENO=CN.NAMENO
			   and N.NAMEVARIANTNO=CN.NAMEVARIANTNO)
	Where CN.CASEID  =@pnCaseId
	and   CN.NAMETYPE=@psNameType
	and  (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>@pdtToday)
	order by CN.SEQUENCE, CN.NAMENO

Return @sFormattedNameList
End
go

grant execute on dbo.fn_GetConcatenatedNameVariants to public
GO
