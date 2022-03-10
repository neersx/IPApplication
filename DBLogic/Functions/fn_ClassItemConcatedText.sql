-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_ClassItemConcatedText
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_ClassItemConcatedText') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_ClassItemConcatedText'
	Drop function [dbo].[fn_ClassItemConcatedText]
End
Print '**** Creating Function dbo.fn_ClassItemConcatedText...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS OFF 
GO

CREATE FUNCTION [dbo].[fn_ClassItemConcatedText]
	(
		@pnCaseId    int,                                    
        @pnLanguage  int, 
        @psClass     nvarchar(20)
	)
Returns nvarchar(max)
-- FUNCTION :	fn_ClassItemConcatedText
-- VERSION :	1
-- DESCRIPTION:	Returns concatenated item texts for the given class.

-- Date		Who	Number	Version	Description
-- ====         ===	======	=======	===========
-- 05 OCT 2018  AV              1       Function created

AS 
BEGIN
	SET ANSI_NULLS ON
		   DECLARE @sResult nvarchar(max)
		   Declare @sCountryCode nvarchar(3)
		   Declare @sPropertyTypeCode nchar(1)
		   DECLARE @sDelimeter nvarchar(10)
		   SELECT @sDelimeter = COLCHARACTER FROM SITECONTROL WHERE CONTROLID ='Goods and Services Item Text Separator'

		   Select @sCountryCode = ISNULL(TM1.COUNTRYCODE,'ZZZ') , @sPropertyTypeCode = C.PROPERTYTYPE from CASES C 
			left JOIN TMCLASS TM1 on (C.PROPERTYTYPE = TM1.PROPERTYTYPE and C.COUNTRYCODE = TM1.COUNTRYCODE)
			where C.CASEID = @pnCaseId

		   ;WITH CLASSITEMTEXT(ITEMNO, DESCRIPTION, LANGUAGE, CLASS, CASEID, CLASSITEMID)
		   AS 
		   (SELECT CI.ITEMNO, CI.DESCRIPTION, CI.LANGUAGE, CI.CLASS, CCI.CASEID, CCI.CLASSITEMID
											FROM CLASSITEM CI 
											INNER JOIN CASECLASSITEM CCI ON CI.ID = CCI.CLASSITEMID
											INNER JOIN TMCLASS TC ON TC.CLASS =@psClass
											WHERE CI.CLASS = TC.ID AND CI.LANGUAGE = @pnLanguage AND CCI.CASEID = @pnCaseId
											 	  AND TC.PROPERTYTYPE = @sPropertyTypeCode AND TC.COUNTRYCODE = @sCountryCode)

		   SELECT @sResult = STUFF((SELECT DISTINCT ISNULL(@sDelimeter,';') + ISNULL(DESCRIPTION,'')
																	   FROM CLASSITEMTEXT b 
																	   WHERE B.CASEID = A.CASEID 
																	   FOR XML PATH('')), 1, 1, '')
																	   FROM CLASSITEMTEXT A
																	   GROUP BY CASEID,LANGUAGE

	RETURN @sResult
END

GO

grant execute on dbo.fn_ClassItemConcatedText to public
GO
