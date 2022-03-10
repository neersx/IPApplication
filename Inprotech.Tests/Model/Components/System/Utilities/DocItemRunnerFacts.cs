using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.System.Utilities;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.System.Utilities
{
    public class DocItemRunnerFacts : FactBase
    {
        [Fact]
        public void ShouldCallCreateSqlCommandWithCorrectArgumentsForSqlStatement()
        {
            var sql = "Select * from CASES where caseid = :gstrEntryPoint";
            var parameters = new Dictionary<string, object> { { "@gstrEntryPoint", 1 } };

            var fixture = new DocItemRunnerFixture(Db);

            fixture.Controller.CreateSqlQueryCommand(sql, parameters);

            var result = fixture.SqlCommandArguments;

            Assert.Equal("Select * from CASES where caseid = @gstrEntryPoint", fixture.SqlCommandArguments[0]);
            Assert.Equal(parameters, result[1]);
        }

        [Fact]
        public void ShouldNormaliseParameters()
        {
            var parameters = new Dictionary<string, object> { { "gstrEntryPoint", 1 } };

            var result = DocItemRunner.NormaliseParameters(parameters);

            Assert.Equal("@gstrEntryPoint", result.Keys.FirstOrDefault());
        }

        [Fact]
        public void ShouldReplaceParametersInSql()
        {
            const string sql = "Select * from CASES where caseid = :gstrEntryPoint and irn = :irn";
            var parameters = new List<string> { "@gstrEntryPoint", "@irn" };

            var result = DocItemRunner.ReplaceParametersInSql(sql, parameters);

            Assert.Equal("Select * from CASES where caseid = @gstrEntryPoint and irn = @irn", result);
        }

        [Fact]
        public void ShouldSetConcatNullYieldsNullBasedOnSiteControl()
        {
            var fixture = new DocItemRunnerFixture(Db);

            fixture.SiteControlReader.Read<bool?>(SiteControls.DocItemConcatNull).Returns(false);

            fixture.Controller.CreateSqlQueryCommand(string.Empty, null);

            fixture.SiteControlReader.Received(1).Read<bool?>(SiteControls.DocItemConcatNull);

            Assert.Equal("SET CONCAT_NULL_YIELDS_NULL OFF" + Environment.NewLine, fixture.SqlCommandArguments[0]);
        }

        [Fact]
        public void ShouldSetCorrectAndMatchingParameterTypesForStoredProc()
        {
            var parameters = new Dictionary<string, object> { { "@gstrEntryPoint", "1234/A" }, { "@gstrUserId", 45 } };

            var fixture = new DocItemRunnerFixture(Db);

            var sqlCommand = new SqlCommand();
            sqlCommand.Parameters.AddWithValue("@gstrEntryPoint", "1234/A");
            sqlCommand.Parameters.AddWithValue("@gstrUserId", 45);
            sqlCommand.Parameters.AddWithValue("@xyz", null);

            fixture.DbContext.CreateSqlCommand(string.Empty).ReturnsForAnyArgs(sqlCommand);

            var derivedParams = new Dictionary<string, SqlDbType> { { "@gstrEntryPoint", SqlDbType.NVarChar }, { "@xyz", SqlDbType.NVarChar }, { "@gstrUserId", SqlDbType.Int } };
            fixture.SqlHelper.DeriveParameters(string.Empty).ReturnsForAnyArgs(derivedParams);

            var result = fixture.Controller.CreateStoredProcCommand("test", parameters);

            Assert.Equal(3, result.Parameters.Count);
            Assert.Equal(SqlDbType.NVarChar, result.Parameters[0].SqlDbType);
            Assert.Equal(SqlDbType.Int, result.Parameters[1].SqlDbType);
            Assert.Equal(DbType.String, result.Parameters[2].DbType);
        }

        [Fact]
        public void ShouldSetEmptyParamsAsNullsBasedOnSiteControl()
        {
            var parameters = new Dictionary<string, object> { { "@gstrEntryPoint", string.Empty } };

            var fixture = new DocItemRunnerFixture(Db);

            var sqlCommand = new SqlCommand();
            sqlCommand.Parameters.AddWithValue("@gstrEntryPoint", string.Empty);
            fixture.DbContext.CreateSqlCommand(string.Empty).ReturnsForAnyArgs(sqlCommand);

            var derivedParams = new Dictionary<string, SqlDbType> { { "@gstrEntryPoint", SqlDbType.NVarChar } };
            fixture.SqlHelper.DeriveParameters(string.Empty).ReturnsForAnyArgs(derivedParams);

            fixture.SiteControlReader.Read<bool?>(SiteControls.DocItemEmptyParamsAsNulls).Returns(true);

            var result = fixture.Controller.CreateStoredProcCommand("test", parameters);

            fixture.SiteControlReader.Received(1).Read<bool?>(SiteControls.DocItemEmptyParamsAsNulls);

            Assert.Null(result.Parameters[0].Value);
        }

        [Fact]
        public void ShouldThrowExceptionIfDocItemNotFound()
        {
            var controller = new DocItemRunnerFixture(Db).Subject;

            var exception = Record.Exception(
                                     () => { controller.Run(-1, null); });

            Assert.Equal("Requested Data item not found", exception?.Message);
        }

        [Fact]
        public void ShouldThrowExceptionIfItemTypeUnsupported()
        {
            new DocItem
            {
                Id = 1,
                ItemType = -1
            }.In(Db);

            var controller = new DocItemRunnerFixture(Db).Subject;

            var exception = Record.Exception(
                                     () => { controller.Run(1, null); });

            Assert.Equal("The ItemType -1 is not supported", exception?.Message);
        }
    }

    public class DocItemRunnerFixture : IFixture<IDocItemRunner>
    {
        public DocItemRunnerFixture(InMemoryDbContext db)
        {
            DbContext = Substitute.For<IDbContext>();
            DbContext.Set<DocItem>().Returns(db.Set<DocItem>());
            DbContext.CreateSqlCommand(string.Empty).ReturnsForAnyArgs(new SqlCommand());
            DbContext.WhenForAnyArgs(_ => _.CreateSqlCommand(null)).Do(_ => SqlCommandArguments = _.Args());

            SqlHelper = Substitute.For<ISqlHelper>();
            SiteControlReader = Substitute.For<ISiteControlReader>();
        }

        public dynamic SqlCommandArguments { get; private set; }
        public IDbContext DbContext { get; set; }
        public ISqlHelper SqlHelper { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }

        internal DocItemRunner Controller => (DocItemRunner)Subject;

        public IDocItemRunner Subject => new DocItemRunner(DbContext, SqlHelper, SiteControlReader);
    }
}

