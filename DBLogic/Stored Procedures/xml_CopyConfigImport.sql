-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_CopyConfigImport
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_CopyConfigImport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_CopyConfigImport.'
	drop procedure dbo.xml_CopyConfigImport
end
print '**** Creating procedure dbo.xml_CopyConfigImport...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.xml_CopyConfigImport
			@pnRowCount	int=0	OUTPUT,
			@psUserName	nvarchar(40),
			@pnMode		int=0			-- 0 do nothing, 1 = cleanup, 2 = do something 
AS

-- PROCEDURE :	xml_CopyConfigImport
-- VERSION :	11
-- DESCRIPTION:	Executed after bulk import process via Import Server.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 15 Jan 2012	AvdA		1	Procedure created (based on xml_RulesImport v 4)
-- 31 Feb 2012	BSH		2	Only perform overview creation and population for mode 2
-- 07/09/2012	AvdA		3	Remove TABLEATTRIBUTES
-- 03/10/2012	AvdA		4	Include genned GROUPMEMBERS
-- 02 Oct 2014	MF	32711	5 	Procedure created
-- 22 Dec 2014	Ak	42541	6	Removed table STATUSSEQUENCE references.
-- 10 Apr 2017	MF	42541	7	Added TOPICUSAGE table.
-- 01 May 2017	MF	71205	8	Added ROLESCONTROL table.
-- 21 Aug 2019	MF	DR-42774 9	Added PROGRAM table.
-- 21 Aug 2019	MF	DR-36783 10	Added FORMFIELDS table
-- 21 Aug 2019	MF	DR-51238 10	Added CONFIGURATIONITEMGROUP table
-- 06 Dec 2019	MF	DR-28833 11	Added EVENTTEXTTYPE table

set nocount on
set concat_null_yields_null off
set ansi_warnings off


Declare	@ErrorCode 	int
Declare	@sUserName	nvarchar(40)
Declare @bImportedOverviewExists bit
Declare @sSQLString nvarchar(max)

-- Initialize variables
Set @ErrorCode = 0
Set @sUserName = @psUserName

If @ErrorCode = 0 and @pnMode = 2
begin
	
	-- Check existence of CCImport_OVERVIEW Table. Drop and recreate.
	Set @bImportedOverviewExists = 0
	If @ErrorCode=0
	Begin
		Set @sSQLString="SELECT @bImportedOverviewExists = 1 
				 from sysobjects 
				 where id = object_id('CCImport_OVERVIEW')"
				Exec @ErrorCode=sp_executesql @sSQLString,
				N'@bImportedOverviewExists	bit OUTPUT',
				  @bImportedOverviewExists 	= @bImportedOverviewExists OUTPUT
	end
	
	If  @ErrorCode=0
	and @bImportedOverviewExists=1
	Begin
		Set @sSQLString=" DROP TABLE CCImport_OVERVIEW"
		exec @ErrorCode=sp_executesql @sSQLString
	end
	
	If @ErrorCode=0
	Begin
		Set @sSQLString="CREATE TABLE  CCImport_OVERVIEW
		(	ID int IDENTITY(1,1), 
		TRIPNO int , 
		TABLENAME varchar(50),
		NEW int, 
		MISSING int, 
		CHANGE int,
		MATCH int )"
		exec @ErrorCode=sp_executesql @sSQLString
	end
	
	-- Now call each of the Count functions to populate the table for various trips/tabs.
	-- Paste generated code here.
