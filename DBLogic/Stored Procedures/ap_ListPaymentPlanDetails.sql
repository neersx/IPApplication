-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.ap_ListPaymentPlanDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ap_ListPaymentPlanDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ap_ListPaymentPlanDetails'
	drop procedure [dbo].[ap_ListPaymentPlanDetails]
end
print '**** Creating procedure dbo.ap_ListPaymentPlanDetails...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go

SET ANSI_NULLS ON 
go


CREATE PROCEDURE [dbo].[ap_ListPaymentPlanDetails]
		@pnPlanId int			-- The PlanId of the bulk payment run.			
as
-- PROCEDURE :	ap_ListPaymentPlanDetails
-- VERSION :	2
-- DESCRIPTION:	Return a list of suppliers and email addresses associated with a bulk payment plan
--		The email addess associated with the supplier will be determined in the following order
--		Attention of (Send Payments To Contact)
--			else Send Payments To Name
--				else Supplier
-- CALLED BY :	

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/03/2010	DL	11346	1	Procedure created	
-- 01/10/2010	Dw	19010	2	Added distinct keyword to select

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

Declare @nErrorCode	int

	
Select  distinct PPD.ITEMENTITYNO, PPD.REFTRANSNO, CI.ACCTCREDITORNO SUPPLIERNAMENO,

-- SUPPLIER
S.NAMECODE, 
convert( nvarchar(254), S.NAME 
+ CASE WHEN S.FIRSTNAME IS NOT NULL THEN ', ' END 
+ S.FIRSTNAME+SPACE(1)+ CASE WHEN S.NAMECODE IS NOT NULL THEN '{' END +S.NAMECODE 
+ CASE WHEN S.NAMECODE IS NOT NULL THEN '}' END ) SUPPLIER,

-- EMAIL Repient
convert( nvarchar(254), N2.NAME 
+ CASE WHEN N2.FIRSTNAME IS NOT NULL THEN ', ' END 
+ N2.FIRSTNAME+SPACE(1)+ CASE WHEN N2.NAMECODE IS NOT NULL THEN '{' END + N2.NAMECODE 
+ CASE WHEN N2.NAMECODE IS NOT NULL THEN '}' END ) EMAILRECIPIENT,  

-- EMAIL ADDRESSES
AN.EMAILADDRESS, AN.EMAILRECIPIENT RECIPIENTNAMENO

from PAYMENTPLANDETAIL PPD  
join CREDITORITEM CI  ON (CI.ITEMENTITYNO = PPD.ITEMENTITYNO     
	AND CI.ITEMTRANSNO = PPD.ITEMTRANSNO     
	AND CI.ACCTENTITYNO = PPD.ACCTENTITYNO     
	AND CI.ACCTCREDITORNO = PPD.ACCTCREDITORNO)  
join NAME S  ON (S.NAMENO = CI.ACCTCREDITORNO)  

left join (
	select	PL.ACCTCREDITORNO AS NAMENO, 
	Coalesce(E1.TELECOMNUMBER, E2.TELECOMNUMBER, E3.TELECOMNUMBER) AS EMAILADDRESS,
	-- ROW_NUMBER sorts mulitple 'Payment To' entries according to value of RELATEDNAME
	-- only the first row is selected.  
	ROW_NUMBER() OVER (PARTITION BY PL.ACCTCREDITORNO ORDER BY AN.RELATEDNAME) as NAMESEQ
	, AN.RELATEDNAME, 

	case when (E1.TELECOMNUMBER is not null) then AN.CONTACT
	     when (E2.TELECOMNUMBER is not null) then AN.RELATEDNAME
	     when (E3.TELECOMNUMBER is not null) then PL.ACCTCREDITORNO end as EMAILRECIPIENT

	from PAYMENTPLANDETAIL PL
	left join ASSOCIATEDNAME AN on (AN.NAMENO = PL.ACCTCREDITORNO
					and AN.RELATIONSHIP= 'PAY' 
					and AN.CEASEDDATE is null)
	
	-- Payment To Contact 
	left join TELECOMMUNICATION E1 on (E1.TELECODE=(select min(E.TELECODE)
							from NAMETELECOM NT
							join TELECOMMUNICATION E on (E.TELECODE=NT.TELECODE
										  and E.TELECOMTYPE=1903)
							where NT.NAMENO=AN.CONTACT))
	-- Payment To
	left join TELECOMMUNICATION E2 on (E2.TELECODE=(select min(E.TELECODE)
							from NAMETELECOM NT
							join TELECOMMUNICATION E on (E.TELECODE=NT.TELECODE
										  and E.TELECOMTYPE=1903)
							where NT.NAMENO=AN.RELATEDNAME))
	-- Supplier
	left join TELECOMMUNICATION E3 on (E3.TELECODE=(select min(E.TELECODE)
							from NAMETELECOM NT
							join TELECOMMUNICATION E on (E.TELECODE=NT.TELECODE
										  and E.TELECOMTYPE=1903)
							where NT.NAMENO= PL.ACCTCREDITORNO)) 
	where PL.PLANID = @pnPlanId
	) AN ON (AN.NAMENO = CI.ACCTCREDITORNO and AN.NAMESEQ = 1)

left join NAME N2  ON (N2.NAMENO = AN.EMAILRECIPIENT)  

where PPD.PLANID = @pnPlanId 
order by SUPPLIER, PPD.REFTRANSNO

Select  @nErrorCode=@@Error

Return @nErrorCode
go 

grant execute on [dbo].[ap_ListPaymentPlanDetails] to public
go
