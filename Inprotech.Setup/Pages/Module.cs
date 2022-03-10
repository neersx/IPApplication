using Autofac;
using Caliburn.Micro;

namespace Inprotech.Setup.Pages
{
    public class Module : Autofac.Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<BasicSettingViewModel>().Keyed<Screen>(ScreenType.Basic);
            builder.RegisterType<AuthenticationModesViewModel>().Keyed<Screen>(ScreenType.AuthMode);
            builder.RegisterType<AdfsSettingsViewModel>().Keyed<Screen>(ScreenType.Adfs);
            builder.RegisterType<IpPlatformSettingsViewModel>().Keyed<Screen>(ScreenType.Sso);
            builder.RegisterType<CookieConsentViewModel>().Keyed<Screen>(ScreenType.CookieConsent);
            builder.RegisterType<ProductImprovementViewModel>().Keyed<Screen>(ScreenType.ProductImprovement);

            builder.RegisterTypes(
                typeof(ShellView),
                typeof(IisAppSelectionView),
                typeof(IisAppDetailsView),
                typeof(HomeView),
                typeof(SetupRunnerView),
                typeof(ScheduledActionView),
                typeof(EventView),
                typeof(PairedWebAppView),
                typeof(BasicSettingView),
                typeof(AuthenticationModesView),
                typeof(HomeViewModel),
                typeof(IisAppSelectionViewModel),
                typeof(IisAppDetailsViewModel),
                typeof(SetupRunnerViewModel),
                typeof(ScheduledActionViewModel),
                typeof(EventViewModel),
                typeof(PairedWebAppViewModel),
                typeof(IisAppSelectionItemViewModel),
                typeof(IpPlatformSettingsView),
                typeof(AdfsSettingsView),
                typeof(SettingsView),
                typeof(SettingsViewModel),
                typeof(CookieConsentView),
                typeof(ProductImprovementView))
                    .AsSelf();
        }
    }
}