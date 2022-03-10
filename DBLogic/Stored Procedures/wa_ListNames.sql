-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_ListNames
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_ListNames]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_ListNames'
	drop procedure [dbo].[wa_ListNames]
end
print '**** Creating procedure dbo.wa_ListNames...'
print ''
go

set QUOTED_IDENTIFIER off
go

CREATE PROCEDURE [dbo].[wa_ListNames]
	@iRowCount	int output, /* the number of rows available */
	@iPage		int,
	@iPageSize	int,
	@sAnySearch varchar(254) = NULL,	/* search through any of the important fields */
	/* other search criteria to include*/
	@sSearchKey		varchar(20) 	= NULL,
	@bUseKey1		int 		= NULL,	
	@bUseKey2		int 		= NULL,
	@sNameCode		varchar(20) 	= NULL,
	@bHasCode		int 		= NULL,
	@sName		 	varchar(20) 	= NULL,
	@sFirstName	 	varchar(20) 	= NULL,
	@sCountry	 	varchar(20) 	= NULL,
	@sCity		 	varchar(20) 	= NULL,
	@sLocality	 	varchar(20) 	= NULL,
	@sUsedAs	 	varchar(20) 	= NULL,
	@sCategory	 	varchar(20) 	= NULL,
	@sFiledIn	 	varchar(20) 	= NULL,
	@sTelecomNo	 	varchar(100) 	= NULL,
	@sArea			varchar(20)	= NULL,
	@sTextType		varchar(20) 	= NULL,
	@nEntityType		int 		= NULL,
	@nStatus		int 		= NULL, /* current and/or ceased */
	@sGroup			varchar(20) 	= NULL
AS
-- PROCEDURE :	wa_ListNames
-- VERSION :	8
-- DESCRIPTION:	Constructs a SELECT statement using the parameters passed and then returns
--		details of the Names returned after executing the SELECT.
-- 	
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 01/07/2001	MF		1	Procedure created	
-- 01/07/2001	AF		2	Remove % from like prefix in any search and include column headings
-- 16/08/2001	MF		3	Allow all rows to be returned if @iPageSize is zero.
-- 06 Aug 2004	AB	8035	4	Add collate database_default to temp table definitions
-- 22 Nov 2007	SW	RFC5967	5	Change TELECOMMUNICATION.TELECOMNUMBER from nvarchar(50) to nvarchar(100)
-- 15 Dec 2008	MF	17136	6	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 04 Jun 2010	MF	18703	7	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be null here.
-- 27 Feb 2014	DL	S21508	8	Change variables and temp table columns that reference namecode to 20 characters

