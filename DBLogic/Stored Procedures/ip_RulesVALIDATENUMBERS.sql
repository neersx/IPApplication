-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ip_RulesVALIDATENUMBERS
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ip_RulesVALIDATENUMBERS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.ip_RulesVALIDATENUMBERS.'
	drop procedure dbo.ip_RulesVALIDATENUMBERS
	print '**** Creating procedure dbo.ip_RulesVALIDATENUMBERS...'
	print ''
end
go


SET QUOTED_IDENTIFIER OFF 
go


CREATE PROCEDURE dbo.ip_RulesVALIDATENUMBERS
	@pnRowCount			int 		= 0	OUTPUT,
	@pnUserIdentityId		int		= null,	-- included for use by .NET
	@psCulture			nvarchar(10)	= null, -- the language in which output is to be expressed
	@pnFunction			int		= 1, 	-- the specific behaviour required of the stored procedure on this occasion
	@psUserName			nvarchar(40)	= 'dbo', -- the current user name which will have created the 'Imported_' tables dbo used as default for security error instead of crash
	@pnSourceNo			int		= null, --  Name No - source of import file
	@psChangeList			ntext		= null, --  XML 'table' listing values to be updated
	@pnOrderBy			tinyint		= 2	-- 1-Result; 2-Code
	
AS

-- PROCEDURE :	ip_RulesVALIDATENUMBERS
-- VERSION :	4
-- DESCRIPTION:	The comparison/display and merging of imported data for the VALIDATENUMBERS table
-- CALLED BY :	

-- MODIFICATION
-- Date		Who	Number	Version	Description
-- ----         ---	------	-------	-----------------------------------------------------------
-- 20 Jul 2004	MF		1	Procedure created
-- 03 Oct 2007	MF	15417	2	Do not update existing VALIDATENUMBERS rows.
-- 11 Jan 2008	MF	15417	3	Revisit to correct problem
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


-- Prerequisite that the IMPORTED_VALIDATENUMBERS table has been loaded

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
		"UPDATE "+@sUserName+".Imported_VALIDATENUMBERS
		SET COUNTRYCODE = M.MAPVALUE
		FROM "+@sUserName+".Imported_VALIDATENUMBERS C
		JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
				and M.MAPTABLE   ='COUNTRY'
				and M.MAPCOLUMN  ='COUNTRYCODE'
				and M.SOURCEVALUE=C.COUNTRYCODE)
		WHERE M.MAPVALUE is not null"

	exec @ErrorCode=sp_executesql @sSQLString

	If @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDATENUMBERS
			SET PROPERTYTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDATENUMBERS C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='PROPERTYTYPE'
					and M.MAPCOLUMN  ='PROPERTYTYPE'
					and M.SOURCEVALUE=C.PROPERTYTYPE)
			WHERE M.MAPVALUE is not null"
	
		exec @ErrorCode=sp_executesql @sSQLString
	End

	If @ErrorCode=0
	Begin
		Set @sSQLString=
			"UPDATE "+@sUserName+".Imported_VALIDATENUMBERS
			SET NUMBERTYPE = M.MAPVALUE
			FROM "+@sUserName+".Imported_VALIDATENUMBERS C
			JOIN DATAMAP M	on (M.SOURCENO   ="+CAST(@pnSourceNo AS NVARCHAR(20))+"
					and M.MAPTABLE   ='NUMBERTYPES'
					and M.MAPCOLUMN  ='NUMBERTYPE'
					and M.SOURCEVALUE=C.NUMBERTYPE)
			WHERE M.MAPVALUE is not null"
	
		exec @ErrorCode=sp_executesql @sSQLString
	End
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
			I.PROPERTYTYPE		as 'Imported Property',
			N.DESCRIPTION		as 'Imported Number Type',
			I.VALIDFROM		as 'Imported Valid From',
			I.PATTERN		as 'Imported Pattern',
			CASE(I.WARNINGFLAG) WHEN(1) THEN 'Warning' ELSE 'Error' END as 'Imported Warning/Error',
			I.ERRORMESSAGE		as 'Imported Error Message',
			T.DESCRIPTION 		as 'Imported Procedure',
			C.COUNTRYCODE		as 'Country',
			C.PROPERTYTYPE		as 'Property',
			N.DESCRIPTION		as 'Number Type',
			C.VALIDFROM		as 'Valid From',
			C.PATTERN		as 'Pattern',
			CASE(C.WARNINGFLAG) WHEN(1) THEN 'Warning' ELSE 'Error' END as 'Warning/Error',
			C.ERRORMESSAGE		as 'Error Message',
			T.DESCRIPTION		as 'Procedure'
		from "+@sUserName+".Imported_VALIDATENUMBERS I
		join "+@sUserName+".Imported_NUMBERTYPES N	on (N.NUMBERTYPE=I.NUMBERTYPE)"
		Set @sSQLString2="	join VALIDATENUMBERS C	on (C.COUNTRYCODE=I.COUNTRYCODE
								and C.PROPERTYTYPE=I.PROPERTYTYPE
								and C.NUMBERTYPE=I.NUMBERTYPE
								and(C.VALIDFROM=I.VALIDFROM OR (C.VALIDFROM is null and I.VALIDFROM is null)))
		left join "+@sUserName+".Imported_TABLECODES T on (T.TABLECODE=I.VALIDATINGSPID)
		where	(I.PATTERN=C.PATTERN)
		and	(I.VALIDATINGSPID=C.VALIDATINGSPID OR (I.VALIDATINGSPID is null and C.VALIDATINGSPID is null))"
