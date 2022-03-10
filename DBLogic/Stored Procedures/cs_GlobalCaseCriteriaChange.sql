-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_GlobalCaseCriteriaChange
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cs_GlobalCaseCriteriaChange]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.cs_GlobalCaseCriteriaChange.'
	Drop procedure [dbo].[cs_GlobalCaseCriteriaChange]
End
Print '**** Creating Stored Procedure dbo.cs_GlobalCaseCriteriaChange...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.cs_GlobalCaseCriteriaChange
(
	@pnResults		int		output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,
	@pnProcessId		int,		-- Identifier for the background process request
	@psGlobalTempTable	nvarchar(50),	
	@pbDebugFlag            bit             = 0,
	@pbCalledFromCentura	bit		= 0,
	@psErrorMsg nvarchar(max) = null output
)
as
-- PROCEDURE:	cs_GlobalCaseCriteriaChange
-- VERSION:	2
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Update the Case fields used to determine the Criteria.  These include:
--			CaseType, CountryCode, PropertyType, CaseCategory, SubType, and Basis
--              No concurrency checking.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 13 Apr 2011	MF	RFC10491 1	Procedure created
-- 28 Oct 2013  MZ  RFC10491 2  Fixed global field update of family not working and error message not showing correctly
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Begin Try

declare	@nErrorCode	int
declare @sSQLString	nvarchar(max)

-- Initialise variables
Set @nErrorCode = 0
Set @pnResults  = 0

If @nErrorCode = 0
Begin
	-------------------------------------------
	-- Identify what columns on which Cases are
	-- actually being updated.
	-------------------------------------------
	Set @sSQLString = 
	"UPDATE " +@psGlobalTempTable+ "
	Set CASETYPEUPDATED     = CASE WHEN(GC.CASETYPE     is not null AND (C.CASETYPE    <>GC.CASETYPE     OR C.CASETYPE     is NULL)) THEN 1 ELSE 0 END,
	    COUNTRYCODEUPDATED  = CASE WHEN(GC.COUNTRYCODE  is not null AND (C.COUNTRYCODE <>GC.COUNTRYCODE  OR C.COUNTRYCODE  is NULL)) THEN 1 ELSE 0 END,
	    PROPERTYTYPEUPDATED = CASE WHEN(GC.PROPERTYTYPE is not null AND (C.PROPERTYTYPE<>GC.PROPERTYTYPE OR C.PROPERTYTYPE is NULL)) THEN 1 ELSE 0 END,
	    CASECATEGORYUPDATED = CASE WHEN(GC.CASECATEGORY is not null AND (C.CASECATEGORY<>GC.CASECATEGORY OR C.CASECATEGORY is NULL)) THEN 1 ELSE 0 END,
	    SUBTYPEUPDATED      = CASE WHEN(GC.SUBTYPE      is not null AND (C.SUBTYPE     <>GC.SUBTYPE      OR C.SUBTYPE      is NULL)) THEN 1 ELSE 0 END
	from CASES C
	join " +@psGlobalTempTable+ " CS on (CS.CASEID = C.CASEID)
	join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
	where	(GC.CASETYPE     is not null AND (C.CASETYPE    <>GC.CASETYPE     OR C.CASETYPE     is NULL))
	OR	(GC.COUNTRYCODE  is not null AND (C.COUNTRYCODE <>GC.COUNTRYCODE  OR C.COUNTRYCODE  is NULL))
	OR	(GC.PROPERTYTYPE is not null AND (C.PROPERTYTYPE<>GC.PROPERTYTYPE OR C.PROPERTYTYPE is NULL))
	OR	(GC.CASECATEGORY is not null AND (C.CASECATEGORY<>GC.CASECATEGORY OR C.CASECATEGORY is NULL))
	OR	(GC.SUBTYPE      is not null AND (C.SUBTYPE     <>GC.SUBTYPE      OR C.SUBTYPE      is NULL))"
	
	If @pbDebugFlag = 1
	Begin
		Print @sSQLString
	End

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnProcessId		int',
				  @pnProcessId = @pnProcessId
End

