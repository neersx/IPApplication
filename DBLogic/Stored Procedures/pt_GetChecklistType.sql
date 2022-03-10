-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_GetChecklistType
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[pt_GetChecklistType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_GetChecklistType.'
	drop procedure dbo.pt_GetChecklistType
	print '**** Creating procedure dbo.pt_GetChecklistType...'
	print ''
end
go

create proc dbo.pt_GetChecklistType  
			@pnCaseId 		int, 
			@pnQuestionNo 		smallint, 
			@prnCheckListType	smallint output 
as

-- PROCEDURE :	pt_GetChecklistType
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns the Checklist Type associated with a Question and Case
-- CALLED BY :	pt_DoCalculation

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 26/02/2002	MF		Procedure Created

set nocount on

declare	@ErrorCode	int

Select	@ErrorCode=0

If @ErrorCode=0
Begin
	SELECT 	@prnCheckListType=CHECKLISTTYPE 
	FROM 	CASECHECKLIST 
	WHERE   CASEID     = @pnCaseId
	and	QUESTIONNO = @pnQuestionNo 
	
	Select @ErrorCode=@@Error
End

Return @ErrorCode
go

grant execute on dbo.pt_GetChecklistType to public
go
