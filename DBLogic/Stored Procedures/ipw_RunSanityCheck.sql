-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_RunSanityCheck
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_RunSanityCheck]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.ipw_RunSanityCheck.'
	Drop procedure [dbo].[ipw_RunSanityCheck]
end
Print '**** Creating Stored Procedure dbo.ipw_RunSanityCheck...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/*
Usage:
	To make call to stored procedure ip_DataValidation to return validation rules which may apply on seelcted cases.
*/


CREATE  PROCEDURE dbo.ipw_RunSanityCheck 
		@pnUserIdentityId		int,			-- Mandatory
		@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed	
		@psFunctionalArea		nchar(1)	= 'C',	-- The area of functionality the data validation is against
		@pnCaseId			int		= null,	-- Key of Case if it is being validated
		@pnNameNo			int		= null,	-- Key of Name if it is being validated
		@pnTransactionNo		int		= null,	-- The database transaction number if it is known		
		@pbDeferredValidations		bit		= 0,	-- Tells the procedure to process any outstanding Validation Requests that were deferred
		@pbPrintFlag			bit		= 0,
		@psCaseKeys			nvarchar(max)	        -- Comma seperated case keys		
AS
-- PROCEDURE :	ipw_RunSanityCheck
-- VERSION :	3
-- DESCRIPTION:	To run the data validation on selected cases
-- COPYRIGHT: 	CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 4/07/2013	SW      R25136	1	Procedure created
-- 27/08/2014   SW      R38218  2	Increase size of @sSQLString to nvarchar(max)
-- 12 Jan 2016	MF	R39102	3	Use service broker instead of OLE Automation to run the command asynchronoulsly

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF 

Declare @sSQLString     nvarchar(max)
Declare @nErrorCode	int	
declare	@sCommand	varchar(4000)
Declare @psTableName nvarchar(60)
Declare @pnBackgroundProcessId int
declare	@nObject	int
declare	@nObjectExist	tinyint
declare @sCurrentTable nvarchar(50)

-- Initialise variables
Set  @nErrorCode    = 0

-- Initialize BACKGROUNDPROCESS with Sanity Check process
If @nErrorCode = 0
Begin	
	-- The Sanity Check Process is added to the BackgroundProcess list	
		Set @sSQLString="Insert into BACKGROUNDPROCESS (IDENTITYID,PROCESSTYPE, STATUS, STATUSDATE)
		Values (@pnUserIdentityId,'SanityCheck',1, getDate())"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId int',
				  @pnUserIdentityId = @pnUserIdentityId

		If @nErrorCode = 0
		Begin
			Set @pnBackgroundProcessId = IDENT_CURRENT('BACKGROUNDPROCESS') 
		End
End

-- Initialise variables
Set  @sCurrentTable = '##CASELISTSC_' + Cast(@@SPID as varchar(10))

-------------------------------------------------
-- Remove any preexisting global temporary tables
-------------------------------------------------

If exists(select * from tempdb.dbo.sysobjects where name = @sCurrentTable)
and @nErrorCode=0
Begin
	Set @sSQLString = "Drop table "+@sCurrentTable
	
	Exec @nErrorCode = sp_executesql @sSQLString
End

If @nErrorCode=0
Begin
	---------------------------------------------
	-- Create temporary table for storing CaseIDs
	---------------------------------------------
	Set @sSQLString = "Create table "+CHAR(10)+ @sCurrentTable + " (CASEID int)" 

	Exec @nErrorCode = sp_executesql @sSQLString	
End

--Insert CASEID 
If @psCaseKeys is not null
Begin
		-- Export only the specified cases using fn_Tokenise
		Set @sSQLString="
		Insert into "+CHAR(10)+ @sCurrentTable + " (CASEID)
		Select  distinct C.CASEID
		from  dbo.fn_Tokenise('"+@psCaseKeys+"',',') T 
		join CASES C on (C.CASEID = T.PARAMETER)"	
		
		
		exec @nErrorCode = sp_executesql @sSQLString		
		
End 

If  @nErrorCode = 0
Begin
	----------------------------------------------
	-- Build command line to run ip_DataValidation 	
	----------------------------------------------
	Set @sCommand = 'dbo.ip_DataValidation '
	
	If @pnUserIdentityId is not null
			Set @sCommand = @sCommand + "@pnUserIdentityId=" + convert(varchar,@pnUserIdentityId) + ","	
		
	If @pbDeferredValidations is not null
		Set @sCommand = @sCommand + "@pbDeferredValidations=" + convert(varchar,@pbDeferredValidations) + "," 				
		
	If @psCaseKeys is not null
		Set @sCommand = @sCommand + "@psTableName='" + @sCurrentTable + "'," 	

	If @pnBackgroundProcessId is not null
		Set @sCommand = @sCommand + "@pnBackgroundProcessId=" + convert(varchar,@pnBackgroundProcessId) 

	print @sCommand
	---------------------------------------------------------------
	-- Run the command asynchronously using Service Broker (rfc39102)
	--------------------------------------------------------------- 
	exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
End
		
Return @nErrorCode
GO

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ipw_RunSanityCheck to public
go

