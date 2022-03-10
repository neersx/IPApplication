using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Configuration.Search;
using InprotechKaizen.Model.Components.Security;

namespace Inprotech.Web.Portal
{
    public interface IAppsMenu
    {
        IEnumerable<AppsMenu.AppsMenuItem> Build();
    }

    public class AppsMenu : IAppsMenu
    {
        public enum MenuTypes
        {
            simple,
            newtab,
            searchPanel
        }

        const string NamesConsolidationKey = "NamesConsolidation";
        const string HmrcVatSubmission = "HmrcVatSubmission";
        const string DebitNote = "DebitNote";
        const string DisbursementDissection = "DisbursementDissection";
        const string Roles = "Roles";

        static readonly ApplicationTask[] SchedulePtoDataDownload =
            Enum.GetNames(typeof(ApplicationTask))
                .Where(_ => _.StartsWith("Schedule") && _.EndsWith("DataDownload"))
                .Select(_ => Enum.Parse(typeof(ApplicationTask), _))
                .Cast<ApplicationTask>()
                .ToArray();

        static readonly Dictionary<string, Func<AppsMenuItem>> AppsMenuMap = new()
        {
            { M.CaseSearch.Key, () => M.CaseSearch },
            { M.TaskPlanner.Key, () => M.TaskPlanner },
            { M.TimeRecording.Key, () => M.TimeRecording },
            { M.CaseDataComparisonInbox.Key, () => M.CaseDataComparisonInbox },
            { M.ImportCase.Key, () => M.ImportCase },
            { M.MaintainPriorArt.Key, () => M.MaintainPriorArt },
            { M.PolicingDashboard.Key, () => M.PolicingDashboard },
            { M.ExchangeIntegration.Key, () => M.ExchangeIntegration },
            { M.ScheduleDataDownload.Key, () => M.ScheduleDataDownload },
            { M.Utilities.Key, () => M.Utilities },
            //{ M.Billing.Key, () => M.Billing },
            { M.WorkInProgress.Key, () => M.WorkInProgress },
            { M.FinancialReports.Key, () => M.FinancialReports },
            { M.WorkflowRules.Key, () => M.WorkflowRules },
            { M.SystemMaintenance.Key, () => M.SystemMaintenance },
            { M.UserManagement.Key, () => M.UserManagement },
            { M.SchemaMapping.Key, () => M.SchemaMapping },

            { M.InprotechClassic.Key, () => M.InprotechClassic }
        };

        static readonly Dictionary<string, ApplicationTask[]> MenuApplicationTasks = new()
        {
            { M.CaseSearch.Key, new[] { ApplicationTask.AdvancedCaseSearch } },
            { M.TaskPlanner.Key, new[] { ApplicationTask.MaintainTaskPlannerApplication } },
            { M.TimeRecording.Key, new[] { ApplicationTask.MaintainTimeViaTimeRecording } },
            { M.CaseDataComparisonInbox.Key, new[] { ApplicationTask.ViewCaseDataComparison } },

            { M.ImportCase.Key, new[] { ApplicationTask.BulkCaseImport } },

            { M.MaintainPriorArt.Key, new[] { ApplicationTask.MaintainPriorArt } },
            { M.PolicingDashboard.Key, new[] { ApplicationTask.ViewPolicingDashboard, ApplicationTask.PolicingAdministration } },
            { M.ExchangeIntegration.Key, new[] { ApplicationTask.ExchangeIntegrationAdministration } },
            { M.ScheduleDataDownload.Key, SchedulePtoDataDownload },

            { M.Utilities.Key, new[] { ApplicationTask.NotDefined } },
            { M.Utilities.Items.Single(i => i.Key.Equals(NamesConsolidationKey)).Key, new[] { ApplicationTask.NamesConsolidation } },
            { M.Utilities.Items.Single(i => i.Key.Equals(HmrcVatSubmission)).Key, new[] { ApplicationTask.HmrcVatSubmission } },

            { M.Billing.Key, new[] { ApplicationTask.MaintainDebitNote } },
            { M.Billing.Items.Single(i => i.Key.Equals(DebitNote)).Key, new[] { ApplicationTask.MaintainDebitNote } },

            { M.WorkInProgress.Key, new[] { ApplicationTask.RecordWip } },
            { M.WorkInProgress.Items.Single( i=> i.Key.Equals(DisbursementDissection)).Key, new[] {ApplicationTask.DisbursementDissection } },

            { M.FinancialReports.Key, new[] { ApplicationTask.ViewAgedDebtorsReport, ApplicationTask.ViewRevenueAnalysisReport } },
            { M.WorkflowRules.Key, new[] { ApplicationTask.MaintainWorkflowRules, ApplicationTask.MaintainWorkflowRulesProtected } },
            { M.SystemMaintenance.Key, new[] { ApplicationTask.NotDefined } },

            { M.UserManagement.Key, new[] { ApplicationTask.MaintainRole } },
            { M.UserManagement.Items.Single(i => i.Key.Equals(Roles)).Key, new[] { ApplicationTask.NotDefined } },

            { M.SchemaMapping.Key, new[] { ApplicationTask.ConfigureSchemaMappingTemplate } },

            { M.InprotechClassic.Key, new[] { ApplicationTask.ShowLinkstoWeb } }
        };

