using Autofac;

namespace Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps
{
    public class StepsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<WorkflowEntryStepsService>().As<IWorkflowEntryStepsService>();
            builder.RegisterType<ActionStepCategory>().As<IStepCategory>();
            builder.RegisterType<CaseRelationStepCategory>().As<IStepCategory>();
            builder.RegisterType<ChecklistTypeStepCategory>().As<IStepCategory>();
            builder.RegisterType<CountryFlagStepCategory>().As<IStepCategory>();
            builder.RegisterType<NameGroupStepCategory>().As<IStepCategory>();
            builder.RegisterType<NameTypeStepCategory>().As<IStepCategory>();
            builder.RegisterType<NumberTypeStepCategory>().As<IStepCategory>();
            builder.RegisterType<TextTypeStepCategory>().As<IStepCategory>();
        }
    }
}