If @nErrorCode = 0
Begin
	-------------------------------------------
	-- Apply global updates against Cases table
	-------------------------------------------
	Set @sSQLString = 
	"UPDATE C
	Set CASETYPE     = CASE WHEN(GC.CASETYPE     is not null) THEN GC.CASETYPE     ELSE C.CASETYPE     END,
	    COUNTRYCODE  = CASE WHEN(GC.COUNTRYCODE  is not null) THEN GC.COUNTRYCODE  ELSE C.COUNTRYCODE  END,
	    PROPERTYTYPE = CASE WHEN(GC.PROPERTYTYPE is not null) THEN GC.PROPERTYTYPE ELSE C.PROPERTYTYPE END,
	    CASECATEGORY = CASE WHEN(GC.CASECATEGORY is not null) THEN GC.CASECATEGORY ELSE C.CASECATEGORY END,
	    SUBTYPE      = CASE WHEN(GC.SUBTYPE      is not null) THEN GC.SUBTYPE      ELSE C.SUBTYPE      END
	OUTPUT INSERTED.CASEID
	INTO #UPDATEDCASES
	from CASES C
	join " +@psGlobalTempTable+ " CS on (CS.CASEID = C.CASEID)
	join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
	where	(GC.CASETYPE     is not null AND (C.CASETYPE    <>GC.CASETYPE     OR C.CASETYPE     is NULL))
	OR	(GC.COUNTRYCODE  is not null AND (C.COUNTRYCODE <>GC.COUNTRYCODE  OR C.COUNTRYCODE  is NULL))
	OR	(GC.PROPERTYTYPE is not null AND (C.PROPERTYTYPE<>GC.PROPERTYTYPE OR C.PROPERTYTYPE is NULL))
	OR	(GC.CASECATEGORY is not null AND (C.CASECATEGORY<>GC.CASECATEGORY OR C.CASECATEGORY is NULL))
	OR	(GC.SUBTYPE      is not null AND (C.SUBTYPE     <>GC.SUBTYPE      OR C.SUBTYPE      is NULL))
	
	set @pnResults = @@RowCount"
	
	If @pbDebugFlag = 1
	Begin
		Print @sSQLString
	End

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnProcessId	int,
				  @pnResults	int	output',
				  @pnProcessId	= @pnProcessId,
				  @pnResults	= @pnResults OUTPUT
End

If @nErrorCode = 0
Begin
	-------------------------------------------
	-- Identify the CASES where the BASIS is
	-- actually being updated.
	-------------------------------------------
	Set @sSQLString = 
	"UPDATE " +@psGlobalTempTable+ "
	Set BASISUPDATED = 1
	from PROPERTY P
	join " +@psGlobalTempTable+ " CS on (CS.CASEID = P.CASEID)
	join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
	where	(GC.BASIS is not null AND (C.BASIS<>GC.BASIS OR C.BASIS is NULL))"
	
	If @pbDebugFlag = 1
	Begin
		Print @sSQLString
	End

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnProcessId		int',
				  @pnProcessId = @pnProcessId
End


If @nErrorCode = 0
Begin
	----------------------------------------------
	-- Apply global updates against Property table
	----------------------------------------------
	Set @sSQLString = 
	"UPDATE P
	Set BASIS = CASE WHEN(GC.BASIS is not null) THEN GC.BASIS ELSE C.BASIS END
	from PROPERTY P
	join " +@psGlobalTempTable+ " CS on (CS.CASEID = P.CASEID)
	join GLOBALCASECHANGEREQUEST GC on (GC.PROCESSID = @pnProcessId)
	where	(GC.BASIS is not null AND (C.BASIS<>GC.BASIS OR C.BASIS is NULL))
	
	set @pnResults = @pnResults+@@RowCount"
	
	If @pbDebugFlag = 1
	Begin
		Print @sSQLString
	End

	exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnProcessId	int,
				  @pnResults	int		output',
				  @pnProcessId	= @pnProcessId,
				  @pnResults	= @pnResults	OUTPUT
End

End Try
Begin Catch
	SET @nErrorCode = ERROR_NUMBER()
	SET @psErrorMsg = ERROR_MESSAGE()
End Catch

Return @nErrorCode
GO

Grant execute on dbo.cs_GlobalCaseCriteriaChange to public
GO
