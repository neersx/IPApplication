-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetBestMatchAssociatedNameWithSequence
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetBestMatchAssociatedNameWithSequence') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetBestMatchAssociatedNameWithSequence.'
	drop function dbo.fn_GetBestMatchAssociatedNameWithSequence
end
print '**** Creating function dbo.fn_GetBestMatchAssociatedNameWithSequence...'
print ''
go

set QUOTED_IDENTIFIER off
go
set CONCAT_NULL_YIELDS_NULL off
go


Create Function dbo.fn_GetBestMatchAssociatedNameWithSequence
			(
			@pnNameNo	int,
			@pnCaseKey	int,
			@psRelationship	nvarchar(3),
                        @pnSequence     smallint,
                        @psAction       nvarchar(2) = null
			)
Returns int

-- FUNCTION :	fn_GetBestMatchAssociatedNameWithSequence
-- VERSION :	1
-- DESCRIPTION:	This function will return the best fit ASSOCIATEDNAME NAMENO based on parameters.

-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	 Version Description
-- -----------	-------	-------	 ------- ----------------------------------------------- 
-- 04 Apr 2017	MS	R71040	 1	 Function created.
-- 07 Feb 2018  MS      R72578   2       Added best fit logic for action

as
Begin
	Declare @nRelatedNameNo	int
	-- Best fit search.
	Select @nRelatedNameNo = RELATEDNAME
	from (	Select top 1 RELATEDNAME,
		Case when (AN.PROPERTYTYPE IS NULL) then '0' else '1' end +    	
                Case when (AN.ACTION is NULL) then '0' else '1' end +  		
		Case when (AN.COUNTRYCODE IS NULL) then '0' else '1' end as BESTFIT
		From ASSOCIATEDNAME AN, CASES C
		join COUNTRY CT on (CT.COUNTRYCODE=C.COUNTRYCODE)
		join VALIDPROPERTY VP on (VP.PROPERTYTYPE=C.PROPERTYTYPE
							and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
												from VALIDPROPERTY VP1
												where VP1.PROPERTYTYPE=C.PROPERTYTYPE
												and VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))		
		where AN.RELATIONSHIP = @psRelationship
		and AN.NAMENO = @pnNameNo
                and (AN.SEQUENCE = @pnSequence or @pnSequence is null)
		and (AN.PROPERTYTYPE = C.PROPERTYTYPE or AN.PROPERTYTYPE IS NULL) 
		and (AN.COUNTRYCODE = C.COUNTRYCODE OR AN.COUNTRYCODE IS NULL) 	
                and (AN.ACTION = @psAction or AN.ACTION is null) 
		and C.CASEID = @pnCaseKey		
		order by BESTFIT desc) as TEMPTABLE

	Return @nRelatedNameNo
End
go

grant execute on dbo.fn_GetBestMatchAssociatedNameWithSequence to public
GO
