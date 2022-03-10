-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_InsertDataValidationFailLog 
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_InsertDataValidationFailLog]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_InsertDataValidationFailLog.'
	drop procedure dbo.ip_InsertDataValidationFailLog
end
print '**** Creating procedure dbo.ip_InsertDataValidationFailLog...'
print ''
go

set QUOTED_IDENTIFIER on -- this is required for the XML Nodes method
go
set ANSI_NULLS on
go

create procedure dbo.ip_InsertDataValidationFailLog	
		@pnUserIdentityId		int,			-- Mandatory
		@pxValidationIdXML		XML			-- List of the ValidationId values to be saved to database.
		  
as
---PROCEDURE :	ip_InsertDataValidationFailLog
-- VERSION :	1
-- DESCRIPTION:	This procedure inserts rows into the DATAVALIDATIONFAILLOG table.
	
-- MODIFICATION
-- Date		Who	No	Version	Description
-- ====         ===	=== 	=======	=====================================================================
-- 20 Mar 2011	MF	10379	1	Procedure created.
		
set nocount on
set concat_null_yields_null on	-- this is required for the XML Nodes method
set quoted_identifier on	-- this is required for the XML Nodes method
		 	
Declare	@ErrorCode		int
Declare	@TranCountStart		int
Declare	@nRetry			smallint
Declare @bHexNumber		varbinary(128)

------------------------------
--
-- I N I T I A L I S A T I O N
--
------------------------------
Set @ErrorCode = 0
Set @nRetry    = 3

While @nRetry>0
and   @ErrorCode=0
Begin
	Begin TRY
		Select @TranCountStart = @@TranCount
		BEGIN TRANSACTION

		--------------------------------------------------------------
		-- Load a common area accessible from the database server with
		-- the UserIdentityId.
		-- This will be used by the audit logs.
		--------------------------------------------------------------

		Set @bHexNumber=substring(cast(isnull(@pnUserIdentityId,'') as varbinary),1,4)
		SET CONTEXT_INFO @bHexNumber

		-------------------------------------
		-- Insert a row for each ValidationId
		-- that has been passed in the XML.
		-------------------------------------
	
		Insert into DATAVALIDATIONFAILLOG(IDENTITYID, VALIDATIONID, CASEID, NAMENO)
		select	C.value(N'IDENTITYID[1]',  N'int') as IDENTITYID,
			C.value(N'VALIDATIONID[1]',N'int') as VALIDATIONID,
			C.value(N'CASEID[1]',      N'int') as CASEID,
			C.value(N'NAMENO[1]',      N'int') as NAMENO
		from @pxValidationIdXML.nodes(N'/LogValidation/LogRow') FAILLOG(C)

		Set @ErrorCode=@@Error		

		-- Commit or Rollback the transaction
		
		If @@TranCount > @TranCountStart
		Begin
			If @ErrorCode = 0
				COMMIT TRANSACTION
			Else
				ROLLBACK TRANSACTION
		End
		
		-- Terminate the WHILE loop
		Set @nRetry=-1
	END TRY	

	---------------------------------
	-- D E A D L O C K   V I C T I M   
	--       P R O C E S S I N G
	---------------------------------
	BEGIN CATCH
		------------------------------------------
		-- If the process has been made the victim
		-- of a deadlock (error 1205), then allow 
		-- another attempt to apply the updates 
		-- to the database up to a retry limit.
		------------------------------------------
		If ERROR_NUMBER()=1205
		Begin
			Set @nRetry=@nRetry-1
			WAITFOR DELAY '0:0:05'	-- pause for 5 seconds
		End
		Else
			Set @nRetry=-1
			
		If XACT_STATE()<>0
			Rollback Transaction
		
		If @nRetry<1
			Set @ErrorCode=ERROR_NUMBER()
	END CATCH
END -- While loop

return @ErrorCode
go

grant execute on dbo.ip_InsertDataValidationFailLog  to public
go

