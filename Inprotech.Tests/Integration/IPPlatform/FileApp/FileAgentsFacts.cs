using System.Linq;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using Xunit;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp
{
    public class FileAgentsFacts
    {
        public class TryGetAgentIdMethod : FactBase
        {
            [Fact]
            public void ShouldReturnFalseIfCaseAlreadyHasNonFileAgentSelected()
            {
                var name1 = new NameBuilder(Db).Build().In(Db);
                var nameType = new NameType(KnownNameTypes.Agent, Fixture.String()).In(Db);

                var @case = new Case().In(Db);

                new CaseName(@case, nameType, name1, 1).In(Db);

                var subject = new FileAgents(Db);
                string agentId;
                var r = subject.TryGetAgentId(@case.Id, out agentId);

                Assert.Null(agentId);
                Assert.False(r);
            }

            [Fact]
            public void ShouldReturnTrueWithFirstFileAgent()
            {
                var agent1 = Fixture.String();
                var agent2 = Fixture.String();
                var name1 = new NameBuilder(Db).Build().In(Db);
                var name2 = new NameBuilder(Db).Build().In(Db);
                var nameType = new NameType(KnownNameTypes.Agent, Fixture.String()).In(Db);
                var aliasType = new NameAliasType
                {
                    Code = KnownAliasTypes.FileAgentId
                }.In(Db);

                new NameAlias
                {
                    Alias = agent1,
                    AliasType = aliasType,
                    Name = name1
                }.In(Db);

                new NameAlias
                {
                    Alias = agent2,
                    AliasType = aliasType,
                    Name = name2
                }.In(Db);

                var @case = new Case().In(Db);

                new CaseName(@case, nameType, name1, 1).In(Db);
                new CaseName(@case, nameType, name2, 2).In(Db);

                var subject = new FileAgents(Db);
                string agentId;
                var r = subject.TryGetAgentId(@case.Id, out agentId);

                Assert.Equal(agent1, agentId);
                Assert.True(r);
            }

            [Fact]
            public void ShouldReturnTrueWithNoAgentReturnWhenThereAreFileAgentsForTheJurisdictionButNotAlreadySetInCase()
            {
                var agent1 = Fixture.String();
                var name1 = new NameBuilder(Db).Build().In(Db);
                var aliasType = new NameAliasType
                {
                    Code = KnownAliasTypes.FileAgentId
                }.In(Db);

                new NameAlias
                {
                    Alias = agent1,
                    AliasType = aliasType,
                    Name = name1
                }.In(Db);

                var @case = new Case().In(Db);

                var subject = new FileAgents(Db);
                string agentId;
                var r = subject.TryGetAgentId(@case.Id, out agentId);

                Assert.Null(agentId);
                Assert.True(r);
            }
        }

        public class FilesInJuridictionsMethod : FactBase
        {
            [Fact]
            public void DoesNotReturnAgentNotInFile()
            {
                var name1 = new NameBuilder(Db).Build().In(Db);
                var name2 = new NameBuilder(Db).Build().In(Db);

                new FilesIn
                {
                    JurisdictionId = "AU",
                    Name = name1,
                    NameId = name1.Id
                }.In(Db);

                new FilesIn
                {
                    JurisdictionId = "US",
                    Name = name1,
                    NameId = name1.Id
                }.In(Db);

                new FilesIn
                {
                    JurisdictionId = "US",
                    Name = name2,
                    NameId = name2.Id
                }.In(Db);

                new FilesIn
                {
                    JurisdictionId = "GB",
                    Name = name2,
                    NameId = name2.Id
                }.In(Db);

                var subject = new FileAgents(Db);
                var r = subject.FilesInJuridictions();

                Assert.Empty(r);
            }

            [Fact]
            public void ReturnKnownFileAgentCoveredJurisdictions()
            {
                var agent1 = Fixture.String();
                var agent2 = Fixture.String();
                var name1 = new NameBuilder(Db).Build().In(Db);
                var name2 = new NameBuilder(Db).Build().In(Db);

                var aliasType = new NameAliasType
                {
                    Code = KnownAliasTypes.FileAgentId
                }.In(Db);

                new NameAlias
                {
                    Alias = agent1,
                    AliasType = aliasType,
                    Name = name1
                }.In(Db);

                new NameAlias
                {
                    Alias = agent2,
                    AliasType = aliasType,
                    Name = name2
                }.In(Db);

                new FilesIn
                {
                    JurisdictionId = "AU",
                    Name = name1,
                    NameId = name1.Id
                }.In(Db);

                new FilesIn
                {
                    JurisdictionId = "US",
                    Name = name1,
                    NameId = name1.Id
                }.In(Db);

                new FilesIn
                {
                    JurisdictionId = "US",
                    Name = name2,
                    NameId = name2.Id
                }.In(Db);

                new FilesIn
                {
                    JurisdictionId = "GB",
                    Name = name2,
                    NameId = name2.Id
                }.In(Db);

                var subject = new FileAgents(Db);
                var r = subject.FilesInJuridictions();

                Assert.Contains("US", r);
                Assert.Contains("GB", r);
                Assert.Contains("AU", r);
                Assert.Equal(3, r.Count());
            }
        }
    }
}