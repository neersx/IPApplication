-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesREMINDERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesREMINDERS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesREMINDERS.'
	drop procedure dbo.ip_RulesREMINDERS
	print '**** Creating procedure dbo.ip_RulesREMINDERS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesREMINDERS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesREMINDERS
-- VERSION :	6
-- DESCRIPTION:	The comparison/display and merging of imported data for the REMINDERS table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 21 Jul 2004	MF		1	Procedure created
-- 28 Jul 2004	MF	10224	2	Need to remove REMINDERS rows that do not exist in the 
--					imported table but do exists in the imported CRITERIA table.
-- 23 Aug 2006	MF	13299	3	Imported data is to inherit down to user created rules that has
--					been inherited.
-- 21 Jan 2011	MF	19321	4	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 12 Jul 2013	MF	R13596	5	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	6	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
--					client/server.
--
-- @pnFunction - possible values and expected behaviour:
-- 	= 1	Refresh the import table if necessary (with updated keys for example) 
-- 		and return the comparison with the system table
--	= 2	Update the system tables with the imported data 
--	= 3	Supply the statement to collect the system keys if
-- 		there is a primary key associated with this tab which may be mapped
-- 		(Return null to indicate mapping not allowed.)
-- 	= 4	Supply the statement to list the imported keys and any existing mapping.
-- 		(Should not be called if mapping not allowed.)
-- 	= 5 	Add/update the existing mapping based on the supplied XML in the form
--		 <DataMap><DataMapChange><SourceValue/><StoredMapValue/><NewMapValue/></DataMapChange></DataMap>

set nocount on
Set CONCAT_NULL_YIELDS_NULL OFF


-- Prerequisite that the IMPORTED_REMINDERS table has been loaded

Declare @sSQLString		nvarchar(4000)
Declare @sSQLString1		varchar(8000)
Declare @sSQLString2		varchar(8000)
Declare @sSQLString3		varchar(8000)
Declare @sSQLString4		varchar(8000)
Declare @sSQLString5		varchar(8000)
Declare @sSQLString6		varchar(8000)

Declare	@ErrorCode			int
Declare @sUserName			nvarchar(40)
Declare	@hDocument	 		int 			-- handle to the XML parameter
Declare @bOriginalKeyColumnExists	bit

Set @ErrorCode=0
Set @bOriginalKeyColumnExists = 0
Set @sUserName	= @psUserName
--------------------------------------
-- Create and load CRITERIAALLOWED if
-- it does not exist already
--------------------------------------
If @ErrorCode=0
and not exists(	SELECT 1 
		from sysobjects 
		where id = object_id(@sUserName+'.CRITERIAALLOWED'))
Begin
	---------------------------------------------------
	-- Create an interim table to hold the criteria
	-- that are allowed to be imported for the purpose
	-- of creating or update laws on the receiving
	-- database
	---------------------------------------------------
	Set @sSQLString="CREATE TABLE "+@sUserName+".CRITERIAALLOWED (CRITERIANO int not null PRIMARY KEY)"
	exec @ErrorCode=sp_executesql @sSQLString
	
	If @ErrorCode=0
	Begin
		-----------------------------------------
		-- Load the CRITERIA that are candidates
		-- to be imported into a temporary table.
		-- This allows rules defined by a firm to
		-- block or allow criteria.
		-----------------------------------------
		set @sSQLString="
		insert into "+@sUserName+".CRITERIAALLOWED (CRITERIANO)
		select distinct C.CRITERIANO
		from "+@sUserName+".Imported_CRITERIA C
		left join CRITERIA C1 on (C1.CRITERIANO = dbo.fn_GetCriteriaNoForLawImportBlocking( C.CASETYPE,	
												    C.ACTION,
												    C.PROPERTYTYPE,
												    C.COUNTRYCODE,
												    C.CASECATEGORY,
												    C.SUBTYPE,
												    C.BASIS,
												    C.DATEOFACT) )
		where isnull(C1.RULEINUSE,0)=0"
		
		exec @ErrorCode=sp_executesql @sSQLString
	End
end

-- @pnFunction = 1 & 2 Apply any data mapping before Updating or Displaying data comparison

If @ErrorCode=0 
and @pnSourceNo is not null
and @pnFunction in (1,2)
Begin
	-- Apply the Mapping if it exists

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_REMINDERS
		SET EVENTNO = M.MAPVALUE
		FROM "+@sUserName+".Imported_REMINDERS C
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='EVENTS'
				and M.MAPCOLUMN  ='EVENTNO'
				and M.SOURCEVALUE=C.EVENTNO)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_REMINDERS
			SET LETTERNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_REMINDERS C
			join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='LETTER'
					and M.MAPCOLUMN  ='LETTERNO'
					and M.SOURCEVALUE=C.LETTERNO)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end
End


