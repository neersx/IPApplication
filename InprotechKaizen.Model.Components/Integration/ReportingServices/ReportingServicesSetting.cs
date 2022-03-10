using System.ComponentModel;

namespace InprotechKaizen.Model.Components.Integration.ReportingServices
{
    public class ReportingServicesSetting
    {
        public ReportingServicesSetting()
        {
            foreach (PropertyDescriptor property in TypeDescriptor.GetProperties(this))
            {
                var myAttribute = (DefaultValueAttribute) property.Attributes[typeof(DefaultValueAttribute)];

                if (myAttribute != null)
                {
                    property.SetValue(this, myAttribute.Value);
                }
            }
        }

        [DefaultValue(105)]
        public int MessageSize { get; set; }

        [DefaultValue(10)]
        public int Timeout { get; set; }

        public string RootFolder { get; set; }

        public string ReportServerBaseUrl { get; set; }

        public SecurityElement Security { get; set; }
    }

    public class SecurityElement
    {
        public string Username { get; set; }

        public string Password { get; set; }

        public string Domain { get; set; }
    }

    public static class SecurityElementExtension
    {
        public static bool IsEmpty(this SecurityElement securityElement)
        {
            return string.IsNullOrWhiteSpace(securityElement.Username) || 
                   string.IsNullOrWhiteSpace(securityElement.Password);
        }
    }

    public static class ReportingServicesSettingExtension
    {
        public static bool IsValid(this ReportingServicesSetting settings)
        {
            return !string.IsNullOrWhiteSpace(settings?.RootFolder) &&
                   !string.IsNullOrWhiteSpace(settings.ReportServerBaseUrl);
        }
    }
}