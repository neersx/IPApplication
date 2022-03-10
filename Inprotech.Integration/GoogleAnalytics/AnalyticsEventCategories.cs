namespace Inprotech.Integration.GoogleAnalytics
{
    public abstract class AnalyticsEventCategories
    {
        public const string LanguageDb = "Language.DB";
        public const string LanguageFirm = "Language.Firm";
        public const string LanguageUsers = "Language.Users";

        public const string UsersWeb = "Users.Web";
        public const string UsersClientServer = "Users.ClientServer";
        public const string UsersActive = "Users.Active";
        public const string UsersExternal = "Users.External";

        public const string VersionDbRelease = "Version.DBRelease";
        public const string VersionInprotechWebApps = "Version.InprotechWebApps";
        public const string VersionIntegration = "Version.Integration";
        
        public const string InstallationDateDbRelease = "InstallationDate.DBRelease";
        public const string InstallationDateInprotechWebApps = "InstallationDate.InprotechWebApps";
        public const string InstallationDateIntegration = "InstallationDate.Integration";

        public const string IntegrationsSchemaMapping = "IntegrationStatus.SchemaMapping";
        public const string IntegrationsIManageView = "IntegrationStatus.Dms.IManage.View";
        public const string IntegrationsIManageType = "IntegrationStatus.Dms.IManage.Type";
        public const string IntegrationsFirstToFileView = "IntegrationStatus.Dms.FirstToFile.View";
        
        public const string IntegrationsExchangeDocumentsDeliveredViaExchangeOption = "IntegrationStatus.Exchange.DocumentsDeliveredViaExchange";
        public const string IntegrationsExchangeRemindersOption = "IntegrationStatus.Exchange.Reminders";
        public const string IntegrationsExchangeBillReviewOption = "IntegrationStatus.Exchange.InvoiceReview";
        public const string IntegrationsExchangeType = "IntegrationStatus.Exchange.Type";

        public const string RolesNoOfUsersPrefix = "Roles.NoOfUsers.";
        public const string RolesTasksPrefix = "Roles.Tasks.";
        public const string RolesWebPartPrefix = "Roles.Modules.";
        public const string RolesSubjectPrefix = "Roles.Subjects.";

        public const string IntegrationsHmrcVatReturns = "Integrations.HmrcVatReturns";
        public const string IntegrationsCasesPrefix = "Integrations.Cases.";
        public const string IntegrationsDocumentsPrefix = "Integrations.Documents.";
        public const string IntegrationsIp1dServiceTypePrefix = "Integrations.Ip1d.ServiceType.";
        public const string IntegrationsIp1dMatchedPrefix = "Integrations.Ip1d.Matched.";
        public const string IntegrationsEfilingPrefix = "Integrations.Efiling.";
        
        public const string IntegrationsExchangeDocumentsDeliveredViaExchange = "Integrations.Exchange.DocumentsDeliveredViaExchange";
        public const string IntegrationsExchangeReminders = "Integrations.Exchange.Reminders";
        public const string IntegrationsExchangeBillsReviewed = "Integrations.Exchange.BillsReviewed";
        
        public const string SiteConfigurationsPrefix = "SiteControl.";

        public const string LawUpdateServiceDate = "LawUpdateService.Date";

        public const string IctDate = "Ict.Date";
        public const string IctVersion = "Ict.Version";
        
        public const string AuthenticationTypesPrefix = "AuthenticationType.";

        public const string StatisticsNewCasesPrefix = "Statistics.New.";
        public const string StatisticsDocGenerated = "Statistics.DocGenerated";
        
        public const string StatisticsAdHocDocGeneratedInprodocPrefix = "Statistics.AdHocDocGenerated.Inprodoc";
        public const string StatisticsSchemaMappingViaApiPrefix = "Statistics.SchemaMappingViaApi";

        public const string StatisticsInnographyIdsDocuments = "Statistics.Innography.Ids.Documents";
        public const string StatisticsInnographyIdsSearch = "Statistics.Innography.Ids.Search";
        public const string StatisticsInnographyIdsPdf= "Statistics.Innography.Ids.Pdf";

        public const string StatisticsClientServerModuleUsePrefix = "Statistics.ClientServerModule.";
        public const string StatisticsPriorArtImportedPrefix = "Statistics.PriorArtImported.";

        public const string ConfigurationClientServerScreensUsePrefix = "Configuration.ClientServerScreen.";
        public const string ConfigurationInternalWebCaseTopicUsePrefix = "Configuration.Internal.WebTopic.Cases.";
        public const string ConfigurationInternalWebNameTopicUsePrefix = "Configuration.Internal.WebTopic.Names.";
        public const string ConfigurationExternalWebCaseTopicUsePrefix = "Configuration.External.WebTopic.Cases.";
        
        public const string ConfigurationWorkflowEntryScreensUsePrefix = "Configuration.WorkflowEntryScreen.";

        public const string StatisticsTaskPlannerAccessedPrefix = "Statistics.TaskPlanner.Accessed";
        public const string StatisticsTaskPlannerUsersPrefix = "Statistics.TaskPlanner.Users";

        public const string StatisticsTimeRecordingAccessedPrefix = "Statistics.TimeRecording.Accessed";
        public const string StatisticsTimeRecordingUsersPrefix = "Statistics.TimeRecording.Users";
    }
}