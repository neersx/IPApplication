using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Integration.DmsIntegration.Component.Domain;
using Newtonsoft.Json;

namespace Inprotech.Integration.DmsIntegration.Component.iManage
{
    public class IManageSettings : DmsSettings
    {
        public IManageSettings()
        {
            Databases = new SiteDatabaseSettings[0];
            NameTypes = new NameTypeSettings[0];
            Case = new CaseSettings();
        }

        public bool Disabled { get;set; }
        public bool HasDatabaseChanges { get; set; }
        public IEnumerable<SiteDatabaseSettings> Databases { get; set; }
        public IEnumerable<NameTypeSettings> NameTypes { get; set; }
        public CaseSettings Case { get; set; }

        public DataItemsSettings DataItemCodes { get; set; }

        public override IEnumerable<string> NameTypesRequired
        {
            get { return (NameTypes ?? Enumerable.Empty<NameTypeSettings>()).SelectMany(nt => nt.NameType.Split(',')); }
        }

        public string FindSubclassByNameType(string nameType)
        {
            return NameTypes.SingleOrDefault(n => n.NameType.Split(',').Any(nt => nt.Equals(nameType)))?.SubClass;
        }

        public class CaseSettings
        {
            public string SearchField { get; set; }
            public string SubClass { get; set; }
            public string SubType { get; set; }
        }

        public class NameTypeSettings
        {
            public string SubClass { get; set; }
            public string NameType { get; set; }
        }

        public class SiteDatabaseSettings
        {
            string _accessTokenUrl;

            string _authUrl;

            string _callBackUrl;
            public string SiteDbId { get; set; }
            public string Database { get; set; }
            [JsonIgnore]
            public IEnumerable<string> Databases => Database.Split(new[] {','}, StringSplitOptions.RemoveEmptyEntries).Select(_ => _.Trim()).Where(_ => !string.IsNullOrWhiteSpace(_));
            public string Server { get; set; }
            public string IntegrationType { get; set; }
            public string LoginType { get; set; }
            public int? CustomerId { get; set; }
            public string Password { get; set; }
            public string CallbackUrl
            {
                get => _callBackUrl;
                set => _callBackUrl = value?.Trim() ?? string.Empty;
            }

            public string AuthUrl
            {
                get => _authUrl;
                set => _authUrl = value?.Trim() ?? string.Empty;
            }

            public string AccessTokenUrl
            {
                get => _accessTokenUrl;
                set => _accessTokenUrl = value?.Trim() ?? string.Empty;
            }

            public string ClientId { get; set; }

            public string ClientSecret { get; set; }

            [JsonIgnore]
            public bool IsUsernamePasswordRequired => LoginType == LoginTypes.UsernamePassword;

            [JsonIgnore]
            public bool IsUsernameWithImpersonationEnabled => LoginType == LoginTypes.UsernameWithImpersonation;

            [JsonIgnore]
            public bool IsInprotechUsernameWithImpersonationEnabled => LoginType == LoginTypes.InprotechUsernameWithImpersonation;

            [JsonIgnore]
            public bool IsOAuth2Enabled => LoginType == LoginTypes.OAuth;

            public Uri ServerUrl()
            {
                if (!string.IsNullOrWhiteSpace(Server) &&
                    Uri.TryCreate(Server, UriKind.Absolute, out var uri))
                {
                    return uri;
                }

                return null;
            }
        }

        public static class IntegrationTypes
        {
            public const string iManageWorkApiV1 = "iManage Work API V1";
            public const string iManageWorkApiV2 = "iManage Work API V2";
            public const string iManageCOM = "iManage COM";
            public const string Demo = "Demo";

            public static bool Contains(string value)
            {
                return value == iManageCOM || value == iManageWorkApiV2 || value == iManageWorkApiV1 || value == Demo;
            }
        }

        public static class LoginTypes
        {
            public const string UsernamePassword = "UsernamePassword";
            public const string TrustedLogin = "TrustedLogin";
            public const string TrustedLogin2 = "TrustedLogin2";
            public const string UsernameWithImpersonation = "UsernameWithImpersonation";
            public const string InprotechUsernameWithImpersonation = "InprotechUsernameWithImpersonation";
            public const string OAuth = "OAuth 2.0";

            public static bool Contains(string value)
            {
                return value == UsernamePassword || value == TrustedLogin || value == TrustedLogin2 || value == UsernameWithImpersonation || value == InprotechUsernameWithImpersonation || value == OAuth;
            }
        }

        public static class SearchFields
        {
            public const string CustomField1 = "CustomField1";
            public const string CustomField2 = "CustomField2";
            public const string CustomField3 = "CustomField3";
            public const string CustomField1And2 = "CustomField1And2";
        }

        public class DataItemsSettings
        {
            public string NameDataItem { get; set; }
            public string CaseDataItem { get; set; }
        }
    }

    public class IManageTestSettings
    {
        public string UserName { get; set; }
        public string Password { get; set; }
        public IManageSettings Settings { get; set; }
    }

    public static class SiteDatabaseSettingsExtension
    {
        public static IEnumerable<string> CallbackUrls(this IManageSettings.SiteDatabaseSettings settings)
        {
            return (settings.CallbackUrl ?? string.Empty).Split(new[] { Environment.NewLine, "\n" },
                                                                StringSplitOptions.RemoveEmptyEntries);
        }

        public static string GetCallbackUrlOrThrow(this IManageSettings.SiteDatabaseSettings settings, HttpRequestMessage request)
        {
            var requiredCallbackUrl = request.RequestUri.ReplaceStartingFromSegment("api", $"{Uri.EscapeUriString("api/dms/imanage/auth/redirect")}").ToString();
            var configuredCallbackUrl = settings.CallbackUrls().SingleOrDefault(_ => _.IgnoreCaseEquals(requiredCallbackUrl));
            if (string.IsNullOrWhiteSpace(configuredCallbackUrl))
            {
                throw new Exception($"Expected '{requiredCallbackUrl}' to have been configured, but not");
            }

            return configuredCallbackUrl;
        }
    }
}