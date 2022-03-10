-----------------------------------------------------------------------------------------------------------------------------
-- Creation of cpa_FormatAddresses
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[cpa_FormatAddresses]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.cpa_FormatAddresses.'
	drop procedure dbo.cpa_FormatAddresses
end
print '**** Creating procedure dbo.cpa_FormatAddresses...'
print ''
go

set QUOTED_IDENTIFIER off
go

create proc dbo.cpa_FormatAddresses 
as
-- PROCEDURE :	cpa_FormatAddresses
-- VERSION :	5
-- DESCRIPTION:	Retrieves the required address, formats them and splits them into
--		separate lines to be sent to CPA.
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICTION :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 22 Apr 2002	MF			Procedure Created
-- 30 Sep 2003	MF	9304	2	Strip out carriage returns from the formatted addresses
-- 05 Aug 2004	AB	8035	3	Add collate database_default to temp table definitions
-- 15 May 2006	MF	12559	4	Add a new Address Format Style (7208)
-- 15 Aug 2017	MF	72176	5	Correct corrupt data where 2 carriage returns followed by a line feed exists. 
--					[ char(13)+char(13)+char(10) should be replaced by char(13)+char(10) ]

set nocount on
set concat_null_yields_null off

Create table #TEMPADDRESSES
		(	ADDRESSCODE		int,
			STREET1			nvarchar(254)	collate database_default NULL,
			STREET2			nvarchar(254)	collate database_default NULL,
			CITY			nvarchar(30)	collate database_default NULL,
			STATE			nvarchar(20)	collate database_default NULL,
			STATENAME		nvarchar(30)	collate database_default NULL,
			POSTCODE		nvarchar(10)	collate database_default NULL,
			COUNTRY			nvarchar(50)	collate database_default NULL,
			POSTCODEFIRST		tinyint		NULL,
			STATEABBREVIATED	tinyint		NULL,
			ADDRESSSTYLE		int		NULL,
			FORMATTEDADDRESS	nvarchar(1000)	collate database_default NULL,
			ADDRESSLINE1		nvarchar(50)	collate database_default NULL,
			ADDRESSLINE2		nvarchar(50)	collate database_default NULL,
			ADDRESSLINE3		nvarchar(50)	collate database_default NULL,
			ADDRESSLINE4		nvarchar(50)	collate database_default NULL
		)

declare	@ErrorCode	int
declare	@sSQLString	nvarchar(4000)
declare @nCounter	smallint

Set	@ErrorCode=0

-- Extract details of the addresses to be exported

