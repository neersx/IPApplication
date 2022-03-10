using System;
using System.Linq;
using System.Net;
using Inprotech.Integration.ExternalApplications;
using Inprotech.Tests.Integration.DbHelpers;
using Newtonsoft.Json;

namespace Inprotech.Tests.Integration
{
    [AttributeUsage(AttributeTargets.Class, AllowMultiple = true)]
    public class ChangeAppSettings : Attribute
    {
        public ChangeAppSettings(AppliesTo appliesTo, string key, string value)
        {
            AppliesTo = appliesTo;
            Key = key;
            Value = value;
        }

        public AppliesTo AppliesTo { get; }

        public string Key { get; }

        public string ConfigSettingsKey { get; set; }

        public string Value { get; }
    }

    public enum AppliesTo
    {
        InprotechServer,
        IntegrationServer
    }

    public class SettingsValue
    {
        public string Value { get; set; }
    }

    public static class Helper
    {
        public static string Jsonify(string value)
        {
            return JsonConvert.SerializeObject(new SettingsValue
            {
                Value = value
            });
        }

        public static string Stringify(string value)
        {
            return JsonConvert.DeserializeObject<SettingsValue>(value).Value;
        }

        public static string GetOrCreateToken()
        {
            using (var db = new IntegrationDbSetup())
            {
                var ctx = db.IntegrationDbContext;
                var ext = ctx.Set<ExternalApplication>();
                var e = ext.SingleOrDefault(_ => _.Name == "E2E") ?? db.Insert(new ExternalApplication
                {
                    Name = "E2E",
                    CreatedOn = DateTime.Now,
                    CreatedBy = -1
                });

                var token = e.ExternalApplicationToken ?? db.Insert(new ExternalApplicationToken
                {
                    ExternalApplication = e,
                    Token = Guid.NewGuid().ToString(),
                    CreatedOn = DateTime.Now,
                    ExpiryDate = DateTime.Now + TimeSpan.FromDays(2),
                    IsActive = true
                });

                return token.Token;
            }
        }
    }

    public static class SettingsModifier
    {
        public static string UpdateSetting(AppliesTo @for, string key, string value, string configSettingsKey, string classAndMethodName)
        {
            var keyToLog = !string.IsNullOrWhiteSpace(configSettingsKey) ? $"{key}/{configSettingsKey}" : key;
            RunnerInterface.Log($"Request Settings to be Modified: {@for} {keyToLog} ({classAndMethodName})");
            
            string apiUrl;
            switch (@for)
            {
                case AppliesTo.InprotechServer:
                    apiUrl = $"{Env.RootUrl}/api/e2e/settings?key={key}&configSettingKey={configSettingsKey}&context={classAndMethodName}";
                    break;
                case AppliesTo.IntegrationServer:
                    apiUrl = $"{Env.RootUrl}/api/e2e/integration-settings?key={key}&context={classAndMethodName}";
                    break;

                default: throw new NotImplementedException();
            }

            var client = new WebClient
            {
                Headers =
                {
                    ["X-ApiKey"] = Helper.GetOrCreateToken(),
                    ["Content-Type"] = "application/json"
                }
            };

            return Helper.Stringify(client.UploadString(apiUrl, "PUT", Helper.Jsonify(value)));
        }
    }

    public static class InprotechServer
    {
        public static void InterruptJobsScheduler()
        {
            RunnerInterface.Log("Request Job Scheduler to be interrupted");

            var client = new WebClient
            {
                Headers =
                {
                    ["X-ApiKey"] = Helper.GetOrCreateToken(),
                    ["Content-Type"] = "application/json"
                }
            };

            client.UploadString($"{Env.RootUrl}/api/e2e/interrupt-schedulers", "PUT", string.Empty);
        }
        
        public static string ClientRoot()
        {
            RunnerInterface.Log("Request client-root");

            var apiUrl = $"{Env.RootUrl}/api/e2e/client-root";
            
            var client = new WebClient
            {
                Headers =
                {
                    ["X-ApiKey"] = Helper.GetOrCreateToken(),
                    ["Content-Type"] = "application/json"
                }
            };
            
            return Helper.Stringify(client.DownloadString(apiUrl));
        }
        
        public static DateTime CurrentUtcTime()
        {
            RunnerInterface.Log("Request server time in utc");

            var apiUrl = $"{Env.RootUrl}/api/e2e/serverTimeUtc";
            var client = new WebClient
            {
                Headers =
                {
                    ["X-ApiKey"] = Helper.GetOrCreateToken(),
                    ["Content-Type"] = "application/json"
                }
            };
            var response = Helper.Stringify(client.DownloadString(apiUrl));

            return new DateTime(long.Parse(response)).ToUniversalTime();
        }

        public static void UpdateMailSettingsForInprotechAndIntegrationServer(string mailPickupLocation)
        {
            RunnerInterface.Log($"Request Mail Settings to be Modified: {mailPickupLocation}");

            var client = new WebClient
            {
                Headers =
                {
                    ["X-ApiKey"] = Helper.GetOrCreateToken(),
                    ["Content-Type"] = "application/json"
                }
            };

            client.UploadString($"{Env.RootUrl}/api/e2e/mail-settings", "PUT", Helper.Jsonify(mailPickupLocation));
        }
    }
}