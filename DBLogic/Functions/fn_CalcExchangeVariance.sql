-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_CalcExchangeVariance
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_CalcExchangeVariance') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_CalcExchangeVariance'
	Drop function [dbo].[fn_CalcExchangeVariance]
End
Print '**** Creating Function dbo.fn_CalcExchangeVariance...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_CalcExchangeVariance
(
	@pnLocalBalance		Decimal(11,2),
	@pnForeignBalance	Decimal(11,2),
	@pnItemExchRate		Decimal(11,4),
	@psItemCurrency		nvarchar(3),
	@pnAllocatedLocal	Decimal(11,2),
	@pnAllocatedForeign	Decimal(11,2),
	@pnAllocExchRate	Decimal(11,4),
	@psAllocatedCurrency	nvarchar(3),
	@pnForcedPayout		decimal(1,0)
) 
RETURNS Decimal (11,2)
AS
-- Function :	fn_CalcExchangeVariance
-- VERSION :	4
-- DESCRIPTION:	Return any exchange variance that may result from allocating the specified 
--		amount to the specified outstanding balance.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 NOV 2003	CR	8816	1.00	Function created
-- 09-Dec-2003	CR	8817	1.01	Fixed scenario where currencies are the same but
--					Exchange Rates
-- 15 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 19 Jul 2016	DL	R64233	3	SQL red hand error when producing a large payment of more than $9,999,999.99
-- 08 Sep 2017	MAF	72375	4	Increase the Exchange Rate fields to bring in line with the exchange rate fields on the Currency table

Begin

/*-- For Debugging
Declare @pnLocalBalance		Decimal(11,2),
	@pnForeignBalance	Decimal(11,2),
	@pnItemExchRate		Decimal(9,4),
	@psItemCurrency		nvarchar(3),
	@pnAllocatedLocal	Decimal(11,2),
	@pnAllocatedForeign	Decimal(11,2),
	@pnAllocExchRate	Decimal(9,4),
	@psAllocatedCurrency	nvarchar(3),
	@pnForcedPayout		decimal(1,0)

Set @pnLocalBalance = 884.09
Set @pnForeignBalance = 495.00
Set @pnItemExchRate	= .5599
Set @psItemCurrency	= 'USD'
Set @pnAllocatedLocal = 811.48
Set @pnAllocatedForeign = 495.00
Set @pnAllocExchRate = .6100
Set @psAllocatedCurrency = 'USD'
Set @pnForcedPayout = 0

*/

	declare @nResult 	Decimal (11,2),
		@nLocalAmount	Decimal	(11,2),
		@nForeignAmount	Decimal (11,2),
		@sCurrency	nvarchar(3),
		@nExchRate	Decimal (11,4),
		@sLocalCurrency	nvarchar(3),
		@nProportion	Decimal	(11,4)

	set @nResult = 0

	Select @sLocalCurrency = S.COLCHARACTER
	from SITECONTROL S
	where S.CONTROLID = 'CURRENCY'

	
	-- print 'Local Currency'
	-- Select @sLocalCurrency AS LOCALCURRENCY

	-- Logic extracted from dlgPaymentDissection.wfCalculateExchangeVariance()
	-- Call uOutAmount.cfSetInBaseOf( puAllocatedValue, puItemBalance )
	-- Set nExchangeVariance = (( uOutAmount.cfGetLocal() - puAllocatedValue.cfGetLocal() ) * -1)
	-- Return nExchangeVariance

