-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_ApplyGeneratedReference
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_ApplyGeneratedReference]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
 	Print '**** Drop Stored Procedure dbo.cs_ApplyGeneratedReference.'
 	Drop procedure [dbo].[cs_ApplyGeneratedReference]
End
Print '**** Creating Stored Procedure dbo.cs_ApplyGeneratedReference...'
Print ''
GO

Set QUOTED_IDENTIFIER OFF
GO

CREATE PROCEDURE dbo.cs_ApplyGeneratedReference
(
 	@psCaseReference		nvarchar(30)  		OUTPUT,
 	@pnUserIdentityId		int,     		-- Mandatory
 	@psCulture			nvarchar(10)  		= null,
 	@pnCaseKey    			int,  			-- Mandatory
 	@pnParentCaseKey   		int   			= null
)
as
-- PROCEDURE: cs_ApplyGeneratedReference
-- VERSION: 	26
-- SCOPE: CPA.net
-- DESCRIPTION: Generates Case Reference.
-- COPYRIGHT:	Copyright 1993 - 2005 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 12-Jun-2003  TM  	  	 1   	Procedure created
-- 21-Aug-2003	TM	 	 2	RFC326 Case Reference segments in lower case not saved 
--				   	to database in upper case. Convert @psCaseReference to
--				   	upper case before saving it to database.
-- 10-Mar-2004	TM	RFC857	 3	Strip off any leading and trailing spaces from the @psCaseReference before 
--					updating CASES.IRN with its value.	
-- 20 Sep 2004	MF	SQA10297 4	Allow Roman Numerals to be generated as a Sequence
-- 24 Nov 2004	MF	SQA10698 5	Allow a new sequence of 01 Ascending
-- 03 Feb 2005	MF	SQA10637 6	Allow a new Text Stem to be passed as a parameter for inclusion in the 
--					generated IRN.
-- 08 Feb 2005	MF	SQA10637 7	Reverse out the code for passing the Text Stem.  It will now be retrieved
--					from the STEM column in the CASES table.
-- 24 May 2005	TM	RFC1990	 8	Change TextStem calculation to get the stem from the parent case by default.
--					Convert Stem into upper case.
-- 30 May 2005	JD	SQA10914 9	Suppress trailing delimiters for NUL+ sequences
--			SQA11268 9	Modify Parent Sequence/Parent stem/Sequence to display Roman Numerals.
-- 13 Jul 2005	AT	SQA7463	 10	Modified to refer to Segment Options TABLECODES.
-- 10 Jun 2006	JD	SQA12068 11	Add new Z&Descending sequence
-- 28 May 2007	vql	SQA14774 12	Add new 000, 001, 0000, 0001 sequence types.
-- 08 Jun 2007	mf	SQA14897 13	Extension to 10914. Allow delimiters with a value between 0 and 9 and A and Z
--					to appear even if the following Sequence is NULL.
-- 06 Dec 2007	vql	SQA15248 14	Add new segment Office IRN Code.
-- 03 Mar 2008	vql	SQA15970 15	IRN Generation using Parent Sequence, if no Parent Sequence ignore segment.
-- 17 Mar 2008	vql	SQA15970 16	Ignore the Parent Sequence Segment, if Parent case does not have a Sequence,
--					but does have a Stem part.
-- 15 Apr 2008	vql	S15970	17	Remove the error messages for where Parent case is not available.
-- 06 May 2008	vql	S16351	18	IRN Generation bug, parent sequence not following to child stem.
-- 29 Aug 2008	vql	S16820	19	Copy the case office code in the parent’s IRN into the new case’s IRN.
-- 11 Dec 2008	MF	S17136	20	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 21 Sep 2009  LP	R8047	21	Pass ProfileKey parameter to fn_GetCriteriaNo
-- 18 Aug 2010  vql	S18210	22	Error messages when creating EP national phases with copy profile from designated country tab
-- 01 Jun 2011	MF	R10700	23	When a new numeric stem forms part of the generated IRN it is possible that the new IRN already exists
--					in the database. This could occur if manually entered IRNs have been entered. This change is to trap 
--					duplicate key errors and find the next available number to use.
-- 07 Jul 2011	DL	R10830	24	Specify database collation default to temp table columns of type varchar, nvarchar and char
-- 05 Dec 2013	MF	R28144	25	Provide the ability for firms to extend the functionality of Case Reference Generation by a call out
--					to a user defined stored procedure.
-- 14 Jan 2014	MF	R28144	26	Revisit to correct problem found in testing.

Set NOCOUNT On
Set CONCAT_NULL_YIELDS_NULL Off

declare @sSQLString			nvarchar(4000)

declare @nSEGMENT1CODE			int
declare @nSEGMENT2CODE   		int
declare @nSEGMENT3CODE   		int
declare @nSEGMENT4CODE   		int
declare @nSEGMENT5CODE   		int
declare @nSEGMENT6CODE   		int
declare @nSEGMENT7CODE   		int
declare @nSEGMENT8CODE   		int
declare @nSEGMENT9CODE   		int
declare @nINSTRUCTORFLAG  		decimal(1,0)
declare @nOWNERFLAG   			decimal(1,0)
declare @nSTAFFFLAG   			decimal(1,0)
declare @nFAMILYFLAG   			decimal(1,0)
declare @bNewStem			bit		-- RFC10700
declare @bIncrementStemAgain		bit		-- RFC10700

declare @nCriteriaNo			int		-- Is used to store the key of the appropriate Criteria row, which is located using a best fit.
declare @sNewNumericStem		nvarchar(10)	-- Is used to store generated by cs_GenerateNumericStem New Numeric Stem.

declare @sCaseStem   			nvarchar(30)	-- Is used to store CASES.STEM Case Stem Value.
declare @sCaseCountry   		nvarchar(3)
declare @sCaseFamily			nvarchar(20)
declare @sCasePropertyType		nvarchar(1)
declare @sCaseOfficeIRNCode		nvarchar(3)

declare @sUserProcedure			nvarchar(254)	-- RFC28144 Name of user defined stored procedure to extend Case Reference generation logic.
declare @sParentStem   			nvarchar(30)	-- Is used to store CASES.STEM Parent Case Stem Value.
declare @sParentSequence		nvarchar(30)	-- Is used to store the Parent Sequence.
declare @sParentCountry   		nvarchar(3)
declare @sParentCaseOfficeIRNCode	nvarchar(3)
	
declare @sOwnerNameCode		        nvarchar(10)

declare @nInstructorNameKey		int
declare @sInstructorNameCode	        nvarchar(10)
declare @sInstructorPrefix		nvarchar(10)
declare @nInstructorCaseSequence	smallint

declare @nStaffNameKey			int
declare @sStaffNameCode			nvarchar(10)
declare @sOfficeUserCode		nvarchar(10)
		
declare @nSequenceType			int		-- Sequence Type (SEGMENTNAME value where ISSEQUENCE = 1). 
declare @sGeneratedSequence		nvarchar(12)	-- Sequence generated by the cs_GenerateNextSequence stored procedure.
declare @sRomanNumeral			nvarchar(12)	-- Roman Numeral generated by cs_GenerateNextSequence stored procedure.
declare @sStemSegment   		nvarchar(30) 	-- Stem value (SEGMENTVALUE where ISSTEM = 1 and there is no "Parent StemSequence" segment). 
declare @sPartialCaseReference		nvarchar(30)	-- Is assembled from all of the Segments, but substituting "%" for the Sequence to be generated.
declare	@sDelimiter			nvarchar(12)	-- Partial Case Reference, temporarily stores delimiters.

