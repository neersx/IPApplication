using Autofac;

namespace Inprotech.Web.Configuration.Keywords
{
    public class KeywordsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<KeywordsService>().As<IKeywords>();
        }
    }
}
