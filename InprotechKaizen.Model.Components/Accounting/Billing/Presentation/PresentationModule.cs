using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Presentation
{
    public class PresentationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<BillLines>().As<IBillLines>();
            builder.RegisterType<BillFormatResolver>().As<IBillFormatResolver>();
        }
    }
}