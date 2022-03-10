-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ConvertToPctShortFormat
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ConvertToPctShortFormat') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_ConvertToPctShortFormat'
	Drop function [dbo].[fn_ConvertToPctShortFormat]
End
Print '**** Creating Function dbo.fn_ConvertToPctShortFormat...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_ConvertToPctShortFormat
(
	@psPctLongFormat	nvarchar(max)
) 
RETURNS nvarchar(max)
AS
-- Function :	fn_ConvertToPctShortFormat
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the passed long format PCT number in short format

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Jun 2015  R47863	JD	1	Converts Pct long format to short format 
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
