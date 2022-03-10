using System.Collections.Generic;
using System.Data.SqlClient;
using Inprotech.Setup.Actions;
using Inprotech.Setup.Contracts.Immutable;
using NSubstitute;
using Xunit;

namespace Inprotech.Setup.Tests.Actions
{
    public class PrepareConnectionStringsFacts
    {
        public PrepareConnectionStringsFacts()
        {
            _eventStream = Substitute.For<IEventStream>();
            _context = new Dictionary<string, object>();
            _prepareConnectionStrings = new PrepareConnectionStrings();
        }

        readonly IEventStream _eventStream;
        readonly IDictionary<string, object> _context;
        readonly PrepareConnectionStrings _prepareConnectionStrings;

        [Fact]
        public void PreservesCredentialsInOriginalConnectionString()
        {
            _context["InprotechConnectionString"] = "data source=JG2-W8S8O7A9I7;database=inpro;uid=SYSADM;pwd=SYSADM;Persist Security Info=true;APPLICATION NAME=Inprotech";
            new PrepareConnectionStrings().Run(_context, _eventStream);
            var intCon = new SqlConnectionStringBuilder((string) _context["IntegrationConnectionString"]);

            Assert.Equal("SYSADM", intCon.UserID);
            Assert.Equal("SYSADM", intCon.Password);
            Assert.False(intCon.IntegratedSecurity);
        }

        [Fact]
        public void SetsIntegrationDatabaseNameCorrectly()
        {
            _context["InprotechConnectionString"] = "Data Source=.;Initial Catalog=IPDEV;Integrated Security=True;";
            _prepareConnectionStrings.Run(_context, _eventStream);
            var builder = new SqlConnectionStringBuilder((string) _context["IntegrationAdministrationConnectionString"]);

            Assert.Equal("IPDEVIntegration", builder.InitialCatalog);
        }
    }
}