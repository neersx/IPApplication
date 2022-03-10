using Autofac;
using InprotechKaizen.Model.Components.Search.WipOverview;

namespace InprotechKaizen.Model.Components.Search
{
    internal class SearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<CreateBillValidator>().As<ICreateBillValidator>();
        }
    }
}
