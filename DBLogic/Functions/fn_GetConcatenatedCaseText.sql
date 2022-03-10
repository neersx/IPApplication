-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedCaseText
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedCaseText') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetConcatenatedCaseText.'
	drop function dbo.fn_GetConcatenatedCaseText
	print '**** Creating function dbo.fn_GetConcatenatedCaseText...'
	print ''
end
go

SET ANSI_NULLS ON 
go
set QUOTED_IDENTIFIER off
go

CREATE FUNCTION dbo.fn_GetConcatenatedCaseText
	(
		@pnCaseId		int,			-- The CaseId to be reported on
		@psTextType		nvarchar(2),		-- The text type to retrieve
		@psSeparator		nvarchar(254)		-- Separator between text
	)
Returns nvarchar(3905)

-- FUNCTION :	fn_GetConcatenatedCaseText
-- VERSION :	5
-- DESCRIPTION:	This function accepts a CaseId and a Text Type and returns all
--		case text of that text time in one text string (up to 3905 chars).
--		Note: Cases returns an error if more than 3906 characters are returned.

-- Date		Who	Number		Version	Description
-- ====         ===	======		=======	===========
-- 10 Jan 2007	AT	SQA12744	1	Function Created.
-- 23 Jan 2007	MF	SQA12744	2	Allow separator to be passed as parameter.
-- 24 Jan 2007	AT	SQA12744	3	Fixed bugs.
-- 15 Dec 2008	MF	17136		4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 14 Apr 2011	MF	10475		5	Change nvarchar(4000) to nvarchar(max)
AS
Begin

	Declare @sAllCaseText	nvarchar(3905)

	Set @sAllCaseText = ''
	If @psSeparator is null
	Begin
		Select @psSeparator = COLCHARACTER 
		from SITECONTROL 
		where CONTROLID = 'Default Delimiter'
	End

	Select @sAllCaseText = @sAllCaseText +	Case When LONGFLAG = 0 
							Then ISNULL(SHORTTEXT,'')
							Else ISNULL(Cast(TEXT As nvarchar(max)),'') 
					  	End
				+ @psSeparator
	From  CASETEXT
	Where CASEID = @pnCaseId AND TEXTTYPE = @psTextType
	Order By TEXTNO

	-- If the string is >= the maximum, replace the last 5 chars with '.....'
	If ( len(@sAllCaseText) >= 3905 )
		Begin
			select @sAllCaseText = left(@sAllCaseText, 3900) + '.....'
		End
	Else
		Begin
			If len(@sAllCaseText) > 0
				Begin
					-- Remove the trailing delimiter
					select @sAllCaseText = left(@sAllCaseText, len(@sAllCaseText) - len(@psSeparator))
				End
		End

Return @sAllCaseText
End
go

grant execute on dbo.fn_GetConcatenatedCaseText to public
GO




