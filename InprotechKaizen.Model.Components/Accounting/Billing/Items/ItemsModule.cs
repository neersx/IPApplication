using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Items
{
    public class ItemsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<GetOpenItemCommand>().As<IGetOpenItemCommand>();
            builder.RegisterType<OpenItemStatusResolver>().As<IOpenItemStatusResolver>();
            builder.RegisterType<FinaliseBillValidator>().As<IFinaliseBillValidator>();
            builder.RegisterType<DebitOrCreditNotes>().As<IDebitOrCreditNotes>();
            builder.RegisterType<OpenItemService>().As<IOpenItemService>();
            builder.RegisterType<OpenItemNumbers>().As<IOpenItemNumbers>();
        }
    }
}
