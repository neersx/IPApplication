/**********************************************************************************************************/	
/*** RFC74443 Ensure Default Date Of Law exists 														***/      
/**                                                                                                      **/
/**********************************************************************************************************/
If exists (SELECT DISTINCT COUNTRYCODE, PROPERTYTYPE, DATEOFACT FROM VALIDACTDATES VA 
where RETROSPECTIVEACTIO is not null
and not exists (SELECT * from VALIDACTDATES VA1
		WHERE RETROSPECTIVEACTIO is null and VA.COUNTRYCODE = VA1.COUNTRYCODE 
		and VA.PROPERTYTYPE = VA1.PROPERTYTYPE and VA.DATEOFACT = VA1.DATEOFACT))
BEGIN
	PRINT '**** RFC74443 Inserting Valid Dates for default action'
	PRINT ''
	declare @dateInsert table (
		COUNTRYCODE nvarchar(3),
		PROPERTYTYPE nchar(1),
		DATEOFACT datetime,
		SEQUENCENO smallint
	);
	INSERT into @dateInsert (COUNTRYCODE,PROPERTYTYPE,DATEOFACT,SEQUENCENO)
	SELECT COUNTRYCODE, PROPERTYTYPE, DATEOFACT,max(SEQUENCENO) + 1 
	FROM VALIDACTDATES VA 
	where RETROSPECTIVEACTIO is not null
	and not exists (SELECT * from VALIDACTDATES VA1
					WHERE RETROSPECTIVEACTIO is null	and VA.COUNTRYCODE = VA1.COUNTRYCODE 
														and VA.PROPERTYTYPE = VA1.PROPERTYTYPE 
														and VA.DATEOFACT = VA1.DATEOFACT)
	group by  COUNTRYCODE,PROPERTYTYPE,DATEOFACT

	INSERT INTO VALIDACTDATES (COUNTRYCODE,PROPERTYTYPE,DATEOFACT,SEQUENCENO,ACTEVENTNO,RETROEVENTNO)
	SELECT VAI.COUNTRYCODE,VAI.PROPERTYTYPE,VAI.DATEOFACT,VAI.SEQUENCENO, VA.ACTEVENTNO, VA.RETROEVENTNO 
	FROM @dateInsert VAI join VALIDACTDATES VA on (VA.COUNTRYCODE = VAI.COUNTRYCODE 
													and VA.PROPERTYTYPE = VAI.PROPERTYTYPE 
													and VA.DATEOFACT = VAI.DATEOFACT
													and VA.SEQUENCENO = (SELECT min(VA2.SEQUENCENO) from VALIDACTDATES VA2 
																			where VA2.COUNTRYCODE = VA.COUNTRYCODE 
																			and VA2.PROPERTYTYPE = VA.PROPERTYTYPE 
																			and VA2.DATEOFACT = VA.DATEOFACT))
	PRINT '**** RFC74443 Valid Dates for default action successfully inserted'
	PRINT ''

END
ELSE
BEGIN
	PRINT '**** RFC74443 Default Action exists for all Valid Dates'
	PRINT ''
END


