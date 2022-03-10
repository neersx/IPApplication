----------------------------------------------------------------------------------------------
-- Creation of dbo.na_ListAttributes
----------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[na_ListAttributes]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop Stored Procedure dbo.na_ListAttributes.'
	drop procedure [dbo].[na_ListAttributes]
	print '**** Creating Stored Procedure dbo.na_ListAttributes...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

create   PROCEDURE dbo.na_ListAttributes

-- PROCEDURE :	na_ListAttributes
-- VERSION :	5
-- DESCRIPTON:	Populate the Attributes table in the NameDetails typed dataset.
-- CALLED BY :	

-- MODIFICTION HISTORY:
-- Date         Who  	Number	Version	Change
-- ------------ ---- 	------	-------	------------------------------------------- 
-- 18/06/2002	SF			Procedure created	
-- 31/12/2003	TM	RFC631	5	Display an appropriate description if an Office attribute is chosen.

	@pnUserIdentityId		int,			-- Mandatory
	@psCulture			nvarchar(10) = null,  	-- the language in which output is to be expressed
	@pnNameNo			int
AS
begin
	-- disable row counts
	set nocount on
	set concat_null_yields_null off

	-- declare variables
	declare	@ErrorCode	int

	select @ErrorCode=0
	
	If @ErrorCode=0
	begin

		select 	
		ATTRTYPE.TABLENAME			as 'AttributeTypeDescription',
		ISNULL(ATTR.DESCRIPTION, O.DESCRIPTION)	as 'AttributeDescription'
		from TABLEATTRIBUTES T
		left join TABLETYPE ATTRTYPE 	on (T.TABLETYPE = ATTRTYPE.TABLETYPE)
		left join OFFICE O		on (O.OFFICEID = T.TABLECODE)						
		left join TABLECODES ATTR 	on (T.TABLECODE = ATTR.TABLECODE)
		where T.PARENTTABLE = 'NAME'
		and	Cast(T.GENERICKEY as int) = @pnNameNo
	
	End

	
	RETURN @ErrorCode
end
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.na_ListAttributes to public
go
