If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_ConvertIntToString]') and xtype = 'FN')
Begin
	Print '**** Drop Stored Procedure dbo.fn_ConvertIntToString.'
	Drop function [dbo].[fn_ConvertIntToString]
End
Print '**** Creating Stored Procedure dbo.fn_ConvertIntToString...'
Print ''
GO

CREATE FUNCTION [dbo].[fn_ConvertIntToString]
(
	@psIntValue	int
)
RETURNS nvarchar(max)

-- FUNCTION	 :	fn_ConvertIntToString
-- VERSION 	 :	1
-- DESCRIPTION	: Converts Int to nchar(11)
-- IMPORTANT	: This function is used extensively in Inprotech Web Applications to get string value of int.
-- MODIFICATIONS :
-- Date		SQA	Who	Version	Change
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- 14 Oct 2019  DR42724	KT	1	Function Created
AS
Begin

	DECLARE @result nchar(11)
	SET @result = CONVERT(nchar(11), @psIntValue)

	Return @result
End
GO

grant execute on dbo.fn_ConvertIntToString to public
go