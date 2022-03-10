-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetBillRuleRows
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetBillRuleRows') and xtype='TF')
begin
	print '**** Drop function dbo.fn_GetBillRuleRows.'
	drop function dbo.fn_GetBillRuleRows
end
print '**** Creating function dbo.fn_GetBillRuleRows...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_GetBillRuleRows
			(
 	 		@pnRuleType		int		= null,
			@psWIPCode		nvarchar(12)	= null,
 	 		@pnCaseId		int		= null,
 	 		@pnDebtorNo		int		= null,
 	 		@pnEntityNo		int		= null,
 	 		@pnNameCategory		int		= null,
 	 		@pnLocalClientFlag	decimal(1,0)	= 0, 	 		
			@psCaseType		nchar(2)	= null,
			@psPropertyType		nchar(2)	= null,
			@psCaseAction		nvarchar(4)	= null,
			@psCaseCountry		nvarchar(6)	= null,
			@pbExactMatch		bit		= 0
			)

Returns @tbCriteria TABLE
   (      
	RULESEQNO		int		primary key,
	RULETYPE		int,
	CASEID			int	NULL,
	DEBTORNO		int	NULL,
	ENTITYNO		int	NULL,
	NAMECATEGORY		int	NULL,
	LOCALCLIENTFLAG		decimal(1,0) NULL,
	CASETYPE		nchar(2) collate database_default NULL,
	PROPERTYTYPE		nchar(2) collate database_default NULL,
	CASEACTION		nvarchar(4) collate database_default NULL,
	CASECOUNTRY		nvarchar(6) collate database_default NULL,
	BILLINGENTITY		int NULL,
	MINIMUMNETBILL		decimal(7,2) NULL,
	WIPCODE			nvarchar(12) collate database_default NULL,
	BESTFITSCORE		nvarchar(20) collate database_default NULL
   )

as
-- FUNCTION :	fn_GetBillRuleRows
-- VERSION  :	3
-- COPYRIGHT:	Copyright CPA Global Software Solutions Pty Limited
-- DESCRIPTION:	This function returns BILLRULE row details that match either exactly the 
--		non NULL input parameters or match based on the Best Fit search algorithm.
--		If an exact match is not required then the Best Fit search will determine
--		a BESTFITSCORE value that indicates how well each returned row matches.

--		Rule Types from TABLECODES where TABLETYPE = 63
--			21 - Minimum Net Bill
--			22 - Billing Entity
--			23 - Minimum WIP Value

-- MODIFICATIONS :
-- Date		Who	Number	Version	Description
-- -----------	-------	------	-------	-----------------------------------------------
-- 21 Oct 2011	KR	R9451	1	Procedure created
-- 01 Nov 2011	AT	R9451	2	Allow return of all rules for a case and/or debtor
-- 07 Jul 2016	MF	63861	3	If the @pnLocalClientFlag is null then it should be treated as Not Local(0)

