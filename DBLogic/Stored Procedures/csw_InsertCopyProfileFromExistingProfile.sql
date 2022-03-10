-----------------------------------------------------------------------------------------------------------------------------
-- Creation of csw_InsertCopyProfileFromExistingProfile
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'dbo.csw_InsertCopyProfileFromExistingProfile') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.csw_InsertCopyProfileFromExistingProfile.'
	drop procedure dbo.csw_InsertCopyProfileFromExistingProfile
	print '**** Creating Stored Procedure dbo.csw_InsertCopyProfileFromExistingProfile...'
	print ''
end
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON 
GO

create procedure dbo.csw_InsertCopyProfileFromExistingProfile
	@pnRowCount			int		= 0	output,	
	@pnUserIdentityId		int		= null,	 -- optional identifier of the user
	@psCulture			nvarchar(10) = null, -- optional identifier for culture
	@psNewCopyProfile		nvarchar(50),	 -- mandatory name of the new Copy Profile to be created.
	@psXmlCopyProfileData      ntext     	 -- mandatory xml containing profile attribute data
as
-- PROCEDURE :	csw_InsertCopyProfileFromExistingProfile
-- VERSION :	1
-- DESCRIPTION:	Copies all of the details of an existing Case Copy Profile from @psXmlCopyProfileData xml
--		into a newly named Copy Profile.

-- MODIFICATIONS :
-- Date		Who	Number	Version	Change
-- ------------	-------	------	-------	----------------------------------------------- 
-- 18 Jan 2010	MF	RFC7946	1	Procedure created
-- 10 Mar 2010  DV  RFC7946 2   Modified procedure after change of approach

set nocount on

declare	@sSQLString		nvarchar(max)
declare	@bHexNumber		varbinary(128)
declare @nOfficeID		int
declare	@nLogMinutes		int 
declare	@nTransNo		int
declare @nBatchNo		int

declare @nErrorCode		int
declare @TranCountStart		int

-----------------------
-- Initialise Variables
-----------------------
set @nErrorCode = 0

--------------------------------------------------
-- D A T A   V A L I D A T I O N
-- Validate the input parameters before attempting
-- to create the new CopyProfile
--------------------------------------------------