declare @sCasesStem   			nvarchar(30) 	-- Prepared Cases.Stem.
declare @sCaseReference			nvarchar(60)    -- Prepared Case Reference.
declare @nProfileKey                    int             

declare @sAlertXML			nvarchar(400)
declare @nRowCount			int
declare @nErrorCode			int
--declare @nCount			smallint
declare @nSegmentsCount			smallint	-- Number of Segments Case Reference is assembled from.

Declare @nDelimiterTableType int

-- Sequence Table Codes
Declare @nZDescending			Int
Declare @n00Ascending			Int
Declare @n01Ascending			Int
Declare @n1Ascending			Int
Declare @nAAscending			Int
Declare @nCheckDigit			Int
Declare @nNul1Ascending			Int
Declare @nNulAAscending			Int
Declare @nRomanNumeral			Int

-- Special Space delimiter table code
Declare @nSpace Int

-- Segment Options
Declare @nCountry			Int
Declare @nProperty			Int
Declare @nStaff				Int
Declare @nOwner				Int
Declare @nInstructor			Int
Declare @nFamily			Int
Declare @nDelimiter			Int
Declare @nOfficeIRNCode			Int
Declare @nNumericStem			Int
Declare @nParentStem			Int
Declare @nSequence			Int
Declare @nParentSequence		Int
Declare @nParentStemSequence		Int
Declare @nTextStem			Int
Declare @nParentCountry			Int
Declare @nNewNumericStem		Int
Declare @nStaffOffice			Int
Declare @nInstructorPrefix		Int
Declare @nInstructorSequence		Int
Declare @n000Ascending			int
Declare @n001Ascending			int
Declare @n0000Ascending			int
Declare @n0001Ascending			int
Declare @nParentStemOffice		int

Set @nDelimiterTableType = 115

Set @nZDescending = 1399
Set @n00Ascending = 1400
Set @n01Ascending = 1401
Set @n1Ascending = 1402
Set @nAAscending = 1403
Set @nCheckDigit = 1404
Set @nNul1Ascending = 1405
Set @nNulAAscending = 1406
Set @nRomanNumeral = 1407
Set @n000Ascending = 1468
Set @n001Ascending = 1469
Set @n0000Ascending = 1470
Set @n0001Ascending = 1471

Set @nSpace = 1409

Set @nCountry = 1450
Set @nProperty = 1451
Set @nStaff = 1452
Set @nOwner = 1453
Set @nInstructor = 1454
Set @nFamily = 1455
Set @nDelimiter = 1456
Set @nNumericStem = 1457
Set @nParentStem = 1458
Set @nSequence = 1459
Set @nParentSequence = 1460
Set @nParentStemSequence = 1461
Set @nTextStem = 1462
Set @nParentCountry = 1463
Set @nNewNumericStem = 1464
Set @nStaffOffice = 1465
Set @nInstructorPrefix = 1466
Set @nInstructorSequence = 1467
Set @nOfficeIRNCode = 1472
Set @nParentStemOffice = -42846973

Create table #TempSegment      (SEGMENTNO	int IDENTITY,
    				SEGMENTCODE	int,
    				ISSEQUENCE	bit DEFAULT 0,
    				ISSTEM		bit DEFAULT 0,
    				ISDELIMITER	bit DEFAULT 0,  -- 10914
    				ISNULLSEQUENCE	bit DEFAULT 0,	-- 10914
    				SEGMENTVALUE 	nvarchar(30) collate database_default,
				ROMANVALUE	nvarchar(12) collate database_default )

Set     @nErrorCode = 0

-- Get ProfileKey for the current user
If @nErrorCode = 0
Begin
        Select @nProfileKey = PROFILEID
        from USERIDENTITY
        where IDENTITYID = @pnUserIdentityId
        
        Set @nErrorCode = @@ERROR
        
End       
-- Get the best IRN format CriteriaNo rule for the Case. 

If @nErrorCode = 0
Begin
	Set @nCriteriaNo = dbo.fn_GetCriteriaNo(@pnCaseKey, 'R', NULL, GETDATE(), @nProfileKey) 

 	If @nCriteriaNo is null
 	Begin
  		Set @sAlertXML = dbo.fn_GetAlertXML('CS30', 'Cannot generate Case Reference.  There is no Internal Reference Format Criteria that matches the case.',
    						null, null, null, null, null)
  		RAISERROR(@sAlertXML, 14, 1)
  		Set @nErrorCode = @@ERROR
	 End
End

-- If there is no Internal Reference Format rule that matches the case then raise an error. 

If @nErrorCode = 0
and not exists(select * from IRFORMAT where CRITERIANO = @nCriteriaNo)   
Begin
	
	Set @sAlertXML = dbo.fn_GetAlertXML('CS31', 'Cannot generate Case Reference.  There is no Internal Reference Format rule that matches the case.',
    					null, null, null, null, null)
  	RAISERROR(@sAlertXML, 14, 1)
  	Set @nErrorCode = @@ERROR
End

-- Get the Segments that make up the IRN Format rule for the Criteria.

If @nErrorCode=0
Begin
 	set @sSQLString="
 	select  @nSEGMENT1CODE        =SEGMENT1CODE,
         	@nSEGMENT2CODE        =SEGMENT2CODE,
         	@nSEGMENT3CODE        =SEGMENT3CODE,
         	@nSEGMENT4CODE        =SEGMENT4CODE,
         	@nSEGMENT5CODE        =SEGMENT5CODE,
         	@nSEGMENT6CODE        =SEGMENT6CODE,
         	@nSEGMENT7CODE        =SEGMENT7CODE,
         	@nSEGMENT8CODE        =SEGMENT8CODE,
         	@nSEGMENT9CODE        =SEGMENT9CODE,
         	@nINSTRUCTORFLAG  =INSTRUCTORFLAG,
         	@nOWNERFLAG       =OWNERFLAG,
         	@nSTAFFFLAG       =STAFFFLAG,
         	@nFAMILYFLAG      =FAMILYFLAG
	from IRFORMAT
 	where CRITERIANO=@nCriteriaNo"
 
 	exec @nErrorCode=sp_executesql @sSQLString, 
		      		N'@nSEGMENT1CODE	int OUTPUT,
            			  @nSEGMENT2CODE	int OUTPUT,
            			  @nSEGMENT3CODE	int OUTPUT,
            			  @nSEGMENT4CODE	int OUTPUT,
            			  @nSEGMENT5CODE	int OUTPUT,
            			  @nSEGMENT6CODE	int OUTPUT,
            			  @nSEGMENT7CODE	int OUTPUT,
            			  @nSEGMENT8CODE	int OUTPUT,
            			  @nSEGMENT9CODE	int OUTPUT,
            			  @nINSTRUCTORFLAG      decimal(1,0) OUTPUT,
           			  @nOWNERFLAG           decimal(1,0) OUTPUT,
            			  @nSTAFFFLAG           decimal(1,0) OUTPUT,
            			  @nFAMILYFLAG          decimal(1,0) OUTPUT,
     		        	  @nCriteriaNo  	int',
      				  @nSEGMENT1CODE            =@nSEGMENT1CODE OUTPUT,
            			  @nSEGMENT2CODE            =@nSEGMENT2CODE OUTPUT,
            			  @nSEGMENT3CODE            =@nSEGMENT3CODE OUTPUT,
	            		  @nSEGMENT4CODE            =@nSEGMENT4CODE OUTPUT,
	            		  @nSEGMENT5CODE            =@nSEGMENT5CODE OUTPUT,
	            		  @nSEGMENT6CODE            =@nSEGMENT6CODE OUTPUT,
	            		  @nSEGMENT7CODE            =@nSEGMENT7CODE OUTPUT,
	            		  @nSEGMENT8CODE            =@nSEGMENT8CODE OUTPUT,
	            		  @nSEGMENT9CODE            =@nSEGMENT9CODE OUTPUT,
	            		  @nINSTRUCTORFLAG      =@nINSTRUCTORFLAG OUTPUT,
	            		  @nOWNERFLAG           =@nOWNERFLAG OUTPUT,
	            		  @nSTAFFFLAG           =@nSTAFFFLAG OUTPUT,
				  @nFAMILYFLAG          =@nFAMILYFLAG,	
	            		  @nCriteriaNo          =@nCriteriaNo
