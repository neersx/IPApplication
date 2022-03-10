-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedNameKeys
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedNameKeys') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetConcatenatedNameKeys.'
	drop function dbo.fn_GetConcatenatedNameKeys
	print '**** Creating function dbo.fn_GetConcatenatedNameKeys...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetConcatenatedNameKeys
	(
		@pnCaseId		int,
		@psNameType		nvarchar(3),
		@psSeparator		nvarchar(10), 
		@pdtToday		datetime
	)
Returns nvarchar(max)

-- FUNCTION :	fn_GetConcatenatedNameKeys
-- VERSION :	2
-- DESCRIPTION:	This function accepts a CaseId and NameType and gets all name keys and concatenates them with the Separator between each name.

-- Date		Who	Number	Version	Description
-- ====         	===	======	=======	===========
-- 15 July 2008	SF	RFC576	1	Function created.
-- 14 Apr 2011	MF	RFC10475 2	Change nvarchar(4000) to nvarchar(max)
AS
Begin
	-- Get the Item with the lowest value from the delimited string
	Declare @sFormattedNameList	nvarchar(max)


	Select @sFormattedNameList=nullif(@sFormattedNameList+@psSeparator, @psSeparator)+
					cast(CN.NAMENO as nvarchar(15))
	From CASENAME CN
	Where CN.CASEID  =@pnCaseId
	and   CN.NAMETYPE=@psNameType
	and  (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>@pdtToday)
	order by CN.SEQUENCE, CN.NAMENO

Return @sFormattedNameList
End
go

grant execute on dbo.fn_GetConcatenatedNameKeys to public
GO
