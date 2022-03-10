using Autofac;
using InprotechKaizen.Model.Components.Accounting.Billing.Delivery.Type;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Delivery
{
    public class DeliveryModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CapabilitiesResolver>().As<ICapabilitiesResolver>();
            builder.RegisterType<BillXmlProfileResolver>().As<IBillXmlProfileResolver>();
            builder.RegisterType<FinalisedBillDetailsResolver>().As<IFinalisedBillDetailsResolver>();
            builder.RegisterType<BillDelivery>().As<IBillDelivery>();
            
            builder.RegisterType<SendBillingProfileFileToDmsLocation>()
                   .Keyed<IBillDeliveryService>(BillGenerationType.GenerateThenSendToDms);
            
            builder.RegisterType<AttachToCasesAndNames>()
                   .Keyed<IBillDeliveryService>(BillGenerationType.GenerateThenAttachToCase);
        }
    }
}