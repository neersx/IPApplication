using System.Collections.Generic;
namespace Inprotech.Setup.Core
{
    public class WebConfig
    {
        public string InprotechConnectionString { get; internal set; }

        public string InprotechAdministrationConnectionString { get; internal set; }

        public string IntegrationAdministrationConnectionString { get; internal set; }

        public string AuthenticationMode { get; set; }

        public string IntegrationConnectionString { get; internal set; }

        public string SmtpServer { get; set; }

        public string CookieName { get; set; }

        public string CookiePath { get; set; }

        public string CookieDomain { get; set; }

        public string TimeoutInterval { get; set; }
        
        public string ContactUsEmailAddress { get; set; }

        public string IwsMachineName { get; set; }

        public string IwsDmsMachineName { get; set; }

        public string IwsAttachmentMachineName { get; set; }

        public string IwsReportsMachineName { get; set; }

        public string ReportProvider { get; set; }

        public string ReportServiceUrl { get; set; }

        public string ReportServiceEntryFolder { get; set; }

        public string EnableHsts { get; set; }

        public string HstsMaxAge { get; set; }

        public IEnumerable<string> FeaturesAvailable { get; set; }

        public WebConfigBackup Backup { get; internal set; }

        public string InprotechVersionFriendlyName { get; internal set; }
    }

    public class WebConfigBackup
    {
        public WebConfigBackup()
        {
            Exists = false;
        }
        public bool Exists { get; internal set; }

        public string AuthenticationMode { get; internal set; }
    }
}