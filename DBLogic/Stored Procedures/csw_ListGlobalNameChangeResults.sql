-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_ListGlobalNameChangeResults
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_ListGlobalNameChangeResults]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.csw_ListGlobalNameChangeResults.'
	Drop procedure [dbo].[csw_ListGlobalNameChangeResults]
End
Print '**** Creating Stored Procedure dbo.csw_ListGlobalNameChangeResults...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[csw_ListGlobalNameChangeResults]
(	
	@pnUserIdentityId		int,		-- Mandatory
	@psCulture			nvarchar(10) 	= null,	
	@pnRequestNo			int,		-- Mandatory
	@pbCalledFromCentura		bit		= 0
)
as
-- PROCEDURE:	csw_ListGlobalNameChangeResults
-- VERSION:	3	
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns list of Global Name Change Results and Save the Global Name Change
--              Search containing the updated cases into the database

-- MODIFICATIONS :
-- Date		Who  Change	Version	  Description
-- -----------	---- -------	--------  ------------------------------------------------------ 
-- 5 NOV 2008	MS   RFC5698	1	  Procedure created
-- 19 Nov 2008  MS   RFC5698	2	  Remove implementation of saving Global Name Change Search
-- 08 Dec 2009	MS   RFC100063	3	  Get the Counts from GNCCOUNTRESULT table rather than CASENAMEREQUEST	
--					  and changed Cases from GNCCHANGEDCASES table

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare	@nErrorCode		int
Declare @sSQLString		nvarchar(4000)

-- Initialise variables
Set @nErrorCode 	= 0

If @nErrorCode=0
Begin	
	--------------------------------
	-- Get the Counts of GlobalNameChange Case Names
	--------------------------------	
	Set @sSQLString = "Select  PROCESSID as 'RowKey',
				NOUPDATEDROWS as 'NamesUpdatedCount', 
				NOINSERTEDROWS as 'NamesInsertedCount',
				NODELETEDROWS as 'NamesDeletedCount'						 
			From GNCCOUNTRESULT
			Where PROCESSID = @pnRequestNo"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnRequestNo	int',				  
			@pnRequestNo =  @pnRequestNo	

End

If @nErrorCode=0
Begin	
	--------------------------------
	-- Get the list of Cases which are affected by GlobalNameChanges 
	--------------------------------
	Set @sSQLString = "Select CASEID as RowKey, CASEID as CaseKey from GNCCHANGEDCASES where PROCESSID=@pnRequestNo"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnRequestNo int',	  
			@pnRequestNo =  @pnRequestNo	
	
End

Return @nErrorCode
GO

Grant execute on dbo.csw_ListGlobalNameChangeResults to public
GO