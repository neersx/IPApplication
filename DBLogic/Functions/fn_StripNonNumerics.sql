-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_StripNonNumerics
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_StripNonNumerics') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_StripNonNumerics'
	Drop function [dbo].[fn_StripNonNumerics]
	Print '**** Creating Function dbo.fn_StripNonNumerics...'
	Print ''
End
go

CREATE FUNCTION dbo.fn_StripNonNumerics
(
	@psStringToClean	nvarchar(max)
)
RETURNS nvarchar(max)

-- FUNCTION	 :	fn_StripNonNumerics
-- VERSION 	 :	7
-- DESCRIPTION	 :	Returns the passed string with all non numeric characters removed

-- MODIFICATIONS :
-- Date		SQA	Who	Version	Change
---------------------------------------------------------------------------
---------------------------------------------------------------------------
-- 02 Jul 2003  6851	IB	1	Removes all non numeric characters 
--					from the @psString string
-- 01 Jun 2004	SQA10121 MF	2	If the input string is NULL then it must be returned as NULL.
-- 20 Sep 2005	RFC3076	TM	3	Eliminate '-' from the @sCleanString.
-- 23 Oct 2006	12413	MF	4	Performance improvement
-- 15 Nov 2010	SQA19193 vql	5	Implement bug fix by Albert Van Biljon.
-- 14 Apr 2011	10475	MF	6	Change nvarchar(4000) to nvarchar(max)
-- 19 Sep 2011	11298	MF	7	Endless loop occurring under some circumstances

AS
Begin
	declare @i		int
	declare @cleanstr	nvarchar(max)  

	set @i        = 0
	set @cleanstr = ''
	set @psStringToClean = REPLACE(@psStringToClean,' ','')

	While @i <= LEN(@psStringToClean)
	Begin
		set @i = @i +1
		if PATINDEX('%[^0-9]%', substring(@psStringToClean,@i,1))= 0
				set @cleanstr = @cleanstr + substring(@psStringToClean,@i,1)
	End
	
	RETURN @cleanstr   
End
go

grant execute on dbo.fn_StripNonNumerics to public
go



