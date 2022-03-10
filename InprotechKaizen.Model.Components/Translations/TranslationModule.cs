using Autofac;

namespace InprotechKaizen.Model.Components.Translations
{
    public class TranslationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<LookupCultureResolver>().AsImplementedInterfaces();
            builder.RegisterType<TranslationMetadataLoader>().AsImplementedInterfaces();
            builder.RegisterType<TidColumnLoader>().AsImplementedInterfaces();
            builder.RegisterType<TranslatedTextLoader>().AsImplementedInterfaces();
            builder.RegisterType<TranslationBuilder>().AsImplementedInterfaces();
            builder.RegisterType<TranslationDeltaApplier>().As<ITranslationDeltaApplier>().AsSelf();
        }
    }
}