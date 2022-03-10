using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Persistence
{
    public class SqlDbArtifactsFacts
    {
        public class ExistsMethod : FactBase
        {
            public class SqlDbArtifactsFixture : IFixture<SqlDbArtifacts>
            {
                public SqlDbArtifactsFixture()
                {
                    DbContext = Substitute.For<IDbContext>();
                    Subject = new SqlDbArtifacts(DbContext);
                }

                public IDbContext DbContext { get; }
                public SqlDbArtifacts Subject { get; }

                public SqlDbArtifactsFixture WithSqlQueryReturnData(int[] returnData)
                {
                    DbContext.When(x => x.SqlQuery<int>(Arg.Any<string>())).DoNotCallBase();
                    DbContext.SqlQuery<int>(Arg.Any<string>()).Returns(returnData);

                    return this;
                }
            }

            [Fact]
            public void CallsSqlQuery()
            {
                var f = new SqlDbArtifactsFixture();
                f.Subject.Exists("somename", SysObjects.Table, SysObjects.Function);

                f.DbContext.Received(1).SqlQuery<int>("select 1 from sysobjects where id = object_id('somename') and xtype in ('U','FN')");
            }

            [Fact]
            public void ReturnFalseIfNoSysObjectsPassed()
            {
                var f = new SqlDbArtifacts(Db);
                var result = f.Exists("somename");

                Assert.False(result);
            }

            [Fact]
            public void ReturnFalseIfSysObjectsPassedIsNull()
            {
                var f = new SqlDbArtifacts(Db);
                var result = f.Exists("somename", null);

                Assert.False(result);
            }

            [Fact]
            public void ReturnsFalseIfSysObjectsZero()
            {
                var f = new SqlDbArtifactsFixture()
                    .WithSqlQueryReturnData(new[] {0});
                var result = f.Subject.Exists("somename", SysObjects.Table, SysObjects.Function);

                Assert.False(result);
            }

            [Fact]
            public void ReturnsTrueIfSysObjectsMoreThanOne()
            {
                var f = new SqlDbArtifactsFixture()
                    .WithSqlQueryReturnData(new[] {1});
                var result = f.Subject.Exists("somename", SysObjects.Table, SysObjects.Function);

                Assert.True(result);
            }
        }
    }
}