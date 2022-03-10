-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ListClientCharges
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[na_ListClientCharges]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.na_ListClientCharges.'
	drop procedure dbo.na_ListClientCharges
end
print '**** Creating procedure dbo.na_ListClientCharges...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.na_ListClientCharges
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psFromNameCode			nvarchar(10)	= null,	
	@psToNameCode			nvarchar(10)	= null,	
	@pbCPAClientsOnly		tinyint		= 0,	-- Report names tagged as CPA clients
	@pbClientSpecificChargesOnly	tinyint		= 0,	-- Report names that specific Charges defined
	@psPropertyType			nchar(1)	= null,
	@psCountryCode			nvarchar(3)	= null,
	@pnRateNo			int
	
AS
-- PROCEDURE :	na_ListClientCharges
-- VERSION:	6
-- DESCRIPTION:	Returns details of charges that will apply for a restricted set of Clients for an explicit Rate.
--		The report will be sorted by PropertyType
-- CALLED BY :	
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 03/07/2002	MF			Procedure created
-- 06 Aug 2004	AB	8035	2	Add collate database_default to temp table definitions
-- 07/07/2005	VL	11011	3	Change the CaseCategory size to nvarchar(2).
-- 28 Sep 2007	CR	14901	4	Changed Exchange Rate field sizes to (8,4)
-- 20 Oct 2015  MS      R53933  5       Changed size from decimal(8,4) to decimal(11,4) for EXCHRATE cols
-- 07 Jul 2016	MF	63861	6	A null LOCALCLIENTFLAG should default to 0.


	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF

	create table #TEMPINSTRUCTIONS 
			(	INSTRUCTIONCODE		smallint	not null,
				NAMETYPE		nvarchar(3)	collate database_default not null
			)

	-- We will need a unique set of Case characteristics for each debtor that potentially
	-- could have different fee calcualtions associated with them.

	create table #TEMPCLIENTCHARGES
			(	SEQUENCENO		int		identity(1,1) PRIMARY KEY,
				NAMENO			int		null,
				CASETYPE		nchar(1)	collate database_default null,
				PROPERTYTYPE		nchar(1)	collate database_default null,
				COUNTRYCODE		nvarchar(3)	collate database_default null,
				CASECATEGORY		nvarchar(2)	collate database_default null,
				SUBTYPE			nvarchar(2)	collate database_default null,
				LOCALCLIENTFLAG		tinyint		null,
				ENTITYSIZE		int		null,
				TYPEOFMARK		int		null,
				YEARNO			smallint	null,
				CRITERIANO		int		null,
				CRITERIADESC		nvarchar(254)	collate database_default null,
				DISBCURRENCY		nvarchar(3)	collate database_default null,
				SERVCURRENCY		nvarchar(3)	collate database_default null,
				BILLCURRENCY		nvarchar(3)	collate database_default null,
				DISBAMOUNT		decimal(11,2)	null,
				DISBHOMEAMOUNT		decimal(11,2)	null,
				DISBBILLAMOUNT		decimal(11,2)	null,
				SERVAMOUNT		decimal(11,2)	null,
				SERVHOMEAMOUNT		decimal(11,2)	null,
				SERVBILLAMOUNT		decimal(11,2)	null,
				DISBDISCORIGINAL	decimal(11,2)	null,
				DISBHOMEDISCOUNT	decimal(11,2)	null,
				DISBBILLDISCOUNT	decimal(11,2)	null,
				SERVDISCORIGINAL	decimal(11,2)	null,
				SERVHOMEDISCOUNT	decimal(11,2)	null,
				SERVBILLDISCOUNT	decimal(11,2)	null,
				TOTHOMEDISCOUNT		decimal(11,2)	null,
				TOTBILLDISCOUNT		decimal(11,2)	null,
				DISBTAXAMT		decimal(11,2)	null,
				DISBTAXHOMEAMT		decimal(11,2)	null,
				DISBTAXBILLAMT		decimal(11,2)	null,
				SERVTAXAMT		decimal(11,2)	null,
				SERVTAXHOMEAMT		decimal(11,2)	null,
				SERVTAXBILLAMT		decimal(11,2)	null
			)


	DECLARE	@ErrorCode		int,
		@sSQLString		nvarchar(4000),
		@sSelect		nvarchar(1000),
		@sFrom			nvarchar(3000),
		@sWhere			nvarchar(1000),
		@sOrderBy		nvarchar(100),
		@sRateDesc		nvarchar(50),
		@nRateType		int,
		@bUseTypeOfMark		tinyint,
		@nCurrentRow		int,
		@nCriteriaNo		int,
		@sIRN			nvarchar(30),
		@nYearNo		smallint
	
	-- Variable to be returned as output parameters from FEESCALC.

	declare @prsDisbCurrency 	varchar(3),	
		@prnDisbExchRate 	decimal(11,4), 
		@prsServCurrency 	varchar(3) , 	
		@prnServExchRate 	decimal(11,4) , 
		@prsBillCurrency 	varchar(3) , 	
		@prnBillExchRate 	decimal(11,4) , 
		@prsDisbTaxCode 	varchar(3) , 	
		@prsServTaxCode 	varchar(3) , 
		@prnDisbNarrative 	int 	, 		
		@prnServNarrative 	int 	, 
		@prsDisbWIPCode 	varchar(6) , 	
		@prsServWIPCode 	varchar(6) , 
		@prnDisbAmount 		decimal(11,2) , 	
		@prnDisbHomeAmount 	decimal(11,2) , 
		@prnDisbBillAmount 	decimal(11,2) ,
		@prnServAmount 		decimal(11,2) , 
		@prnServHomeAmount 	decimal(11,2) ,
		@prnServBillAmount 	decimal(11,2) , 
		@prnTotHomeDiscount 	decimal(11,2) ,
		@prnTotBillDiscount 	decimal(11,2) , 
		@prnDisbTaxAmt 		decimal(11,2) , 	
		@prnDisbTaxHomeAmt 	decimal(11,2) , 
		@prnDisbTaxBillAmt 	decimal(11,2) ,
		@prnServTaxAmt 		decimal(11,2) , 	
		@prnServTaxHomeAmt 	decimal(11,2) ,
		@prnServTaxBillAmt 	decimal(11,2) ,				
		@prnDisbDiscOriginal	decimal(11,2) ,
		@prnDisbHomeDiscount 	decimal(11,2) ,
		@prnDisbBillDiscount 	decimal(11,2) ,
		@prnServDiscOriginal	decimal(11,2) ,
		@prnServHomeDiscount 	decimal(11,2) ,
		@prnServBillDiscount 	decimal(11,2) ,
		@prnDisbCostHome	decimal(11,2) ,
		@prnDisbCostOriginal	decimal(11,2)		

	set @ErrorCode=0

	-- Get the RATES row to determine what type of Debtor is to be used and whether or not 
	-- the type of mark is also required to determine the Fees.

	If @ErrorCode=0
	begin
		set @sSQLString="
		select	@nRateType=RATETYPE,
			@sRateDesc=RATEDESC,
			@bUseTypeOfMark=USETYPEOFMARK
		from RATES
		where RATENO=@pnRateNo"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@nRateType		int		OUTPUT,
						  @sRateDesc		nvarchar(50)	OUTPUT,
						  @bUseTypeOfMark	tinyint		OUTPUT,
						  @pnRateNo		int',
						  @nRateType=@nRateType			OUTPUT,
						  @sRateDesc=@sRateDesc			OUTPUT,
						  @bUseTypeOfMark=@bUseTypeOfMark	OUTPUT,
						  @pnRateNo=@pnRateNo
	End

	-- Initialise the SQL to get unique set of characteristics for which rates are to be extracted

	Set @sSelect	="Insert into #TEMPCLIENTCHARGES(NAMENO, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE, LOCALCLIENTFLAG, ENTITYSIZE, TYPEOFMARK)"+char(10)+
			 "Select distinct N.NAMENO, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE, isnull(C.LOCALCLIENTFLAG,0), C.ENTITYSIZE, "+CASE WHEN(@bUseTypeOfMark=1) THEN "C.TYPEOFMARK" ELSE "NULL" END
	
	Set @sFrom	="from NAME N"+char(10)+
			 "join CASENAME CN on (CN.NAMENO=N.NAMENO"      +char(10)+
			 "                 and CN.NAMETYPE="+CASE WHEN(@nRateType=1601) THEN "'Z'" ELSE "'D'" END+char(10)+
			 "                 and CN.EXPIRYDATE is null)"  +char(10)+
			 "join CASES C     on (C.CASEID=CN.CASEID)"	+char(10)+
			 "join STATUS S    on (S.STATUSCODE=C.STATUSCODE"+char(10)+
			 "                 and S.LIVEFLAG  =1)"

	Set @sWhere	="Where C.PROPERTYTYPE is not null"


	-- If the report is to be restricted to CPA Reportable clients ONLY
	-- then we need to find out what Instruction codes will cause the CPA
	-- flag to be set on against Cases so as to check if the Instruction 
	-- applies to the debtor

	if @pbCPAClientsOnly=1
	and @ErrorCode=0
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
		set @sWhere = @sWhere+char(10)+"and	N.NAMECODE between '"+@psFromNameCode+"' and '"+@psToNameCode+"'"
	end
	else if  @psFromNameCode is not NULL
	begin
		set @sWhere = @sWhere+char(10)+"and	N.NAMECODE >='"+@psFromNameCode+"'"
	end
	else if @psToNameCode is not NULL
	begin
		set @sWhere = @sWhere+char(10)+"and	N.NAMECODE <='"+@psToNameCode+"'"
	end

	-- Restrict to a specific Property Type

	If @psPropertyType is not null
	begin
		set @sWhere = @sWhere+char(10)+"and	C.PROPERTYTYPE='"+@psPropertyType+"'"
	end

	-- Restrict to a specific Country

	If @psCountryCode is not null
	begin
		set @sWhere = @sWhere+char(10)+"and	C.COUNTRYCODE='"+@psCountryCode+"'"
	end

	-- Restrict to Names that have a FEESCALCULATION explicitly defined

	If @pbClientSpecificChargesOnly=1
	begin 
		set @sWhere=@sWhere+
			char(10)+"and exists"+
			char(10)+"(select * from FEESCALCULATION FC"+
			char(10)+" where FC.DEBTOR=N.NAMENO)"
	end

	-- Restrict to only Clients that report cases to CPA

	If @pbCPAClientsOnly=1
	begin
		set @sWhere =@sWhere+
			char(10)+"and (exists(select * from NAMEINSTRUCTIONS NI"+
			char(10)+"  join #TEMPINSTRUCTIONS T on (T.INSTRUCTIONCODE=NI.INSTRUCTIONCODE)"+
			char(10)+"  where NI.NAMENO=N.NAMENO)"+
			char(10)+" or exists"+
			char(10)+"  (select * from #TEMPINSTRUCTIONS T"+
			char(10)+"   join CASENAME CN1	on (CN1.NAMETYPE=T.NAMETYPE"+
			char(10)+"			and CN1.NAMENO  =N.NAMENO"+
			char(10)+"			and CN1.EXPIRYDATE is null)"+
			char(10)+"   join CASES C1	on (C1.CASEID=CN1.CASEID)"+
			char(10)+"   where C1.REPORTTOTHIRDPARTY=1))"
	end

	If @ErrorCode=0
	begin
		Set @sSQLString=@sSelect+char(10)+@sFrom+char(10)+@sWhere+char(10)
		
		exec @ErrorCode=sp_executesql @sSQLString
	end

	-- Now we have a unique set of characteristics we must get the CriteriaNo that would be used
	-- so that we can determine if we need to return a different Fee for each year.  We must loop
	-- through each row in #TEMPCLIENTCHARGES and extract the CriteriaNo.  The method used avoids 
	-- cursors

	Set @nCurrentRow=1

	While @nCurrentRow is not null
	and @ErrorCode=0
	Begin
		Set @sSQLString="
		SELECT 	@nCriteriaNo =
			Substring ( max(
			CASE WHEN C.CASETYPE	    is null THEN '0' ELSE '1' END +
			CASE WHEN C.PROPERTYTYPE    is null THEN '0' ELSE '1' END +
			CASE WHEN C.COUNTRYCODE	    is null THEN '0' ELSE '1' END +
			CASE WHEN C.CASECATEGORY    is null THEN '0' ELSE '1' END +
			CASE WHEN C.SUBTYPE	    is null THEN '0' ELSE '1' END +
			CASE WHEN C.LOCALCLIENTFLAG is null THEN '0' ELSE '1' END +
			CASE WHEN C.TYPEOFMARK      is null THEN '0' ELSE '1' END +
			CASE WHEN C.TABLECODE	    is null THEN '0' ELSE '1' END +
			isnull(convert(char(8), C.DATEOFACT,112),'00000000')+		-- valid from date in YYYYMMDD format
			convert(char(11),C.CRITERIANO)),17,11)
		FROM  CRITERIA C 
		join  #TEMPCLIENTCHARGES T on (T.SEQUENCENO=@nCurrentRow) 
		WHERE C.RULEINUSE	= 1  
		AND   C.PURPOSECODE	= 'F'  
		AND   C.RATENO		= @pnRateNo  
		AND ( C.CASETYPE	= T.CASETYPE		OR C.CASETYPE		IS NULL) 
		AND ( C.PROPERTYTYPE	= T.PROPERTYTYPE	OR C.PROPERTYTYPE	IS NULL) 
		AND ( C.COUNTRYCODE	= T.COUNTRYCODE		OR C.COUNTRYCODE	IS NULL)  
		AND ( C.CASECATEGORY	= T.CASECATEGORY	OR C.CASECATEGORY	IS NULL) 
		AND ( C.SUBTYPE		= T.SUBTYPE		OR C.SUBTYPE		IS NULL) 
		AND ( C.LOCALCLIENTFLAG = T.LOCALCLIENTFLAG	OR C.LOCALCLIENTFLAG	IS NULL) 
		AND ( C.TYPEOFMARK	= T.TYPEOFMARK		OR C.TYPEOFMARK		IS NULL) 
		AND ( C.TABLECODE	= T.ENTITYSIZE		OR C.TABLECODE		IS NULL) 
		AND ( C.DATEOFACT      <= getdate()		OR C.DATEOFACT		IS NULL)"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCriteriaNo	int	OUTPUT,
						  @pnRateNo	int,
						  @nCurrentRow	int',
						  @nCriteriaNo=@nCriteriaNo OUTPUT,
						  @pnRateNo=@pnRateNo,
						  @nCurrentRow=@nCurrentRow

		-- If a CriteriaNo is found then insert a row into #TEMPCLIENTCHARGES
		-- with the characteristics of the Criteria and if there are multiple
		-- cycles defined against FEESCALCULATION then also insert this data

		If  @ErrorCode=0
		and @nCriteriaNo is not null
		begin
			Set @sSQLString="
			insert into #TEMPCLIENTCHARGES(NAMENO, CASETYPE, PROPERTYTYPE, COUNTRYCODE, CASECATEGORY, SUBTYPE, LOCALCLIENTFLAG, ENTITYSIZE, YEARNO, TYPEOFMARK, CRITERIANO, CRITERIADESC)
			select distinct T.NAMENO, C.CASETYPE, C.PROPERTYTYPE, C.COUNTRYCODE, C.CASECATEGORY, C.SUBTYPE, isnull(C.LOCALCLIENTFLAG,0), C.TABLECODE, F.CYCLENUMBER, C.TYPEOFMARK, C.CRITERIANO, C.DESCRIPTION
			from #TEMPCLIENTCHARGES T
			join CRITERIA C		on (C.CRITERIANO=@nCriteriaNo)
			join FEESCALCULATION F	on (F.CRITERIANO=C.CRITERIANO)
			where T.SEQUENCENO=@nCurrentRow
			and not exists
			(select * from #TEMPCLIENTCHARGES T1
 			 where T1.NAMENO=T.NAMENO
			 and   T1.CRITERIANO=C.CRITERIANO)"

			-- If we only want to report on Names that have an explicit
			-- charge defined then add an addition constraint to the Where clause
			If @pbClientSpecificChargesOnly=1
			begin
				set @sSQLString=@sSQLString+char(10)+"			and F.DEBTOR=T.NAMENO"
			end

			exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCurrentRow	int,
							  @nCriteriaNo	int',
							  @nCurrentRow=@nCurrentRow,
							  @nCriteriaNo=@nCriteriaNo
		end

		-- Now get the next row to process

		If @ErrorCode=0
		begin
			set @sSQLString="
			select @nCurrentRowOUT=min(SEQUENCENO)
			from #TEMPCLIENTCHARGES T
			where T.SEQUENCENO>@nCurrentRow
			and   T.CRITERIANO is null"

			exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCurrentRowOUT	int	OUTPUT,
							  @nCurrentRow		int',
							  @nCurrentRowOUT=@nCurrentRow	OUTPUT,
							  @nCurrentRow   =@nCurrentRow
		end
	End	-- End of WHILE loop

	-- Now that we have a unique set of Criteria and their characteristics for each
	-- Debtor we can delete all of the rows that still do not have a Criteriano

	If @ErrorCode=0
	begin
		set @sSQLString="
		delete from #TEMPCLIENTCHARGES
		where CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	-- To extract the fees and charges we will require a an IRN that matches the 
	-- Criteria to be extracted.  Construct an SQL statement to be used to find
	-- an IRN for each row to be processed
	
	Set @sSelect	="Select @sIRN=C.IRN, @nYearNo=T.YEARNO"
	
	Set @sFrom	="from #TEMPCLIENTCHARGES T"+char(10)+
			 "join CASENAME CN on (CN.NAMENO=T.NAMENO"         +char(10)+
			 "                 and CN.NAMETYPE="+CASE WHEN(@nRateType=1601) THEN "'Z'" ELSE "'D'" END+char(10)+
			 "                 and CN.EXPIRYDATE is null)"     +char(10)+
			 "join CASES C     on (C.IRN = (select min(C1.IRN)"+char(10)+
			 "                              from CASES C1"     +char(10)+
			 "                              join STATUS S1 on (S1.STATUSCODE=C1.STATUSCODE"+char(10)+
			 "                                             and S1.LIVEFLAG  =1)"           +char(10)+
			 "                              where  C1.CASEID=CN.CASEID"                    +char(10)+
			 "                              and   (C1.CASETYPE       =T.CASETYPE        or T.CASETYPE        is null)"+char(10)+
			 "                              and   (C1.PROPERTYTYPE   =T.PROPERTYTYPE    or T.PROPERTYTYPE    is null)"+char(10)+
			 "                              and   (C1.COUNTRYCODE    =T.COUNTRYCODE     or T.COUNTRYCODE     is null)"+char(10)+
			 "                              and   (C1.CASECATEGORY   =T.CASECATEGORY    or T.CASECATEGORY    is null)"+char(10)+
			 "                              and   (C1.SUBTYPE        =T.SUBTYPE         or T.SUBTYPE         is null)"+char(10)+
			 "                              and   (C1.LOCALCLIENTFLAG=T.LOCALCLIENTFLAG or T.LOCALCLIENTFLAG is null)"+char(10)+
			 "                              and   (C1.TYPEOFMARK     =T.TYPEOFMARK      or T.TYPEOFMARK      is null)"+char(10)+
			 "                              and   (C1.ENTITYSIZE     =T.ENTITYSIZE      or T.ENTITYSIZE      is null)))"

	Set @sWhere	="Where T.SEQUENCENO=@nCurrentRow"

	-- Get the sequence number of the first row to process

	If @ErrorCode=0
	begin
		set @sSQLString="
		select @nCurrentRowOUT=min(SEQUENCENO)
		from #TEMPCLIENTCHARGES T"

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@nCurrentRowOUT	int	OUTPUT',
						  @nCurrentRowOUT=@nCurrentRow	OUTPUT
	end	

	-- Now loop through each row and call the procedures to do the calculations

	While @nCurrentRow is not null
	and @ErrorCode=0
	begin
		Set @sSQLString=@sSelect+char(10)+@sFrom+char(10)+@sWhere

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sIRN		nvarchar(30)	OUTPUT,
						  @nYearNo	int		OUTPUT,
						  @nCurrentRow	int',
						  @sIRN       =@sIRN	OUTPUT,
						  @nYearNo    =@nYearNo	OUTPUT,
						  @nCurrentRow=@nCurrentRow

		-- Now use the FEESCALC stored procedure to determine the fees and 
		-- charges to 

		exec @ErrorCode=FEESCALC 
				@psIRN=@sIRN,
				@pnRateNo=@pnRateNo,
				@pnCycle=@nYearNo,
				@prsDisbCurrency=@prsDisbCurrency 	output,	
				@prnDisbExchRate=@prnDisbExchRate 	output, 
				@prsServCurrency=@prsServCurrency 	output, 	
				@prnServExchRate=@prnServExchRate 	output, 
				@prsBillCurrency=@prsBillCurrency 	output, 	
				@prnBillExchRate=@prnBillExchRate 	output, 
				@prsDisbTaxCode=@prsDisbTaxCode 	output, 	
				@prsServTaxCode=@prsServTaxCode 	output, 
				@prnDisbNarrative=@prnDisbNarrative 	output, 		
				@prnServNarrative=@prnServNarrative 	output, 
				@prsDisbWIPCode=@prsDisbWIPCode 	output, 	
				@prsServWIPCode=@prsServWIPCode 	output, 
				@prnDisbAmount=@prnDisbAmount 		output, 	
				@prnDisbHomeAmount=@prnDisbHomeAmount 	output, 
				@prnDisbBillAmount=@prnDisbBillAmount 	output,
				@prnServAmount=@prnServAmount 		output, 
				@prnServHomeAmount=@prnServHomeAmount 	output,
				@prnServBillAmount=@prnServBillAmount 	output, 
				@prnTotHomeDiscount=@prnTotHomeDiscount output,
				@prnTotBillDiscount=@prnTotBillDiscount output, 
				@prnDisbTaxAmt=@prnDisbTaxAmt 		output, 	
				@prnDisbTaxHomeAmt=@prnDisbTaxHomeAmt 	output, 
				@prnDisbTaxBillAmt=@prnDisbTaxBillAmt 	output,
				@prnServTaxAmt=@prnServTaxAmt 		output, 	
				@prnServTaxHomeAmt=@prnServTaxHomeAmt 	output,
				@prnServTaxBillAmt=@prnServTaxBillAmt 	output,
				@prnDisbDiscOriginal=@prnDisbDiscOriginal output,
				@prnDisbHomeDiscount=@prnDisbHomeDiscount output,
				@prnDisbBillDiscount=@prnDisbBillDiscount output, 
				@prnServDiscOriginal=@prnServDiscOriginal output,
				@prnServHomeDiscount=@prnServHomeDiscount output,
				@prnServBillDiscount=@prnServBillDiscount output,
				@prnDisbCostHome=@prnDisbCostHome	  output,
				@prnDisbCostOriginal=@prnDisbCostOriginal output

				set @sSQLString="
				update #TEMPCLIENTCHARGES
				set	DISBCURRENCY	=@prsDisbCurrency,
					SERVCURRENCY	=@prsServCurrency,
					BILLCURRENCY	=@prsBillCurrency,
					DISBAMOUNT	=@prnDisbAmount,
					DISBHOMEAMOUNT	=@prnDisbHomeAmount,
					DISBBILLAMOUNT	=@prnDisbBillAmount,
					SERVAMOUNT	=@prnServAmount,
					SERVHOMEAMOUNT	=@prnServHomeAmount,
					SERVBILLAMOUNT	=@prnServBillAmount,
					DISBDISCORIGINAL=@prnDisbDiscOriginal,
					DISBHOMEDISCOUNT=@prnDisbHomeDiscount,
					DISBBILLDISCOUNT=@prnDisbBillDiscount,
					SERVDISCORIGINAL=@prnServDiscOriginal,
					SERVHOMEDISCOUNT=@prnServHomeDiscount,
					SERVBILLDISCOUNT=@prnServBillDiscount,
					TOTHOMEDISCOUNT	=@prnTotHomeDiscount,
					TOTBILLDISCOUNT	=@prnTotBillDiscount,
					DISBTAXAMT	=@prnDisbTaxAmt,
					DISBTAXHOMEAMT	=@prnDisbTaxHomeAmt,
					DISBTAXBILLAMT	=@prnDisbTaxBillAmt,
					SERVTAXAMT	=@prnServTaxAmt,
					SERVTAXHOMEAMT	=@prnServTaxHomeAmt,
					SERVTAXBILLAMT	=@prnServTaxBillAmt
				where SEQUENCENO=@nCurrentRow"

				exec @ErrorCode=sp_executesql @sSQLString,
							N'@prsDisbCurrency		nvarchar(3),
			 				  @prsServCurrency		nvarchar(3),
							  @prsBillCurrency		nvarchar(3),
							  @prnDisbAmount		decimal(11,2),
							  @prnDisbHomeAmount		decimal(11,2),
							  @prnDisbBillAmount		decimal(11,2),
							  @prnServAmount		decimal(11,2),
							  @prnServHomeAmount		decimal(11,2),
							  @prnServBillAmount		decimal(11,2),
							  @prnDisbDiscOriginal		decimal(11,2),
							  @prnDisbHomeDiscount		decimal(11,2),
							  @prnDisbBillDiscount		decimal(11,2),
							  @prnServDiscOriginal		decimal(11,2),
							  @prnServHomeDiscount		decimal(11,2),
							  @prnServBillDiscount		decimal(11,2),
							  @prnTotHomeDiscount		decimal(11,2),
							  @prnTotBillDiscount		decimal(11,2),
							  @prnDisbTaxAmt		decimal(11,2),
							  @prnDisbTaxHomeAmt		decimal(11,2),
							  @prnDisbTaxBillAmt		decimal(11,2),
							  @prnServTaxAmt		decimal(11,2),
							  @prnServTaxHomeAmt		decimal(11,2),
							  @prnServTaxBillAmt		decimal(11,2),
							  @nCurrentRow			int',
							  @prsDisbCurrency,
							  @prsServCurrency,
							  @prsBillCurrency,
							  @prnDisbAmount,
							  @prnDisbHomeAmount,
							  @prnDisbBillAmount,
							  @prnServAmount,
							  @prnServHomeAmount,
							  @prnServBillAmount,
							  @prnDisbDiscOriginal,
							  @prnDisbHomeDiscount,
							  @prnDisbBillDiscount,
							  @prnServDiscOriginal,
							  @prnServHomeDiscount,
							  @prnServBillDiscount,
							  @prnTotHomeDiscount,
							  @prnTotBillDiscount,
							  @prnDisbTaxAmt,
							  @prnDisbTaxHomeAmt,
							  @prnDisbTaxBillAmt,
							  @prnServTaxAmt,
							  @prnServTaxHomeAmt,
							  @prnServTaxBillAmt,
							  @nCurrentRow

		-- Now get the next row to process

		If @ErrorCode=0
		begin
			set @sSQLString="
			select @nCurrentRowOUT=min(SEQUENCENO)
			from #TEMPCLIENTCHARGES T
			where T.SEQUENCENO>@nCurrentRow"

			exec @ErrorCode=sp_executesql @sSQLString,
							N'@nCurrentRowOUT	int	OUTPUT,
							  @nCurrentRow		int',
							  @nCurrentRowOUT=@nCurrentRow	OUTPUT,
							  @nCurrentRow   =@nCurrentRow
		end
	End	-- End of WHILE loop

	set @sSQLString="
	select	N.NAMECODE,
		N.NAME+CASE WHEN(N.FIRSTNAME is not null) THEN ', '+N.FIRSTNAME END as NAME,
		T.CRITERIADESC,
		T.CRITERIANO,
		CT.CASETYPEDESC,
		isnull(VP.PROPERTYNAME, P.PROPERTYNAME) as PROPERTYNAME,
		C.COUNTRY,
		C.COUNTRYCODE,
		isnull(VC.CASECATEGORYDESC, CC.CASECATEGORYDESC) as CASECATEGORYDESC,
		isnull(VS.SUBTYPEDESC, S.SUBTYPEDESC) as SUBTYPEDESC,
		LOCALCLIENTFLAG,
		T1.DESCRIPTION as ENTITYSIZE,
		T2.DESCRIPTION as TYPEOFMARK,
		YEARNO,
		DISBCURRENCY,
		SERVCURRENCY,
		BILLCURRENCY,
		DISBAMOUNT,
		DISBHOMEAMOUNT,
		DISBBILLAMOUNT,
		SERVAMOUNT,
		SERVHOMEAMOUNT,
		SERVBILLAMOUNT,
		DISBDISCORIGINAL,
		DISBHOMEDISCOUNT,
		DISBBILLDISCOUNT,
		SERVDISCORIGINAL,
		SERVHOMEDISCOUNT,
		SERVBILLDISCOUNT,
		DISBTAXAMT,
		DISBTAXHOMEAMT,
		DISBTAXBILLAMT,
		SERVTAXAMT,
		SERVTAXHOMEAMT,
		SERVTAXBILLAMT
	from #TEMPCLIENTCHARGES T
	     join NAME N		on (N.NAMENO   =T.NAMENO)
	left join CASETYPE CT		on (CT.CASETYPE=T.CASETYPE)
	left join PROPERTYTYPE P	on (P.PROPERTYTYPE=T.PROPERTYTYPE)
	left join VALIDPROPERTY VP	on (VP.PROPERTYTYPE=T.PROPERTYTYPE
					and VP.COUNTRYCODE =(	select min(VP1.COUNTRYCODE)
								from VALIDPROPERTY VP1
								where VP1.COUNTRYCODE in ('ZZZ',T.COUNTRYCODE)
								and   VP1.PROPERTYTYPE=T.PROPERTYTYPE))
	left join COUNTRY C		on (C.COUNTRYCODE=T.COUNTRYCODE)
	left join CASECATEGORY CC	on (CC.CASETYPE    =T.CASETYPE
					and CC.CASECATEGORY=T.CASECATEGORY)
	left join VALIDCATEGORY VC	on (VC.PROPERTYTYPE=T.PROPERTYTYPE
					and VC.CASETYPE    =T.CASETYPE				
					and VC.CASECATEGORY=T.CASECATEGORY
					and VC.COUNTRYCODE =(	select min(VC1.COUNTRYCODE)
								from VALIDCATEGORY VC1
								where VC1.COUNTRYCODE in ('ZZZ',T.COUNTRYCODE)
								and   VC1.CASETYPE    =T.CASETYPE
								and   VC1.PROPERTYTYPE=T.PROPERTYTYPE
								and   VC1.CASECATEGORY=T.CASECATEGORY))
	left join SUBTYPE S		on (S.SUBTYPE=T.SUBTYPE)
	left join VALIDSUBTYPE VS	on (VS.PROPERTYTYPE=T.PROPERTYTYPE
					and VS.CASETYPE    =T.CASETYPE
					and VS.CASECATEGORY=T.CASECATEGORY
					and VS.SUBTYPE     =T.SUBTYPE
					and VS.COUNTRYCODE =(	select min(VS1.COUNTRYCODE)
								from VALIDSUBTYPE VS1
								where VS1.COUNTRYCODE in ('ZZZ',T.COUNTRYCODE)
								and   VS1.CASETYPE    =T.CASETYPE
								and   VS1.PROPERTYTYPE=T.PROPERTYTYPE
								and   VS1.CASECATEGORY=T.CASECATEGORY
								and   VS1.SUBTYPE     =T.SUBTYPE))
	left join TABLECODES T1		on (T1.TABLECODE=T.ENTITYSIZE)
	left join TABLECODES T2		on (T2.TABLECODE=T.TYPEOFMARK)
	order by CRITERIADESC, T.CRITERIANO, T.CASETYPE, T.COUNTRYCODE, T.PROPERTYTYPE, T.CASECATEGORY, T.SUBTYPE, T.TYPEOFMARK, T.ENTITYSIZE, N.NAMECODE, N.NAME, T.YEARNO"

	exec (@sSQLString)

	select  @pnRowCount=@@Rowcount,
		@ErrorCode=@@Error

	RETURN @ErrorCode
go

grant execute on dbo.na_ListClientCharges to public
go