If @ErrorCode=0
Begin
	Set @sSQLString="
			insert into #TEMPADDRESSES 
			       (ADDRESSCODE, STREET1, STREET2, CITY, STATE, STATENAME,
				POSTCODE, COUNTRY, POSTCODEFIRST, STATEABBREVIATED, ADDRESSSTYLE)
			select	A.ADDRESSCODE, 
				REPLACE(A.STREET1, char(13)+char(13)+char(10), char(13)+char(10)), 
				REPLACE(A.STREET2, char(13)+char(13)+char(10), char(13)+char(10)),
				A.CITY, A.STATE, S.STATENAME,
				A.POSTCODE, substring(C.COUNTRY,1,50), C.POSTCODEFIRST, C.STATEABBREVIATED, C.ADDRESSSTYLE
			from #TEMPCPASEND T
			join ADDRESS A		on (A.ADDRESSCODE=T.OWNADDRESSCODE)
			left join COUNTRY C	on (C.COUNTRYCODE=A.COUNTRYCODE)
			left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
						and S.STATE      =A.STATE)
			union
			select	A.ADDRESSCODE, 
				REPLACE(A.STREET1, char(13)+char(13)+char(10), char(13)+char(10)),
				REPLACE(A.STREET2, char(13)+char(13)+char(10), char(13)+char(10)),
				A.CITY, A.STATE, S.STATENAME,
				A.POSTCODE, substring(C.COUNTRY,1,50), C.POSTCODEFIRST, C.STATEABBREVIATED, C.ADDRESSSTYLE
			from #TEMPCPASEND T
			join ADDRESS A		on (A.ADDRESSCODE=T.CLTADDRESSCODE)
			left join COUNTRY C	on (C.COUNTRYCODE=A.COUNTRYCODE)
			left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
						and S.STATE      =A.STATE)
			union
			select	A.ADDRESSCODE, 
				REPLACE(A.STREET1, char(13)+char(13)+char(10), char(13)+char(10)),
				REPLACE(A.STREET2, char(13)+char(13)+char(10), char(13)+char(10)),
				A.CITY, A.STATE, S.STATENAME,
				A.POSTCODE, substring(C.COUNTRY,1,50), C.POSTCODEFIRST, C.STATEABBREVIATED, C.ADDRESSSTYLE
			from #TEMPCPASEND T
			join ADDRESS A		on (A.ADDRESSCODE=T.DIVADDRESSCODE)
			left join COUNTRY C	on (C.COUNTRYCODE=A.COUNTRYCODE)
			left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
						and S.STATE      =A.STATE)
			union
			select	A.ADDRESSCODE, 
				REPLACE(A.STREET1, char(13)+char(13)+char(10), char(13)+char(10)),
				REPLACE(A.STREET2, char(13)+char(13)+char(10), char(13)+char(10)),
				A.CITY, A.STATE, S.STATENAME,
				A.POSTCODE, substring(C.COUNTRY,1,50), C.POSTCODEFIRST, C.STATEABBREVIATED, C.ADDRESSSTYLE
			from #TEMPCPASEND T
			join ADDRESS A		on (A.ADDRESSCODE=T.INVADDRESSCODE)
			left join COUNTRY C	on (C.COUNTRYCODE=A.COUNTRYCODE)
			left join STATE S	on (S.COUNTRYCODE=A.COUNTRYCODE
						and S.STATE      =A.STATE)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

-- Now format the Address depending upon the required style.

-- The Address styles are hardcode values as follows :
-- 7201        Post Code before City - Full State
-- 7202        Post Code before City - Short State
-- 7203        Post Code before City - No State
-- 7204        City before PostCode - Full State
-- 7205        City before PostCode - Short State
-- 7206        City before PostCode - No State
-- 7207        Country First, Postcode, Full State, City then Street
-- 7208        Country First, State, City, Street, Postcode

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPADDRESSES
	Set FORMATTEDADDRESS=
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

	     WHEN(ADDRESSSTYLE=7208)
		THEN	COUNTRY+ 
			CASE WHEN(STATENAME+CITY+STREET1+STREET2+POSTCODE is not NULL) THEN char(13)+char(10) END+
			STATENAME+
			CASE WHEN(STATENAME is not null AND CITY+STREET1+POSTCODE is not null) THEN char(13)+char(10) END+
			CITY+
			CASE WHEN(CITY is not null AND STREET1+POSTCODE is not null) THEN ' ' END+
			STREET1+
			CASE WHEN(STREET1 is not null AND POSTCODE is not null) THEN ' ' END+
			POSTCODE	

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
			END

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
			POSTCODE
					-- default Address format
		ELSE 	STREET1+
			CASE WHEN(STREET1 is not null AND STREET2 is not null) THEN char(13)+char(10) END+
			STREET2+
			CASE WHEN(STREET1+STREET2 is not null AND POSTCODE+CITY+STATE is not null) THEN char(13)+char(10) END+
			CITY+
			CASE WHEN(STREET1+STREET2+CITY is not null AND STATENAME is not null) THEN char(13)+char(10) END+
			STATENAME+
			CASE WHEN(STREET1+STREET2 is not null AND CITY+STATE is null) THEN char(13)+char(10)
			     WHEN(CITY+STATE      is not null AND POSTCODE is not null) THEN ' '
			END+
			POSTCODE
	END
	From #TEMPADDRESSES"

	Exec @ErrorCode=sp_executesql @sSQLString
END

