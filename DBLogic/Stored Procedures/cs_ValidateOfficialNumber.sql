-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ValidateOfficialNumber
-----------------------------------------------------------------------------------------------------------------------------

if exists (select * from sysobjects where id = object_id(N'[dbo].[cs_ValidateOfficialNumber]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cs_ValidateOfficialNumber.'
	drop procedure dbo.cs_ValidateOfficialNumber
	print '**** Creating procedure dbo.cs_ValidateOfficialNumber...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.cs_ValidateOfficialNumber
	@pnPatternError			int		OUTPUT,
	@psErrorMessage			nvarchar(254)	OUTPUT,
	@pnWarningFlag			tinyint		OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbInvokedByCentura		tinyint		= 0,	-- Indicates that Centura code is calling the Stored Procedure
	@pnCaseId			int,			-- the CaseId whose Official Number is being validated
	@psNumberType			nvarchar(3),		-- the Number Type being validated
	@psOfficialNumber		nvarchar(36)	= null,	-- the official number to be checked.  If not passed
								-- as a parameter then it will be looked up from the
								-- database.
	@pdtValidatingEventDate		datetime	= null	-- the date that the user has entered for validation, this is
								-- used when the date has not been comitted to the database yet
								-- therefore cannot be found in the CASEEVENT table.
	
AS

-- PROCEDURE :	cs_ValidateOfficialNumber
-- VERSION :	8
-- DESCRIPTION:	Validates the Official Number against previously defined pattern that has been saved by
--		Country, Property Type, Number Type and Date Valid From.
--		If the Official Number is not passed as a parameter then it will be extracted from 
--		the database.
-- CALLED BY :	

-- MODIFICATIONS:
-- Date		Who	Number	Version	
-- ====         ===	======	=======
-- 15/07/2002	MF			Procedure created
-- 21/10/2002	MF	8099		The CASEEVENT to use for the NumberType rule should be Cycle 1
-- 31/07/2003	MF	6367	3	Allow a user defined stored procedure to be called as an additional
--					validation step.
-- 19/08/2003	vql	6367		trim the @sPattern variable.
-- 14/05/2009	vql	15273		Added new EventDate parameter.
-- 16/03/2010	PS	RFC7251	5	Added support for error message translation.
-- 30 Mar 2010	MF	RFC9081	6	VALIDATENUMBERS table now allows rules to be held by Case Category and SubType. 
--					Procedure modified to incorporate into best fit search.
-- 28-Oct-2011	LP	R11251	7	Set transaction isolation level as tables could be locked when there are uncommitted updates,
--					e.g. when validating official numbers from Workflow Wizard
-- 19 May 2020	DL	DR-58943	8	Ability to enter up to 3 characters for Number type code via client server	

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode		int

declare @sSearchResult		nvarchar(591)
declare @sPattern		nvarchar(254)
declare @sProcedureName 	nvarchar(80)

declare @sUserErrorMessage	nvarchar(254)
declare @nUserWarningFlag	tinyint

declare	@sSQLString		nvarchar(4000)
Declare @sLookupCulture	nvarchar(10)

set transaction isolation level read uncommitted

set @ErrorCode=0
set @pnPatternError=0	-- default to indicate a valid match
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbInvokedByCentura)

-- If the Official Number has not been passed as a parameter then it will
-- be extracted from the database.

If @psOfficialNumber is null
begin
	set @sSQLString="select @psOfficialNumber=OFFICIALNUMBER"+char(10)+
			"from OFFICIALNUMBERS"+char(10)+
			"where CASEID=@pnCaseId"+char(10)+
			"and   NUMBERTYPE=@psNumberType"+char(10)+
			"and   ISCURRENT=1"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@psOfficialNumber	nvarchar(36) 	OUTPUT,
					  @pnCaseId		int,
					  @psNumberType		nvarchar(3)',
					  @psOfficialNumber=@psOfficialNumber	OUTPUT,
					  @pnCaseId        =@pnCaseId,
					  @psNumberType    =@psNumberType
end

-- Find the best ValidateNumbers row for the Case and NumberType by matching against
-- the Case attributes and comparing against the date the Number applies to 

if  @ErrorCode=0
begin	
	set @sSQLString="
	select @sSearchResult
		=substring (
			max(
			 CASE WHEN(V.CASETYPE     is NULL) THEN '0' ELSE '1' END
			+CASE WHEN(V.CASECATEGORY is NULL) THEN '0' ELSE '1' END
			+CASE WHEN(V.SUBTYPE      is NULL) THEN '0' ELSE '1' END
			+isnull(convert(varchar(8), V.VALIDFROM, 112),'00000000') 
			+convert(nchar(254),V.PATTERN)
			+convert(nchar(254)," + dbo.fn_SqlTranslatedColumn('VALIDATENUMBERS','ERRORMESSAGE',null,'V',@sLookupCulture,@pbInvokedByCentura)+ ")
			+convert(nchar(1),  V.WARNINGFLAG)
			+convert(nchar(80), isnull(T.DESCRIPTION,''))),
			12,589)
	from CASES C
	     join NUMBERTYPES NT	on (NT.NUMBERTYPE=@psNumberType)
	left join CASEEVENT CE		on (CE.CASEID=C.CASEID
					and CE.EVENTNO=NT.RELATEDEVENTNO
					and CE.CYCLE=1)
	     join VALIDATENUMBERS V	on (V.COUNTRYCODE=C.COUNTRYCODE
					and V.PROPERTYTYPE=C.PROPERTYTYPE	
					and V.NUMBERTYPE  =NT.NUMBERTYPE)
	left join TABLECODES T		on (T.TABLECODE=V.VALIDATINGSPID)
	where C.CASEID=@pnCaseId
	and  (V.CASETYPE    =C.CASETYPE     OR V.CASETYPE     is null)
	and  (V.CASECATEGORY=C.CASECATEGORY OR V.CASECATEGORY is null)
	and  (V.SUBTYPE     =C.SUBTYPE      OR V.SUBTYPE      is null)
	and  (V.VALIDFROM <=coalesce(@pdtValidatingEventDate,CE.EVENTDATE,getdate()) OR V.VALIDFROM is null)"

	exec @ErrorCode=sp_executesql @sSQLString,
					N'@sSearchResult	nvarchar(591) 	OUTPUT,
					  @pnCaseId		int,
					  @psNumberType		nvarchar(3),
					  @pdtValidatingEventDate		datetime',
					  @sSearchResult=@sSearchResult	OUTPUT,
					  @pnCaseId     =@pnCaseId,
					  @psNumberType =@psNumberType,
					  @pdtValidatingEventDate	=@pdtValidatingEventDate
end

-- Now perform the pattern matching validation if we have a pattern and a string to validate

If @ErrorCode=0
begin
--	set @sPattern      =substring(@sSearchResult,   1, 254)
--	vql SQA6367
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
						'                	@nUserWarningFlag	OUTPUT'
				
				exec sp_executesql @sSQLString,
						N'@psOfficialNumber 	nvarchar(36),
						  @sUserErrorMessage	nvarchar(254)	OUTPUT,
						  @nUserWarningFlag	tinyint		OUTPUT,
						  @pnPatternError	int		OUTPUT',
						  @psOfficialNumber,		
						  @sUserErrorMessage	OUTPUT,	
						  @nUserWarningFlag	OUTPUT,
						  @pnPatternError	OUTPUT
				
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

-- Return the result set indicating if 
If @pbInvokedByCentura=1
begin
	select	@ErrorCode      as ErrorCode,
		@pnPatternError as PatternErrorFlag,
	 	@psErrorMessage as ErrorMessage,
		@pnWarningFlag  as WarningFlag
end


RETURN @ErrorCode
go

grant execute on dbo.cs_ValidateOfficialNumber  to public
go
