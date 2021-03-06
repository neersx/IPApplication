-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_CopyConfigTempTableCleanup
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].ip_CopyConfigTempTableCleanup') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_CopyConfigTempTableCleanup.'
	drop procedure dbo.ip_CopyConfigTempTableCleanup
	print '**** Creating procedure dbo.ip_CopyConfigTempTableCleanup...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE [dbo].[ip_CopyConfigTempTableCleanup]
	@psUserName			nvarchar(40)  -- mandatory
AS

-- VERSION :	11
-- DESCRIPTION:	This procedure drops all the CCImport_* temp tables
--		for the specified user
-- EXPECTS:	@psUserName
-- RETURNS:	Errorcode
-- SCOPE:	CPA Inpro
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02/02/2012	AvdA		1	Creation based on ip_CopyConfigTempTableCleanup
-- 31/7/2012	AvdA		2	Regenerated after table changes.
-- 07/09/2012	AvdA		3	Remove TABLEATTRIBUTES
-- 09/10/2012   DH		4	POLICING cleanup - Manually added
-- 02 Oct 2014	MF	32711	5	Add copy functionality for TOPICCONTROLFILTER	
-- 10 Apr 2017	MF	42541	6	Add copy functionality for TOPICUSAGE
-- 01 May 2017	MF	71205	7	Add copy functionality for ROLESCONTROL.
-- 21 Aug 2019	MF	DR-42774 8	Add copy functionality for PROGRAM
-- 21 Aug 2019	MF	DR-36783 9	Add copy functionality for FORMFIELDS
-- 21 Aug 2019	MF	DR-51238 9	Added CONFIGURATIONITEMGROUP table
-- 06 Dec 2019	MF	DR-28833 10	Added EVENTTEXTTYPE table
-- 23 Mar 2020	BS	DR-57435 11	DB public role missing execute permission on some stored procedures and functions

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

-- First clear out OVERVIEW table
-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_OVERVIEW')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_OVERVIEW"
	exec @ErrorCode=sp_executesql @sSQLString
end

