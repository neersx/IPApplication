-----------------------------------------------------------------------------------------------------------------------------
-- Creation of dw_ListAvailableEvents
-----------------------------------------------------------------------------------------------------------------------------
If exists (select * from dbo.sysobjects where id = object_id(N'[dbo].[dw_ListAvailableEvents]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
Begin
	Print '**** Drop Stored Procedure dbo.dw_ListAvailableEvents.'
	Drop procedure [dbo].[dw_ListAvailableEvents]
End
Print '**** Creating Stored Procedure dbo.dw_ListAvailableEvents...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF
GO
-- Allow comparison of null values.
-- Procedure uses setting in place before it's created.
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE dbo.dw_ListAvailableEvents
(
	@pnRowCount		int		= null output,
	@pnUserIdentityId	int,		-- Mandatory
	@psCulture		nvarchar(10) 	= null,	
	@pbCalledFromCentura		bit		= 0,
	@psPickListSearch	nvarchar(30)	= null,
	@pnCaseKey		int, -- Mandatory
	@pnEventKey		int	= null
)
as
-- PROCEDURE:	dw_ListAvailableEvents
-- VERSION:	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	List available events for selection in docketing wizard

-- MODIFICATIONS :
-- Date		Who	Change	Version	Description
-- -----------	-------	------	-------	----------------------------------------------- 
-- 16 JAN 208	SF	RFC5708	1	Procedure created

SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF
-- Reset so that next procedure gets the default.
SET ANSI_NULLS ON

declare	@nErrorCode	int
declare @sLookupCulture	nvarchar(10)
declare @sSQLString nvarchar(4000)
-- Initialise variables
Set @nErrorCode = 0
Set @sLookupCulture 	= dbo.fn_GetLookupCulture(@psCulture, null, @pbCalledFromCentura)

If @nErrorCode = 0
Begin
	Set @sSQLString = "SELECT  
						E.EVENTNO			as 'Key',
						E.EVENTCODE			as Code, "+CHAR(10)+
			dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'V',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					"						as Description,
						E.EVENTNO 			as EventKey, 
						E.EVENTCODE			as EventCode, "+CHAR(10)+
			dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'V',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					"						as EventDescription,
						V.NUMCYCLESALLOWED 	as MaxCycle,   	
						I.IMPORTANCELEVEL	as ImportanceLevel, "+CHAR(10)+
			dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					"						as ImportanceLevelDescription,
						E.CLIENTIMPLEVEL	as ClientImportanceLevel, "+CHAR(10)+
			dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I1',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					"						as ClientImportancelevelDescription, "+CHAR(10)+
			dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					"						as Definition
					FROM	EVENTCONTROL V       
					join	EVENTS E 		on (E.EVENTNO=V.EVENTNO)  
					left join IMPORTANCE I 		on (I.IMPORTANCELEVEL = isnull(V.IMPORTANCELEVEL,E.IMPORTANCELEVEL))  
					left join IMPORTANCE I1 	on (I1.IMPORTANCELEVEL = E.CLIENTIMPLEVEL)  
					left join EVENTCATEGORY EC 	on (EC.CATEGORYID = E.CATEGORYID)   
					WHERE V.CRITERIANO=(	select 
								min(V1.CRITERIANO)  				
								from OPENACTION OA  				
								join EVENTCONTROL V1 ON (V1.CRITERIANO=OA.CRITERIANO)  				
								where OA.CASEID=@pnCaseKey   				
								and OA.POLICEEVENTS=1  				
								and V1.EVENTNO=V.EVENTNO)   	
					and E.EVENTNO not in (-13,-14)"+char(10)+
			Case 
				when @psPickListSearch is not null and len(@psPickListSearch)>0 and isnumeric(@psPickListSearch)=1 then
					"and E.EVENTNO = cast('"+@psPickListSearch+"' as int)"
				when @psPickListSearch is not null and len(@psPickListSearch)<=10 then 
					"and (UPPER(E.EVENTCODE)= " + dbo.fn_WrapQuotes(UPPER(@psPickListSearch), 0, 0) + " or "+char(10)+
					"upper("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'V',@sLookupCulture,@pbCalledFromCentura)+
						") like " + dbo.fn_WrapQuotes(UPPER(@psPickListSearch) + '%', 0, 0) + ")"
				when @psPickListSearch is not null and len(@psPickListSearch)>10 then 
					"and UPPER(V.EVENTDESCRIPTION) like " + dbo.fn_WrapQuotes(UPPER(@psPickListSearch) + '%', 0, 0)				
				when @pnEventKey is not null then
					"and E.EVENTNO = @pnEventKey"
			End + char(10)+
					"UNION  
					SELECT   	
						E.EVENTNO, 		  	
						E.EVENTCODE,   	"+char(10)+
					"	isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'V',@sLookupCulture,@pbCalledFromCentura)+","
							   +dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+"),"+char(10)+
					"	E.EVENTNO, 		  	
						E.EVENTCODE,   	"+char(10)+
					"	isnull("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'V',@sLookupCulture,@pbCalledFromCentura)+","
							   +dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+"),"+char(10)+
					"	isnull(V.NUMCYCLESALLOWED, E.NUMCYCLESALLOWED),  	
						I.IMPORTANCELEVEL,"+char(10)+  	
			dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+","+
						"E.CLIENTIMPLEVEL," +char(10)+
			dbo.fn_SqlTranslatedColumn('IMPORTANCE','IMPORTANCEDESC',null,'I1',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+","+
			dbo.fn_SqlTranslatedColumn('EVENTS','DEFINITION',null,'E',@sLookupCulture,@pbCalledFromCentura)+CHAR(10)+
					"FROM		CASEEVENT CE       
					join		EVENTS E 		on (E.EVENTNO=CE.EVENTNO)  
					left join	EVENTCONTROL V	on (V.EVENTNO=CE.EVENTNO  				
								and			V.CRITERIANO=isnull((select		min(OA.CRITERIANO)  							 
											from OPENACTION OA  							 
											join EVENTCONTROL V1 on (V1.CRITERIANO=OA.CRITERIANO  and V1.EVENTNO=CE.EVENTNO)  							 
											where OA.CASEID=CE.CASEID and OA.POLICEEVENTS=1),CE.CREATEDBYCRITERIA))  
					left join IMPORTANCE I 		on (I.IMPORTANCELEVEL = isnull(V.IMPORTANCELEVEL,E.IMPORTANCELEVEL))  
					left join IMPORTANCE I1 	on (I1.IMPORTANCELEVEL = E.CLIENTIMPLEVEL)  
					left join EVENTCATEGORY EC 	on (EC.CATEGORYID = E.CATEGORYID)   
					WHERE CE.OCCURREDFLAG between 1 and 8  and CE.CASEID=@pnCaseKey"+char(10)+
			Case 
				when @psPickListSearch is not null and len(@psPickListSearch)>0 and isnumeric(@psPickListSearch)=1 then
					"and E.EVENTNO = cast('"+@psPickListSearch+"' as int)"
				when @psPickListSearch is not null and len(@psPickListSearch)<=10 then 
					"and (UPPER(E.EVENTCODE)= " + dbo.fn_WrapQuotes(UPPER(@psPickListSearch), 0, 0) + " or " + char(10)+
					"	isnull(upper("+dbo.fn_SqlTranslatedColumn('EVENTCONTROL','EVENTDESCRIPTION',null,'V',@sLookupCulture,@pbCalledFromCentura)+"), "+char(10)+
							   "upper("+dbo.fn_SqlTranslatedColumn('EVENTS','EVENTDESCRIPTION',null,'E',@sLookupCulture,@pbCalledFromCentura)+")) like "
						+ dbo.fn_WrapQuotes(UPPER(@psPickListSearch) + '%', 0, 0) + ")"
				when @psPickListSearch is not null and len(@psPickListSearch)>10 then 
					"and UPPER(V.EVENTDESCRIPTION) like " + dbo.fn_WrapQuotes(UPPER(@psPickListSearch) + '%', 0, 0)				
				when @pnEventKey is not null then
					"and E.EVENTNO = @pnEventKey"
			End + char(10)+			
					"ORDER BY 3,2,1"
	Exec @nErrorCode = sp_executesql @sSQLString,
				N'@pnCaseKey		int,
					@pnEventKey		int,
					@psPickListSearch nvarchar(30)',
				  @pnCaseKey		= @pnCaseKey,
				  @pnEventKey		= @pnEventKey,
				  @psPickListSearch 	= @psPickListSearch

	Set @pnRowCount = @@ROWCOUNT
End

Return @nErrorCode
GO

Grant execute on dbo.dw_ListAvailableEvents to public
GO