-- The formatted address must now be split into 4 separate line

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPADDRESSES
	set	ADDRESSLINE1=	CASE WHEN(charindex(char(13), FORMATTEDADDRESS)=0) 
					THEN substring(FORMATTEDADDRESS,1,50) 
					ELSE substring(substring(FORMATTEDADDRESS, 1, charindex(char(13),FORMATTEDADDRESS)-1),1,50)
				END, 

		FORMATTEDADDRESS=CASE WHEN(charindex(char(13), FORMATTEDADDRESS)=0)
					THEN NULL
					ELSE substring(FORMATTEDADDRESS, CHARINDEX(CHAR(13),FORMATTEDADDRESS)+2, datalength(FORMATTEDADDRESS))
				 END
	From #TEMPADDRESSES"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPADDRESSES
	set	ADDRESSLINE2=	CASE WHEN(charindex(char(13), FORMATTEDADDRESS)=0) 
					THEN substring(FORMATTEDADDRESS,1,50) 
					ELSE substring(substring(FORMATTEDADDRESS, 1, charindex(char(13),FORMATTEDADDRESS)-1),1,50)
				END, 

		FORMATTEDADDRESS=CASE WHEN(charindex(char(13), FORMATTEDADDRESS)=0)
					THEN NULL
					ELSE substring(FORMATTEDADDRESS, CHARINDEX(CHAR(13),FORMATTEDADDRESS)+2, datalength(FORMATTEDADDRESS))
				 END
	From #TEMPADDRESSES"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPADDRESSES
	set	ADDRESSLINE3=	CASE WHEN(charindex(char(13), FORMATTEDADDRESS)=0) 
					THEN substring(FORMATTEDADDRESS,1,50) 
					ELSE substring(substring(FORMATTEDADDRESS, 1, charindex(char(13),FORMATTEDADDRESS)-1),1,50)
				END, 

		FORMATTEDADDRESS=CASE WHEN(charindex(char(13), FORMATTEDADDRESS)=0)
					THEN NULL
					ELSE substring(FORMATTEDADDRESS, CHARINDEX(CHAR(13),FORMATTEDADDRESS)+2, datalength(FORMATTEDADDRESS))
				 END
	From #TEMPADDRESSES"

	Exec @ErrorCode=sp_executesql @sSQLString
End

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPADDRESSES
	set	ADDRESSLINE4=	CASE WHEN(charindex(char(13), FORMATTEDADDRESS)=0) 
					THEN substring(FORMATTEDADDRESS,1,50) 
					ELSE substring(substring(FORMATTEDADDRESS, 1, charindex(char(13),FORMATTEDADDRESS)-1),1,50)
				END, 

		FORMATTEDADDRESS=CASE WHEN(charindex(char(13), FORMATTEDADDRESS)=0)
					THEN NULL
					ELSE substring(FORMATTEDADDRESS, CHARINDEX(CHAR(13),FORMATTEDADDRESS)+2, datalength(FORMATTEDADDRESS))
				 END
	From #TEMPADDRESSES"

	Exec @ErrorCode=sp_executesql @sSQLString
End

--  Now update the #TEMPCPASEND with the address details

