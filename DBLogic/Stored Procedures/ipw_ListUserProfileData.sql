-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_ListUserProfileData
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[ipw_ListUserProfileData]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.ipw_ListUserProfileData.'
	Drop procedure [dbo].[ipw_ListUserProfileData]
End
Print '**** Creating Stored Procedure dbo.ipw_ListUserProfileData...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE dbo.ipw_ListUserProfileData
(
	@pnUserIdentityId	int,		
	@psCulture		nvarchar(10) 	= null,
	@pnProfileKey           int             = null,            
	@pbCalledFromCentura	bit		= 0
)
as
-- PROCEDURE:	ipw_ListUserProfileData
-- VERSION:	7
-- COPYRIGHT:	Copyright CPA Global Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Return information regarding the specified user profile and attached attributes.

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 09 Sep 2009	LP	RFC8047	1	Procedure created
-- 05 Jan 2010	LP	RFC8450	2	Return ProfilePrograms result set
-- 08 Jan 2010	LP	RFC8525	3	Include Default CRM Name Program in Attributes result set
-- 14 jan 2010	LP	RFC8450	4	Fix Programs logic using Union All.
-- 26 Jul 2008	DV	R100308	5	Return an additional Column AttributeValueKey in ProfileAttributes result set
-- 15 Apr 2013	DV	R13270	6	Increase the length of nvarchar to 11 when casting or declaring integer
-- 02 Dec 2014	LP	R14176	7	Return programs with parent program belonging to the group

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare	@nErrorCode	int
declare @sSQLString     nvarchar(4000)
Declare @sLookupCulture		nvarchar(10)

set @sLookupCulture = dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

-- Initialise variables
Set @nErrorCode = 0

-- Return UserProfile result set
If @nErrorCode = 0
Begin
        If @pnProfileKey is not null
        Begin
                Set @sSQLString = "select  
	        PR.PROFILEID as ProfileKey,"+
                dbo.fn_SqlTranslatedColumn('PROFILES','PROFILENAME',null,'PR',@sLookupCulture,@pbCalledFromCentura)+ " as ProfileName,"+CHAR(10)+
                dbo.fn_SqlTranslatedColumn('PROFILES','DESCRIPTION',null,'PR',@sLookupCulture,@pbCalledFromCentura)+ " as Description"+CHAR(10)+	        	
                "from PROFILES PR
	        where PROFILEID = @pnProfileKey"
	        
	        exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnProfileKey         int',
		  @pnProfileKey         = @pnProfileKey	
	End
	Else
	Begin
	        Set @sSQLString = "select  
	        ISNULL(MAX(PR.PROFILEID),1) + 1 as ProfileKey,
	        NULL as ProfileName,
                NULL as Description"+CHAR(10)+	        	
                "from PROFILES PR"
                
                exec @nErrorCode = sp_executesql @sSQLString
	End
		
End

-- Return ProfileAttributes result set
If @nErrorCode = 0
and @pnProfileKey is not null
Begin
        Set @sSQLString = "select  
		convert(nvarchar(11),P.PROFILEID) +'^'+ convert(nvarchar(11),A.ATTRIBUTEID) as RowKey,
	        P.PROFILEID as ProfileKey,
	        A.ATTRIBUTENAME as AttributeName,
	        I.IMPORTANCEDESC as AttributeValue,
			PA.ATTRIBUTEVALUE as AttributeValueKey,
	        A.ATTRIBUTEID as AttributeKey,
	        A.DATATYPE as Type
		from PROFILES P
	        join PROFILEATTRIBUTES PA on (PA.PROFILEID = P.PROFILEID)
	        join ATTRIBUTES A on (A.ATTRIBUTEID = PA.ATTRIBUTEID)
	        join IMPORTANCE I on (I.IMPORTANCELEVEL = PA.ATTRIBUTEVALUE)
	        where P.PROFILEID = @pnProfileKey
	        and PA.ATTRIBUTEID = 1
	        
	        UNION
	        
	        select  
		convert(nvarchar(11),P.PROFILEID) +'^'+ convert(nvarchar(11),A.ATTRIBUTEID) as RowKey,
	        P.PROFILEID as ProfileKey,
	        A.ATTRIBUTENAME as AttributeName,
	        PR.PROGRAMNAME as AttributeValue,
			PA.ATTRIBUTEVALUE as AttributeValueKey,
	        A.ATTRIBUTEID as AttributeKey,
	        A.DATATYPE as Type
		from PROFILES P
	        join PROFILEATTRIBUTES PA on (PA.PROFILEID = P.PROFILEID)
	        join ATTRIBUTES A on (A.ATTRIBUTEID = PA.ATTRIBUTEID)
	        join PROGRAM PR on (PR.PROGRAMID= PA.ATTRIBUTEVALUE)
	        where P.PROFILEID = @pnProfileKey
	        and PA.ATTRIBUTEID in (2,3,4)
	        "
	        
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnProfileKey         int',
		  @pnProfileKey         = @pnProfileKey		
