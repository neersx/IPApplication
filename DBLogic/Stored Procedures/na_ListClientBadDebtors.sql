-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ListClientBadDebtors
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[na_ListClientBadDebtors]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.na_ListClientBadDebtors.'
	drop procedure dbo.na_ListClientBadDebtors
end
print '**** Creating procedure dbo.na_ListClientBadDebtors...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.na_ListClientBadDebtors
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psFromNameCode			nvarchar(10)	= null,	
	@psToNameCode			nvarchar(10)	= null,	
	@pnBadDebtor			smallint	= null,
	@pbActionFlag			tinyint		= null,
	@pbCPAClientsOnly		tinyint		= 0,
	@pbOrderBy			tinyint		= 0	-- 0=ActionFlag, 1=NameCode, 2=Name
	
AS
-- PROCEDURE :	na_ListClientBadDebtors
-- DESCRIPTION:	Returns details of Clients that have been marked as some level of bad debtor
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03/07/2002	MF			Procedure created
-- 06 Aug 2004	AB	8035	2	Add collate database_default to temp table definitions

	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF

	create table #TEMPINSTRUCTIONS 
			(	INSTRUCTIONCODE		smallint	not null,
				NAMETYPE		nvarchar(3)	collate database_default not null
			)


	DECLARE	@ErrorCode		int,
		@sSQLString		nvarchar(4000),
		@sSelect		nvarchar(1000),
		@sFrom			nvarchar(1000),
		@sWhere			nvarchar(1000),
		@sOrderBy		nvarchar(100)

	set @ErrorCode=0

	-- Initialise the SQL

	Set @sSelect	="Select N.NAMECODE,N.NAME+CASE WHEN(N.FIRSTNAME is not null) THEN ', '+N.FIRSTNAME END as NAME, D.DEBTORSTATUS, D.ACTIONFLAG"
	
	Set @sFrom	="from NAME N"+char(10)+
			 "join IPNAME IP	on (IP.NAMENO=N.NAMENO)"+char(10)+
			 "join DEBTORSTATUS D	on (D.BADDEBTOR=IP.BADDEBTOR)"

	-- Set the Order By clause

	if @pbOrderBy=0
		set @sOrderBy="Order by D.ACTIONFLAG, D.DEBTORSTATUS, 2, N.NAMECODE"
	else if @pbOrderBy=1
		set @sOrderBy="Order by N.NAMECODE"
	else if @pbOrderBy=2
		set @sOrderBy="Order by 2, N.NAMECODE"

	-- If the report is to be restricted to CPA Reportable clients ONLY
	-- then we need to find out what Instruction codes will cause the CPA
	-- flag to be set on against Cases so as to check if the Instruction 
	-- applies to the debtor

	if @pbCPAClientsOnly=1
	begin
		Set @sSQLString="
		insert into #TEMPINSTRUCTIONS (INSTRUCTIONCODE, NAMETYPE)
		select distinct I.INSTRUCTIONCODE, T.NAMETYPE
		from EVENTCONTROL EC
		join INSTRUCTIONS I	on (I.INSTRUCTIONTYPE=EC.INSTRUCTIONTYPE)
		join INSTRUCTIONFLAG F	on (F.INSTRUCTIONCODE=I.INSTRUCTIONCODE
					and F.FLAGNUMBER     =EC.FLAGNUMBER)
		join INSTRUCTIONTYPE T	on (T.INSTRUCTIONTYPE=I.INSTRUCTIONTYPE)
		Where EC.SETTHIRDPARTYON=1"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Construct the WHERE clause depending upon the parameters passed.

	-- Restrict to particular Name Codes

	if  @psFromNameCode is not NULL
	and @psToNameCode   is not NULL
	begin
		if @sWhere is null
			set @sWhere ="Where	N.NAMECODE between '"+@psFromNameCode+"' and '"+@psToNameCode+"'"
		else
			set @sWhere = @sWhere+char(10)+"and	N.NAMECODE between '"+@psFromNameCode+"' and '"+@psToNameCode+"'"
	end
	else if  @psFromNameCode is not NULL
	begin
		if @sWhere is null
			set @sWhere ="Where	N.NAMECODE >='"+@psFromNameCode+"'"
		else
			set @sWhere = @sWhere+char(10)+"and	N.NAMECODE >='"+@psFromNameCode+"'"
	end
	else if @psToNameCode is not NULL
	begin
		if @sWhere is null
			set @sWhere ="Where	N.NAMECODE <='"+@psToNameCode+"'"
		else
			set @sWhere = @sWhere+char(10)+"and	N.NAMECODE <='"+@psToNameCode+"'"
	end

	-- Restrict to a specific Bad Debtor Flag.

	If @pnBadDebtor is not null
	begin
		if @sWhere is null
			set @sWhere ="Where	D.BADDEBTOR="+convert(varchar,@pnBadDebtor)
		else
			set @sWhere = @sWhere+char(10)+"and	D.BADDEBTOR="+convert(varchar,@pnBadDebtor)
	end

	-- Restrict to a specific group of Bad Debtor flags.

	If @pbActionFlag is not null
	begin
		if @sWhere is null
			set @sWhere ="Where	D.ACTIONFLAG="+convert(varchar,@pbActionFlag)
		else
			set @sWhere = @sWhere+char(10)+"and	D.ACTIONFLAG="+convert(varchar,@pbActionFlag)
	end

	-- Restrict to only Clients that report cases to CPA

	If @pbCPAClientsOnly=1
	begin
		if @sWhere is null
			set @sWhere ="Where"+
				char(10)+"(exists(select * from NAMEINSTRUCTIONS NI"+
				char(10)+"  join #TEMPINSTRUCTIONS T on (T.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)"+
				char(10)+"  where NI.NAMENO=N.NAMENO)"+
				char(10)+" or exists"+
				char(10)+"  (select * from #TEMPINSTRUCTIONS T"+
				char(10)+"   join CASENAME CN	on (CN.NAMETYPE=T.NAMETYPE"+
				char(10)+"			and CN.NAMENO  =N.NAMENO"+
				char(10)+"			and CN.EXPIRYDATE is null)"+
				char(10)+"   join CASES C		on (C.CASEID=CN.CASEID)"+
				char(10)+"   where C.REPORTTOTHIRDPARTY=1))"
		else
			set @sWhere =@sWhere+
				char(10)+"and (exists(select * from NAMEINSTRUCTIONS NI"+
				char(10)+"  join #TEMPINSTRUCTIONS T on (T.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)"+
				char(10)+"  where NI.NAMENO=N.NAMENO)"+
				char(10)+" or exists"+
				char(10)+"  (select * from #TEMPINSTRUCTIONS T"+
				char(10)+"   join CASENAME CN	on (CN.NAMETYPE=T.NAMETYPE"+
				char(10)+"			and CN.NAMENO  =N.NAMENO"+
				char(10)+"			and CN.EXPIRYDATE is null)"+
				char(10)+"   join CASES C		on (C.CASEID=CN.CASEID)"+
				char(10)+"   where C.REPORTTOTHIRDPARTY=1))"
	end

	Set @sSQLString=@sSelect+char(10)+@sFrom+char(10)+@sWhere+char(10)+@sOrderBy

	exec (@sSQLString)
	select  @pnRowCount=@@Rowcount,
		@ErrorCode=@@Error
	
	RETURN @ErrorCode
go

grant execute on dbo.na_ListClientBadDebtors  to public
go

