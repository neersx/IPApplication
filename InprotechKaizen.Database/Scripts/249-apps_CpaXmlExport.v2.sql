if exists (select * from sysobjects where id = object_id(N'[dbo].[Apps_CpaXmlExport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.Apps_CpaXmlExport.'
	drop procedure dbo.Apps_CpaXmlExport
	print '**** Creating procedure dbo.Apps_CpaXmlExport....'
	print ''
end
go

if exists (select * from sysobjects where id = object_id(N'[dbo].[apps_CpaXmlExport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.apps_CpaXmlExport.'
	drop procedure dbo.apps_CpaXmlExport
	print '**** Creating procedure dbo.apps_CpaXmlExport....'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS on
GO

CREATE  PROCEDURE [dbo].[apps_CpaXmlExport] 
		@psCaseKeys					nvarchar(max) = null,		
		@pnTempStorageId			bigint = null,		
		@pnUserIdentityId			int,		-- @pnUserIdentityId must accept null (when called from InPro)
		@pnTypeOfRequest            smallint	-- Generate CPA-XML request type (0 for CaseExport , 1 for CaseImport)		
AS
-- PROCEDURE :	apps_CpaXmlExport
-- VERSION :	2
-- DESCRIPTION:	To initiate the process to export cpa-xml data for apps, it's based on csw_CpaXmlExport and adding the return value
-- COPYRIGHT: 	CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date			Who		SQA#		Version	Description
-- ------------	----	---			-------	-------------------------
-- 17/12/2019	KT		DR-50637	1		Procedure created
-- 24/12/2019	SF					2		Use tempstorage to send large amount of caseIds


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

If @psCaseKeys is null
and @pnTempStorageId is not null
Begin
		select @psCaseKeys = [DATA]
		from TEMPSTORAGE
		where ID = @pnTempStorageId

		delete 
		from TEMPSTORAGE
		where ID = @pnTempStorageId
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

	If @pnTypeOfRequest is not null
		Set @sCommand = @sCommand + ", @pnExportRequestType=" + convert(varchar,@pnTypeOfRequest)
		
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

		SELECT @nBackgroundProcessId as BackgroundProcessId, @sErrorMessage as ErrorMessage
	End		
	ELSE
	BEGIN
		SELECT @nBackgroundProcessId as BackgroundProcessId
	END
End


Go

Grant execute on dbo.apps_CpaXmlExport to public
GO