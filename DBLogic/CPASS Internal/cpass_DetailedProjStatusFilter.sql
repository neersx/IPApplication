-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpass_DetailedProjStatusFilter
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cpass_DetailedProjStatusFilter]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cpass_DetailedProjStatusFilter.'
	Drop procedure [dbo].[cpass_DetailedProjStatusFilter]
End
Print '**** Creating Stored Procedure dbo.cpass_DetailedProjStatusFilter...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.cpass_DetailedProjStatusFilter
(
	@psCaseType			nchar(1)	= null,  
	@psCaseFamily			nvarchar(20)	= null,  
	@pnProjectLeader		int		= null,  
	@pnCurrentProjectEvent		int		= 0  
)

AS
-- PROCEDURE :	cpass_DetailedProjStatusFilter
-- DESCRIPTION:	Gets the report set for the Detailed Project Status Report
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- VERSION:	1
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 10 Jun 2006	JD		1	Procedure created


Set nocount on
Set concat_null_yields_null off

-- Declare a temporary table to hold the result returned from 
-- the cs_GetBudgetDetails table

Declare	@ErrorCode	int
declare @ClientName 	nvarchar(254)
Declare	@FamilyCount	int
declare @ReportSet	table
(	FAMILY	nvarchar(20) collate database_default )

Set @ErrorCode=0

If @ErrorCode=0
Begin
	insert into @ReportSet
	SELECT 	DISTINCT 
		C.FAMILY
	FROM  	CASES C
	WHERE 	C.PROPERTYTYPE = 'B'
	AND	( @psCaseType is NULL OR C.CASETYPE = @psCaseType )
	AND	( @psCaseFamily is NULL OR C.FAMILY = @psCaseFamily )
	AND	( @pnProjectLeader is NULL OR (
		( @pnProjectLeader is NOT NULL AND EXISTS 	(
							SELECT 	*
							FROM  	CASENAME CN 
							WHERE 	CN.CASEID = C.CASEID
							AND	CN.NAMETYPE = 'EMP'
							AND	CN.NAMENO = @pnProjectLeader)
 )
		)
		)
	AND	( @pnCurrentProjectEvent = 0 OR
		( @pnCurrentProjectEvent = 1 AND NOT EXISTS	(
							SELECT 	EVENTDATE
							FROM  	CASEEVENT E
							WHERE 	E.CASEID = C.CASEID
							AND	E.EVENTNO = -12 )
		)
		)
	AND	C.FAMILY is not null

	set @ErrorCode = @@Error

End

If @ErrorCode=0
Begin
	SELECT 	@FamilyCount = Count(*) 
	FROM  	@ReportSet

	PRINT 'Count'
End 

If @ErrorCode=0
Begin
	SELECT 	DISTINCT 
		@FamilyCount as [FAMILY COUNT],
		C.CASETYPE,
		CT.CASETYPEDESC,
		C.FAMILY,
		CF.FAMILYTITLE,
		substring(  CASE WHEN N.TITLE IS NOT NULL THEN N.TITLE + ' '  END
		+ CASE WHEN N.FIRSTNAME IS NOT NULL THEN N.FIRSTNAME + ' ' END
		+ N.NAME,0,254 ) as [PROJECT LEADER],
		T.TELECOMNUMBER as [EMAIL]
	FROM  	@ReportSet RS
	JOIN	CASES C on ( C.FAMILY = RS.FAMILY )
	JOIN	CASEFAMILY CF on ( CF.FAMILY = C.FAMILY )
	JOIN	CASETYPE CT on ( CT.CASETYPE = C.CASETYPE )
	left JOIN CASENAME CN on ( CN.CASEID = C.CASEID and CN.NAMETYPE = 'EMP'  )
	left JOIN NAME N on ( N.NAMENO = CN.NAMENO )
	left JOIN TELECOMMUNICATION T on ( T.TELECODE = N.MAINEMAIL )
	WHERE 	C.PROPERTYTYPE = 'B'
	and	( @psCaseType is NULL OR C.CASETYPE = @psCaseType )
	order by 3

	set @ErrorCode = @@Error

	PRINT 'Result Set'
End 

Return @ErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cpass_DetailedProjStatusFilter to public
go