------------------------------
-- Validate @psNewCopyProfile
------------------------------
If @nErrorCode = 0
Begin
	If @psNewCopyProfile is null
	Begin
		RAISERROR('@psNewCopyProfile must not be NULL', 14, 1)
		Set @nErrorCode = @@ERROR
	End
	Else If exists (select 1 from COPYPROFILE where PROFILENAME=@psNewCopyProfile)
	Begin
		RAISERROR('@psNewCopyProfile must NOT already exist in COPYPROFILE table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

-------------------------------------
-- Validate the supplied UserIdentity
-------------------------------------
If @nErrorCode=0
Begin
	If (@pnUserIdentityId is null
	 or @pnUserIdentityId='')
	Begin
		Set @sSQLString="
		Select @pnUserIdentityId=min(IDENTITYID)
		from USERIDENTITY
		where LOGINID=substring(SYSTEM_USER,1,50)"

		exec @nErrorCode=sp_executesql @sSQLString,
				N'@pnUserIdentityId		int	OUTPUT',
				  @pnUserIdentityId=@pnUserIdentityId	OUTPUT
	End
	Else If not exists (select 1 from USERIDENTITY where IDENTITYID=@pnUserIdentityId)
	Begin
		RAISERROR('@pnUserIdentityId must exist in USERIDENTITY table', 14, 1)
		Set @nErrorCode = @@ERROR
	End
End

--------------------------------------
-- Initialise variables that will be 
-- loaded into CONTEXT_INFO for access
-- by the audit triggers
--------------------------------------

If @nErrorCode=0
Begin
	Set @sSQLString="
	Select @nOfficeID=COLINTEGER
	from SITECONTROL
	where CONTROLID='Office For Replication'

	Select @nLogMinutes=COLINTEGER
	from SITECONTROL
	where CONTROLID='Log Time Offset'"

	exec @nErrorCode=sp_executesql @sSQLString,
				N'@nOfficeID	int		OUTPUT,
				  @nLogMinutes	int		OUTPUT',
				  @nOfficeID  = @nOfficeID	OUTPUT,
				  @nLogMinutes=@nLogMinutes	OUTPUT
End

---------------------------------------------------
-- Get Transaction Number for use in audit records.
---------------------------------------------------
If @nErrorCode=0
Begin
	-----------------------------------------------------------------------------
	-- A separate database transaction will be used to insert the TRANSACTIONINFO
	-- row to ensure the lock on the database is kept to a minimum as this table
	-- will be used extensively by other processes.
	-----------------------------------------------------------------------------

	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION

	-- Allocate a transaction id that can be accessed by the audit logs
	-- for inclusion.

	Set @sSQLString="Insert into TRANSACTIONINFO(TRANSACTIONDATE) values(getdate())
			Set @nTransNo=SCOPE_IDENTITY()"
	
	exec @nErrorCode=sp_executesql @sSQLString,
					N'@nTransNo	int	OUTPUT',
					  @nTransNo=@nTransNo	OUTPUT

	--------------------------------------------------------------
	-- Load a common area accessible from the database server with
	-- the UserIdentityId and the TransactionNo just generated.
	-- This will be used by the audit logs.
	--------------------------------------------------------------
	If @nErrorCode=0
	Begin
		Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4)+ 
				substring(cast(isnull(@nTransNo,'') as varbinary),1,4)+ 
				substring(cast(isnull(@nBatchNo,'') as varbinary),1,4) +
				substring(cast(isnull(@nOfficeID,'') as varbinary),1,4) +
				substring(cast(isnull(@nLogMinutes,'') as varbinary),1,4)
		SET CONTEXT_INFO @bHexNumber
	End

	-- Commit or Rollback the transaction
	
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

-----------------------------------------------------------------------------------------------
-- C O P Y P R O F I L E   C R E A T I O N
-- The insert to the database is to be applied as a single transaction so that the entire
-- transaction can be rolled back should a failure occur.
-----------------------------------------------------------------------------------------------
If @nErrorCode=0
Begin
	Select @TranCountStart = @@TranCount
	BEGIN TRANSACTION
	
	Declare @idoc                   int
	Declare @sRowPattern            nvarchar(100)
	
	Set @sRowPattern = "//CopyProfileData/CopyData"
	If @nErrorCode = 0
	Begin	 
	        
			exec sp_xml_preparedocument	@idoc OUTPUT, @psXmlCopyProfileData	
	        
			insert into COPYPROFILE(PROFILENAME, SEQUENCENO, COPYAREA, CHARACTERKEY, REPLACEMENTDATA, PROTECTCOPY,NUMERICKEY)
			Select	*
			from	OPENXML (@idoc, @sRowPattern, 2)
			WITH (
				  PROFILENAME	        nvarchar(50)'ProfileName/text()',	
				  COPYAREA		        int      	'SequenceNo/text()',
				  COPYAREAKEY		nvarchar(20)	'CopyArea/text()',
				  CHARACTERKEY		nvarchar(20)	'CharacterKey/text()',
				  REPLACEMENTDATA	nvarchar(508)	'ReplaceData/text()',
				  PROTECTCOPY       bit             'ProtectCopy/text()',
				  NUMERICKEY        int             'NumericKey/text()'
				 )
			Set @pnRowCount = @@RowCount	

			exec sp_xml_removedocument @idoc

			Set @nErrorCode=@@Error
	End
	----------------------------------------
	-- Commit or Rollback the transaction
	----------------------------------------
	If @@TranCount > @TranCountStart
	Begin
		If @nErrorCode = 0
			COMMIT TRANSACTION
		Else
			ROLLBACK TRANSACTION
	End
End

return @nErrorCode
go

grant execute on dbo.csw_InsertCopyProfileFromExistingProfile to public
go
