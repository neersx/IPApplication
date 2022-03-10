using Autofac;

namespace InprotechKaizen.Model.Components.Accounting
{
    public class AccountingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CaseStatusValidator>().As<ICaseStatusValidator>();
            builder.RegisterType<Entities>().As<IEntities>();
        }
    }
}
