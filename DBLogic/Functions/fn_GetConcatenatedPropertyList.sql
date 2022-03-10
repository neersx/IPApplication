-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedPropertyList
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedPropertyList') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetConcatenatedPropertyList'
	Drop function [dbo].[fn_GetConcatenatedPropertyList]
End
Print '**** Creating Function dbo.fn_GetConcatenatedPropertyList...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetConcatenatedPropertyList
(
		@pnCaseId		int,
		@psProperty		nvarchar(25),
		@psRelationOrType	nvarchar(5),
		@psSeparator		nvarchar(10), 
		@pdtToday		datetime
) 
RETURNS nvarchar(max)
AS
-- Function :	fn_GetConcatenatedPropertyList
-- VERSION :	2
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns the concatenated list of the property passed as parameter.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 23 Nov 2009	NG	RFC8098	1	Function created
-- 14 Apr 2011	MF	RFC10475 2	Change nvarchar(4000) to nvarchar(max)

Begin
	-- Get the Item with the lowest value from the delimited string
	Declare @sResult 	nvarchar(max)
	Declare @tblString	table (Result nvarchar(500) collate database_default NULL)

	Set @sResult = N''

	If @psProperty =  'NAMECOUNTRY'
	
	Begin
		Insert into @tblString (Result)
		Select C.COUNTRY
		FROM COUNTRY C 					
		Join ADDRESS A on (A.COUNTRYCODE = C.COUNTRYCODE)
		Join CASENAME CN on (CN.ADDRESSCODE = A.ADDRESSCODE)
		Where CN.CASEID  =@pnCaseId
		and  (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>@pdtToday)
		order by CN.SEQUENCE, CN.NAMENO

		Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
			from @tblString order by Result
	End
	
	Else if @psProperty =  'NAMESTATE'
	
	Begin
		Insert into @tblString (Result)
		Select S.STATENAME
		FROM STATE S 					
		Join ADDRESS A on (A.STATE = S.STATE)
		Join CASENAME CN on (CN.ADDRESSCODE = A.ADDRESSCODE)
		Where CN.CASEID  =@pnCaseId
		and  (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>@pdtToday)
		order by CN.SEQUENCE, CN.NAMENO
		
		Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
			from @tblString order by Result
	End
	
	Else if @psProperty = 'NAMEVATNO'
	
	Begin
		Insert into @tblString (Result)
		Select O.VATNO
		FROM ORGANISATION O	
		Join CASENAME CN on (CN.NAMENO = O.NAMENO)
		Where CN.CASEID  =@pnCaseId
		and  (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>@pdtToday)
		order by CN.SEQUENCE, CN.NAMENO

		Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
			from @tblString order by Result
	End

	Else if @psProperty = 'RELATEDCOUNTRY'
	
	Begin
		Insert into @tblString (Result)
		Select C.COUNTRY
		FROM COUNTRY C 					
		join RELATEDCASE RC on (RC.COUNTRYCODE = C.COUNTRYCODE)		
		Where RC.CASEID  =@pnCaseId
		and RC.RELATIONSHIP = @psRelationOrType
		order by RC.COUNTRYCODE
		
		Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
			from @tblString order by Result
	End

	Else if @psProperty = 'RELATEDDATE'
	
	Begin
		Insert into @tblString (Result)
		Select RC.PRIORITYDATE
		FROM RELATEDCASE RC		
		Where RC.CASEID  =@pnCaseId
		and RC.RELATIONSHIP = @psRelationOrType
		order by RC.PRIORITYDATE
		
		Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
			from @tblString order by Result
	End

	Else if @psProperty = 'RELATEDNUMBER'
	
	Begin
		Insert into @tblString (Result)
		Select RC.OFFICIALNUMBER
		FROM RELATEDCASE RC	
		Where RC.CASEID  =@pnCaseId
		and RC.RELATIONSHIP = @psRelationOrType
		order by RC.OFFICIALNUMBER
		
		Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
			from @tblString order by Result
	End

	Else if @psProperty = 'TEXT'
	
	Begin
		Insert into @tblString (Result)
		Select 	'Class:' + CT.CLASS + ',' + char(10)+
				'Language:' + cast(CT.LANGUAGE as nvarchar(20))+ ',' + char(10)+
				'Short Text:' + CT.SHORTTEXT + ',' + char(10)+
				'Long Text:' + cast(CT.TEXT as nvarchar(500))
		FROM CASETEXT CT	
		Where CT.CASEID  =@pnCaseId
		and CT.TEXTTYPE = @psRelationOrType
		order by CT.CLASS
		
		Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
			from @tblString order by Result
	End

	Else if @psProperty = 'NAMEALIAS'

	Begin
		Insert into @tblString (Result)	
		Select NA.ALIAS 					
		From NAMEALIAS NA
		Join CASENAME CN on (CN.NAMENO = NA.NAMENO)
		Join NAME N on (N.NAMENO=CN.NAMENO)
		Where CN.CASEID  =@pnCaseId
		and   NA.ALIASTYPE=@psRelationOrType
		and  (CN.EXPIRYDATE is null OR CN.EXPIRYDATE>@pdtToday)
		order by CN.SEQUENCE, CN.NAMENO
		
		Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
			from @tblString order by Result
	End
	
	Set @sResult = CASE WHEN @sResult = N'' THEN NULL ELSE @sResult END

	Return @sResult

End
GO

grant execute on dbo.fn_GetConcatenatedPropertyList to public
go
