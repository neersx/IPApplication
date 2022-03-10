-----------------------------------------------------------------------------------------------------------------------------
-- Creation of ipw_WorkflowEventReferenceSearch
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[ipw_WorkflowEventReferenceSearch]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
       print '**** Drop procedure dbo.ipw_WorkflowEventReferenceSearch.'
       drop procedure dbo.ipw_WorkflowEventReferenceSearch
       print '**** Creating procedure dbo.ipw_WorkflowEventReferenceSearch...'
       print ''
end
go

SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO

CREATE PROCEDURE dbo.ipw_WorkflowEventReferenceSearch
(
       @pnCriteriaNo              int,
       @pnEventNo                 int
)      
-- PROCEDURE :       ipw_WorkflowEventReferenceSearch
-- VERSION :  2
-- DESCRIPTION:      Lists EVENTCONTROL containing a particular event.

-- Modifications
--
-- Date              Who    Number			Version       Description
-- ------------      ------ -------       -------       ------------------------------------
-- 21/03/2016		  AT     R57659			1		      Procedure created.
-- 15/02/2017		  SS     R70670			2		      Added consideration for required event from event occurenece section

AS
SET NOCOUNT ON
SET CONCAT_NULL_YIELDS_NULL OFF

declare @ErrorCode         int
declare @sSql        nvarchar(max)

Set @sSql = 'SELECT EC.EVENTNO as EventId
       From EVENTCONTROL EC
       left join DUEDATECALC DDC on DDC.CRITERIANO = EC.CRITERIANO
                           and DDC.EVENTNO = EC.EVENTNO
                           and @pnEventNo in (DDC.FROMEVENT, DDC.COMPAREEVENT)
       left join DATESLOGIC DL on DL.CRITERIANO = EC.CRITERIANO
                           and DL.EVENTNO = EC.EVENTNO 
                           and DL.COMPAREEVENT = @pnEventNo         
       left join RELATEDEVENTS RE on RE.CRITERIANO = EC.CRITERIANO
                           and RE.EVENTNO = EC.EVENTNO
                           and RE.RELATEDEVENT = @pnEventNo
       left join EVENTCONTROLREQEVENT REV on REV.CRITERIANO = EC.CRITERIANO
                           and REV.EVENTNO = EC.EVENTNO
                           and REV.REQEVENTNO = @pnEventNo
       WHERE EC.CRITERIANO = @pnCriteriaNo 
       AND ((EC.EVENTNO = @pnEventNo or EC.UPDATEFROMEVENT = @pnEventNo)
       or DDC.CRITERIANO IS NOT NULL
       or DL.CRITERIANO IS NOT NULL
       or RE.CRITERIANO IS NOT NULL
	   or REV.CRITERIANO IS NOT NULL)'

exec @ErrorCode=sp_executesql @sSql, 
                     N'@pnCriteriaNo            int,
                     @pnEventNo           int',
                     @pnCriteriaNo = @pnCriteriaNo,
                     @pnEventNo    = @pnEventNo

RETURN @ErrorCode
go

grant execute on dbo.ipw_WorkflowEventReferenceSearch  to public
go