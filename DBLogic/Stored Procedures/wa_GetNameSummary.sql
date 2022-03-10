-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dbo.wa_GetNameSummary
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[wa_GetNameSummary]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.wa_GetNameSummary'
	drop procedure [dbo].[wa_GetNameSummary]
	print '**** Creating procedure dbo.wa_GetNameSummary...'
	print ''
end
go

CREATE PROCEDURE [dbo].[wa_GetNameSummary]
	@pnNameNo	int,
	@pnAddressCode	int	= NULL	-- the specific addess to display
AS
-- PROCEDURE :	wa_GetNameSummary
-- VERSION :	2.2.0
-- DESCRIPTION:	Returns summary Name details for a given NameNo passed as a parameter.
-- CALLED BY :	

-- Date		MODIFICTION HISTORY
-- ====         ===================
-- 01/07/2001	AF		Procedure created
-- 31/07/2001	MF		Only display details if the user has the correct access rights
-- 03/08/2001	MF		Make the the access rights check a stored procedure
-- 12/02/2002	MF	SQA7397	Give external users limited access to names that they are not directly linked to.

begin
	-- disable row counts
	set nocount on
	
	-- declare variables

	declare @ErrorCode	int

	-- Check that external users have access to see the details of the Name.

	Execute @ErrorCode=wa_CheckSecurityForName @pnNameNo
	
	-- If the ErrorCode is -1 then still return limited information about the name.

	if  @ErrorCode in (0, -1)
	Begin
		SELECT
		N.NAMECODE,
		FULLNAME = N.NAME +  
			CASE WHEN (N.TITLE IS NOT NULL or N.FIRSTNAME IS NOT NULL) THEN ', ' ELSE '' END  +
			CASE WHEN N.TITLE IS NOT NULL THEN N.TITLE + ' ' ELSE '' END  +
			CASE WHEN N.FIRSTNAME IS NOT NULL THEN N.FIRSTNAME ELSE '' END,
		N.MAINCONTACT,
		CONTACTNAME = 
			CASE WHEN (@ErrorCode=0)
				THEN 	MC.NAME + 
					CASE WHEN (MC.TITLE IS NOT NULL or MC.FIRSTNAME IS NOT NULL) THEN ', ' ELSE '' END  +
					CASE WHEN MC.TITLE IS NOT NULL THEN MC.TITLE + ' ' ELSE '' END  +
					CASE WHEN MC.FIRSTNAME IS NOT NULL THEN MC.FIRSTNAME ELSE '' END
			END,
		PHONE =	CASE WHEN (@ErrorCode=0 OR N.USEDASFLAG=3)
				THEN	CASE WHEN T.ISD IS NOT NULL THEN T.ISD + ' ' ELSE '' END  +
					CASE WHEN T.AREACODE IS NOT NULL THEN T.AREACODE  + ' ' ELSE '' END +
					T.TELECOMNUMBER +
					CASE WHEN T.EXTENSION IS NOT NULL THEN ' x' + T.EXTENSION ELSE '' END
			END,
		FAX =	CASE WHEN (@ErrorCode=0 OR N.USEDASFLAG=3)
				THEN	CASE WHEN F.ISD IS NOT NULL THEN F.ISD + ' ' ELSE '' END  +
					CASE WHEN F.AREACODE IS NOT NULL THEN F.AREACODE  + ' ' ELSE '' END +
					F.TELECOMNUMBER +
					CASE WHEN F.EXTENSION IS NOT NULL THEN ' x' + F.EXTENSION ELSE '' END
			END,
		EMAIL =	CASE WHEN (@ErrorCode=0 OR N.USEDASFLAG=3) THEN	E.TELECOMNUMBER END,
		REMARKS=CASE WHEN (@ErrorCode=0 OR N.USEDASFLAG=3) THEN	N.REMARKS END,
		N.SEARCHKEY1,
		N.SEARCHKEY2,
		POSTALADDRESS = P.STREET1
		+ 	CASE 
			WHEN P.STREET2 IS NOT NULL THEN CHAR(10)+ P.STREET2
			ELSE ''
			END
		+ 	CASE 
			WHEN CP.POSTCODEFIRST=1 THEN   /* Postcode before City */
		    	CASE
				WHEN P.POSTCODE IS NOT NULL THEN CHAR(10)+P.POSTCODE+
		        	CASE
		        	WHEN P.CITY IS NOT NULL THEN ' ' + P.CITY +
		        		CASE
						WHEN P.STATE IS NOT NULL THEN CHAR(10) + P.STATE
						ELSE ''
						END
		          	ELSE
		          		CASE
						WHEN P.STATE IS NOT NULL THEN ' ' + P.STATE
						ELSE ''
						END
		        	END
		        ELSE
		        	CASE
		            WHEN P.CITY IS NOT NULL THEN CHAR(10)+P.CITY+
		            	CASE
						WHEN P.STATE IS NOT NULL THEN ' '+P.STATE
						ELSE ''
						END
		            ELSE
		              	CASE
						WHEN P.STATE IS NOT NULL THEN CHAR(10)+P.STATE
						ELSE ''
						END
		       END
		    END
		    ELSE  /* Postcode after City */
		    	CASE 
		        WHEN P.CITY IS NOT NULL THEN CHAR(10)+P.CITY+
		        	CASE
		            WHEN P.POSTCODE IS NOT NULL THEN ' '+P.POSTCODE+
		            	CASE
						WHEN P.STATE IS NOT NULL THEN ' '+P.STATE
						ELSE ''
						END
		            ELSE
		              	CASE
						WHEN P.STATE IS NOT NULL THEN ' '+P.STATE
						ELSE ''
						END
		          	END
		        ELSE
		     		CASE
		            WHEN P.POSTCODE IS NOT NULL THEN CHAR(10)+P.POSTCODE+
		              	CASE
						WHEN P.STATE IS NOT NULL THEN ' '+P.STATE
						ELSE ''
						END
		            ELSE
		              	CASE
						WHEN P.STATE IS NOT NULL THEN CHAR(10) + P.STATE
						ELSE ''
						END
		          	END
		      	END
		  	END
		+	CASE
		    WHEN CP.COUNTRYCODE <> (SELECT SC.COLCHARACTER
									FROM SITECONTROL SC
									where SC.CONTROLID = 'HOMECOUNTRY')
									THEN CHAR(10)+ CP.COUNTRY
			ELSE ''
			END,
		STREETADDRESS = S.STREET1
		+ 	CASE 
			WHEN S.STREET2 IS NOT NULL THEN CHAR(10)+ S.STREET2
			ELSE ''
			END
		+ 	CASE 
			WHEN CS.POSTCODEFIRST=1 THEN   /* Postcode before City */
		    	CASE
				WHEN S.POSTCODE IS NOT NULL THEN CHAR(10)+S.POSTCODE+
		        	CASE
		        	WHEN S.CITY IS NOT NULL THEN ' ' + S.CITY +
		        		CASE
						WHEN S.STATE IS NOT NULL THEN CHAR(10) + S.STATE
						ELSE ''
						END
		          	ELSE
		          		CASE
						WHEN S.STATE IS NOT NULL THEN ' ' + S.STATE
						ELSE ''
						END
		        	END
		        ELSE
		        	CASE
		            WHEN S.CITY IS NOT NULL THEN CHAR(10)+S.CITY+
		            	CASE
						WHEN S.STATE IS NOT NULL THEN ' '+S.STATE
						ELSE ''
						END
		            ELSE
		              	CASE
						WHEN S.STATE IS NOT NULL THEN CHAR(10)+S.STATE
						ELSE ''
						END
		       END
		    END
		    ELSE  /* Postcode after City */
		    	CASE 
		        WHEN S.CITY IS NOT NULL THEN CHAR(10)+S.CITY+
		        	CASE
		            WHEN S.POSTCODE IS NOT NULL THEN ' '+S.POSTCODE+
		            	CASE
						WHEN S.STATE IS NOT NULL THEN ' '+S.STATE
						ELSE ''
						END
		            ELSE
		              	CASE
						WHEN S.STATE IS NOT NULL THEN ' '+S.STATE
						ELSE ''
						END
		          	END
		        ELSE
		     		CASE
		            WHEN S.POSTCODE IS NOT NULL THEN CHAR(10)+S.POSTCODE+
		              	CASE
						WHEN S.STATE IS NOT NULL THEN ' '+S.STATE
						ELSE ''
						END
		            ELSE
		              	CASE
						WHEN S.STATE IS NOT NULL THEN CHAR(10) + S.STATE
						ELSE ''
						END
		          	END
		      	END
		  	END
		+	CASE
			    WHEN CS.COUNTRYCODE <> (SELECT SC.COLCHARACTER
									FROM SITECONTROL SC
									where SC.CONTROLID = 'HOMECOUNTRY')
									THEN CHAR(10)+ CS.COUNTRY
			ELSE ''
			END,
		N.DATECEASED,
		NATIONALITY=C.COUNTRYADJECTIVE,
		COMPANYNO=O.REGISTRATIONNO,
		O.INCORPORATED	
		FROM NAME N
		left join NAME MC 		on N.MAINCONTACT = MC.NAMENO	/* main contact */			
		left join TELECOMMUNICATION T	on N.MAINPHONE = T.TELECODE	/* main phone */			
		left join TELECOMMUNICATION F	on N.FAX = F.TELECODE	/* main fax */
		left join TELECOMMUNICATION E	on (E.TELECODE=(select min(E1.TELECODE)
								    from NAMETELECOM NT1
								    join TELECOMMUNICATION E1 on (E1.TELECODE=NT1.TELECODE
											      and E1.TELECOMTYPE=1903)
								    where NT1.NAMENO=N.NAMENO))
		left join ADDRESS P	on P.ADDRESSCODE = N.POSTALADDRESS
		left join ADDRESS S	on S.ADDRESSCODE = isnull(@pnAddressCode, N.STREETADDRESS)
		left join COUNTRY CP	on CP.COUNTRYCODE = P.COUNTRYCODE
		left join COUNTRY CS	on CS.COUNTRYCODE = S.COUNTRYCODE
		left join COUNTRY C	on C.COUNTRYCODE = N.NATIONALITY
		left join ORGANISATION O on O.NAMENO = N.NAMENO
		where	N.NAMENO=@pnNameNo

		select @ErrorCode=@@Error
	End

	return @ErrorCode
end
go 

grant execute on [dbo].[wa_GetNameSummary] to public
go
