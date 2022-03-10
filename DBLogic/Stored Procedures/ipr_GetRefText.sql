-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipr_GetRefText
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipr_GetRefText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipr_GetRefText.'
	drop procedure dbo.ipr_GetRefText
	print '**** Creating procedure dbo.ipr_GetRefText...'
	print ''
end
go

create procedure dbo.ipr_GetRefText
	@psIRNText nvarchar(254) = NULL,
	@psLanguage nvarchar(254) = NULL,
	@psNameType nvarchar(3) = NULL,
	@pnDebtorNo int = NULL,
	@psOpenItemNo nvarchar(12) = NULL

as
-- PROCEDURE :	ipr_GetRefText
-- VERSION :	3
-- DESCRIPTION:	
-- CALLED BY :	

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 17/03/2004	abell			Syntax cleanup on grant statement
-- 18/09/2007	Dw	15122	3	Added 3 new parameters & changed varchar to nvarchar

DECLARE @nLanguage int,@sCountryAdjective nvarchar(254),@sPropertyName nvarchar(254),
	@sApplication nvarchar(254), @sOfficialNo nvarchar(254),
	@sCountryAdjectiveX nvarchar(254),@sPropertyNameX nvarchar(254),
	@sApplicationX nvarchar(254), @sNoX nvarchar(254)

IF @psIRNText IS NULL
	RETURN
ELSE
	BEGIN
		SELECT  @sCountryAdjective = COUNTRYADJECTIVE,
		@sPropertyName = VP.PROPERTYNAME ,
		@sApplication = CASE WHEN O.NUMBERTYPE<>'R' THEN 'Application ' END,
		@sOfficialNo= O.OFFICIALNUMBER
		FROM  CASES C,COUNTRY CT,VALIDPROPERTY VP, OFFICIALNUMBERS O
		WHERE CT.COUNTRYCODE=C.COUNTRYCODE
		AND   VP.COUNTRYCODE IN (C.COUNTRYCODE, 'ZZZ')
		AND   VP.PROPERTYTYPE=C.PROPERTYTYPE
		AND   O.CASEID=C.CASEID
		AND   O.NUMBERTYPE IN ('0','A','C','P','R')
		AND   C.IRN = @psIRNText
		ORDER BY VP.COUNTRYCODE, O.NUMBERTYPE DESC
	END		

	--After collecting the pieces, translate each piece.
	SELECT @nLanguage = convert(int,@psLanguage)
	EXEC ipo_GetTranslated @nLanguage, @sCountryAdjective, @sCountryAdjectiveX output
	EXEC ipo_GetTranslated @nLanguage, @sPropertyName, @sPropertyNameX output
	EXEC ipo_GetTranslated @nLanguage, @sApplication, @sApplicationX output
	EXEC ipo_GetTranslated @nLanguage, 'No.', @sNoX output

	--Now that each piece has been translated where possible concatenate and return.
	SELECT @sCountryAdjectiveX +' '+ @sPropertyNameX 
		+ ' ' + @sApplicationX + ' '+ @sNoX + ' ' + @sOfficialNo

RETURN
go

grant execute on dbo.ipr_GetRefText to public
go
