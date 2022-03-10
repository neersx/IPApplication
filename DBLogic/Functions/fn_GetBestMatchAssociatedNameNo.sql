-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetBestMatchAssociatedNameNo
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetBestMatchAssociatedNameNo') and xtype='FN')
begin
        print '**** Drop function dbo.fn_GetBestMatchAssociatedNameNo.'
        drop function dbo.fn_GetBestMatchAssociatedNameNo
end
go

if exists (select * from sysobjects where id = object_id('dbo.fn_GetBestMatchAssociatedNameNo') and xtype='TF')
begin
	print '**** Drop function dbo.fn_GetBestMatchAssociatedNameNo.'
	drop function dbo.fn_GetBestMatchAssociatedNameNo
end
print '**** Creating function dbo.fn_GetBestMatchAssociatedNameNo...'
print ''
go

set QUOTED_IDENTIFIER off
go
set CONCAT_NULL_YIELDS_NULL off
go


Create Function dbo.fn_GetBestMatchAssociatedNameNo
			(
			@pnNameNo	int,
			@pnCaseKey	int,
			@psRelationship	nvarchar(3),
                        @psAction       nvarchar(2),
                        @bDebtorHasSameNameType bit,
                        @pbUseRenewalDebtor bit
			)
Returns @tbAssociatedName TABLE
(
        [NAMENO] [int] NOT NULL,
	[RELATIONSHIP] [nvarchar](3) NOT NULL,
	[RELATEDNAME] [int] NOT NULL,
	[SEQUENCE] [smallint] NOT NULL,
        [CONTACT] [int] NULL,
        [POSTALADDRESS] [int] NULL,
	[STREETADDRESS] [int] NULL
)

-- FUNCTION :	fn_GetBestMatchAssociatedNameNo
-- VERSION :	2
-- DESCRIPTION:	This function will return the best fit ASSOCIATEDNAME NAMENO based on parameters.

-- COPYRIGHT:	Copyright 1993 - 2006 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	 Version Description
-- -----------	-------	-------	 ------- ----------------------------------------------- 
-- 30 Jan 2013	DV	R100777	 1	 Function created.
-- 07 Feb 2018  MS      R72578   2       Added best fit logic for action

as
Begin
	Declare @nRelatedNameNo	int
	-- Best fit search.
	INSERT INTO @tbAssociatedName(NAMENO, RELATIONSHIP, RELATEDNAME, SEQUENCE, CONTACT, POSTALADDRESS, STREETADDRESS) 
	Select NameNo, Relationship, RelatedName, Sequence, Contact, PostalAddress, StreetAddress
        FROM (SELECT top 1 AN.NAMENO as NameNo, AN.RELATIONSHIP as Relationship, AN.RELATEDNAME as RelatedName, 
                AN.SEQUENCE as Sequence, AN.CONTACT as Contact, AN.POSTALADDRESS as PostalAddress, AN.STREETADDRESS as StreetAddress,
		Case when (AN.PROPERTYTYPE IS NULL) then '0' else '1' end +   
                Case when (AN.ACTION is NULL) then '0' else '1' end +  			
		Case when (AN.COUNTRYCODE IS NULL) then '0' else '1' end as BESTFIT
		From ASSOCIATEDNAME AN, CASES C
		join COUNTRY CT on (CT.COUNTRYCODE=C.COUNTRYCODE)
		join VALIDPROPERTY VP on (VP.PROPERTYTYPE=C.PROPERTYTYPE
							and VP.COUNTRYCODE=(select min(VP1.COUNTRYCODE)
												from VALIDPROPERTY VP1
												where VP1.PROPERTYTYPE=C.PROPERTYTYPE
												and VP1.COUNTRYCODE in (C.COUNTRYCODE,'ZZZ')))		
		where AN.RELATIONSHIP = @psRelationship
		and AN.NAMENO = @pnNameNo
		and (AN.PROPERTYTYPE = C.PROPERTYTYPE or AN.PROPERTYTYPE IS NULL) 
		and (AN.COUNTRYCODE = C.COUNTRYCODE OR AN.COUNTRYCODE IS NULL) 	
		and C.CASEID = @pnCaseKey	
                and (AN.ACTION = @psAction or AN.ACTION is null) 
                and (@bDebtorHasSameNameType = 0 or exists (select 1 from NAMETYPECLASSIFICATION NTC where NTC.NAMENO = AN.RELATEDNAME 
								and NTC.NAMETYPE = case when ISNULL(@pbUseRenewalDebtor,0) = 1 then 'Z' else 'D' end and NTC.ALLOW = 1))	
		order by BESTFIT desc) As TEMPTABLE

        Return
End
go

grant REFERENCES, SELECT on dbo.fn_GetBestMatchAssociatedNameNo to public
GO
