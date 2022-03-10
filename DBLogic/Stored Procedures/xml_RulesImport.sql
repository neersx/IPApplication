-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_RulesImport
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_RulesImport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_RulesImport.'
	drop procedure dbo.xml_RulesImport
end
print '**** Creating procedure dbo.xml_RulesImport...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.xml_RulesImport
			@pnRowCount	int=0	OUTPUT,
			@psUserName	nvarchar(40),
			@pnMode		int=2			-- 1 = cleanup 2 = process (2)
AS

-- PROCEDURE :	xml_RulesImport
-- VERSION :	3
-- DESCRIPTION:	Executed after bulk import process via Import Server.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 17 Oct 2003	AvdA		1	Procedure created
-- 28 Jul 2004	MF	10225	2	No processing required so just return an error code of 0.
-- 8 Feb  2005	PK	10796	3	Add new @pnMode parameter
-- 21 Sep 2005	VL	11665	4	Swap the parameters around so the OUTPUT parameter is first

Set nocount on

Declare	@ErrorCode 	int
Declare	@sUserName	nvarchar(40)

-- Initialize variables
Set @ErrorCode = 0
Set @sUserName = @psUserName

-- Any future processing code would be inserted here

If @ErrorCode = 0 and @pnMode = 1
Begin
	exec @ErrorCode=ip_RulesTempTableCleanup @sUserName
End

Return @ErrorCode
go

grant execute on dbo.xml_RulesImport  to public
go
