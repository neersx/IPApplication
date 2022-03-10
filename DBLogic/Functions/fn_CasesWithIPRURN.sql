-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_CasesWithIPRURN
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_CasesWithIPRURN') and xtype in ('IF','TF'))
begin
	print '**** Drop function dbo.fn_CasesWithIPRURN.'
	drop function dbo.fn_CasesWithIPRURN
end
print '**** Creating function dbo.fn_CasesWithIPRURN...'
print ''
go

set QUOTED_IDENTIFIER off
go

Create Function dbo.fn_CasesWithIPRURN()

RETURNS TABLE


-- FUNCTION :	fn_CasesWithIPRURN
-- VERSION :	1
-- DESCRIPTION:	Determines the IPRURN that identifies Cases in the CPA Global Renewal system.
--		This assumes that the firm has imported from CPA either of the :
--			Electronic Production Log (EPL); and/or
--			Portfolio of live and dead cases.

-- MODIFICATION
-- Date		Who	No.	Version
-- ====         ===	=== 	=======
-- 20 Jul 2017	MF		1	Function created


as RETURN
	Select	C.CASEID, 
		coalesce(CPA1.IPRURN, CPA2.IPRURN, CPA3.IPRURN) as IPRURN
	from CASES C
	left join SITECONTROL SC on (SC.CONTROLID='CPA-Use ClientCaseCode')
	-- from the EPL
	left join (	select CR.CASEID, CR.IPRURN
			from CPARECEIVE CR	
			Where CR.BATCHNO = (select max (CR1.BATCHNO)
					    from CPARECEIVE CR1
					    where CR1.CASEID = CR.CASEID
					    and CR1.IPRURN is not null) ) CPA1 
					on (CPA1.CASEID=C.CASEID)
	-- from the live portfolio record where responsible party is consistent
	left join (	select CASEID, RESPONSIBLEPARTY, min(IPRURN) as IPRURN
			from CPAPORTFOLIO
			where STATUSINDICATOR = 'L'
			group by CASEID, RESPONSIBLEPARTY) CPA2
					on (CPA2.CASEID=C.CASEID
					and CPA2.RESPONSIBLEPARTY=CASE WHEN(SC.COLBOOLEAN=1) THEN 'C' ELSE 'A' END
					and CPA1.IPRURN is null)
	-- from the dead portfolio record where responsible party is consistent
	left join (	select CASEID, RESPONSIBLEPARTY, min(IPRURN) as IPRURN
			from CPAPORTFOLIO
			where STATUSINDICATOR <> 'L'
			group by CASEID, RESPONSIBLEPARTY) CPA3
					on (CPA3.CASEID=C.CASEID
					and CPA3.RESPONSIBLEPARTY=CASE WHEN(SC.COLBOOLEAN=1) THEN 'C' ELSE 'A' END
					and CPA1.IPRURN is null
					and CPA2.IPRURN is null)
	Where coalesce(CPA1.IPRURN, CPA2.IPRURN, CPA3.IPRURN) is not null
go

grant DELETE, INSERT, REFERENCES, SELECT, UPDATE on dbo.fn_CasesWithIPRURN to public
GO

