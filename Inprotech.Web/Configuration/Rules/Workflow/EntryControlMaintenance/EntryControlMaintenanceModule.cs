using Autofac;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance
{
    public class EntryControlMaintenanceModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<WorkflowEntryDetailService>().As<IWorkflowEntryDetailService>();
            builder.RegisterType<DescriptionValidator>().As<IDescriptionValidator>();

            builder.RegisterType<EntryEventMaintenance>()
                   .As<ISectionMaintenance>()
                   .As<IReorderableSection>();
            
            builder.RegisterType<StepsMaintenance>()
                   .As<ISectionMaintenance>()
                   .As<IReorderableSection>();

            builder.RegisterType<EntryDocumentMaintainance>()
                  .As<ISectionMaintenance>();

            builder.RegisterType<EntryUserAccessMaintenance>()
                  .As<ISectionMaintenance>();
        }
    }
}