begin
	-- set server options
	set NOCOUNT on
	set QUOTED_IDENTIFIER off
	set CONCAT_NULL_YIELDS_NULL off

	
	-- declare variables
	declare @iStart		int	-- start record
	declare @iEnd		int	-- end record
	declare @iPageCount	int	-- total number of pages
	declare @iExternalUser	tinyint -- flag to indicate the user is external

	declare @sSql		nvarchar(4000) 	-- the SQL to execute
	declare @sSelectList	nvarchar(1000)   -- the SQL list of columns to return
	declare	@sFrom		nvarchar(1000)	-- the SQL to list tables and joins
	declare @sOrder		nvarchar(500)	-- the SQL to order
	declare @sWhere		nvarchar(1000) 	-- the SQL to filter

	-- create a temporary table to hold the number of rows that the built
	-- select statement will return.  This has to be done this way in order
	-- to get the result from the dynamically constructed Select.

	create table #TEMPROWCOUNT
	(
		NUMBEROFROWS	int
	)

	-- create the temporary table and populate it
	create table #pagedNames
	(
		ID		int	IDENTITY,
		NAMENO		int	NOT NULL,
		NAMECODE	varchar(20) 	collate database_default,
		FULLNAME	varchar(2048)	collate database_default,
		TELEPHONE	varchar(50)	collate database_default,
		FAX		varchar(50)	collate database_default,
		EMAIL		varchar(100)	collate database_default,
		REMARKS		varchar(254)	collate database_default,
		SEARCHKEY	varchar(20)	collate database_default
	)
	
	set @sSql =	"insert 	into #pagedNames (NAMENO, NAMECODE, FULLNAME, TELEPHONE, FAX, EMAIL, REMARKS, SEARCHKEY)
	select	"

	set @sSelectList= "
		N.NAMENO,
		N.NAMECODE,
		FULLNAME = N.NAME + 
			CASE WHEN (N.TITLE IS NOT NULL or N.FIRSTNAME IS NOT NULL) THEN ', ' ELSE NULL END  +
			CASE WHEN N.TITLE IS NOT NULL THEN N.TITLE + ' ' ELSE NULL END  +
			CASE WHEN N.FIRSTNAME IS NOT NULL THEN N.FIRSTNAME ELSE NULL END,
		PHONE =	CASE WHEN T.ISD IS NOT NULL THEN T.ISD + ' ' ELSE NULL END  +
			CASE WHEN T.AREACODE IS NOT NULL THEN T.AREACODE  + ' ' ELSE NULL END +
			T.TELECOMNUMBER +
			CASE WHEN T.EXTENSION IS NOT NULL THEN ' x' + T.EXTENSION ELSE NULL END,
		FAX =	CASE WHEN F.ISD IS NOT NULL THEN F.ISD + ' ' ELSE NULL END  +
			CASE WHEN F.AREACODE IS NOT NULL THEN F.AREACODE  + ' ' ELSE NULL END +
			F.TELECOMNUMBER +
			CASE WHEN F.EXTENSION IS NOT NULL THEN ' x' + F.EXTENSION ELSE NULL END, 
		EMAIL =	E.TELECOMNUMBER, 
		N.REMARKS,
		N.SEARCHKEY1"
	set @sFrom = char(10)+"	from		NAME N
	left join	TELECOMMUNICATION T on N.MAINPHONE = T.TELECODE	/* main phone */			
	left join	TELECOMMUNICATION F on N.FAX = F.TELECODE	/* main fax */
	left join	TELECOMMUNICATION E on (E.TELECODE=(select min(E1.TELECODE)
							    from NAMETELECOM NT1
							    join TELECOMMUNICATION E1 on (E1.TELECODE=NT1.TELECODE
										      and E1.TELECOMTYPE=1903)
							    where NT1.NAMENO=N.NAMENO))"
	set @sWhere = NULL

	if (@sAnySearch is not NULL)
	begin
		set @sAnySearch=upper(@sAnySearch)
		set @sWhere = char(10)+"	where	" +
						"(upper(N.NAME)      LIKE '" 	+ @sAnySearch + "%' OR
						  upper(N.FIRSTNAME) LIKE '" 	+ @sAnySearch + "%' OR
						  N.SEARCHKEY1       LIKE '" 	+ @sAnySearch + "%' OR
						  N.SEARCHKEY2       LIKE '" 	+ @sAnySearch + "%' OR
						  N.NAMECODE         LIKE '" 	+ @sAnySearch + "%')"
	end
	else begin
		if @sSearchKey is not NULL
		begin
			if @bUseKey1=1 and @bUseKey2=1
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"	where	(N.SEARCHKEY1 like '"+@sSearchKey+"%' OR N.SEARCHKEY2 like '"+@sSearchKey+"%')"
				else
					set @sWhere = @sWhere+char(10)+"	and	(N.SEARCHKEY1 like '"+@sSearchKey+"%' OR N.SEARCHKEY2 like '"+@sSearchKey+"%')"
			end
			else if @bUseKey1=1
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"	where	N.SEARCHKEY1 like '"+@sSearchKey+"%'"
				else
					set @sWhere = @sWhere+char(10)+"	and	N.SEARCHKEY1 like '"+@sSearchKey+"%'"
			end
			else if @bUseKey2=1
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"	where	N.SEARCHKEY2 like '"+@sSearchKey+"%'"
				else
					set @sWhere = @sWhere+char(10)+"	and	N.SEARCHKEY2 like '"+@sSearchKey+"%'"
			end
			
		end

		if @sNameCode is not NULL
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	N.NAMECODE like '"+ @sNameCode +"%'"
			else
				set @sWhere = @sWhere+char(10)+"	and	N.NAMECODE like '"+ @sNameCode +"%'"
		end
		else if @bHasCode=1
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	N.NAMECODE is not NULL"
			else
				set @sWhere = @sWhere+char(10)+"	and	N.NAMECODE is not NULL"
		end

		if @sName is not NULL
		begin
			set @sName=upper(@sName)
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	upper(N.NAME) like '"+ @sName +"%'"
			else
				set @sWhere = @sWhere+char(10)+"	and	upper(N.NAME) like '"+ @sName +"%'"
		end

		if @sFirstName is not NULL
		begin
			set @sFirstName=upper(@sFirstName)
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	upper(N.FIRSTNAME) like '"+ @sFirstName +"%'"
			else
				set @sWhere = @sWhere+char(10)+"	and	upper(N.FIRSTNAME) like '"+ @sFirstName +"%'"
		end
		
		if @sCountry is not NULL
		or @sCity    is not NULL
		begin
			set @sFrom = @sFrom+char(10)+"	     join	ADDRESS A	on (A.ADDRESSCODE=N.POSTALADDRESS)"
			
			if @sCountry is not NULL
			begin
				if @sWhere is NULL
					set @sWhere = char(10)+"	where	A.COUNTRYCODE='"+ @sCountry +"'"
				else
					set @sWhere = @sWhere+char(10)+"	and	A.COUNTRYCODE='"+ @sCountry +"'"
			end
			
			if @sCity is not NULL
			begin
				select @sCity=upper(@sCity)
				if @sWhere is NULL
					set @sWhere = char(10)+"	where	upper(A.CITY) like '"+ @sCity +"%'"
				else
					set @sWhere = @sWhere+char(10)+"	and	upper(A.CITY) like '"+ @sCity +"%'"
			end
		end
	
		if @sLocality is not NULL
		or @sCategory is not NULL
		begin
			set @sFrom = @sFrom+char(10)+"	     join	IPNAME IP	on (IP.NAMENO=N.NAMENO)"
		end

		if @sLocality is not NULL
		begin
			set @sLocality=upper(@sLocality)
			set @sFrom = @sFrom+char(10)+"	     join	AIRPORT AP	on (AP.AIRPORTCODE=IP.AIRPORTCODE)"

			if @sWhere is NULL
				set @sWhere = char(10)+"	where	upper(AP.AIRPORTNAME)='"+ @sLocality +"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	upper(AP.AIRPORTNAME)='"+ @sLocality +"'"
		end

		if @sCategory is not NULL
		begin
			select @sCategory=upper(@sCategory)
			set @sFrom = @sFrom+char(10)+"	     join	TABLECODES TC	on (TC.TABLECODE=IP.CATEGORY)"

			if @sWhere is NULL
				set @sWhere = char(10)+"	where	upper(TC.DESCRIPTION)='"+ @sCategory +"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	upper(TC.DESCRIPTION)='"+ @sCategory +"'"
		end

		if @sFiledIn is not NULL
		begin
			set @sFrom = @sFrom+char(10)+"	     join	FILESIN FI	on (FI.NAMENO=N.NAMENO)"

			if @sWhere is NULL
				set @sWhere = char(10)+"	where	FI.COUNTRYCODE='"+ @sFiledIn +"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	FI.COUNTRYCODE='"+ @sFiledIn +"'"
		end

		if @sTextType is not NULL
		begin
			set @sFrom = @sFrom+char(10)+"	     join	NAMETEXT NT	on (NT.NAMENO=N.NAMENO)"

			if @sWhere is NULL
				set @sWhere = char(10)+"	where	NT.TEXTTYPE='"+ @sTextType +"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	NT.TEXTTYPE='"+ @sTextType +"'"
		end

		if @sTelecomNo is not NULL
		or @sArea      is not NULL
		begin
			set @sFrom = @sFrom+char(10)+"	     join	NAMETELECOM NTC		on (NTC.NAMENO=N.NAMENO)"
					   +char(10)+"	     join	TELECOMMUNICATION TC	on (TC.TELECODE=NTC.TELECODE)"
		end

		if @sTelecomNo is not NULL
		begin
			set @sTelecomNo=upper(replace(@sTelecomNo,' ',''))
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	upper(replace(TC.TELECOMNUMBER,' ','')) like '%"+@sTelecomNo+"%'"
			else
				set @sWhere = @sWhere+char(10)+"	and	upper(replace(TC.TELECOMNUMBER,' ','')) like '%"+@sTelecomNo+"%'"
		end

		if @sArea is not NULL
		begin
			set @sArea=upper(replace(@sArea,' ',''))
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	upper(replace(TC.AREACODE,' ','')) = '"+@sArea+"'"
			else
				set @sWhere = @sWhere+char(10)+"	and	upper(replace(TC.AREACODE,' ','')) = '"+@sArea+"'"
		end

		if @nEntityType is not NULL
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	N.USEDASFLAG="+convert(varchar,@nEntityType)
			else
				set @sWhere = @sWhere+char(10)+"	and	N.USEDASFLAG="+convert(varchar,@nEntityType)
		end

		-- Current Only
		if @nStatus = 1
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	(N.DATECEASED is null or N.DATECEASED>getdate())"
			else
				set @sWhere = @sWhere+char(10)+"	and	(N.DATECEASED is null or N.DATECEASED>getdate())"
		end

		-- Ceased Only
		if @nStatus = 2
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where	N.DATECEASED <= getdate()"
			else 
				set @sWhere = @sWhere+char(10)+"	and	N.DATECEASED <= getdate()"
		end

		if @sGroup is not NULL
		begin
			set @sFrom = @sFrom+char(10)+"	     join	NAMEFAMILY NF	on (NF.FAMILYNO=N.FAMILYNO)"

			if @sWhere is NULL
				set @sWhere = char(10)+"	where	NF.FAMILYTITLE like '"+ @sGroup +"%'"
			else
				set @sWhere = @sWhere+char(10)+"	and	NF.FAMILYTITLE like '"+ @sGroup +"%'"
		end

		if @sUsedAs is not null
		begin
			if @sWhere is NULL
				set @sWhere = char(10)+"	where exists"
					     +char(10)+"	(select * from CASENAME CN"
					     +char(10)+"	 where CN.NAMENO=N.NAMENO"
					     +char(10)+"	 and   CN.NAMETYPE='"+@sUsedAs+"')"
			else
				set @sWhere = @sWhere
					     +char(10)+"	and exists"
					     +char(10)+"	(select * from CASENAME CN"
					     +char(10)+"	 where CN.NAMENO=N.NAMENO"
					     +char(10)+"	 and   CN.NAMETYPE='"+@sUsedAs+"')"
		end
	end

	if (exists (	select * from USERS
			where USERID = user
			AND EXTERNALUSERFLAG > 1))
	begin
		set @iExternalUser = 1
		set @sFrom = @sFrom + char(10)+"	     join	NAMEALIAS NA	on (NA.NAMENO    = N.NAMENO"
				    + char(10)+"					and NA.ALIASTYPE = 'IU'"
				    + char(10)+"					and NA.ALIAS     = user"
				    + char(10)+"					and NA.COUNTRYCODE  is null"
				    + char(10)+"					and NA.PROPERTYTYPE is null)"

	end

	-- Set the ORDER BY clause
	if @sNameCode is not null
		set @sOrder = char(10)+"	Order By  N.NAMECODE"
	else
		set @sOrder = char(10)+"	Order By  N.NAME, N.FIRSTNAME, N.SEARCHKEY1"

	-- check the page number
	IF @iPage < 1
		set @iPage = 1

