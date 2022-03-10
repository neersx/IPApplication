-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesINHERITS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesINHERITS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesINHERITS.'
	drop procedure dbo.ip_RulesINHERITS
	print '**** Creating procedure dbo.ip_RulesINHERITS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesINHERITS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesINHERITS
-- VERSION :	5
-- DESCRIPTION:	The comparison/display and merging of imported data for the INHERITS table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 28 Jul 2004	MF	10224	2	Need to remove INHERITS rows that do not exist in the 
--					imported table but do exists in the imported CRITERIA table.
-- 21 Jan 2011	MF	19321	3	Data columns that are not to be replaced will now be reported with the client data 
--					so as not be highlighted as a difference through the user interface.
-- 12 Jul 2013	MF	R13596	4	Cater for a new rule where PURPOSECODE='X' which is used to define rules that allow or
--					block the importing of law update services rules.
-- 06 Nov 2013	MF	R28126	5	Revisit of RFC13596. Cannot use "#TEMPCRITERIA as this is out of scope when SQL is executed from
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


-- Prerequisite that the IMPORTED_INHERITS table has been loaded

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

-- Function 1 - Data Comparison
If @ErrorCode=0 
and @pnFunction=1
Begin
	-- Return result set of imported data with current live data
	If  @ErrorCode=0
	Begin
		Set @sSQLString1="
		select	3		as 'Comparison',
			NULL		as Match,
			CC.DESCRIPTION+' {'+convert(varchar,I.CRITERIANO)+'}'   as 'Imported Criteria No',
			CP.DESCRIPTION+' {'+convert(varchar,I.FROMCRITERIA)+'}' as 'Imported From Criteria',
			CC.DESCRIPTION+' {'+convert(varchar,C.CRITERIANO)+'}'   as 'Criteria No',
			CP.DESCRIPTION+' {'+convert(varchar,C.FROMCRITERIA)+'}' as 'From Criteria'
		from "+@sUserName+".Imported_INHERITS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)"
		Set @sSQLString2="
		join INHERITS C	on( C.CRITERIANO=I.CRITERIANO
				and C.FROMCRITERIA=I.FROMCRITERIA)
		join CRITERIA CC on (CC.CRITERIANO=I.CRITERIANO)
		join CRITERIA CP on (CP.CRITERIANO=I.FROMCRITERIA)"
		Set @sSQLString3="
		UNION ALL
		select	1,
			'X',
			CC.DESCRIPTION +' {'+convert(varchar,I.CRITERIANO)+'}',
			CP.DESCRIPTION +' {'+convert(varchar,I.FROMCRITERIA)+'}',
			null,
			null
		from "+@sUserName+".Imported_INHERITS I
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)"
		Set @sSQLString4="	left join INHERITS C on( C.CRITERIANO=I.CRITERIANO
					 and C.FROMCRITERIA=I.FROMCRITERIA)
		join "+@sUserName+".Imported_CRITERIA CC on  (CC.CRITERIANO=I.CRITERIANO)
		join "+@sUserName+".Imported_CRITERIA CP on  (CP.CRITERIANO=I.FROMCRITERIA)
		left join CRITERIA CC1 on (CC.CRITERIANO=C.CRITERIANO)
		left join CRITERIA CP1 on (CP.CRITERIANO=C.FROMCRITERIA)
		where C.CRITERIANO is null
		order by "+CASE WHEN(@pnOrderBy=1) THEN "1,3,4" ELSE "3,4" END
	
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
	-- Remove any INHERITS rows that do not exist in the imported table
	If @ErrorCode = 0
	Begin
		Set @sSQLString="
		Delete INHERITS
		From INHERITS IH
		Join "+@sUserName+".Imported_CRITERIA C	on (C.CRITERIANO=IH.CRITERIANO)
		join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=C.CRITERIANO)
		Left Join "+@sUserName+".Imported_INHERITS I	on (I.CRITERIANO=IH.CRITERIANO
						and I.FROMCRITERIA=IH.FROMCRITERIA)
		Where I.CRITERIANO is null"

		exec @ErrorCode=sp_executesql @sSQLString
	End

	-- Insert the rows where the key is different.
	Set @sSQLString= "
	Insert into INHERITS(
		CRITERIANO,
		FROMCRITERIA)
	select	I.CRITERIANO,
		I.FROMCRITERIA
	from "+@sUserName+".Imported_INHERITS I
	join "+@sUserName+".CRITERIAALLOWED T on (T.CRITERIANO=I.CRITERIANO)
	left join INHERITS C on (C.CRITERIANO=I.CRITERIANO
			     and C.FROMCRITERIA=I.FROMCRITERIA)
	where C.CRITERIANO is null"

	exec @ErrorCode=sp_executesql @sSQLString

	Set @pnRowCount=@pnRowCount+@@rowcount
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
grant execute on dbo.ip_RulesINHERITS  to public
go

