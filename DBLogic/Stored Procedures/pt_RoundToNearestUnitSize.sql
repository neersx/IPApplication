-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_RoundToNearestUnitSize
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_RoundToNearestUnitSize]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_RoundToNearestUnitSize.'
	drop procedure dbo.pt_RoundToNearestUnitSize
	print '**** Creating procedure dbo.pt_RoundToNearestUnitSize...'
	print ''
end
go

create proc dbo.pt_RoundToNearestUnitSize 
			@pnUnroundedAmount	decimal(11,2),
			@pnUnitSize		smallint,
			@pnRoundedInteger	int	output
as

-- PROCEDURE :	pt_RoundToNearestUnitSize
-- VERSION :	2
-- DESCRIPTION:	A procedure to accept a number and a unit size and return a number that is 
--		rounded to the nearest unit.

-- MODIFICTIONS :
-- Date         Who  	Number	Version Change
-- ------------ ---- 	------	------- ------------------------------------------- 
-- 26 Feb 2002	MF		1	Procedure Created
-- 08 Mar 2006	MF		2	Minor changes to adhere to guidelines

set nocount on

declare @nRemainder	smallint
declare @ErrorCode	int

If @pnUnitSize=0
	Set @ErrorCode=-1
Else
	Set @ErrorCode=0


-- Perform an initial rounding of the amount to an integer
If  @ErrorCode=0
begin
	Set @pnRoundedInteger = Round(@pnUnroundedAmount,0)

	-- Perform a Modulus division to get the remainder of the amount divided by the Unit Size

	Set @nRemainder = @pnRoundedInteger % @pnUnitSize

	-- Subtract the remainder from the integer

	Set @pnRoundedInteger= @pnRoundedInteger-@nRemainder

	-- Now determine if rounding up or down is required.

	If ABS(convert(decimal(11,2),@nRemainder)/@pnUnitSize)>0.5
	begin
		If @pnRoundedInteger>0
			Set @pnRoundedInteger=@pnRoundedInteger+@pnUnitSize
		else If @pnRoundedInteger<0
			Set @pnRoundedInteger=@pnRoundedInteger-@pnUnitSize
	end
end

return (@ErrorCode)
go
	
grant execute on dbo.pt_RoundToNearestUnitSize to public
go