/******** SQA 15417 comment out UPDATE so as not overwrite user changes
		Set @sSQLString3="
		UNION ALL
		select	2,
			'O',
			I.COUNTRYCODE,
			I.PROPERTYTYPE,
			N.DESCRIPTION,
			I.VALIDFROM,
			I.PATTERN,
			CASE(I.WARNINGFLAG) WHEN(1) THEN 'Warning' ELSE 'Error' END,
			I.ERRORMESSAGE,
			T.DESCRIPTION,
			C.COUNTRYCODE,
			C.PROPERTYTYPE,
			N.DESCRIPTION,
			C.VALIDFROM,
			C.PATTERN,
			CASE(C.WARNINGFLAG) WHEN(1) THEN 'Warning' ELSE 'Error' END,
			C.ERRORMESSAGE,
			T1.DESCRIPTION
		from "+@sUserName+".Imported_VALIDATENUMBERS I
		join "+@sUserName+".Imported_NUMBERTYPES N	on (N.NUMBERTYPE=I.NUMBERTYPE)
		left join "+@sUserName+".Imported_TABLECODES T on (T.TABLECODE=I.VALIDATINGSPID)"
		Set @sSQLString4="	join VALIDATENUMBERS C	on (C.COUNTRYCODE=I.COUNTRYCODE
								and C.PROPERTYTYPE=I.PROPERTYTYPE
								and C.NUMBERTYPE=I.NUMBERTYPE
								and(C.VALIDFROM=I.VALIDFROM OR (C.VALIDFROM is null and I.VALIDFROM is null)))
		left join TABLECODES T1 on (T1.TABLECODE=C.VALIDATINGSPID)
		where 	I.PATTERN<>C.PATTERN
		OR	I.VALIDATINGSPID<>C.VALIDATINGSPID OR (I.VALIDATINGSPID is null and C.VALIDATINGSPID is not null) OR (I.VALIDATINGSPID is not null and C.VALIDATINGSPID is null)"
******** SQA 15417 comment out UPDATE so as not overwrite user changes *************/
		Set @sSQLString5="
		UNION ALL
		select	1,
			'X',
			I.COUNTRYCODE,
			I.PROPERTYTYPE,
			N.DESCRIPTION,
			I.VALIDFROM,
			I.PATTERN,
			CASE(I.WARNINGFLAG) WHEN(1) THEN 'Warning' ELSE 'Error' END,
			I.ERRORMESSAGE,
			T.DESCRIPTION,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null,
			Null
		from "+@sUserName+".Imported_VALIDATENUMBERS I
		join "+@sUserName+".Imported_NUMBERTYPES N	on (N.NUMBERTYPE=I.NUMBERTYPE)
		left join "+@sUserName+".Imported_TABLECODES T on (T.TABLECODE=I.VALIDATINGSPID)"
		Set @sSQLString6="	left join VALIDATENUMBERS C	on (C.COUNTRYCODE=I.COUNTRYCODE
									and C.PROPERTYTYPE=I.PROPERTYTYPE
									and C.NUMBERTYPE=I.NUMBERTYPE
									and(C.VALIDFROM=I.VALIDFROM OR (C.VALIDFROM is null and I.VALIDFROM is null)))
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

	/********* SQA 15417 comment out UPDATE so as not overwrite user changes
	If @ErrorCode = 0
	Begin

		-- Update the rows where the key matches but there is some other discrepancy
	
		Set @sSQLString="
		Update VALIDATENUMBERS
		set	PATTERN=I.PATTERN,
			VALIDATINGSPID=I.VALIDATINGSPID
		from	VALIDATENUMBERS C
		join	"+@sUserName+".Imported_VALIDATENUMBERS I	on (I.COUNTRYCODE=C.COUNTRYCODE
									and I.PROPERTYTYPE=C.PROPERTYTYPE
									and I.NUMBERTYPE=C.NUMBERTYPE
									and(I.VALIDFROM=C.VALIDFROM OR (I.VALIDFROM is null and C.VALIDFROM is null)))
		where 	I.PATTERN<>C.PATTERN
		OR	I.VALIDATINGSPID<>C.VALIDATINGSPID OR (I.VALIDATINGSPID is null and C.VALIDATINGSPID is not null) OR (I.VALIDATINGSPID is not null and C.VALIDATINGSPID is null)"
		exec @ErrorCode=sp_executesql @sSQLString

		Set @pnRowCount=@@rowcount
	End 
	*********************************** SQA 15417 */

	If @ErrorCode=0
	Begin

		-- Insert the rows where the key is different.
		Set @sSQLString= "
		Insert into VALIDATENUMBERS(
			VALIDATIONID,
			COUNTRYCODE,
			PROPERTYTYPE,
			NUMBERTYPE,
			VALIDFROM,
			PATTERN,
			WARNINGFLAG,
			ERRORMESSAGE,
			VALIDATINGSPID)
		select	CASE WHEN(V1.VALIDATIONID is null) 
				THEN I.VALIDATIONID
				ELSE isnull(V2.VALIDATIONID,-1)+1
			END,
			I.COUNTRYCODE,
			I.PROPERTYTYPE,
			I.NUMBERTYPE,
			I.VALIDFROM,
			I.PATTERN,
			I.WARNINGFLAG,
			I.ERRORMESSAGE,
			I.VALIDATINGSPID
		from "+@sUserName+".Imported_VALIDATENUMBERS I
		left join VALIDATENUMBERS C	on (C.COUNTRYCODE=I.COUNTRYCODE
						and C.PROPERTYTYPE=I.PROPERTYTYPE
						and C.NUMBERTYPE=I.NUMBERTYPE
						and(C.VALIDFROM=I.VALIDFROM OR (C.VALIDFROM is null and I.VALIDFROM is null)))
		left join VALIDATENUMBERS V1	on (V1.VALIDATIONID=I.VALIDATIONID)
		cross join (select max(VALIDATIONID) as VALIDATIONID
			   from VALIDATENUMBERS) V2
		where C.VALIDATIONID is null"

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
grant execute on dbo.ip_RulesVALIDATENUMBERS  to public
go