/*-- For Debugging
	Select @sLocalCurrency AS LOCALCURRENCY, @pnLocalBalance AS LOCALBALANCE, @pnForeignBalance AS FOREIGNBALANCE,
	@pnItemExchRate AS ITEMEXCHRATE, @psItemCurrency AS ITEMCURRENCY, @pnAllocatedLocal  AS ALLOCATEDLOCAL, 
	@pnAllocatedForeign  AS ALLOCATEDFOREIGN, @pnAllocExchRate AS ALLOCEXCHRATE, @psAllocatedCurrency AS ALLOCATEDCURRENCY
	
*/
	-- cfSetInBaseOf
	-- cfIsSameBase()
	If (@psItemCurrency = @psAllocatedCurrency) AND (@pnItemExchRate = @pnAllocExchRate)
	Begin
		-- Print 'The allocated value is the same currency and exchange rate as the item'
		
		Set @nLocalAmount = @pnAllocatedLocal
		Set @nForeignAmount = @pnAllocatedForeign
		Set @nExchRate = @pnAllocExchRate
		Set @sCurrency = @psAllocatedCurrency

		If (((@psAllocatedCurrency IS NOT NULL) AND (@psAllocatedCurrency <> @sLocalCurrency)) AND
			( ABS( @pnAllocatedForeign ) = ABS( @pnForeignBalance ) ) )
		Begin

			-- Print 'The Foreign allocated value = the foreign item balance'

			-- It is possible that because of rounding errors, two amounts with the
			-- same exchange rate and foreign value, may have slightly different
			-- local values.  Use the puOfAmount local value and force an
			-- exchange gain/loss for the rounding error
			If ( ABS( @pnAllocatedLocal ) <> ABS( @pnLocalBalance ) )
			Begin
				If ( @pnAllocatedForeign < 0 )
				Begin
					Set @nLocalAmount = ABS( @pnLocalBalance ) * -1
				End
				Else
				Begin
					Set @nLocalAmount = ABS( @pnLocalBalance )
				End
				
				-- For Debugging
				-- print 'local allocated value DOES NOT EQUAL the local item balance'
				-- Select @nLocalAmount AS LOCALAMOUNT

			End
		End
	End
	Else
	Begin
		Set @nLocalAmount = @pnLocalBalance
		Set @nForeignAmount = @pnForeignBalance
		Set @nExchRate = @pnItemExchRate
		Set @sCurrency = @psItemCurrency

		If (@psItemCurrency IS NULL) OR (@psItemCurrency = @sLocalCurrency)
		Begin
			-- For Debugging
			-- Print 'Item is local'
			-- Select @psItemCurrency as ITEMCURRENCY, @sLocalCurrency AS LOCALCURRENCY
			
			Set @nLocalAmount = @pnAllocatedLocal
		End
		Else
		Begin
			-- For Debugging
			-- Print 'Same currency, but different exchange rates'
			
			If (@psItemCurrency = @psAllocatedCurrency)
			Begin
				Set @nForeignAmount = @pnAllocatedForeign
				If ABS( @nForeignAmount ) > ABS( @pnForeignBalance )
				Begin
					Set @nLocalAmount= ( convert(decimal(11,2), @nForeignAmount) /  @nExchRate )
					
					-- For Debugging
					-- print 'derive local'
					-- Select @nLocalAmount AS LOCALAMOUNT
				End
				Else
				Begin
					-- For Debugging	
					-- print 'Calculate the local value as a proportion, if possible, to avoid rounding errors'
					
					If (@pnLocalBalance = 0)
					Begin
						Set @nLocalAmount = ( convert(decimal(11,2), @nForeignAmount) /  @nExchRate )

						-- For Debugging
						-- print 'All of local balance consumed - derive local'
						-- Select @nLocalAmount AS LOCALAMOUNT

					End
					Else
					Begin
						Set @nProportion = @pnAllocatedForeign / @pnForeignBalance
						Set @nLocalAmount = @pnLocalBalance * @nProportion

						-- For Debugging
						-- print 'Only part of local balance consumed'
						-- Select @nLocalAmount AS LOCALAMOUNT, @nProportion AS PROPORTION
					End
				End
			End
			Else
			Begin
				-- For Debugging		
				-- Print 'Different currencies, so use the local as the conversion basis'

				Set @nLocalAmount = @pnAllocatedLocal
				If ABS( @nLocalAmount ) > ABS( @pnLocalBalance )
				Begin
					If ((@psAllocatedCurrency IS NOT NULL) AND (@psAllocatedCurrency <> @sLocalCurrency))
					Begin
						Set @nForeignAmount = ( convert(decimal(11,2), @nLocalAmount) /@nExchRate )
					End
					Else
					Begin
						Set @nForeignAmount = NULL
					End
					-- For Debugging
					-- print 'Not all of Local Balance will be consumed'
					-- print 'Derive Foreign'
					-- Select @nForeignAmount AS FOREIGNAMOUNT
				End
				Else
				Begin
					If (@pnLocalBalance = 0)
					Begin
						If ((@psAllocatedCurrency IS NOT NULL) AND (@psAllocatedCurrency <> @sLocalCurrency))
						Begin
							Set @nForeignAmount = ( convert(decimal(11,2), @nLocalAmount) /@nExchRate )
						End
						Else
						Begin
							Set @nForeignAmount = NULL
						End
						
						-- For Debugging
						-- print 'All of Local Balance will be consumed'
						-- print 'Derive Foreign'
						-- Select @nForeignAmount AS FOREIGNAMOUNT
					End
					Else
					Begin
						Set @nProportion = @pnAllocatedLocal / @pnLocalBalance
						Set @nForeignAmount = @pnForeignBalance * @nProportion
						
						-- For Debugging
						-- print 'Calculate foreign amount proportionally'
						-- Select @nForeignAmount AS FOREIGNAMOUNT
					End
				End
			End
		End
	End



	-- Set nExchangeVariance = (( uOutAmount.cfGetLocal() - puAllocatedValue.cfGetLocal() ) * -1)	
	-- * -1 for display purposes
	Set @nResult = ((@nLocalAmount - @pnAllocatedLocal ))
 
	-- For Debugging
	-- print 'Exchange Variance calculated'
	-- Select @nResult	

	return @nResult
