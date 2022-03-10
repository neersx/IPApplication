-----------------------------------------------------------------------------------------------------------------------------
-- Creation of de_CaseComparisonRemove
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[de_CaseComparisonRemove]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.de_CaseComparisonRemove.'
	drop procedure [dbo].[de_CaseComparisonRemove]
End
Print '**** Creating Stored Procedure dbo.de_CaseComparisonRemove...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.de_CaseComparisonRemove
(
	@pnUserIdentityId	int,		-- Mandatory
	@psTableNameQualifier	nvarchar(15) 	-- A qualifier appended to the table names to ensure that they are unique.

)
as
-- PROCEDURE:	de_CaseComparisonRemove
-- VERSION:	4
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Removes the work tables used by the case comparison process.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 05 Sep 2005	JEK	RFC1324	1	Procedure created
-- 22 Sep 2005	JEK	RFC1324	2	More tables
-- 23 Sep 2005	JEK	RFC1324	3	Extend processing.
-- 07 Apr 2016  MS      R52206  4       Added quotename before using table variables to avoid sql injection

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString	nvarchar(4000)
declare	@sTimeStamp	nvarchar(24)

declare @sSenderTable		nvarchar(50)
declare @sCaseTable		nvarchar(50)
declare @sOfficialNumberTable	nvarchar(50)
declare @sRelatedCaseTable	nvarchar(50)
declare @sEventTable		nvarchar(50)
declare @sCaseNameTable		nvarchar(50)

-- Initialise variables
Set @nErrorCode = 0
Set @sSenderTable = quotename('CC_SENDER' + @psTableNameQualifier, '')
Set @sCaseTable = quotename('CC_CASE' + @psTableNameQualifier, '')
Set @sOfficialNumberTable = quotename('CC_OFFICIALNUMBER' + @psTableNameQualifier, '')
Set @sRelatedCaseTable = quotename('CC_RELATEDCASE' + @psTableNameQualifier, '')
Set @sEventTable = quotename('CC_CASEEVENT' + @psTableNameQualifier, '')
Set @sCaseNameTable = quotename('CC_CASENAME' + @psTableNameQualifier, '')

-- Tables should be cleaned up regardless of errors

If exists(select * from dbo.sysobjects where name = @sSenderTable )
Begin
	Set @sSQLString = "drop table "+@sSenderTable
	exec sp_executesql @sSQLString
End

If exists(select * from dbo.sysobjects where name = @sCaseTable )
Begin
	Set @sSQLString = "drop table "+@sCaseTable
	exec sp_executesql @sSQLString
End

If exists(select * from dbo.sysobjects where name = @sOfficialNumberTable )
Begin
	Set @sSQLString = "drop table "+@sOfficialNumberTable
	exec sp_executesql @sSQLString
End

If exists(select * from dbo.sysobjects where name = @sRelatedCaseTable )
Begin
	Set @sSQLString = "drop table "+@sRelatedCaseTable
	exec sp_executesql @sSQLString
End

If exists(select * from dbo.sysobjects where name = @sEventTable )
Begin
	Set @sSQLString = "drop table "+@sEventTable
	exec sp_executesql @sSQLString
End

If exists(select * from dbo.sysobjects where name = @sCaseNameTable )
Begin
	Set @sSQLString = "drop table "+@sCaseNameTable
	exec sp_executesql @sSQLString
End

Return @nErrorCode
GO

Grant execute on dbo.de_CaseComparisonRemove to public
GO
