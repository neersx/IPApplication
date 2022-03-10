-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetCaseTextCount
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetCaseTextCount') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetCaseTextCount'
	Drop function [dbo].[fn_GetCaseTextCount]
End
Print '**** Creating Function dbo.fn_GetCaseTextCount...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetCaseTextCount
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10),
	@pnDocumentControlKey	int,		
	@pnCaseKey		int,		
	@psTextTypeCode         nvarchar(2)
) 
RETURNS int
AS
-- Function :	fn_GetCaseTextCount
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return text count for case

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Feb 2012	MS	R11154	1	Function created

Begin
	declare @nResult int
	set @nResult = 0

	Select @nResult = COUNT(*)
        from CASETEXT CT
        join dbo.fn_FilterUserTextTypes(45,null,0,0) TT on (TT.TEXTTYPE  = CT.TEXTTYPE)
        left join TABLECODES TC	on (TC.TABLECODE = CT.LANGUAGE)	
        left join (Select CT1.CASEID, CT1.TEXTTYPE, CT1.CLASS, CT1.LANGUAGE, COUNT(*) as CaseTextRows
	                from CASETEXT CT1
		        group by CT1.CASEID, CT1.TEXTTYPE, CT1.CLASS, CT1.LANGUAGE) CTR 
                on (CTR.CASEID = CT.CASEID
		and CTR.TEXTTYPE = CT.TEXTTYPE
		and (CTR.CLASS is null and CT.CLASS is null)
	        and (CTR.LANGUAGE = CT.LANGUAGE or (CTR.LANGUAGE is null and CT.LANGUAGE is null)))
        where CT.CASEID = @pnCaseKey
        and  (convert(nvarchar(24),CT.MODIFIEDDATE, 21)+cast(CT.TEXTNO as nvarchar(6))) 
             =
             ( select max(convert(nvarchar(24), CT2.MODIFIEDDATE, 21)+cast(CT2.TEXTNO as nvarchar(6)) )
	       from CASETEXT CT2
	       where CT2.CASEID   = CT.CASEID
	       and   CT2.TEXTTYPE = CT.TEXTTYPE
	       and   ((CT2.TEXTTYPE <> 'G' and CT2.CLASS is null and CT.CLASS is null) or 
	              (CT2.TEXTTYPE = 'G' and (CT2.CLASS = CT.CLASS or (CT2.CLASS is null and CT.CLASS is null))))
	       and   ((CT2.LANGUAGE = CT.LANGUAGE) or (CT2.LANGUAGE IS NULL and CT.LANGUAGE  IS NULL)))
	 and (  
	        (
	                @psTextTypeCode is null and CT.TEXTTYPE <> 'G'
                        --and CT.TEXTTYPE not in (SELECT FILTERVALUE from TOPICCONTROL 
                        --                        where WINDOWCONTROLNO = @pnDocumentControlKey
                        --                        and FILTERVALUE is not null)
                )
                or 
                (
                        (@psTextTypeCode is not null and CT.TEXTTYPE = @psTextTypeCode)
                        and ((@psTextTypeCode <> 'G' and CT.CLASS is null) or (@psTextTypeCode = 'G'))
                )
             )
                
		
	return @nResult
End
GO

grant execute on dbo.fn_GetCaseTextCount to public
go