        readonly IConfigurableItems _configurables;
        readonly ISecurityContext _securityContext;

        readonly ITaskSecurityProvider _taskSecurityProvider;

        public AppsMenu(ITaskSecurityProvider taskSecurityProvider, IConfigurableItems configurables, ISecurityContext securityContext)
        {
            _taskSecurityProvider = taskSecurityProvider;
            _configurables = configurables;
            _securityContext = securityContext;
        }

        public IEnumerable<AppsMenuItem> Build()
        {
            var allowedTasks = _taskSecurityProvider.ListAvailableTasks().ToArray();

            var isExternalUser = _securityContext.User.IsExternalUser;

            var inprotechMenu = Build(AppsMenuMap, allowedTasks, isExternalUser).ToList();

            if (!_configurables.Any())

                //Todo Custom map for sub level, maybe move this to other traversal
            {
                inprotechMenu.RemoveAll(_ => _.Key == M.SystemMaintenance.Key);
            }

            inprotechMenu.RemoveAll(_ => _ == null);

            return inprotechMenu;
        }

        static IEnumerable<AppsMenuItem> Build(
            Dictionary<string, Func<AppsMenuItem>> menuMap,
            ValidSecurityTask[] allowedTasks,
            bool isExternalUser)
        {
            var mainMenu = (from m in menuMap
                            where MenuApplicationTasks[m.Key].Contains(ApplicationTask.NotDefined) || allowedTasks.Any(t => MenuApplicationTasks[m.Key].Contains((ApplicationTask)t.TaskId))
                            select m.Value()).ToList();

            if (!mainMenu.Any()) return null;

            for (var i = mainMenu.Count - 1; i >= 0; i--)
            {
                if (mainMenu[i].Items == null || !mainMenu[i].Items.Any()) continue;
                RemoveUnAuthorizedChildMenus(mainMenu[i]);
                if (!mainMenu[i].Items.Any())
                {
                    mainMenu.RemoveAt(i);
                }
            }

            var caseSearchMenu = mainMenu.FirstOrDefault(_ => _.Key == "CaseSearch");
            if (caseSearchMenu != null)
            {
                if (allowedTasks.All(_ => _.TaskId != (short)ApplicationTask.RunSavedCaseSearch))
                {
                    caseSearchMenu.Type = MenuTypes.simple;
                }

                if (isExternalUser)
                {
                    caseSearchMenu.QueryContextKey = (int)QueryContext.CaseSearchExternal;
                }
            }

            return mainMenu;

            void RemoveUnAuthorizedChildMenus(AppsMenuItem menu)
            {
                if (menu?.Items == null) return;
                menu.Items.RemoveAll(_ => !MenuApplicationTasks[_.Key].Contains(ApplicationTask.NotDefined) && !allowedTasks.Any(t => MenuApplicationTasks[_.Key].Contains((ApplicationTask)t.TaskId)));
                foreach (var child in menu.Items)
                    RemoveUnAuthorizedChildMenus(child);
            }
        }

        static class M
        {
            public static AppsMenuItem CaseSearch => new("CaseSearch", "#/case/search", "cpa-icon-advanced-search", "Case Search")
            {
                Type = MenuTypes.searchPanel,
                QueryContextKey = (int)QueryContext.CaseSearch
            };