-- Function 1 - Data Comparison
If @ErrorCode=0 
and @pnFunction=1
Begin
	-- Return result set of imported data with current live data
	If  @ErrorCode=0
	Begin
		Set @sSQLString1="
		select	3			as 'Comparison',
			NULL			as Match,
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'
						as 'Imported Criteria',
			EC.EVENTDESCRIPTION	as 'Imported Event',
			CASE (I.PERIODTYPE)
				WHEN('D') THEN 'Days'
				WHEN('W') THEN 'Weeks'	
				WHEN('M') THEN 'Months'	
				WHEN('Y') THEN 'Years'	
			END			as 'Imported Period Type',
			I.LEADTIME		as 'Imported Lead Time',
			I.FREQUENCY		as 'Imported Frequency',
			I.STOPTIME		as 'Imported Stop Time',
			CASE (I.UPDATEEVENT)
				WHEN(1) THEN 'Update Event when document produced'
				WHEN(2) THEN 'Produce document when Event updated'
			END			as 'Imported Update Event',
			L.LETTERNAME		as 'Imported Letter',
			dbo.fn_DisplayBoolean(I.CHECKOVERRIDE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Check Override',
			I.MAXLETTERS		as 'Imported Max Letters',
			R.RATEDESC		as 'Imported Letter Fee',
			CASE WHEN(I.PAYFEECODE in (1,3)) THEN 'On' END 
						as 'Imported Raise Charge',
			CASE WHEN(I.PAYFEECODE in (2,3)) THEN 'On' END 
						as 'Imported Add to Fee List',
			dbo.fn_DisplayBoolean(I.ESTIMATEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Use/Create Estimate',
			dbo.fn_DisplayBoolean(I.EMPLOYEEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Employee Reminder',
			dbo.fn_DisplayBoolean(I.SIGNATORYFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Signatory Reminder',
			dbo.fn_DisplayBoolean(I.CRITICALFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Critical Reminder',
			NT.DESCRIPTION		as 'Imported Name Type Reminder',
			dbo.fn_DisplayBoolean(I.SENDELECTRONICALLY,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Send as Email',
			dbo.fn_DisplayBoolean(I.USEMESSAGE1,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Message 1 Before Due Date',
			I.EMAILSUBJECT		as 'Imported Email Subject',
			convert(nvarchar(254),I.MESSAGE1)
						as 'Imported Message 1',
			convert(nvarchar(254),I.MESSAGE2)
						as 'Imported Message 2',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'
						as 'Criteria',
			EC.EVENTDESCRIPTION	as 'Event',
			CASE (C.PERIODTYPE)
				WHEN('D') THEN 'Days'
				WHEN('W') THEN 'Weeks'	
				WHEN('M') THEN 'Months'	
				WHEN('Y') THEN 'Years'	
			END			as 'Period Type',
			C.LEADTIME		as 'Lead Time',
			C.FREQUENCY		as 'Frequency',
			C.STOPTIME		as 'Stop Time',
			CASE (C.UPDATEEVENT)
				WHEN(1) THEN 'Update Event when document produced'
				WHEN(2) THEN 'Produce document when Event updated'
			END			as 'Update Event',
			L.LETTERNAME		as 'Imported Letter',
			dbo.fn_DisplayBoolean(C.CHECKOVERRIDE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Imported Check Override',
			C.MAXLETTERS		as 'Max Letters',
			R.RATEDESC		as 'Letter Fee',
			CASE WHEN(C.PAYFEECODE in (1,3)) THEN 'On' END 
						as 'Raise Charge',
			CASE WHEN(C.PAYFEECODE in (2,3)) THEN 'On' END 
						as 'Add to Fee List',
			dbo.fn_DisplayBoolean(C.ESTIMATEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Use/Create Estimate',
			dbo.fn_DisplayBoolean(C.EMPLOYEEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Employee Reminder',
			dbo.fn_DisplayBoolean(C.SIGNATORYFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Signatory Reminder',
			dbo.fn_DisplayBoolean(C.CRITICALFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Critical Reminder',
			NT.DESCRIPTION		as 'Name Type Reminder',
			dbo.fn_DisplayBoolean(C.SENDELECTRONICALLY,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Send as Email',
			dbo.fn_DisplayBoolean(C.USEMESSAGE1,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1)
						as 'Message 1 Before Due Date',
			I.EMAILSUBJECT		as 'Email Subject',
			convert(nvarchar(254),C.MESSAGE1)
						as 'Message 1',
			convert(nvarchar(254),C.MESSAGE2)
						as 'Message 2'
		from "+@sUserName+".Imported_REMINDERS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
					and EC.EVENTNO=I.EVENTNO)
		left join "+@sUserName+".Imported_LETTER L	on (L.LETTERNO=I.LETTERNO)
		left join RATES R	on (R.RATENO=I.LETTERFEE)
		left join NAMETYPE NT	on (NT.NAMETYPE=I.NAMETYPE)"
		Set @sSQLString2="
		join REMINDERS C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and C.REMINDERNO=I.REMINDERNO)
		where		(I.PERIODTYPE=C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is null))
		and		(I.LEADTIME=C.LEADTIME OR (I.LEADTIME is null and C.LEADTIME is null))
		and		(I.FREQUENCY=C.FREQUENCY OR (I.FREQUENCY is null and C.FREQUENCY is null))
		and		(I.STOPTIME=C.STOPTIME OR (I.STOPTIME is null and C.STOPTIME is null))
		and		(I.UPDATEEVENT=C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is null))
		and		(I.LETTERNO=C.LETTERNO OR (I.LETTERNO is null and C.LETTERNO is null))
		and		(I.CHECKOVERRIDE=C.CHECKOVERRIDE OR (I.CHECKOVERRIDE is null and C.CHECKOVERRIDE is null))
		and		(I.MAXLETTERS=C.MAXLETTERS OR (I.MAXLETTERS is null and C.MAXLETTERS is null))
		and		(I.LETTERFEE=C.LETTERFEE OR (I.LETTERFEE is null and C.LETTERFEE is null))
		and		(I.PAYFEECODE=C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is null))
		and		(I.EMPLOYEEFLAG=C.EMPLOYEEFLAG OR (I.EMPLOYEEFLAG is null and C.EMPLOYEEFLAG is null))
		and		(I.SIGNATORYFLAG=C.SIGNATORYFLAG OR (I.SIGNATORYFLAG is null and C.SIGNATORYFLAG is null))
		and		(I.INSTRUCTORFLAG=C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is null))
		and		(I.CRITICALFLAG=C.CRITICALFLAG OR (I.CRITICALFLAG is null and C.CRITICALFLAG is null))
		and		(I.REMINDEMPLOYEE=C.REMINDEMPLOYEE OR (I.REMINDEMPLOYEE is null and C.REMINDEMPLOYEE is null))
		and		(I.USEMESSAGE1=C.USEMESSAGE1 OR (I.USEMESSAGE1 is null and C.USEMESSAGE1 is null))
		and		(I.EMAILSUBJECT=C.EMAILSUBJECT OR (I.EMAILSUBJECT is null and C.EMAILSUBJECT is null))
		and		(I.SENDELECTRONICALLY=C.SENDELECTRONICALLY OR (I.SENDELECTRONICALLY is null and C.SENDELECTRONICALLY is null))
		and		(I.NAMETYPE=C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is null))
		and		(I.ESTIMATEFLAG=C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			CR1.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC1.EVENTDESCRIPTION,
			CASE (I.PERIODTYPE)
				WHEN('D') THEN 'Days'
				WHEN('W') THEN 'Weeks'	
				WHEN('M') THEN 'Months'	
				WHEN('Y') THEN 'Years'	
			END,
			I.LEADTIME,
			I.FREQUENCY,
			I.STOPTIME,
			CASE (I.UPDATEEVENT)
				WHEN(1) THEN 'Update Event when document produced'
				WHEN(2) THEN 'Produce document when Event updated'
			END,
			L.LETTERNAME,
			dbo.fn_DisplayBoolean(I.CHECKOVERRIDE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			I.MAXLETTERS,
			R.RATEDESC,
			CASE WHEN(I.PAYFEECODE in (1,3)) THEN 'On' END,
			CASE WHEN(I.PAYFEECODE in (2,3)) THEN 'On' END,
			dbo.fn_DisplayBoolean(I.ESTIMATEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.EMPLOYEEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.SIGNATORYFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.CRITICALFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			NT.DESCRIPTION,
			dbo.fn_DisplayBoolean(I.SENDELECTRONICALLY,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.USEMESSAGE1,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			I.EMAILSUBJECT,
			convert(nvarchar(254),I.MESSAGE1),
			convert(nvarchar(254),I.MESSAGE2),
			CR1.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC1.EVENTDESCRIPTION,
			CASE (C.PERIODTYPE)
				WHEN('D') THEN 'Days'
				WHEN('W') THEN 'Weeks'	
				WHEN('M') THEN 'Months'	
				WHEN('Y') THEN 'Years'	
			END,
			C.LEADTIME,
			C.FREQUENCY,
			C.STOPTIME,
			CASE (C.UPDATEEVENT)
				WHEN(1) THEN 'Update Event when document produced'
				WHEN(2) THEN 'Produce document when Event updated'
			END,
			L1.LETTERNAME,
			dbo.fn_DisplayBoolean(C.CHECKOVERRIDE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			C.MAXLETTERS,
			R1.RATEDESC,
			CASE WHEN(C.PAYFEECODE in (1,3)) THEN 'On' END,
			CASE WHEN(C.PAYFEECODE in (2,3)) THEN 'On' END,
			dbo.fn_DisplayBoolean(C.ESTIMATEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(C.EMPLOYEEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(C.SIGNATORYFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(C.CRITICALFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			NT1.DESCRIPTION,
			dbo.fn_DisplayBoolean(C.SENDELECTRONICALLY,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(C.USEMESSAGE1,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			I.EMAILSUBJECT,
			convert(nvarchar(254),C.MESSAGE1),
			convert(nvarchar(254),C.MESSAGE2)
		from "+@sUserName+".Imported_REMINDERS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
						and EC.EVENTNO=I.EVENTNO)
		left join "+@sUserName+".Imported_LETTER L	on (L.LETTERNO=I.LETTERNO)
		left join RATES R	on (R.RATENO=I.LETTERFEE)
		left join NAMETYPE NT	on (NT.NAMETYPE=I.NAMETYPE)"
		Set @sSQLString4="
		join REMINDERS C	on( C.CRITERIANO=I.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and C.REMINDERNO=I.REMINDERNO)
		join CRITERIA CR1	on (CR1.CRITERIANO=C.CRITERIANO)
		join EVENTCONTROL EC1	on (EC1.CRITERIANO=C.CRITERIANO
					and EC1.EVENTNO=C.EVENTNO)
		left join LETTER L1	on (L1.LETTERNO=C.LETTERNO)
		left join RATES R1	on (R1.RATENO=C.LETTERFEE)
		left join NAMETYPE NT1	on (NT1.NAMETYPE=C.NAMETYPE)
		where 		I.PERIODTYPE<>C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) OR (I.PERIODTYPE is not null and C.PERIODTYPE is null)
		OR		I.LEADTIME<>C.LEADTIME OR (I.LEADTIME is null and C.LEADTIME is not null) OR (I.LEADTIME is not null and C.LEADTIME is null)
		OR		I.FREQUENCY<>C.FREQUENCY OR (I.FREQUENCY is null and C.FREQUENCY is not null) OR (I.FREQUENCY is not null and C.FREQUENCY is null)
		OR		I.STOPTIME<>C.STOPTIME OR (I.STOPTIME is null and C.STOPTIME is not null) OR (I.STOPTIME is not null and C.STOPTIME is null)
		OR		I.UPDATEEVENT<>C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is not null) OR (I.UPDATEEVENT is not null and C.UPDATEEVENT is null)
		OR		I.LETTERNO<>C.LETTERNO OR (I.LETTERNO is null and C.LETTERNO is not null) OR (I.LETTERNO is not null and C.LETTERNO is null)
		OR		I.CHECKOVERRIDE<>C.CHECKOVERRIDE OR (I.CHECKOVERRIDE is null and C.CHECKOVERRIDE is not null) OR (I.CHECKOVERRIDE is not null and C.CHECKOVERRIDE is null)
		OR		I.MAXLETTERS<>C.MAXLETTERS OR (I.MAXLETTERS is null and C.MAXLETTERS is not null) OR (I.MAXLETTERS is not null and C.MAXLETTERS is null)
		OR		I.LETTERFEE<>C.LETTERFEE OR (I.LETTERFEE is null and C.LETTERFEE is not null) OR (I.LETTERFEE is not null and C.LETTERFEE is null)
		OR		I.PAYFEECODE<>C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is not null) OR (I.PAYFEECODE is not null and C.PAYFEECODE is null)
		OR		I.EMPLOYEEFLAG<>C.EMPLOYEEFLAG OR (I.EMPLOYEEFLAG is null and C.EMPLOYEEFLAG is not null) OR (I.EMPLOYEEFLAG is not null and C.EMPLOYEEFLAG is null)
		OR		I.SIGNATORYFLAG<>C.SIGNATORYFLAG OR (I.SIGNATORYFLAG is null and C.SIGNATORYFLAG is not null) OR (I.SIGNATORYFLAG is not null and C.SIGNATORYFLAG is null)
		OR		I.INSTRUCTORFLAG<>C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is not null) OR (I.INSTRUCTORFLAG is not null and C.INSTRUCTORFLAG is null)
		OR		I.CRITICALFLAG<>C.CRITICALFLAG OR (I.CRITICALFLAG is null and C.CRITICALFLAG is not null) OR (I.CRITICALFLAG is not null and C.CRITICALFLAG is null)
		OR		I.REMINDEMPLOYEE<>C.REMINDEMPLOYEE OR (I.REMINDEMPLOYEE is null and C.REMINDEMPLOYEE is not null) OR (I.REMINDEMPLOYEE is not null and C.REMINDEMPLOYEE is null)
		OR		I.USEMESSAGE1<>C.USEMESSAGE1 OR (I.USEMESSAGE1 is null and C.USEMESSAGE1 is not null) OR (I.USEMESSAGE1 is not null and C.USEMESSAGE1 is null)
		OR		I.EMAILSUBJECT<>C.EMAILSUBJECT OR (I.EMAILSUBJECT is null and C.EMAILSUBJECT is not null) OR (I.EMAILSUBJECT is not null and C.EMAILSUBJECT is null)
		OR		I.SENDELECTRONICALLY<>C.SENDELECTRONICALLY OR (I.SENDELECTRONICALLY is null and C.SENDELECTRONICALLY is not null) OR (I.SENDELECTRONICALLY is not null and C.SENDELECTRONICALLY is null)
		OR		I.NAMETYPE<>C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) OR (I.NAMETYPE is not null and C.NAMETYPE is null)
		OR		I.ESTIMATEFLAG<>C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is not null) OR (I.ESTIMATEFLAG is not null and C.ESTIMATEFLAG is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			CR.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}',
			EC.EVENTDESCRIPTION,
			CASE (I.PERIODTYPE)
				WHEN('D') THEN 'Days'
				WHEN('W') THEN 'Weeks'	
				WHEN('M') THEN 'Months'	
				WHEN('Y') THEN 'Years'	
			END,
			I.LEADTIME,
			I.FREQUENCY,
			I.STOPTIME,
			CASE (I.UPDATEEVENT)
				WHEN(1) THEN 'Update Event when document produced'
				WHEN(2) THEN 'Produce document when Event updated'
			END,
			L.LETTERNAME,
			dbo.fn_DisplayBoolean(I.CHECKOVERRIDE,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			I.MAXLETTERS,
			R.RATEDESC,
			CASE WHEN(I.PAYFEECODE in (1,3)) THEN 'On' END,
			CASE WHEN(I.PAYFEECODE in (2,3)) THEN 'On' END,
			dbo.fn_DisplayBoolean(I.ESTIMATEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.EMPLOYEEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.SIGNATORYFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.CRITICALFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			NT.DESCRIPTION,
			dbo.fn_DisplayBoolean(I.SENDELECTRONICALLY,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			dbo.fn_DisplayBoolean(I.USEMESSAGE1,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",1),
			I.EMAILSUBJECT,
			convert(nvarchar(254),I.MESSAGE1),
			convert(nvarchar(254),I.MESSAGE2),
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL,
			NULL
		from "+@sUserName+".Imported_REMINDERS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CR	on (CR.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_EVENTCONTROL EC	on (EC.CRITERIANO=I.CRITERIANO
							and EC.EVENTNO=I.EVENTNO)
		left join "+@sUserName+".Imported_LETTER L	on (L.LETTERNO=I.LETTERNO)
		left join RATES R	on (R.RATENO=I.LETTERFEE)
		left join NAMETYPE NT	on (NT.NAMETYPE=I.NAMETYPE)"
		Set @sSQLString6="
		left join REMINDERS C on( C.CRITERIANO=I.CRITERIANO
					 and C.EVENTNO=I.EVENTNO
					 and C.REMINDERNO=I.REMINDERNO)
		where C.CRITERIANO is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,4,5" ELSE "3,4,5" END
	
		select @sSQLString1,@sSQLString2,@sSQLString3,@sSQLString4,@sSQLString5,@sSQLString6
		
		Select	@ErrorCode=@@Error,
			@pnRowCount=@@rowcount
	End
End

-- Data Update from temporary table
-- Merge the imported data
-- @pnFunction = 2 describes the update of the system data from the temporary table
If  @ErrorCode=0
and @pnFunction=2
Begin
	-- Remove any REMINDERS rows that do not exist in the imported table
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete REMINDERS
		From REMINDERS R
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=R.CRITERIANO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_REMINDERS I	on (I.CRITERIANO=R.CRITERIANO
						and I.EVENTNO=R.EVENTNO
						and I.REMINDERNO=R.REMINDERNO)
		Where I.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Remove any REMINDERS rows that were inherited from an imported Criteria
	-- but no longer exist in the newly imported criteria
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete REMINDERS
		From REMINDERS R
		Join CRITERIA CR on (CR.CRITERIANO=R.CRITERIANO)
		Join INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=IH.FROMCRITERIA)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_REMINDERS I	on (I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=R.EVENTNO
						and I.REMINDERNO=R.REMINDERNO)
		Where I.CRITERIANO is null
		and CR.USERDEFINEDRULE=1
		and R.INHERITED=1"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString1="
		Update REMINDERS
		set	PERIODTYPE=I.PERIODTYPE,
			LEADTIME=I.LEADTIME,
			FREQUENCY=I.FREQUENCY,
			STOPTIME=I.STOPTIME,
			UPDATEEVENT=I.UPDATEEVENT,
			LETTERNO=I.LETTERNO,
			CHECKOVERRIDE=I.CHECKOVERRIDE,
			MAXLETTERS=I.MAXLETTERS,
			LETTERFEE=I.LETTERFEE,
			PAYFEECODE=I.PAYFEECODE,
			EMPLOYEEFLAG=I.EMPLOYEEFLAG,
			SIGNATORYFLAG=I.SIGNATORYFLAG,
			INSTRUCTORFLAG=I.INSTRUCTORFLAG,
			CRITICALFLAG=I.CRITICALFLAG,
			REMINDEMPLOYEE=I.REMINDEMPLOYEE,
			USEMESSAGE1=I.USEMESSAGE1,
			INHERITED=I.INHERITED,
			EMAILSUBJECT=I.EMAILSUBJECT,
			SENDELECTRONICALLY=I.SENDELECTRONICALLY,
			NAMETYPE=I.NAMETYPE,
			ESTIMATEFLAG=I.ESTIMATEFLAG
		from	REMINDERS C
		join	"+@sUserName+".Imported_REMINDERS I	on ( I.CRITERIANO=C.CRITERIANO
						and I.EVENTNO=C.EVENTNO
						and I.REMINDERNO=C.REMINDERNO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)"
		Set @sSQLString2="
		where 		I.PERIODTYPE<>C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) OR (I.PERIODTYPE is not null and C.PERIODTYPE is null)
		OR		I.LEADTIME<>C.LEADTIME OR (I.LEADTIME is null and C.LEADTIME is not null) OR (I.LEADTIME is not null and C.LEADTIME is null)
		OR		I.FREQUENCY<>C.FREQUENCY OR (I.FREQUENCY is null and C.FREQUENCY is not null) OR (I.FREQUENCY is not null and C.FREQUENCY is null)
		OR		I.STOPTIME<>C.STOPTIME OR (I.STOPTIME is null and C.STOPTIME is not null) OR (I.STOPTIME is not null and C.STOPTIME is null)
		OR		I.UPDATEEVENT<>C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is not null) OR (I.UPDATEEVENT is not null and C.UPDATEEVENT is null)
		OR		I.LETTERNO<>C.LETTERNO OR (I.LETTERNO is null and C.LETTERNO is not null) OR (I.LETTERNO is not null and C.LETTERNO is null)
		OR		I.CHECKOVERRIDE<>C.CHECKOVERRIDE OR (I.CHECKOVERRIDE is null and C.CHECKOVERRIDE is not null) OR (I.CHECKOVERRIDE is not null and C.CHECKOVERRIDE is null)
		OR		I.MAXLETTERS<>C.MAXLETTERS OR (I.MAXLETTERS is null and C.MAXLETTERS is not null) OR (I.MAXLETTERS is not null and C.MAXLETTERS is null)
		OR		I.LETTERFEE<>C.LETTERFEE OR (I.LETTERFEE is null and C.LETTERFEE is not null) OR (I.LETTERFEE is not null and C.LETTERFEE is null)
		OR		I.PAYFEECODE<>C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is not null) OR (I.PAYFEECODE is not null and C.PAYFEECODE is null)
		OR		I.EMPLOYEEFLAG<>C.EMPLOYEEFLAG OR (I.EMPLOYEEFLAG is null and C.EMPLOYEEFLAG is not null) OR (I.EMPLOYEEFLAG is not null and C.EMPLOYEEFLAG is null)
		OR		I.SIGNATORYFLAG<>C.SIGNATORYFLAG OR (I.SIGNATORYFLAG is null and C.SIGNATORYFLAG is not null) OR (I.SIGNATORYFLAG is not null and C.SIGNATORYFLAG is null)
		OR		I.INSTRUCTORFLAG<>C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is not null) OR (I.INSTRUCTORFLAG is not null and C.INSTRUCTORFLAG is null)
		OR		I.CRITICALFLAG<>C.CRITICALFLAG OR (I.CRITICALFLAG is null and C.CRITICALFLAG is not null) OR (I.CRITICALFLAG is not null and C.CRITICALFLAG is null)
		OR		I.REMINDEMPLOYEE<>C.REMINDEMPLOYEE OR (I.REMINDEMPLOYEE is null and C.REMINDEMPLOYEE is not null) OR (I.REMINDEMPLOYEE is not null and C.REMINDEMPLOYEE is null)
		OR		I.USEMESSAGE1<>C.USEMESSAGE1 OR (I.USEMESSAGE1 is null and C.USEMESSAGE1 is not null) OR (I.USEMESSAGE1 is not null and C.USEMESSAGE1 is null)
		OR		I.EMAILSUBJECT<>C.EMAILSUBJECT OR (I.EMAILSUBJECT is null and C.EMAILSUBJECT is not null) OR (I.EMAILSUBJECT is not null and C.EMAILSUBJECT is null)
		OR		I.SENDELECTRONICALLY<>C.SENDELECTRONICALLY OR (I.SENDELECTRONICALLY is null and C.SENDELECTRONICALLY is not null) OR (I.SENDELECTRONICALLY is not null and C.SENDELECTRONICALLY is null)
		OR		I.NAMETYPE<>C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) OR (I.NAMETYPE is not null and C.NAMETYPE is null)
		OR		I.ESTIMATEFLAG<>C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is not null) OR (I.ESTIMATEFLAG is not null and C.ESTIMATEFLAG is null)"

		exec (@sSQLString1+@sSQLString2)

		Select	@ErrorCode=@@error,
			@pnRowCount=@@rowcount
	End

	If @ErrorCode = 0
	Begin

		-- Update the inherited rows where the key matches but there is some other discrepancy
	
		Set @sSQLString1="
		Update REMINDERS
		set	PERIODTYPE=I.PERIODTYPE,
			LEADTIME=I.LEADTIME,
			FREQUENCY=I.FREQUENCY,
			STOPTIME=I.STOPTIME,
			UPDATEEVENT=I.UPDATEEVENT,
			LETTERNO=I.LETTERNO,
			CHECKOVERRIDE=I.CHECKOVERRIDE,
			MAXLETTERS=I.MAXLETTERS,
			LETTERFEE=I.LETTERFEE,
			PAYFEECODE=I.PAYFEECODE,
			EMPLOYEEFLAG=I.EMPLOYEEFLAG,
			SIGNATORYFLAG=I.SIGNATORYFLAG,
			INSTRUCTORFLAG=I.INSTRUCTORFLAG,
			CRITICALFLAG=I.CRITICALFLAG,
			REMINDEMPLOYEE=I.REMINDEMPLOYEE,
			USEMESSAGE1=I.USEMESSAGE1,
			EMAILSUBJECT=I.EMAILSUBJECT,
			SENDELECTRONICALLY=I.SENDELECTRONICALLY,
			NAMETYPE=I.NAMETYPE,
			ESTIMATEFLAG=I.ESTIMATEFLAG
		from	REMINDERS C
		Join 	CRITERIA CR on (CR.CRITERIANO=C.CRITERIANO)
		Join 	INHERITS IH on (IH.CRITERIANO=CR.CRITERIANO)
		join	"+@sUserName+".Imported_REMINDERS I	on ( I.CRITERIANO=IH.FROMCRITERIA
						and I.EVENTNO=C.EVENTNO
						and I.REMINDERNO=C.REMINDERNO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)"
		Set @sSQLString2="
		where		CR.USERDEFINEDRULE=1
		AND		C.INHERITED=1 
		AND	       (I.PERIODTYPE<>C.PERIODTYPE OR (I.PERIODTYPE is null and C.PERIODTYPE is not null) OR (I.PERIODTYPE is not null and C.PERIODTYPE is null)
		OR		I.LEADTIME<>C.LEADTIME OR (I.LEADTIME is null and C.LEADTIME is not null) OR (I.LEADTIME is not null and C.LEADTIME is null)
		OR		I.FREQUENCY<>C.FREQUENCY OR (I.FREQUENCY is null and C.FREQUENCY is not null) OR (I.FREQUENCY is not null and C.FREQUENCY is null)
		OR		I.STOPTIME<>C.STOPTIME OR (I.STOPTIME is null and C.STOPTIME is not null) OR (I.STOPTIME is not null and C.STOPTIME is null)
		OR		I.UPDATEEVENT<>C.UPDATEEVENT OR (I.UPDATEEVENT is null and C.UPDATEEVENT is not null) OR (I.UPDATEEVENT is not null and C.UPDATEEVENT is null)
		OR		I.LETTERNO<>C.LETTERNO OR (I.LETTERNO is null and C.LETTERNO is not null) OR (I.LETTERNO is not null and C.LETTERNO is null)
		OR		I.CHECKOVERRIDE<>C.CHECKOVERRIDE OR (I.CHECKOVERRIDE is null and C.CHECKOVERRIDE is not null) OR (I.CHECKOVERRIDE is not null and C.CHECKOVERRIDE is null)
		OR		I.MAXLETTERS<>C.MAXLETTERS OR (I.MAXLETTERS is null and C.MAXLETTERS is not null) OR (I.MAXLETTERS is not null and C.MAXLETTERS is null)
		OR		I.LETTERFEE<>C.LETTERFEE OR (I.LETTERFEE is null and C.LETTERFEE is not null) OR (I.LETTERFEE is not null and C.LETTERFEE is null)
		OR		I.PAYFEECODE<>C.PAYFEECODE OR (I.PAYFEECODE is null and C.PAYFEECODE is not null) OR (I.PAYFEECODE is not null and C.PAYFEECODE is null)
		OR		I.EMPLOYEEFLAG<>C.EMPLOYEEFLAG OR (I.EMPLOYEEFLAG is null and C.EMPLOYEEFLAG is not null) OR (I.EMPLOYEEFLAG is not null and C.EMPLOYEEFLAG is null)
		OR		I.SIGNATORYFLAG<>C.SIGNATORYFLAG OR (I.SIGNATORYFLAG is null and C.SIGNATORYFLAG is not null) OR (I.SIGNATORYFLAG is not null and C.SIGNATORYFLAG is null)
		OR		I.INSTRUCTORFLAG<>C.INSTRUCTORFLAG OR (I.INSTRUCTORFLAG is null and C.INSTRUCTORFLAG is not null) OR (I.INSTRUCTORFLAG is not null and C.INSTRUCTORFLAG is null)
		OR		I.CRITICALFLAG<>C.CRITICALFLAG OR (I.CRITICALFLAG is null and C.CRITICALFLAG is not null) OR (I.CRITICALFLAG is not null and C.CRITICALFLAG is null)
		OR		I.REMINDEMPLOYEE<>C.REMINDEMPLOYEE OR (I.REMINDEMPLOYEE is null and C.REMINDEMPLOYEE is not null) OR (I.REMINDEMPLOYEE is not null and C.REMINDEMPLOYEE is null)
		OR		I.USEMESSAGE1<>C.USEMESSAGE1 OR (I.USEMESSAGE1 is null and C.USEMESSAGE1 is not null) OR (I.USEMESSAGE1 is not null and C.USEMESSAGE1 is null)
		OR		I.EMAILSUBJECT<>C.EMAILSUBJECT OR (I.EMAILSUBJECT is null and C.EMAILSUBJECT is not null) OR (I.EMAILSUBJECT is not null and C.EMAILSUBJECT is null)
		OR		I.SENDELECTRONICALLY<>C.SENDELECTRONICALLY OR (I.SENDELECTRONICALLY is null and C.SENDELECTRONICALLY is not null) OR (I.SENDELECTRONICALLY is not null and C.SENDELECTRONICALLY is null)
		OR		I.NAMETYPE<>C.NAMETYPE OR (I.NAMETYPE is null and C.NAMETYPE is not null) OR (I.NAMETYPE is not null and C.NAMETYPE is null)
		OR		I.ESTIMATEFLAG<>C.ESTIMATEFLAG OR (I.ESTIMATEFLAG is null and C.ESTIMATEFLAG is not null) OR (I.ESTIMATEFLAG is not null and C.ESTIMATEFLAG is null))"

		exec (@sSQLString1+@sSQLString2)

		Select	@ErrorCode=@@error,
			@pnRowCount=@pnRowCount+@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into REMINDERS(
			CRITERIANO,
			EVENTNO,
			REMINDERNO,
			PERIODTYPE,
			LEADTIME,
			FREQUENCY,
			STOPTIME,
			UPDATEEVENT,
			LETTERNO,
			CHECKOVERRIDE,
			MAXLETTERS,
			LETTERFEE,
			PAYFEECODE,
			EMPLOYEEFLAG,
			SIGNATORYFLAG,
			INSTRUCTORFLAG,
			CRITICALFLAG,
			REMINDEMPLOYEE,
			USEMESSAGE1,
			INHERITED,
			EMAILSUBJECT,
			SENDELECTRONICALLY,
			NAMETYPE,
			ESTIMATEFLAG,
			MESSAGE1,
			MESSAGE2)
		select	I.CRITERIANO,
			I.EVENTNO,
			I.REMINDERNO,
			I.PERIODTYPE,
			I.LEADTIME,
			I.FREQUENCY,
			I.STOPTIME,
			I.UPDATEEVENT,
			I.LETTERNO,
			I.CHECKOVERRIDE,
			I.MAXLETTERS,
			I.LETTERFEE,
			I.PAYFEECODE,
			I.EMPLOYEEFLAG,
			I.SIGNATORYFLAG,
			I.INSTRUCTORFLAG,
			I.CRITICALFLAG,
			I.REMINDEMPLOYEE,
			I.USEMESSAGE1,
			I.INHERITED,
			I.EMAILSUBJECT,
			I.SENDELECTRONICALLY,
			I.NAMETYPE,
			I.ESTIMATEFLAG,
			I.MESSAGE1,
			I.MESSAGE2
		from "+@sUserName+".Imported_REMINDERS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		left join REMINDERS C	on ( C.CRITERIANO=I.CRITERIANO
						and C.EVENTNO=I.EVENTNO
						and C.REMINDERNO=I.REMINDERNO)
		where C.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

	If @ErrorCode=0
	Begin

		-- Insert the rows for Inherited Criteria where the data does not exist.
		Set @sSQLString= "
		Insert into REMINDERS(
			CRITERIANO,
			EVENTNO,
			REMINDERNO,
			PERIODTYPE,
			LEADTIME,
			FREQUENCY,
			STOPTIME,
			UPDATEEVENT,
			LETTERNO,
			CHECKOVERRIDE,
			MAXLETTERS,
			LETTERFEE,
			PAYFEECODE,
			EMPLOYEEFLAG,
			SIGNATORYFLAG,
			INSTRUCTORFLAG,
			CRITICALFLAG,
			REMINDEMPLOYEE,
			USEMESSAGE1,
			INHERITED,
			EMAILSUBJECT,
			SENDELECTRONICALLY,
			NAMETYPE,
			ESTIMATEFLAG,
			MESSAGE1,
			MESSAGE2)
		select	IH.CRITERIANO,
			I.EVENTNO,
			I.REMINDERNO,
			I.PERIODTYPE,
			I.LEADTIME,
			I.FREQUENCY,
			I.STOPTIME,
			I.UPDATEEVENT,
			I.LETTERNO,
			I.CHECKOVERRIDE,
			I.MAXLETTERS,
			I.LETTERFEE,
			I.PAYFEECODE,
			I.EMPLOYEEFLAG,
			I.SIGNATORYFLAG,
			I.INSTRUCTORFLAG,
			I.CRITICALFLAG,
			I.REMINDEMPLOYEE,
			I.USEMESSAGE1,
			1,
			I.EMAILSUBJECT,
			I.SENDELECTRONICALLY,
			I.NAMETYPE,
			I.ESTIMATEFLAG,
			I.MESSAGE1,
			I.MESSAGE2
		from "+@sUserName+".Imported_REMINDERS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
		join INHERITS IH on (IH.FROMCRITERIA=I.CRITERIANO)
		join CRITERIA CR on (CR.CRITERIANO=IH.CRITERIANO)
		left join REMINDERS C	on (C.CRITERIANO=CR.CRITERIANO
					and C.EVENTNO=I.EVENTNO
					and C.REMINDERNO=I.REMINDERNO)
		where C.CRITERIANO is null
		AND CR.USERDEFINEDRULE=1"

		exec @ErrorCode=sp_executesql @sSQLString
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End
End

-- @pnFunction = 3 supplies the statement to collect the system keys if
-- there is a primary key associated with this tab which may be mapped.
-- (if no mapping is allowed return null)
If  @ErrorCode=0
and @pnFunction=3
Begin
	Set @sSQLString=null

	select @sSQLString
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End


RETURN @ErrorCode
go
grant execute on dbo.ip_RulesREMINDERS  to public
go

