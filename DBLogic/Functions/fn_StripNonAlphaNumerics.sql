	-----------------------------------------------------------------------------------------------------------------------------
	-- Creation of fn_StripNonAlphaNumerics
	-----------------------------------------------------------------------------------------------------------------------------
	if exists (select * from sysobjects where id = object_id('dbo.fn_StripNonAlphaNumerics') and xtype='FN')
	Begin
		Print '**** Drop Function dbo.fn_StripNonAlphaNumerics'
		Drop function [dbo].[fn_StripNonAlphaNumerics]
		Print '**** Creating Function dbo.fn_StripNonAlphaNumerics...'
		Print ''
	End
	go

	CREATE FUNCTION dbo.fn_StripNonAlphaNumerics
	(
		@psStringToClean	nvarchar(max)
	)
	RETURNS nvarchar(max)

	-- FUNCTION	 :	fn_StripNonAlphaNumerics
	-- VERSION 	 :	5
	-- DESCRIPTION	 :	Returns the passed string with all non alpha numeric characters removed

	-- MODIFICATIONS :
	-- Date		SQA	Who	Version	Change
	---------------------------------------------------------------------------
	---------------------------------------------------------------------------
	-- 06 Sep 2006  12413	MF	1	Copied from fn_StripNonNumerics
	-- 20 Oct 2006	12413	MF	2	Performance improvement
	-- 01 May 2008		DL	3	PATINDEX is buggy and caused this function to hang when @psStringToClean 
	--					contains 'aa' or 'AA' or 'a/a' and database collation is 'Danish_Norwegian_CI_AS'
	--					e.g. SELECT PATINDEX('%[^0-9A-Za-z]%', 'AA?' COLLATE Danish_Norwegian_CI_AS ) returns 1 when should be 3.
	-- 14 Apr 2011	10475	MF	4	Change nvarchar(4000) to nvarchar(max)
	-- 19 Sep 2011	11298	MF	5	Endless loop occurring under some circumstances
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
			if PATINDEX('%[^0-9A-Za-z]%', substring(@psStringToClean,@i,1))= 0
				set @cleanstr = @cleanstr + substring(@psStringToClean,@i,1)
		End
		
		RETURN @cleanstr   
	End  
	go

	grant execute on dbo.fn_StripNonAlphaNumerics to public
	go