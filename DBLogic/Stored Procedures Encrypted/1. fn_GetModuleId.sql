-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetModuleId
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_GetModuleId]') and xtype in (N'FN', N'IF', N'TF'))
Begin
	Print '**** Drop Function dbo.fn_GetModuleId.'
	Drop function [dbo].[fn_GetModuleId]
End
Print '**** Creating Function dbo.fn_GetModuleId...'
Print ''
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetModuleId
	(	
		@psProgramName	varchar(100)
	)
Returns varchar(100)
With ENCRYPTION
AS
-- FUNCTION:	fn_GetModuleId
-- VERSION:	26
-- DESCRIPTION:	Returns the Module ID(s) for the passed program name
-- COPYRIGHT: 	Copyright CPA Software Solutions (Australia) Pty Limited

-- MODIFICATIONS :
-- Date		Who	Change	 Version Description
-- -----------	-------	------	 ------- ----------------------------------------------- 
--05/04/2004	JB		1	Function created
--14/09/2004	vl		2	fixed some spelling mistakes.
--27/10/2004	TM	RFC870	3	Replace 'CPA INPROSTART STANDALONE' and 'CPA INPROSTART MODULE' with
--					a single program 'CPA INPROSTART' that maps to two modules '01,03'.
--06/07/2005	IB	10718 	4	Added the CONFLICTSEARCH program to the Cases and Names group.	
--14/07/2005	vl	8348 	5	Added the AUDITTRAIL program to the Cases and Names group.
--06/09/2005	IB	11685 	6	Added the DATAMAPPING program to the Cases and Names group.	
--20/12/2005	KR	12107 	7	Added MARGIN PROFILE program to the core program group.
--16/06/2006	vql	12775 	8	Removed 'PTRPTS' and 'PTWSVR32' from the Cases and Names module.
--29/05/2006	vql	11588	9	Added new module E Filing, and include the B2BTASKS program in it.
--21/06/2006	vql	12426	10	Added NAMEMAPPING to Cases and Names module.
--24/10/2006	Dev	13009	11	Added a new module named EDE, included BATCHPROCESSING,IMPORTSVR,
--  					NAMEMAPPING,CASEREVIEW programs.
--21/11/2006	Dev	12866	12	Added a new module named Law Update and included the DATAWIZARD program
--08/03/2006	Dev	14536	13	Removed DATAWIZARD from the Cases module.
--05/06/2007	PK	14860	14	Add e-filing licencing to B2BConfiguration application
--05/06/2007	PK	14850	15	Remove redundant application DBNMNT and CHANGEFIELDFORMATS.
--10/12/2007	vql	15305	16	Adding a new module for CRM Workbenches.
--20/02/2008	CR	10105	17	Added a new module for Trust Accounting.
--14/03/2008	CR	10105	18	Added a new module for Administration WorkBenches. Also put in Clerical and Marketing WB.
--31/03/2008	DL	11964	19	Added new module PRIORART to CASE & NAME module.
--07/05/2008	vql	16293	20	Remove Web Access Module.
--17/11/2008	vql	16320	21	Cater for upgrading licences from Client Server to WorkBenches
--07/05/2010	vql	18394	22	Update licensing software for new module structure.
--26/08/2010	DL	10311	23	Added a new module 'TRANSGENERATION' 
--05/09/2012	DL	20594	24	Include Law Update program in licensing modules of Case & Name and IPMatter Management
--23/10/2013	DL	21696	25	EDE is to be protected by license restrictions
--08/07/2014	vql	33896	26	Include 'TRANSGENERATION' in 

