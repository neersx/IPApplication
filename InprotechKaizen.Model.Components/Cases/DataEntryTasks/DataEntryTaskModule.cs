using Autofac;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Policing;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Components.Policing;

namespace InprotechKaizen.Model.Components.Cases.DataEntryTasks
{
    public class DataEntryTaskModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<DataEntryTaskPrerequisiteCheck>().As<IDataEntryTaskPrerequisiteCheck>();
            builder.RegisterType<BatchDataEntryTaskPrerequisiteCheck>().As<IBatchDataEntryTaskPrerequisiteCheck>();
            builder.RegisterType<CycleSelection>().As<ICycleSelection>();
            builder.RegisterType<GetOrCreateCaseEvent>().As<IGetOrCreateCaseEvent>();
            builder.RegisterType<PolicingRequestProcessor>().As<IPolicingRequestProcessor>();
            builder.RegisterType<BatchPolicingRequest>().AsImplementedInterfaces();
        }
    }
}