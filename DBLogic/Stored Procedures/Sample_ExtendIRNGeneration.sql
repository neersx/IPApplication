-----------------------------------------------------------------------------------------------------------------------------
-- Creation of Sample_ExtendIRNGeneration
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[Sample_ExtendIRNGeneration]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
 	Print '**** Drop Stored Procedure dbo.Sample_ExtendIRNGeneration.'
 	Drop procedure [dbo].[Sample_ExtendIRNGeneration]
End
Print '**** Creating Stored Procedure dbo.Sample_ExtendIRNGeneration...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE [dbo].[Sample_ExtendIRNGeneration]
(
 	@pnCaseKey    		int,
 	@pnParentCaseKey	int		= NULL, 
 	@pnCriteriaNo		int		= NULL,
 	@psCaseReference	nvarchar(30)  	= NULL OUTPUT
)
as
-- PROCEDURE:	Sample_ExtendIRNGeneration
-- VERSION: 	1
-- DESCRIPTION: User Defined Extension to IRN Generation
-- COPYRIGHT:	Copyright 1993 - 2014 CPA Global Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 06-Dec-2013  MF  	R28144 	 1   	Procedure created

Set NOCOUNT ON
Set CONCAT_NULL_YIELDS_NULL Off

declare @nErrorCode		int
declare	@sSQLString		nvarchar(max)

declare	@sCaseCountry		nvarchar(3)
declare	@sCasePropertyType	nchar(1)
declare @sCaseCategory		nvarchar(2)
declare @sCaseSubType		nvarchar(2)

-- Segment Options
Declare @nCountry		Int
Declare @nProperty		Int
Declare @nFamily		Int
Declare @nDelimiter		Int
Declare @nNumericStem		Int
Declare @nTextStem		Int
Declare @nParentCountry		Int

Set @nErrorCode		= 0

Set @nCountry		= 1450
Set @nProperty		= 1451
Set @nFamily		= 1455
Set @nDelimiter		= 1456
Set @nNumericStem	= 1457
Set @nTextStem		= 1462
Set @nParentCountry	= 1463

-- Get all of this information from the CASES in a single Select from the database.

