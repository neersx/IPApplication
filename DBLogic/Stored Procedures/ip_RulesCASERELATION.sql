-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesCASERELATION
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesCASERELATION]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesCASERELATION.'
	drop procedure dbo.ip_RulesCASERELATION
	print '**** Creating procedure dbo.ip_RulesCASERELATION...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesCASERELATION
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesCASERELATION
-- VERSION :	8
-- DESCRIPTION:	The comparison/display and merging of imported data for the CASERELATION table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 19 Jul 2004	MF		1	Procedure created
-- 28 Mar 2006	MF	12500	2	Do not replace the description
-- 27-Nov-2006	MF	13919	3	Ensure sp_xml_removedocument is called after sp_xml_preparedocument
--					by ignoring the value or ErrorCode
-- 16-Aug-2007	MF	14732	4	Do not report differences in RELATIONSHIPDESC as these are deliberately
--					not updated.
-- 24-Jul-2009	MF	16548	5	Two new columns: FROMEVENTNO and DISPLAYEVENTNO
-- 20-Jan-2011	MF	19332	6	The Event numbers associated with the Relationship should not be changed if they already have a value.
-- 21 Jan 2011	MF	19321	7	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 26-May-2011	MF	19332	8	Revisit 19332 and ensure FROMEVENTNO and DISPLAYEVENTNO are delivered for new
--					relationships.
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


-- Prerequisite that the IMPORTED_CASERELATION table has been loaded

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
Set @sUserName=@psUserName


--------------------------------------------------------
-- If the imported law file is not yet delivering values
-- in the FROMEVENTNO columns then initialise these now.
-- This will cater for firms that have upgraded before
-- the law update service.
--------------------------------------------------------
If @ErrorCode=0
Begin
	Set @sSQLString=
	"Update "+@sUserName+".Imported_CASERELATION
	Set FROMEVENTNO=EVENTNO
	Where EVENTNO is not null
	and FROMEVENTNO is null"

	exec @ErrorCode=sp_executesql @sSQLString
End

