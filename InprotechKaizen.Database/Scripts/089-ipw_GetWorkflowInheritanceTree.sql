-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_GetWorkflowInheritanceTree
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_GetWorkflowInheritanceTree]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipw_GetWorkflowInheritanceTree.'
	drop procedure dbo.ipw_GetWorkflowInheritanceTree
	print '**** Creating procedure dbo.ipw_GetWorkflowInheritanceTree...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS on
GO

CREATE PROCEDURE dbo.ipw_GetWorkflowInheritanceTree
(
	@psCulture	nvarchar(10) = null,
	@psCriteriaIds	nvarchar(max)
)
-- PROCEDURE :	ipw_GetWorkflowInheritanceTree
-- VERSION :	1
-- DESCRIPTION:	Lists inheritance tree for given csv list of criteria ids

-- Modifications
--
-- Date		Who	Number	Version	Description
-- ------------	------	-------	-------	------------------------------------
-- 15/01/2016	AT	R53209	1	Procedure created.

AS
	SET NOCOUNT ON
	SET CONCAT_NULL_YIELDS_NULL OFF

	declare @ErrorCode		int
	declare @sSql		nvarchar(max)
	declare @sLookupCulture		nvarchar(10)
	
	set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, 0)
	
	if not exists (select * from TRANSLATIONSOURCE WHERE TABLENAME = 'CRITERIA' AND SHORTCOLUMN = 'DESCRIPTION' AND INUSE = 1)
	Begin
		Set @sLookupCulture = null
	End
		
	set @sSql = "
	-- recurse up to the top of the trees for the given criteria
	WITH PARENTS as
	(
		select C.CRITERIANO AS PARENT, 
		null AS CHILD, -- I dont care about the children at this stage
		0 as LEVEL,
		SENTINEL = CAST(C.CRITERIANO AS NVARCHAR(MAX))
		FROM CRITERIA C
		join dbo.fn_Tokenise(@psCriteriaIds, ',') T on CAST(T.Parameter AS INT) = C.CRITERIANO -- filter the criteria
		WHERE C.PURPOSECODE = 'E'
		UNION ALL
		-- climb up the trees to back-fill top level parents
		SELECT I.FROMCRITERIA AS PARENT, 
		I.CRITERIANO AS CHILD,
		P.LEVEL + 1 AS LEVEL,
		SENTINEL = P.SENTINEL + '|' + CAST(I.FROMCRITERIA AS NVARCHAR(12))
		FROM PARENTS P
		join INHERITS I ON I.CRITERIANO = P.PARENT
		WHERE CHARINDEX(CAST(I.FROMCRITERIA AS NVARCHAR(12)),SENTINEL) = 0
	)
	select (SELECT 
	C.CRITERIANO,
	ISNULL(C.USERDEFINEDRULE, 0) as ISUSERDEFINED,
	" + dbo.fn_SqlTranslatedColumn("CRITERIA","DESCRIPTION",NULL,"C",@sLookupCulture,0) + " as DESCRIPTION,
	-- return child nodes
	dbo.fn_GetWorkflowInheritedChildren(@sLookupCulture, C.CRITERIANO, NULL) as CHILDCRITERIA
	FROM (
	select DISTINCT
	P.PARENT, P.LEVEL
	from PARENTS P
	JOIN (SELECT PARENT, MAX(LEVEL) AS MAXLEVEL
		FROM PARENTS
		GROUP BY PARENT) AS MAXLEVEL ON (MAXLEVEL.PARENT = P.PARENT
						 AND MAXLEVEL.MAXLEVEL = P.LEVEL)
	LEFT JOIN INHERITS I ON I.FROMCRITERIA = P.PARENT
	WHERE NOT EXISTS (SELECT * FROM PARENTS PX WHERE PX.CHILD = P.PARENT) -- only get top level parents which are not children
	) AS P
	JOIN CRITERIA C ON C.CRITERIANO = P.PARENT
	ORDER BY DESCRIPTION
	for xml path('CRITERIA'), ROOT('INHERITS'), type) as Tree"
	
	exec @ErrorCode = sp_executesql @sSql, N'@sLookupCulture nvarchar(10),
						@psCriteriaIds nvarchar(max)',
						@sLookupCulture = @sLookupCulture,
						@psCriteriaIds = @psCriteriaIds

	RETURN @ErrorCode
go

grant execute on dbo.ipw_GetWorkflowInheritanceTree  to public
go

