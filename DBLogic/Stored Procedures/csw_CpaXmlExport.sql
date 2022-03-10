-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cs_CpaXmlExport
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[csw_CpaXmlExport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.csw_CpaXmlExport.'
	Drop procedure [dbo].[csw_CpaXmlExport]
end
Print '**** Creating Stored Procedure dbo.csw_CpaXmlExport...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

/*
Usage:
	To make call to stored procedure EDE_ExportCaseName to export CPA-XML Case and Names data to provided shared location.
*/


CREATE  PROCEDURE dbo.csw_CpaXmlExport 
		@psCaseKeys				nvarchar(max),		
		@pnUserIdentityId			int, -- @pnUserIdentityId must accept null (when called from InPro)
		@pnTypeOfRequest                        smallint  -- Generate CPA-XML request type (0 for CaseExport , 1 for CaseImport)		
AS
-- PROCEDURE :	csw_CpaXmlExport
-- VERSION :	5
-- DESCRIPTION:	To initiate the process to export cpa-xml data
-- COPYRIGHT: 	CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Description
-- ------------	-------	-------	-------	-------------------------------------- 
-- 20/06/2013	AK	R6623	1	Procedure created
-- 07/07/2013   DV	R6623	2	Create a temporary table to store the CaseID rather then passing them as nvarchar
-- 27/08/2014   SW      R38218  3	Increase size of @sSQLString to nvarchar(max)
-- 6/07/2015    SW      R42540  4	Add request type for cpa-xml case import or case export
-- 04 Aug 2017	MF	72112	5	Change the call to start asynchronous processing to use ipu_ScheduleAsyncCommand.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
SET ANSI_WARNINGS OFF 

Declare @sSQLString		nvarchar(max)
Declare @nErrorCode		int	
declare	@sCommand		nvarchar(max)
declare @nBackgroundProcessId	int
declare	@nObject		int
declare	@nObjectExist		tinyint
declare @sErrorMessage		nvarchar(254)
declare @sCurrentTable		nvarchar(254)
declare @sProcessType		nvarchar(254)

Set @sProcessType = 'CpaXmlExport' 
If @pnTypeOfRequest = 1 
	set @sProcessType = 'CpaXmlForImport'

-- Initialise variables
Set  @nErrorCode    = 0

If @nErrorCode = 0
Begin	
	-- The CPA-XML Export Process is added to the BackgroundProcess list	
		Set @sSQLString="Insert into BACKGROUNDPROCESS (IDENTITYID,PROCESSTYPE, STATUS, STATUSDATE)
		Values (@pnUserIdentityId,'" +@sProcessType + "',1, getDate())"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId int',
				  @pnUserIdentityId = @pnUserIdentityId

		If @nErrorCode = 0
		Begin
			Set @nBackgroundProcessId = IDENT_CURRENT('BACKGROUNDPROCESS') 
		End
End

-- Initialise variables
Set  @sCurrentTable = '##CASELISTCPAEXPORT_' + Cast(@@SPID as varchar(10))

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
		
		exec @sSQLString = sp_executesql @sSQLString
End 

If  @nErrorCode = 0
Begin
	------------------------------------------------
	-- Build command line to run EDE_ExportCaseName 	
	------------------------------------------------

	Set @sCommand = 'dbo.EDE_ExportCaseName '
	
	Set @sCommand = @sCommand + "@pnExportType='1'," 

	Set @sCommand = @sCommand + "@psCaseTable='" + @sCurrentTable + "'" 	

	If @nBackgroundProcessId is not null
		Set @sCommand = @sCommand + ", @pnBackgroundProcessId=" + convert(varchar,@nBackgroundProcessId)
		
	---------------------------------------------------------------
	-- Run the command asynchronously using Servie Broker (rfc-39102)
	--------------------------------------------------------------- 
	exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand

	If @nErrorCode != 0
	Begin
		Set @sSQLString="Select @sErrorMessage = description
			from master..sysmessages
			where error=@nErrorCode
			and msglangid=(SELECT msglangid FROM master..syslanguages WHERE name = @@LANGUAGE)"

		Exec @nErrorCode=sp_executesql @sSQLString,
			N'@sErrorMessage	nvarchar(254) output,
			  @nErrorCode	int',
			  @sErrorMessage	= @sErrorMessage output,
			  @nErrorCode	= @nErrorCode


		---------------------------------------
		-- Update BACKGROUNDPROCESS table 
		---------------------------------------	
		Set @sSQLString = "Update BACKGROUNDPROCESS
					Set STATUS = 3,
					    STATUSDATE = getdate(),
					    STATUSINFO = @sErrorMessage
					Where PROCESSID = @nBackgroundProcessId"

		exec sp_executesql @sSQLString,
			N'@nBackgroundProcessId	int,
			  @sErrorMessage	nvarchar(254)',
			  @nBackgroundProcessId = @nBackgroundProcessId,
			  @sErrorMessage	= @sErrorMessage
	End		

End

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.csw_CpaXmlExport to public
go

