If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_ConvertToPctShortFormat]') and xtype = 'FN')
Begin
	Print '**** Drop Stored Procedure dbo.fn_ConvertToPctShortFormat.'
	Drop function [dbo].[fn_ConvertToPctShortFormat]
End
Print '**** Creating Stored Procedure dbo.fn_ConvertToPctShortFormat...'
Print ''
GO

CREATE FUNCTION [dbo].[fn_ConvertToPctShortFormat]
(
	@psPctLongFormat	nvarchar(max)
)
RETURNS nvarchar(max)

-- FUNCTION	 :	fn_ConvertToPctShortFormat
-- VERSION 	 :	1
-- DESCRIPTION	: Returns the passed long format PCT number in short format
-- IMPORTANT	: This function is used extensively in Inprotech Web Applications to resolve PCT cases from USPTO Private PAIR.
--                Changes made to this function should consider impact in Apps as Apps deploy this same function at installation time.
-- MODIFICATIONS :
-- Date		SQA	Who	Version	Change
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- 22 Jun 2015  R47863	JD	1	Converts Pct long format to short format 

AS
Begin
	Set @psPctLongFormat = REPLACE(@psPctLongFormat, ' ', '')

	If(LEN(@psPctLongFormat) = 17)
	Begin
		Declare @sPctShortFormat	nvarchar(14)
		Declare @sPCT			nvarchar(4)
		Declare @sCountryCode		nvarchar(2)
		Declare @sYear			nvarchar(4)
		Declare @sSequenceNumber	nvarchar(6)
		Declare @sDivider		nvarchar(1)

		Select @sPCT = SUBSTRING(@psPctLongFormat, 1, 4) 
		Select @sCountryCode = SUBSTRING(@psPctLongFormat, 5, 2)
		Select @sYear = SUBSTRING(@psPctLongFormat, 8, 4)
		Select @sDivider = SUBSTRING(@psPctLongFormat, 11, 1)
		Select @sSequenceNumber = SUBSTRING(@psPctLongFormat, 12, 6)

		Set @sPctShortFormat = ''
		If (@sPCT = 'PCT/' AND @sDivider = '/' AND SUBSTRING(@sSequenceNumber, 1, 1) = '0')
		Begin
			Select @sPctShortFormat = @sPCT + @sCountryCode + SUBSTRING(@sYear, 2, 2) + @sDivider + SUBSTRING(@sSequenceNumber, 2, 5)
		End

		RETURN @sPctShortFormat
	End
	Return ''
End
GO

grant execute on dbo.fn_ConvertToPctShortFormat to public
go