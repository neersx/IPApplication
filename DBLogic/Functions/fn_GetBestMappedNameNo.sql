-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetBestMappedNameNo
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetBestMappedNameNo') and xtype='FN')
begin
	print '**** Drop function dbo.fn_GetBestMappedNameNo.'
	drop function dbo.fn_GetBestMappedNameNo
end
print '**** Creating function dbo.fn_GetBestMappedNameNo...'
print ''
go

set QUOTED_IDENTIFIER off
go
set CONCAT_NULL_YIELDS_NULL off
go


Create Function dbo.fn_GetBestMappedNameNo
			(
			@psSenderNameIdentifier	nvarchar(254),
			@pnDataSourceNameNo	int,
			@psPropertyType		nchar(1) = null,
			@pnInstructorNameNo	int = null
			)
Returns int

-- FUNCTION :	fn_GetBestMappedNameNo
-- VERSION :	1
-- DESCRIPTION:	This function will return the best fit mapping NAMENO based on parameters.

-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	 Version Description
-- -----------	-------	-------	 ------- ----------------------------------------------- 
-- 27 Sep 2006	vql	SQA12995 1	 Function created.

as
Begin
	Declare @nNameNo	int

	If @psPropertyType is null
	Begin
		-- If property is null then return NAMENO only if we find one row.
		-- Dont even use property and instructor.
		Select @nNameNo = INPRONAMENO
		From EXTERNALNAMEMAPPING EM
		join EXTERNALNAME EN on (EN.EXTERNALNAMEID = EM.EXTERNALNAMEID)
		where EN.EXTERNALNAMECODE = @psSenderNameIdentifier
		and EN.DATASOURCENAMENO = @pnDataSourceNameNo
		
		If @@ROWCOUNT <> 1
		Begin
			Set @nNameNo = NULL
		End
	End
	Else
	Begin
		-- Best fit search.
		Select @nNameNo = INPRONAMENO
		from (	Select top 1 INPRONAMENO,
			Case when (PROPERTYTYPE IS NULL) then '0' else '1' end +    			
			Case when (INSTRUCTORNAMENO IS NULL) then '0' else '1' end as BESTFIT
			From EXTERNALNAMEMAPPING EM
			join EXTERNALNAME EN on (EN.EXTERNALNAMEID = EM.EXTERNALNAMEID)
			where EN.EXTERNALNAMECODE = @psSenderNameIdentifier
			and EN.DATASOURCENAMENO = @pnDataSourceNameNo
			and (EM.PROPERTYTYPE = @psPropertyType or EM.PROPERTYTYPE IS NULL) 
			and (EM.INSTRUCTORNAMENO = @pnInstructorNameNo OR EM.INSTRUCTORNAMENO IS NULL) 
			order by BESTFIT desc) as TEMPTABLE
	End

	Return @nNameNo
End
go

grant execute on dbo.fn_GetBestMappedNameNo to public
GO
