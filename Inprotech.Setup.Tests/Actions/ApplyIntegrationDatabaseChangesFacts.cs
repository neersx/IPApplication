using System.Collections.Generic;
using System.Data.SqlClient;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class ApplyIntegrationDatabaseChangesFacts
    {
        public ApplyIntegrationDatabaseChangesFacts()
        {
            _eventStream = Substitute.For<IEventStream>();
            _context = new Dictionary<string, object>();
            _processRunner = Substitute.For<IProcessRunner>();
            _processRunner.Run(string.Empty, string.Empty).ReturnsForAnyArgs(new CommandLineUtilityResult());
            _applyIntegrationDatabaseChanges = new ApplyIntegrationDatabaseChanges(_processRunner);
        }

        readonly IEventStream _eventStream;
        readonly IDictionary<string, object> _context;
        readonly ApplyIntegrationDatabaseChanges _applyIntegrationDatabaseChanges;
        readonly IProcessRunner _processRunner;

        [Fact]
        public void InvokesDatabaseExeWithCorrectArguments()
        {
            _context["IntegrationAdministrationConnectionString"] =
                new SqlConnectionStringBuilder(
                                               "Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=Inprotech Web")
                    .ConnectionString;

            _applyIntegrationDatabaseChanges.Run(_context, _eventStream);

            _processRunner.Received().Run("Content\\Database\\InprotechKaizen.Database.exe", "-m InprotechIntegration -c \"Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=\\\"Inprotech Web\\\"\"");
        }
    }
}