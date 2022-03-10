-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_GetConcatenatedAttributes
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_GetConcatenatedAttributes') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_GetConcatenatedAttributes'
	Drop function [dbo].[fn_GetConcatenatedAttributes]
End
Print '**** Creating Function dbo.fn_GetConcatenatedAttributes...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_GetConcatenatedAttributes
(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10)	= null,	-- The language in which output is to be expressed.
	@pbCalledFromCentura	bit		= 0, 	-- Indicates whether called from Centura.
	@psParentTable		nvarchar(50)	= null, -- The parent table the attributes relates to; e.g. CASES, NAME, COUNTRY.
	@psGenericKey		nvarchar(20)	= null,	-- The primary key of the parent table.
	@psSeparator		nvarchar(20)	= null	-- The character to use between multiple attributes returned.
) 
RETURNS nvarchar(max)
AS
-- Function :	fn_GetConcatenatedAttributes
-- VERSION :	3
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Returns a list of attributes formatted as <Type> - <Value>. 
--		Multiple attributes are concatenated together into a single field in Type then Value order.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 04 Jul 2005	TM	RFC1480	1	Function created
-- 06 Jul 2005	TM	RFC1480	2	Correct the translation checking.
-- 14 Apr 2011	MF	RFC10475 3	Change nvarchar(4000) to nvarchar(max)

Begin
	Declare @sLookupCulture nvarchar(10)
	Declare @sResult 	nvarchar(max)
	Declare @tblString	table (Result nvarchar(500) collate database_default NULL)

	Set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)
	Set @sResult = N''

	-- Is a translation required?
	If @sLookupCulture is not null
	and (dbo.fn_GetTranslatedTIDColumn('TABLETYPE','TABLENAME') is not null
	 or dbo.fn_GetTranslatedTIDColumn('OFFICE','DESCRIPTION') is not null
	 or dbo.fn_GetTranslatedTIDColumn('TABLECODES','DESCRIPTION') is not null)
	Begin
		-- If called from Centura, use the fn_GetTranslationLimited function:
		If @pbCalledFromCentura = 1
		Begin		
			Insert into @tblString (Result)
			Select	dbo.fn_GetTranslationLimited(TY.TABLENAME,null,TY.TABLENAME_TID,@sLookupCulture) + ' - ' +
				CASE WHEN TY.DATABASETABLE = 'OFFICE'			   
				     THEN dbo.fn_GetTranslationLimited(O.DESCRIPTION,null,O.DESCRIPTION_TID,@sLookupCulture)			  
				     ELSE dbo.fn_GetTranslationLimited(A.DESCRIPTION,null,A.DESCRIPTION_TID,@sLookupCulture)
				END as String
			from TABLEATTRIBUTES T
			join TABLETYPE TY 	on (TY.TABLETYPE = T.TABLETYPE)
			left join TABLECODES A 	on (A.TABLECODE = T.TABLECODE)
			left join OFFICE O	on (O.OFFICEID = T.TABLECODE)
			where 	T.PARENTTABLE = @psParentTable
			and	T.GENERICKEY  = @psGenericKey
			order by dbo.fn_GetTranslationLimited(TY.TABLENAME,null,TY.TABLENAME_TID,@sLookupCulture),
				CASE WHEN TY.DATABASETABLE = 'OFFICE'			   
				     THEN dbo.fn_GetTranslationLimited(O.DESCRIPTION,null,O.DESCRIPTION_TID,@sLookupCulture)			  
				     ELSE dbo.fn_GetTranslationLimited(A.DESCRIPTION,null,A.DESCRIPTION_TID,@sLookupCulture)
				END	
		
			Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
			from @tblString
			order by Result		
		End
		Else Begin	
			-- If called from WorkBenches, use standard fn_GetTranslation function:
			Insert into @tblString (Result)
			Select	dbo.fn_GetTranslation(TY.TABLENAME,null,TY.TABLENAME_TID,@sLookupCulture) + ' - ' +
				CASE WHEN TY.DATABASETABLE = 'OFFICE'			   
				     THEN dbo.fn_GetTranslation(O.DESCRIPTION,null,O.DESCRIPTION_TID,@sLookupCulture)			  
				     ELSE dbo.fn_GetTranslation(A.DESCRIPTION,null,A.DESCRIPTION_TID,@sLookupCulture)
				END as String
			from TABLEATTRIBUTES T
			join TABLETYPE TY 	on (TY.TABLETYPE = T.TABLETYPE)
			left join TABLECODES A 	on (A.TABLECODE = T.TABLECODE)
			left join OFFICE O	on (O.OFFICEID = T.TABLECODE)
			where 	T.PARENTTABLE = @psParentTable
			and	T.GENERICKEY  = @psGenericKey
			order by dbo.fn_GetTranslation(TY.TABLENAME,null,TY.TABLENAME_TID,@sLookupCulture),
				CASE WHEN TY.DATABASETABLE = 'OFFICE'			   
				     THEN dbo.fn_GetTranslation(O.DESCRIPTION,null,O.DESCRIPTION_TID,@sLookupCulture)			  
				     ELSE dbo.fn_GetTranslation(A.DESCRIPTION,null,A.DESCRIPTION_TID,@sLookupCulture)
				END	
		
			Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
			from @tblString
			order by Result			
		End
	End
	-- No translation required
	Else
	Begin
		Insert into @tblString (Result)
		Select	TY.TABLENAME + ' - ' +
			CASE WHEN TY.DATABASETABLE = 'OFFICE'			   
			     THEN O.DESCRIPTION	  
			     ELSE A.DESCRIPTION
			END 
		from TABLEATTRIBUTES T
		join TABLETYPE TY 	on (TY.TABLETYPE = T.TABLETYPE)
		left join TABLECODES A 	on (A.TABLECODE = T.TABLECODE)
		left join OFFICE O	on (O.OFFICEID = T.TABLECODE)
		where 	T.PARENTTABLE = @psParentTable
		and	T.GENERICKEY  = @psGenericKey
		order by TY.TABLENAME,
			CASE WHEN TY.DATABASETABLE = 'OFFICE'			   
			     THEN O.DESCRIPTION	  
			     ELSE A.DESCRIPTION
			END	
	
		Select @sResult = nullif(@sResult+@psSeparator, @psSeparator) + Result
		from @tblString
		order by Result		
	End		
	
	Set @sResult = CASE WHEN @sResult = N'' THEN NULL ELSE @sResult END

	Return @sResult
End
GO

grant execute on dbo.fn_GetConcatenatedAttributes to public
go
