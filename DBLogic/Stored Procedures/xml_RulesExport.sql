-----------------------------------------------------------------------------------------------------------------------------
-- Creation of xml_RulesExport
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[xml_RulesExport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.xml_RulesExport.'
	drop procedure dbo.xml_RulesExport
	print '**** Creating procedure dbo.xml_RulesExport...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go

CREATE PROCEDURE dbo.xml_RulesExport
-- no params for complete current set of rules
	
AS

-- PROCEDURE :	xml_RulesExport
-- VERSION :	19
-- DESCRIPTION:	Extract specified data from the database 
-- 		as XML to match the LawImport.xsd 
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 27 Apr 2004	AvdA		1	Procedure created
-- 12 Jul 2004	MF		2	Restrict extraction of data to only items related to CPA Law Care rules.
-- 29 Jul 2004	MF	10225	3	Ensure all referenced Events and Actions are exported.
-- 04 Oct 2005	MF	11934	4	Ensure all referenced Actions are exported.
-- 21 Feb 2006	MF	11934	5	Revisit to correct syntax error
-- 06 Mar 2006	MF	11942	6	New columns added to VALIDPROPERTY
-- 24 Oct 2006	MF	13466	7	Export INSTRUCTIONTYPE and INSTRUCTIONLABEL
-- 06 Nov 2006	MF	13769	8	Export Relationships referred to by Data Comparison rules.
-- 21 Feb 2007	MF	14398	9	Export RECALCEVENTDATE in the EVENTS and EVENTCONTROL tables
-- 21 May 2007	MF	13936	10	Generate a datetime stamp at the time of extraction of the rules
--					which will be imported into a special SITECONTROL as a record of the
--					last rules imported.
-- 16 Aug 2007	MF	15018	11	Export TABLEATTRIBUTES associated with Country
-- 25 Mar 2008	MF	16144	12	Export EVENTNO referenced by NUMBERTYPES.RELATEDEVENTNO
-- 11 Sep 2008	MF	16899	13	Export new columns RELATEDEVENTS.CLEAREVENTONDUECHANGE and
--					CLEARDUEONDUECHANGE
-- 16 Apr 2009	MF	17472	14	Export new column COUNTRYGROUP.PREVENTNATPHASE
-- 17 Apr 2009	MF	16955	15	Export new columns on DUEDATECALC table for COMPARERELATIONSHIP,  COMPAREDATE,  COMPARESYSTEMDATE
-- 17 Apr 2009	MF	16548	16	Export new columns on CASERELATION table for FROMEVENTNO,  DISPLAYEVENTNO
-- 28 Jan 2011	MF	19371	17	Only export TABLETYPE rows that are explicitly referenced by the exported laws.
-- 25 Oct 2011	MF	20074	18	Body of this stored procedure moved into xml_RulesExportAction so that procedure may be called
--					using specific Actions to extract.
-- 26 Oct 2011	AvdA	20074	19	Parameter tweak.

SET NOCOUNT ON

declare @nErrorCode	int

Set @nErrorCode=0

if @nErrorCode = 0
begin
	exec @nErrorCode=dbo.xml_RulesExportAction
					@psActions='~1,~2',
					@pbContent=1	-- 1 = All content required for Law Update Service
									--     including the "CPA Law Update Service" SiteControl
End
 
RETURN @nErrorCode
GO

grant execute on dbo.xml_RulesExport  to public
go