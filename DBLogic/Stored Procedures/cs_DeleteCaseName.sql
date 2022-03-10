-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_DeleteCaseName
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_DeleteCaseName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.cs_DeleteCaseName.'
	drop procedure [dbo].[cs_DeleteCaseName]
end
print '**** Creating Stored Procedure dbo.cs_DeleteCaseName...'
print ''
GO

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

Create  procedure dbo.cs_DeleteCaseName
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@psCaseKey		varchar(11)	= null,
	@pnNameTypeId		int 		= null,
	@psNameTypeKey		varchar(3)	= null,
	@psNameTypeDescription	nvarchar(50) 	= null,
	@psNameKey		varchar(11) 	= null,
	@psDisplayName		nvarchar(254) 	= null,
	@pnNameSequence		int 		= null,
	@psReferenceNo		nvarchar(80)	= null
)
as
-- PROCEDURE :	cs_DeleteCaseName
-- VERSION :	8
-- DESCRIPTION:	See CaseData.doc 
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18/07/2002	JB 			Procedure created
-- 27/07/2002	SF 			Removed some mandatory statuses
-- 29/11/2002	SF		6	Use @pnNameSequence when deleting
-- 23/07/2004	TM	RFC1610	7	Increase the datasize of the @psReferenceNo from nvarchar(50) to varchar(80). 
-- 25 Nov 2011	ASH	R100640	8	Change the size of Case Key to 11.

Begin -- Procedure

	-----------------
	-- Minimum Data
	If 	@psCaseKey is null or @psCaseKey = ''
		or @psNameTypeKey is null or @psNameTypeKey = ''
		or @psNameKey is null or @psNameKey = ''
		RETURN -1

	Delete
	From	[CASENAME]
	Where	[CASEID] = Cast(@psCaseKey as int)
	and	[NAMETYPE] = @psNameTypeKey
	and	[NAMENO] = Cast(@psNameKey as int)
	and	SEQUENCE = @pnNameSequence
	
RETURN @@ERROR
End -- Procedure
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.cs_DeleteCaseName to public
go
