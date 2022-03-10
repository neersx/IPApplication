-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetWorkflowInheritedChildren
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetWorkflowInheritedChildren') and xtype = 'FN')
begin
	print '**** Drop function dbo.fn_GetWorkflowInheritedChildren.'
	drop function dbo.fn_GetWorkflowInheritedChildren
end
print '**** Creating function dbo.fn_GetWorkflowInheritedChildren...'
print ''
go

CREATE FUNCTION dbo.fn_GetWorkflowInheritedChildren
(
    @psCulture	nvarchar(10) = null,
    @pnParentCriteriaNo int,
    @pnTopLevelCriteriaNo int = null
)
RETURNS XML

-- FUNCTION :	fn_GetWorkflowInheritedChildren
-- VERSION :	1
-- DESCRIPTION:	Returns child nodes inheriting from a criteria.

-- Modifications
--
-- Date		Who	Number	Version		Description
-- ------------	-------	-------	---------------	---------------------
-- 25 Aug 2016	AT	R53209	1		Function created.
	
AS 
Begin
	RETURN (
		SELECT
			C.CRITERIANO,
			ISNULL(C.USERDEFINEDRULE, 0) as ISUSERDEFINED,
			case when @psCulture is null
			then C.DESCRIPTION
			else dbo.fn_GetTranslation(C.DESCRIPTION, null, C.DESCRIPTION_TID, @psCulture)  -- manually apply translation because functions can't use dynamic sql
			end as DESCRIPTION,
			dbo.fn_GetWorkflowInheritedChildren(@psCulture, I.CRITERIANO, ISNULL(@pnTopLevelCriteriaNo, @pnParentCriteriaNo)) as CHILDCRITERIA
		FROM CRITERIA C
		join INHERITS I ON I.CRITERIANO = C.CRITERIANO
		WHERE I.FROMCRITERIA = @pnParentCriteriaNo
		and (@pnTopLevelCriteriaNo is null or I.CRITERIANO != @pnTopLevelCriteriaNo) -- AVOID CIRCULAR REFERENCES
		order by DESCRIPTION
		for xml path('CRITERIA'), TYPE
	)
End
GO

grant execute on dbo.fn_GetWorkflowInheritedChildren to public
GO