using InprotechKaizen.Model.Security;

namespace Inprotech.Tests.Web.Builders.Model.Security
{
    public class ExternalCredentialsBuilder : IBuilder<ExternalCredentials>
    {
        public string ProviderName { get; set; }
        public User User { get; set; }

        public ExternalCredentials Build()
        {
            return new ExternalCredentials(
                                           User,
                                           Fixture.String("Username"),
                                           Fixture.String("Password"),
                                           ProviderName ?? Fixture.String("ProviderName"));
        }

        public static ExternalCredentialsBuilder WithParams(string providerName, User user)
        {
            return new ExternalCredentialsBuilder
            {
                ProviderName = providerName,
                User = user
            };
        }
    }
}