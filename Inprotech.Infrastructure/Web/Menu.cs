using Inprotech.Infrastructure.Security;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Inprotech.Infrastructure.Web
{
    public interface IMenu
    {
        IEnumerable<object> Build();
    }

    public class Menu : IMenu
    {
        readonly ITaskSecurityProvider _taskSecurityProvider;

        public static readonly Dictionary<ApplicationTask, string[]> AvailableLists = new Dictionary<ApplicationTask, string[]>
                        {
                                {
                                    ApplicationTask.MaintainEventNoteTypes,
                                    new [] { "EventNoteTypes", "#/configuration/general/events/eventnotetypes"}
                                },
                                {
                                    ApplicationTask.MaintainLocality, 
                                    new [] { "Locality", "/#/configuration/general/names/locality"}
                                },
                                {
                                    ApplicationTask.MaintainNameAliasTypes, 
                                    new [] { "NameAliasTypes", "#/configuration/general/names/namealiastype"}
                                },
                                {
                                    ApplicationTask.MaintainNameRelationshipCode,
                                    new [] { "NameRelationship", "/#/configuration/general/names/namerelations"}
                                }                               
                        };

        static readonly ApplicationTask[] SchedulePtoDataDownload =
        {
            ApplicationTask.ScheduleUsptoTsdrDataDownload, 
            ApplicationTask.ScheduleUsptoPrivatePairDataDownload,
            ApplicationTask.ScheduleEpoDataDownload,
            ApplicationTask.ScheduleIpOneDataDownload
        };

        public static readonly ApplicationTask[] SystemMaintenanceTasks =
        {
            ApplicationTask.ConfigureDmsIntegration,
            ApplicationTask.ConfigureDataMapping,
            ApplicationTask.MaintainSiteControl,
            ApplicationTask.MaintainBaseInstructions,
            ApplicationTask.MaintainStatus,
            ApplicationTask.MaintainNameTypes,
            ApplicationTask.MaintainValidCombinations,
            ApplicationTask.MaintainJurisdiction,
            ApplicationTask.ViewJurisdiction,
            ApplicationTask.MaintainNumberTypes,
            ApplicationTask.MaintainNameRestrictions,
            ApplicationTask.MaintainTextTypes,
            ApplicationTask.MaintainImportanceLevel,
            ApplicationTask.ScheduleEpoDataDownload,
            ApplicationTask.MaintainDataItems,
            ApplicationTask.ConfigureUsptoPractitionerSponsorship
        };

        static readonly Dictionary<string, ApplicationTask[]> MenuApplicationTasks = new Dictionary<string, ApplicationTask[]>
                        {
                            {"CaseDataComparisonInbox", new [] { ApplicationTask.ViewCaseDataComparison }},
                            {"SchedulePtoDataDownload", SchedulePtoDataDownload },
                            {"BulkCaseImport", new [] { ApplicationTask.BulkCaseImport }},
                            {"BulkCaseImportStatus", new [] { ApplicationTask.BulkCaseImport }},
                            {"MaintainPriorArt", new [] { ApplicationTask.MaintainPriorArt }},
                            {"ApplicationLinkSecurity", new [] { ApplicationTask.MaintainApplicationLinkSecurity }},
                            {"FinancialReports", new [] { ApplicationTask.ViewAgedDebtorsReport, ApplicationTask.ViewRevenueAnalysisReport}},
                            {"SystemMaintenance", AvailableLists.Keys.Concat(SystemMaintenanceTasks).ToArray()},
                            {"ConfigureDmsIntegration", new []{ ApplicationTask.ConfigureDmsIntegration }},
                            {"SchemaMapping", new [] {ApplicationTask.ConfigureSchemaMappingTemplate}},
                            {"WorkflowRules", new [] {ApplicationTask.MaintainWorkflowRules, ApplicationTask.MaintainWorkflowRulesProtected}},
                            {"PolicingDashboard", new[] {ApplicationTask.ViewPolicingDashboard, ApplicationTask.PolicingAdministration}}
                        };

        static readonly Dictionary<string, Func<dynamic>> IntegrationMenuMap = new Dictionary<string, Func<dynamic>>
                      {
                          {"CaseDataComparisonInbox", () => BuildMenuItem("CaseDataComparisonInbox", "#/casecomparison/inbox")},
                          {"SchedulePtoDataDownload", () => BuildMenuItem("SchedulePtoDataDownload", "#/integration/ptoaccess/schedules")},
                          {"ApplicationLinkSecurity", () => BuildMenuItem("ApplicationLinkSecurity", "#/integration/externalapplication")},
                          {"SchemaMapping", () => BuildMenuItem("SchemaMapping", "schemamapping")}
                      };

        static readonly Dictionary<string, Func<dynamic>> InprotechMenuMap = new Dictionary<string, Func<dynamic>>
                      {
                          {"BulkCaseImport", () => BuildMenuItem("BulkCaseImport", "#/bulkcaseimport")},
                          {"MaintainPriorArt", () => BuildMenuItem("MaintainPriorArt", "priorart/#/search")},
                          {"FinancialReports", () => BuildMenuItem("FinancialReports", "#/reports")},
                          {"SystemMaintenance",() => BuildMenuItem("SystemMaintenance","#/configuration/search")},
                          {"PolicingDashboard",() => BuildMenuItem("PolicingDashboard","#/policing-dashboard")},
                          {"WorkflowRules",() => BuildMenuItem("WorkflowRules","#/configuration/rules/workflows")}
                      };
    
        public Menu(ITaskSecurityProvider taskSecurityProvider)
        {
            if (taskSecurityProvider == null) throw new ArgumentNullException("taskSecurityProvider");
            _taskSecurityProvider = taskSecurityProvider;
        }

        public IEnumerable<dynamic> Build()
        {
            var allowedTasks = _taskSecurityProvider.ListAvailableTasks().ToArray();

            var inprotechMenu = Build("Inprotech", InprotechMenuMap, allowedTasks);

            var integrationMenu = Build("Integration", IntegrationMenuMap, allowedTasks);

            if (inprotechMenu != null)
                yield return inprotechMenu;

            if (integrationMenu != null)
                yield return integrationMenu;
        }

        static dynamic Build(string name,
            Dictionary<string, Func<dynamic>> menuMap,
            IEnumerable<ValidSecurityTask> allowedTasks)
        {
            var menuItems = (from m in menuMap
                             where allowedTasks.Any(t => MenuApplicationTasks[m.Key].Contains((ApplicationTask)t.TaskId))
                             select m.Value()).ToArray();

            if (!menuItems.Any()) return null;

            return new
            {
                name,
                TitleResId = "menu" + name,
                Items = menuItems
            };
        }

        static dynamic BuildMenuItem(string name, string itemPath, string titleResId = null)
        {
            if (string.IsNullOrEmpty(titleResId))
                titleResId = "menu" + name;

            return new
            {
                id = name,
                name,
                itemPath,
                titleResId
            };
        }
    }
}
