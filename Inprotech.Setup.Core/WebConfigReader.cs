using System;
using System.Data.SqlClient;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;
using Microsoft.Web.Administration;
using NLog;

namespace Inprotech.Setup.Core
{
    public interface IWebConfigReader
    {
        WebConfig Read(string root, ManagedPipelineMode pipelineMode);
    }

    class WebConfigReader : IWebConfigReader
    {
        static readonly Logger Logger = LogManager.GetCurrentClassLogger();

        readonly IFileSystem _fileSystem;
        readonly IAvailableFeatures _availableFeatures;
        readonly IAuthenticationMode _authMode;
        readonly IWebConfigBackupReader _webConfigBackupReader;

        public WebConfigReader(IFileSystem fileSystem, IAvailableFeatures availableFeatures, IAuthenticationMode authMode, IWebConfigBackupReader webConfigBackupReader)
        {
            _fileSystem = fileSystem;
            _availableFeatures = availableFeatures;
            _authMode = authMode;
            _webConfigBackupReader = webConfigBackupReader;
        }

        public WebConfig Read(string root, ManagedPipelineMode pipelineMode)
        {
            try
            {
                var webconfigData = ReadInternal(root, pipelineMode);
                webconfigData.Backup = _webConfigBackupReader.Read(root);

                return webconfigData;
            }
            catch (Exception ex)
            {
                Logger.Error(ex, $"web.config location=\"{root}\".");

                return null;
            }
        }

