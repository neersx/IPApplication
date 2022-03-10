use cpalive
go

if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[cpass_ProjectStatusReport]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dbo].[cpass_ProjectStatusReport]
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO



CREATE     PROCEDURE dbo.cpass_ProjectStatusReport
(
	@psCaseType						nchar(1)	= null
	,@psCaseFamily					nvarchar(20)	= null
	,@pnProjectLeader				int		= null
	,@pnIncludeClosedProjects		int		= 0
	,@pnIncludeProjectsNotStarted	int		= 0
	,@psClientSatisfaction			nvarchar(80)	= null
)

AS
-- PROCEDURE :	cpass_ProjectStatusReport
-- DESCRIPTION:	Gets the report set for the Project Status Report
-- NOTES:	
-- VERSION:	1
-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 10 Jun 2006	JD		1	Procedure created


Set nocount on
Set concat_null_yields_null off

Declare	@ErrorCode	int
Declare	@sCompanyName	nvarchar(254)  
Declare	@nRowCount	int

Declare	@ReportSet	table
(
	FAMILY		nvarchar(20) collate database_default, 
	FAMILYTITLE	nvarchar(254) collate database_default,
	TITLE		nvarchar(254) collate database_default,
	CASETYPE	nchar(1) collate database_default,
	CASETYPEDESC	nvarchar(50) collate database_default,
	COUNTRY		nvarchar(60) collate database_default,
	[PROJECT LEADER]
			nvarchar(254) collate database_default,
	[EMAIL]		nvarchar(50) collate database_default,
	[CLIENT NAME]
			nvarchar(254) collate database_default,
	[PROJECT START DATE]	
			datetime,
	[CURRENT EXPECTED LIVE DATE]
			datetime,  
	[ORIGINAL EXPECTED LIVE DATE]
			datetime,  
	[ORIGINAL EXPECTED DURATION]
			int,   
	[CURRENT EXPECTED DURATION]
			int,
	[LENGTH TO DATE]
			int,
	[CLIENT SATISFACTION]
			nvarchar(80) collate database_default
)

Set @ErrorCode=0

SELECT	@sCompanyName = CASE WHEN NL.FIRSTNAME IS NOT NULL THEN NL.FIRSTNAME + ' ' END
	+ NL.NAME
FROM 	[SITECONTROL] SC
join	NAME NL on ( NL.NAMENO = SC.COLINTEGER and CONTROLID = 'HOMENAMENO' )

