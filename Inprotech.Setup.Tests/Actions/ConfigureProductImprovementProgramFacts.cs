using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    internal class ConfigureProductImprovementProgramFacts
    {
        public ConfigureProductImprovementProgramFacts()
        {
            _eventStream = Substitute.For<IEventStream>();
            _configManager = Substitute.For<IInprotechServerPersistingConfigManager>();
            _subject = new ConfigureProductImprovementProgram(_configManager);
        }

        readonly ConfigureProductImprovementProgram _subject;
        readonly IInprotechServerPersistingConfigManager _configManager;
        readonly IEventStream _eventStream;

        [Fact]
        public async Task ShouldNotSaveIfNoKeyInContext()
        {
            _subject.Run(new Dictionary<string, object>(), _eventStream);

            _configManager.DidNotReceive().SaveProductImprovement(Arg.Any<string>(), Arg.Any<string>());
            _eventStream.DidNotReceive().PublishInformation(Arg.Any<string>());
        }

        [Fact]
        public async Task ShouldSaveIfKeyInContext()
        {
            var connectionString = Fixture.String();
            _subject.Run(new Dictionary<string, object>
            {
                {"UsageStatisticsSettings", new UsageStatisticsSettings()},
                {"InprotechConnectionString", connectionString}
            }, _eventStream);

            _configManager.Received(1).SaveProductImprovement(connectionString, Arg.Any<string>());
            _eventStream.Received(1).PublishInformation(Arg.Any<string>());
        }
    }
}