-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_ImportValidateOfficialNumber
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_ImportValidateOfficialNumber]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_ImportValidateOfficialNumber.'
	drop procedure dbo.ip_ImportValidateOfficialNumber
end
print '**** Creating procedure dbo.ip_ImportValidateOfficialNumber...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.ip_ImportValidateOfficialNumber
	@pnPatternError			int		OUTPUT,
	@psErrorMessage			nvarchar(254)	OUTPUT,
	@pnWarningFlag			tinyint		OUTPUT,
	@psValidNumber			nvarchar(36)	OUTPUT,
	@psNumberType			nvarchar(3),		-- the Number Type being validated
	@psOfficialNumber		nvarchar(36),		-- the official number to be checked
	@psPropertyType			nchar(1),		-- Property Type to be validated
	@psCountryCode			nvarchar(3),		-- Country to be validated
	@pdtEventDate			datetime	= null	-- the date to use to determine the validation rule
	
AS

-- PROCEDURE :	ip_ImportValidateOfficialNumber
-- VERSION :	2
-- DESCRIPTION:	Validates the Official Number against previously defined pattern that has been saved by
--		Country, Property Type, Number Type and Date Valid From.
--		If the Official Number is not passed as a parameter then it will be extracted from 
--		the database.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 5 Apr 2005	MF	8748	1	Procedure created (copied from cs_ValidateOfficialNumber)
-- 19 May 2020	DL	DR-58943	2	Ability to enter up to 3 characters for Number type code via client server	


set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode		int

declare @sSearchResult		nvarchar(591)
declare @sPattern		nvarchar(254)
declare @sProcedureName 	nvarchar(80)

declare @sUserErrorMessage	nvarchar(254)
declare @nUserWarningFlag	tinyint

declare @sValidNumber		nvarchar(36)	
declare @pbInvokedByCentura	int

declare	@sSQLString		nvarchar(4000)

set @ErrorCode=0
set @pnPatternError=0	-- default to indicate a valid match

-- Find the best ValidateNumbers row for the number to be validate by matching against
-- the attributes passed as parameters.

if  @ErrorCode=0
begin	
	set @sSQLString="
	select @sSearchResult
		=substring (
			max(isnull(convert(varchar(8), V.VALIDFROM, 112),'00000000') 
			+convert(nchar(254),V.PATTERN)
			+convert(nchar(254),V.ERRORMESSAGE)
			+convert(nchar(1),  V.WARNINGFLAG)
			+convert(nchar(80), isnull(T.DESCRIPTION,''))),
			9,589)
	from VALIDATENUMBERS V
	left join TABLECODES T	on (T.TABLECODE=V.VALIDATINGSPID)
	where V.COUNTRYCODE=@psCountryCode
	and V.PROPERTYTYPE=@psPropertyType
	and V.NUMBERTYPE  =@psNumberType
	and  (V.VALIDFROM <=isnull(@pdtEventDate,getdate()) OR V.VALIDFROM is null)"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sSearchResult	nvarchar(591) 	OUTPUT,
					  @psCountryCode	nvarchar(3),
					  @psPropertyType	nchar(1),
					  @psNumberType		nvarchar(3),
					  @pdtEventDate		datetime',
					  @sSearchResult =@sSearchResult	OUTPUT,
					  @psCountryCode =@psCountryCode,
					  @psPropertyType=@psPropertyType,
					  @psNumberType  =@psNumberType,
					  @pdtEventDate  =@pdtEventDate
end

-- Now perform the pattern matching validation if we have a pattern and a string to validate

If @ErrorCode=0
begin
	set @sPattern      =ltrim(rtrim(substring(@sSearchResult,   1, 254)))
	set @psErrorMessage=substring(@sSearchResult, 255, 254)
	set @sProcedureName=replace(substring(@sSearchResult, 510, 80),' ','')

	if substring(@sSearchResult, 509,1)='1'
		set @pnWarningFlag=1
	else
		set @pnWarningFlag=0

	-- Now that the parameters have been extracted perform the pattern
	-- matching comparison to validate the Official Number against the 
	-- pattern

	If @sPattern         is null
	or @psOfficialNumber is null
	begin
		set @psErrorMessage=null
	end
	else begin
		exec @pnPatternError = ip_MatchPattern 	
						@psOfficialNumber, 	-- string to be validated
						@sPattern, 		-- pattern used to validate against
						0			-- Flag to indicated this procedure is NOT called directly from Centura code						 
		--  @pnPatternError return values
		--  0 - psSourceString matches psPattern
		-- -1 - psSourceString does not match psPattern
		--  1 - could not create VBScript.RegExp object
		--  2 - error occurred when setting the psPattern pattern
		--  3 - psPattern is not a valid pattern
		--  4 - error occurred when matching the psPattern pattern
		If  @pnPatternError=0
		Begin
			-- If there is a stored procedure to perform additional validation then execute it

			If datalength(@sProcedureName)>0
			Begin
				Set @sSQLString='Exec @pnPatternError='+@sProcedureName+' '+char(10)+
						'                	@psOfficialNumber,'+char(10)+
						'                	@sUserErrorMessage 	OUTPUT,'+char(10)+
						'                	@nUserWarningFlag	OUTPUT'+char(10)+
						'			@psValidNumber		OUTPUT'
				
				exec sp_executesql @sSQLString,
						N'@psOfficialNumber 	nvarchar(36),
						  @sUserErrorMessage	nvarchar(254)	OUTPUT,
						  @nUserWarningFlag	tinyint		OUTPUT,
						  @pnPatternError	int		OUTPUT,
						  @sValidNumber		nvarchar(36)	OUTPUT',
						  @psOfficialNumber,		
						  @sUserErrorMessage	OUTPUT,	
						  @nUserWarningFlag	OUTPUT,
						  @pnPatternError	OUTPUT,
						  @psValidNumber	OUTPUT
				
				-- A non zero ErrorCode returned from the user defined stored procedure
				-- indicates that the validation failed.
				If @pnPatternError=0
				Begin
					set @psErrorMessage=null
				End
				Else Begin
					-- The stored procedure may override the Warning and ErrorMessage

					If @nUserWarningFlag is not null
						Set @pnWarningFlag=@nUserWarningFlag

					If @sUserErrorMessage is not null
						Set @psErrorMessage=@sUserErrorMessage
				End
			End
			Else Begin
				set @psErrorMessage=null
			End
		End
		else If @pnPatternError=1
			set @psErrorMessage='Could not create VBScript.RegExp object'
		else If @pnPatternError=2
			set @psErrorMessage='Error occurred when setting the pattern'
		else If @pnPatternError=3
			set @psErrorMessage='Pattern defined is not valid'
		else If @pnPatternError=4
			set @psErrorMessage='Error occurred when matching the pattern'

	end
End

RETURN @ErrorCode
go

grant execute on dbo.ip_ImportValidateOfficialNumber  to public
go
