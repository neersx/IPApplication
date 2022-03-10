-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListDesignElements
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListDesignElements]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_ListDesignElements.'
	drop procedure [dbo].[csw_ListDesignElements]
	print '**** Creating Stored Procedure dbo.csw_ListDesignElements...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.csw_ListDesignElements
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnCaseKey 		int, 		-- Mandatory
	@pbCalledFromCentura	bit		= 0
)
-- PROCEDURE:	csw_ListDesignElements
-- VERSION:	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- SCOPE:	Inpro.Net
-- DESCRIPTION:	Returns a list of codes and names of the firm elements of the case.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 17 Oct 2005  TM	RFC3144	1	Procedure created
-- 29 Mar 2006  IB	RFC3388	2	Remove RowKey, return FIRMELEMENTID as Key and
--					ELEMENTDESC as Description
-- 27 Aug 2011  DV      RFC4086 3       Return FIRMELEMENTID as Description

AS

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @sSQLString		nvarchar(4000)
Declare @nErrorCode		int
Declare @sLookupCulture		nvarchar(10)

-- Initialise variables
Set @nErrorCode = 0
set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
	
If @nErrorCode = 0
Begin
	Set @sSQLString = "
	Select  D.FIRMELEMENTID		as [Key],
		D.FIRMELEMENTID	        as Description
	from  DESIGNELEMENT D
	where D.CASEID = @pnCaseKey
	order by [Key]"

	exec @nErrorCode=sp_executesql @sSQLString,
					N'@pnCaseKey		int',
					  @pnCaseKey		= @pnCaseKey
	Set @pnRowCount = @@Rowcount	
End

Return @nErrorCode
go

grant execute on dbo.csw_ListDesignElements  to public
go
