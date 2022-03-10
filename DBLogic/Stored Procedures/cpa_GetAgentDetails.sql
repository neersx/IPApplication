-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_GetAgentDetails
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_GetAgentDetails]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_GetAgentDetails.'
	drop procedure dbo.cpa_GetAgentDetails
end
print '**** Creating procedure dbo.cpa_GetAgentDetails...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_GetAgentDetails 
	@pnRowCount			int 		= null	output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pbOutputAsCSV			bit		= 0	-- format the result as a CSV

as
-- PROCEDURE :	cpa_GetAgentDetails
-- VERSION :	3
-- DESCRIPTION:	Get the details of Agents for those countries where Renewals
--		are to be performed by the filing agent.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Jul 2003	MF		1	Procedure Created
-- 05 Aug 2004	AB	8035	2	Add collate database_default to temp table definitions
-- 14 Jun 2005	MF	8966	3	Order the results by Country and then Name

set nocount on
set concat_null_yields_null off

Create table #TEMPCPASEND
		(	OWNERNAMECODE		varchar(10)	collate database_default NULL,
			OWNERNAME		varchar(100)	collate database_default NULL,
			OWNADDRESSCODE		int		NULL,
			OWNADDRESSLINE1		varchar(50)	collate database_default NULL,
			OWNADDRESSLINE2		varchar(50)	collate database_default NULL,
			OWNADDRESSLINE3		varchar(50)	collate database_default NULL,
			OWNADDRESSLINE4		varchar(50)	collate database_default NULL,
			OWNADDRESSCOUNTRY	varchar(50)	collate database_default NULL,
			OWNADDRESSPOSTCODE	varchar(16)	collate database_default NULL,
			CLTADDRESSCODE		int		NULL,
			CLTADDRESSLINE1		varchar(50)	collate database_default NULL,
			CLTADDRESSLINE2		varchar(50)	collate database_default NULL,
			CLTADDRESSLINE3		varchar(50)	collate database_default NULL,
			CLTADDRESSLINE4		varchar(50)	collate database_default NULL,
			CLTADDRESSCOUNTRY	varchar(50)	collate database_default NULL,
			CLTADDRESSPOSTCODE	varchar(16)	collate database_default NULL,
			DIVADDRESSCODE		int		NULL,
			DIVADDRESSLINE1		varchar(50)	collate database_default NULL,
			DIVADDRESSLINE2		varchar(50)	collate database_default NULL,
			DIVADDRESSLINE3		varchar(50)	collate database_default NULL,
			DIVADDRESSLINE4		varchar(50)	collate database_default NULL,
			DIVADDRESSCOUNTRY	varchar(50)	collate database_default NULL,
			DIVADDRESSPOSTCODE	varchar(16)	collate database_default NULL,
			INVADDRESSCODE		int		NULL,
			INVADDRESSLINE1		varchar(50)	collate database_default NULL,
			INVADDRESSLINE2		varchar(50)	collate database_default NULL,
			INVADDRESSLINE3		varchar(50)	collate database_default NULL,
			INVADDRESSLINE4		varchar(50)	collate database_default NULL,
			INVADDRESSCOUNTRY	varchar(50)	collate database_default NULL,
			INVADDRESSPOSTCODE	varchar(16)	collate database_default NULL
		)

declare	@ErrorCode	int
declare	@sSQLString	nvarchar(4000)

Set	@ErrorCode=0

If @ErrorCode=0
Begin
	Set @sSQLString="
	insert into #TEMPCPASEND(OWNERNAMECODE, OWNERNAME, OWNADDRESSCODE)
	select distinct N.NAMECODE, N.NAME, N.POSTALADDRESS
	from CASES C
	join TABLEATTRIBUTES TA on (TA.PARENTTABLE='COUNTRY'
	                        and TA.GENERICKEY=C.COUNTRYCODE
	                        and TA.TABLECODE=CASE WHEN(C.PROPERTYTYPE='D')              THEN 5010
	                                              WHEN(C.PROPERTYTYPE not in ('T','I')) THEN 5009
	                                         END)
	join CASENAME CN        on (CN.CASEID=C.CASEID
	                        and CN.NAMETYPE='A'
	                        and CN.EXPIRYDATE is null)
	join NAME N             on (N.NAMENO=CN.NAMENO)
	where C.CASETYPE='A'
	and C.REPORTTOTHIRDPARTY=1"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- Load the addresses into a format acceptable to CPA
If @ErrorCode=0
begin
	exec @ErrorCode=cpa_FormatAddresses
End

If @ErrorCode=0
Begin
	If @pbOutputAsCSV=1
	Begin
		Set @sSQLString="
		select char(34)+replace(OWNERNAMECODE,char(34),char(34)+char(34))+char(34)+','+char(34)+replace(OWNERNAME,char(34),char(34)+char(34))+char(34)+','+char(34)+replace(OWNADDRESSLINE1,char(34),char(34)+char(34))+char(34)+','+char(34)+replace(OWNADDRESSLINE2,char(34),char(34)+char(34))+char(34)+','+char(34)+replace(OWNADDRESSLINE3,char(34),char(34)+char(34))+char(34)+','+char(34)+replace(OWNADDRESSLINE4,char(34),char(34)+char(34))+char(34)+','+char(34)+replace(OWNADDRESSCOUNTRY,char(34),char(34)+char(34))+char(34)
		from #TEMPCPASEND
		order by OWNADDRESSCOUNTRY, OWNERNAME, OWNERNAMECODE"
	End
	Else Begin
		Set @sSQLString="
		select 	OWNERNAMECODE		as NameCode,
			OWNERNAME		as Name,
			OWNADDRESSLINE1		as Address1,
			OWNADDRESSLINE2		as Address2,
			OWNADDRESSLINE3		as Address3,
			OWNADDRESSLINE4		as Address4,
			OWNADDRESSCOUNTRY	as Country
		from #TEMPCPASEND
		order by OWNADDRESSCOUNTRY, OWNERNAME, OWNERNAMECODE"
	End

	exec @ErrorCode=sp_executesql @sSQLString
	
	Set @pnRowCount=@@rowcount
End

drop table #TEMPCPASEND

Return @ErrorCode
go

grant execute on dbo.cpa_GetAgentDetails to public
go
