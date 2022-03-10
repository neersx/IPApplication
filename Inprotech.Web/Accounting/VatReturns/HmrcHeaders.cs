using System;
using System.Collections.Generic;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Net.Http;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Hosting;
using Inprotech.Infrastructure.ResponseEnrichment.ApplicationVersion;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Profiles;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;

namespace Inprotech.Web.Accounting.VatReturns
{
    [SuppressMessage("Microsoft.Usage", "CA2237:MarkISerializableTypesWithSerializable")]
    [JsonConverter(typeof(HmrcHeaderConverter))]
    public class HmrcHeaders : Dictionary<string, string>
    {
        public HmrcHeaders(Dictionary<string, string> dict) : base(dict)
        {
            
        }
    }

    internal class HmrcHeaderConverter : JsonConverter
    {
        public override void WriteJson(JsonWriter writer, object value, JsonSerializer serializer)
        {
            var dictionary = (IDictionary<string, string>)value;
            writer.WriteStartObject();
            foreach (var key in dictionary.Keys)
            {
                writer.WritePropertyName(key);
                serializer.Serialize(writer, dictionary[key]);
            }
            writer.WriteEndObject();
        }

        public override object ReadJson(JsonReader reader, Type objectType, object existingValue, JsonSerializer serializer)
        {
            throw new NotImplementedException();
        }

        public override bool CanConvert(Type objectType)
        {
            return objectType.IsAssignableFrom(typeof(HmrcHeaders));
        }
    }

    public interface IFraudPreventionHeaders
    {
        void Include(HttpRequestMessage requestToHmrc, HttpRequestMessage httpInputRequest);
    }

    public class FraudPreventionHeaders : IFraudPreventionHeaders
    {
        readonly IDbContext _dbContext;
        readonly IAppVersion _appVersion;
        readonly IAppSettingsProvider _appSettings;
        readonly ISecurityContext _securityContext;

        static readonly Dictionary<string, string> HmrcClientHeaders = 
            new Dictionary<string, string>
            {
                {"Gov-Client-Public-IP", "x-inprotech-client-public-ip"},
                {"Gov-Client-Timezone","x-inprotech-current-timezone"},
                {"Gov-Client-Screens","x-inprotech-client-screens"},
                {"Gov-Client-Window-Size","x-inprotech-client-window-size"},
                {"Gov-Client-Device-ID","x-inprotech-client-device-id"},
                {"Gov-Client-Browser-Do-Not-Track", "x-inprotech-client-browser-do-not-track"}
            };

        public FraudPreventionHeaders(IDbContext dbContext,IAppVersion appVersion, IAppSettingsProvider appSettings, ISecurityContext securityContext)
        {
            _dbContext = dbContext;
            _appVersion = appVersion;
            _appSettings = appSettings;
            _securityContext = securityContext;
        }

        public void Include(HttpRequestMessage requestToHmrc, HttpRequestMessage httpInputRequest)
        {
            if (requestToHmrc == null) throw new ArgumentNullException(nameof(requestToHmrc));
            if (httpInputRequest == null) throw new ArgumentNullException(nameof(httpInputRequest));
            
            var headers = GetHmrcHeaders(httpInputRequest);
            var referenceHeaderValues = httpInputRequest.Headers;

            foreach (var h in KnownHmrcHeaders.FraudPrevention)
            {
                var clientHeaderValue = string.Empty;
                if (HmrcClientHeaders.TryGetValue(h, out string refHeader) && referenceHeaderValues.TryGetValues(refHeader, out var values))
                    clientHeaderValue = values.FirstOrDefault();

                var resolved = headers.Get(h) ?? clientHeaderValue;
                if (resolved == null) continue;

                requestToHmrc.Headers.Add(h, resolved);
            }
        }

