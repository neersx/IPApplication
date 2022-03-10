using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor;
using InprotechKaizen.Model.Components.DocumentGeneration.Processor.RunMappers;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.InproDoc
{
    public class RunDocItemRunnerFacts : FactBase
    {
        readonly DocItemRunnerFixture _fixture;

        public RunDocItemRunnerFacts()
        {
            _fixture = new DocItemRunnerFixture(Db);
        }

        [Fact]
        public void ExecuteCallsSp()
        {
            var diSp = new DocItem
            {
                Id = 1,
                Name = "sp",
                ItemType = (short?) DataItemType.StoredProcedure,
                Sql = "someStoredProc"
            }.In(Db);

            var diSql = new DocItem
            {
                Id = 2,
                Name = "sql",
                ItemType = (short?) DataItemType.SqlStatement,
                Sql = "someSqlQuery"
            }.In(Db);

            var r = _fixture.Subject.Execute(new List<ItemProcessor>
            {
                new ItemProcessor {ReferencedDataItem = new ReferencedDataItem {ItemName = diSp.Name}},
                new ItemProcessor {ReferencedDataItem = new ReferencedDataItem {ItemName = diSql.Name}}
            }).ToList();

            Assert.Equal(2, r.Count);

            _fixture.RunQueryMapper
                    .Received(1)
                    .Execute("someSqlQuery", Arg.Any<string>(), Arg.Any<string>(), Arg.Any<RunDocItemParams>());

            _fixture.RunStoredProcedureMapper
                    .Received(1)
                    .Execute("someStoredProc", Arg.Any<string>(), Arg.Any<string>(), Arg.Any<RunDocItemParams>());
        }

        class DocItemRunnerFixture : IFixture<RunDocItemsManager>
        {
            public DocItemRunnerFixture(InMemoryDbContext db)
            {
                SiteControls = Substitute.For<ISiteControlReader>();

                RunQueryMapper = Substitute.For<RunQueryMapper>(null, null, null);
                RunStoredProcedureMapper = Substitute.For<RunStoredProcedureMapper>(null, null, null);

                Subject = new RunDocItemsManager(db, new LegacyDocItemRunner(RunQueryMapper,
                                                                        RunStoredProcedureMapper,
                                                                        SiteControls));
            }

            public RunQueryMapper RunQueryMapper { get; }
            public RunStoredProcedureMapper RunStoredProcedureMapper { get; }
            public ISiteControlReader SiteControls { get; }
            public RunDocItemsManager Subject { get; }
        }
    }
}