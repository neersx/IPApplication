-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_NumericToDate
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_NumericToDate]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop Function dbo.fn_NumericToDate.'
	drop function [dbo].[fn_NumericToDate]
	print '**** Creating Function dbo.fn_NumericToDate...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_NumericToDate
	(	
		@pnNumberToConvert	decimal(7,0)
	)
Returns Datetime

-- FUNCTION :	fn_NumericToDate
-- VERSION :	1
-- DESCRIPTION:	Returns the date converted from a 7 digit numeric
--		Format of numeric is :
--			CYYMMDD
--		Where C is :
--			0 = 1900
--			1 = 2000
--		Negative numbers :
--			Century = 1800
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 15 Feb 2005	MF		1	Function created

as
Begin

	Declare @dtWorkDate	datetime,
		@sCharDate 	varchar(12),
		@Century	smallint,
		@Year 		smallint,
		@Month 		smallint,
		@Day 		smallint

	-- Use the modulo operator (%) to get the components of the date
	-- The Modulo operator returns the Remainder after division by the number
	If @pnNumberToConvert<0
		SELECT 	@Year  = CONVERT(VARCHAR(2), (CONVERT(int,@pnNumberToConvert*-1) % 1000000 
		                        - CONVERT(int,@pnNumberToConvert*-1) % 10000) / 10000),
			@Month = CONVERT(VARCHAR(2), (CONVERT(int,@pnNumberToConvert*-1) % 10000 
		                        - CONVERT(int,@pnNumberToConvert*-1) % 100) / 100),
			@Day   = CONVERT(VARCHAR(2), CONVERT(int,@pnNumberToConvert*-1) % 100)
	Else
		SELECT 	@Century=CONVERT(VARCHAR(2), (CONVERT(int,@pnNumberToConvert) % 10000000 
		                        - CONVERT(int,@pnNumberToConvert) % 1000000) / 1000000),
			@Year  = CONVERT(VARCHAR(2), (CONVERT(int,@pnNumberToConvert) % 1000000 
		                        - CONVERT(int,@pnNumberToConvert) % 10000) / 10000),
			@Month = CONVERT(VARCHAR(2), (CONVERT(int,@pnNumberToConvert) % 10000 
		                        - CONVERT(int,@pnNumberToConvert) % 100) / 100),
			@Day   = CONVERT(VARCHAR(2), CONVERT(int,@pnNumberToConvert) % 100)

	-- Now add the Century onto the Year.
	SET @Year = @Year + CASE WHEN(@pnNumberToConvert<0) THEN 1800 
			 	 WHEN(@Century=1)	    THEN 2000
							    ELSE 1900 
			    END

	-- Now Reconstruct the full date
	IF  @Month between 0 and 12
	and @Day  between 1 and 31
	and @Year between 1800 and 2099
	Begin
		SET @sCharDate = CONVERT(CHAR(4), @Year) + '-'
				+ RIGHT('00' + CONVERT(VARCHAR(2), @Month), 2) + '-'
				+ RIGHT('00' + CONVERT(VARCHAR(2), @Day), 2)
	End
	
	If ISDATE(@sCharDate)=0 
		RETURN NULL

	RETURN CONVERT(datetime, @sCharDate, 120)
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_NumericToDate to public
GO