Begin

	-- INPRO.EXE ???

	Declare @sModuleIds varchar(100)

	Set @sModuleIds = ''
	Set @psProgramName = UPPER(RTRIM(@psProgramName))
		
	If @psProgramName in ('CPA INPROSTART')
		Set @sModuleIds = @sModuleIds + ',01,03'
	
	If @psProgramName in (	'ALERTS', 	'BMP2PNG', 	'BULKREN',
				'CASE', 	'CASEEXPORTMC',
				'COUNTRY',	'CPAEXTRT',	'CPAINTERFACE', 
						'DOCITEMS',
				'DOCSVR32',	'EVTCON', 	'LETTERS', 
				'IPCNTRL',	'IMPJRNL',	'IMPORTSVR',
				'IRALLOCN',	'NAMES',	'POLREQST',
				'POLSVR',  	'NAMEMAPPING',
				'REMINDER', 	'SECURE', 	'SITECONT',
				'SOUNDEX',	'TABLES',	'CONFLICTSEARCH',
				'AUDITTRAIL',	'DATAMAPPING',	'MARGINPROFILE',
				'PRIORART', 'DATAWIZARD'
				)
		Set @sModuleIds = @sModuleIds + ',02' 	-- Cases and Names	
	If @psProgramName in ('CHGEN', 'FEES', 'IPCNTRL')
		Set @sModuleIds = @sModuleIds + ',04'  	-- Fee Generation & Fees List
	
	If @psProgramName in ('RECIPROCITYENQUIRY', 'STAFFPERFORMANCE', 'STATS')
		Set @sModuleIds = @sModuleIds + ',05'  	-- Reciprocity & Statistics
	
	If @psProgramName in ('TIMESHT', 'RATESMNT', 'WIP')
		Set @sModuleIds = @sModuleIds + ',06'	-- Timesheet
	
	If @psProgramName in ('BILLING', 'EXPENSEIMPORT', 'RATESMNT', 'WIP')
		Set @sModuleIds = @sModuleIds + ',07'	-- Billing
	
	If @psProgramName in ('QUOTATIONS')
		Set @sModuleIds = @sModuleIds + ',08'	-- Quotations
	
	If @psProgramName in ('ARTRANS', 'ARITEMIMPORT')
		Set @sModuleIds = @sModuleIds + ',09'	-- Accounts Receivable
	
	If @psProgramName in (	'CASHBOOK', 	'FINANCIALINTERFACE', 
				'GENERALLEDGER','JOURNALGENERATION', 'TRANSGENERATION')
		Set @sModuleIds = @sModuleIds + ',10'	-- General Ledger
	
	If @psProgramName in ('PAYABLE')
		Set @sModuleIds = @sModuleIds + ',11'	-- Accounts Payable
	
	If @psProgramName in ('FINANCIALINTERFACE')
		Set @sModuleIds = @sModuleIds + ',12'	-- Financial Interface
	
	If @psProgramName in ('CONTMGMT')
		Set @sModuleIds = @sModuleIds + ',13'	-- Contact Management
	
	If @psProgramName in ('FILELOCN')
		Set @sModuleIds = @sModuleIds + ',14'	-- File Tracking
	
	If @psProgramName in ('COSTTRACKING', 'REVENUETRACKING')
		Set @sModuleIds = @sModuleIds + ',15'	-- Cost Tracking
	
	If @psProgramName in ('CLIENT WORKBENCH')  
		Set @sModuleIds = @sModuleIds + ',17'	-- Client Workbench
	
	If @psProgramName in ('PROFESSIONAL WORKBENCH')  
		Set @sModuleIds = @sModuleIds + ',18'	-- Professional Workbench
	
	If @psProgramName in ('MANAGERS WORKBENCH')  
		Set @sModuleIds = @sModuleIds + ',19'	-- Managers Workbench

	If @psProgramName in ('MARKETING WORKBENCH')  
		Set @sModuleIds = @sModuleIds + ',20'	-- Marketing WorkBench

	If @psProgramName in ('CLERICAL WORKBENCH')  
		Set @sModuleIds = @sModuleIds + ',21'	-- Clerical WorkBench

	If @psProgramName in ('B2BTASKS', 'B2BCONFIGURATION')  
		Set @sModuleIds = @sModuleIds + ',22'	-- E Filing

	If @psProgramName in ('BATCHPROCESSING','IMPORTSVR','NAMEMAPPING',
			      'CASEREVIEW')  
		Set @sModuleIds = @sModuleIds + ',23'	-- EDE

	If @psProgramName in ('DATAWIZARD')  
		Set @sModuleIds = @sModuleIds + ',24'	-- Law Update

	If @psProgramName in ('CRM WORKBENCH')  
		Set @sModuleIds = @sModuleIds + ',25'	-- CRM Workbenches
    
	If @psProgramName in ('TRUSTACCT')  
		Set @sModuleIds = @sModuleIds + ',26'	-- Trust Accounting

	If @psProgramName in ('ADMINISTRATOR WORKBENCH')  
		Set @sModuleIds = @sModuleIds + ',27'	-- Administration Workbenches

	If @psProgramName in ('ALERTS', 'BMP2PNG', 'BULKREN',
				'CASE', 'CASEEXPORTMC',
				'COUNTRY', 'CPAEXTRT', 'CPAINTERFACE',
				'DOCITEMS',
				'DOCSVR32', 'EVTCON',	'LETTERS',
				'IPCNTRL', 'IMPJRNL', 'IMPORTSVR',
				'IRALLOCN', 'NAMES', 'POLREQST',
				'POLSVR', 'NAMEMAPPING',
				'REMINDER', 'SECURE', 'SITECONT',
				'SOUNDEX', 'TABLES', 'CONFLICTSEARCH',
				'AUDITTRAIL', 'DATAMAPPING', 'MARGINPROFILE',
				'PRIORART', 'CLERICAL WORKBENCH'
				)
		Set @sModuleIds = @sModuleIds + ',28'	-- Cases & Names & Clerical WorkBench

	If @psProgramName in ('ALERTS','BMP2PNG','BULKREN','CASE','CASEEXPORTMC',
				'COUNTRY','CPAEXTRT','CPAINTERFACE','DOCITEMS','DOCSVR32',
				'EVTCON','LETTERS','IPCNTRL','IMPJRNL','IMPORTSVR',
				'IRALLOCN','NAMES','POLREQST','POLSVR',
				'REMINDER','SECURE','SITECONT','SOUNDEX','TABLES','CONFLICTSEARCH',
				'AUDITTRAIL','DATAMAPPING','MARGINPROFILE','PRIORART','CHGEN',
				'FEES','RECIPROCITYENQUIRY','STAFFPERFORMANCE','STATS',
				'QUOTATIONS','CONTMGMT','FILELOCN','COSTTRACKING', 'REVENUETRACKING',
				'DATAWIZARD','ADMINISTRATOR WORKBENCH',
				'PROFESSIONAL WORKBENCH','MANAGERS WORKBENCH','CLERICAL WORKBENCH')
		Set @sModuleIds = @sModuleIds + ',29'	-- IP Matter Management Module (Model 2)

	If @psProgramName in ('TIMESHT','RATESMNT','WIP','BILLING','EXPENSEIMPORT')
		Set @sModuleIds = @sModuleIds + ',30'	-- Time & Billing Module (Model 2)

	If @psProgramName in ('CASHBOOK','FINANCIALINTERFACE','GENERALLEDGER',
				'JOURNALGENERATION','PAYABLE','TRUSTACCT','ARTRANS','ARITEMIMPORT','TRANSGENERATION')
		Set @sModuleIds = @sModuleIds + ',31'	-- Financial Management Module (Model 2)

	If @psProgramName in ('MARKETING WORKBENCH','CRM WORKBENCH')  
		Set @sModuleIds = @sModuleIds + ',32'	-- Marketing Module (Model 2)

	If @psProgramName in ('CLIENT WORKBENCH')  
		Set @sModuleIds = @sModuleIds + ',33'	-- Client Access Module (Model 2)

	If @psProgramName in ('B2BTASKS','B2BCONFIGURATION')  
		Set @sModuleIds = @sModuleIds + ',34'	-- Integration E-filing Module (Model 2)

	If @psProgramName in ('BATCHPROCESSING','IMPORTSVR','NAMEMAPPING',
			      'CASEREVIEW')  
		Set @sModuleIds = @sModuleIds + ',38'	-- EDE (Model 2)
	
	If LEFT(@sModuleIds, 1) = ','
		 Set @sModuleIds = RIGHT(@sModuleIds, len(@sModuleIds)-1)

	Return @sModuleIds
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

Grant execute on dbo.fn_GetModuleId to public
GO
