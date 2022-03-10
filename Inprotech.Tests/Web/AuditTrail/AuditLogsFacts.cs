using System.ComponentModel.DataAnnotations.Schema;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.AuditTrail
{
    public class AuditLogsFacts : FactBase
    {
        [Table("Test_iLog")]
        public class TestEntity
        {

        }
        public class AuditAuditLogRows : FactBase
        {
            [Fact]
            public void ReturnsEmptyIfAuditNotEnabled()
            {
                
                var fixture = new AuditLogsFixture(Db);
                new AuditLogTable()
                {
                    Name = "Test",
                    IsLoggingRequired = false
                }.In(Db);
                new TestEntity().In(Db);

                var result = fixture.Subject.AuditLogRows<TestEntity>(_ => true);

                Assert.Empty(result);
            }

            [Fact]
            public void ReturnsRecordsIfAuditNotEnabled()
            {
                
                var fixture = new AuditLogsFixture(Db);
                new AuditLogTable()
                {
                    Name = "Test",
                    IsLoggingRequired = true
                }.In(Db);
                fixture.DbArtifacts.Exists("Test_iLog", SysObjects.Table, SysObjects.View).Returns(true);
                new TestEntity().In(Db);

                var result = fixture.Subject.AuditLogRows<TestEntity>(_ => true);

                Assert.NotEmpty(result);
            }
        }
        public class HasAuditEnabled : FactBase
        {
            [Fact]
            public void ReturnsTrueIfTableExistsAndLoggingEnabledForTestTable()
            {
                var fixture = new AuditLogsFixture(Db);
                new AuditLogTable()
                {
                    Name = "Test",
                    IsLoggingRequired = true
                }.In(Db);
                fixture.DbArtifacts.Exists("Test_iLog", SysObjects.Table, SysObjects.View).Returns(true);

                var result = fixture.Subject.HasAuditEnabled<TestEntity>();

                Assert.True(result);
            }

            [Fact]
            public void ReturnsFalseIfTableDoesNotExistAndLoggingEnabledForTestTable()
            {
                var fixture = new AuditLogsFixture(Db);
                new AuditLogTable()
                {
                    Name = "Test",
                    IsLoggingRequired = true
                }.In(Db);
                fixture.DbArtifacts.Exists("Test_iLog", SysObjects.Table, SysObjects.View).Returns(false);

                var result = fixture.Subject.HasAuditEnabled<TestEntity>();

                Assert.False(result);
            }
            
            [Fact]
            public void ReturnsFalseIfTableExistsAndLoggingDisabledForTestTable()
            {
                var fixture = new AuditLogsFixture(Db);
                new AuditLogTable()
                {
                    Name = "Test",
                    IsLoggingRequired = false
                }.In(Db);
                fixture.DbArtifacts.Exists("Test_iLog", SysObjects.Table, SysObjects.View).Returns(true);

                var result = fixture.Subject.HasAuditEnabled<TestEntity>();

                Assert.False(result);
            }

            [Fact]
            public void ReturnsFalseIfTableDoesNotExistAndLoggingDisabledForTestTable()
            {
                var fixture = new AuditLogsFixture(Db);
                new AuditLogTable()
                {
                    Name = "Test",
                    IsLoggingRequired = false
                }.In(Db);
                fixture.DbArtifacts.Exists("Test_iLog", SysObjects.Table, SysObjects.View).Returns(false);

                var result = fixture.Subject.HasAuditEnabled<TestEntity>();

                Assert.False(result);
            }
        }
    }

    internal class AuditLogsFixture : IFixture<AuditLogs>
    {
        public AuditLogsFixture(IDbContext db)
        {
            DbArtifacts = Substitute.For<IDbArtifacts>();
            Subject = new AuditLogs(DbArtifacts, db);
        }
        public AuditLogs Subject { get; }
        public IDbArtifacts DbArtifacts { get; }
    }
}
