-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetParentCriteria
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetParentCriteria') and xtype='TF')
Begin
	Print '**** Drop Function dbo.fn_GetParentCriteria'
	Drop function [dbo].fn_GetParentCriteria
End
Print '**** Creating Function dbo.fn_GetParentCriteria...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO

CREATE FUNCTION dbo.fn_GetParentCriteria (@pnCriteriaNo	int, @pbIsNameCriteria bit = 0) 
RETURNS @tbCriteria TABLE
   (
        CRITERIANO		int	NOT NULL	primary key,
        FROMCRITERIA		int	NULL,
        DEPTH			int	NOT NULL
   )

AS
-- Function :	fn_GetParentCriteria
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns all CriteriaNo that are the ancestors (parent, grandparent, etc..)
--		of the CriteriaNo passed to the function. The input CriteriaNo will also be
--		included in the table as Depth = 0.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17 Mar 2009	LP	RFC7208	1	Function created

Begin
	declare @nRowCount	int
	declare @nErrorCode	int
	declare @nDepth		int
	
	set @nDepth=0
	
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
		Set @nDepth=@nDepth-1
		
		if @pbIsNameCriteria = 0
		Begin
			insert into @tbCriteria(CRITERIANO,FROMCRITERIA,DEPTH)
			select I.CRITERIANO,I.FROMCRITERIA,@nDepth
			from @tbCriteria C
			join INHERITS I		 on (I.CRITERIANO=C.FROMCRITERIA)
			left join @tbCriteria C1 on (C1.CRITERIANO=I.CRITERIANO)
			where C1.CRITERIANO is null
		End
		Else
		Begin
			insert into @tbCriteria(CRITERIANO,FROMCRITERIA,DEPTH)
			select I.NAMECRITERIANO,I.FROMNAMECRITERIANO,@nDepth
			from @tbCriteria C
			join NAMECRITERIAINHERITS I		 on (I.NAMECRITERIANO=C.FROMCRITERIA)
			left join @tbCriteria C1 on (C1.CRITERIANO=I.NAMECRITERIANO)
			where C1.CRITERIANO is null
		End
		select @nErrorCode=@@Error,
		       @nRowCount=@@Rowcount
	End
	
	Return
End
GO

grant REFERENCES, SELECT on dbo.fn_GetParentCriteria to public
go
