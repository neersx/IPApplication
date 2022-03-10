using Autofac;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;

namespace InprotechKaizen.Model.Components.Profiles
{
    public class ProfilesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<PreferredCultureSettings>().As<IPreferredCultureSettings>();
            builder.RegisterType<UserTwoFactorAuthPreferenceSettings>().As<IUserTwoFactorAuthPreference>();
            builder.RegisterType<HomePageResolver>().As<IHomeStateResolver>();
            builder.RegisterType<JsonPreferenceManager>().As<IJsonPreferenceManager>();
        }
    }
}
