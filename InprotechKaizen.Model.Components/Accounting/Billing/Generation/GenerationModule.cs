using Autofac;
using InprotechKaizen.Model.Components.Accounting.Billing.Generation.Builders;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Generation
{
    public class GenerationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CapabilitiesResolver>().As<ICapabilitiesResolver>();
            builder.RegisterType<BillPrintDetails>().As<IBillPrintDetails>();
            builder.RegisterType<BillDefinitions>().As<IBillDefinitions>();
            
            builder.RegisterType<DefaultBuilder>()
                   .Keyed<IBillDefinitionBuilder>(BillGenerationType.GenerateOnly);

            builder.RegisterType<DmsSaveTypeBillDefinitionBuilder>()
                   .Keyed<IBillDefinitionBuilder>(BillGenerationType.GenerateThenSendToDms);
            
            builder.RegisterType<PdfAttachmentSaveTypeBillDefinitionBuilder>()
                   .Keyed<IBillDefinitionBuilder>(BillGenerationType.GenerateThenAttachToCase);

            builder.RegisterType<BillGeneration>().As<IBillGeneration>();
        }
    }
}
