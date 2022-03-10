-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ConstructOperator
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ConstructOperator') and xtype='FN')
begin
	print '**** Drop function dbo.fn_ConstructOperator.'
	drop function dbo.fn_ConstructOperator
end
print '**** Creating function dbo.fn_ConstructOperator...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_ConstructOperator 
		(
		@pnOperator		tinyint,
		@psDataType		nvarchar(3),
		@psParameter1		nvarchar(max),
		@psParameter2		nvarchar(1000),
		@pbCenturaRunsSql	bit		= 0	-- Will the prepared Sql be executed via Centura?
		)
Returns nvarchar(max)

-- FUNCTION :	fn_ConstructOperator
-- VERSION :	20
-- DESCRIPTION:	This function accepts an encoded Operator along with up to two parameters
--		and constructs the Operator and Parameter that can be included in a WHERE clause
--		The values for the OperatorS represent the following :
--			0	Equal To
--			1	Not Equal To
--			2	Starts With
--			3	Ends With
--			4	Contains
--			5	Is Not Null
--			6	Is Null
--			7	Between
--			8	Not Between
--			9	Sounds Like (reserved but not used here)
--			10	Less Than
--			11	Less Than or Equal To
--			12	Greater Than
--			13	Greater Than or Equal To
--			14	Does Not Contain


-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 25 JUL 2002	MF			Function created
-- 05 SEP 2002	MF			Need to take account of parameters that are already enclosed by quotes
-- 06 NOV 2003	MF	R586	6	Provide a new DataType(CS) to indicate a Comma Delimited String
-- 18 Nov 2003	MF	R586	7	Also handle embedded quotes by calling fn_WrapQuotes
-- 26 Feb 2004	MF	R1271	8	Ensure dates are in the format '{ d YYYY-MM-DD }' to handle various  
--					international date formats.  This is an ODBC date escape sequence.
-- 28 May 2004	TM	R1537	9	Replace the '{ d YYYY-MM-DD }' date format with '{ ts YYYY-MM-DD HH:MM:SS.FFF }'
--					date and time format. Ensute that the @psParameter1 has a time portion 
--					of '00:00:00.000' and the @psParameter2 has a date as it was provied and
--					time portion of '23:59:59.997'. Remove remaining 'N' prefixes.	
-- 02 Sep 2004	JEK	R1377	10	Pass new Centura parameter to fn_WrapQuotes	
-- 01 Mar 2005	TM	S11081	11	On Foreign (German) SQL the date conversion should all be done with 120 style (ODBC canonical)
-- 14 May 2010	MF	R9326	12	Extend comparisons to include <, <=, >, and >=. Also a new datatype with the value 'COL' will
--					indicate that @psParameter1 is the name of a column to be used in the comparison.
-- 24 Mar 2011	KR	R7956	13	Added Comma Numeric to allow for debtor multi select pick list
-- 14 Apr 2011	MF	R10475	14	Change nvarchar(4000) to nvarchar(max)
-- 25 May 2011	MF	R9326	15	Revisit of RFC9326 to change the Values as value 9 has been reserved for "Sounds Like"
-- 01 Aug 2014  SS	RFC36952 16     Modified the size of CaseKeys to max to cater to condition where the 200 case keys will be passed for Global Name change
-- 13 Jan 2016	MF	R57111	17	Check for Wildcard in search parameter when Equal To operator is chosen and change the search to LIKE.
-- 04 Apr 2016  MS      R61151  18      Added wrapquotes for parmater1 and parameter2 if the datatype is numeric to avoid sql injection
-- 19 Jul 2016  AK      R64431  19      passed 1 as second parameter in wrapquotes to return comma separated string instead of single string.
-- 20 Mar 2019	MF	DR-47693 20	Introduced new operator for Does Not Contain