        WebConfig ReadInternal(string root, ManagedPipelineMode pipelineMode)
        {
            var path = Path.Combine(root, "web.config");
            if (!_fileSystem.FileExists(path))
                return null;

            var config = XElement.Load(path);
            var connectionString = (string) (from connectionStrings in config.Elements("connectionStrings")
                                             from add in connectionStrings.Elements("add")
                                             where add.Attribute("name")?.Value == "defaultConnection"
                                             select add.Attribute("connectionString")).SingleOrDefault();

            var smtpServer = (from appSettingSection in config.Elements("appSettings")
                              from add in appSettingSection.Elements("add")
                              where add.Attribute("key")?.Value == "SmtpServer"
                              select add.Attribute("value")?.Value).SingleOrDefault();

            var cookieName = (string)(from loc in config.Elements("location")
                                           from web in loc.Elements("system.web")
                                           from auth in web.Elements("authentication")
                                           from formEle in auth.Elements("forms")
                                           select formEle.Attribute("name")).SingleOrDefault();

            var cookiePath = (string)(from loc in config.Elements("location")
                                      from web in loc.Elements("system.web")
                                      from auth in web.Elements("authentication")
                                      from formEle in auth.Elements("forms")
                                      select formEle.Attribute("path")).SingleOrDefault();
            
            var cookieDomain = (string)(from loc in config.Elements("location")
                                      from web in loc.Elements("system.web")
                                      from auth in web.Elements("authentication")
                                      from formEle in auth.Elements("forms")
                                      select formEle.Attribute("domain")).SingleOrDefault();

            var timeoutInterval = (string)(from loc in config.Elements("location")
                                      from web in loc.Elements("system.web")
                                      from auth in web.Elements("authentication")
                                      from formEle in auth.Elements("forms")
                                      select formEle.Attribute("timeout")).SingleOrDefault();
            
            var contactUsEmailAddress = (from appSettingSection in config.Elements("appSettings")
                                         from add in appSettingSection.Elements("add")
                                         where add.Attribute("key")?.Value == "ContactUsEmailAddress"
                                         select add.Attribute("value")?.Value).SingleOrDefault();
            
            var iwsMachineName = (from appSettingSection in config.Elements("appSettings")
                             from add in appSettingSection.Elements("add")
                             where add.Attribute("key")?.Value == "InprotechServices_MachineName"
                             select add.Attribute("value")?.Value).SingleOrDefault();

            var iwsReportsMachineName = (from appSettingSection in config.Elements("appSettings")
                                  from add in appSettingSection.Elements("add")
                                  where add.Attribute("key")?.Value == "InprotechServices_Reports_MachineName"
                                  select add.Attribute("value")?.Value).SingleOrDefault();

            var reportServiceUrl = (from appSettingSection in config.Elements("appSettings")
                                  from add in appSettingSection.Elements("add")
                                  where add.Attribute("key")?.Value == "ReportServiceUrl"
                                  select add.Attribute("value")?.Value).SingleOrDefault();

            var reportServiceEntryFolder = (from appSettingSection in config.Elements("appSettings")
                                  from add in appSettingSection.Elements("add")
                                  where add.Attribute("key")?.Value == "ReportServiceEntryFolder"
                                  select add.Attribute("value")?.Value).SingleOrDefault();

            var reportProvider = (from appSettingSection in config.Elements("appSettings")
                                  from add in appSettingSection.Elements("add")
                                  where add.Attribute("key")?.Value == "ReportProvider"
                                  select add.Attribute("value")?.Value).SingleOrDefault();
            
            var iwsDmsMachineName = (from appSettingSection in config.Elements("appSettings")
                             from add in appSettingSection.Elements("add")
                             where add.Attribute("key")?.Value == "InprotechServices_DMS_Worksite_MachineName"
                             select add.Attribute("value")?.Value).SingleOrDefault();

            var iwsAttachmentMachineName = (from appSettingSection in config.Elements("appSettings")
                                     from add in appSettingSection.Elements("add")
                                     where add.Attribute("key")?.Value == "InprotechServices_ContactActivity_Attachment_MachineName"
                                     select add.Attribute("value")?.Value).SingleOrDefault();

            var inprotechVersionFriendlyName = (from appSettingSection in config.Elements("appSettings")
                                                 from add in appSettingSection.Elements("add")
                                                 where add.Attribute("key")?.Value == "InprotechVersionFriendlyName"
                                                 select add.Attribute("value")?.Value).SingleOrDefault();

            var hstsRule = config.XPathSelectElements("//outboundRules/rule/match[@serverVariable='RESPONSE_Strict_Transport_Security']").FirstOrDefault();

            return new WebConfig
            {
                InprotechConnectionString = connectionString,
                InprotechAdministrationConnectionString =
                    InprotechAdministrationConnectionString(connectionString),
                IntegrationConnectionString = IntegrationConnectionString(connectionString),
                IntegrationAdministrationConnectionString =
                    IntegrationAdministrationConnectionString(connectionString),
                AuthenticationMode = _authMode.Resolve(config),
                FeaturesAvailable = _availableFeatures.Resolve(config, pipelineMode),
                SmtpServer = smtpServer,
                CookieName = cookieName,
                CookiePath = cookiePath,
                CookieDomain = cookieDomain,
                TimeoutInterval = timeoutInterval,
                ContactUsEmailAddress = contactUsEmailAddress,
                IwsMachineName = iwsMachineName,
                IwsDmsMachineName = iwsDmsMachineName,
                ReportProvider = reportProvider,
                IwsReportsMachineName = iwsReportsMachineName,
                ReportServiceEntryFolder = reportServiceEntryFolder,
                ReportServiceUrl = reportServiceUrl,
                IwsAttachmentMachineName = iwsAttachmentMachineName,
                InprotechVersionFriendlyName = inprotechVersionFriendlyName,
                HstsMaxAge = HstsMaxAge(hstsRule),
                EnableHsts = (hstsRule != null).ToString()
            };
        }

        static string HstsMaxAge(XElement hstsRule)
        {
            if (hstsRule == null || hstsRule.Parent == null) return null;

            var maxAge = (from act in hstsRule.Parent.Elements("action")
                  let value = act.Attribute("value")?.Value
                  where value != null && value.Contains("max-age")
                  select act.Attribute("value")?.Value).SingleOrDefault();

            return string.IsNullOrWhiteSpace(maxAge) ? null : maxAge.Remove(0, 8);
        }

        static string InprotechAdministrationConnectionString(string connectionString)
        {
            var builder = new SqlConnectionStringBuilder(connectionString);

            if (builder.IntegratedSecurity)
                return builder.ConnectionString;

            builder.IntegratedSecurity = true;

            return builder.ConnectionString;
        }

        static string IntegrationConnectionString(string connectionString)
        {
            var builder = new SqlConnectionStringBuilder(connectionString);

            builder.InitialCatalog = builder.InitialCatalog + "Integration";

            return builder.ConnectionString;
        }

        static string IntegrationAdministrationConnectionString(string connectionString)
        {
            var builder = new SqlConnectionStringBuilder(connectionString);

            builder.InitialCatalog = builder.InitialCatalog + "Integration";

            if (builder.IntegratedSecurity)
                return builder.ConnectionString;

            builder.IntegratedSecurity = true;

            return builder.ConnectionString;
        }
    }
}