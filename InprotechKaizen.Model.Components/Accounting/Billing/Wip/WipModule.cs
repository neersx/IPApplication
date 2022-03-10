using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Billing.Wip
{
    internal class WipModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<AvailableWipItemCommands>().As<IAvailableWipItemCommands>();
            builder.RegisterType<DiscountsAndMargins>().As<IDiscountsAndMargins>();
            builder.RegisterType<DefaultTaxCodeResolver>().As<IDefaultTaxCodeResolver>();
            builder.RegisterType<DraftWipAdditionalDetailsResolver>().As<IDraftWipAdditionalDetailsResolver>();
            builder.RegisterType<WipItemsService>().As<IWipItemsService>();
            builder.RegisterType<DraftWipItem>().As<IDraftWipItem>();
        }
    }
}
