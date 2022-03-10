-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_ImportJournalCleanup
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[xml_ImportJournalCleanup]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.xml_ImportJournalCleanup.'
	Drop procedure [dbo].[xml_ImportJournalCleanup]
End
Print '**** Creating Stored Procedure dbo.xml_ImportJournalCleanup...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.xml_ImportJournalCleanup
	@psUserName			nvarchar(40)  -- mandatory
AS

-- VERSION :	1
-- DESCRIPTION:	This procedure drops the IMPORTJOURNALBULK temp table
--		for the specified user
-- EXPECTS:	@psUserName
-- RETURNS:	Errorcode
-- SCOPE:	CPA Inpro
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 14/02/2005	PK	10796	1	Initial creation
				

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare @sSQLString		nvarchar(4000),
	@ErrorCode		int,
	@sUserName		nvarchar(40),
	@bInterimTableExists	bit

-- Initialize variables
Set @sUserName	= @psUserName
Set @ErrorCode = 0

If @ErrorCode=0
Begin
	-- Clean up of temp table
	Set @bInterimTableExists = 0
	Set @sUserName = @psUserName
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="SELECT @bInterimTableExists = 1 
				 from sysobjects 
				 where id = object_id('"+@sUserName+".IMPORTJOURNALBULK')"
		Exec @ErrorCode=sp_executesql @sSQLString,
				N'@bInterimTableExists	bit OUTPUT',
				  @bInterimTableExists 	= @bInterimTableExists OUTPUT
	End
	If  @ErrorCode=0 and @bInterimTableExists=1
	Begin
		Set @sSQLString="DROP TABLE "+@sUserName+".IMPORTJOURNALBULK"
		exec @ErrorCode=sp_executesql @sSQLString
	End
End

RETURN @ErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.xml_ImportJournalCleanup to public
go
