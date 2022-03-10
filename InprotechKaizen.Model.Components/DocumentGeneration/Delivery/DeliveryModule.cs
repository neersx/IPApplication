using Autofac;
using InprotechKaizen.Model.Components.System.Utilities;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Delivery
{
    class DeliveryModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<DocItemRunner>().AsImplementedInterfaces();

            builder.RegisterType<EmailStoredProcedureRunner>().As<IEmailStoredProcedureRunner>();
            builder.RegisterType<EmailRecipientResolver>().As<IEmailRecipientResolver>();

            builder.RegisterType<DeliveryDestinationStoredProcedureRunner>().As<IDeliveryDestinationStoredProcedureRunner>();
            builder.RegisterType<DeliveryDestinationResolver>().As<IDeliveryDestinationResolver>();

        }
    }
}