If @nErrorCode=0
and exists(Select * from #TempSegment where SEGMENTCODE in (@nCountry, @nParentCountry, @nProperty, @nFamily, @nNumericStem, @nTextStem) )
Begin
 	Set @sSQLString="
	  	Select @sCaseCountry 		= C.COUNTRYCODE,
		       @sCasePropertyType	= C.PROPERTYTYPE,
		       @sCaseCategory		= C.CASECATEGORY,
		       @sCaseSubType		= C.SUBTYPE
	  	from CASES C
	 	where C.CASEID=@pnCaseKey"
 
	exec @nErrorCode=sp_executesql @sSQLString, 
		 		N'@sCaseCountry 	nvarchar(3)		OUTPUT,
				  @sCasePropertyType	nvarchar(1)		OUTPUT,
				  @sCaseCategory	nvarchar(2)		OUTPUT,
				  @sCaseSubType		nvarchar(2)		OUTPUT,
				  @pnCaseKey		int',
		   		  @sCaseCountry 	= @sCaseCountry 	OUTPUT,
				  @sCasePropertyType	= @sCasePropertyType	OUTPUT,
				  @sCaseCategory	= @sCaseCategory	OUTPUT,
				  @sCaseSubType		= @sCaseSubType		OUTPUT,
		   		  @pnCaseKey 		= @pnCaseKey

	if	@sCaseCountry = 'US' and @sCasePropertyType = 'P' and @sCaseCategory = 'P' 
		set @sCaseCountry = '888'

	if	@sCaseCountry = 'US' and @sCasePropertyType = 'P' and @sCaseCategory <> 'P' 
		set @sCaseCountry = '999'

	if	@sCaseCountry = 'US' and @sCasePropertyType = 'D'
		set @sCaseCountry = '999'

	if	@sCaseCountry = 'US' and @sCasePropertyType = 'T'
		set @sCaseCountry = '999'

	if	@sCaseCountry = 'IB' and @sCasePropertyType = 'T' 
		set @sCaseCountry = '170'

	if	@sCaseCategory = 'G'
		select @sCaseCountry =  
			case	when @sCaseSubType = 'AK' then '902'
				when @sCaseSubType = 'AL' then '901'
				when @sCaseSubType = 'AR' then '904'
				when @sCaseSubType = 'AZ' then '903'
				when @sCaseSubType = 'CA' then '905'
				when @sCaseSubType = 'CO' then '906'
				when @sCaseSubType = 'CT' then '907'
				when @sCaseSubType = 'DE' then '908'
				when @sCaseSubType = 'FL' then '909'
				when @sCaseSubType = 'GA' then '910'
				when @sCaseSubType = 'HI' then '911'
				when @sCaseSubType = 'HI' then '911'
				when @sCaseSubType = 'IA' then '915'
				when @sCaseSubType = 'ID' then '912'
				when @sCaseSubType = 'IL' then '913'
				when @sCaseSubType = 'IN' then '914'
				when @sCaseSubType = 'KS' then '916'
				when @sCaseSubType = 'LA' then '918'
				when @sCaseSubType = 'MA' then '921'
				when @sCaseSubType = 'MD' then '920'
				when @sCaseSubType = 'ME' then '919'
				when @sCaseSubType = 'MI' then '922'
				when @sCaseSubType = 'MN' then '923'
				when @sCaseSubType = 'MO' then '949'
				when @sCaseSubType = 'MS' then '948'
				when @sCaseSubType = 'MT' then '924'
				when @sCaseSubType = 'NC' then '931'
				when @sCaseSubType = 'ND' then '932'
				when @sCaseSubType = 'NE' then '925'
				when @sCaseSubType = 'NH' then '927'
				when @sCaseSubType = 'NJ' then '928'
				when @sCaseSubType = 'NM' then '929'
				when @sCaseSubType = 'NV' then '926'
				when @sCaseSubType = 'NY' then '930'
				when @sCaseSubType = 'OH' then '933'
				when @sCaseSubType = 'OK' then '934'
				when @sCaseSubType = 'OR' then '935'
				when @sCaseSubType = 'PA' then '936'
				when @sCaseSubType = 'RI' then '937'
				when @sCaseSubType = 'SC' then '938'
				when @sCaseSubType = 'SK' then '939'
				when @sCaseSubType = 'TN' then '940'
				when @sCaseSubType = 'TX' then '941'
				when @sCaseSubType = 'UT' then '942'
				when @sCaseSubType = 'VA' then '944'
				when @sCaseSubType = 'VT' then '943'
				when @sCaseSubType = 'WA' then '945'
				when @sCaseSubType = 'WI' then '947'
				when @sCaseSubType = 'WV' then '946'
				when @sCaseSubType = 'WY' then '950'
			end

	if isnumeric(@sCaseCountry) = 0
	Begin
		select @sCaseCountry = convert(varchar(10),COUNTRYTEXT)
		from	COUNTRYTEXT CT
		join	TABLECODES TC on (CT.TEXTID = TC.TABLECODE)
		where	COUNTRYCODE = @sCaseCountry 
		and	PROPERTYTYPE = @sCasePropertyType
		and	TC.DESCRIPTION = 'Jones Days Country Code' 
		and	TC.TABLETYPE = 49
	End

	if len(@sCaseCountry) = 1 
		set @sCaseCountry = '00'+@sCaseCountry
	else
	if len(@sCaseCountry) = 2
		set @sCaseCountry = '0'+@sCaseCountry
End

If  @nErrorCode = 0
and @sCaseCountry is not null
Begin
	-- Update the Country segment 
	Update #TempSegment 
	Set SEGMENTVALUE=@sCaseCountry
  	where SEGMENTCODE=@nCountry
End

Return @nErrorCode
GO

Grant execute on dbo.Sample_ExtendIRNGeneration to public
GO

