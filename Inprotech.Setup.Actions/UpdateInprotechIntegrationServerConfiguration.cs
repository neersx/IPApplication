using System;
using System.Collections.Generic;
using System.Xml;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;

namespace Inprotech.Setup.Actions
{
    public class UpdateInprotechIntegrationServerConfiguration : ISetupAction
    {
        public string Description => "Update Inprotech Integration Server configuration";

        public bool ContinueOnException => false;

        public void Run(IDictionary<string, object> context, IEventStream eventStream)
        {
            if (context == null) throw new ArgumentNullException(nameof(context));
            if (eventStream == null) throw new ArgumentNullException(nameof(eventStream));

            UpdateAppConfig(context);
            UpdateAppSettings(context);
        }

        static void UpdateAppConfig(IDictionary<string, object> context)
        {
            var integrationConnectionString = (string) context["IntegrationConnectionString"];

            var inprotechConnectionString = (string) context["InprotechConnectionString"];

            var path = context.InprotechIntegrationServerConfigFilePath();

            var doc = new XmlDocument();
            doc.Load(path);

            ConfigurationUtility.UpdateSmtpSettings(doc, (string)context["SmtpServer"]);

            doc.Save(path);

            ConfigurationUtility.UpdateConnectionString(path, "InprotechIntegration", integrationConnectionString);

            ConfigurationUtility.UpdateConnectionString(path, "Inprotech", inprotechConnectionString);
        }

        static void UpdateAppSettings(IDictionary<string, object> context)
        {
            var addOrUpdateSettings = new Dictionary<string, string>
                                      {
                                          {
                                              "InstanceName",
                                              (string) context["InstanceName"]
                                          },
                                          {
                                              "AuthenticationMode",
                                              (string) context["AuthenticationMode"]
                                          },
                                          {
                                              "Authentication2FAMode",
                                              (string) context["Authentication2FAMode"]
                                          },
                                          {
                                              "Port",
                                              (string) context["IntegrationServer.Port"]
                                          }
                                      };

            if (context.ContainsKey("IsE2EMode") && (bool) context["IsE2EMode"])
            {
                addOrUpdateSettings["e2e"] = "true";
            }

            if (context.ContainsKey("BypassSslCertificateCheck") && (bool) context["BypassSslCertificateCheck"])
            {
                addOrUpdateSettings["BypassSslCertificateCheck"] = "true";
            }

            if (context.ContainsKey("IpPlatformSettings"))
            {
                var ipPlatformSettings = context["IpPlatformSettings"] as IpPlatformSettings;
                if (ipPlatformSettings != null)
                {
                    addOrUpdateSettings.Add(Constants.IpPlatformSettings.ClientId, ipPlatformSettings.ClientId);
                    addOrUpdateSettings.Add(Constants.IpPlatformSettings.ClientSecret, ipPlatformSettings.ClientSecret);
                }
            }

            ConfigurationUtility.AddUpdateAppSettings(context.InprotechIntegrationServerConfigFilePath(), addOrUpdateSettings);
        }
    }
}