-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_SqlSelectList
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[fn_SqlSelectList]') and xtype in (N'FN', N'IF', N'TF'))
begin
	print '**** Drop Function dbo.fn_SqlSelectList.'
	drop function [dbo].[fn_SqlSelectList]
	print '**** Creating Function dbo.fn_SqlSelectList...'
	print ''
end
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_SqlSelectList
	(
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10),	-- The language in which the output is to be expressed
	@pbCalledFromCentura	bit,		-- Indicates whether the procedure is being used from Centura
	@psTableName		nvarchar(30),	-- Name of database table the list is to be obtained from
	@psKeyColumnName	nvarchar(30),	-- Name of column that represents the key
	@psCodeColumnName	nvarchar(30),	-- Name of column to be shown in list as a CODE.
	@psDescriptionColumnName nvarchar(30)	-- Name of column to be shown in list as DESCRIPTION
	)
Returns nvarchar(max)

-- FUNCTION :	fn_SqlSelectList
-- VERSION :	4
-- DESCRIPTION:	Returns SQL to produce a Select list consisting of KEYVALUE, CODE and DESCRIPTION columns.
--		The returned SQL might be used to populate a drop down list, or as a derived table to be 
--		used in a large statement.

-- MODIFICTIONS :
-- Date         Who	Version	Change	Description
-- ------------ ----	-------	------	------------------------------------- 
-- 06 Sep 2005	MF	1	11685	Function created
-- 15 Sep 2005	JEK	2	11685	Ensure that Code column is a string.
-- 12 Oct 2006	JEK	3	13614	Ensure that the Key value is unique (particularly for use with CASECATEGORY).
-- 14 Apr 2011	MF	4	10475	Change nvarchar(4000) to nvarchar(max)
as
Begin
	Declare @sSQLString 	nvarchar(max)

	Set @sSQLString='Select '+@psKeyColumnName+' as KEYVALUE, '+
		case when @psCodeColumnName is null then 'NULL'
		     else 'cast('+@psCodeColumnName+' as nvarchar(50))'
		end +' as CODE, '

	-- If there is a DESCRIPTION column then check to see if a translation
	-- is required
	If @psDescriptionColumnName is null
		Set @sSQLString=@sSQLString+'NULL'
	Else
		Set @sSQLString=@sSQLString+'min('+dbo.fn_SqlTranslatedColumn(	@psTableName,
									@psDescriptionColumnName,
									default,
									default,
									@psCulture,
									@pbCalledFromCentura)+')'

	Set @sSQLString=@sSQLString+' as DESCRIPTION'

	Set @sSQLString=@sSQLString+char(10)+'		From '+@psTableName

	-- SQA13614 Ensure that a unique set of key (and possibly code) values are returned.
	Set @sSQLString=@sSQLString+char(10)+'		Group by '+@psKeyColumnName

	If @psCodeColumnName is not null
		Set @sSQLString=@sSQLString+', '+@psCodeColumnName

	-- Now return the constructed SELECT

	Return @sSQLString
End
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant execute on dbo.fn_SqlSelectList to public
GO
