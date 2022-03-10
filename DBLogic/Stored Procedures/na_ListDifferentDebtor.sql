-----------------------------------------------------------------------------------------------------------------------------
-- Creation of na_ListDifferentDebtor
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[na_ListDifferentDebtor]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.na_ListDifferentDebtor.'
	drop procedure dbo.na_ListDifferentDebtor
end
print '**** Creating procedure dbo.na_ListDifferentDebtor...'
print ''
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

CREATE PROCEDURE dbo.na_ListDifferentDebtor
	@pnRowCount			int output,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@psFromNameCode			nvarchar(20)	= null,	
	@psToNameCode			nvarchar(20)	= null,	
	@psPropertyType			nvarchar(2)	= null,	-- Include/Exclude based on next parameter
	@pbPropertyTypeExcluded		tinyint		= 0,
	@pbCPAClientsOnly		tinyint		= 0,	-- Report names tagged as CPA clients
	@pbUseRenewalInstructor		tinyint		= 0,	-- Report on Renewal Instructor instead of Instructor 
	@pbReportDebtorDifference	tinyint		= 1,	-- Report where there is a different Debtor/Address/Attention
	@pbReportCopyTo			tinyint		= 1,	-- Report where Copy To details exist.
	@pbCaseLevelFlag		tinyint		= 0	-- Report on Cases that do not match the default 
	