            public static AppsMenuItem TaskPlanner => new("TaskPlanner", "#/task-planner", "cpa-icon-calendar-check-o", "Task Planner");

            public static AppsMenuItem TimeRecording => new("TimeRecording", "#/accounting/time", "cpa-icon-clock-o", "Time Recording")
            {
                Type = MenuTypes.newtab
            };

            public static AppsMenuItem CaseDataComparisonInbox => new("CaseDataComparisonInbox", "#/casecomparison/inbox", "cpa-icon-columns", "Case Data Comparison Inbox");

            public static AppsMenuItem ImportCase => new("ImportCase", "#/bulkcaseimport", "cpa-icon-check-out", "Import Cases");

            public static AppsMenuItem MaintainPriorArt => new("MaintainPriorArt", "#/priorart", "cpa-icon-prior-art", "Prior Art");
            public static AppsMenuItem PolicingDashboard => new("PolicingDashboard", "#/policing-dashboard", "cpa-icon-policing-dashboard", "Policing Dashboard");
            public static AppsMenuItem ExchangeIntegration => new("ExchangeIntegration", "#/exchange-requests", "cpa-icon-exchange-integration", "Exchange Integration");
            public static AppsMenuItem ScheduleDataDownload => new("SchedulePtoDataDownload", "#/integration/ptoaccess/schedules", "cpa-icon-calendar-download", "Schedule Data Downloads");
            public static AppsMenuItem FinancialReports => new("FinancialReports", "#/reports", "cpa-icon-reports", "Financial Reports");
            public static AppsMenuItem WorkflowRules => new("WorkflowRules", "#/configuration/rules/workflows", "cpa-icon-workflow-designer", "Workflow Designer");
            public static AppsMenuItem SystemMaintenance => new("SystemMaintenance", "#/configuration/search", "cpa-icon-wrench", "Configuration");

            public static AppsMenuItem SchemaMapping => new("SchemaMapping", "#/schemamapping/list", "cpa-icon-schema-mapping", "Schema Mapping");

            public static AppsMenuItem InprotechClassic => new("InprotechClassic", "../", "cpa-icon-logo", "Inprotech") { Type = MenuTypes.newtab };

            public static AppsMenuItem Utilities => new("Utilities", string.Empty, "cpa-icon-sliders", "Utilities")
            {
                Items = new List<AppsMenuItem>
                {
                    new(NamesConsolidationKey, "#/names/consolidation", string.Empty, "Name Consolidation"),
                    new(HmrcVatSubmission, "#/accounting/vat", string.Empty, "HMRC VAT Submission")
                }
            };

            public static AppsMenuItem Billing => new("Billing", string.Empty, "cpa-icon-file-coins-o", "Billing")
            {
                Items = new List<AppsMenuItem>
                {
                    new(DebitNote, "#/accounting/billing/debit-note", string.Empty, "Create Debit Note")
                }
            };

            public static AppsMenuItem UserManagement => new("UserManagement", string.Empty, "cpa-icon-key", "User Management")
            {
                Items = new List<AppsMenuItem>
                {
                    new(Roles, "#/user-configuration/roles", string.Empty, "Roles")
                }
            };
            public static AppsMenuItem WorkInProgress => new AppsMenuItem("WorkInProgress", string.Empty, "cpa-icon-wip-o", "Work In Progress")
            {
                Items = new List<AppsMenuItem>
                {
                    new(DisbursementDissection, "#/accounting/wip-disbursements",string.Empty,"Disbursement Dissection")
                }
            };
        }

        public class AppsMenuItem
        {
            public AppsMenuItem(string key)
            {
                Key = key;
            }

            public AppsMenuItem(string key, string url, string iconClass, string text)
            {
                if (string.IsNullOrEmpty(text))
                {
                    text = key;
                }

                Key = key;
                Url = url;
                Icon = iconClass;
                Text = text;
                Type = MenuTypes.simple;
            }

            public string Key { get; set; }
            public string Icon { get; set; }
            public string Url { get; set; }
            public string Text { get; set; }
            public string Description { get; set; }
            public MenuTypes Type { get; set; }

            public int? QueryContextKey { get; set; }

            public bool CanEdit { get; set; }

            public List<AppsMenuItem> Items { get; set; }
        }
    }
}