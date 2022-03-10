-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesVALIDACTDATES
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesVALIDACTDATES]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesVALIDACTDATES.'
	drop procedure dbo.ip_RulesVALIDACTDATES
	print '**** Creating procedure dbo.ip_RulesVALIDACTDATES...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesVALIDACTDATES
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesVALIDACTDATES
-- VERSION :	14
-- DESCRIPTION:	The comparison/display and merging of imported data for the VALIDACTDATES table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 10 Jan 2005	MF	10788	2	Data comparison was not showing the differences correctly on the
--					existing data.
-- 26 Sep 2012	MF	12788	3	Need to cater for situation where firms have created their own VALIDACTDATES
--					entry and so SEQUENCENO cannot be used as a guarantee to match on.
-- 28 Sep 2012	MF	12788	4	Revisit.  Only update an existing VALIDACTDATES row if the RESTROSPECTIVEACTIO
--					matches the imported row currently with a value of ~1 or ~2. New rows with no
--					RETROSPECTIVEACTIO value may however be inserted.
-- 12 Nov 2012	MF	12936	5	Revisit of 12788. Two rows can be delivered at the same time where one has a RESTROSPECTIVEACTIO
--					value and the other is NULL.  This was causing the same SEQUENCENO to be generated and producing a
--					duplicate key error.
-- 04 Jan 2013	MF	12936	6	Further revisit of 12788.  Increment SEQUENCENO by 1 to cater for imported rows that have a 
--					SEQUENCENO of 0.
-- 10 Apr 2013	DL	21326	7	Remove embedded comments in select SQL that being created for the front end to run.
-- 11 Jun 2013	MF	S21404	8	When updating VALIDACTDATE ensure there is not already an identical row in existence.
-- 14 Mar 2015	MF	R45721	9	Correction to Update that was blocking some rows from being updated.
-- 29 May 2015	MF	R48057	10	Laws blocked from importing are still generating Policing requests. VALIDACTDATES needs to consider
--					the blocking rules to ensure that VALIDACTDATES rows to be imported are allowed.
-- 19 Aug 2015	MF	R51367	11	Revisit of RFC48057 as Centura crashing because it can't see temporary table.
-- 17 Sep 2015	MF	R52350	12	Law update of ValidActDate not being applied when retrospective action is empty.
-- 16 Nov 2015	MF		13	Delete out all of the ValidActDate rows with a RetrospectiveActio set to NULL as long as it doesn’t 
--							have a non-LUS row equivalent. The XML load will then correctly replace what is required.
-- 31 Mar 2020	DL	DR-58828 14 Not all VALIDACTDATES entries created during law update
--
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


CREATE TABLE #TEMPVALIDACTDATESALLOWED
 (
 	COUNTRYCODE		nvarchar(3)	collate database_default NOT NULL ,
 	PROPERTYTYPE		nchar(1)	collate database_default NOT NULL
 )

-- Prerequisite that the IMPORTED_VALIDACTDATES table has been loaded

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

-- @pnFunction = 1 & 2 Apply any data mapping before Updating or Displaying data comparison
If @ErrorCode=0 
and @pnSourceNo is not null
and @pnFunction in (1,2)
Begin
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.

	Set @sSQLString=
		"UPDATE "+@sUserName+".Imported_VALIDACTDATES
		SET COUNTRYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_VALIDACTDATES C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.COUNTRYCODE)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDACTDATES
			SET PROPERTYTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDACTDATES C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='PROPERTYTYPE'
					and M.MAPCOLUMN  ='PROPERTYTYPE'
					and M.SOURCEVALUE=C.PROPERTYTYPE)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDACTDATES
			SET RETROSPECTIVEACTIO = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDACTDATES C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='ACTIONS'
					and M.MAPCOLUMN  ='ACTION'
					and M.SOURCEVALUE=C.RETROSPECTIVEACTIO)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDACTDATES
			SET ACTEVENTNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDACTDATES C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.ACTEVENTNO)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end

	If  @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDACTDATES
			SET RETROEVENTNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDACTDATES C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.RETROEVENTNO)
			WHERE M.MAPVALUE is not null"

		exec @ErrorCode=sp_executesql @sSQLString
	end
End

