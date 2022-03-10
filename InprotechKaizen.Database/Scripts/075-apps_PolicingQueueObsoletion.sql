
-----------------------------------------------------------------------------------------------------------------------------
-- Obsoletion of apps_PolicingQueue
-----------------------------------------------------------------------------------------------------------------------------
if exists (select * from sysobjects where id = object_id(N'[dbo].[apps_PolicingQueue]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
begin
	print '**** Drop procedure dbo.apps_PolicingQueue.'
	drop procedure dbo.apps_PolicingQueue
	print '**** Creating procedure dbo.apps_PolicingQueue...'
	print ''
end
go