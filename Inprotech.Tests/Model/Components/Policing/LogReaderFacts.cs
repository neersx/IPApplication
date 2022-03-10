using System.Data;
using Inprotech.Contracts;
using InprotechKaizen.Model.Components.Policing;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Policing
{
    public class LogReaderFacts
    {
        public class IsHistoricalDataAvailableMethod : FactBase
        {
            [Fact]
            public void CallsDbArtifactsToCheckLogExistence()
            {
                var f = new LogReaderFixture().WithLog();
                var result = f.Subject.IsHistoricalDataAvailable();

                f.DbArtifacts.Received(1).Exists("POLICING_iLOG", SysObjects.View, SysObjects.Table);
                Assert.True(result);
            }

            [Fact]
            public void ReturnsValueReturnedByDbArtifacts()
            {
                var f = new LogReaderFixture().WithoutLog();
                var result = f.Subject.IsHistoricalDataAvailable();

                Assert.False(result);
            }
        }

        public class LogReaderFixture : IFixture<LogReader>
        {
            public LogReaderFixture()
            {
                DbContext = Substitute.For<IDbContext>();
                DbArtifacts = Substitute.For<IDbArtifacts>();
                Logger = Substitute.For<IBackgroundProcessLogger<LogReader>>();
                Subject = new LogReader(DbContext, DbArtifacts, Logger);
            }

            public IDbContext DbContext { get; }

            public IDbArtifacts DbArtifacts { get; }

            public IDbCommand SqlCommand { get; private set; }

            public IBackgroundProcessLogger<LogReader> Logger { get; }

            public LogReader Subject { get; }

            public LogReaderFixture WithLog()
            {
                DbArtifacts.Exists(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>()).Returns(true);
                return this;
            }

            public LogReaderFixture WithoutLog()
            {
                DbArtifacts.Exists(Arg.Any<string>(), Arg.Any<string>(), Arg.Any<string>()).Returns(false);
                return this;
            }
        }
    }
}