If @ErrorCode=0
Begin
	-----------------------------------------
	-- Check each candidate import row of
	-- VALIDACTDATES to see that it is not
	-- blocked from being imported.
	-----------------------------------------
	set @sSQLString="
	insert into #TEMPVALIDACTDATESALLOWED (COUNTRYCODE, PROPERTYTYPE)
	select V.COUNTRYCODE, V.PROPERTYTYPE
	from "+@sUserName+".Imported_VALIDACTDATES V
	cross join (select distinct ACTION
		    from CRITERIA
		    where PURPOSECODE='X'
		    and ACTION is not null) A
	left join CRITERIA C on (C.CRITERIANO = dbo.fn_GetCriteriaNoForLawImportBlocking( 'A',		-- defaulting the CaseType to 'A'
											  A.ACTION,	-- defaulting from Actions defined in blocking rules
											  V.PROPERTYTYPE,
											  V.COUNTRYCODE,
											  default,
											  default,
											  default,
											  default) )
	where isnull(C.RULEINUSE,0)=0
	------------------------------------------------
	-- If no blocking is defined at all then return 
	-- every combination of Country and PropertyType
	------------------------------------------------
	UNION
	select V.COUNTRYCODE, V.PROPERTYTYPE
	from "+@sUserName+".Imported_VALIDACTDATES V
	where not exists
	(select 1 from CRITERIA where PURPOSECODE='X' and ACTION is not null)"
	
	exec @ErrorCode=sp_executesql @sSQLString
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
			I.COUNTRYCODE		as 'Imported Country',
			P.PROPERTYNAME		as 'Imported Property',
			I.DATEOFACT		as 'Imported Date of Law',
			A.ACTIONNAME		as 'Imported Action',
			EL.EVENTDESCRIPTION	as 'Imported Event',
			ER.EVENTDESCRIPTION	as 'Imported Restrospective',
			C.COUNTRYCODE		as 'Country',
			P.PROPERTYNAME		as 'Property',
			C.DATEOFACT		as 'Date of Law',
			A.ACTIONNAME		as 'Action',
			EL.EVENTDESCRIPTION	as 'Event',
			EL.EVENTDESCRIPTION	as 'Retrospective'
		from "+@sUserName+".Imported_VALIDACTDATES I
		join "+@sUserName+".Imported_PROPERTYTYPE P	on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		left join "+@sUserName+".Imported_ACTIONS A	on (A.ACTION=I.RETROSPECTIVEACTIO)
		left join "+@sUserName+".Imported_EVENTS EL	on (EL.EVENTNO=I.ACTEVENTNO)
		left join "+@sUserName+".Imported_EVENTS ER	on (ER.EVENTNO=I.RETROEVENTNO)"
		Set @sSQLString2="	join VALIDACTDATES C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.DATEOFACT=I.DATEOFACT
					and(C.RETROSPECTIVEACTIO=I.RETROSPECTIVEACTIO OR (C.RETROSPECTIVEACTIO is null and I.RETROSPECTIVEACTIO is null )))
		where	(I.ACTEVENTNO=C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is null))
		and	(I.RETROEVENTNO=C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.COUNTRYCODE,
			P.PROPERTYNAME,
			I.DATEOFACT,
			A.ACTIONNAME,
			EL.EVENTDESCRIPTION,
			ER.EVENTDESCRIPTION,
			C.COUNTRYCODE,
			P.PROPERTYNAME,
			C.DATEOFACT,
			A1.ACTIONNAME,
			EL1.EVENTDESCRIPTION,
			ER1.EVENTDESCRIPTION
		from "+@sUserName+".Imported_VALIDACTDATES I
		join "+@sUserName+".Imported_PROPERTYTYPE P	on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		left join "+@sUserName+".Imported_ACTIONS A	on (A.ACTION=I.RETROSPECTIVEACTIO)
		left join "+@sUserName+".Imported_EVENTS EL	on (EL.EVENTNO=I.ACTEVENTNO)
		left join "+@sUserName+".Imported_EVENTS ER	on (ER.EVENTNO=I.RETROEVENTNO)"

		-- SQA21326 remove embedded comments as sql cannot be compiled by ODBC driver.
		-- and C.RETROSPECTIVEACTIO=I.RETROSPECTIVEACTIO	-- Deliberately does not consider NULL to be a match
		-- and C.RETROSPECTIVEACTIO in ('~1','~2') )	-- Only consider ~1 and ~2
		Set @sSQLString3=@sSQLString3+"
		join VALIDACTDATES C	on( C.COUNTRYCODE=I.COUNTRYCODE
					and C.PROPERTYTYPE=I.PROPERTYTYPE
					and C.DATEOFACT=I.DATEOFACT
					and C.RETROSPECTIVEACTIO=I.RETROSPECTIVEACTIO	
					and C.RETROSPECTIVEACTIO in ('~1','~2') )	
		left join ACTIONS A1	on (A1.ACTION=C.RETROSPECTIVEACTIO)
		left join EVENTS EL1	on (EL1.EVENTNO=C.ACTEVENTNO)
		left join EVENTS ER1	on (ER1.EVENTNO=C.RETROEVENTNO)
		where 	I.ACTEVENTNO<>C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is not null) OR (I.ACTEVENTNO is not null and C.ACTEVENTNO is null)
		OR	I.RETROEVENTNO<>C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is not null) OR (I.RETROEVENTNO is not null and C.RETROEVENTNO is null)"
		Set @sSQLString4="
		UNION ALL
		select	2,
			'O',
			I.COUNTRYCODE,
			P.PROPERTYNAME,
			I.DATEOFACT,
			NULL,
			EL.EVENTDESCRIPTION,
			ER.EVENTDESCRIPTION,
			C.COUNTRYCODE,
			P.PROPERTYNAME,
			C.DATEOFACT,
			NULL,
			EL1.EVENTDESCRIPTION,
			ER1.EVENTDESCRIPTION
		from "+@sUserName+".Imported_VALIDACTDATES I
		join "+@sUserName+".Imported_PROPERTYTYPE P	on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		left join "+@sUserName+".Imported_EVENTS EL	on (EL.EVENTNO=I.ACTEVENTNO)
		left join "+@sUserName+".Imported_EVENTS ER	on (ER.EVENTNO=I.RETROEVENTNO)
		join VALIDACTDATES C  on (C.PROPERTYTYPE= I.PROPERTYTYPE
		                      and C.COUNTRYCODE = I.COUNTRYCODE
		                      and C.DATEOFACT   = I.DATEOFACT
		                      and C.RETROSPECTIVEACTIO is null)
		left join CRITERIA CR on (CR.PROPERTYTYPE=C.PROPERTYTYPE
				      and CR.COUNTRYCODE =C.COUNTRYCODE
				      and CR.ACTION not in ('~1','~2')
				      and CR.DATEOFACT   =C.DATEOFACT)
		left join VALIDACTDATES C2
				      on (C2.PROPERTYTYPE=C.PROPERTYTYPE
				      and C2.COUNTRYCODE =C.COUNTRYCODE
				      and C2.DATEOFACT   =C.DATEOFACT
				      and isnull(C2.RETROSPECTIVEACTIO, '~1') NOT IN ('~1','~2'))
		left join EVENTS EL1	on (EL1.EVENTNO=C.ACTEVENTNO)
		left join EVENTS ER1	on (ER1.EVENTNO=C.RETROEVENTNO)
		where   I.RETROSPECTIVEACTIO is null
		and    CR.CRITERIANO         is null
		and    C2.DATEOFACT          is null	
		and (	I.ACTEVENTNO<>C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is not null) OR (I.ACTEVENTNO is not null and C.ACTEVENTNO is null)
		OR	I.RETROEVENTNO<>C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is not null) OR (I.RETROEVENTNO is not null and C.RETROEVENTNO is null))"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.COUNTRYCODE,
			P.PROPERTYNAME,
			I.DATEOFACT,
			A.ACTIONNAME,
			EL.EVENTDESCRIPTION,
			ER.EVENTDESCRIPTION,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_VALIDACTDATES I
		join PROPERTYTYPE P	on (P.PROPERTYTYPE=I.PROPERTYTYPE)
		left join ACTIONS A	on (A.ACTION=I.RETROSPECTIVEACTIO)
		left join EVENTS EL	on (EL.EVENTNO=I.ACTEVENTNO)
		left join EVENTS ER	on (ER.EVENTNO=I.RETROEVENTNO)"
		Set @sSQLString6="	left join VALIDACTDATES C on( C.COUNTRYCODE=I.COUNTRYCODE
					 and C.PROPERTYTYPE=I.PROPERTYTYPE
					 and C.DATEOFACT=I.DATEOFACT
					 and(C.RETROSPECTIVEACTIO=I.RETROSPECTIVEACTIO OR (C.RETROSPECTIVEACTIO is null and I.RETROSPECTIVEACTIO is null ))
						and   isnull(C.ACTEVENTNO,'')=isnull(I.ACTEVENTNO,'')
						and   isnull(C.RETROEVENTNO,'')=isnull(I.RETROEVENTNO,'') )
		where C.COUNTRYCODE is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,4,5,6" ELSE "3,4,5,6" END
	
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
	If @ErrorCode = 0
	Begin
		-------------------------------------------------
		-- Update the ~1 or ~2 rows where the key matches 
		-- but there is some other discrepancy.
		-------------------------------------------------	
		Set @sSQLString="
		Update VALIDACTDATES
		set	ACTEVENTNO=I.ACTEVENTNO,
			RETROEVENTNO=I.RETROEVENTNO
		from	VALIDACTDATES C
		join	"+@sUserName+".Imported_VALIDACTDATES I	on ( I.COUNTRYCODE=C.COUNTRYCODE
						and I.PROPERTYTYPE=C.PROPERTYTYPE
						and I.DATEOFACT=C.DATEOFACT
						and(I.RETROSPECTIVEACTIO=C.RETROSPECTIVEACTIO OR (I.RETROSPECTIVEACTIO is null and C.RETROSPECTIVEACTIO is null))	-- RFC52350
						and I.RETROSPECTIVEACTIO  in ('~1','~2') )	-- Only consider changes for ~1 or ~2
		join #TEMPVALIDACTDATESALLOWED I1
						on (I1.COUNTRYCODE =I.COUNTRYCODE
						and I1.PROPERTYTYPE=I.PROPERTYTYPE)
		where (	I.ACTEVENTNO<>C.ACTEVENTNO OR (I.ACTEVENTNO is null and C.ACTEVENTNO is not null) OR (I.ACTEVENTNO is not null and C.ACTEVENTNO is null)
		OR	I.RETROEVENTNO<>C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is not null) OR (I.RETROEVENTNO is not null and C.RETROEVENTNO is null) )
		and not exists
		(SELECT 1 from VALIDACTDATES C1
		 where C1.COUNTRYCODE=C.COUNTRYCODE
		 and   C1.PROPERTYTYPE=C.PROPERTYTYPE	-- RFC45721
		 and   C1.DATEOFACT  =C.DATEOFACT
		 and  (C1.RETROSPECTIVEACTIO=C.RETROSPECTIVEACTIO OR (C1.RETROSPECTIVEACTIO is null and C.RETROSPECTIVEACTIO is null))	-- RFC52350
		 and   isnull(C1.ACTEVENTNO,'')=isnull(I.ACTEVENTNO,'')
		 and   isnull(C1.RETROEVENTNO,'')=isnull(I.RETROEVENTNO,'') )"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 
	
	If @ErrorCode = 0
	Begin
		-------------------------------------------------
		-- Update the rows that do not have a Retrospective
		-- Action and where there are no non LUS criteria
		-- referencing the DateOfAct.  Also ensure the
		-- VALIDACTDATES row being updated is not being 
		-- paired with another 
		-------------------------------------------------
		Set @sSQLString="
		Update C
		set	ACTEVENTNO  =I.ACTEVENTNO,
			RETROEVENTNO=I.RETROEVENTNO
		from	VALIDACTDATES C
		join	"+@sUserName+".Imported_VALIDACTDATES I	
						on (I.COUNTRYCODE =C.COUNTRYCODE
						and I.PROPERTYTYPE=C.PROPERTYTYPE
						and I.DATEOFACT   =C.DATEOFACT
						and I.RETROSPECTIVEACTIO is null 
						and C.RETROSPECTIVEACTIO is null)
		join #TEMPVALIDACTDATESALLOWED I1
						on (I1.COUNTRYCODE =I.COUNTRYCODE
						and I1.PROPERTYTYPE=I.PROPERTYTYPE)
						
		left join CRITERIA CR		on (CR.PROPERTYTYPE=C.PROPERTYTYPE
						and CR.COUNTRYCODE =C.COUNTRYCODE
						and CR.ACTION not in ('~1','~2')
						and CR.DATEOFACT   =C.DATEOFACT)
		where CR.CRITERIANO is null
		and (	I.ACTEVENTNO<>C.ACTEVENTNO     OR (I.ACTEVENTNO   is null and C.ACTEVENTNO   is not null) OR (I.ACTEVENTNO   is not null and C.ACTEVENTNO   is null)
		OR	I.RETROEVENTNO<>C.RETROEVENTNO OR (I.RETROEVENTNO is null and C.RETROEVENTNO is not null) OR (I.RETROEVENTNO is not null and C.RETROEVENTNO is null) )
		and not exists
		(SELECT 1 from VALIDACTDATES C1
		 where C1.COUNTRYCODE =C.COUNTRYCODE
		 and   C1.PROPERTYTYPE=C.PROPERTYTYPE	-- RFC45721
		 and   C1.DATEOFACT   =C.DATEOFACT
		 and  (C1.RETROSPECTIVEACTIO=C.RETROSPECTIVEACTIO OR (C1.RETROSPECTIVEACTIO is null and C.RETROSPECTIVEACTIO is null))	-- RFC52350
		 and   isnull(C1.ACTEVENTNO,'')  =isnull(I.ACTEVENTNO,'')
		 and   isnull(C1.RETROEVENTNO,'')=isnull(I.RETROEVENTNO,'') )
		 -------------------------------------------
		 -- Check that the row being updated is not 
		 -- paired to a VALIDACTDATES row for a non
		 -- LUS(~1, ~2) action
		 -------------------------------------------
		and not exists
		(SELECT 1 from VALIDACTDATES C2
		 where C2.COUNTRYCODE =C.COUNTRYCODE
		 and   C2.PROPERTYTYPE=C.PROPERTYTYPE	-- RFC45721
		 and   C2.DATEOFACT   =C.DATEOFACT
		 and   isnull(C2.RETROSPECTIVEACTIO, '~1') NOT IN ('~1','~2'))"
		 
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@pnRowCount+@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into VALIDACTDATES(
			COUNTRYCODE,
			PROPERTYTYPE,
			DATEOFACT,
			SEQUENCENO,
			RETROSPECTIVEACTIO,
			ACTEVENTNO,
			RETROEVENTNO)
		select	I.COUNTRYCODE,
			I.PROPERTYTYPE,
			I.DATEOFACT,
			(select isnull(max(C1.SEQUENCENO),0)+I.SEQUENCENO+1	-- cater for I.SEQUENCENO=0 by incrementing by 1
			 from VALIDACTDATES C1
			 where C1.COUNTRYCODE=I.COUNTRYCODE
			 and   C1.PROPERTYTYPE=I.PROPERTYTYPE
			 and   C1.DATEOFACT   =I.DATEOFACT ),
			I.RETROSPECTIVEACTIO,
			I.ACTEVENTNO,
			I.RETROEVENTNO
		from "+@sUserName+".Imported_VALIDACTDATES I
		join #TEMPVALIDACTDATESALLOWED I1
						on (I1.COUNTRYCODE =I.COUNTRYCODE
						and I1.PROPERTYTYPE=I.PROPERTYTYPE)
		left join VALIDACTDATES C	on (C.COUNTRYCODE=I.COUNTRYCODE
						and C.PROPERTYTYPE=I.PROPERTYTYPE
						and C.DATEOFACT=I.DATEOFACT
						and(C.RETROSPECTIVEACTIO=I.RETROSPECTIVEACTIO OR (C.RETROSPECTIVEACTIO is null and I.RETROSPECTIVEACTIO is null ))
						-- DR-58828  Add these conditions to insert the missing rows
						and   isnull(C.ACTEVENTNO,'')=isnull(I.ACTEVENTNO,'')
						and   isnull(C.RETROEVENTNO,'')=isnull(I.RETROEVENTNO,''))
		where C.COUNTRYCODE is null"


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
grant execute on dbo.ip_RulesVALIDACTDATES  to public
go