end

-- Load the segments into a table variable to allow further validation of the
-- logical correctness of the Segments' values. 

if @nErrorCode=0
Begin
	insert into #TempSegment(SEGMENTCODE)
 	select @nSEGMENT1CODE where @nSEGMENT1CODE is not null
 	UNION ALL 
 	select @nSEGMENT2CODE where @nSEGMENT2CODE is not null
 	UNION ALL 
 	select @nSEGMENT3CODE where @nSEGMENT3CODE is not null
 	UNION ALL 
 	select @nSEGMENT4CODE where @nSEGMENT4CODE is not null
 	UNION ALL 
 	select @nSEGMENT5CODE where @nSEGMENT5CODE is not null
 	UNION ALL
 	select @nSEGMENT6CODE where @nSEGMENT6CODE is not null
 	UNION ALL
 	select @nSEGMENT7CODE where @nSEGMENT7CODE is not null
 	UNION ALL
 	select @nSEGMENT8CODE where @nSEGMENT8CODE is not null
 	UNION ALL
 	select @nSEGMENT9CODE where @nSEGMENT9CODE is not null

	-- Get the number of rows in the #TempSegment to use to loop through the table fields. 	

	Set @nSegmentsCount = @@ROWCOUNT
	
	Update #TempSegment 
 	Set ISSEQUENCE   = 1
 	where SEGMENTCODE IN (@n00Ascending, @n01Ascending,@n1Ascending, @nNul1Ascending, @nAAscending, @nNulAAscending, @nCheckDigit, @nRomanNumeral, @nZDescending,
			      @n000Ascending, @n001Ascending, @n0000Ascending, @n0001Ascending)
 
 	Update #TempSegment 
 	Set ISSTEM       = 1,
	    @bNewStem	 = CASE WHEN(SEGMENTCODE=@nNewNumericStem) THEN 1 ELSE @bNewStem END	
 	where SEGMENTCODE IN (@nNewNumericStem, @nNumericStem, @nParentStem, @nParentStemSequence,@nTextStem) 

-- Delimiters are only one char in length
	Update #TempSegment
 	Set ISDELIMITER	= 1
 	where not ISSTEM = 1
	and not	ISSEQUENCE = 1
	and SEGMENTCODE IN (SELECT TABLECODE FROM TABLECODES WHERE TABLETYPE = @nDelimiterTableType)

	Update #TempSegment 
 	Set ISNULLSEQUENCE	= 1
 	where SEGMENTCODE IN ( @nNul1Ascending, @nNulAAscending )	
End

-- If there are more than 1 Stem type of segment then raise an error.

