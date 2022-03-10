using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Filing
{
    public class FilingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<FilingLanguageResolver>().As<IFilingLanguageResolver>();
        }
    }
}