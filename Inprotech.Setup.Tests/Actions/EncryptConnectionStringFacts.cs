using System.Collections.Generic;
using System.Configuration;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class EncryptConnectionStringFacts
    {
        public EncryptConnectionStringFacts()
        {
            _eventStream = Substitute.For<IEventStream>();
            _context = new Dictionary<string, object>();
            _encryptConnectionStringAction = new EncryptConnectionString();
        }

        readonly IEventStream _eventStream;
        readonly IDictionary<string, object> _context;
        readonly EncryptConnectionString _encryptConnectionStringAction;

        [Fact]
        public void ShouldEncryptInprotechServerConnectionString()
        {
            _context["InstanceDirectory"] = "Assets/instance-1";

            // protect section
            _encryptConnectionStringAction.Run(_context, _eventStream);

            var updatedInprotechServerConfig = ConfigurationUtility.ReadConfigFile(_context.InprotechServerConfigFilePath());
            var inprotechServerConnectionStringSection = updatedInprotechServerConfig.GetSection("connectionStrings");

            Assert.True(inprotechServerConnectionStringSection.SectionInformation.IsProtected);

            var updatedIntegrationServerConfig = ConfigurationUtility.ReadConfigFile(_context.InprotechIntegrationServerConfigFilePath());
            var inprotechIntegrationServerConnectionStringSection = updatedIntegrationServerConfig.GetSection("connectionStrings");

            Assert.True(inprotechIntegrationServerConnectionStringSection.SectionInformation.IsProtected);

            //Unprotect section
            inprotechServerConnectionStringSection.SectionInformation.UnprotectSection();
            ConfigurationManager.RefreshSection("connectionStrings");
            updatedInprotechServerConfig.Save(ConfigurationSaveMode.Full);

            Assert.False(inprotechServerConnectionStringSection.SectionInformation.IsProtected);

            inprotechIntegrationServerConnectionStringSection.SectionInformation.UnprotectSection();
            ConfigurationManager.RefreshSection("connectionStrings");
            updatedIntegrationServerConfig.Save(ConfigurationSaveMode.Full);

            Assert.False(inprotechIntegrationServerConnectionStringSection.SectionInformation.IsProtected);
        }
    }
}