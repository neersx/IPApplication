using System.Collections.Generic;
using System.Data.SqlClient;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Actions.Utilities;
using Inprotech.Setup.Contracts.Immutable;
using Inprotech.Setup.Core.Utilities;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class FailedDatabaseScriptFacts
    {
        public FailedDatabaseScriptFacts()
        {
            _context = new Dictionary<string, object>();
            _eventStream = Substitute.For<IEventStream>();
            _fileSystem = Substitute.For<IFileSystem>();
            _processRunner = Substitute.For<IProcessRunner>();
            _processRunner.Run(string.Empty, string.Empty).ReturnsForAnyArgs(new CommandLineUtilityResult());

            _subject = new FailedDatabaseScript(_processRunner, _fileSystem);
        }

        readonly IDictionary<string, object> _context;
        readonly IEventStream _eventStream;
        readonly IFileSystem _fileSystem;
        readonly FailedDatabaseScript _subject;
        readonly IProcessRunner _processRunner;

        [Fact]
        public void InvokesDatabaseExeForInprotech()
        {
            _context["InprotechAdministrationConnectionString"] =
                new SqlConnectionStringBuilder(
                                               "Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=Inprotech Web")
                    .ConnectionString;

            _context["failedActionName"] = typeof(ApplyInprotechDatabaseChanges).Name;

            _subject.Run(_context, _eventStream);

            _processRunner.Received().Run("Content\\Database\\InprotechKaizen.Database.exe", "-m Inprotech -c \"Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=\\\"Inprotech Web\\\"\" -s");

            _processRunner.Received().Open(Arg.Any<string>());
        }

        [Fact]
        public void InvokesDatabaseExeForIntegration()
        {
            _context["IntegrationAdministrationConnectionString"] =
                new SqlConnectionStringBuilder(
                                               "Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=Inprotech Web")
                    .ConnectionString;

            _context["failedActionName"] = typeof(ApplyIntegrationDatabaseChanges).Name;

            _subject.Run(_context, _eventStream);

            _processRunner.Received().Run("Content\\Database\\InprotechKaizen.Database.exe", "-m InprotechIntegration -c \"Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=\\\"Inprotech Web\\\"\" -s");

            _processRunner.Received().Open(Arg.Any<string>());
        }

        [Fact]
        public void ShouldBuildScriptToAllowBypassOnResume()
        {
            _context["InprotechAdministrationConnectionString"] =
                new SqlConnectionStringBuilder(
                                               "Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;Application Name=Inprotech Web")
                    .ConnectionString;

            _context["failedActionName"] = typeof(ApplyInprotechDatabaseChanges).Name;

            _processRunner.Run("Content\\Database\\InprotechKaizen.Database.exe", Arg.Any<string>())
                          .Returns(new CommandLineUtilityResult
                          {
                              Output = @"
-- SCRIPT NAME: InprotechKaizen.Database.Scripts.194-UpdateClientEventTextSiteControlComments.sql

UPDATE dbo.SITECONTROL
  SET
      COMMENTS = 'Determines whether or not Event Notes entered without a Event Note Type are visible to your firms external users (your Clients). If set to TRUE, your clients are able to view Event Notes without an Event Note type.
This site control does not affect Event Notes which have an Event Note Type entered against them because they are controlled by the public flag set against the note type long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long long.'
WHERE CONTROLID = 'Client Event Text';
GO"
                          });

            _subject.Run(_context, _eventStream);

            const string expectedBypassScript = @"/*
        
------------------------------------------------------------------------------------------------------------
--- If the attempt to correct this script has failed, you may consider indicating to the Inprotech.Setup ---
--- so that it will not run this script when you resume setup.  If you are using this step to proceed,   ---
--- you will need to ensure the cause of initial failure is attended to after the set up completes.      ---
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
------- UNCOMMENT THE BELOW SECTION TO PREVENT INPROTECH SETUP FROM RUNNING THIS SCRIPT ON RESUME  ---------
------------------------------------------------------------------------------------------------------------

if not exists (select * from SchemaVersions where ScriptName = 'InprotechKaizen.Database.Scripts.194-UpdateClientEventTextSiteControlComments.sql') 
begin 
    insert SchemaVersions (ScriptName, Applied) 
    values ('InprotechKaizen.Database.Scripts.194-UpdateClientEventTextSiteControlComments.sql', getdate()) 
end 
go 
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
*/";

            _fileSystem.Received(1).WriteTemperoryFile(Arg.Is<string>(_ => _.Contains(expectedBypassScript)), ".sql");
        }
    }
}