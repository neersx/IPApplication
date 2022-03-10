using Autofac;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Configuration.Rules.Checklists;
using Inprotech.Web.Configuration.Rules.ScreenDesigner.Cases;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules
{
    public class RulesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<WorkflowSearch>().As<IWorkflowSearch>();
            builder.RegisterType<Inheritance>().As<IInheritance>();
            builder.RegisterType<ValidEventService>().As<IValidEventService>();
            builder.RegisterType<WorkflowPermissionHelper>().As<IWorkflowPermissionHelper>();
            builder.RegisterType<WorkflowEventControlService>().As<IWorkflowEventControlService>();
            builder.RegisterType<WorkflowEntryControlService>().As<IWorkflowEntryControlService>();
            builder.RegisterType<WorkflowInheritanceService>().As<IWorkflowInheritanceService>();
            builder.RegisterType<WorkflowEventInheritanceService>().As<IWorkflowEventInheritanceService>();
            builder.RegisterType<WorkflowEntryInheritanceService>().As<IWorkflowEntryInheritanceService>();
            builder.RegisterType<EntryService>().As<IEntryService>();
            builder.RegisterType<WorkflowMaintenanceService>().As<IWorkflowMaintenanceService>();
            builder.RegisterType<ConfigurationSettings>().As<IConfigurationSettings>();
            builder.RegisterType<SessionTasksProvider>().As<ITaskSecurityProvider>();
            builder.RegisterType<CaseScreenDesignerSearch>().As<ICaseScreenDesignerSearch>();
            builder.RegisterType<ChecklistConfigurationSearch>().As<IChecklistConfigurationSearch>();
            builder.RegisterType<CaseScreenDesignerPermissionHelper>().As<ICaseScreenDesignerPermissionHelper>();
            builder.RegisterType<CaseScreenDesignerInheritanceService>().As<ICaseScreenDesignerInheritanceService>();
            builder.RegisterType<WorkflowCharacteristicsService>()
                   .Keyed<ICharacteristicsService>(CriteriaPurposeCodes.EventsAndEntries);
            builder.RegisterType<CaseScreenDesignerCharacteristicsService>()
                   .Keyed<ICharacteristicsService>(CriteriaPurposeCodes.WindowControl);
            builder.RegisterType<WorkflowCharacteristicsValidator>()
                   .Keyed<ICharacteristicsValidator>(CriteriaPurposeCodes.EventsAndEntries);
            builder.RegisterType<CaseScreenDesignerCharacteristicsValidator>()
                   .Keyed<ICharacteristicsValidator>(CriteriaPurposeCodes.WindowControl);
            builder.RegisterType<ChecklistCharacteristicsValidator>()
                   .Keyed<ICharacteristicsValidator>(CriteriaPurposeCodes.CheckList);
            builder.RegisterType<ChecklistCharacteristicsService>()
                   .Keyed<ICharacteristicsService>(CriteriaPurposeCodes.CheckList);
            builder.RegisterType<ChecklistMaintenanceService>().As<IChecklistMaintenanceService>();
            builder.RegisterType<CriteriaMaintenanceValidator>().As<ICriteriaMaintenanceValidator>();
        }
    }
}