If @ErrorCode=0
Begin
	insert into	@ReportSet

	SELECT 	DISTINCT 
		C.FAMILY,
		CASEFAMILY.FAMILYTITLE,
		C.TITLE,
		C.CASETYPE,
		CASETYPE.CASETYPEDESC,
		COUNTRY.COUNTRY,
		-- Project Leader
		substring(  CASE WHEN NL.FIRSTNAME IS NOT NULL THEN NL.FIRSTNAME + ' ' END
		+ NL.NAME,0,254 ) as [PROJECT LEADER],
		TL.TELECOMNUMBER as [EMAIL],
		-- Instructor reference
		CNCLIENT.REFERENCENO  as [CLIENT_NAME],
		-- Start Date
		ESTARTDT.EVENTDATE,
		-- Current Expected Live Date
		ELIVEDT.EVENTDATE,
		-- Original Expected Live Date
		EORIGLIVEDT.EVENTDATE,
		-- Original Expected Duration
		datediff( Day, ESTARTDT.EVENTDATE, EORIGLIVEDT.EVENTDATE ) as [ORIGINAL EXPECTED DURATION],
		-- Current Expected Duration
		datediff( Day, ESTARTDT.EVENTDATE, ELIVEDT.EVENTDATE ) as [CURRENT EXPECTED DURATION],
		-- Length to date
		datediff( Day, ESTARTDT.EVENTDATE, GetDate() ) as [LENGTH TO DATE],
		-- Client Satisfaction
		T.DESCRIPTION as [CLIENT SATISFACTION]
	FROM  	CASES C
	JOIN	CASEFAMILY CASEFAMILY on ( CASEFAMILY.FAMILY = C.FAMILY )
	JOIN	CASETYPE CASETYPE on ( CASETYPE.CASETYPE = C.CASETYPE )
	join	COUNTRY COUNTRY on ( COUNTRY.COUNTRYCODE = C.COUNTRYCODE )
	-- Project Leader
	left JOIN CASENAME CNL on ( CNL.CASEID = C.CASEID and CNL.NAMETYPE = 'EMP'  )
	left JOIN NAME NL on ( NL.NAMENO = CNL.NAMENO )
	left JOIN TELECOMMUNICATION TL on ( TL.TELECODE = NL.MAINEMAIL )
	-- Instructor reference
	left join	CASENAME CNCLIENT on ( CNCLIENT.CASEID=C.CASEID 
					and	CNCLIENT.NAMETYPE  = 'I' 
					AND	CNCLIENT.SEQUENCE = ( 	SELECT 	MIN(CN2.SEQUENCE) 
									FROM 	CASENAME CN2 
									WHERE 	CN2.NAMETYPE  = 'I' 
									AND	CN2.CASEID=C.CASEID )
						)
	left join	NAME NCLIENT on ( NCLIENT.NAMENO = CNCLIENT.NAMENO )
	-- Start Date
	left JOIN	CASEEVENT ESTARTDT ON ( ESTARTDT.CASEID = C.CASEID 
					and	ESTARTDT.EVENTNO = -4 
					and 	ESTARTDT.CYCLE = ( 
							SELECT 	MAX(CYCLE)
							FROM  	CASEEVENT 
							WHERE 	CASEID = C.CASEID
							AND	EVENTNO = ESTARTDT.EVENTNO )
					)
	-- Current Expected live date
	left JOIN	CASEEVENT ELIVEDT ON ( ELIVEDT.CASEID = C.CASEID 
					and	ELIVEDT.EVENTNO = -8 
					and 	ELIVEDT.CYCLE = ( 
							SELECT 	MAX(CYCLE)
							FROM  	CASEEVENT 
							WHERE 	CASEID = C.CASEID
							AND	EVENTNO = ELIVEDT.EVENTNO )
					)
	-- Original Expected live date
	left JOIN	CASEEVENT EORIGLIVEDT ON ( EORIGLIVEDT.CASEID = C.CASEID 
					and	EORIGLIVEDT.EVENTNO = -6
					and 	EORIGLIVEDT.CYCLE = ( 
							SELECT 	MAX(CYCLE)
							FROM  	CASEEVENT 
							WHERE 	CASEID = C.CASEID
							AND	EVENTNO = EORIGLIVEDT.EVENTNO )
					)
	-- Client Satisfaction
	left join	
		CASECHECKLIST CC on ( CC.CASEID = C.CASEID
				AND 	CC.QUESTIONNO = 611 )
	left join	
		TABLECODES T on ( T.TABLECODE = CC.TABLECODE )

	WHERE 	C.PROPERTYTYPE = 'B'
	AND	( @psCaseType is NULL OR C.CASETYPE = @psCaseType )
	AND	( @psCaseFamily is NULL OR C.FAMILY = @psCaseFamily ) 
	AND	( @psClientSatisfaction is NULL OR T.DESCRIPTION = @psClientSatisfaction ) 
	AND	( @pnProjectLeader is NULL OR (
		( @pnProjectLeader is NOT NULL AND EXISTS 	(
							SELECT 	*
							FROM  	CASENAME CN 
							WHERE 	CN.CASEID = C.CASEID
							AND	CN.NAMETYPE = 'EMP'
							AND	CN.NAMENO = @pnProjectLeader
								)
 						)
		)
		)
	AND	( @pnIncludeClosedProjects = 1 OR
		( @pnIncludeClosedProjects = 0
		AND		NOT EXISTS	(
							SELECT 	EVENTDATE
							FROM  	CASEEVENT E
							WHERE 	E.CASEID = C.CASEID
							AND	E.EVENTNO = -12 )
		)
		)
	AND	( @pnIncludeProjectsNotStarted = 1 OR
		( @pnIncludeProjectsNotStarted = 0
		AND		EXISTS	(
							SELECT 	EVENTDATE
							FROM  	CASEEVENT E
							WHERE 	E.CASEID = C.CASEID
							AND	E.EVENTNO = -4 )
		AND		getdate() >=	(
					SELECT 	EVENTDATE
					FROM  	CASEEVENT E
					WHERE 	E.CASEID = C.CASEID
					AND		E.EVENTNO = -4					
					and 	E.CYCLE = ( 
							SELECT 	MAX(CYCLE)
							FROM  	CASEEVENT 
							WHERE 	CASEID = E.CASEID
							AND		EVENTNO = E.EVENTNO ) )
		)
		)
	AND	C.FAMILY is not null

	set	@ErrorCode = @@Error
End

select 	@nRowCount = count(*) 
from 	@ReportSet

select	@nRowCount as [FAMILY COUNT], -- Row count
	FAMILY,
	FAMILYTITLE,
	TITLE,
	CASETYPE,
	CASETYPEDESC,
	COUNTRY,
	[PROJECT LEADER],
	[EMAIL],
	[CLIENT NAME],
	[PROJECT START DATE],
	[CURRENT EXPECTED LIVE DATE],
	[ORIGINAL EXPECTED LIVE DATE],
	[CURRENT EXPECTED DURATION],
	[ORIGINAL EXPECTED DURATION],
	[LENGTH TO DATE],
	[CLIENT SATISFACTION],
	@sCompanyName as [COMPANY NAME]
from 	@ReportSet
order by
	[PROJECT LEADER],
	[CLIENT NAME]

Return @ErrorCode

GO

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO

grant execute on [dbo].[cpass_ProjectStatusReport] to public
go