using Inprotech.IntegrationServer.PtoAccess.Innography;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede.DataMapping;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography
{
    public class RelationshipCodeResolverFacts : FactBase
    {
        [Fact]
        public void ReturnsOnlyMappingsForTheRequiredCodes()
        {

            var mappings = new[]
            {
                new Mapping()
                {
                    StructureId = KnownMapStructures.CaseRelationship,
                    DataSourceId = (int)KnownExternalSystemIds.IPONE,
                    InputCode = Fixture.String(),
                },
                new Mapping()
                {
                    StructureId = KnownMapStructures.CaseRelationship,
                    DataSourceId = (int)KnownExternalSystemIds.IPONE,
                    InputCode = Fixture.String(),
                },
                new Mapping()
                {
                    StructureId = KnownMapStructures.CaseRelationship,
                    DataSourceId = (int)KnownExternalSystemIds.IPONE,
                    InputCode = Fixture.String(),
                }
            }.In(Db);

            var subject = new RelationshipCodeResolver(Db);
            var result = subject.ResolveMapping(mappings[0].InputCode, mappings[1].InputCode);

            Assert.Equal(2, result.Keys.Count);
            Assert.Contains(mappings[0].InputCode, result.Keys);
            Assert.Contains(mappings[1].InputCode, result.Keys);
        }

        [Fact]
        public void ReturnsOnlyMappingsWithCodesInDb()
        {

            var mappings = new[]
            {
                new Mapping()
                {
                    StructureId = KnownMapStructures.CaseRelationship,
                    DataSourceId = (int)KnownExternalSystemIds.IPONE,
                    InputCode = Fixture.String(),
                },
                new Mapping()
                {
                    StructureId = KnownMapStructures.CaseRelationship,
                    DataSourceId = (int)KnownExternalSystemIds.IPONE,
                    InputCode = Fixture.String(),
                },
                new Mapping()
                {
                    StructureId = KnownMapStructures.CaseRelationship,
                    DataSourceId = (int)KnownExternalSystemIds.IPONE,
                    InputCode = Fixture.String(),
                }
            }.In(Db);

            var subject = new RelationshipCodeResolver(Db);
            var result = subject.ResolveMapping(mappings[0].InputCode, mappings[1].InputCode, Fixture.String());

            Assert.Equal(2, result.Keys.Count);
            Assert.Contains(mappings[0].InputCode, result.Keys);
            Assert.Contains(mappings[1].InputCode, result.Keys);
        }

        [Fact]
        public void ReturnsOnlyInnographyDataSourceRecords()
        {

            var mappings = new[]
            {
                new Mapping()
                {
                    StructureId = KnownMapStructures.CaseRelationship,
                    DataSourceId = Fixture.Integer(),
                    InputCode = Fixture.String(),
                },
                new Mapping()
                {
                    StructureId = KnownMapStructures.CaseRelationship,
                    DataSourceId = Fixture.Integer(),
                    InputCode = Fixture.String(),
                },
                new Mapping()
                {
                    StructureId = KnownMapStructures.CaseRelationship,
                    DataSourceId = (int)KnownExternalSystemIds.IPONE,
                    InputCode = Fixture.String(),
                }
            }.In(Db);

            var subject = new RelationshipCodeResolver(Db);
            var result = subject.ResolveMapping(mappings[0].InputCode, mappings[2].InputCode);

            Assert.Single(result.Keys);
            Assert.Contains(mappings[2].InputCode, result.Keys);
        }

        [Fact]
        public void ReturnsOnlyCaseRelationshipRecords()
        {

            var mappings = new[]
            {
                new Mapping()
                {
                    StructureId = Fixture.Short(),
                    DataSourceId =(int)KnownExternalSystemIds.IPONE,
                    InputCode = Fixture.String(),
                },
                new Mapping()
                {
                    StructureId = Fixture.Short(),
                    DataSourceId = (int)KnownExternalSystemIds.IPONE,
                    InputCode = Fixture.String(),
                },
                new Mapping()
                {
                    StructureId = KnownMapStructures.CaseRelationship,
                    DataSourceId = (int)KnownExternalSystemIds.IPONE,
                    InputCode = Fixture.String(),
                }
            }.In(Db);

            var subject = new RelationshipCodeResolver(Db);
            var result = subject.ResolveMapping(mappings[0].InputCode, mappings[2].InputCode);

            Assert.Single(result.Keys);
            Assert.Contains(mappings[2].InputCode, result.Keys);
        }
    }
}
