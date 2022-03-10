using System.Collections.Generic;
using System.Data.SqlClient;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class ApplyInprotechDatabaseChangesFacts
    {
        public ApplyInprotechDatabaseChangesFacts()
        {
            _eventStream = Substitute.For<IEventStream>();
            _context = new Dictionary<string, object>();
            _processRunner = Substitute.For<IProcessRunner>();
            _processRunner.Run(string.Empty, string.Empty).ReturnsForAnyArgs(new CommandLineUtilityResult());
            _applyInprotechDatabaseChangesFacts = new ApplyInprotechDatabaseChanges(_processRunner);
        }

        readonly IEventStream _eventStream;
        readonly IDictionary<string, object> _context;
        readonly ApplyInprotechDatabaseChanges _applyInprotechDatabaseChangesFacts;
        readonly IProcessRunner _processRunner;

        [Fact]
        public void InvokesDatabaseExeWithCorrectArguments()
        {
            _context["InprotechAdministrationConnectionString"] =
                new SqlConnectionStringBuilder(
                                               "Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=Inprotech Web")
                    .ConnectionString;

            _applyInprotechDatabaseChangesFacts.Run(_context, _eventStream);

            _processRunner.Received().Run("Content\\Database\\InprotechKaizen.Database.exe", "-m Inprotech -c \"Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=\\\"Inprotech Web\\\"\"");
        }
    }
}