-- 	Only extract the number of rows required to get the specific page requested
	
	If @iPageSize>0
	begin
		set @sSql = @sSql + 'TOP '+
		    convert(varchar, @iPageSize * @iPage) +
		    @sSelectList + @sFrom + @sWhere + @sOrder
	end
	else begin
		set @sSql = @sSql + @sSelectList + @sFrom + @sWhere + @sOrder
	end

	exec sp_executesql @sSql

	-- get the number of rows the full query would return

	set @sSql  ='insert into #TEMPROWCOUNT SELECT COUNT(N.NAMENO)'+ @sFrom + @sWhere

	exec sp_executesql @sSql
	
	select @iRowCount = NUMBEROFROWS
	from #TEMPROWCOUNT

	-- work out how many pages there are in total

	If @iPageSize>0
	Begin
		SELECT @iPageCount = CEILING(@iRowCount / @iPageSize) + 1
	End
	Else Begin
		If @iRowCount>0
		begin
		 	SELECT @iPageCount=1
		end
		else begin
			SELECT @iPageCount=0
		end
	End

	IF @iPage > @iPageCount
		SELECT @iPage = @iPageCount

	-- calculate the start and end records
	If @iPageSize>0
	Begin
		SELECT @iStart = (@iPage - 1) * @iPageSize
		SELECT @iEnd = @iStart + @iPageSize + 1
	End
	Else Begin
		SELECT @iStart=0
		SELECT @iEnd  =@iRowCount
	End

	-- select only those records that fall within our page and also extract the 
	-- number of Cases associated with the Name

	If @iExternalUser=1
	begin
		SELECT	NAMENO, NAMECODE, FULLNAME, TELEPHONE, FAX, EMAIL, REMARKS, SEARCHKEY,
			CASECOUNT = (select count(distinct CN.CASEID) 
			 from CASENAME CN 
			 join CASES C       on (C.CASEID=CN.CASEID)
			 join SITECONTROL S on (S.CONTROLID='Client Name Types')
			 join SITECONTROL T on (T.CONTROLID='Client Case Types')
			 where CN.NAMENO=#pagedNames.NAMENO 
			 and 0< patindex('%'+CN.NAMETYPE+'%',S.COLCHARACTER)
			 and 0<	patindex('%'+C.CASETYPE+'%',T.COLCHARACTER))
		FROM	#pagedNames
		WHERE	ID > @iStart
		AND	ID < @iEnd
		order by ID
	end
	else begin
		SELECT	NAMENO, NAMECODE, FULLNAME, TELEPHONE, FAX, EMAIL, REMARKS, SEARCHKEY,
			CASECOUNT = (select count(distinct CN.CASEID) 
			 from CASENAME CN 
			 where CN.NAMENO=#pagedNames.NAMENO)
		FROM	#pagedNames
		WHERE	ID > @iStart
		AND	ID < @iEnd
		order by ID
	end

	DROP TABLE #pagedNames

	-- Return the number of records left
	RETURN @iPageCount
end
go 

grant execute on [dbo].[wa_ListNames] to public
go

