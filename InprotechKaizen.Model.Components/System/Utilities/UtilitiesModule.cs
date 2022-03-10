using Autofac;

namespace InprotechKaizen.Model.Components.System.Utilities
{
    public class UtilitiesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<HtmlAsPlainText>().As<IHtmlAsPlainText>();
            builder.RegisterType<TempStorageHandler>().As<ITempStorageHandler>();
        }
    }
}
