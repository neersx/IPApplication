using Autofac;

namespace Inprotech.Web.Translation
{
    public class TranslationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ResourceFile>().As<IResourceFile>();

            builder.RegisterType<DefaultResourceExtractor>().As<IDefaultResourceExtractor>();
            builder.RegisterType<TranslationSource>().As<ITranslationSource>();
            builder.RegisterType<DeltaPersister>().As<IDeltaPersister>();
        }
    }
}