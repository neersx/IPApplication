-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_CheckSecurityForCase
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_CheckSecurityForCase]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_CheckSecurityForCase'
	drop procedure [dbo].[wa_CheckSecurityForCase]
	print '**** Creating procedure dbo.wa_CheckSecurityForCase...'
	print ''
end
go

SET QUOTED_IDENTIFIER OFF    
go

CREATE PROCEDURE [dbo].[wa_CheckSecurityForCase]
	@pnCaseId	int,
	@pbExternalUser tinyint = NULL OUTPUT

AS
-- PROCEDURE :	wa_CheckSecurityForCase
-- VERSION :	5
-- DESCRIPTION:	Validates if a user is allowed to see details for the Case
-- CALLED BY :	

-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 03/08/2001	MF		1	Procedure Created
-- 17/08/2001	MF		2	Update and output parameter to indicate if the user is External or not.
-- 26/09/2001	MF		3	Include a check of the row level security
-- 15 Dec 2008	MF	17136	4	Improve performance on SiteControl table by removing use of UPPER in JOIN against CONTROLID
-- 04 Jun 2010	MF	18703	5	NAMEALIAS may be defined by COUNTRYCODE and PROPERTYTYPE which need to be NULL

begin
	-- disable row counts
	set nocount on
	SET CONCAT_NULL_YIELDS_NULL OFF
	
	-- declare variables

	declare @ErrorCode	int

	-- Check that external users have access to see the details of the case.

	if exists (	select * from USERS
			where USERID = user
			AND EXTERNALUSERFLAG > 1)
	begin
		set @pbExternalUser=1
	
		if not exists
		(	select C.*
			from CASES C
			join SITECONTROL S	on (S.CONTROLID='Client Case Types'
						and patindex('%'+C.CASETYPE+'%',S.COLCHARACTER)>0)
			join SITECONTROL T	on (T.CONTROLID='Client Name Types')
			join NAMEALIAS NA  	on (NA.ALIAS=user
						and NA.ALIASTYPE='IU'
						and NA.COUNTRYCODE  is null
						and NA.PROPERTYTYPE is null)
			join CASENAME CN	on (CN.CASEID=C.CASEID
						and CN.NAMENO=NA.NAMENO
						and patindex('%'+CN.NAMETYPE+'%',T.COLCHARACTER)>0)
			where	C.CASEID =@pnCaseId
			and (not exists 
				(SELECT *
	 			 FROM USERROWACCESS U
				 join ROWACCESSDETAIL R	on (R.ACCESSNAME=U.ACCESSNAME)
				 WHERE RECORDTYPE = 'C')
			or Substring(
          			(select MAX (   CASE WHEN OFFICE       IS NULL THEN '0' ELSE '1' END +
						CASE WHEN CASETYPE     IS NULL THEN '0' ELSE '1' END +   
			  			CASE WHEN PROPERTYTYPE IS NULL THEN '0' ELSE '1' END +   
			  			CASE WHEN SECURITYFLAG < 10    THEN '0' END +  /* pack a single digit flag with zero */   
			  			convert(nvarchar,SECURITYFLAG))   
				 from USERROWACCESS UA   
				 left join TABLEATTRIBUTES TA 	on (TA.PARENTTABLE='CASES'        
								and TA.TABLETYPE=44        
								and TA.GENERICKEY=convert(nvarchar, C.CASEID))   
				 left join ROWACCESSDETAIL RAD 	on  (RAD.ACCESSNAME   = UA.ACCESSNAME        
								and (RAD.OFFICE       = TA.TABLECODE   or RAD.OFFICE       is NULL)        
								and (RAD.CASETYPE     = C.CASETYPE     or RAD.CASETYPE     is NULL)        
								and (RAD.PROPERTYTYPE = C.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL)         
								and RAD.RECORDTYPE = 'C')   
				 where UA.USERID= user   ),   4,2) in (  '01','03','05','07','09','11','13','15' ))
		)
		Begin
			set @ErrorCode=-1
		End
		Else Begin
			set @ErrorCode=0
		End
	end
	else begin
		set @pbExternalUser=0
	
		if not exists
		(	select C.*
			from CASES C
			where	C.CASEID =@pnCaseId
			and (not exists 
				(SELECT *
	 			 FROM USERROWACCESS U
				 join ROWACCESSDETAIL R	on (R.ACCESSNAME=U.ACCESSNAME)
				 WHERE RECORDTYPE = 'C')
			or Substring(
          			(select MAX (   CASE WHEN OFFICE       IS NULL THEN '0' ELSE '1' END +
						CASE WHEN CASETYPE     IS NULL THEN '0' ELSE '1' END +   
			  			CASE WHEN PROPERTYTYPE IS NULL THEN '0' ELSE '1' END +   
			  			CASE WHEN SECURITYFLAG < 10    THEN '0' END +  /* pack a single digit flag with zero */   
			  			convert(nvarchar,SECURITYFLAG))   
				 from USERROWACCESS UA   
				 left join TABLEATTRIBUTES TA 	on (TA.PARENTTABLE='CASES'        
								and TA.TABLETYPE=44        
								and TA.GENERICKEY=convert(nvarchar, C.CASEID))   
				 left join ROWACCESSDETAIL RAD 	on  (RAD.ACCESSNAME   = UA.ACCESSNAME        
								and (RAD.OFFICE       = TA.TABLECODE   or RAD.OFFICE       is NULL)        
								and (RAD.CASETYPE     = C.CASETYPE     or RAD.CASETYPE     is NULL)        
								and (RAD.PROPERTYTYPE = C.PROPERTYTYPE or RAD.PROPERTYTYPE is NULL)         
								and RAD.RECORDTYPE = 'C')   
				 where UA.USERID= user   ),   4,2) in (  '01','03','05','07','09','11','13','15' ))
		)
		Begin
			set @ErrorCode=-1
		End
		Else Begin
			set @ErrorCode=0
		End
	end
		
	return @ErrorCode
end
go 

grant execute on [dbo].[wa_CheckSecurityForCase] to public
go
