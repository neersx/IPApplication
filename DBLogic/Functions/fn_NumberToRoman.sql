-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_NumberToRoman
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_NumberToRoman') and xtype='FN')
begin
	print '**** Drop function dbo.fn_NumberToRoman.'
	drop function dbo.fn_NumberToRoman
	print '**** Creating function dbo.fn_NumberToRoman...'
	print ''
end
go

set QUOTED_IDENTIFIER off
go

Create Function  dbo.fn_NumberToRoman
(
  @pnNumber	tinyint
)
Returns nvarchar(12)
-- FUNCTION: fn_NumberToRoman
-- VERSION: 1
-- DESCRIPTION: Converts a numeric  between 1 and 99 to a Roman Numeral equivalent.
-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 23-Sep-2004  MF 	10297	1 	Function created

as
Begin

Declare @psRomanNumeral		nvarchar(12)

-- Calculate a distinct and repeatable numeric value for the supplied string and then 
-- convert that to a single character derived as check digit.

Set @psRomanNumeral =	CASE(@pnNumber)
				WHEN(1)  THEN 'I'
				WHEN(2)  THEN 'II'
				WHEN(3)  THEN 'III'
				WHEN(4)  THEN 'IV'
				WHEN(5)  THEN 'V'
				WHEN(6)  THEN 'VI'
				WHEN(7)  THEN 'VII'
				WHEN(8)  THEN 'VIII'
				WHEN(9)  THEN 'IX'
				WHEN(10) THEN 'X'
				WHEN(11) THEN 'XI'
				WHEN(12) THEN 'XII'
				WHEN(13) THEN 'XIII'
				WHEN(14) THEN 'XIV'
				WHEN(15) THEN 'XV'
				WHEN(16) THEN 'XVI'
				WHEN(17) THEN 'XVII'
				WHEN(18) THEN 'XVIII'
				WHEN(19) THEN 'XIX'
				WHEN(20) THEN 'XX'
				WHEN(21) THEN 'XXI'
				WHEN(22) THEN 'XXII'
				WHEN(23) THEN 'XXIII'
				WHEN(24) THEN 'XXIV'
				WHEN(25) THEN 'XXV'
				WHEN(26) THEN 'XXVI'
				WHEN(27) THEN 'XXVII'
				WHEN(28) THEN 'XXVIII'
				WHEN(29) THEN 'XXIX'
				WHEN(30) THEN 'XXX'
				WHEN(31) THEN 'XXXI'
				WHEN(32) THEN 'XXXII'
				WHEN(33) THEN 'XXXIII'
				WHEN(34) THEN 'XXXIV'
				WHEN(35) THEN 'XXXV'
				WHEN(36) THEN 'XXXVI'
				WHEN(37) THEN 'XXXVII'
				WHEN(38) THEN 'XXXVIII'
				WHEN(39) THEN 'XXXIX'
				WHEN(40) THEN 'XL'
				WHEN(41) THEN 'XLI'
				WHEN(42) THEN 'XLII'
				WHEN(43) THEN 'XLIII'
				WHEN(44) THEN 'XLIV'
				WHEN(45) THEN 'XLV'
				WHEN(46) THEN 'XLVI'
				WHEN(47) THEN 'XLVII'
				WHEN(48) THEN 'XLVIII'
				WHEN(49) THEN 'XLIX'
				WHEN(50) THEN 'L'
				WHEN(51) THEN 'LI'
				WHEN(52) THEN 'LII'
				WHEN(53) THEN 'LIII'
				WHEN(54) THEN 'LIV'
				WHEN(55) THEN 'LV'
				WHEN(56) THEN 'LVI'
				WHEN(57) THEN 'LVII'
				WHEN(58) THEN 'LVIII'
				WHEN(59) THEN 'LIX'
				WHEN(60) THEN 'LX'
				WHEN(61) THEN 'LXI'
				WHEN(62) THEN 'LXII'
				WHEN(63) THEN 'LXIII'
				WHEN(64) THEN 'LXIV'
				WHEN(65) THEN 'LXV'
				WHEN(66) THEN 'LXVI'
				WHEN(67) THEN 'LXVII'
				WHEN(68) THEN 'LXVIII'
				WHEN(69) THEN 'LXIX'
				WHEN(70) THEN 'LXX'
				WHEN(71) THEN 'LXXI'
				WHEN(72) THEN 'LXXII'
				WHEN(73) THEN 'LXXIII'
				WHEN(74) THEN 'LXXIV'
				WHEN(75) THEN 'LXXV'
				WHEN(76) THEN 'LXXVI'
				WHEN(77) THEN 'LXXVII'
				WHEN(78) THEN 'LXXVIII'
				WHEN(79) THEN 'LXXIX'
				WHEN(80) THEN 'LXXX'
				WHEN(81) THEN 'LXXXI'
				WHEN(82) THEN 'LXXXII'
				WHEN(83) THEN 'LXXXIII'
				WHEN(84) THEN 'LXXXIV'
				WHEN(85) THEN 'LXXXV'
				WHEN(86) THEN 'LXXXVI'
				WHEN(87) THEN 'LXXXVII'
				WHEN(88) THEN 'LXXXVIII'
				WHEN(89) THEN 'LXXXIX'
				WHEN(90) THEN 'XC'
				WHEN(91) THEN 'XCI'
				WHEN(92) THEN 'XCII'
				WHEN(93) THEN 'XCIII'
				WHEN(94) THEN 'XCIV'
				WHEN(95) THEN 'XCV'
				WHEN(96) THEN 'XCVI'
				WHEN(97) THEN 'XCVII'
				WHEN(98) THEN 'XCVIII'
				WHEN(99) THEN 'XCIX'
			END
					
Return @psRomanNumeral
End	

GO

Grant execute on dbo.fn_NumberToRoman to public
GO







	



