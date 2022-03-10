-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GenerateNumericStem
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GenerateNumericStem]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GenerateNumericStem.'
	Drop procedure [dbo].[cs_GenerateNumericStem]
End
Print '**** Creating Stored Procedure dbo.cs_GenerateNumericStem...'
Print ''
go

SET QUOTED_IDENTIFIER OFF


GO

CREATE PROCEDURE dbo.cs_GenerateNumericStem
(
	@psNewNumericStem 	nvarchar(30)     = null output,
	@pnUserIdentityId 	int,  		 -- Mandatory
	@pnCaseKey 		int,		 -- Mandatory
	@pbCallFromCentura	bit=0,	
	@pbSuppressGeneration bit=0
)
as
-- PROCEDURE: cs_GenerateNumericStem
-- VERSION: 6
-- SCOPE: CPA.net
-- DESCRIPTION: Get a New Numeric Stem for a Case.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 03-Jun-2003  TM 		1 	Procedure created
-- 17 May-2004	TM	RFC1464	2	Set NOCOUNT ON to improve performance.
-- 20 Sep 2004	MF	10296 	3	New columns added to the INTERNALREFSTEM table.
-- 30 Mar 2005	VL	11200 	4	Add support for centura.
-- 17 Aug 2015	MF	49702	5	If Stem is not configured for Draft CaseType then use associated Actual Case Type.
-- 01 Aug 2018	DV	72235	6	Introduced another parameter for just returning the next available stem

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @sSQLString		nvarchar(4000)

declare @sAlertXML 		nvarchar(400)

declare @nStemUniqueNo 		smallint	
declare @nLeadingZerosFlag 	decimal(1,0)
declare @nNumberOfDigits 	smallint
declare @nNextAvailableStem 	int

declare @nErrorCode 		int
set     @nErrorCode 		= 0


-- New Numeric Stem is the next number in a predefined range. Different number ranges
-- are defined on the InternalRefStem table. Locate the appropriate row by using a best 
-- fit on the CaseType and PropertyType of the @pnCaseKey.  

-- Get all of this information from the InternalRefStem in a single Select from the database. 

If @nErrorCode = 0
Begin
	Set @sSQLString="
	SELECT 
	@nLeadingZerosFlag	 = I.LEADINGZEROSFLAG,
	@nNumberOfDigits	 = I.NUMBEROFDIGITS,
	@nNextAvailableStem 	 = I.NEXTAVAILABLESTEM,
	@nStemUniqueNo 		 = I.STEMUNIQUENO
	FROM INTERNALREFSTEM I
	WHERE 
	I.STEMUNIQUENO in
	( SELECT
	CONVERT(int,
	SUBSTRING(
	MAX(
	CASE WHEN (I2.CASEOFFICEID IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (I2.CASETYPE     IS NULL)	THEN '0' 
						ELSE CASE WHEN(I2.CASETYPE=CS2.CASETYPE) THEN '2' ELSE '1' END 
	END +  
	CASE WHEN (I2.PROPERTYTYPE IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (I2.COUNTRYCODE  IS NULL)	THEN '0' ELSE '1' END +
	CASE WHEN (I2.CASECATEGORY IS NULL)	THEN '0' ELSE '1' END +
	CONVERT(varchar,I2.STEMUNIQUENO)), 6,20))
	FROM INTERNALREFSTEM I2 
	join CASES CS2   on (CS2.CASEID=@pnCaseKey)
	join CASETYPE CT on (CT.CASETYPE=CS2.CASETYPE)
	WHERE (	I2.CASEOFFICEID	= CS2.OFFICEID		OR I2.CASEOFFICEID	is NULL )
	AND   (	I2.CASETYPE in (CS2.CASETYPE,CT.ACTUALCASETYPE) OR I2.CASETYPE	is NULL )
	AND   (	I2.PROPERTYTYPE = CS2.PROPERTYTYPE 	OR I2.PROPERTYTYPE 	is NULL )
	AND   (	I2.COUNTRYCODE	= CS2.COUNTRYCODE 	OR I2.COUNTRYCODE 	is NULL )
	AND   (	I2.CASECATEGORY = CS2.CASECATEGORY 	OR I2.CASECATEGORY 	is NULL )
	)"

	exec @nErrorCode=sp_executesql @sSQLString, 
					N'@nLeadingZerosFlag	decimal(1,0)	OUTPUT,
					  @nNumberOfDigits	smallint	OUTPUT,
					  @nNextAvailableStem	int		OUTPUT,
					  @nStemUniqueNo	smallint	OUTPUT,
					  @pnCaseKey		int',
					  @nLeadingZerosFlag =@nLeadingZerosFlag  OUTPUT,
					  @nNumberOfDigits   =@nNumberOfDigits	  OUTPUT,
					  @nNextAvailableStem=@nNextAvailableStem OUTPUT,
					  @nStemUniqueNo     =@nStemUniqueNo	  OUTPUT,
					  @pnCaseKey	     =@pnCaseKey
End

-- If there is no number range (InternalRefStem) defined for a Case then raise an error.
		
If @nErrorCode = 0
and @nNextAvailableStem is null 
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('CS35', 'Cannot generate Case Reference. There is no Internal Reference Stem rule that matches the case.',
					null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End 

-- Increment by 1 InternalRefStem.NextAvailableStem to obtain the number for this IRN.

If @nErrorCode = 0
Begin
	Set @nNextAvailableStem = @nNextAvailableStem + 1	
End

-- If InternalRefStem.LeadingZerosFlag = 1, the number used in the Case Reference 
-- must include leading zeroes up to InternalRefStem.NumberOfDigits. 
		
If @nErrorCode = 0
Begin
	Set @psNewNumericStem = CASE WHEN @nNumberOfDigits > LEN(@nNextAvailableStem) AND @nLeadingZerosFlag = 1  THEN REPLICATE('0',(@nNumberOfDigits - LEN(@nNextAvailableStem))) + CAST(@nNextAvailableStem as nvarchar(30)) 
			     	     ELSE CAST(@nNextAvailableStem as nvarchar(30)) 
		        	END	
End

-- If the formatted Stem contains more than InternalRefStem.NumberOfDigits characters then raise an error.

If @nErrorCode = 0
and LEN(@psNewNumericStem) > @nNumberOfDigits 
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('CS36', 'Cannot generate Case Reference. The Stem has reached the end of its number range',
					null, null, null, null, null)
	RAISERROR(@sAlertXML, 14, 1)
	Set @nErrorCode = @@ERROR
End

-- Update back to the InternalRefStem the last number used.
If @nErrorCode = 0 and @pbSuppressGeneration = 0
Begin
	Set @sSQLString="
  		Update  INTERNALREFSTEM 
		Set 	NEXTAVAILABLESTEM = @nNextAvailableStem
		Where 	STEMUNIQUENO 	  = @nStemUniqueNo"
 		 
  	exec @nErrorCode=sp_executesql @sSQLString, 
    			 	N'@nNextAvailableStem	int,
				  @nStemUniqueNo	smallint',
       			   	  @nNextAvailableStem	=@nNextAvailableStem,
				  @nStemUniqueNo	=@nStemUniqueNo
				      
End

-- Handle when stored procedure is called from centura.
If  @pbCallFromCentura=1
and @nErrorCode=0
Begin				
	Select	@nLeadingZerosFlag as LeadingZerosFlag,
		@nNumberOfDigits as NumberOfDigits,
		@nNextAvailableStem as NextAvailableStem,
		@nStemUniqueNo as StemUniqueNo
End

Return @nErrorCode
GO

Grant execute on dbo.cs_GenerateNumericStem to public
GO