        Dictionary<string, string> GetHmrcHeaders(HttpRequestMessage httpInputRequest)
        {
            var overrides = _dbContext.Set<ExternalSettings>()
                                      .SingleOrDefault(setting => setting.ProviderName == KnownExternalSettings.HmrcHeaders);

            var rawHeaders = overrides?.Settings ?? string.Empty;
            
            var headers = rawHeaders.Split(new[] {"\\n"}, StringSplitOptions.RemoveEmptyEntries)
                                    .Select(part => part.Split(new[] {':'}, StringSplitOptions.RemoveEmptyEntries))
                                    .ToDictionary(k => k[0].Trim(), v => v[1].Trim());
            
            headers.AddOrReplace("Gov-Vendor-Version", $"{GetHmrcApplicationName() ?? "Inprotech"}=App{_appVersion.CurrentVersion}");
            headers.AddOrReplace("Gov-Vendor-Public-IP", headers.Get("Gov-Vendor-Public-IP") ?? _appSettings["PublicIpAddress"]);
            headers.AddOrReplace("Gov-Client-Browser-JS-User-Agent", headers.Get("Gov-Client-Browser-JS-User-Agent") ?? httpInputRequest.Headers.UserAgent.ToString());
            headers.AddOrReplace("Gov-Client-Connection-Method", headers.Get("Gov-Client-Connection-Method") ?? "WEB_APP_VIA_SERVER");
            headers.AddOrReplace("Gov-Client-Multi-Factor", headers.Get("Gov-Client-Multi-Factor") ?? GetClientMultiFactor(httpInputRequest));
            headers.AddOrReplace("Gov-Client-User-IDs", headers.Get("Gov-Client-User-IDs") ?? GetClientUserId());
            headers.AddOrReplace("Gov-Client-Public-Port", headers.Get("Gov-Client-Public-Port") ?? string.Empty);
            headers.AddOrReplace("Gov-Vendor-Forwarded", headers.Get("Gov-Vendor-Forwarded") ?? GetVendorForwarded(headers.Get("Gov-Vendor-Public-IP") ?? _appSettings["PublicIpAddress"],httpInputRequest.Headers.GetValues("x-inprotech-client-public-ip").First()));
            headers.AddOrReplace("Gov-Client-Browser-Plugins", headers.Get("Gov-Client-Browser-Plugins") ?? string.Empty);
            headers.AddOrReplace("Gov-Vendor-License-IDs", headers.Get("Gov-Vendor-License-IDs") ?? GetVendorLicenseId());
            headers.AddOrReplace("Gov-Client-Local-IPs",  headers.Get("Gov-Client-Local-IPs") ?? GetClientLocalIp(httpInputRequest));

            return new HmrcHeaders(headers);
        }

        string GetClientMultiFactor(HttpRequestMessage requestMessage)
        {
            var env = requestMessage.GetOwinContext().Environment;
            if (!env.ContainsKey("Auth2FaMode") || !env.ContainsKey("Auth2FaModeGranted")) return string.Empty;
            var issueDate = (DateTime) env["Auth2FaModeGranted"];
            return $"type=AUTH_CODE&timestamp={issueDate:yyyy-MM-ddThh:mmZ}&unique-reference={Hash.Md5(_securityContext.User.UserName)}";
        }

        string GetClientUserId()
        {
            return "inprotech_login_id=" + _securityContext.User.UserName;
        }

        string GetVendorForwarded(string vendorIp, string clientIp)
        {
            return "by="+ vendorIp + "&for=" + clientIp;
        }
        
        static string GetClientLocalIp(HttpRequestMessage requestMessage)
        {
            return requestMessage.GetOwinContext().Request.RemoteIpAddress;
        }

        string GetVendorLicenseId()
        {
            var vendorLicenseName = (from n in _dbContext.Set<Name>()
                           join sc in _dbContext.Set<SiteControl>() on n.Id equals sc.IntegerValue
                           where sc.ControlId == SiteControls.HomeNameNo
                           select n.LastName).FirstOrDefault();

            return "LicenseId=" + (vendorLicenseName == null ? string.Empty : Hash.Md5(vendorLicenseName));
        }

        string GetHmrcApplicationName()
        {
            var externalSetting = _dbContext.Set<ExternalSettings>()
                                            .SingleOrDefault(_ => _.ProviderName == KnownExternalSettings.HmrcVatSettings);
            if (externalSetting == null) return string.Empty;
            var hmrcSettings = JObject.Parse(externalSetting.Settings).ToObject<HmrcVatSettings>();
            return hmrcSettings.HmrcApplicationName;
        }
    }
}