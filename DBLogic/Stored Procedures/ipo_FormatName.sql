-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipo_FormatName
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipo_FormatName]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ipo_FormatName.'
	drop procedure dbo.ipo_FormatName
end
print '**** Creating procedure dbo.ipo_FormatName...'
print ''
go

create procedure dbo.ipo_FormatName
	@pnNameNo int,
	@prsFormattedName varchar(255) = NULL OUTPUT

as

-- PROCEDURE :	ipo_FormatName
-- VERSION :	3
-- DESCRIPTION:	A procedure to return an output string containing the supplied NameNo formatted as either an 
-- 		individual or an organisation.
-- CALLED BY :	ipo_MailingLabel, ipr_ReturnNameAddress
-- COPYRIGHT:	Copyright 1993 - 2004 CPA Software Solutions (Australia) Pty Limited
-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	-------	-------	----------------------------------------------- 
-- 28/06/01	AvdA	6730 	1	NameAddress formatting
-- 14/06/06	AB	12566	2	Change *= syntax to left outer join for SQL 2005 compatibility.
-- 03/11/06	AT	13759	3	Move NAMENO where outside of join syntax.

IF @pnNameNo IS NULL
	RETURN
ELSE
	BEGIN
	select @prsFormattedName = CASE 
	WHEN (	CASE WHEN N.NAMESTYLE  IS NOT NULL
		THEN 	N.NAMESTYLE 
		ELSE	CASE WHEN  N.NATIONALITY IS NOT NULL
			THEN  NN.NAMESTYLE
			ELSE NMS.TABLECODE
			END
		END ) = 7101 
	THEN 	 N.TITLE +
			CASE WHEN  N.TITLE IS NOT NULL 
			THEN SPACE(1) 
			END  +N.FIRSTNAME +
			CASE WHEN N.FIRSTNAME IS NOT NULL 
			THEN SPACE(1) 
			END  +N.NAME 
	WHEN (	CASE WHEN N.NAMESTYLE  IS NOT NULL
		THEN 	N.NAMESTYLE 
		ELSE	CASE WHEN  N.NATIONALITY IS NOT NULL
			THEN  NN.NAMESTYLE
			ELSE NMS.TABLECODE
			END
		END ) = 7102 
	THEN		N.NAME + 
			CASE WHEN N.FIRSTNAME IS NOT NULL 
			THEN SPACE(1) 
			END  +N.FIRSTNAME  +
			CASE WHEN N.TITLE IS NOT NULL 
			THEN SPACE(1)  +N.TITLE
			END
	END 
	From	NAME N
	LEFT OUTER JOIN COUNTRY NN on N.NATIONALITY = NN.COUNTRYCODE
	LEFT OUTER JOIN TABLECODES NMS on NMS.TABLETYPE = 71 AND NMS.USERCODE = 'Name Last'
	WHERE N.NAMENO = @pnNameNo
	END
go

grant execute on ipo_FormatName to public
go
