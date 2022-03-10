namespace InprotechKaizen.Model.Components.Integration.Exchange
{
    public class ExchangeConfigurationSettings
    {
        public string ServiceType { get; set; }
        public string Server { get; set; }
        public string Domain { get; set; }
        public string UserName { get; set; }
        public string Password { get; set; }
        public bool IsReminderEnabled { get; set; }
        public bool IsDraftEmailEnabled { get; set; }
        public bool IsBillFinalisationEnabled { get; set; }
        public ExchangeGraph ExchangeGraph { get; set; }
        public bool SupressConsentPrompt { get; set; }
        public bool RefreshTokenNotRequired { get; set; }

    }

    public class ExchangeGraph
    {
        public string TenantId { get; set; }
        public string ClientId { get; set; }
        public string ClientSecret { get; set; }
    }
 }