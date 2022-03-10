using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Comparison.Translations
{
    public class TranslationsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<EventDescriptionTranslator>()
                   .As<IEventDescriptionTranslator>();
        }
    }
}