--Paste generated code here:
----------------------

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ACCT_TRANS_TYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ACCT_TRANS_TYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ACTIONS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ACTIONS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ADJUSTMENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ADJUSTMENT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_AIRPORT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_AIRPORT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ALERTTEMPLATE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ALERTTEMPLATE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ALIASTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ALIASTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ANALYSISCODE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ANALYSISCODE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_APPLICATIONBASIS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_APPLICATIONBASIS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ATTRIBUTES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ATTRIBUTES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_B2BELEMENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_B2BELEMENT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_B2BTASKEVENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_B2BTASKEVENT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_BUSINESSFUNCTION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_BUSINESSFUNCTION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_BUSINESSRULECONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_BUSINESSRULECONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CASECATEGORY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CASECATEGORY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CASERELATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CASERELATION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CASETYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CASETYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CHARGERATES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CHARGERATES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CHARGETYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CHARGETYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CHECKLISTITEM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CHECKLISTITEM"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CHECKLISTLETTER')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CHECKLISTLETTER"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CHECKLISTS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CHECKLISTS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CONFIGURATIONITEM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CONFIGURATIONITEM"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CONFIGURATIONITEMGROUP')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CONFIGURATIONITEMGROUP"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_COPYPROFILE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_COPYPROFILE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CORRESPONDTO')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CORRESPONDTO"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_COUNTRY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_COUNTRY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_COUNTRYFLAGS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_COUNTRYFLAGS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_COUNTRYGROUP')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_COUNTRYGROUP"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_COUNTRYTEXT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_COUNTRYTEXT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CPAEVENTCODE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CPAEVENTCODE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CPANARRATIVE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CPANARRATIVE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CRITERIA')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CRITERIA"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CRITERIA_ITEMS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CRITERIA_ITEMS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CRITERIACHANGES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CRITERIACHANGES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CULTURE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CULTURE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CULTURECODEPAGE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_CULTURECODEPAGE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DATASOURCE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DATASOURCE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DATATOPIC')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DATATOPIC"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DATAVALIDATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DATAVALIDATION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DATAVIEW')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DATAVIEW"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DATESLOGIC')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DATESLOGIC"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DEBTOR_ITEM_TYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DEBTOR_ITEM_TYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DEBTORSTATUS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DEBTORSTATUS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DELIVERYMETHOD')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DELIVERYMETHOD"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DETAILCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DETAILCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DETAILDATES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DETAILDATES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DETAILLETTERS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DETAILLETTERS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DOCUMENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DOCUMENT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DOCUMENTDEFINITION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DOCUMENTDEFINITION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DOCUMENTDEFINITIONACTINGAS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DOCUMENTDEFINITIONACTINGAS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DUEDATECALC')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_DUEDATECALC"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDEREQUESTTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EDEREQUESTTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULECASE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EDERULECASE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULECASEEVENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EDERULECASEEVENT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULECASENAME')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EDERULECASENAME"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULECASETEXT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EDERULECASETEXT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULEOFFICIALNUMBER')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EDERULEOFFICIALNUMBER"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULERELATEDCASE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EDERULERELATEDCASE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ELEMENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ELEMENT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ELEMENTCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ELEMENTCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ENCODEDVALUE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ENCODEDVALUE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ENCODINGSCHEME')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ENCODINGSCHEME"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ENCODINGSTRUCTURE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ENCODINGSTRUCTURE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTCATEGORY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EVENTCATEGORY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EVENTCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTCONTROLNAMEMAP')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EVENTCONTROLNAMEMAP"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTCONTROLREQEVENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EVENTCONTROLREQEVENT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EVENTS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTSREPLACED')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EVENTSREPLACED"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTTEXTTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EVENTTEXTTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTUPDATEPROFILE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EVENTUPDATEPROFILE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EXTERNALSYSTEM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_EXTERNALSYSTEM"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEATURE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_FEATURE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEATUREMODULE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_FEATUREMODULE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEATURETASK')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_FEATURETASK"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEESCALCALT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_FEESCALCALT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEESCALCULATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_FEESCALCULATION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEETYPES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_FEETYPES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FIELDCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_FIELDCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FILELOCATIONOFFICE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_FILELOCATIONOFFICE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FORMFIELDS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_FORMFIELDS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FREQUENCY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_FREQUENCY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_GROUPMEMBERS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_GROUPMEMBERS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_GROUPS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_GROUPS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_HOLIDAYS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_HOLIDAYS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_IMPORTANCE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_IMPORTANCE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_INHERITS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_INHERITS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_INSTRUCTIONFLAG')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_INSTRUCTIONFLAG"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_INSTRUCTIONLABEL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_INSTRUCTIONLABEL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_INSTRUCTIONS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_INSTRUCTIONS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_INSTRUCTIONTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_INSTRUCTIONTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_IRFORMAT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_IRFORMAT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ITEM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ITEM"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ITEM_GROUP')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ITEM_GROUP"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ITEM_NOTE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ITEM_NOTE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_LANGUAGE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_LANGUAGE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_LETTER')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_LETTER"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MAPPING')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_MAPPING"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MAPSCENARIO')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_MAPSCENARIO"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MAPSTRUCTURE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_MAPSTRUCTURE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MODULE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_MODULE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MODULECONFIGURATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_MODULECONFIGURATION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MODULEDEFINITION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_MODULEDEFINITION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NAMECRITERIA')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_NAMECRITERIA"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NAMECRITERIAINHERITS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_NAMECRITERIAINHERITS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NAMEGROUPS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_NAMEGROUPS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NAMERELATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_NAMERELATION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NAMETYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_NAMETYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NARRATIVE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_NARRATIVE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NARRATIVERULE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_NARRATIVERULE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NUMBERTYPES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_NUMBERTYPES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_OFFICE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_OFFICE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PAYMENTMETHODS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PAYMENTMETHODS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PERMISSIONS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PERMISSIONS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_POLICING')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_POLICING"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PORTAL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PORTAL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PORTALMENU')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PORTALMENU"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PORTALSETTING')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PORTALSETTING"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PORTALTAB')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PORTALTAB"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PORTALTABCONFIGURATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PORTALTABCONFIGURATION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROFILEATTRIBUTES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PROFILEATTRIBUTES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROFILEPROGRAM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PROFILEPROGRAM"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROFILES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PROFILES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROFITCENTRE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PROFITCENTRE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROFITCENTRERULE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PROFITCENTRERULE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROGRAM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PROGRAM"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROPERTYTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PROPERTYTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROTECTCODES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_PROTECTCODES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_QUANTITYSOURCE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_QUANTITYSOURCE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_QUERYCONTEXT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_QUERYCONTEXT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_QUERYDATAITEM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_QUERYDATAITEM"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_QUESTION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_QUESTION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RATES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_RATES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_REASON')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_REASON"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RECORDALELEMENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_RECORDALELEMENT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RECORDALTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_RECORDALTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RECORDTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_RECORDTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RELATEDEVENTS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_RELATEDEVENTS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_REMINDERS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_REMINDERS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_REQATTRIBUTES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_REQATTRIBUTES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RESOURCE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_RESOURCE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ROLE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ROLE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ROLESCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ROLESCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ROLETASKS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ROLETASKS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ROLETOPICS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_ROLETOPICS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SCREENCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_SCREENCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SCREENS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_SCREENS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SELECTIONTYPES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_SELECTIONTYPES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_STATE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_STATE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_STATUS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_STATUS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_STATUSCASETYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_STATUSCASETYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_STATUSSEQUENCE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_STATUSSEQUENCE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SUBJECT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_SUBJECT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SUBJECTAREA')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_SUBJECTAREA"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SUBJECTAREATABLES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_SUBJECTAREATABLES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SUBTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_SUBTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TABCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TABCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TABLECODES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TABLECODES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TABLETYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TABLETYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TASK')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TASK"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TAXRATESCOUNTRY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TAXRATESCOUNTRY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TEXTTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TEXTTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TITLES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TITLES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TMCLASS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TMCLASS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TOPICCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICCONTROLFILTER')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TOPICCONTROLFILTER"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICDATAITEMS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TOPICDATAITEMS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICDEFAULTSETTINGS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TOPICDEFAULTSETTINGS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TOPICS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICUSAGE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TOPICUSAGE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TRANSACTIONREASON')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_TRANSACTIONREASON"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDACTDATES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDACTDATES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDACTION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDACTION"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDATENUMBERS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDATENUMBERS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDBASIS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDBASIS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDBASISEX')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDBASISEX"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDCATEGORY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDCATEGORY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDCHECKLISTS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDCHECKLISTS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDEXPORTFORMAT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDEXPORTFORMAT"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDPROPERTY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDPROPERTY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDRELATIONSHIPS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDRELATIONSHIPS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDSTATUS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDSTATUS"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDSUBTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDSUBTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDTABLECODES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_VALIDTABLECODES"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_WINDOWCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_WINDOWCONTROL"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_WIPATTRIBUTE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_WIPATTRIBUTE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_WIPCATEGORY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_WIPCATEGORY"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_WIPTEMPLATE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_WIPTEMPLATE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- Check existence of Imported Table.
Set @bInterimTableExists = 0
If @ErrorCode=0
Begin
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_WIPTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end
If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @sSQLString=" DROP TABLE CCImport_WIPTYPE"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- end of generated code
----------------------
End

RETURN @ErrorCode
GO

grant execute on dbo.ip_CopyConfigTempTableCleanup  to public
go

