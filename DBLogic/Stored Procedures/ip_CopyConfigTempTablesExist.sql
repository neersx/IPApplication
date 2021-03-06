-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_CopyConfigTempTablesExist
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].ip_CopyConfigTempTablesExist') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_CopyConfigTempTablesExist.'
	drop procedure dbo.ip_CopyConfigTempTablesExist
	print '**** Creating procedure dbo.ip_CopyConfigTempTablesExist...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE [dbo].[ip_CopyConfigTempTablesExist]
	@psUserName			nvarchar(40),  -- mandatory
	@pbAllTempTablesExists		bit OUTPUT
AS

-- VERSION :	12
-- DESCRIPTION:	This procedure checks if all the CCImport_* temp tables
--		for the specified user exists
-- EXPECTS:	@psUserName
-- RETURNS:	Errorcode
-- SCOPE:	CPA Inpro
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 02/02/2012	AvdA		1	Creation based on ip_RulesTempTablesExist.
-- 01/06/2012	AvdA		2	Fix the logic.
-- 31/7/2012	AvdA		3	Regenerated after table changes.
-- 07/09/2012	AvdA		4	Remove TABLEATTRIBUTES
-- 03/10/2012	AvdA		5	Add genned GROUPMEMBERS
-- 02 Oct 2014	MF	32711	6	Add copy functionality for TOPICCONTROLFILTER
-- 10 Apr 2017	MF	42541	7	Removed table STATUSSEQUENCE references.
--					Added TOPICUSAGE table.
-- 01 May 2017	MF	71205	8	Add copy functionality for ROLESCONTROL
-- 21 Aug 2019	MF	DR-42774 9	Add copy functionality for PROGRAM
-- 21 Aug 2019	MF	DR-36783 10	Add copy functionality for FORMFIELDS
-- 21 Aug 2019	MF	DR-51238 10	Added CONFIGURATIONITEMGROUP table
-- 06 Dec 2019	MF	DR-28833 11	Added EVENTTEXTTYPE table
-- 23 Mar 2020	BS	DR-57435 12	DB public role missing execute permission on some stored procedures and functions

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
Set @pbAllTempTablesExists = 0
Set @bInterimTableExists = 1

If @ErrorCode=0
Begin

-- Paste generated code here
-------------------------------

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ACCT_TRANS_TYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ACTIONS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ADJUSTMENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_AIRPORT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ALERTTEMPLATE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ALIASTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ANALYSISCODE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_APPLICATIONBASIS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ATTRIBUTES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_B2BELEMENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_B2BTASKEVENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_BUSINESSFUNCTION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_BUSINESSRULECONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CASECATEGORY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CASERELATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CASETYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CHARGERATES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CHARGETYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CHECKLISTITEM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CHECKLISTLETTER')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CHECKLISTS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CONFIGURATIONITEM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CONFIGURATIONITEMGROUP')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_COPYPROFILE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CORRESPONDTO')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_COUNTRY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_COUNTRYFLAGS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_COUNTRYGROUP')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_COUNTRYTEXT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CPAEVENTCODE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CPANARRATIVE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CRITERIA')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CRITERIA_ITEMS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CRITERIACHANGES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CULTURE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_CULTURECODEPAGE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DATASOURCE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DATATOPIC')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DATAVALIDATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DATAVIEW')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DATESLOGIC')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DEBTOR_ITEM_TYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DEBTORSTATUS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DELIVERYMETHOD')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DETAILCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DETAILDATES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DETAILLETTERS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DOCUMENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DOCUMENTDEFINITION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DOCUMENTDEFINITIONACTINGAS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_DUEDATECALC')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDEREQUESTTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULECASE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULECASEEVENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULECASENAME')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULECASETEXT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULEOFFICIALNUMBER')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EDERULERELATEDCASE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ELEMENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ELEMENTCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ENCODEDVALUE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ENCODINGSCHEME')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ENCODINGSTRUCTURE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTCATEGORY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTCONTROLNAMEMAP')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTCONTROLREQEVENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTSREPLACED')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTTEXTTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EVENTUPDATEPROFILE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_EXTERNALSYSTEM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEATURE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEATUREMODULE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEATURETASK')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEESCALCALT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEESCALCULATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FEETYPES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FIELDCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FILELOCATIONOFFICE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FORMFIELDS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_FREQUENCY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_GROUPMEMBERS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_GROUPS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_HOLIDAYS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_IMPORTANCE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_INHERITS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_INSTRUCTIONFLAG')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_INSTRUCTIONLABEL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_INSTRUCTIONS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_INSTRUCTIONTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_IRFORMAT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ITEM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ITEM_GROUP')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ITEM_NOTE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_LANGUAGE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_LETTER')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MAPPING')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MAPSCENARIO')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MAPSTRUCTURE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MODULE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MODULECONFIGURATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_MODULEDEFINITION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NAMECRITERIA')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NAMECRITERIAINHERITS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NAMEGROUPS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NAMERELATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NAMETYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NARRATIVE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NARRATIVERULE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_NUMBERTYPES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_OFFICE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PAYMENTMETHODS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PERMISSIONS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PORTAL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PORTALMENU')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PORTALSETTING')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PORTALTAB')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PORTALTABCONFIGURATION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROFILEATTRIBUTES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROFILEPROGRAM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROFILES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROFITCENTRE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROFITCENTRERULE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROGRAM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROPERTYTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_PROTECTCODES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_QUANTITYSOURCE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_QUERYCONTEXT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_QUERYDATAITEM')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_QUESTION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RATES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_REASON')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RECORDALELEMENT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RECORDALTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RECORDTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RELATEDEVENTS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_REMINDERS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_REQATTRIBUTES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_RESOURCE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ROLE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ROLESCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ROLETASKS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_ROLETOPICS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SCREENCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SCREENS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SELECTIONTYPES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_STATE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_STATUS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_STATUSCASETYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SUBJECT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SUBJECTAREA')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SUBJECTAREATABLES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_SUBTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TABCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TABLECODES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TABLETYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TASK')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TAXRATESCOUNTRY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TEXTTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TITLES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TMCLASS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICCONTROLFILTER')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICDATAITEMS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICDEFAULTSETTINGS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TOPICUSAGE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_TRANSACTIONREASON')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDACTDATES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDACTION')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDATENUMBERS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDBASIS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDBASISEX')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDCATEGORY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDCHECKLISTS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDEXPORTFORMAT')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDPROPERTY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDRELATIONSHIPS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDSTATUS')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDSUBTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_VALIDTABLECODES')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_WINDOWCONTROL')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_WIPATTRIBUTE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_WIPCATEGORY')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_WIPTEMPLATE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- Check existence of Imported Table.
If @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @bInterimTableExists = 0
	Set @sSQLString="SELECT @bInterimTableExists = 1 
			 from sysobjects 
			 where id = object_id('CCImport_WIPTYPE')"
			Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bInterimTableExists	bit OUTPUT',
			  @bInterimTableExists 	= @bInterimTableExists OUTPUT
end

-- end of generated code
--------------------------------

If  @ErrorCode=0
and @bInterimTableExists=1
Begin
	Set @pbAllTempTablesExists = 1
end

End

RETURN @ErrorCode
GO

grant execute on dbo.ip_CopyConfigTempTablesExist  to public
go

