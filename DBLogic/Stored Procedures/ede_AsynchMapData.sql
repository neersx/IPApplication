-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ede_AsynchMapData
-----------------------------------------------------------------------------------------------------------------------------
If exists (Select * from dbo.sysobjects where id = object_id(N'[dbo].[ede_AsynchMapData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	Print '**** Drop Stored Procedure dbo.ede_AsynchMapData.'
	Drop procedure [dbo].[ede_AsynchMapData]
end
Print '**** Creating Stored Procedure dbo.ede_AsynchMapData...'
Print ''
GO


SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO


CREATE PROCEDURE dbo.ede_AsynchMapData
(
	@pnProcessId		int = null,
	@psCommand		nvarchar(1000)
)
AS
-- PROCEDURE :	ede_AsynchMapData
-- VERSION :	8
-- DESCRIPTION:	Run a stored procedure specified in the @psCommand anynchronously using the server's login.
-- COPYRIGHT: 	Copyright 1993 - 2007 CPA Software Solutions (Australia) Pty Limited
--
-- MODIFICATIONS :
-- Date		Who	SQA#	Version	Change
-- ------------	-------	-----	-------	----------------------------------------------- 
-- 27/04/2007	DL	13716	1	Procedure created
-- 26 May 2008	MF	16430	2	Change @@Servername to SERVERPROPERTY('ServerName') as this is more consistant
-- 16 Jun 2008	DL	16458	3	Use sqlcmd instead of osql if SQLServer2005 or later
-- 04 Feb 2010	DL	18430	4	Grant stored procedure to public
-- 28 May 2013	DL	10030	5	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 31 Jul 2013	vql	DR536	6	Make sure ipu_OAGetErrorInfo is called correctly. 
-- 21 Aug 2014	AT	R37920	7	Make Process Id optional.
-- 14 Oct 2014	DL	R39102	8	Use service broker instead of OLE Automation to run the command asynchronoulsly



SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF


declare @nErrorCode 	int
declare @object 	int
declare @ErrorSource 	nvarchar(255)
declare @ErrorDesc 	nvarchar(255)
declare @sServerName	nvarchar(50)
declare @sDBName 	nvarchar(50)
declare @sCommand 	nvarchar(4000)
declare @sSQLString 	nvarchar(4000)

Set @nErrorCode = 0

Begin TRANSACTION


If @nErrorCode <> 0 and @pnProcessId is not null
Begin
	-- delete the request
	Set @sSQLString = "
		Delete PROCESSREQUEST where PROCESSID = @pnProcessId
	"
	Execute @nErrorCode = sp_executesql @sSQLString,
				N'@pnProcessId int',
				  @pnProcessId = @pnProcessId
End

-- run the request asynchronously
If @nErrorCode = 0
Begin

	-- use the server login to perform the task asynchronously
	exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @psCommand				

	If @nErrorCode <> 0
	Begin
		-- delete the request
		if (@pnProcessId is not null)
		Begin
			Set @sSQLString = "
				Delete PROCESSREQUEST where PROCESSID = @pnProcessId
			"
			Execute @nErrorCode = sp_executesql @sSQLString,
						N'@pnProcessId int',
						  @pnProcessId = @pnProcessId
		End
					  
		--execute ipu_OAGetErrorInfo 
		--	@pnObjectToken 	= @object,
		--	@psSource	= @ErrorSource OUT,
		--	@psDescription	= @ErrorDesc OUT,
		--	@psHelpFile	= null,
		--	@pnHelpId	= null
		
		--RAISERROR('Could not run %s command. Error received: %s. Error source: %s', 10, 1, @sCommand, @ErrorDesc, @ErrorSource) WITH LOG
	End
End


COMMIT TRANSACTION


RETURN @nErrorCode

GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

GRANT execute on dbo.ede_AsynchMapData to public
GO