as
Begin
	declare @sResult	nvarchar(max)

	-- If the data type is Date then convert to the format YYYY-MM-DD HH:MM:SS.FFF. The date arrives as a VARCHAR in
	-- an unknown format. Allow SQLServer to convert to DATE TIME and then convert back to CHAR in an explicit
	-- format of YYYY-MM-DD HH:MM:SS.FFF.
	If @psDataType='DT'
	Begin
		If @psParameter1 is not null
			-- To ensure that @psParameter1 has  a time portion of '00:00:00.000' convert supplied 
			-- date to the 'YYYY-MM-DD' format so any supplied time gets trancated and then 
			-- convert it into the required format as: 'supplied date' + 'the earliest possible time' 
		        -- (i.e. '00:00:00.000'):
			set @psParameter1=
					  -- Step 2: convert the result date back to CHAR
					  convert(char(23),					 
					  convert(datetime,
					  -- Step 1: convert supplied date to the 'YYYY-MM-DD' format so any 
					  -- supplied time gets trancated. 
					  convert(char(10),convert(datetime,@psParameter1,120),120),120  
					  ),121)

		If @psParameter2 is not null
			-- The following converts the @psParameter2 in the required '{ ts YYYY-MM-DD HH:MM:SS.FFF }' 
			-- format as: 'supplied date' + 'the latest possible time' (i.e. '23:59:59.997'):
			set @psParameter2=
					  -- Step 4: convert the result date back to CHAR
					  convert(char(23), 
					  -- Step 3: subtract 2 milliseconds from the day after supplied date	
					  dateadd(ms, -2,    
					  -- Step 2: add one day to the supplied date
					  dateadd(dd, 1,    
					  convert(datetime, 	
					 -- Step 1: convert supplied date to the 'YYYY-MM-DD' format so any 
					  -- supplied time gets trancated. 
					  convert(char(10),convert(datetime,@psParameter2,120),120), 120 
					  ))), 121)
	End

	-- If the data type is String or Text and the operator requires a wild card search then
	-- strip any quotes surrounding the text

	If  @psDataType   in ('S','T')
	and @pnOperator   >1
	and @psParameter1 like "'%"
	and @psParameter1 like "%'"
	and len(@psParameter1)>2
		Set @psParameter1=substring(@psParameter1, 2, len(@psParameter1)-2)

	If @pnOperator=0
		If @psDataType='T'
			set @sResult=" like "
		Else
		If  @psDataType='S'
		and(@psParameter1 like "%~%%" ESCAPE '~'
		 OR @psParameter1 like "%~_%" ESCAPE '~'
		 OR @psParameter1 like "%~[%" ESCAPE '~'
		 OR @psParameter1 like "%~^%" ESCAPE '~')
			set @sResult=" like "
		Else
		If @psDataType='COL'
			set @sResult="="
		else
			set @sResult=" in ("
	else If @pnOperator=1
		If @psDataType='T'
			set @sResult=" not like "
		Else
		If  @psDataType='S'
		and(@psParameter1 like "%~%%" ESCAPE '~'
		 OR @psParameter1 like "%~_%" ESCAPE '~'
		 OR @psParameter1 like "%~[%" ESCAPE '~'
		 OR @psParameter1 like "%~^%" ESCAPE '~')
			set @sResult=" not like "
		Else
		If @psDataType='COL'
			set @sResult="<>"
		else
			set @sResult=" not in ("
	else If @pnOperator=2
	     and upper(@psDataType) in ('S','T')
	begin
		set @sResult=" like "
		set @psParameter1=@psParameter1+"%"
	end
	else If @pnOperator=3
	     and upper(@psDataType) in ('S','T')
	begin
		set @sResult=" like "
		set @psParameter1="%"+@psParameter1
	end
	else If @pnOperator=4
	     and upper(@psDataType) in ('S','T')
	begin
		set @sResult=" like "
		set @psParameter1="%"+@psParameter1+"%"
	end
	else If @pnOperator=5
		set @sResult=" is not null "
	else If @pnOperator=6
		set @sResult=" is null "
	else If @pnOperator=7
	begin
		If  @psParameter1 is not null
		and @psParameter2 is not null
			set @sResult=" between "
		else If @psParameter1 is not null
			set @sResult=">="
		else If @psParameter2 is not null
			set @sResult="<="
	end
	else If @pnOperator=8
	begin
		If  @psParameter1 is not null
		and @psParameter2 is not null
			set @sResult=" not between "
		else If @psParameter1 is not null
			set @sResult="<"
		else If @psParameter2 is not null
			set @sResult=">"
	end
	Else If @pnOperator=10
	begin
		Set @sResult='<'
	End
	Else If @pnOperator=11
	begin
		Set @sResult='<='
	End
	Else If @pnOperator=12
	begin
		Set @sResult='>'
	End
	Else If @pnOperator=13
	begin
		Set @sResult='>='
	End
	else If @pnOperator=14
	     and upper(@psDataType) in ('S','T')
	begin
		set @sResult=" not like "
		set @psParameter1="%"+@psParameter1+"%"
	end

	-- Wrap quotes around the parameters where necessary remembering that Parameter1
	-- may be comma separated.

	If  upper(@psDataType) in ('S','DT','T', 'CS', 'CN')
	begin
		if @pnOperator in (0,1,2,3,4,14)
		begin
			if @psParameter1 is not null
				-- Comma Delimited Strings are to specically set the second
				-- parameter of fn_WrapQuotes to indicate each entry needs to 
				-- be surrounded by quotes
				If @psDataType='CS'
					set @psParameter1=dbo.fn_WrapQuotes(@psParameter1,1,@pbCenturaRunsSql)
				Else If @psDataType='CN'
					set @psParameter1=@psParameter1
				Else If @psDataType='DT'
					set @psParameter1="{ ts '"+@psParameter1+"' }"
				Else
					set @psParameter1=dbo.fn_WrapQuotes(@psParameter1,0,@pbCenturaRunsSql)
		end
		else begin
			if @psParameter1 is not null
			Begin
				If @psDataType='DT'
					set @psParameter1="{ ts '"+@psParameter1+"' }"
				Else
					set @psParameter1="'"+@psParameter1+"'"
			End

			if @psParameter2 is not null
			Begin
				If @psDataType='DT'
					set @psParameter2="{ ts '"+@psParameter2+"' }"
				Else
					set @psParameter2="'"+@psParameter2+"'"
			End
		end
	end
	
	-- If the operator is not testing against NULLs then we 
	-- need to combine the Operator with the Parameter(s)

	If  @pnOperator not in (5,6)
	and @sResult is not null
	begin
		If @psParameter1 is not null
		begin
                        If @psDataType='N'
                        Begin
                                Set @psParameter1 = dbo.fn_WrapQuotes(@psParameter1,1,@pbCenturaRunsSql)
                        End

			set @sResult=@sResult+@psParameter1

			If  @psParameter2 is not null
			and @pnOperator in (7,8)
			Begin
                                If @psDataType='N'
                                Begin
                                        Set @psParameter2 = dbo.fn_WrapQuotes(@psParameter2,1,@pbCenturaRunsSql)
                                End
				set @sResult=@sResult+" and "+@psParameter2
                        End
		end
		else If  @psParameter2 is not null
		     and @pnOperator in (7,8)
		Begin
                        If @psDataType='N'
                        Begin
                                Set @psParameter2 = dbo.fn_WrapQuotes(@psParameter2,1,@pbCenturaRunsSql)
                        End
			set @sResult=@sResult+@psParameter2
                End

		If  @pnOperator in (0,1)
		and @psDataType not in ('T','COL')
		and @sResult like '% in (%'
			set @sResult=@sResult+")"
	end

	Return @sResult
End
go

grant execute on dbo.fn_ConstructOperator  to public
GO
