DECLARE @RC int
DECLARE @pnUserIdentityId int
DECLARE @psCulture nvarchar(10)
DECLARE @psCaseKey nvarchar(10)
DECLARE @psCaseReference nvarchar(20)
DECLARE @psCaseFamilyReference nvarchar(20)
DECLARE @psCaseTypeKey nvarchar(1)
DECLARE @psCaseTypeDescription nvarchar(50)
DECLARE @psCountryKey nvarchar(3)
DECLARE @psCountryName nvarchar(60)
DECLARE @psPropertyTypeKey nvarchar(1)
DECLARE @psPropertyTypeDescription nvarchar(50)
DECLARE @psCaseCategoryKey nvarchar(1)
DECLARE @psCaseCategoryDescription nvarchar(20)
DECLARE @psSubTypeKey nvarchar(2)
DECLARE @psSubTypeDescription nvarchar(50)
DECLARE @psStatusKey nvarchar(10)
DECLARE @psStatusDescription nvarchar(50)
DECLARE @psShortTitle nvarchar(254)
DECLARE @pbReportToThirdParty bit
DECLARE @pnNoOfClaims int
DECLARE @pnNoInSeries int
DECLARE @psEntitySizeKey nvarchar(10)
DECLARE @psEntitySizeDescription nvarchar(80)
DECLARE @psFileLocationKey nvarchar(10)
DECLARE @psFileLocationDescription nvarchar(80)
DECLARE @psStopPayReasonKey nvarchar(1)
DECLARE @psStopPayReasonDescription nvarchar(80)
DECLARE @psTypeOfMarkKey nvarchar(10)
DECLARE @psTypeOfMarkDescription nvarchar(80)
DECLARE @pdtInstructionsReceivedDate datetime
-- Set parameter values
Set @pnUserIdentityId = 1
Set @psCaseReference = '1234/JB2'
Set @psCaseFamilyReference = 'Bosker'
Set @psCaseTypeKey = 'X'
set @psCountryKey = 'UK'
set @psPropertyTypeKey = '#'
set @psCaseCategoryKey ='*'
set @psSubTypeKey = '@2'
set @psStatusKey = '098'
set @psShortTitle = 'this is the title'
set @pbReportToThirdParty = 1
set @pnNoOfClaims = 2
set @pnNoInSeries =1
set @psEntitySizeKey = '232'
set @psFileLocationKey = 'desk'
set @psStopPayReasonKey = 'X'
set @psTypeOfMarkKey = '3232'
set @pdtInstructionsReceivedDate = getdate()

EXEC @RC = [JON].[dbo].[cs_InsertCase] @pnUserIdentityId, @psCulture, @psCaseKey OUTPUT , @psCaseReference, @psCaseFamilyReference, @psCaseTypeKey, @psCaseTypeDescription, @psCountryKey, @psCountryName, @psPropertyTypeKey, @psPropertyTypeDescription, @psCaseCategoryKey, @psCaseCategoryDescription, @psSubTypeKey, @psSubTypeDescription, @psStatusKey, @psStatusDescription, @psShortTitle, @pbReportToThirdParty, @pnNoOfClaims, @pnNoInSeries, @psEntitySizeKey, @psEntitySizeDescription, @psFileLocationKey, @psFileLocationDescription, @psStopPayReasonKey, @psStopPayReasonDescription, @psTypeOfMarkKey, @psTypeOfMarkDescription, @pdtInstructionsReceivedDate
Select @psCaseKey