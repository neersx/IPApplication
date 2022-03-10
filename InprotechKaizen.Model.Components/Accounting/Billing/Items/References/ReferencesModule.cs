using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items.References
{
    public class ReferencesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ReferenceResolver>().As<IReferenceResolver>();
        }
    }
}