AS
-- PROCEDURE :	na_ListDifferentDebtor
-- VERSION :	5
-- DESCRIPTION:	Returns details of Debtors and copy to information where the details vary to the main
--		instructor or renewal instructor.
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 08/07/2002	MF			Procedure created
-- 16/10/2002	MF	8051		Allow Street1 to be null in the temporary table
-- 06 Aug 2004	AB	8035	3	Add collate database_default to temp table definitions
-- 13 Nov 2007	Dw	14853	4	Bug fix. Data inserted into temp table was using wrong table aliases
-- 27 Feb 2014	DL	S21508	5	Change variables and temp table columns that reference namecode to 20 characters

	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF

	create table #TEMPINSTRUCTIONS 
			(	INSTRUCTIONCODE		smallint	not null,
				NAMETYPE		nvarchar(3)	collate database_default not null
			)

	-- We will need a unique set of Case characteristics for each debtor that potentially
	-- could have different fee calcualtions associated with them.

	create table #TEMPNAMEVARIATIONS
			(	NAMENO			int		not null,
				COPYTONO		int		null,
				DEBTORNO		int		null,
				CASEID			int		null,
				IRN			nvarchar(30)	collate database_default null, 
				CURRENTOFFICIALNO	nvarchar(36)	collate database_default null,
				POSTALADDRESSNO		int		null,
				COPYADDRESSNO		int		null,
				DEBTORADDRESSNO		int		null,
				NAMECODE		nvarchar(20)	collate database_default null,
				COPYNAMECODE		nvarchar(20)	collate database_default null,
				DEBTORNAMECODE		nvarchar(20)	collate database_default null,
				NAME			nvarchar(500)	collate database_default null,
				COPYNAME		nvarchar(500)	collate database_default null,
				DEBTORNAME		nvarchar(500)	collate database_default null,
				ATTENTION		nvarchar(500)	collate database_default null,
				COPYATTENTION		nvarchar(500)	collate database_default null,
				DEBTORATTENTION		nvarchar(500)	collate database_default null
			)

	CREATE INDEX XPKTEMPNAMEVARIATIONS ON #TEMPNAMEVARIATIONS
 	(
        	NAMENO
 	)

	Create table #TEMPADDRESSES
			(	ADDRESSCODE		int		not null PRIMARY KEY,
				STREET1			nvarchar(254)	collate database_default null,
				STREET2			nvarchar(254)	collate database_default null,
				CITY			nvarchar(30)	collate database_default null,
				STATE			nvarchar(20)	collate database_default null,
				STATENAME		nvarchar(30)	collate database_default null,
				POSTCODE		nvarchar(10)	collate database_default null,
				COUNTRY			nvarchar(50)	collate database_default null,
				POSTCODEFIRST		tinyint		null,
				STATEABBREVIATED	tinyint		null,
				ADDRESSSTYLE		int		null,
				FORMATTEDADDRESS	nvarchar(1000)	collate database_default null
			)

	DECLARE	@ErrorCode		int,
		@sSQLString		nvarchar(4000),
		@sSelect		nvarchar(2000),
		@sFrom			nvarchar(3000),
		@sWhere			nvarchar(2000),
		@sWhere2		nvarchar(2000),
		@sOrderBy		nvarchar(100),
		@nCurrentRow		int,
		@sInstructorNameType	nvarchar(3),
		@sDebtorNameType	nvarchar(3),
		@sCopyNameType		nvarchar(3)
	
	set @ErrorCode=0

	-- Initialise the NameTypes to be used in the searches depending on whether the procedure
	-- is being run for Renewals or not.  Note that these NameTypes are currently hardcoded however
	-- we may need to consider getting these from a Site Control

	If @pbUseRenewalInstructor=1
	begin
		set @sInstructorNameType='R'
	
		if @pbReportDebtorDifference=1
			set @sDebtorNameType='Z'

		if @pbReportCopyTo=1
			set @sCopyNameType='Y'
	end
	else begin
		set @sInstructorNameType='I'

		If @pbReportDebtorDifference=1
			set @sDebtorNameType='D'

		If @pbReportCopyTo=1
			set @sCopyNameType='C'
	end

	-- Initialise the SQL to get the names to be reported on.

	Set @sSelect	="Insert into #TEMPNAMEVARIATIONS(NAMENO, POSTALADDRESSNO, DEBTORNO, DEBTORADDRESSNO, COPYTONO, COPYADDRESSNO, NAMECODE, DEBTORNAMECODE, COPYNAMECODE, NAME, DEBTORNAME, COPYNAME, ATTENTION, DEBTORATTENTION, COPYATTENTION)"+char(10)+
			 "Select N.NAMENO, N.POSTALADDRESS, N1.NAMENO, isnull(AN1.POSTALADDRESS,N1.POSTALADDRESS), N2.NAMENO, isnull(AN2.POSTALADDRESS,N2.POSTALADDRESS),"+char(10)+
			 "       N.NAMECODE, N1.NAMECODE, N2.NAMECODE,"+char(10)+
			 "       rtrim(CASE WHEN  N.FIRSTNAME is NULL THEN  N.NAME ELSE  N.NAME+','+ N.FIRSTNAME END),"+char(10)+
			 "       rtrim(CASE WHEN N1.FIRSTNAME is NULL THEN N1.NAME ELSE N1.NAME+','+N1.FIRSTNAME END),"+char(10)+
			 "       rtrim(CASE WHEN N2.FIRSTNAME is NULL THEN N2.NAME ELSE N2.NAME+','+N2.FIRSTNAME END),"+char(10)+
			 "       ltrim( A.TITLE+' '+CASE WHEN( A.FIRSTNAME is not null) THEN  A.FIRSTNAME+' ' END+ A.NAME),"+char(10)+
			 "       ltrim(A1.TITLE+' '+CASE WHEN(A1.FIRSTNAME is not null) THEN A1.FIRSTNAME+' ' END+A1.NAME),"+char(10)+
			 "       ltrim(A2.TITLE+' '+CASE WHEN(A2.FIRSTNAME is not null) THEN A2.FIRSTNAME+' ' END+A2.NAME)"
	
	Set @sFrom	="from NAME N"+char(10)+
			 "left join NAME A             on (A.NAMENO=N.MAINCONTACT)"+char(10)+
			 "left join NAMETYPE NT1       on (NT1.NAMETYPE=@sDebtorNameType)"+char(10)+
			 "left join ASSOCIATEDNAME AN1 on (AN1.NAMENO=N.NAMENO"+char(10)+
			 "                             and AN1.RELATIONSHIP=NT1.PATHRELATIONSHIP)"+char(10)+
			 "left join NAME N1            on (N1.NAMENO=AN1.RELATEDNAME)"+char(10)+
			 "left join NAME A1            on (A1.NAMENO=isnull(AN1.CONTACT, N1.MAINCONTACT))"+char(10)+
			 "left join NAMETYPE NT2       on (NT2.NAMETYPE=@sCopyNameType)"+char(10)+
			 "left join ASSOCIATEDNAME AN2 on (AN2.NAMENO=N.NAMENO"+char(10)+
			 "                             and AN2.RELATIONSHIP=NT2.PATHRELATIONSHIP)"+char(10)+
			 "left join NAME N2            on (N2.NAMENO=AN2.RELATEDNAME)"+char(10)+
			 "left join NAME A2            on (A2.NAMENO=isnull(AN2.CONTACT, N2.MAINCONTACT))"

	Set @sWhere	="Where (  (N.NAMENO<>N1.NAMENO OR N.POSTALADDRESS<>isnull(AN1.POSTALADDRESS,N1.POSTALADDRESS) OR N.MAINCONTACT<>A1.NAMENO OR (N.MAINCONTACT is null and A1.NAMENO is not null)) "+char(10)+
			 "       or(N.NAMENO<>N2.NAMENO OR N.POSTALADDRESS<>isnull(AN2.POSTALADDRESS,N2.POSTALADDRESS) OR N.MAINCONTACT<>A1.NAMENO OR (N.MAINCONTACT is null and A1.NAMENO is not null)))"+char(10)+
			 "and exists"+char(10)+
			 "(select * from CASENAME CN"+char(10)+
			 " where CN.NAMETYPE=@sInstructorNameType)"


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
		set @sWhere = @sWhere +char(10)+"and	N.NAMECODE between '"+@psFromNameCode+"' and '"+@psToNameCode+"'"
		set @sWhere2= @sWhere2+char(10)+"and	N.NAMECODE between '"+@psFromNameCode+"' and '"+@psToNameCode+"'"
	end
	else if  @psFromNameCode is not NULL
	begin
		set @sWhere = @sWhere +char(10)+"and	N.NAMECODE >='"+@psFromNameCode+"'"
		set @sWhere2= @sWhere2+char(10)+"and	N.NAMECODE >='"+@psFromNameCode+"'"
	end
	else if @psToNameCode is not NULL
	begin
		set @sWhere = @sWhere +char(10)+"and	N.NAMECODE <='"+@psToNameCode+"'"
		set @sWhere2= @sWhere2+char(10)+"and	N.NAMECODE <='"+@psToNameCode+"'"
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
			char(10)+"   join STATUS S1	on (S1.STATUSCODE=C1.STATUSCODE"+
			char(10)+"                      and S1.LIVEFLAG=1)"+
			char(10)+"   where C1.REPORTTOTHIRDPARTY=1))"

		set @sWhere2=@sWhere2+char(10)+"and C.REPORTTOTHIRDPARTY=1"
	end

	If @ErrorCode=0
	begin
		Set @sSQLString=@sSelect+char(10)+@sFrom+char(10)+@sWhere+char(10)

		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sInstructorNameType	nvarchar(3),
						  @sDebtorNameType	nvarchar(3),
						  @sCopyNameType	nvarchar(3)',
						  @sInstructorNameType,
						  @sDebtorNameType,
						  @sCopyNameType
	end

	-- Now that the default variations in names have been extracted also check any 
	-- specific Case variations that do not match the default rules if the parameter

	If  @pbCaseLevelFlag=1
	and @ErrorCode=0
	begin

		-- Restrict the propertytype of the Cases to report on if Cases are being reported

		if @psPropertyType is not null
		begin
			if @pbPropertyTypeExcluded = 1
				set @sWhere2 = @sWhere2+char(10)+"and C.PROPERTYTYPE <> '"+@psPropertyType+"'"
			else
				set @sWhere2 = @sWhere2+char(10)+"and C.PROPERTYTYPE =  '"+@psPropertyType+"'"
		end

		Set @sSelect	="Insert into #TEMPNAMEVARIATIONS(CASEID, IRN, CURRENTOFFICIALNO, NAMENO, POSTALADDRESSNO, DEBTORNO, DEBTORADDRESSNO, COPYTONO, COPYADDRESSNO, NAMECODE, DEBTORNAMECODE, COPYNAMECODE, NAME, DEBTORNAME, COPYNAME, ATTENTION, DEBTORATTENTION, COPYATTENTION)"+char(10)+
				 "Select C.CASEID, C.IRN, C.CURRENTOFFICIALNO, N.NAMENO, N.POSTALADDRESS, N1.NAMENO, isnull(CN1.ADDRESSCODE,N1.POSTALADDRESS), N2.NAMENO, isnull(CN2.ADDRESSCODE,N2.POSTALADDRESS),"+char(10)+
			 "       N.NAMECODE, N1.NAMECODE, N2.NAMECODE,"+char(10)+
			 "       rtrim(CASE WHEN  N.FIRSTNAME is NULL THEN  N.NAME ELSE  N.NAME+','+ N.FIRSTNAME END),"+char(10)+
			 "       rtrim(CASE WHEN N1.FIRSTNAME is NULL THEN N1.NAME ELSE N1.NAME+','+N1.FIRSTNAME END),"+char(10)+
			 "       rtrim(CASE WHEN N2.FIRSTNAME is NULL THEN N2.NAME ELSE N2.NAME+','+N2.FIRSTNAME END),"+char(10)+
			 "       ltrim( A.TITLE+' '+CASE WHEN( A.FIRSTNAME is not null) THEN  A.FIRSTNAME+' ' END+ A.NAME),"+char(10)+
			 "       ltrim(A1.TITLE+' '+CASE WHEN(A1.FIRSTNAME is not null) THEN A1.FIRSTNAME+' ' END+A1.NAME),"+char(10)+
			 "       ltrim(A2.TITLE+' '+CASE WHEN(A2.FIRSTNAME is not null) THEN A2.FIRSTNAME+' ' END+A2.NAME)"
	
		Set @sFrom	="from CASENAME CN"+char(10)+
				 "     join NAME N       on (  N.NAMENO=CN.NAMENO)"+char(10)+
				 "left join NAME A       on (  A.NAMENO=isnull(CN.CORRESPONDNAME, N.MAINCONTACT))"+char(10)+
				 "     join CASES C      on (  C.CASEID=CN.CASEID)"+char(10)+
				 "     join STATUS S     on (  S.STATUSCODE=C.STATUSCODE"+char(10)+
				 "                       and   S.LIVEFLAG=1)"+char(10)+
				 "left join CASENAME CN1 on (CN1.CASEID=CN.CASEID"+char(10)+
				 "                       and CN1.NAMETYPE=@sDebtorNameType"+char(10)+
				 "                       and CN1.EXPIRYDATE is null)"+char(10)+
				 "left join NAME N1      on ( N1.NAMENO=CN1.NAMENO)"+char(10)+
				 "left join NAME A1      on ( A1.NAMENO=isnull(CN1.CORRESPONDNAME, N1.MAINCONTACT))"+char(10)+
				 "left join CASENAME CN2 on (CN2.CASEID=CN.CASEID"+char(10)+
				 "                       and CN2.NAMETYPE=@sCopyNameType"+char(10)+
				 "                       and CN2.EXPIRYDATE is null)"+char(10)+
				 "left join NAME N2      on ( N2.NAMENO=CN2.NAMENO)"+char(10)+
				 "left join NAME A2      on ( A2.NAMENO=isnull(CN2.CORRESPONDNAME, N2.MAINCONTACT))"
	
		Set @sWhere	="Where CN.NAMETYPE=@sInstructorNameType"+char(10)+
				 "and (  ((CN.NAMENO<>CN1.NAMENO or isnull(CN.ADDRESSCODE,N.POSTALADDRESS)<> isnull(CN1.ADDRESSCODE,N1.POSTALADDRESS) or A.NAMENO<>A1.NAMENO or (A.NAMENO is null and A1.NAMENO is not null)) AND not exists (select * from #TEMPNAMEVARIATIONS T where T.NAMENO=CN.NAMENO and T.DEBTORNO=CN1.NAMENO and T.NAMENO=A1.NAMENO and T.CASEID is null))"+char(10)+
				 "     or((CN.NAMENO<>CN2.NAMENO or isnull(CN.ADDRESSCODE,N.POSTALADDRESS)<> isnull(CN2.ADDRESSCODE,N2.POSTALADDRESS) or A.NAMENO<>A2.NAMENO or (A.NAMENO is null and A1.NAMENO is not null)) AND not exists (select * from #TEMPNAMEVARIATIONS T where T.NAMENO=CN.NAMENO and T.COPYTONO=CN2.NAMENO and T.NAMENO  =A2.NAMENO and T.CASEID is null)))"

		Set @sSQLString=@sSelect+char(10)+@sFrom+char(10)+@sWhere+@sWhere2
	
		exec @ErrorCode=sp_executesql @sSQLString,
						N'@sInstructorNameType	nvarchar(3),
						  @sDebtorNameType	nvarchar(3),
						  @sCopyNameType	nvarchar(3)',
						  @sInstructorNameType,
						  @sDebtorNameType,
						  @sCopyNameType
	end

	-- As there is potential that a lot of addresses may be repeated extract a distinct
	-- set of addresses to be formatted into an interim temporary table

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		insert into #TEMPADDRESSES 
		       (ADDRESSCODE, STREET1, STREET2, CITY, STATE, STATENAME,
			POSTCODE, COUNTRY, POSTCODEFIRST, STATEABBREVIATED, ADDRESSSTYLE)
		select	A.ADDRESSCODE, A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME,
			A.POSTCODE, substring(C.COUNTRY,1,50), C.POSTCODEFIRST, C.STATEABBREVIATED, C.ADDRESSSTYLE
		from #TEMPNAMEVARIATIONS T
		join ADDRESS A		on (A.ADDRESSCODE=T.POSTALADDRESSNO)
		left join COUNTRY C	on (C.COUNTRYCODE=A.COUNTRYCODE)
		left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
					and S.STATE      =A.STATE)
		union
		select	A.ADDRESSCODE, A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME,
			A.POSTCODE, substring(C.COUNTRY,1,50), C.POSTCODEFIRST, C.STATEABBREVIATED, C.ADDRESSSTYLE
		from #TEMPNAMEVARIATIONS T
		join ADDRESS A		on (A.ADDRESSCODE=T.COPYADDRESSNO)
		left join COUNTRY C	on (C.COUNTRYCODE=A.COUNTRYCODE)
		left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
					and S.STATE      =A.STATE)
		union
		select	A.ADDRESSCODE, A.STREET1, A.STREET2, A.CITY, A.STATE, S.STATENAME,
			A.POSTCODE, substring(C.COUNTRY,1,50), C.POSTCODEFIRST, C.STATEABBREVIATED, C.ADDRESSSTYLE
		from #TEMPNAMEVARIATIONS T
		join ADDRESS A		on (A.ADDRESSCODE=T.DEBTORADDRESSNO)
		left join COUNTRY C	on (C.COUNTRYCODE=A.COUNTRYCODE)
		left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
					and S.STATE      =A.STATE)"

		Exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Now format the distinct set of addresses extracted

	-- The Address styles are hardcode values as follows :
	-- 7201        Post Code before City - Full State
	-- 7202        Post Code before City - Short State
	-- 7203        Post Code before City - No State
	-- 7204        City before PostCode - Full State
	-- 7205        City before PostCode - Short State
	-- 7206        City before PostCode - No State
	-- 7207        Country First, Postcode, Full State, City then Street

	If @ErrorCode=0
	Begin
		Set @sSQLString="
		Update #TEMPADDRESSES
		Set FORMATTEDADDRESS=
			-- Country first
		CASE WHEN(ADDRESSSTYLE=7207)	
			THEN	COUNTRY+ 
				CASE WHEN(POSTCODE+STATENAME+CITY+STREET1+STREET2 is not NULL) THEN char(13)+char(10) END+
				POSTCODE+
				CASE WHEN(POSTCODE  is not null AND STATENAME+CITY is not null) THEN ' ' END+
				CASE WHEN(STATEABBREVIATED=1) THEN STATE ELSE STATENAME END+
				CASE WHEN(STATENAME is not null AND CITY is not null) THEN ' '+CITY ELSE CITY END+
				CASE WHEN(POSTCODE+STATENAME+CITY is not null AND STREET1+STREET2 is not null) THEN char(13)+char(10) END+
				STREET1+
				CASE WHEN(STREET1 is not null AND STREET2 is not NULL) THEN char(13)+char(10) END+
				STREET2
			-- POSTCODE before CITY
		     WHEN(ADDRESSSTYLE in (7201, 7202, 7203) OR (ADDRESSSTYLE is null AND POSTCODEFIRST=1))
			THEN	STREET1+
				CASE WHEN(STREET1 is not null AND STREET2 is not null) THEN char(13)+char(10) END+
				STREET2+
				CASE WHEN(STREET1+STREET2 is not null AND POSTCODE+CITY+STATE is not null) THEN char(13)+char(10) END+
				POSTCODE+
				CASE WHEN(POSTCODE is not null AND CITY is not null) THEN ' ' END+
				CITY+
				CASE WHEN(ADDRESSSTYLE=7201 OR (ADDRESSSTYLE is null AND isnull(STATEABBREVIATED,0)=0))
					THEN CASE WHEN(STREET1+STREET2 is not null and STATENAME is not null) THEN char(13)+char(10)
					          WHEN(POSTCODE+CITY   is not null and STATENAME is not null) THEN char(13)+char(10) 
					     END+
					     STATENAME
				END+
				CASE WHEN(ADDRESSSTYLE=7202 OR (ADDRESSSTYLE is null AND STATEABBREVIATED=1))
					THEN CASE WHEN(STREET1+STREET2 is not null and STATE is not null and POSTCODE+CITY is null) THEN char(13)+char(10)
					          WHEN(POSTCODE+CITY   is not null and STATE is not null) THEN ' ' 
					     END+
					     STATE
				END+
				char(13)+char(10)+COUNTRY
			-- POSTCODE after CITY
		     WHEN(ADDRESSSTYLE in (7204, 7205, 7206) OR (ADDRESSSTYLE is null AND isnull(POSTCODEFIRST,0)=0))
			THEN 	STREET1+
				CASE WHEN(STREET1 is not null AND STREET2 is not null) THEN char(13)+char(10) END+
				STREET2+
				CASE WHEN(STREET1+STREET2 is not null AND POSTCODE+CITY+STATE is not null) THEN char(13)+char(10) END+
				CITY+
				CASE WHEN(ADDRESSSTYLE=7204 OR (ADDRESSSTYLE is null AND isnull(STATEABBREVIATED,0)=0))
					THEN CASE WHEN(STREET1+STREET2+CITY is not null AND STATENAME is not null) THEN char(13)+char(10) END+
					     STATENAME
				END+
				CASE WHEN(ADDRESSSTYLE=7205 OR (ADDRESSSTYLE is null AND STATEABBREVIATED=1))
					THEN CASE WHEN(STREET1+STREET2 is not null AND STATE is not null AND CITY is null) THEN char(13)+char(10)
					          WHEN(CITY            is not null AND STATE is not null) THEN ' ' 
					     END+
					     STATE
				END+
				CASE WHEN(STREET1+STREET2 is not null AND CITY+STATE is null) THEN char(13)+char(10)
				     WHEN(CITY+STATE      is not null AND POSTCODE is not null) THEN ' '
				END+
				POSTCODE+
				char(13)+char(10)+COUNTRY
		END
		From #TEMPADDRESSES"

		Exec @ErrorCode=sp_executesql @sSQLString
	END

	set @sSQLString="
	
	select 	T.IRN, T.CURRENTOFFICIALNO,
		T.NAMECODE,       T.NAME,       T.ATTENTION,       A1.FORMATTEDADDRESS as Address,
	 	T.COPYNAMECODE,   T.COPYNAME,   T.COPYATTENTION,   A2.FORMATTEDADDRESS as CopyAddress,
	 	T.DEBTORNAMECODE, T.DEBTORNAME, T.DEBTORATTENTION, A3.FORMATTEDADDRESS as DebtorAddress

	from	#TEMPNAMEVARIATIONS T
	left join #TEMPADDRESSES A1	on (A1.ADDRESSCODE=T.POSTALADDRESSNO)
	left join #TEMPADDRESSES A2	on (A2.ADDRESSCODE=T.COPYADDRESSNO)
	left join #TEMPADDRESSES A3	on (A3.ADDRESSCODE=T.DEBTORADDRESSNO)
	order by T.IRN, T.NAMECODE, T.NAME"

	exec (@sSQLString)

	select  @pnRowCount=@@Rowcount,
		@ErrorCode=@@Error

	RETURN @ErrorCode
go

grant execute on dbo.na_ListDifferentDebtor  to public
go

