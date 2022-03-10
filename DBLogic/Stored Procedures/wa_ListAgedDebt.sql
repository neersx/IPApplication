-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListAgedDebt
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListAgedDebt]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListAgedDebt'
	drop procedure [dbo].[wa_ListAgedDebt]
	print '**** Creating procedure dbo.wa_ListAgedDebt...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_ListAgedDebt]
	@pnDebtorNo	int

-- PROCEDURE :	wa_ListAgedDebt
-- VERSION :	2.2.0
-- DESCRIPTION:	Display the aged debt for the Debtor passed as a parameter using the defined
--		accounting periods as the basis for ageing the debt.  Note that a row will 
--		be returned for each entity that the Debtor has a debt with.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 12/07/2001	MF	Procedure created
-- 20/07/2001	AF	Corrected row titles and return Debtor NameNo 	
-- 03/08/2001	MF	Check that the user may see the debtor details
-- 16/10/2001	MF	Format amounts as currency
-- 05/07/2013	vql	R13629(Remove string length restriction and use nvarchar on datetime conversions using 106 format)
-- 14 Nov 2018  AV  75198/DR-45358   Date conversion errors when creating cases and opening names in Chinese DB

as 
	-- set server options
	set NOCOUNT on

	-- declare variables
	declare	@ErrorCode	int

	Execute @ErrorCode=wa_CheckSecurityForDebtor @pnDebtorNo

	If @ErrorCode=0
	Begin
		select  
		CONVERT(VARCHAR(20), CAST(sum(CASE WHEN (O.ITEMDATE > P0.STARTDATE)			 THEN O.LOCALBALANCE ELSE 0 END) as MONEY), 1)
		as 'Current',
		CONVERT(VARCHAR(20), CAST(sum(CASE WHEN (O.ITEMDATE between P1.STARTDATE and P1.ENDDATE) THEN O.LOCALBALANCE ELSE 0 END) as MONEY), 1)
		as 'Period1',
		CONVERT(VARCHAR(20), CAST(sum(CASE WHEN (O.ITEMDATE between P2.STARTDATE and P2.ENDDATE) THEN O.LOCALBALANCE ELSE 0 END) as MONEY), 1)
		as 'Period2',
		CONVERT(VARCHAR(20), CAST(sum(CASE WHEN (O.ITEMDATE < P2.STARTDATE )			 THEN O.LOCALBALANCE ELSE 0 END) as MONEY), 1)
		as 'Period3',
		CONVERT(VARCHAR(20), CAST(sum(O.LOCALBALANCE) as MONEY), 1)
		as 'Total',
		N.NAME,
		N.NAMENO,
		DEBTORNO = @pnDebtorNo /* required in the resultset for efficient UI */
		from OPENITEM O
		    join NAME N		on (N.NAMENO=O.ACCTENTITYNO)
								-- get the current period
		    join PERIOD P0	on (P0.STARTDATE<=convert(nvarchar,getdate(),112)
					and P0.ENDDATE  >=convert(nvarchar,getdate(),112))
			
								-- get the period one older than the current period
		left join PERIOD P1	on (P1.PERIODID = 
						substring ((	select max(convert(varchar,ENDDATE, 102) + convert(varchar,PERIODID))
								from PERIOD
								where ENDDATE < P0.STARTDATE ),
								11, 10))
		
								-- get the period two older than the current period
		left join PERIOD P2	on (P2.PERIODID = 
						substring ((	select max(convert(varchar,ENDDATE, 102) + convert(varchar,PERIODID))
								from PERIOD
								where ENDDATE < P1.STARTDATE ),
								11, 10))
		
		where	O.ACCTDEBTORNO = @pnDebtorNo
		and	O.STATUS = 1 
		and	O.POSTDATE 	 < convert(nvarchar,dateadd(day,1,getdate()) ,112)
		and	O.CLOSEPOSTDATE >= convert(nvarchar,dateadd(day,1,getdate()) ,112)
		and	O.ITEMDATE 	<= convert(nvarchar,getdate(),112)
		group by N.NAME, N.NAMENO order by N.NAME

		Select @ErrorCode=@@Error
	End

return @ErrorCode
go

grant execute on [dbo].[wa_ListAgedDebt] to public
go
