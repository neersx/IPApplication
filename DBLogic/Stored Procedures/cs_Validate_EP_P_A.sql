-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_Validate_EP_P_A
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_Validate_EP_P_A]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_Validate_EP_P_A.'
	drop procedure dbo.cs_Validate_EP_P_A
	print '**** Creating procedure dbo.cs_Validate_EP_P_A...'
	print ''
end
go

set QUOTED_IDENTIFIER off
GO

create proc dbo.cs_Validate_EP_P_A
		@psOfficialNumber 	nvarchar(36),			-- the Official Number to be validated
		@psErrorMessage		nvarchar(254)=null 	OUTPUT,	-- Optional error message
		@pnWarningFlag		tinyint=null		OUTPUT,	-- Optional flag to indicate a Warning
		@psValidOfficialNumber	nvarchar(36)=null	OUTPUT	-- the modified Official Number that is now valid
as
-- PROCEDURE :	cs_Validate_EP_P_A
-- VERSION :	3
-- DESCRIPTION:	A specific validation of European Patent Application Number
-- CALLED BY :	cs_ValidateOfficialNumber

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 30 Jul 2003	MF	 	1	Procedure created
-- 17 MAR 2004	abell			Fix up grant exec statement
-- 01 JUN 2004	MF	10120	2	Transform a check digit calculated as 10 into 0
-- 06 APR 2005	MF	8748	3	If the validated form of the official number can be determined
--					then return it.

Declare @ErrorCode		int
Declare	@nDecimalPos		tinyint
Declare @nPos			tinyint
Declare	@nProduct		tinyint
Declare @nNoOfDigits		tinyint
Declare @nTotalDigits		smallint
Declare @sUserCheckDigit	char(1)
Declare @sCheckDigit		char(1)
Declare	@sDigits		nvarchar(36)
Declare @sReceivedNumber	nvarchar(36)

Set @ErrorCode=0

-- European Application Number
-- Consists of 8 digits plus a checkdigit, example :
--		12345678.9 OR 12 345 678.9
-- The check digit algorithm is as follows :
-- (i)	Each digit of the base is multiplied from right to left 2,1,2,1,.. respectively.
-- (ii)	The separate digits of the product are added together
-- (iii)The sum is divided by 10
-- (iv)	The remainder is subtracted from 10 giving the checkdigit
--
-- At the substantive examination stage the EPO allocates a further four digit number
-- to the application number, example :
--		12345678.9-1234
-- NOTE : If the check digit is not included in the number to be validated then
--        return the calculated Checkdigit in the Error Message as a Warning only.

-- Save the number as it is originally received 
Set @sReceivedNumber=@psOfficialNumber

-- Find the digits to the left of the decimal point

Set @psOfficialNumber=replace(@psOfficialNumber,' ','')

Set @nDecimalPos=charindex('.',@psOfficialNumber)

-- Split the Official Number into the Checkdigit and the Digits used to calculate the Checkdigit 

If @nDecimalPos>0
Begin
	-- Save the entered check digit which is located in the position immediately following the decimal
	Set @sUserCheckDigit=substring(@psOfficialNumber,@nDecimalPos+1,1)

	-- Save the digits to the left of the decimal place
	-- Reverse the order of the string so we can effectively work from right to left
	Set @sDigits=reverse(left(@psOfficialNumber,@nDecimalPos-1))
End
Else Begin
	-- If no decimal point then use the entire Official Number to calculate the check digit
	Set @sDigits=reverse(@psOfficialNumber)
End

-- Reject where non numerics exist
If isnumeric(@sDigits)=0
Begin
	Set @psErrorMessage='Non numeric digits in Application Number.  Cannot calculate check digit'
	Set @ErrorCode=1
End
Else Begin
	-- Loop through each of the individual digits and multiply alternatively by 2 then 1
	-- and then add the separate digits of the resulting number
	Set @nPos=1
	Set @nTotalDigits=0
	Set @nNoOfDigits=len(@sDigits) -- Use the "len" function because of double byte nvarchar

	While @nPos<=@nNoOfDigits
	Begin
		-- The Product is found by multiplying each digit by 2 or 1
		-- @nPos%2 will return a value of 0 if @nPos is divisible by 2 otherwise 1
		Set @nProduct=cast(substring(@sDigits,@nPos,1) as tinyint) * (1+@nPos%2)

		-- Now sum the separate digits of the product and keep a running total
		Set @nTotalDigits=@nTotalDigits
				+(@nProduct%10)	-- Mod 10 will give the number of units
				+(@nProduct/10)	-- Because of rounding this will give the number of 10s
		
		-- Increment the position
		Set @nPos=@nPos+1
	End

	-- Now divide the TotalDigits by 10 and subtract the remainder from the 10 to get the Check Digit
	-- Reversing the result and taking the first digit will transform a calculated
	 -- check digit to 0
	 Set @sCheckDigit=left(reverse(cast(10-(@nTotalDigits%10) as varchar(2))),1)

	-- If the user did not supply a check digit then return a Warning with the check digit in the message
	If isnumeric(@sUserCheckDigit)=0
	Begin
		Set @ErrorCode=1
	
		Set @pnWarningFlag=1

		-- reconstruct the Offical Number with the check digit in place by stripping
		-- out the full period separator(if it exists) then reinserting it followed
		-- by the check digit.
		Set @psValidOfficialNumber=replace(@sReceivedNumber,'.','')+'.'+@sCheckDigit

		Set @psErrorMessage=	'No Check Digit found on entered Application No.'+char(10)+
					'System calculated Check Digit is : '+@sCheckDigit+char(10)+
					'You can enter a check digit after a decimal point, eg '+reverse(@sDigits)+'.'+@sCheckDigit
	End
	Else If @sUserCheckDigit<> @sCheckDigit
	Begin
		Set @ErrorCode=1
	
		Set @psErrorMessage=	'Entered Check Digit does not match calculated Check Digit'+char(10)+
					'Check digit entered on the Application No:'+@sUserCheckDigit+char(10)+
					'System calculated Check Digit:            '+@sCheckDigit
	End
	
End

Return @ErrorCode
go

grant execute on dbo.cs_Validate_EP_P_A to public
go
