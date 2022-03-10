if exists (select * from sysobjects where type='TR' and name = 'UpdateIPNAME')
begin
	PRINT 'Refreshing trigger UpdateIPNAME...'
	DROP TRIGGER UpdateIPNAME
end
go
	
CREATE TRIGGER UpdateIPNAME ON IPNAME FOR UPDATE NOT FOR REPLICATION AS
-- TRIGGER:	UpdateIPNAME    
-- VERSION:	3
-- DESCRIPTION:	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 24-Apr-2005	MF	11291	1	Trigger created to monitor changes against Currency.
-- 17 Mar 2009	MF	17490	2	Ignore if trigger is being fired as a result of the audit details being updated
-- 28 Oct 2011	MF	R11482	3	Performance problem

If NOT UPDATE(LOGDATETIMESTAMP)
BEGIN
	IF UPDATE(CURRENCY) 
	BEGIN
		Update ACTIVITYHISTORY
		set	BILLCURRENCY	=i.CURRENCY,
			BILLEXCHANGERATE=isnull(C.SELLRATE,1),

			DISBBILLAMOUNT	=CASE WHEN(A.DISBCURRENCY=i.CURRENCY or (A.DISBCURRENCY is null and i.CURRENCY is null))
						THEN A.DISBORIGINALAMOUNT 		-- Billing currency and disbursement currency are the same
						ELSE A.DISBAMOUNT*isnull(C.SELLRATE,1)	-- Disbursement in home currency x billing xrate
					 END,
	
			SERVBILLAMOUNT	=CASE WHEN(A.SERVICECURRENCY=i.CURRENCY or (A.SERVICECURRENCY is null and i.CURRENCY is null))
						THEN A.SERVORIGINALAMOUNT		-- Billing currency and service currency are the same
						ELSE A.SERVICEAMOUNT*isnull(C.SELLRATE,1)-- Service in home currency x billing xrate
					 END,

			DISBBILLDISCOUNT=CASE WHEN(A.DISBCURRENCY=i.CURRENCY or (A.DISBCURRENCY is null and i.CURRENCY is null))
						THEN A.DISBDISCORIGINAL 		-- Billing currency and disbursement currency are the same
						ELSE A.DISBDISCOUNT*isnull(C.SELLRATE,1)-- Disbursement discount in home currency x billing xrate
					 END,

			SERVBILLDISCOUNT=CASE WHEN(A.SERVICECURRENCY=i.CURRENCY or (A.SERVICECURRENCY is null and i.CURRENCY is null))
						THEN A.SERVDISCORIGINAL			-- Billing currency and service currency are the same
						ELSE A.SERVDISCOUNT*isnull(C.SELLRATE,1)-- Service in home currency x billing xrate
					 END,

			DISCBILLAMOUNT	=CASE WHEN(A.DISBCURRENCY=i.CURRENCY or (A.DISBCURRENCY is null and i.CURRENCY is null))
						THEN A.DISBDISCORIGINAL 		-- Billing currency and disbursement currency are the same
						ELSE A.DISBDISCOUNT*isnull(C.SELLRATE,1)-- Disbursement discount in home currency x billing xrate
					 END
					+CASE WHEN(A.SERVICECURRENCY=i.CURRENCY or (A.SERVICECURRENCY is null and i.CURRENCY is null))
						THEN A.SERVDISCORIGINAL			-- Billing currency and service currency are the same
						ELSE A.SERVDISCOUNT*isnull(C.SELLRATE,1)-- Service in home currency x billing xrate
					 END
		From deleted d
		join inserted i 	on (i.NAMENO=d.NAMENO)

		-- Need a derived table to return the first Debtor of a given NameType to allow
		-- for when multiple debtors exist and the billing currency has been based on 
		-- the first debtor.
		left join (	select CN1.CASEID as CASEID, CN1.NAMENO as NAMENO, CN1.NAMETYPE as NAMETYPE
				from CASENAME CN1
				where CN1.NAMETYPE in ('D','Z')
				and CN1.SEQUENCE=(	select min(CN2.SEQUENCE)
							from CASENAME CN2
							where CN2.CASEID=CN1.CASEID
							and CN2.NAMETYPE=CN1.NAMETYPE) ) CN		
					on (CN.NAMENO=d.NAMENO)
--		RFC11482 Comment this code out as it is not required
--		-- Get all the Cases associated with the Name that has been modified with either of
--		-- the billing NameTypes.  This is because the NameNo may be the explicit
--		join CASENAME CN3	on (CN3.NAMENO=d.NAMENO
--					and CN3.NAMETYPE in ('D','Z'))
		join ACTIVITYHISTORY A	on (A.CASEID=CN.CASEID
					and A.ESTIMATEFLAG=1)		-- Get the ACTIVITYHISTORY estimate rows
		join RATES R		on (R.RATENO=A.RATENO)
		left join CURRENCY C	on (C.CURRENCY=i.CURRENCY)

			-- Ensure the Currency has changed
		where( d.CURRENCY<>i.CURRENCY
		   OR (d.CURRENCY is null     and i.CURRENCY is not null) 
		   OR (d.CURRENCY is not null and i.CURRENCY is null) )

			-- Now check that the ACTIVITYHISTORY row applies to the Debtor
			-- whose Currency has changed.  This may be where the row has
			-- the DEBTOR explicitly set or where the NAMETYPE of Name linking 
			-- it to the Case is correct for the RateType.
		AND  ((A.DEBTOR=CN.NAMENO)
		   OR (A.DEBTOR is null and CN.NAMETYPE=CASE WHEN(R.RATETYPE=1601) THEN 'Z' ELSE 'D' END) )
	END
END
go