------------------------------------------------------------

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnACCT_TRANS_TYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnACTIONS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnADJUSTMENT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnAIRPORT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnALERTTEMPLATE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnALIASTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnANALYSISCODE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnAPPLICATIONBASIS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnATTRIBUTES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnB2BELEMENT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnB2BTASKEVENT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnBUSINESSFUNCTION('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnBUSINESSRULECONTRO_('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCASECATEGORY('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCASERELATION('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCASETYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCHARGERATES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCHARGETYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCHECKLISTITEM('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCHECKLISTLETTER('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCHECKLISTS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCONFIGURATIONITEM('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCONFIGURATIONITEMGROUP('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCOPYPROFILE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCORRESPONDTO('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCOUNTRY('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCOUNTRYFLAGS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCOUNTRYGROUP('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCOUNTRYTEXT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCPAEVENTCODE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCPANARRATIVE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCRITERIA('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCRITERIA_ITEMS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCRITERIACHANGES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCULTURE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnCULTURECODEPAGE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDATASOURCE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDATATOPIC('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDATAVALIDATION('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDATAVIEW('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDATESLOGIC('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDEBTOR_ITEM_TYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDEBTORSTATUS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDELIVERYMETHOD('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDETAILCONTROL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDETAILDATES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDETAILLETTERS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDOCUMENT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDOCUMENTDEFINITION('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDOCUMENTDEFINITION_('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnDUEDATECALC('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEDEREQUESTTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEDERULECASE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEDERULECASEEVENT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEDERULECASENAME('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEDERULECASETEXT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEDERULEOFFICIALNUM_('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEDERULERELATEDCASE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnELEMENT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnELEMENTCONTROL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnENCODEDVALUE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnENCODINGSCHEME('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnENCODINGSTRUCTURE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEVENTCATEGORY('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEVENTCONTROL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEVENTCONTROLNAMEMA_('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEVENTCONTROLREQEVE_('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEVENTS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEVENTSREPLACED('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEVENTTEXTTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEVENTUPDATEPROFILE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnEXTERNALSYSTEM('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnFEATURE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnFEATUREMODULE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnFEATURETASK('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnFEESCALCALT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnFEESCALCULATION('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnFEETYPES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnFIELDCONTROL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnFILELOCATIONOFFICE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnFORMFIELDS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnFREQUENCY('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnGROUPMEMBERS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnGROUPS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnHOLIDAYS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnIMPORTANCE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnINHERITS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnINSTRUCTIONFLAG('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnINSTRUCTIONLABEL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnINSTRUCTIONS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnINSTRUCTIONTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnIRFORMAT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnITEM('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnITEM_GROUP('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnITEM_NOTE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnLANGUAGE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnLETTER('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnMAPPING('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnMAPSCENARIO('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnMAPSTRUCTURE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnMODULE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnMODULECONFIGURATIO_('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnMODULEDEFINITION('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnNAMECRITERIA('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnNAMECRITERIAINHERI_('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnNAMEGROUPS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnNAMERELATION('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnNAMETYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnNARRATIVE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnNARRATIVERULE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnNUMBERTYPES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnOFFICE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPAYMENTMETHODS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPERMISSIONS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPORTAL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPORTALMENU('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPORTALSETTING('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPORTALTAB('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPORTALTABCONFIGURA_('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPROFILEATTRIBUTES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPROFILEPROGRAM('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPROFILES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPROFITCENTRE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPROFITCENTRERULE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPROGRAM('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPROPERTYTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnPROTECTCODES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnQUANTITYSOURCE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnQUERYCONTEXT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnQUERYDATAITEM('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnQUESTION('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnRATES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnREASON('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnRECORDALELEMENT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnRECORDALTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnRECORDTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnRELATEDEVENTS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnREMINDERS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnREQATTRIBUTES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnRESOURCE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnROLE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnROLESCONTROL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnROLETASKS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnROLETOPICS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnSCREENCONTROL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnSCREENS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnSELECTIONTYPES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnSTATE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnSTATUS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnSTATUSCASETYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnSUBJECT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnSUBJECTAREA('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnSUBJECTAREATABLES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnSUBTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTABCONTROL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTABLECODES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTABLETYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTASK('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTAXRATESCOUNTRY('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTEXTTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTITLES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTMCLASS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTOPICCONTROL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTOPICCONTROLFILTER('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTOPICDATAITEMS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTOPICDEFAULTSETTIN_('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTOPICS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTOPICUSAGE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnTRANSACTIONREASON('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDACTDATES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDACTION('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDATENUMBERS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDBASIS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDBASISEX('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDCATEGORY('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDCHECKLISTS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDEXPORTFORMAT('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDPROPERTY('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDRELATIONSHIPS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDSTATUS('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDSUBTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnVALIDTABLECODES('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnWINDOWCONTROL('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnWIPATTRIBUTE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnWIPCATEGORY('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnWIPTEMPLATE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

If @ErrorCode=0
Begin
	Set @sSQLString="insert into CCImport_OVERVIEW (TRIPNO, TABLENAME, MISSING, NEW, CHANGE, MATCH)
		select * from dbo.fn_ccnWIPTYPE('"+@sUserName+"')"
	exec @ErrorCode=sp_executesql @sSQLString
end

-- end of generated code
------------------------------------------------------------
end -- of mode 2 section

If @ErrorCode = 0 and @pnMode = 1
Begin
	-- Create new cleanup sp for all the other config tables
	exec @ErrorCode=ip_CopyConfigTempTableCleanup @sUserName
End

Return @ErrorCode
go

grant execute on dbo.xml_CopyConfigImport to public
go

