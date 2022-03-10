-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_SoundsLike
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_SoundsLike') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_SoundsLike.'
	Drop function [dbo].[fn_SoundsLike]
	Print '**** Creating Function dbo.fn_SoundsLike...'
	Print ''
End
GO

Set QUOTED_IDENTIFIER OFF
GO

CREATE FUNCTION dbo.fn_SoundsLike
(
	@psInputString	varchar(50)
)
RETURNS char(4)

-- PROCEDURE:	fn_SoundsLike
-- VERSION :	5
-- DESCRIPTION:	Returns a Soundex code for a string of characters.
--		Based on the function found in "The Gurus Guide to Stored Procedures" by Ken Henderson
-- NOTES:	There is no point in using double byte characters as the Sounds Like is only useful
--		for English pronunciation.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 25 Jun 2003  MF		1	Create the function 
-- 30 Jan 2006	SW		2	Renamed from fn_SoundsLikeX to fn_SoundsLike
-- 09 Feb 2007	SW		3	Add checking code for empty string
-- 21 Feb 2007	MF	14397	4	Remove trailing and leading spaces from input string.
-- 23 Feb 2007	SW	14397	5	trim before empty string checking
	
AS
Begin

	Set @psInputString=LTRIM(RTRIM(UPPER(@psInputString)))

	-- Return empty string so LEN(@psInputString)-1 later will not cause error
	If @psInputString = ''
	Begin
		Return ''
	End

	DECLARE @sWorking	varchar(10), 
		@sSoundex	varchar(50),
		@nASCII 	int
	
	-- Put all but the first char in a work buffer (we always return the first char)
	Set @sSoundex=RIGHT(@psInputString,LEN(@psInputString)-1) 
	
	-- Replace vowels and Y with the letter A
	Set @sWorking='EIOUY' 
	While (@sWorking<>'') 
	Begin
	  Set @sSoundex=REPLACE(@sSoundex,LEFT(@sWorking,1),'A')  
	  Set @sWorking=RIGHT(@sWorking,LEN(@sWorking)-1)
	End
	
	
	-- Translate word prefixes using this table
	
	-- From		To
	-- MAC		MCC
	-- KN		NN
	-- K		C
	-- PF		FF
	-- SCH		SSS
	-- PH		FF
	
	
	-- Re-affix first char
	Set @sSoundex=LEFT(@psInputString,1)+@sSoundex
	
	IF (LEFT(@sSoundex,3)='MAC') Set @sSoundex='MCC'+RIGHT(@sSoundex,LEN(@sSoundex)-3)
	IF (LEFT(@sSoundex,2)='KN')  Set @sSoundex='NN' +RIGHT(@sSoundex,LEN(@sSoundex)-2)
	IF (LEFT(@sSoundex,1)='K')   Set @sSoundex='C'  +RIGHT(@sSoundex,LEN(@sSoundex)-1)
	IF (LEFT(@sSoundex,2)='PF')  Set @sSoundex='FF' +RIGHT(@sSoundex,LEN(@sSoundex)-2)
	IF (LEFT(@sSoundex,3)='SCH') Set @sSoundex='SSS'+RIGHT(@sSoundex,LEN(@sSoundex)-3)
	IF (LEFT(@sSoundex,2)='PH')  Set @sSoundex='FF' +RIGHT(@sSoundex,LEN(@sSoundex)-2)
	
	-- Remove first char
	Set @psInputString=@sSoundex
	Set @sSoundex=RIGHT(@sSoundex,LEN(@sSoundex)-1)
	
	-- Translate phonetic  prefixes (those following the first char) using this table:
	
	-- From		To
	-- DG		GG
	-- CAAN		TAAN
	-- D		T
	-- NST		NSS
	-- AV		AF
	-- Q		G
	-- Z		S
	-- M		N
	-- KN		NN
	-- K		C
	-- H		A (unless part of AHA)
	-- AW		A
	-- PH		FF
	-- SCH		SSS
	
	Set @sSoundex=REPLACE(@sSoundex,'DG',  'GG')
	Set @sSoundex=REPLACE(@sSoundex,'CAAN','TAAN')
	Set @sSoundex=REPLACE(@sSoundex,'D',   'T')
	Set @sSoundex=REPLACE(@sSoundex,'NST', 'NSS')
	Set @sSoundex=REPLACE(@sSoundex,'AV',  'AF')
	Set @sSoundex=REPLACE(@sSoundex,'Q',   'G')
	Set @sSoundex=REPLACE(@sSoundex,'Z',   'S')
	Set @sSoundex=REPLACE(@sSoundex,'M',   'N')
	Set @sSoundex=REPLACE(@sSoundex,'KN',  'NN')
	Set @sSoundex=REPLACE(@sSoundex,'K',   'C')
	
	-- Translate H to A unless it's part of "AHA"
	Set @sSoundex=REPLACE(@sSoundex,'AHA','~~~')
	Set @sSoundex=REPLACE(@sSoundex,'H',  'A')
	Set @sSoundex=REPLACE(@sSoundex,'~~~','AHA')
	
	Set @sSoundex=REPLACE(@sSoundex,'AW', 'A')
	Set @sSoundex=REPLACE(@sSoundex,'PH', 'FF')
	Set @sSoundex=REPLACE(@sSoundex,'SCH','SSS')
	
	-- Truncate ending A or S
	IF (RIGHT(@sSoundex,1)='A' or RIGHT(@sSoundex,1)='S') 
		Set @sSoundex=LEFT(@sSoundex,LEN(@sSoundex)-1)
	
	-- Translate ending "NT" to "TT"
	IF (RIGHT(@sSoundex,2)='NT') 
		Set @sSoundex=LEFT(@sSoundex,LEN(@sSoundex)-2)+'TT'
	
	-- Remove all As
	Set @sSoundex=REPLACE(@sSoundex,'A','')
	
	-- Re-affix first char
	Set @sSoundex=LEFT(@psInputString,1)+@sSoundex
	
	-- Remove repeating characters by looping through each ascii value from 
	-- A (65) to Z (90) and replacing each double character by a single occurrence
	Set @nASCII=65
	While (@nASCII<91) 
	Begin
		While (CHARINDEX(char(@nASCII)+CHAR(@nASCII),@sSoundex)<>0)
		Begin
   			Set @sSoundex=REPLACE(@sSoundex,CHAR(@nASCII)+CHAR(@nASCII),CHAR(@nASCII))
		End

		Set @nASCII=@nASCII+1
	End
	
	Set @sSoundex=LEFT(@sSoundex,4)
	IF (LEN(@sSoundex)<4) 
		Set @sSoundex=@sSoundex+SPACE(4-LEN(@sSoundex)) -- Pad with spaces
	
	RETURN(@sSoundex)
End
GO

Grant execute on dbo.fn_SoundsLike to public 
go