Begin
	----------------------------------
	-- Default @pnLocalClientFlag to 0
	----------------------------------
	If @pnLocalClientFlag is null
		Set @pnLocalClientFlag=0
		
	If @pbExactMatch=1
	begin
		Insert into @tbCriteria(
			RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
			PROPERTYTYPE,CASEACTION, BILLINGENTITY, MINIMUMNETBILL, WIPCODE, CASECOUNTRY)
		SELECT	RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
			PROPERTYTYPE,CASEACTION, BILLINGENTITY, MINIMUMNETBILL, WIPCODE, CASECOUNTRY
		FROM BILLRULE 
		WHERE 	(RULETYPE		=@pnRuleType)
		and	(DEBTORNO		=@pnDebtorNo		OR @pnDebtorNo		is null)
		and	(ENTITYNO		=@pnEntityNo		OR @pnEntityNo		is null)
		and	(NAMECATEGORY		=@pnNameCategory	OR @pnNameCategory	is null)
		and	(LOCALCLIENTFLAG	=@pnLocalClientFlag	OR @pnLocalClientFlag	is null)
		and	(CASETYPE		=@psCaseType		OR @psCaseType		is null)	
		and	(PROPERTYTYPE		=@psPropertyType	OR @psPropertyType	is null)
		and	(CASEACTION		=@psCaseAction		OR @psCaseAction	is null)
		and	(WIPCODE		=@psWIPCode		OR @psWIPCode		is null)
		and	(CASECOUNTRY		=@psCaseCountry		OR @psCaseCountry	is null)
		
	End
	Else
	Begin
		if (@pnRuleType = 21)
		Begin
			-- Minimum Net Bill
			Insert into @tbCriteria(
				RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
				PROPERTYTYPE,CASEACTION, MINIMUMNETBILL, WIPCODE, CASECOUNTRY, BESTFITSCORE)
			SELECT	RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
				PROPERTYTYPE,CASEACTION, MINIMUMNETBILL, WIPCODE, CASECOUNTRY,  			
				CASE WHEN (ENTITYNO IS NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (NAMECATEGORY IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (CASECOUNTRY is NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (CASETYPE is NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (PROPERTYTYPE is NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (CASEACTION is NULL)		THEN '0' ELSE '1' END AS BESTFITSCORE
			FROM BILLRULE 
			WHERE 	(RULETYPE		=21)
			and	(ENTITYNO		=@pnEntityNo		OR ENTITYNO		is null)
			and	(NAMECATEGORY		=@pnNameCategory	OR NAMECATEGORY		is null)
			and	(LOCALCLIENTFLAG	=@pnLocalClientFlag	OR LOCALCLIENTFLAG	is null)		
			and	(CASECOUNTRY		=@psCaseCountry		OR CASECOUNTRY		is null)
			and	(CASETYPE		=@psCaseType		OR CASETYPE		is null)	
			and	(PROPERTYTYPE		=@psPropertyType	OR PROPERTYTYPE		is null)
			and	(CASEACTION		=@psCaseAction		OR CASEACTION		is null)

		End
		
		if (@pnRuleType = 23 or @pnRuleType is null)
			AND exists (select * FROM SITECONTROL WHERE CONTROLID = 'Charge Variable Fee' AND (COLBOOLEAN = 0 OR COLBOOLEAN IS NULL))
			AND EXISTS (SELECT * FROM REASON WHERE REASONCODE = (SELECT COLCHARACTER FROM SITECONTROL WHERE CONTROLID = 'Minimum WIP Reason' AND COLCHARACTER IS NOT NULL)
							AND USED_BY & 1 = 1)
		Begin
			-- Minimum WIP Value (Same as Minimum Net Bill, but with WIP Code criteria)
			Insert into @tbCriteria(
				RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
				PROPERTYTYPE,CASEACTION, MINIMUMNETBILL, WIPCODE, CASECOUNTRY, BESTFITSCORE)
			SELECT	RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
				PROPERTYTYPE,CASEACTION, MINIMUMNETBILL, WIPCODE, CASECOUNTRY,
				CASE WHEN (WIPCODE IS NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (ENTITYNO IS NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (NAMECATEGORY IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (CASECOUNTRY is NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (CASETYPE is NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (PROPERTYTYPE is NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (CASEACTION is NULL)		THEN '0' ELSE '1' END AS BESTFITSCORE
			FROM BILLRULE 
			WHERE 	(RULETYPE		=23)
			and	(WIPCODE		=@psWIPCode		OR @psWIPCode		is null)
			and	(ENTITYNO		=@pnEntityNo		OR ENTITYNO		is null)
			and	(NAMECATEGORY		=@pnNameCategory	OR NAMECATEGORY		is null)
			and	(LOCALCLIENTFLAG	=@pnLocalClientFlag	OR LOCALCLIENTFLAG	is null)		
			and	(CASECOUNTRY		=@psCaseCountry		OR CASECOUNTRY		is null)
			and	(CASETYPE		=@psCaseType		OR CASETYPE		is null)	
			and	(PROPERTYTYPE		=@psPropertyType	OR PROPERTYTYPE		is null)
			and	(CASEACTION		=@psCaseAction		OR CASEACTION		is null)
		End
		if (@pnRuleType = 22)
			AND EXISTS (select * FROM SITECONTROL WHERE CONTROLID = 'Inter-Entity Billing' AND COLBOOLEAN = 1)
		Begin
			-- Billing Entity
			Insert into @tbCriteria(
				RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
				PROPERTYTYPE,CASEACTION, BILLINGENTITY, WIPCODE, CASECOUNTRY, BESTFITSCORE)
			SELECT	RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
				PROPERTYTYPE,CASEACTION, BILLINGENTITY, WIPCODE, CASECOUNTRY,
				CASE WHEN (CASEID IS NULL)		THEN '0' ELSE '1' END +  			
				CASE WHEN (DEBTORNO IS NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (NAMECATEGORY IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (CASECOUNTRY is NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (CASETYPE is NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (PROPERTYTYPE is NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (CASEACTION is NULL)		THEN '0' ELSE '1' END 
			FROM BILLRULE 
			WHERE 	(RULETYPE		=22)
			and	(CASEID			=@pnCaseId		OR CASEID		is null)		
			and	(DEBTORNO		=@pnDebtorNo		OR DEBTORNO		is null)
			and	(NAMECATEGORY		=@pnNameCategory	OR NAMECATEGORY		is null)
			and	(LOCALCLIENTFLAG	=@pnLocalClientFlag	OR LOCALCLIENTFLAG	is null)		
			and	(CASECOUNTRY		=@psCaseCountry		OR CASECOUNTRY		is null)
			and	(CASETYPE		=@psCaseType		OR CASETYPE		is null)	
			and	(PROPERTYTYPE		=@psPropertyType	OR PROPERTYTYPE		is null)
			and	(CASEACTION		=@psCaseAction		OR CASEACTION		is null)
		End
		if (@pnRuleType is null)
		Begin
			If EXISTS (select * FROM SITECONTROL WHERE CONTROLID = 'Inter-Entity Billing' AND COLBOOLEAN = 1)
			Begin
				-- Billing Entity (only return the best one)
				Insert into @tbCriteria(
					RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
					PROPERTYTYPE,CASEACTION, BILLINGENTITY, WIPCODE, CASECOUNTRY, BESTFITSCORE)
				SELECT	top 1 RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
					PROPERTYTYPE,CASEACTION, BILLINGENTITY, WIPCODE, CASECOUNTRY,
					CASE WHEN (CASEID IS NULL)		THEN '0' ELSE '1' END +  			
					CASE WHEN (DEBTORNO IS NULL)		THEN '0' ELSE '1' END +
					CASE WHEN (NAMECATEGORY IS NULL)	THEN '0' ELSE '1' END +
					CASE WHEN (LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
					CASE WHEN (CASECOUNTRY is NULL)		THEN '0' ELSE '1' END +
					CASE WHEN (CASETYPE is NULL)		THEN '0' ELSE '1' END +
					CASE WHEN (PROPERTYTYPE is NULL)	THEN '0' ELSE '1' END +
					CASE WHEN (CASEACTION is NULL)		THEN '0' ELSE '1' END as BESTFITSCORE
				FROM BILLRULE 
				WHERE 	(RULETYPE		=22)
				and	(CASEID			=@pnCaseId		OR CASEID		is null)		
				and	(DEBTORNO		=@pnDebtorNo		OR DEBTORNO		is null)
				and	(NAMECATEGORY		=@pnNameCategory	OR NAMECATEGORY		is null)
				and	(LOCALCLIENTFLAG	=@pnLocalClientFlag	OR LOCALCLIENTFLAG	is null)		
				and	(CASECOUNTRY		=@psCaseCountry		OR CASECOUNTRY		is null)
				and	(CASETYPE		=@psCaseType		OR CASETYPE		is null)	
				and	(PROPERTYTYPE		=@psPropertyType	OR PROPERTYTYPE		is null)
				and	(CASEACTION		=@psCaseAction		OR CASEACTION		is null)
				ORDER BY BESTFITSCORE DESC
			End
			
			-- Minimum Net Bill (only return the best one)
			Insert into @tbCriteria(
				RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
				PROPERTYTYPE,CASEACTION, MINIMUMNETBILL, WIPCODE, CASECOUNTRY, BESTFITSCORE)
			SELECT	TOP 1 RULESEQNO,  RULETYPE,  CASEID, DEBTORNO,  ENTITYNO,  NAMECATEGORY,  LOCALCLIENTFLAG,  CASETYPE,
				PROPERTYTYPE,CASEACTION, MINIMUMNETBILL, WIPCODE, CASECOUNTRY,  			
				CASE WHEN (ENTITYNO IS NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (NAMECATEGORY IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (LOCALCLIENTFLAG IS NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (CASECOUNTRY is NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (CASETYPE is NULL)		THEN '0' ELSE '1' END +
				CASE WHEN (PROPERTYTYPE is NULL)	THEN '0' ELSE '1' END +
				CASE WHEN (CASEACTION is NULL)		THEN '0' ELSE '1' END AS BESTFITSCORE
			FROM BILLRULE 
			WHERE 	(RULETYPE		=21)
			and	(ENTITYNO		=@pnEntityNo		OR ENTITYNO		is null)
			and	(NAMECATEGORY		=@pnNameCategory	OR NAMECATEGORY		is null)
			and	(LOCALCLIENTFLAG	=@pnLocalClientFlag	OR LOCALCLIENTFLAG	is null)		
			and	(CASECOUNTRY		=@psCaseCountry		OR CASECOUNTRY		is null)
			and	(CASETYPE		=@psCaseType		OR CASETYPE		is null)	
			and	(PROPERTYTYPE		=@psPropertyType	OR PROPERTYTYPE		is null)
			and	(CASEACTION		=@psCaseAction		OR CASEACTION		is null)
			ORDER BY BESTFITSCORE DESC
		End
	End
	
	
	
	Return
End
go

grant REFERENCES, SELECT on dbo.fn_GetBillRuleRows to public
GO
