using Autofac;
using InprotechKaizen.Model.Components.DocumentGeneration.Services.Pdf;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor
{
    public class ProcessorModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<RunDocItemsManager>().As<IRunDocItemsManager>();
            builder.RegisterType<LegacyDocItemRunner>().As<ILegacyDocItemRunner>();
            builder.RegisterType<FormFieldsResolver>().As<IFormFieldsResolver>();
        }
    }
}
