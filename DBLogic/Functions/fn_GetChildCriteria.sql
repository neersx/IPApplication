-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetChildCriteria
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetChildCriteria') and xtype='TF')
Begin
	Print '**** Drop Function dbo.fn_GetChildCriteria'
	Drop function [dbo].[fn_GetChildCriteria]
End
Print '**** Creating Function dbo.fn_GetChildCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE FUNCTION dbo.fn_GetChildCriteria (@pnCriteriaNo	int, @pbIsNameCriteria bit = 0) 
RETURNS @tbCriteria TABLE
   (
        CRITERIANO		int	NOT NULL	primary key,
        FROMCRITERIA		int	NULL,
        DEPTH			int	NOT NULL
   )

AS
-- Function :	fn_GetChildCriteria
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns all CriteriaNo that are the descendants (child, grandchild etc..)
--		of the CriteriaNo passed to the function. The input CriteriaNo will also be
--		included in the table.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14 Nov 2008	MF	RFC6732	1	Function created
-- 02 Feb 2009	JC	RFC6732	2	Add parameter to return Child Criteria for Name

Begin
	declare @nRowCount	int
	declare @nErrorCode	int
	declare @nDepth		int
	
	set @nDepth=1
	
	if @pbIsNameCriteria = 0
	Begin
		insert into @tbCriteria(CRITERIANO,FROMCRITERIA,DEPTH)
		select C.CRITERIANO,I.FROMCRITERIA,@nDepth
		from (select @pnCriteriaNo as CRITERIANO) C
		left join INHERITS I on (I.CRITERIANO=C.CRITERIANO)
	End
	Else
	Begin
		insert into @tbCriteria(CRITERIANO,FROMCRITERIA,DEPTH)
		select C.CRITERIANO,I.FROMNAMECRITERIANO,@nDepth
		from (select @pnCriteriaNo as CRITERIANO) C
		left join NAMECRITERIAINHERITS I on (I.NAMECRITERIANO=C.CRITERIANO)
	End

	select @nErrorCode=@@Error,
	       @nRowCount=@@Rowcount

	While @nRowCount>0
	and   @nErrorCode=0
	Begin
		Set @nDepth=@nDepth+1
		
		if @pbIsNameCriteria = 0
		Begin
			insert into @tbCriteria(CRITERIANO,FROMCRITERIA,DEPTH)
			select I.CRITERIANO,I.FROMCRITERIA,@nDepth
			from @tbCriteria C
			join INHERITS I		 on (I.FROMCRITERIA=C.CRITERIANO)
			left join @tbCriteria C1 on (C1.CRITERIANO=I.CRITERIANO)
			where C1.CRITERIANO is null
		End
		Else
		Begin
			insert into @tbCriteria(CRITERIANO,FROMCRITERIA,DEPTH)
			select I.NAMECRITERIANO,I.FROMNAMECRITERIANO,@nDepth
			from @tbCriteria C
			join NAMECRITERIAINHERITS I		 on (I.FROMNAMECRITERIANO=C.CRITERIANO)
			left join @tbCriteria C1 on (C1.CRITERIANO=I.NAMECRITERIANO)
			where C1.CRITERIANO is null
		End
		select @nErrorCode=@@Error,
		       @nRowCount=@@Rowcount
	End
	
	Return
End
GO

grant REFERENCES, SELECT on dbo.fn_GetChildCriteria to public
go
