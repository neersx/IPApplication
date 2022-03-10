---------------------------------------------------------------------------------------------
-- Creation of dbo.p_ListPrograms
---------------------------------------------------------------------------------------------
if exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[p_ListPrograms]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.p_ListPrograms.'
	drop procedure [dbo].p_ListPrograms
	Print '**** Creating Stored Procedure dbo.p_ListPrograms...'
	Print ''
End
go

SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.p_ListPrograms
    @pnUserIdentityId		int 		= null,
    @psCulture			nvarchar(10) 	= null
    
AS
-- PROCEDURE :	p_ListPrograms
-- VERSION :	3
-- DESCRIPTION:	A procedure to return a list of Logical Programs available to the user based his profile

-- MODIFICATIONS :
-- Date  	Who 	RFC# 	Version Change
-- ------------ ------- ---- 	------- ----------------------------------------------- 
-- 03 Mar 2010	JCLG	RFC8953	1	Procedure created
-- 05 Dec 2014	LP	R14176	2	Return programs with parent program belonging to the required Program Group
-- 08 Dec 2014	KR	R14176	3	Fixed the ProgramGroup in the select 


set nocount on
set concat_null_yields_null off
DECLARE		@ErrorCode		int

Declare 	@sSQLString		nvarchar(max)

-- Initialise the errorcode and then set it after each SQL Statement
Set @ErrorCode   = 0

Set @sSQLString = 
'select P.PROGRAMID as ProgramKey,'+char(10)+
'P.PROGRAMNAME as ProgramName,'+char(10)+
'''C'' as ProgramGroup,'+char(10)+
'CASE WHEN ((P.PROGRAMID=PA.ATTRIBUTEVALUE) OR (PA.ATTRIBUTEVALUE IS NULL AND P.PROGRAMID=SC.COLCHARACTER)) THEN convert(bit,1)'+char(10)+
'ELSE convert(bit,0)'+char(10)+
'END as IsDefault'+char(10)+
'from PROGRAM P'+char(10)+
'left join USERIDENTITY UI on (UI.IDENTITYID = @pnUserIdentityId)'+char(10)+
'left join PROFILEPROGRAM PR on (PR.PROFILEID = UI.PROFILEID)'+char(10)+
'left join PROFILEATTRIBUTES PA on (PR.PROFILEID = PA.PROFILEID and PA.ATTRIBUTEID = 2)'+char(10)+
'left join SITECONTROL SC on (SC.CONTROLID = ''Case Screen Default Program'')'+char(10)+
'left join PROGRAM PP on (PP.PROGRAMID = P.PARENTPROGRAM)'+char(10)+
'where (P.PROGRAMGROUP = ''C'' or PP.PROGRAMGROUP = ''C'')'+char(10)+
'and P.PROGRAMID = PR.PROGRAMID'+char(10)+

'union all'+char(10)+
	
'select P.PROGRAMID as ProgramKey,'+char(10)+
'P.PROGRAMNAME as ProgramName,'+char(10)+
'''N'' as ProgramGroup,'+char(10)+
'CASE WHEN ((P.PROGRAMID=PA.ATTRIBUTEVALUE) OR (PA.ATTRIBUTEVALUE IS NULL AND P.PROGRAMID = SC.COLCHARACTER)) THEN convert(bit,1)'+char(10)+
'ELSE convert(bit,0)'+char(10)+
'END as IsDefault'+char(10)+
'from PROGRAM P'+char(10)+
'left join USERIDENTITY UI on (UI.IDENTITYID = @pnUserIdentityId)'+char(10)+
'left join PROFILEPROGRAM PR on (PR.PROFILEID = UI.PROFILEID)'+char(10)+
'left join PROFILEATTRIBUTES PA on (PR.PROFILEID = PA.PROFILEID and PA.ATTRIBUTEID = 3)'+char(10)+
'left join SITECONTROL SC on (SC.CONTROLID = ''Case Name Default Program'')'+char(10)+
'left join PROGRAM PP on (PP.PROGRAMID = P.PARENTPROGRAM)'+char(10)+
'where (P.PROGRAMGROUP = ''N'' or PP.PROGRAMGROUP = ''N'')'+char(10)+
'and P.PROGRAMID = PR.PROGRAMID'

exec @ErrorCode = sp_executesql @sSQLString,
		N'@pnUserIdentityId   		int',
		  @pnUserIdentityId	= @pnUserIdentityId

return @ErrorCode
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

grant exec on dbo.p_ListPrograms to public
go