-- @pnFunction = 1 & 2 Apply any data mapping before Updating or Displaying data comparison
If @ErrorCode=0 
and @pnFunction in (1,2)
Begin
	-- If mapping is allowed add an extra column to store the original key for update
	-- and update the key with the previously stored mappings.
	-- @pnFunction = 1 describes the set up and selection of the data comparison
	-- Exclude this section if tab does not support mapping.
	
	Set @sSQLString="select @bOriginalKeyColumnExists = 1 
                         from syscolumns 
			 where (name = 'ORIGINAL_KEY') and id = object_id('"+@sUserName+".Imported_CASERELATION')"
	Exec @ErrorCode=sp_executesql @sSQLString,
			N'@bOriginalKeyColumnExists	bit OUTPUT',
			  @bOriginalKeyColumnExists 	= @bOriginalKeyColumnExists OUTPUT

	If  @ErrorCode=0
	and @bOriginalKeyColumnExists=0
	Begin
		Set @sSQLString="ALTER TABLE "+@sUserName+".Imported_CASERELATION ADD ORIGINAL_KEY NVARCHAR(50)"
		exec @ErrorCode=sp_executesql @sSQLString

		-- Now save the original key value
		If @ErrorCode=0
		Begin
			Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CASERELATION
			SET ORIGINAL_KEY=RTRIM(RELATIONSHIP)"

			exec @ErrorCode=sp_executesql @sSQLString
		End
	End
	
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.
	If  @ErrorCode=0
	and @pnSourceNo is not null
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CASERELATION
			SET RELATIONSHIP = isnull(M.MAPVALUE, C.ORIGINAL_KEY)
			FROM "+@sUserName+".Imported_CASERELATION C
			LEFT JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
						and M.MAPTABLE   ='CASERELATION'
						and M.MAPCOLUMN  ='RELATIONSHIP'
						and M.SOURCEVALUE=C.ORIGINAL_KEY)"
		exec @ErrorCode=sp_executesql @sSQLString
	end
	
	-- Apply the Mapping if it exists or revert back to the Original Key if there is no Mapping.
	If  @ErrorCode=0
	and @pnSourceNo is not null
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CASERELATION
			SET EVENTNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_CASERELATION C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.EVENTNO)
			WHERE M.MAPVALUE is not null"
		exec @ErrorCode=sp_executesql @sSQLString
	end
	
	If  @ErrorCode=0
	and @pnSourceNo is not null
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CASERELATION
			SET DISPLAYEVENTNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_CASERELATION C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.DISPLAYEVENTNO)
			WHERE M.MAPVALUE is not null"
		exec @ErrorCode=sp_executesql @sSQLString
	end
	
	If  @ErrorCode=0
	and @pnSourceNo is not null
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_CASERELATION
			SET FROMEVENTNO = M.MAPVALUE
			FROM "+@sUserName+".Imported_CASERELATION C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='EVENTS'
					and M.MAPCOLUMN  ='EVENTNO'
					and M.SOURCEVALUE=C.FROMEVENTNO)
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
			I.RELATIONSHIP		as 'Imported Relationship Code',
			E1.EVENTDESCRIPTION	as 'Imported Event',
			E4.EVENTDESCRIPTION	as 'Imported From Event',
			E5.EVENTDESCRIPTION	as 'Imported Display Event',
			dbo.fn_DisplayBoolean(I.EARLIESTDATEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Imported Earliest Date',
			I.RELATIONSHIPDESC	as 'Imported Relationship',
			I.POINTERTOPARENT	as 'Imported Pointer To Parent',
			C.RELATIONSHIP		as 'Relationship Code',
			E1.EVENTDESCRIPTION	as 'Event',
			E4.EVENTDESCRIPTION	as 'From Event',
			E5.EVENTDESCRIPTION	as 'Display Event',
			dbo.fn_DisplayBoolean(C.EARLIESTDATEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0)
						as 'Earliest Date',
			C.RELATIONSHIPDESC	as 'Relationship',
			C.POINTERTOPARENT	as 'Pointer To Parent'
		from "+@sUserName+".Imported_CASERELATION I
		left join "+@sUserName+".Imported_EVENTS E	on(E.EVENTNO=I.EVENTNO)
		left join "+@sUserName+".Imported_EVENTS E2	on(E2.EVENTNO=I.FROMEVENTNO)
		left join "+@sUserName+".Imported_EVENTS E3	on(E3.EVENTNO=I.DISPLAYEVENTNO)"
		Set @sSQLString2="	join CASERELATION C	on( C.RELATIONSHIP=I.RELATIONSHIP)
		left join EVENTS E1	on(E1.EVENTNO=C.EVENTNO)
		left join EVENTS E4	on(E4.EVENTNO=C.FROMEVENTNO)
		left join EVENTS E5	on(E5.EVENTNO=C.DISPLAYEVENTNO)
		where	(I.EARLIESTDATEFLAG=C.EARLIESTDATEFLAG OR (I.EARLIESTDATEFLAG is null and C.EARLIESTDATEFLAG is null))
		and	(I.POINTERTOPARENT=C.POINTERTOPARENT OR (I.POINTERTOPARENT is null and C.POINTERTOPARENT is null))"
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.RELATIONSHIP,
			E1.EVENTDESCRIPTION,
			E4.EVENTDESCRIPTION,
			E5.EVENTDESCRIPTION,
			dbo.fn_DisplayBoolean(I.EARLIESTDATEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			I.RELATIONSHIPDESC,
			I.POINTERTOPARENT,
			C.RELATIONSHIP,
			E1.EVENTDESCRIPTION,
			E4.EVENTDESCRIPTION,
			E5.EVENTDESCRIPTION,
			dbo.fn_DisplayBoolean(C.EARLIESTDATEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			C.RELATIONSHIPDESC,
			C.POINTERTOPARENT
		from "+@sUserName+".Imported_CASERELATION I
		left join "+@sUserName+".Imported_EVENTS E	on(E.EVENTNO=I.EVENTNO)
		left join "+@sUserName+".Imported_EVENTS E2	on(E2.EVENTNO=I.FROMEVENTNO)
		left join "+@sUserName+".Imported_EVENTS E3	on(E3.EVENTNO=I.DISPLAYEVENTNO)"
		Set @sSQLString4="	join CASERELATION C	on( C.RELATIONSHIP=I.RELATIONSHIP)
		left join EVENTS E1	on(E1.EVENTNO=C.EVENTNO)
		left join EVENTS E4	on(E4.EVENTNO=C.FROMEVENTNO)
		left join EVENTS E5	on(E5.EVENTNO=C.DISPLAYEVENTNO)
		where 	I.EARLIESTDATEFLAG<>C.EARLIESTDATEFLAG OR (I.EARLIESTDATEFLAG is null and C.EARLIESTDATEFLAG is not null) OR (I.EARLIESTDATEFLAG is not null and C.EARLIESTDATEFLAG is null)
		OR	I.POINTERTOPARENT<>C.POINTERTOPARENT   OR (I.POINTERTOPARENT  is null and C.POINTERTOPARENT  is not null) OR (I.POINTERTOPARENT  is not null and C.POINTERTOPARENT  is null)"
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.RELATIONSHIP,
			E.EVENTDESCRIPTION,
			E2.EVENTDESCRIPTION,
			E3.EVENTDESCRIPTION,		
			dbo.fn_DisplayBoolean(I.EARLIESTDATEFLAG,"+CASE WHEN(@psCulture is null) THEN 'DEFAULT' ELSE "'"+ @psCulture+"'" END +",0),
			I.RELATIONSHIPDESC,
			I.POINTERTOPARENT,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_CASERELATION I
		left join "+@sUserName+".Imported_EVENTS E	on(E.EVENTNO=I.EVENTNO)
		left join "+@sUserName+".Imported_EVENTS E2	on(E2.EVENTNO=I.FROMEVENTNO)
		left join "+@sUserName+".Imported_EVENTS E3	on(E3.EVENTNO=I.DISPLAYEVENTNO)"
		Set @sSQLString6="	left join CASERELATION C on( C.RELATIONSHIP=I.RELATIONSHIP)
		where C.RELATIONSHIP is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3" ELSE "3" END
	
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

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update CASERELATION
		set	EARLIESTDATEFLAG=I.EARLIESTDATEFLAG,
			POINTERTOPARENT=I.POINTERTOPARENT
		from	CASERELATION C
		join	"+@sUserName+".Imported_CASERELATION I	on ( I.RELATIONSHIP=C.RELATIONSHIP)
		where 	I.EARLIESTDATEFLAG<>C.EARLIESTDATEFLAG OR (I.EARLIESTDATEFLAG is null and C.EARLIESTDATEFLAG is not null) OR (I.EARLIESTDATEFLAG is not null and C.EARLIESTDATEFLAG is null)
		OR	I.POINTERTOPARENT<>C.POINTERTOPARENT OR (I.POINTERTOPARENT is null and C.POINTERTOPARENT is not null) OR (I.POINTERTOPARENT is not null and C.POINTERTOPARENT is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into CASERELATION(
			RELATIONSHIP,
			EVENTNO,
			EARLIESTDATEFLAG,
			SHOWFLAG,
			RELATIONSHIPDESC,
			POINTERTOPARENT,
			FROMEVENTNO,
			DISPLAYEVENTNO)
		select	I.RELATIONSHIP,
			I.EVENTNO,
			I.EARLIESTDATEFLAG,
			I.SHOWFLAG,
			I.RELATIONSHIPDESC,
			I.POINTERTOPARENT,
			E4.EVENTNO,
			E5.EVENTNO
		from "+@sUserName+".Imported_CASERELATION I
		left join CASERELATION C on ( C.RELATIONSHIP=I.RELATIONSHIP)
		left join EVENTS E4	 on(E4.EVENTNO=C.FROMEVENTNO)
		left join EVENTS E5	 on(E5.EVENTNO=C.DISPLAYEVENTNO)
		where C.RELATIONSHIP is null"

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
	Set @sSQLString="
	select RELATIONSHIP,'{'+RELATIONSHIP+'}'+RELATIONSHIPDESC
	from CASERELATION
	order by RELATIONSHIP"

	select @sSQLString
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End


-- @pnFunction = 4 supplies the statement to list the imported keys and any existing mapping.
If  @ErrorCode=0
and @pnFunction=4
Begin
	-- Mapping has already been done and stored in the table.
	Set @sSQLString1="
	select	I.ORIGINAL_KEY,
		I.RELATIONSHIPDESC,
		CASE WHEN (I.RELATIONSHIP = I.ORIGINAL_KEY)THEN NULL 
			ELSE I.RELATIONSHIP END
	from "+@sUserName+".Imported_CASERELATION I
	left join CASERELATION C on C.RELATIONSHIP = I.RELATIONSHIP
	order by 1"

	select @sSQLString1
	
	Select	@ErrorCode=@@Error,
		@pnRowCount=@@rowcount
End


-- @pnFunction = 5 add/updates the existing mapping based on the supplied XML

If  @ErrorCode=0
and @pnFunction=5
and @pnSourceNo is not null
and @psChangeList is not null

Begin
	-- First collect the data from the XML that has been passed as an XML parameter using 'OPENXML' functionality.
	Exec 	sp_xml_preparedocument  @hDocument OUTPUT, @psChangeList
	Set 	@ErrorCode = @@Error
	-- <DataMap><DataMapChange><SourceValue><StoredMapValue><NewMapValue><DataMapChange><DataMap>
	-- First delete any previous mappings for values being given new mappings.
	
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
			DELETE FROM DATAMAP
			WHERE SOURCENO = @pnSourceNo
			AND MAPTABLE = 'CASERELATION'
			AND MAPCOLUMN = 'RELATIONSHIP'
			AND SOURCEVALUE IN (
				SELECT SOURCEVALUE
				FROM  OPENXML(@hDocument, '//DataMapChange', 2)
				WITH (SOURCEVALUE nvarchar(50)'SourceValue/text()',
				      STOREDMAPVALUE nvarchar(50)'StoredMapValue/text()')
				WHERE STOREDMAPVALUE IS NOT NULL)"

		exec @ErrorCode=sp_executesql @sSQLString,
			N'@hDocument	int,
			  @pnSourceNo int',
			  @hDocument 	= @hDocument,
 			  @pnSourceNo   = @pnSourceNo

		Set @pnRowCount=@@rowcount
	End 


	If @ErrorCode=0
	Begin
		-- Now insert the new mappings (unless identical)
		Set @sSQLString= "
		Insert into DATAMAP(
			SOURCENO,
			SOURCEVALUE,
			MAPTABLE,
			MAPCOLUMN,
			MAPVALUE)
		select	
			@pnSourceNo,
			XDM.SOURCEVALUE,
			'CASERELATION',
			'RELATIONSHIP',
			XDM.NEWMAPVALUE
			from OPENXML(@hDocument, '//DataMapChange', 2)
			with (SOURCEVALUE nvarchar(50)'SourceValue/text()',
			      NEWMAPVALUE nvarchar(50)'NewMapValue/text()') XDM
			left join DATAMAP DM on (DM.SOURCENO = @pnSourceNo
					     and DM.SOURCEVALUE = XDM.SOURCEVALUE
					     and DM.MAPTABLE = 'CASERELATION'
					     and DM.MAPCOLUMN = 'RELATIONSHIP')
			where XDM.SOURCEVALUE != XDM.NEWMAPVALUE
			and DM.SOURCENO is null"
	
		exec @ErrorCode=sp_executesql @sSQLString,
			N'@hDocument	int,
			  @pnSourceNo int',
			  @hDocument 	= @hDocument,
 			  @pnSourceNo   = @pnSourceNo
	
		Set @pnRowCount=@pnRowCount+@@rowcount
	End

	Exec sp_xml_removedocument @hDocument
End

RETURN @ErrorCode
go
grant execute on dbo.ip_RulesCASERELATION  to public
go