If  @nErrorCode = 0
and (Select count(*) from #TempSegment where ISSTEM = 1 )>1 
Begin
 	Set @sAlertXML = dbo.fn_GetAlertXML( 'CS32', 'Cannot generate Case Reference.  An Internal Reference Format rule may contain only one of the following options: New Numeric Stem, Numeric Stem, Parent Stem, Parent StemSequence, Text Stem.',
     					 null, null, null, null, null)
 	RAISERROR(@sAlertXML, 14, 1)
 	Set @nErrorCode = @@ERROR
End

-- If there are more more than 1 Sequence type of segment then raise an error.
  
If @nErrorCode = 0
and (Select count(*) from #TempSegment where ISSEQUENCE = 1 )>1 
Begin
 	Set @sAlertXML = dbo.fn_GetAlertXML( 'CS33', 'Cannot generate Case Reference.  An Internal Reference Format rule may contain only one Sequence option.',
     					 null, null, null, null, null)
 	RAISERROR(@sAlertXML, 14, 1)
 	Set @nErrorCode = @@ERROR
End

-- If there are any Segments that require details from the Parent Case or a Numeric Stem Segment then get all of 
-- this information from the Parent in a single Select from the database.

If @nErrorCode=0
and exists(Select * from #TempSegment where SEGMENTCODE in (@nParentStem, @nParentSequence, @nParentStemSequence, @nParentCountry, @nParentStemOffice) or SEGMENTCODE in (@nNumericStem, @nTextStem))
Begin 
 	If @pnParentCaseKey is NULL
 	Begin
 		Set @nRowCount=0
 	End
 	Else Begin
  		Set @sSQLString="
	  		Select @sParentStem    = C.STEM,
	  		       @sParentCountry = C.COUNTRYCODE
	  		from CASES C
	 		where C.CASEID=@pnParentCaseKey"
 
  		exec @nErrorCode=sp_executesql @sSQLString, 
    			 		N'@sParentStem		nvarchar(30)	 OUTPUT,
       			  		  @sParentCountry 	nvarchar(3)	 OUTPUT,
      			   		  @pnParentCaseKey 	int',
       			   		  @sParentStem  	=@sParentStem    OUTPUT,
       			   		  @sParentCountry 	=@sParentCountry OUTPUT,
      			   		  @pnParentCaseKey      =@pnParentCaseKey
 
  		Set @nRowCount=@@ROWCOUNT
 	End
End

-- Load the Sequence number from the parent Case if it exists otherwise make the stem null. It is held in 
-- the portion of CASES.STEM (already extracted) after the tilde character (~) for the parent Case.

If @nErrorCode=0
and exists(Select * from #TempSegment where SEGMENTCODE = @nParentSequence )
Begin
	if @sParentStem is not null
	begin
	    --	If it is a Roman Numeral pattern 'Rxx' replace it with a Roman Numeral
	    if	charindex('~R',@sParentStem) > 0 and isnumeric( substring(@sParentStem,CHARINDEX('~R',@sParentStem)+2, 2)) = 1
		    Update #TempSegment
	 	    Set SEGMENTVALUE=dbo.fn_NumberToRoman( cast( substring(@sParentStem,CHARINDEX('~R',@sParentStem)+2, 2)as tinyint ) )
		    from #TempSegment
	 	    where SEGMENTCODE=@nParentSequence
	 	    and CHARINDEX('~R',@sParentStem)>0
	    else
--		    Update #TempSegment
--	 	    Set SEGMENTVALUE=substring(@sParentStem,CHARINDEX('~',@sParentStem)+1, CHARINDEX('?',@sParentStem )-CHARINDEX('~',@sParentStem)-1)
--		    from #TempSegment
--	 	    where SEGMENTCODE=@nParentSequence
--	 	    and CHARINDEX('~',@sParentStem)>0
		    If charindex('~',@sParentStem) > 0 and charindex('?',@sParentStem) > 0
		    Begin
			Update #TempSegment
    	 		Set SEGMENTVALUE=substring(@sParentStem,CHARINDEX('~',@sParentStem)+1, CHARINDEX('?',@sParentStem )-CHARINDEX('~',@sParentStem)-1)
			where SEGMENTCODE=@nParentSequence
		    End
		    Else if charindex('~',@sParentStem) > 0 and charindex('?',@sParentStem) = 0
		    Begin
			Update #TempSegment
    	 		Set SEGMENTVALUE=substring(@sParentStem,CHARINDEX('~',@sParentStem)+1, 11)
			where SEGMENTCODE=@nParentSequence
		    End

	    -- if parent has no sequence, set the sequence segment to blank.
	   if (select SEGMENTVALUE from #TempSegment where SEGMENTCODE=@nParentSequence) is null
	   begin
		    Update #TempSegment
		    Set SEGMENTVALUE=''
		    from #TempSegment
		    where SEGMENTCODE=@nParentSequence
	   end 
	end
	else
	begin
	    -- if parent has no STEM at all, set the sequence segment to blank.
    		    Update #TempSegment
	 	    Set SEGMENTVALUE=''
		    from #TempSegment
	 	    where SEGMENTCODE=@nParentSequence
	end
End

-- If both the Stem and Sequence are required from the Parent then load this.

If @nErrorCode=0
and exists(Select * from #TempSegment where SEGMENTCODE = @nParentStemSequence )
Begin
	if @sParentStem is not null
	begin
	    --	If it is a Roman Numeral pattern 'Rxx' replace it with a Roman Numeral
	    if	charindex('~R',@sParentStem) > 0 and isnumeric( substring(@sParentStem,CHARINDEX('~R',@sParentStem)+2, 2)) = 1
		    Update #TempSegment
	 	    Set SEGMENTVALUE=REPLACE( substring(@sParentStem,0 , CHARINDEX('~R',@sParentStem)+1 ) + dbo.fn_NumberToRoman( cast( substring(@sParentStem,CHARINDEX('~R',@sParentStem)+2, 2)as tinyint ) ), '~', '')
	 	    from #TempSegment
	 	    where SEGMENTCODE=@nParentStemSequence
		    and CHARINDEX('~',@sParentStem)<>1 
		    and @sParentStem is not null
	    else
			if CHARINDEX('?',REPLACE(@sParentStem, '~', '')) > 0
			Begin
				Update #TempSegment
	 			Set SEGMENTVALUE=LEFT(REPLACE(@sParentStem, '~', ''),CHARINDEX('?',REPLACE(@sParentStem, '~', ''))-1)
	 			from #TempSegment
	 			where SEGMENTCODE=@nParentStemSequence
				and CHARINDEX('~',@sParentStem)<>1 
				and @sParentStem is not null
			End
		    Else
		    Begin
				Update #TempSegment
	 			Set SEGMENTVALUE=REPLACE(@sParentStem, '~', '')
	 			from #TempSegment
	 			where SEGMENTCODE=@nParentStemSequence
				and CHARINDEX('~',@sParentStem)<>1 
				and @sParentStem is not null
			End
	end
	else
	begin
	    -- if parent has no STEM at all, set the ParentStemSequence segment to blank.
    		    Update #TempSegment
	 	    Set SEGMENTVALUE=''
		    from #TempSegment
	 	    where SEGMENTCODE=@nParentStemSequence
	end
End

-- Get all of this information from the CASES in a single Select from the database.

If @nErrorCode=0
and exists(Select * from #TempSegment where SEGMENTCODE in (@nCountry, @nParentCountry, @nProperty, @nFamily, @nNumericStem, @nTextStem, @nOfficeIRNCode, @nParentStemOffice) )
Begin
 	Set @sSQLString="
	  	Select @sCaseStem		= C.STEM,
	  	       @sCaseCountry 		= C.COUNTRYCODE,
		       @sCaseFamily  		= C.FAMILY,
		       @sCasePropertyType	= C.PROPERTYTYPE,
			   @sCaseOfficeIRNCode	= O.IRNCODE
	  	from CASES C
		left join OFFICE O on (O.OFFICEID = C.OFFICEID)
	 	where C.CASEID=@pnCaseKey"
 
	exec @nErrorCode=sp_executesql @sSQLString, 
		 		N'@sCaseStem		nvarchar(30)		OUTPUT,
				  @sCaseCountry 	nvarchar(3)		OUTPUT,
				  @sCaseFamily		nvarchar(20)		OUTPUT,
				  @sCasePropertyType	nvarchar(1)		OUTPUT,
				  @sCaseOfficeIRNCode	nvarchar(3)		OUTPUT,
				  @pnCaseKey		int',
		   		  @sCaseStem		= @sCaseStem		OUTPUT,
				  @sCaseCountry 	= @sCaseCountry 	OUTPUT,
				  @sCaseFamily		= @sCaseFamily		OUTPUT,
				  @sCasePropertyType	= @sCasePropertyType	OUTPUT,
				  @sCaseOfficeIRNCode	= @sCaseOfficeIRNCode	OUTPUT,
		   		  @pnCaseKey 		= @pnCaseKey
                                  
End

If @nErrorCode=0
Begin

	-- For "Numeric Stem"     : @sCaseStem, or @sParentStem, or @sNewNumericStem.  
	-- For "Parent Stem"      :		  @sParentStem, or  @sNewNumericStem. 
	-- For "New Numeric Stem" :			            @sNewNumericStem.					         			  						     	
	-- For "Text Stem"	  : @sCaseStem, or @sParentStem
	
	-- The STEM should exclude any characters from the tilde (~) onwards. Concatenate the
	-- tilde character onto the end of the Numeric Stem to cater for those entries that 
	-- do not have a tilde character embedded. 	

	-- Use 'UPPER' function to ensure that any Text Stem will be recorded in
	-- upper cases on the Cases.Stem:
	If charindex('~',@sCaseStem) > 0
	Begin
	    Update #TempSegment
	    Set SEGMENTVALUE=left(@sCaseStem,CHARINDEX('~',@sCaseStem)-1)
	    where SEGMENTCODE in (@nNumericStem,@nTextStem)
	End
	Else if charindex('?',@sCaseStem) > 0 and charindex('~',@sCaseStem) = 0
	Begin
	    Update #TempSegment
	    Set SEGMENTVALUE=left(@sCaseStem,CHARINDEX('?',@sCaseStem)-1)
	    where SEGMENTCODE in (@nNumericStem,@nTextStem)
	End
	Else if charindex('~',@sCaseStem) = 0 and charindex('?',@sCaseStem) = 0
	Begin
	    Update #TempSegment
	    Set SEGMENTVALUE=@sCaseStem
	    where SEGMENTCODE in (@nNumericStem,@nTextStem)
	End

--	Update #TempSegment
-- 	Set SEGMENTVALUE=substring(@sCaseStem,CHARINDEX('~',@sCaseStem)+1, CHARINDEX('?',@sCaseStem )-CHARINDEX('~',@sCaseStem)-1)
-- 	from #TempSegment
-- 	where SEGMENTCODE in (@nNumericStem,@nTextStem)
-- 	and CHARINDEX('~',@sCaseStem + '~')>1

	-- Use 'UPPER' function to ensure that any Text Stem will be recorded in
	-- upper cases on the Cases.Stem:

	If charindex('~',@sParentStem) > 0
	Begin
	    Update #TempSegment
	    Set SEGMENTVALUE=left(@sParentStem,CHARINDEX('~',@sParentStem)-1)
	    where SEGMENTCODE in (@nNumericStem, @nParentStem, @nTextStem)
	    and SEGMENTVALUE is null
	End
	Else if charindex('?',@sParentStem) > 0 and charindex('~',@sParentStem) = 0
	Begin
	    Update #TempSegment
	    Set SEGMENTVALUE=left(@sParentStem,CHARINDEX('?',@sParentStem)-1)
	    where SEGMENTCODE in (@nNumericStem, @nParentStem, @nTextStem)
	    and SEGMENTVALUE is null
	End
	Else if charindex('~',@sParentStem) = 0 and charindex('?',@sParentStem) = 0
	Begin
	    Update #TempSegment
	    Set SEGMENTVALUE=@sParentStem
	    where SEGMENTCODE in (@nNumericStem, @nParentStem, @nTextStem)
	    and SEGMENTVALUE is null
	End

--	Update #TempSegment
-- 	Set SEGMENTVALUE=substring(@sParentStem,CHARINDEX('~',@sParentStem)+1, CHARINDEX('?',@sParentStem )-CHARINDEX('~',@sParentStem)-1)
-- 	from #TempSegment
-- 	where SEGMENTCODE in (@nNumericStem, @nParentStem, @nTextStem)
-- 	and CHARINDEX('~',@sParentStem + '~')>1	
--	and SEGMENTVALUE is null


StemProcessing:

 	If exists (Select * 
		   from #TempSegment 
		   where SEGMENTCODE in (@nNumericStem, @nParentStem, @nNewNumericStem)
		   and SEGMENTVALUE is null )
	or @bIncrementStemAgain=1	-- RFC10700
	Begin
		Exec @nErrorCode = cs_GenerateNumericStem 
					@psNewNumericStem 	= @sNewNumericStem    OUTPUT,
       	  				@pnUserIdentityId 	= @pnUserIdentityId,
               				@pnCaseKey 		= @pnCaseKey 
        
	End
	
	-- Load the generated Numeric Stem.	

	If @nErrorCode = 0  
	Begin	
		Update #TempSegment
 		Set SEGMENTVALUE=@sNewNumericStem
 		from #TempSegment
 		where SEGMENTCODE in (@nNumericStem, @nParentStem, @nNewNumericStem)
		and SEGMENTVALUE is null
		 or @bIncrementStemAgain=1	-- RFC10700
	End
 			
End

If @nErrorCode = 0
Begin
	-- If we have a Parent Country Segment load the Parent Country from the Parent Case if it exists otherwise load the Country from the Case. It is held in 
	-- the portion of CASES.COUNTRYCODE (already extracted) for the Case and the Parent Case.
	
	Update #TempSegment
	Set SEGMENTVALUE=coalesce(@sParentCountry, @sCaseCountry)
  	where SEGMENTCODE=@nParentCountry

	-- If we have a Country Segment load the Country from the Case. It is held in 
	-- the portion of CASES.COUNTRYCODE (already extracted) for the Case.
 
	Update #TempSegment 
	Set SEGMENTVALUE=@sCaseCountry
  	where SEGMENTCODE=@nCountry
 
	-- If we have a Family Segment load the Family from the Case. It is held in 
	-- the portion of CASES.FAMILY (already extracted) for the Case.

	Update #TempSegment 
	Set SEGMENTVALUE=@sCaseFamily
  	where SEGMENTCODE=@nFamily
 
	-- If we have a Property Segment load the PropertyType from the Case. It is held in 
	-- the portion of CASES.PROPERTYTYPE (already extracted) for the Case.

	Update #TempSegment 
	Set SEGMENTVALUE=@sCasePropertyType
  	where SEGMENTCODE=@nProperty

	-- If we have a Office IRN Code Segment load the @sCaseOfficeIRNCode for the Case. It is held in 
	-- the portion of OFFICE.IRNCODE (already extracted) for the Case.
	Update #TempSegment 
	Set SEGMENTVALUE=@sCaseOfficeIRNCode
  	where SEGMENTCODE=@nOfficeIRNCode

	-- If we have a Parent Stem Office IRN Code Segment load the Parent Office Code for the Case. It is held in 
	-- the portion of OFFICE.STEM for the Parent Case. Otherwise load the current Office Code
	If charindex('?',@sParentStem) > 0
	Begin
	    Select @sParentCaseOfficeIRNCode = right(@sParentStem, len(@sParentStem)-charindex('?', @sParentStem))
	End

	Update #TempSegment 
	Set SEGMENTVALUE=isnull(@sParentCaseOfficeIRNCode,@sCaseOfficeIRNCode)
  	where SEGMENTCODE=@nParentStemOffice
End 

-- If there are any Segments that require details from the Instructor then get all of 
-- this information from the Case in a single Select from the database.

If @nErrorCode=0
and exists(Select * from #TempSegment where SEGMENTCODE in (@nInstructor, @nInstructorPrefix, @nInstructorSequence))

Begin
 	Set @sSQLString="
	  	Select @nInstructorNameKey	= N.NAMENO,
		       @sInstructorNameCode	= N.NAMECODE,
		       @sInstructorPrefix	= N.INSTRUCTORPREFIX,
		       @nInstructorCaseSequence	= N.CASESEQUENCE    
	   	from CASENAME CN
		join NAME N on (N.NAMENO = CN.NAMENO)
		where CN.CASEID=@pnCaseKey
		and CN.NAMETYPE='I'	
	   	and (CN.EXPIRYDATE IS NULL OR CN.EXPIRYDATE > GETDATE())
	   	and CN.SEQUENCE= 
	    			(Select MIN(CN1.SEQUENCE)
	      			 from CASENAME CN1
	     			 where CN1.CASEID=CN.CASEID
	     			 and CN1.NAMETYPE=CN.NAMETYPE
	      			 and CN1.EXPIRYDATE IS NULL OR CN1.EXPIRYDATE > GETDATE())"
 
 	exec @nErrorCode=sp_executesql @sSQLString, 
    		 		N'@nInstructorNameKey		int			OUTPUT,
				  @sInstructorNameCode		nvarchar(10)	 	OUTPUT,
       		  		  @sInstructorPrefix 		nvarchar(10)	 	OUTPUT,
				  @nInstructorCaseSequence	smallint	 	OUTPUT,
      		   		  @pnCaseKey 			int',
				  @nInstructorNameKey		=@nInstructorNameKey	 OUTPUT,
       		   		  @sInstructorNameCode  	=@sInstructorNameCode    OUTPUT,
       		   		  @sInstructorPrefix 		=@sInstructorPrefix	 OUTPUT,
				  @nInstructorCaseSequence 	=@nInstructorCaseSequence OUTPUT,
      		   		  @pnCaseKey      		=@pnCaseKey

	If @nErrorCode = 0
	Begin
		-- If there is an 'Instructor' Segment then load this. 
		Update #TempSegment 
		Set SEGMENTVALUE=@sInstructorNameCode
  		where SEGMENTCODE=@nInstructor

		-- If there is an 'Instructor Prefix' Segment then load this. 
		Update #TempSegment 
		Set SEGMENTVALUE=@sInstructorPrefix
  		where SEGMENTCODE=@nInstructorPrefix
	End

	-- If there is an 'Instructor Sequence' segment, there is an Instructor, but the
	-- N.CASESEQUENCE is null, default the number from the Instructor Sequence SiteControl.
	-- If still null, set it to 1.
 
	If @nErrorCode = 0 
	and exists(select * from #TempSegment where SEGMENTCODE = @nInstructorSequence) 
	and @nInstructorCaseSequence is null
	and @nInstructorNameKey is not null
	Begin
		Set @sSQLString="
			Select @nInstructorCaseSequence	= COALESCE(COLINTEGER, 1)    
   			from SITECONTROL  
			where CONTROLID = 'Instructor Sequence'"
					
		exec @nErrorCode=sp_executesql @sSQLString, 
    		 			N'@nInstructorCaseSequence	smallint	 	  OUTPUT',
      		   			  @nInstructorCaseSequence 	=@nInstructorCaseSequence OUTPUT
	
	End 

	-- If there is an 'Instructor Sequence' Segment then load this. Leading zeroes are
	-- added to ensure that Sequence is at least 3 characters long, but it may be longer.  	
      		   		  				
	If @nErrorCode = 0	
	Begin
		Update #TempSegment 
		Set SEGMENTVALUE=CASE WHEN LEN(@nInstructorCaseSequence)<3 THEN REPLICATE('0',(3 - LEN(@nInstructorCaseSequence))) + CAST(@nInstructorCaseSequence AS NVARCHAR(2)) 
	       			      ELSE CAST(@nInstructorCaseSequence AS NVARCHAR(12))
	  		         END
  		where SEGMENTCODE=@nInstructorSequence
	End
	
End

-- If we have a Owner Segment load the NameCode from the Name. It is held in 
-- the portion of NAME.NAMECODE for the Case.

If @nErrorCode=0
and exists(Select * from #TempSegment where SEGMENTCODE = @nOwner)
Begin
 	Set @sSQLString="
  		Select @sOwnerNameCode = N.NAMECODE  
    		from CASENAME CN
    		join NAME N on (N.NAMENO = CN.NAMENO)
    		where CN.CASEID = @pnCaseKey
    		and CN.NAMETYPE = 'O'
   	 	and (CN.EXPIRYDATE IS NULL OR CN.EXPIRYDATE > GETDATE())
    		and CN.SEQUENCE = 
     				(Select MIN(CN1.SEQUENCE)
       			 	from CASENAME CN1
      			 	where CN1.CASEID = CN.CASEID
      			 	and CN1.NAMETYPE = CN.NAMETYPE
       			 	and CN1.EXPIRYDATE IS NULL OR CN1.EXPIRYDATE > GETDATE())"
 
 	exec @nErrorCode=sp_executesql @sSQLString, 
    		 		N'@sOwnerNameCode	nvarchar(12)	 OUTPUT,
       		  		  @pnCaseKey 		int',
       		   		  @sOwnerNameCode  	=@sOwnerNameCode OUTPUT,
       		   		  @pnCaseKey      =@pnCaseKey

	If @nErrorCode = 0
	Begin
		Update #TempSegment 
		Set SEGMENTVALUE=@sOwnerNameCode
  		where SEGMENTCODE=@nOwner
	End 
 
End

-- If there are any Segments that require details from the Staff then get the NameKey and the NameCode.

If @nErrorCode=0
and exists(Select * from #TempSegment where SEGMENTCODE in (@nStaff, @nStaffOffice))
Begin
 	Set @sSQLString="
		Select @nStaffNameKey	= CN.NAMENO, 
		       @sStaffNameCode	= N.NAMECODE	 
    		from CASENAME CN
		join NAME N on (N.NAMENO=CN.NAMENO)
    		where CN.CASEID = @pnCaseKey
    		and CN.NAMETYPE = 'EMP'
    		and (CN.EXPIRYDATE IS NULL OR CN.EXPIRYDATE > GETDATE())
    		and CN.SEQUENCE = 
     				(Select MIN(CN1.SEQUENCE)
       				 from CASENAME CN1
      				 where CN1.CASEID = CN.CASEID
      				 and CN1.NAMETYPE = CN.NAMETYPE
      				 and CN1.EXPIRYDATE IS NULL OR CN1.EXPIRYDATE > GETDATE())"
 
 	exec @nErrorCode=sp_executesql @sSQLString, 
    		 	      N'@nStaffNameKey		int	 	  OUTPUT,
				@sStaffNameCode		nvarchar(10)	  OUTPUT,
       			  	@pnCaseKey	 	int',
       			   	@nStaffNameKey  		=@nStaffNameKey    OUTPUT,
				@sStaffNameCode  	=@sStaffNameCode   OUTPUT,
       			   	@pnCaseKey      	=@pnCaseKey
 
  	-- If we have a Staff Segment load the NameCode from the Name. It is held in 
	-- the portion of NAME.NAMECODE(already extracted) for the Case.		

	If @nErrorCode = 0
	Begin
		Update #TempSegment 
		Set SEGMENTVALUE=@sStaffNameCode
  		where SEGMENTCODE=@nStaff
	End 
 
	-- If we have a Staff Office Segment load the UserCode for the Office the responsible
	-- staff member belongs to. It is held in the portion of OFFICE.USERCODE for the Case.

	If @nErrorCode=0
	and exists(Select * from #TempSegment where SEGMENTCODE = @nStaffOffice)
	Begin
 		Set @sSQLString="
	  		Select @sOfficeUserCode	= O.USERCODE
	     		from TABLEATTRIBUTES TA
	     		join OFFICE O on (O.OFFICEID = TA.TABLECODE)
	     		where TA.PARENTTABLE = 'NAME'
	     		and TA.GENERICKEY = CAST(@nStaffNameKey as nvarchar(20)) 
	     		and TA.TABLETYPE = 44
	     		and TA.TABLECODE = 
	      				(Select MIN(TABLECODE)
	       				 from TABLEATTRIBUTES TA2
	       				 where TA2.PARENTTABLE = TA.PARENTTABLE
	       				 and TA2.GENERICKEY = TA.GENERICKEY
	       				 and TA2.TABLETYPE = TA.TABLETYPE)"
		
 
	 	exec @nErrorCode=sp_executesql @sSQLString, 
	    		 		N'@sOfficeUserCode	nvarchar(12)	 OUTPUT,
	       		  		  @nStaffNameKey		int',
	       		   		  @sOfficeUserCode  	=@sOfficeUserCode OUTPUT,
	       		   		  @nStaffNameKey      	=@nStaffNameKey

		If @nErrorCode = 0
		Begin
			Update #TempSegment 
			Set SEGMENTVALUE=@sOfficeUserCode
	  		where SEGMENTCODE=@nStaffOffice
		End 
	 
	End 
End

--Delimiter segment.

-- Special code for Delimiter = ' '.
If @nErrorCode = 0
Begin
  	Update #TempSegment 
	Set SEGMENTVALUE = ' '
   	where SEGMENTCODE = @nSpace
        and SEGMENTVALUE is null
End
 
If @nErrorCode = 0
Begin
  	Update #TempSegment
	Set SEGMENTVALUE = TC.DESCRIPTION
	from #TempSegment 
	join TABLECODES TC on (TC.TABLECODE = SEGMENTCODE)
	where TC.TABLETYPE = @nDelimiterTableType
	and TC.TABLECODE != @nSpace
	and SEGMENTVALUE IS NULL
End
 
-- If we have a Sequence Segment generate the next Sequence according to the type of request.
   
If @nErrorCode = 0
and exists(Select * from #TempSegment where ISSEQUENCE = 1 ) 
Begin
	-- Assemble the PartialCaseReference from all of the Segments, 
	-- but substituting '%' for the Sequence to be generated.
	-- Supress delimiters if a null+ sequence is used. 10914
	if exists ( select * from #TempSegment where ISNULLSEQUENCE = 1 )
		Select	@sPartialCaseReference = @sPartialCaseReference + 
						case when(ISDELIMITER=0) 
							then case when(ISNULLSEQUENCE=1) 
								then case when(SEGMENTVALUE is not null
									    or @sDelimiter between '0' and '9'
									    or @sDelimiter between 'A' and 'Z')
									then @sDelimiter 
									else null 
								     end
								else @sDelimiter 
							     end + 
							    case when(ISSEQUENCE=1) 
								then '%' 
								else SEGMENTVALUE 
							    end
							else null 
						end,
			@sDelimiter = 	case when(ISDELIMITER=1) 
						then @sDelimiter + SEGMENTVALUE
						else NULL 
					end
		from #TempSegment
		order by SEGMENTNO
	else
		Select @sPartialCaseReference = @sPartialCaseReference +CASE WHEN ISSEQUENCE = 1 THEN '%' ELSE SEGMENTVALUE END
		from #TempSegment
		order by SEGMENTNO


/****
	Set @nCount = 1
  	While @nCount <= @nSegmentsCount
  	Begin
   		Set @sPartialCaseReference = @sPartialCaseReference +  (Select CASE WHEN ISSEQUENCE = 1 THEN '%' 
           									    ELSE SEGMENTVALUE  
          						   		       END 
             					    			from #TempSegment 
						    			where SEGMENTNO = @nCount)
   		Set @nCount = @nCount + 1 
  	End
****/
	-- Get the Sequence Type to tell the cs_GenerateNextSequence which Sequence Type to generate.	

	Select @nSequenceType = SEGMENTCODE 
	from #TempSegment
	where ISSEQUENCE = 1 
  	
	-- If we have a Check Digit Segment derive it as fn_GetCheckDigit(PartialCaseReference).
	-- For the Check Digit Segment '%' needs to be replaced by '' in @sPartialCaseReference.   
 
 	Update #TempSegment 
	Set SEGMENTVALUE = dbo.fn_GetCheckDigit(REPLACE(@sPartialCaseReference, '%', ''))
    	where SEGMENTCODE = @nCheckDigit
  		
	-- If there is a "Sequence" segment which is not "Check Digit" then the next Sequence
	-- is derived as an output parameter of the cs_GenerateNextSequence according to the
	-- type of request. 
	
	If (Select SEGMENTVALUE from #TempSegment where ISSEQUENCE = 1) is null
	Begin
		-- Load Stem segment value into the @sStemSegment.
		If @bIncrementStemAgain=1
			Set @sStemSegment=NULL			-- RFC10700
		Else
			Select @sStemSegment = SEGMENTVALUE
			from #TempSegment
			where ISSTEM = 1
		
		Exec @nErrorCode = cs_GenerateNextSequence 
					@psGeneratedSequence 	= @sGeneratedSequence OUTPUT,
					@psRomanNumeral 	= @sRomanNumeral      OUTPUT,
					@pnUserIdentityId 	= @pnUserIdentityId,	
	       	  			@psPartialCaseReference	= @sPartialCaseReference,
					@pnSequenceType		= @nSequenceType,
					@psStemSegment		= @sStemSegment
	               				
		If @nErrorCode = 0
		Begin	
			Update #TempSegment 
			Set SEGMENTVALUE = @sGeneratedSequence,
			    ROMANVALUE   = @sRomanNumeral
	    		where SEGMENTCODE = @nSequenceType
		End
	End 

End 

-----------------------------------------------------------------
-----------------------------------------------------------------
-- U S E R  D E F I N E D  B R E A K O U T  C O D E

-----------------------------------------------------
-- RFC28144
-- Provide the ability for firms to define additional
-- logic for the generation of the Case Reference.
-----------------------------------------------------
-- 
-- Rules for user defined stored procedure :
-- 1. Name of procedure in SITECONTROL 'Case Reference Procedure'
-- 2. Input Parameters
--	@pnCaseKey		INT,
--	@pnParentCaseKey	INT = NULL, 
--	@pnCriteriaNo		INT = NULL, 
-- 3. Output Parameters
--	@psCaseReference	nvarchar(30) = NULL OUTPUT
-- 4. Procedure may access and update the temporary
--    table #TempSegment created within this procedure. 
--    The contents of the temporary table will then be used
--    to construct the Case Reference.
-- 5. The output parameter @psCaseReference may optionally be
--    used to return the fully constructed Case Reference.
-----------------------------------------------------------------
-----------------------------------------------------------------
If @nErrorCode=0
Begin
	---------------------------------------------
	-- Get the name of the optional user defined
	-- stored procedure to provide any extended
	-- logic for the generation of Case Reference
	---------------------------------------------
	Select @sUserProcedure=COLCHARACTER
	from SITECONTROL S
	join INFORMATION_SCHEMA.ROUTINES R on (R.ROUTINE_NAME=S.COLCHARACTER
					   and R.ROUTINE_TYPE='PROCEDURE')
	where CONTROLID='Case Reference Procedure'
	
	Set @nErrorCode=@@Error
End

If  @sUserProcedure is not null
and @nErrorCode=0
Begin
	Set @sSQLString='Exec '+@sUserProcedure+' '
	+convert(varchar,@pnCaseKey)+','
	+isnull(convert(varchar,@pnParentCaseKey) , 'NULL')+','
	+isnull(convert(varchar,@nCriteriaNo), 'NULL')+','
	+ '@psCaseReference		OUTPUT'

	Exec @nErrorCode=sp_executesql @sSQLString,
					N'@psCaseReference	nvarchar(30)		OUTPUT',
					  @psCaseReference=@psCaseReference		OUTPUT
End

-- Validate Generated Case Reference.

-- Assemble Case Reference from all of the Segments if it
-- has not been provide by the User Defined Procedure.
If @nErrorCode=0
and @psCaseReference is not null
and @psCaseReference <> '<GENERATE REFERENCE>'
Begin
	Set @sCaseReference=@psCaseReference
End
Else If  @nErrorCode = 0
Begin
	-- Supress delimiters if a null+ sequence is used. 10914

	Set @sDelimiter = null

	if exists ( select * from #TempSegment where ISNULLSEQUENCE = 1 )
		Select	@sCaseReference = @sCaseReference + 
						case when(ISDELIMITER=0) 
							then case when(ISNULLSEQUENCE=1) 
								then case when(isnull(ROMANVALUE,SEGMENTVALUE) is not null
									    or @sDelimiter between '0' and '9'
									    or @sDelimiter between 'A' and 'Z')
									then @sDelimiter 
									else null 
								     end
								else @sDelimiter 
							     end + 
							     Case When(ROMANVALUE is not null)
								then ROMANVALUE
								else SEGMENTVALUE 
							     end
							else null 
						end,
			@sDelimiter = 	case when(ISDELIMITER=1) 
						then @sDelimiter + SEGMENTVALUE
						else NULL 
					end
		from #TempSegment
		order by SEGMENTNO
	else
		Select @sCaseReference=@sCaseReference+ CASE WHEN ROMANVALUE is not null 
								THEN ROMANVALUE
								ELSE SEGMENTVALUE 
							END
		from #TempSegment
		order by SEGMENTNO
/****
	Set @nCount = 1
  	While @nCount <= @nSegmentsCount
  	Begin
   		Set @sCaseReference = @sCaseReference + (Select isnull(ROMANVALUE,SEGMENTVALUE)
          						 from #TempSegment 
							 where SEGMENTNO = @nCount)
     
   		Set @nCount = @nCount + 1 
  	End
****/
End

-- If length of assembled Case Reference is greater than 30 then raise an error. 

If @nErrorCode = 0 
and LEN(@sCaseReference) > 30 
Begin
	Set @sAlertXML = dbo.fn_GetAlertXML('CS40', 'Generated Case Reference {0} exceeds maximum length of {1}.',
   					@sCaseReference, '30', null, null, null)
  	RAISERROR(@sAlertXML, 14, 1)
 	Set @nErrorCode = @@ERROR
End

-- If assembled Case Reference is already exists in Cases.IRN then raise an error. 

If @nErrorCode = 0
and exists(Select * from CASES where IRN = @sCaseReference and CASEID<>@pnCaseKey) 
Begin
	--------------------------------------
	-- RFC10700
	-- If the generated IRN already exists
	-- and the NewNumericSegment is in use
	-- then go back to StemProcessing to 
	-- generate the next available Stem
	--------------------------------------

	If  @bNewStem=1
	Begin
		Set @sCaseReference=null
		Set @bIncrementStemAgain=1
		Goto StemProcessing
	End
	Else Begin
		Set @sAlertXML = dbo.fn_GetAlertXML('CS5', 'Generated case reference {0} is already in use.',
   						@sCaseReference, null, null, null, null)
  		RAISERROR(@sAlertXML, 14, 1)
 		Set @nErrorCode = @@ERROR
	End
End

-- Update Case.

If @nErrorCode = 0
Begin
	-- Assemble Stem and Sequence excluding "Check Digit" Sequence generated by the 
	-- processing using the following formatting: <Stem>~<Sequence> and store them in 
	-- the @sCasesStem.
	
	Set @sCasesStem = (Select SEGMENTVALUE from #TempSegment where ISSTEM = 1)
        		  + '~' +
              		  (Select CASE WHEN ROMANVALUE is not NULL THEN 'R' ELSE NULL END + SEGMENTVALUE from #TempSegment where ISSEQUENCE = 1 and SEGMENTCODE <> @nCheckDigit)  
	
	-- if there is a parent sequence and the sequence part of the stem is null,
	-- put the parent sequence in the stem.
	If exists (select * from #TempSegment where SEGMENTCODE = @nParentSequence)
	Begin
	    Set @sCasesStem = @sCasesStem + 
	    CASE WHEN (RIGHT(@sCasesStem,1) = '~') THEN
		(select SEGMENTVALUE from #TempSegment where SEGMENTCODE = @nParentSequence)
	    END
	End

	-- If both Stem and Sequence not exist then set the @sCasesStem to null.
	-- If there is a "Stem" segment but there is no "Sequence" segment then cut off the
	-- '~' from the @sCasesStem. 
	
	Set @sCasesStem = CASE WHEN @sCasesStem = '~' 		THEN NULL 
			       WHEN RIGHT(@sCasesStem, 1) = '~'	THEN REPLACE(@sCasesStem, '~', '') 
		   	       ELSE @sCasesStem 
			  END

	-- If there is either a Office Code or Parent Office code make it part of the stem.
	If exists (select * from #TempSegment where SEGMENTCODE in (@nOfficeIRNCode,@nParentStemOffice)) and (@sParentCaseOfficeIRNCode <> '' or @sCaseOfficeIRNCode <> '')
	Begin
	    Set @sCasesStem = @sCasesStem + '?' + isnull(@sParentCaseOfficeIRNCode,@sCaseOfficeIRNCode)
	End
	
	-- Assign validated and converted to upper case @sCaseReference to @psCaseReference. 

	Set @psCaseReference = UPPER(@sCaseReference)
End

-- If length of assembled Case Stem is greater than 30 then raise an error. 

If @nErrorCode = 0
and LEN(@sCasesStem) > 30  
Begin
  	Set @sAlertXML = dbo.fn_GetAlertXML('CS41', 'Cannot generate Case Reference.  Stem information {0} exceeds maximum length of {1}.',
   					@sCasesStem, '30', null, null, null)
  	RAISERROR(@sAlertXML, 14, 1)
 	Set @nErrorCode = @@ERROR
End

-- Update the Cases.IRN for @pnCaseKey with the generated Case Reference 
-- Store any Stem or Sequence values (excluding Check Digit) generated by the processing 
-- on the Cases.Stem. 

If @nErrorCode = 0
Begin
	Set @sSQLString="
  		Update CASES 
		Set IRN = ltrim(rtrim(@psCaseReference)),
  		STEM = @sCasesStem
		where CASEID = @pnCaseKey"
 		 
  	exec @nErrorCode=sp_executesql @sSQLString, 
    			 	N'@psCaseReference	nvarchar(30),
				  @sCasesStem		nvarchar(30),
				  @pnCaseKey		int',
       			   	  @psCaseReference	=@psCaseReference,
				  @sCasesStem		=@sCasesStem,
				  @pnCaseKey      	=@pnCaseKey		
End

-- If there is an "Instructor Sequence" segment and there is an Instructor the Name must be 
-- updated with the next available number.

If @nErrorCode = 0
and exists(select * from #TempSegment where SEGMENTCODE = @nInstructorSequence)
and @nInstructorCaseSequence is not null  
Begin
	Set @sSQLString="
  		Update NAME
		Set CASESEQUENCE = @nInstructorCaseSequence + 1
		where NAMENO = @nInstructorNameKey"
 		 
  		exec @nErrorCode=sp_executesql @sSQLString, 
    			 		N'@nInstructorNameKey		int,
					  @nInstructorCaseSequence	smallint',
       			   		  @nInstructorNameKey      	=@nInstructorNameKey,
					  @nInstructorCaseSequence	=@nInstructorCaseSequence
	
	
End

Return @nErrorCode
GO

Grant execute on dbo.cs_ApplyGeneratedReference to public
GO
