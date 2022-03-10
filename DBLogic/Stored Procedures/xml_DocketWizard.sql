-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_DocketWizard
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_DocketWizard]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_DocketWizard.'
	drop procedure dbo.xml_DocketWizard
	print '**** Creating procedure dbo.xml_DocketWizard...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

create PROCEDURE dbo.xml_DocketWizard (
		@psXMLCaseInfo			nvarchar(2000) )
AS

-- PROCEDURE :	xml_DocketWizard
-- VERSION :	3
-- SCOPE:	CPA Inprotech
-- DESCRIPTION:	Display additional information about a case from Docket Wizard screen
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	----	-------	----------------------------------------------- 
-- 12.11.04  	MB		1	Procedure created as part of SQA10074
-- 15 Dec 2008	MF	17136	2	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID	
-- 02 Nov 2015	vql	R53910	3	Adjust formatted names logic (DR-15543).

set nocount on
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode	int
declare @idoc 		int 	
declare @nCaseId	int

Set @ErrorCode = 0
If @ErrorCode = 0
Begin

	exec sp_xml_preparedocument	@idoc OUTPUT, @psXMLCaseInfo

	Select	@nCaseId = CaseId
		from	OPENXML (@idoc, '//CaseInfo',2)
		WITH (
			  CaseId	Int	'@ID/text()'	   
		     )	
		-- deallocate the xml document handle when finished.
	exec sp_xml_removedocument @idoc
	Select 1 AS TAG, 
	   	NULL AS PARENT,
		CASES.IRN AS [Case!1!IRN!element],
		CASES.LOCALCLASSES AS [Case!1!Classes!element],
		null as [GoodsServices!2!!element],
		null as [GoodsServices!2!Class],
		null as [GoodsServices!2!Language],
		null as [Inventor!3!!element],
		null as [FirstUseDate!4!!element],
		null as [CaseAttribute!5!Attribute],
		null as [CaseAttribute!5!Value],
		null as [InputParameter!6!!xml],
		null as [Owner!7!!element]
	from CASES 
	where CASES.CASEID =@nCaseId 
--Goods/Services Text
	UNION ALL
	Select  2 AS TAG, 
		1 AS PARENT,
		null,
		null,
		CASE 
			WHEN LONGFLAG =1 
			THEN TEXT
			ELSE SHORTTEXT
		END,
		CLASS,
		TABLECODES.DESCRIPTION,
		null,
		null,
		null,
		null,
		null,
		null
	from  CASETEXT left join TABLECODES 
			on (CASETEXT.LANGUAGE = TABLECODES.TABLECODE)
	where TEXTTYPE='G' and CASEID = @nCaseId

-- Inventors
	UNION ALL
	Select 
		3 AS TAG, 
		1 AS PARENT,
		null,
		null,
		null,
		null,
		null,
		dbo.fn_FormatNameUsingNameNo(NAMENO, 7101),
		null,
		null,
		null,
		null,
		null
	from CASENAME
	where NAMETYPE = 'J' and CASEID = @nCaseId

-- First Use Date
	UNION ALL
	select 
		4 AS TAG, 
		1 AS PARENT,
		null,
		null,
		null,
		null,
		null,
		null,
		convert (nvarchar, EVENTDATE, 1),
		null,
		null,
		null,
		null
	from CASEEVENT 
	where EVENTNO = (select COLINTEGER from SITECONTROL 
			where CONTROLID = 'First Use Event') 
		and 	CASEID =@nCaseId
-- Case Attribute
	UNION ALL 
	select	 	
		5 AS TAG, 
		1 AS PARENT,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		A.TABLENAME,
  		V.DESCRIPTION,
		null,
		null
 	from	TABLEATTRIBUTES T,  TABLETYPE A,  TABLECODES V
	where		T.PARENTTABLE = 'CASES' 
	    	and	T.GENERICKEY = CAST (@nCaseId as varchar)
	     	and	T.TABLETYPE = A.TABLETYPE
	     	and	T.TABLECODE = V.TABLECODE
	      	and	A.TABLETYPE = V.TABLETYPE 
		and 	A.TABLETYPE <> 44 

	UNION ALL 
	Select    
		5 AS TAG, 
		1 AS PARENT,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		A.TABLENAME,  
		O.DESCRIPTION,
		null,
		null             
	from    TABLEATTRIBUTES T,  TABLETYPE A,  OFFICE O	          
	where  T.PARENTTABLE = 'CASES'
		and  T.GENERICKEY = CAST (@nCaseId as varchar)
		and  T.TABLETYPE = A.TABLETYPE 	         
		and  T.TABLECODE = O.OFFICEID 
		and  A.TABLETYPE = 44 
	UNION ALL 
-- Input parameter
	Select     
		6 AS TAG, 
		1 AS PARENT,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,  
		null,
		@psXMLCaseInfo,
		null
	UNION ALL
-- Owner
	select 
		7 AS TAG, 
		1 AS PARENT,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		null,
		dbo.fn_FormatNameUsingNameNo(NAMENO, 7101)
	from CASENAME
	where NAMETYPE = 'O' and CASEID = @nCaseId
	FOR XML EXPLICIT

	set @ErrorCode=@@error
end
RETURN @ErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.xml_DocketWizard to public
go
