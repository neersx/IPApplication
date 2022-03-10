-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipu_Policing_Start_Continuously
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipu_Policing_Start_Continuously]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipu_Policing_Start_Continuously.'
	drop procedure dbo.ipu_Policing_Start_Continuously
end
print '**** Creating procedure dbo.ipu_Policing_Start_Continuously...'
print ''
go

set QUOTED_IDENTIFIER off
go
set ANSI_NULLS on
go

create procedure dbo.ipu_Policing_Start_Continuously	
			@psDelayLength			varchar(9)	='00:00:01', --time(hhh:mm:ss) to wait before checking for more Policing requests
			@pnUserIdentityId		int		= null
as
-- PROCEDURE :	ipu_Policing_Start_Continuously
-- VERSION :	4
-- DESCRIPTION:	Sets the 'Police Continuously' site control on and starts Policing
--		running asynchronously in a continuous loop.
--		To stop Policing running:
--
--			update SITECONTROL
--			set COLBOOLEAN=0
--			where CONTROLID='Police Continuously'
--
-- CALLED BY :	
-- COPYRIGHT :	Copyright 1993 - 2008 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Change	Version	Description
-- -----------	---	------	-------	----------------------------------------------- 
-- 08 Aug 2008	MF		1	Procedure created
-- 29 Oct 2010	MF	19124	2	Introduce a 1 second delay as the default. Discovered that when multiple Events are being updated from 
--					case detail entry that Policing Continuously with a 0 delay was sometimes picking up only some of the
--					Policing requests to process on the first pass. Depending on the rules design this could have an impact
--					on the calculations. 
-- 28 May 2013	DL	10030	3	Replace calls to system extended SP sp_OAxxx with wrapper SP ipu_OAxxx
-- 14 Oct 2014	DL	R39102	4	Use service broker instead of OLE Automation to run the command asynchronoulsly



set nocount on

declare	@nErrorCode		int
declare @TranCountStart		int
declare	@nObject		int
declare	@nObjectExist		tinyint
declare	@sCommand		varchar(255)
declare	@sSQLString		nvarchar(1000)

set @nErrorCode = 0

-- Get the current userid 
If @pnUserIdentityId is null or @pnUserIdentityId=''
Begin
	Set @sSQLString="
	Select @pnUserIdentityId=min(IDENTITYID)
	from USERIDENTITY
	where LOGINID=substring(SYSTEM_USER,1,50)"

	exec @nErrorCode=sp_executesql @sSQLString,
			N'@pnUserIdentityId		int	OUTPUT',
			  @pnUserIdentityId=@pnUserIdentityId	OUTPUT
End

If @nErrorCode=0
and not exists (select 1 from SITECONTROL where CONTROLID='Police Continuously' and COLBOOLEAN=1)
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	update SITECONTROL
	set COLBOOLEAN=1
	where CONTROLID='Police Continuously'
	
	set @nErrorCode=0

	-- Commit or Rollback the transaction

	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-----------------------------------------
-- Build command line to run ipu_Policing 
-- using service broker (rfc39102)
-----------------------------------------
If @nErrorCode = 0
Begin
	Set @sCommand = 'dbo.ipu_Policing @psDelayLength='''+rtrim(ltrim(@psDelayLength))+''''


	If @pnUserIdentityId is not null
		Set @sCommand = @sCommand + ',@pnUserIdentityId='+ convert(varchar,@pnUserIdentityId)
End


If @nErrorCode=0
Begin
	---------------------------------------------------------------
	-- Run the command asynchronously using Servie Broker (rfc-39102)
	--------------------------------------------------------------- 
	exec @nErrorCode = dbo.ipu_ScheduleAsyncCommand @sCommand				
End


return @nErrorCode
go

grant execute on dbo.ipu_Policing_Start_Continuously to public
go
