using Autofac;
using InprotechKaizen.Model.Components.DocumentGeneration.Classic;

namespace InprotechKaizen.Model.Components.DocumentGeneration
{
    public class DocumentGenerationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DocumentGenerator>().As<IDocumentGenerator>();
            builder.RegisterType<QueueItems>().As<IQueueItems>();
            builder.RegisterType<ActivityRequestHistoryMapper>().As<IActivityRequestHistoryMapper>();
        }
    }
}