If @ErrorCode=0
Begin
	Set @sSQLString="
	Update #TEMPCPASEND
	Set	OWNADDRESSLINE1		=CASE WHEN(datalength(A1.ADDRESSLINE1)>0) Then replace(A1.ADDRESSLINE1,char(13)+char(10),' ') End,
		OWNADDRESSLINE2		=CASE WHEN(datalength(A1.ADDRESSLINE2)>0) Then replace(A1.ADDRESSLINE2,char(13)+char(10),' ') End,
		OWNADDRESSLINE3		=CASE WHEN(datalength(A1.ADDRESSLINE3)>0) Then replace(A1.ADDRESSLINE3,char(13)+char(10),' ') End,
		OWNADDRESSLINE4		=CASE WHEN(datalength(A1.ADDRESSLINE4)>0) Then replace(A1.ADDRESSLINE4,char(13)+char(10),' ') End,
		OWNADDRESSCOUNTRY	=CASE WHEN(datalength(A1.COUNTRY)>0)      Then A1.COUNTRY      End,
		OWNADDRESSPOSTCODE	=CASE WHEN(datalength(A1.POSTCODE)>0)     Then A1.POSTCODE     End,
		CLTADDRESSLINE1		=CASE WHEN(datalength(A2.ADDRESSLINE1)>0) Then replace(A2.ADDRESSLINE1,char(13)+char(10),' ') End,
		CLTADDRESSLINE2		=CASE WHEN(datalength(A2.ADDRESSLINE2)>0) Then replace(A2.ADDRESSLINE2,char(13)+char(10),' ') End,
		CLTADDRESSLINE3		=CASE WHEN(datalength(A2.ADDRESSLINE3)>0) Then replace(A2.ADDRESSLINE3,char(13)+char(10),' ') End,
		CLTADDRESSLINE4		=CASE WHEN(datalength(A2.ADDRESSLINE4)>0) Then replace(A2.ADDRESSLINE4,char(13)+char(10),' ') End,
		CLTADDRESSCOUNTRY	=CASE WHEN(datalength(A2.COUNTRY)>0)      Then A2.COUNTRY      End,
		CLTADDRESSPOSTCODE	=CASE WHEN(datalength(A2.POSTCODE)>0)     Then A2.POSTCODE     End,
		DIVADDRESSLINE1		=CASE WHEN(datalength(A3.ADDRESSLINE1)>0) Then replace(A3.ADDRESSLINE1,char(13)+char(10),' ') End,
		DIVADDRESSLINE2		=CASE WHEN(datalength(A3.ADDRESSLINE2)>0) Then replace(A3.ADDRESSLINE2,char(13)+char(10),' ') End,
		DIVADDRESSLINE3		=CASE WHEN(datalength(A3.ADDRESSLINE3)>0) Then replace(A3.ADDRESSLINE3,char(13)+char(10),' ') End,
		DIVADDRESSLINE4		=CASE WHEN(datalength(A3.ADDRESSLINE4)>0) Then replace(A3.ADDRESSLINE4,char(13)+char(10),' ') End,
		DIVADDRESSCOUNTRY	=CASE WHEN(datalength(A3.COUNTRY)>0)      Then A3.COUNTRY      End,
		DIVADDRESSPOSTCODE	=CASE WHEN(datalength(A3.POSTCODE)>0)     Then A3.POSTCODE     End,
		INVADDRESSLINE1		=CASE WHEN(datalength(A4.ADDRESSLINE1)>0) Then replace(A4.ADDRESSLINE1,char(13)+char(10),' ') End,
		INVADDRESSLINE2		=CASE WHEN(datalength(A4.ADDRESSLINE2)>0) Then replace(A4.ADDRESSLINE2,char(13)+char(10),' ') End,
		INVADDRESSLINE3		=CASE WHEN(datalength(A4.ADDRESSLINE3)>0) Then replace(A4.ADDRESSLINE3,char(13)+char(10),' ') End,
		INVADDRESSLINE4		=CASE WHEN(datalength(A4.ADDRESSLINE4)>0) Then replace(A4.ADDRESSLINE4,char(13)+char(10),' ') End,
		INVADDRESSCOUNTRY	=CASE WHEN(datalength(A4.COUNTRY)>0)      Then A4.COUNTRY      End,
		INVADDRESSPOSTCODE	=CASE WHEN(datalength(A4.POSTCODE)>0)     Then A4.POSTCODE     End
	From	#TEMPCPASEND T
	left join #TEMPADDRESSES A1	on (A1.ADDRESSCODE=T.OWNADDRESSCODE)
	left join #TEMPADDRESSES A2	on (A2.ADDRESSCODE=T.CLTADDRESSCODE)
	left join #TEMPADDRESSES A3	on (A3.ADDRESSCODE=T.DIVADDRESSCODE)
	left join #TEMPADDRESSES A4	on (A4.ADDRESSCODE=T.INVADDRESSCODE)"

	Exec @ErrorCode=sp_executesql @sSQLString
End

Return @ErrorCode
go

grant execute on dbo.cpa_FormatAddresses to public
go
