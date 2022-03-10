using Autofac;

namespace Inprotech.Web.SavedSearch
{
    public class SavedSearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SavedSearchMenu>().As<ISavedSearchMenu>();
        }
    }
}
