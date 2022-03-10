-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesTempTableCleanup
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ip_RulesTempTableCleanup]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ip_RulesTempTableCleanup.'
	Drop procedure [dbo].[ip_RulesTempTableCleanup]
End
Print '**** Creating Stored Procedure dbo.ip_RulesTempTableCleanup...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE dbo.ip_RulesTempTableCleanup
	@psUserName			nvarchar(40)  -- mandatory
AS

-- VERSION :	4
-- DESCRIPTION:	This procedure drops all the IMPORTED_* temp tables
--		for the specified user
-- EXPECTS:	@psUserName
-- RETURNS:	Errorcode
-- SCOPE:	CPA Inpro
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 8/02/2005	PK	10796	1	Initial creation
-- 24 Oct 2006	MF	13466	2	Two new tables INSTRUCTIONTYPE and INSTRUCTIONLABEL to consider
-- 16 AUG 2007	MF	15018	3	Include TABLEATTRIBUTES table
-- 06 Nov 2013	MF	R28126	4	Include CRITERIAALLOWED table which is an interim table.

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

-- Declare variables
Declare @sSQLString		nvarchar(4000),
	@ErrorCode		int,
	@nTranCountStart	int,
	@sUserName		nvarchar(40),
	@bInterimTableExists	bit

-- Initialize variables
Set @sUserName	= @psUserName
Set @ErrorCode = 0

If @ErrorCode=0
Begin
-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('"+@sUserName+".Imported_ACTIONS')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_ACTIONS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects
			 where id = object_id('"+@sUserName+".Imported_ADJUSTMENT')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_ADJUSTMENT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('"+@sUserName+".Imported_APPLICATIONBASIS')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_APPLICATIONBASIS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 WHERE id = object_id('"+@sUserName+".Imported_CASECATEGORY')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_CASECATEGORY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 WHERE id = object_id('"+@sUserName+".Imported_CASERELATION')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_CASERELATION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 WHERE id = object_id('"+@sUserName+".Imported_CHECKLISTITEM')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_CHECKLISTITEM"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 WHERE id = object_id('"+@sUserName+".Imported_CHECKLISTLETTER')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_CHECKLISTLETTER"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 WHERE id = object_id('"+@sUserName+".Imported_CHECKLISTS')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_CHECKLISTS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects WHERE id = object_id('"+@sUserName+".Imported_COUNTRY')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_COUNTRY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_COUNTRYFLAGS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_COUNTRYFLAGS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_COUNTRYGROUP'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_COUNTRYGROUP"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_COUNTRYTEXT'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_COUNTRYTEXT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_CRITERIA'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_CRITERIA"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_DATESLOGIC'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_DATESLOGIC"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_DETAILCONTROL'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_DETAILCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_DETAILDATES'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_DETAILDATES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_DETAILLETTERS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_DETAILLETTERS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_DUEDATECALC'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_DUEDATECALC"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_EVENTCONTROL'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_EVENTCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_EVENTS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_EVENTS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_INHERITS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_INSTRUCTIONLABEL'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_INSTRUCTIONLABEL"
	exec @ErrorCode=sp_executesql @sSQLString
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_INHERITS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_INSTRUCTIONTYPE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_INSTRUCTIONTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_ITEM'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_ITEM"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_LETTER'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_LETTER"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_NUMBERTYPES'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_NUMBERTYPES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_PROPERTYTYPE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_PROPERTYTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_QUESTION'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_QUESTION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_RELATEDEVENTS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_RELATEDEVENTS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_SCREENCONTROL'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_SCREENCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_SITECONTROL'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_SITECONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_STATE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_STATE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_STATUS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_STATUS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_SUBTYPE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_SUBTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_TABLEATTRIBUTES'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_TABLEATTRIBUTES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_TABLECODES'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_TABLECODES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_TABLETYPE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_TABLETYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_TMCLASS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_TMCLASS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDACTDATES'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_VALIDACTDATES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDACTION'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_VALIDACTION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDATENUMBERS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_VALIDATENUMBERS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDBASIS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_VALIDBASIS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDCATEGORY'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_VALIDCATEGORY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDCHECKLISTS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_VALIDCHECKLISTS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDPROPERTY'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_VALIDPROPERTY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDRELATIONSHIPS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_VALIDRELATIONSHIPS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDSTATUS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_VALIDSTATUS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_VALIDSUBTYPE'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_VALIDSUBTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where exists (SELECT * FROM sysobjects WHERE id = object_id('"+@sUserName+".Imported_REMINDERS'))"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".Imported_REMINDERS"
	exec @ErrorCode=sp_executesql @sSQLString
end

--------------------------------------
-- Check existence of CRITERIAALLOWED
--------------------------------------
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('"+@sUserName+".CRITERIAALLOWED')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString="DROP TABLE "+@sUserName+".CRITERIAALLOWED"
	exec @ErrorCode=sp_executesql @sSQLString
end

End

RETURN @ErrorCode
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.ip_RulesTempTableCleanup to public
go
