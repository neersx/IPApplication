-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_Tokenise
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_Tokenise') and xtype='TF')
begin
	print '**** Drop function dbo.fn_Tokenise.'
	drop function dbo.fn_Tokenise
end
print '**** Creating function dbo.fn_Tokenise...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_Tokenise
			(
			@psParameterString		nvarchar(max),
			@psDelimiter			nvarchar(10)
			)
RETURNS @tbParameters TABLE
   (
    InsertOrder		smallint	identity,
    Parameter		nvarchar(max)	collate database_default null,
    NumericParameter	decimal(38,10)	null
   )
as
-- FUNCTION :	fn_Tokenise
-- VERSION :	14
-- DESCRIPTION:	This function accepts a string of delimited values along with the optional
--		delimiter.  It will then separate out the parameters and return them as a
--		table with the rows in the same order as they appeared in the string.

-- MODIFICATIONS :
-- Date		Who	Change		Version	Description
-- ------------	-------	-------		------	----------------------------------------- 
--  4/07/2002	MF				Function created
-- 17/07/2002	MF				If the tokenised value is numeric then also save in a numeric column
-- 04/09/2002	MF				Do not save in the numeric column if any other values for the column are not 
--						numeric and not null.
-- 18/08/2004	AB	8035		5	Add collate database_default syntax to temp tables.
-- 04 Apr 2006	MF	12459		6	The ISNUMERIC function indicates that '-', '.' are numerics which causes
--						an error if they are then Cast to a numeric field.  Exclude certain values
--						from being treated as a numeric
-- 11 Jan 2007	SW	RFC4924		7	Fix cast numeric overflow error
-- 07 Mar 2008	SW	RFC6226		8	Fix tokenise error when there is a "~" in the @psParameterString
-- 09 Dec 2008	SF	RFC7391		9	ISNUMERIC returns 1 for plus (+), and valid currency symbols such as the dollar sign ($). 
-- 10 Mar 2009	KR	RFC7731		10	Make it return null if parameter passed is ''
-- 14 Apr 2011	MF	RFC10475 	11	Change nvarchar(4000) to nvarchar(max)
-- 21 Jun 2011	AT	RFC10882	12	Cater for blank lines when parameter is a carriage return.
-- 01 Dec 2014	vql	RFC41812	13	Remove use of IsNumeric and check for digits instead.
-- 25 Aug 2016	MF	62043		14	Function needs to cater for an empty parameter (2 continguous delimiters).

Begin
	declare @nFirstDelimiter	smallint

	-- Exit if there is nothing to tokenise

	If ( @psParameterString is null or @psParameterString = '')
		RETURN

	-- Default the delimiter to a comma if it is not explicityl defined
	If @psDelimiter is NULL
		set @psDelimiter=','

	--10882 Normalise the carriage returns if a carriage return is the delimiter,
	-- otherwise it may try to cast char(10) or char(13) as float into NumericParameter
	If (@psDelimiter = char(10) or @psDelimiter = char(13))
	Begin
		Set @psParameterString = replace(@psParameterString,char(13)+char(10),@psDelimiter)
		If @psDelimiter = char(10)
			Set @psParameterString = replace(@psParameterString,char(13),@psDelimiter)
		else
			Set @psParameterString = replace(@psParameterString,char(10),@psDelimiter)
	End

	-- Convert the user defined delimiters to a standard internal character to make processing simpler

	if @psDelimiter <> char(27)
		set @psParameterString = replace(@psParameterString,@psDelimiter,char(27))

	-- If the string does not end in a delimiter then insert one
	
	if @psParameterString not like '%'+char(27)
		set @psParameterString = @psParameterString+char(27)

	WHILE datalength(ltrim(@psParameterString))>0
	Begin
		set @nFirstDelimiter=patindex('%'+char(27)+'%',@psParameterString)
		
		insert into @tbParameters (Parameter, NumericParameter)
		select  CASE WHEN(@nFirstDelimiter<2) THEN NULL ELSE rtrim(ltrim(substring(@psParameterString, 1, @nFirstDelimiter-1))) END,
			CASE WHEN(@nFirstDelimiter<2) 
			THEN NULL
			     WHEN(PATINDEX('%[^0-9]%',(      rtrim(ltrim(substring(@psParameterString, 1, @nFirstDelimiter-1)))))=0
			                 and                 rtrim(ltrim(substring(@psParameterString, 1, @nFirstDelimiter-1))) not in ('-','.','+','$')
			                 and  patindex('%,%',rtrim(ltrim(substring(@psParameterString, 1, @nFirstDelimiter-1))))=0)
			THEN	CASE WHEN(cast(rtrim(ltrim(substring(@psParameterString, 1, @nFirstDelimiter-1))) as FLOAT)<=999999999999999999999999999.9999999999)
				      and @nFirstDelimiter - charindex('.', rtrim(ltrim(substring(@psParameterString, 1, @nFirstDelimiter-1)))) <= 11
					THEN cast(rtrim(ltrim(substring(@psParameterString, 1, @nFirstDelimiter-1))) as DECIMAL(38,10))
					ELSE NULL
				END
			ELSE NULL
			END

		-- Now remove the parameter just extracted
	
		set @psParameterString=substring(@psParameterString,@nFirstDelimiter+1,len(@psParameterString))
		
	end

	-- If any of the tokenised values were not numeric then clear out all of the numeric
	-- valued columns as they are only of value for sorting numerically if all rows are numeric

	update @tbParameters
	set NumericParameter=null
	where exists
	(select * from @tbParameters
	 where NumericParameter is null
	 and    Parameter is not null)

	Return
End
go

grant REFERENCES, SELECT on dbo.fn_Tokenise to public
GO
