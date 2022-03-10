using Autofac;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public class WipModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ValidatePostDates>().As<IValidatePostDates>();
            builder.RegisterType<PostWipCommand>().As<IPostWipCommand>();
            builder.RegisterType<AdjustWipCommand>().As<IAdjustWipCommand>();
            builder.RegisterType<SplitWipCommand>().As<ISplitWipCommand>();
            builder.RegisterType<GetWipItemCommand>().As<IGetWipItemCommand>();
            builder.RegisterType<GetWipDefaultsCommand>().As<IGetWipDefaultsCommand>();
            builder.RegisterType<GetWipCostCommand>().As<IGetWipCostCommand>();
            builder.RegisterType<ProtocolDisbursements>().As<IProtocolDisbursements>();
        }
    }
}
