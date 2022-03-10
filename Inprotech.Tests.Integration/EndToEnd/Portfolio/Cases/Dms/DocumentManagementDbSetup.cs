using Inprotech.Infrastructure;
using Inprotech.Integration.DmsIntegration.Component.iManage;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Configuration.DMSIntegration;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Profiles;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms
{
    public static class IntegrationType
    {
        public const string Work10V1 = "iManage Work API V1";
        public const string Work10V2 = "iManage Work API V2";
    }

    public class DocumentManagementDbSetup : DbSetup
    {
        readonly string[] _siteControlsKeys =
        {
            SiteControls.DMSCaseSearchDocItem,
            SiteControls.DMSNameSearchDocItem
        };

        public void Setup(string integrationType = IntegrationType.Work10V1, string overrideServerName = null, DmsSettingsModel dmsSettings = null)
        {
            dmsSettings = dmsSettings ?? new DmsSettingsModel
            {
                NameType = "I",
                SubType = "work",
                SubClass = "nameView"
            };

            IManageSettings.SiteDatabaseSettings setting;
            if (integrationType == IntegrationType.Work10V2)
            {
                setting = new IManageSettings.SiteDatabaseSettings
                {
                    SiteDbId = "0",
                    Database = "TPSDK",
                    Server = overrideServerName ?? $"{Env.FakeServerUrl}",
                    IntegrationType = integrationType,
                    LoginType = "OAuth 2.0",
                    CustomerId = 999,
                    AuthUrl = $"{Env.FakeServerUrl}/work/auth/oauth2/authorize",
                    AccessTokenUrl = $"{Env.FakeServerUrl}/work/auth/oauth2/token",
                    CallbackUrl = $"{Env.RootUrl}/api/dms/imanage/auth/redirect",
                    ClientId = "12345678-90de-4c79-9182-1234567890abc",
                    ClientSecret = "12345678-90de-4c79-9182-1234567890abc"
                };
            }
            else
            {
                setting = new IManageSettings.SiteDatabaseSettings
                {
                    SiteDbId = "0",
                    Database = "TPSDK",
                    Server = overrideServerName ?? $"{Env.FakeServerUrl}",
                    IntegrationType = integrationType,
                    LoginType = "InprotechUsernameWithImpersonation",
                    CustomerId = 1,
                    Password = "examplePassowrd"
                };
            }

            var nameTypes = new IManageSettingsModel.NameSettings[0];
            if (!string.IsNullOrEmpty(dmsSettings.SubClass) || !string.IsNullOrEmpty(dmsSettings.NameType))
            {
                nameTypes = new[]
                    {
                        new IManageSettingsModel.NameSettings
                        {
                            NameType = dmsSettings.NameType,
                            SubClass = dmsSettings.SubClass
                        }
                    };
            }
            var externalSettings = new ExternalSettings(KnownExternalSettings.IManage)
            {
                Settings = CryptoService.Encrypt(new IManageSettingsModel
                {
                    Case = {SubType = dmsSettings.SubType},
                    NameTypes = nameTypes,
                    Databases = new[]
                    {
                        setting
                    }
                })
            };

            Insert(externalSettings);
            DbContext.SaveChanges();
        }

        public class DmsSettingsModel
        {
            public string SubType { get; set; }
            public string NameType { get; set; }
            public string SubClass { get; set; }
        }
    }
}