End
GO

grant execute on dbo.fn_CalcExchangeVariance to public
go


-- Logic yet to be implemented as it is not required at this stage
/*
	-- Calculate variance as a result of Forced Payout
	if (@pnForcedPayout = 1)
	Begin
		-- Call uDifference.cfCopy( puItemBalance )
		Set @nLocalAmount = @pnLocalBalance
		Set @nForeignAmount = @pnForeignBalance
		Set @nExchRate = @pnItemExchRate
		Set @sCurrency = @psItemCurrency

		-- Call uDifference.cfMinus( puAllocatedValue )
		Set @nLocalAmount = @pnLocalBalance * -1
		Set @nForeignAmount = @pnForeignBalance	* -1	

		-- cfPlus
		If (@sCurrency IS NULL) OR (@sCurrency <> @sLocalCurrency)
			Set @nLocalAmount = @nLocalAmount + @pnAllocatedLocal
		Else
			If @sCurrency  = @psAllocatedCurrency
				If @nExchRate = @pnAllocExchRate
					-- __cfPlusSameAsBase(puAmount)
					Set @nLocalAmount = @nLocalAmount + @pnAllocatedLocal
					Set @nForeignAmount = @nForeignAmount + @pnAllocatedForeign
				Else
				Begin
					-- __cfPlusForeignBase(puAmount)	
					Set nOldLocalAmount = cfGetLocal()
					If cfGetForeign() = 0
					Begin
						Call cfSetForeign(  puAmount.cfGetForeign() )
						Call cfDeriveLocal( )
						Set anVarianceAmount = puAmount.cfGetLocal() - cfGetLocal()
					End
					Else
					Begin
						Set nProportion = ( cfGetForeign() +  puAmount.cfGetForeign() ) / cfGetForeign()
						Call cfSetLocal( cfGetLocal() * nProportion )
						Set anVarianceAmount = ( puAmount.cfGetLocal() - cfGetLocal() ) + nOldLocalAmount
						Call cfSetForeign( cfGetForeign() + puAmount.cfGetForeign( ) )
					End
				End
	
			Else
			Begin
					-- __cfPlusLocalBase(puAmount)
					Call cfSetLocal( cfGetLocal() + puAmount.cfGetLocal( ) )
					If cfIsForeign( )
						Call cfSetForeign( cfGetForeign() + puAmount.cfGetForeign( ) )
					Set anVarianceAmount = 0
			End



		-- __cfPlusLocalBase
				Call cfSetLocal(  cfGetLocal() + puAmount.cfGetLocal( ) )
				Set anVarianceAmount = 0
				Call cfDeriveForeign( )
		

		-- __cfPlusForeignBase
				Set nOldLocalAmount = cfGetLocal()
				If cfGetForeign() = 0
					Call cfSetForeign(  puAmount.cfGetForeign() )
					Call cfDeriveLocal( )
					Set anVarianceAmount = puAmount.cfGetLocal() - cfGetLocal()
				Else
					Set nProportion = ( cfGetForeign() +  puAmount.cfGetForeign() ) / cfGetForeign()
					Call cfSetLocal( cfGetLocal() * nProportion )
					Set anVarianceAmount = ( puAmount.cfGetLocal() - cfGetLocal() ) + nOldLocalAmount
					Call cfSetForeign( cfGetForeign() + puAmount.cfGetForeign( ) )

		-- __cfPlusSameBase
				Call cfSetLocal( cfGetLocal() + puAmount.cfGetLocal( ) )
				If cfIsForeign( )
					Call cfSetForeign( cfGetForeign() + puAmount.cfGetForeign( ) )
				Set anVarianceAmount = 0

		-- Set nExchangeVariance = ( uDifference.cfGetLocal() * -1 )

		Set @Result = @nResult + ( @nLocalAmount * -1 )
	End
*/
