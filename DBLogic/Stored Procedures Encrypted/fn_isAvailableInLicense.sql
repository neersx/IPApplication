-----------------------------------------------------------------------------------------------------------------------------
-- Creation of fn_IsAvailableInLicense
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id('dbo.fn_IsAvailableInLicense') and xtype='FN')
Begin
	Print '**** Drop Function dbo.fn_IsAvailableInLicense'
	Drop function [dbo].[fn_IsAvailableInLicense]
End
Print '**** Creating Function dbo.fn_IsAvailableInLicense...'
Print ''
GO

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE FUNCTION dbo.fn_IsAvailableInLicense
(
	@pnObjectId	int,
	@pnObjectLevel int,
	@pnLicenseModule int
) 

RETURNS nvarchar(13)
With ENCRYPTION
AS
-- Function :	fn_IsAvailableInLicense
-- VERSION :	1
-- COPYRIGHT:	Copyright CPA Software Solutions (Australia) Pty Limited
-- DESCRIPTION:	Check what licenses an object is available under.

-- EXAMPLE:
-- To list all tasks and what licenses they were availabile under

/*
    declare @sSQLString nvarchar(4000)
    set @sSQLString = 'Select T.TASKNAME, T.DESCRIPTION, '
    select @sSQLString = @sSQLString + 'dbo.fn_IsAvailableInLicense(T.TASKID, 20,' + cast(L.MODULEID as nvarchar(2)) + ') as [' + L.MODULENAME + '], '
    from LICENSEMODULE L
    where L.MODULEFLAG = 4 -- comment this line to see licenses also applicable for client/server 
    set @sSQLString = SUBSTRING(@sSQLString, 0, LEN(@sSQLString)) + char(13) + char(10) + 'from TASK T
    order by 1'

    exec sp_executesql @sSQLString
*/

Begin
	declare @bIsAvailable bit
	set @bIsAvailable = 0
	If @pnObjectLevel = 10
	Begin
        -- for Tasks
		Select @bIsAvailable = 1
		from MODULE M
		join VALIDOBJECT VOB on (M.MODULEID=cast(substring(dbo.fn_Clarify(VOB.OBJECTDATA),4,10)as int)
				AND VOB.TYPE=@pnObjectLevel )
		join LICENSEMODULE L ON (
			(L.MODULEID=cast(substring(dbo.fn_Clarify(VOB.OBJECTDATA),1,3)as int) 
			and L.MODULEID = @pnLicenseModule)
			OR substring(dbo.fn_Clarify(VOB.OBJECTDATA),1,3) = '999' /* Any */ 
		)
		where M.MODULEID = @pnObjectId
	End
	Else if @pnObjectLevel = 20
	Begin
        -- for Modules (web part)
		Select @bIsAvailable = 1
		from TASK T
		join VALIDOBJECT VOB on (T.TASKID=cast(substring(dbo.fn_Clarify(VOB.OBJECTDATA),4,10)as int)
				AND VOB.TYPE=@pnObjectLevel )
		join LICENSEMODULE L ON (
			(L.MODULEID=cast(substring(dbo.fn_Clarify(VOB.OBJECTDATA),1,3)as int) 
			and L.MODULEID = @pnLicenseModule)
			OR substring(dbo.fn_Clarify(VOB.OBJECTDATA),1,3) = '999' /* Any */ 
		)
		where T.TASKID = @pnObjectId
	End
	Else If @pnObjectLevel in (30, 35)
	Begin
        -- for topic security, 35 indicate dependent topic security
		Select @bIsAvailable = 1
		from DATATOPIC DT
		join VALIDOBJECT VOB on (DT.TOPICID=cast(substring(dbo.fn_Clarify(VOB.OBJECTDATA),4,10)as int)
				AND VOB.TYPE=@pnObjectLevel )
		join LICENSEMODULE L ON (
			(L.MODULEID=cast(substring(dbo.fn_Clarify(VOB.OBJECTDATA),1,3)as int) 
			and L.MODULEID = @pnLicenseModule)
			OR substring(dbo.fn_Clarify(VOB.OBJECTDATA),1,3) = '999' /* Any */ 
		)
		where DT.TOPICID = @pnObjectId
	End
	return @bIsAvailable
End
GO

grant execute on dbo.fn_IsAvailableInLicense to public
go