End

-- Return ProfilePrograms result set
If @nErrorCode = 0
and @pnProfileKey is not null
Begin
	Set @sSQLString = 
	        'select convert(nvarchar(11),P.PROFILEID) +''^''+ convert(nvarchar(11),PR.PROGRAMID) as RowKey,
		P.PROFILEID as ProfileKey,
		P.PROGRAMID as ProgramKey,
		PR.PROGRAMNAME as ProgramName,
		''C'' as ProgramGroup,
		CASE WHEN ((P.PROGRAMID=PA.ATTRIBUTEVALUE) OR (PA.ATTRIBUTEVALUE IS NULL AND P.PROGRAMID = SCC.COLCHARACTER)) THEN convert(bit,1)
		ELSE convert(bit,0)
		END as IsDefault
		from PROGRAM PR
		join PROFILEPROGRAM P on (PR.PROGRAMID = P.PROGRAMID)
		left join PROFILEATTRIBUTES PA on (PA.PROFILEID = P.PROFILEID and PA.ATTRIBUTEID = 2)
		left join SITECONTROL SCC on (SCC.CONTROLID = ''Case Screen Default Program'')
		left join PROGRAM PP on (PR.PARENTPROGRAM = PP.PROGRAMID)
		where P.PROFILEID = @pnProfileKey
		and (PR.PROGRAMGROUP = ''C'' OR PP.PROGRAMGROUP = ''C'')

		union all

		select convert(nvarchar(11),P.PROFILEID) +''^''+ convert(nvarchar(11),PR.PROGRAMID) as RowKey,
				P.PROFILEID as ProfileKey,
				P.PROGRAMID as ProgramKey,
				PR.PROGRAMNAME as ProgramName,
				''N'' as ProgramGroup,
		CASE WHEN ((P.PROGRAMID=PA.ATTRIBUTEVALUE) OR (PA.ATTRIBUTEVALUE IS NULL AND P.PROGRAMID = SCN.COLCHARACTER)) THEN convert(bit,1)
		ELSE convert(bit,0)
		END as IsDefault
		from PROGRAM PR
		join PROFILEPROGRAM P on (PR.PROGRAMID = P.PROGRAMID)
		left join PROFILEATTRIBUTES PA on (PA.PROFILEID = P.PROFILEID and PA.ATTRIBUTEID = 3)
		left join SITECONTROL SCN on (SCN.CONTROLID = ''Name Screen Default Program'')
		left join PROGRAM PP on (PR.PARENTPROGRAM = PP.PROGRAMID)
		where P.PROFILEID = @pnProfileKey
		and (PR.PROGRAMGROUP = ''N'' OR PP.PROGRAMGROUP = ''N'')'
		
	exec @nErrorCode = sp_executesql @sSQLString,
		N'@pnProfileKey         int',
		  @pnProfileKey         = @pnProfileKey		
End


Return @nErrorCode
GO

Grant execute on dbo.ipw_ListUserProfileData to public
GO
