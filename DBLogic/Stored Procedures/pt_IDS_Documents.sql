-----------------------------------------------------------------------------------------------------------------------------
-- Creation of pt_IDS_Documents  
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'dbo.pt_IDS_Documents') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.pt_IDS_Documents.'
	drop procedure dbo.pt_IDS_Documents
	print '**** Creating procedure dbo.pt_IDS_Documents...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF 
go
SET ANSI_NULLS ON 
go

create procedure dbo.pt_IDS_Documents
	@psIRN				nvarchar(30),
	@psCurrentResultStatus		nvarchar(254),
	@psNewResultStatus		nvarchar(254),
	@psPriorArtType			nvarchar(254)		-- 1 = US Patent Document (granted)
								-- 2 = US Application
								-- 3 = Foreign Patent Document
								-- 4 = Non-patent document
as
-- PROCEDURE :	pt_IDS_Documents
-- VERSION :	2
-- DESCRIPTION:	Extracts prior arts associated with a case
-- CALLED BY :	doc item IDS_DOCUMENTS
-- MODIFICATIONS :
-- Date		Who	No.	Version	Change
-- ------------	-------	-------	-------	----------------------------------------------- 
-- 26/May/2008	RT	11964	1	Procedure created
-- 05 Jul 2013	vql	R13629	2	Remove string length restriction and use nvarchar on datetime conversions using 106 format.


SET CONCAT_NULL_YIELDS_NULL OFF
SET NOCOUNT ON


declare	@prsPriorArt	nvarchar(4000)


-- Create a temporary table to hold the prior art
Create table	#TEMPPRIORART(
		CITENO			smallint	identity(1,1) not NULL,
		CITATION		nvarchar(254)	collate database_default NULL,
		OFFICIALNUMBER		nvarchar(36)	collate database_default NULL,
		COUNTRYCODE		nvarchar(3)	collate database_default NULL,
		KINDCODE		nvarchar(254)	collate database_default NULL,
		PUBLICATIONDATE		datetime	NULL,
		INVENTORNAME		nvarchar(254)	collate database_default NULL,
		REFPAGES		nvarchar(254)	collate database_default NULL
		)

-- Insert rows into #TEMPPRIORART
Insert
into	#TEMPPRIORART(
		CITATION,
		OFFICIALNUMBER,
		COUNTRYCODE,
		KINDCODE,
		PUBLICATIONDATE,
		INVENTORNAME,
		REFPAGES)
Select	DISTINCT
		SR.CITATION,
		SR.OFFICIALNO,
		SR.COUNTRYCODE,
		SR.KINDCODE,		
		case
			when	SR.GRANTEDDATE is not NULL
			then	SR.GRANTEDDATE
			else	SR.PUBLICATIONDATE
		end,
		SR.INVENTORNAME,
		SR.REFPAGES
from	SEARCHRESULTS SR    
join	CASESEARCHRESULT CSR	on CSR.PRIORARTID = SR.PRIORARTID    
join	CASES C	on C.CASEID = CSR.CASEID    
where	C.IRN = @psIRN    
and CSR.STATUS	= convert(int,@psCurrentResultStatus)
and 1 =(case
		when (convert(int,@psPriorArtType)= 1 and (isnull(SR.COUNTRYCODE,'US')='US') and SR.GRANTEDDATE is not null and SR.PATENTRELATED = 1) then 1
		when (convert(int,@psPriorArtType)= 2 and (isnull(SR.COUNTRYCODE,'US')='US') and SR.GRANTEDDATE is null and SR.PATENTRELATED = 1) then 1
		when (convert(int,@psPriorArtType)= 3 and isnull(SR.COUNTRYCODE,'US')<>'US') and SR.PATENTRELATED = 1 then 1
		when (convert(int,@psPriorArtType)= 4 and isnull(SR.PATENTRELATED,0) = 0 ) then 1 
		else 0
	end)
order by 4

-- Concatenate prior art details with tab character, and rows with return character
Select	@prsPriorArt = case
			when	convert(int,@psPriorArtType)= 1
			then	isnull(nullif(@prsPriorArt+char(13),char(13)),'')+char(9)+convert(varchar,CITENO)+char(9)+OFFICIALNUMBER+char(9)+KINDCODE+char(9)+convert(nvarchar,PUBLICATIONDATE,106)+char(9)+INVENTORNAME+char(9)+REFPAGES
			when	convert(int,@psPriorArtType)= 2
			then	isnull(nullif(@prsPriorArt+char(13),char(13)),'')+char(9)+convert(varchar,CITENO)+char(9)+OFFICIALNUMBER+char(9)+KINDCODE+char(9)+convert(nvarchar,PUBLICATIONDATE,106)+char(9)+INVENTORNAME+char(9)+REFPAGES
			when	convert(int,@psPriorArtType)= 3
			then	isnull(nullif(@prsPriorArt+char(13),char(13)),'')+char(9)+convert(varchar,CITENO)+char(9)+OFFICIALNUMBER+char(9)+COUNTRYCODE+char(9)+KINDCODE+char(9)+convert(nvarchar,PUBLICATIONDATE,106)+char(9)+INVENTORNAME+char(9)+REFPAGES+char(9)
			when	convert(int,@psPriorArtType)= 4
			then	isnull(nullif(@prsPriorArt+char(13),char(13)),'')+char(9)+convert(varchar,CITENO)+char(9)+CITATION+char(9)
			else	''
			end
from	#TEMPPRIORART


update CASESEARCHRESULT  
set STATUS = convert(int,@psNewResultStatus)  
from CASESEARCHRESULT CSR  
join CASES C on C.CASEID = CSR.CASEID 
join SEARCHRESULTS SR on SR.PRIORARTID = CSR.PRIORARTID 
where C.IRN = @psIRN  and CSR.STATUS = convert(int,@psCurrentResultStatus)    
and 1 = (case	when (convert(int,@psPriorArtType)= 1 and isnull(SR.COUNTRYCODE,'US') = 'US' and SR.GRANTEDDATE is not null and SR.PATENTRELATED = 1) then 1
		when (convert(int,@psPriorArtType)= 2 and isnull(SR.COUNTRYCODE,'US') = 'US' and SR.GRANTEDDATE is null and SR.PATENTRELATED = 1) then 1
		when (convert(int,@psPriorArtType)= 3 and SR.COUNTRYCODE != 'US' and SR.PATENTRELATED = 1) then 1
		when (convert(int,@psPriorArtType)= 4 and isnull(SR.PATENTRELATED,0) = 0) then 1
		else 0 end)

Select	@prsPriorArt

return 
go
grant exec on dbo.pt_IDS_Documents to public
go
SET ANSI_NULLS OFF
go
