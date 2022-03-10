-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ap_ConvertNumberToPoundsWords stored procedure
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from sysobjects where id = object_id(N'[dbo].[ap_ConvertNumberToPoundsWords]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ap_ConvertNumberToPoundsWords.'
	drop procedure dbo.ap_ConvertNumberToPoundsWords
End
print '**** Creating procedure dbo.ap_ConvertNumberToPoundsWords...'
print ''
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ap_ConvertNumberToPoundsWords
( 
	@pnUserIdentityId int = null,
	@psCulture nvarchar(10) = null,
	@pbCalledFromCentura tinyint = 0,
	@pnMyNumber decimal(16, 2),
	@psDollarWords nvarchar(254) = null OUTPUT 
)
AS
-- PROCEDURE :	ap_ConvertNumberToPoundsWords
-- VERSION :	1
-- DESCRIPTION:	Convert a number with 2 decimal places to dollar amount in English.
-- CALLED BY :	
-- COPYRIGHT: 	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 21/06/2005	MB	11183	1	Procedure created based on ap_ConvertNumberToDollarWords


BEGIN
	declare @sMyNumberInStr nvarchar(20),
		@nDecimalPlace tinyint,
		@sCents nvarchar(24)
					
	set @sMyNumberInStr = N'' -- Initialise string variables b4 use.
	set @sCents = N''
		
	set @sMyNumberInStr = LTRIM(RTRIM(STR(@pnMyNumber, 19, 2)))
	set @nDecimalPlace = CHARINDEX(N'.', @sMyNumberInStr)
	if @nDecimalPlace > 0
	    begin
		set @sCents = dbo.fn_GetTens(LEFT(SUBSTRING(@sMyNumberInStr, @nDecimalPlace + 1, 2) + N'00', 2))
		set @sMyNumberInStr = LTRIM(RTRIM(LEFT(@sMyNumberInStr, @nDecimalPlace - 1)))
	    end
	
	declare @nCount smallint,
		@sDollars nvarchar(210),
		@sTemp nvarchar(27)

	set @sDollars = N''
	set @sTemp = N''
	set @nCount = 1

	while @sMyNumberInStr <> N''
	    begin
		set @sTemp = dbo.fn_GetHundreds(RIGHT(@sMyNumberInStr, 3))
		if @sTemp <> N''
			set @sDollars = @sTemp + dbo.fn_GetPlace(@nCount) + @sDollars
		if LEN(@sMyNumberInStr) > 3
			set @sMyNumberInStr = LEFT(@sMyNumberInStr, LEN(@sMyNumberInStr)-3)
		else
			set @sMyNumberInStr = N''
			
		set @nCount = @nCount + 1
	    end
		
	if @sDollars = N''
		set @sDollars = N'Zero Pounds'
	else if @sDollars = N'One'
		set @sDollars = N'One Pound'
	else 
		set @sDollars = @sDollars + N' Pounds'
	
	if @sCents = N''
		set @sCents = N' and Zero Pence'
	else if @sCents = N'One'
		set @sCents = N' and One Penny'
	else
		set @sCents = N' and ' + @sCents + N' Pence'
	
	set @psDollarWords = @sDollars + @sCents
	set @psDollarWords = REPLACE(@psDollarWords, N'  ', N' ')
	
	if @pbCalledFromCentura = 1
		select @psDollarWords
	
	Return 0
End

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ap_ConvertNumberToPoundsWords to public
go
