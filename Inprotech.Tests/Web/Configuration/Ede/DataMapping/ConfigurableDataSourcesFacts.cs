using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Ede.DataMapping;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.DataMapping;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Ede.DataMapping
{
    public class ConfigurableDataSourcesFacts : FactBase
    {
        public static List<object[]> AllSources
        {
            get
            {
                return Enum.GetValues(typeof(DataSourceType))
                           .Cast<DataSourceType>()
                           .Select(_ => new object[]
                           {
                               _
                           })
                           .ToList();
            }
        }

        [Theory]
        [MemberData(nameof(AllSources), MemberType = typeof(ConfigurableDataSourcesFacts))]
        public void ReturnsEventsAsMapStructureForDataSource(DataSourceType source)
        {
            var structure = new MapStructure()
                            .In(Db)
                            .WithKnownId((short) KnownMapStructures.Events);

            var systemId = Convert.ToInt16(ExternalSystems.Id(source));

            new MapScenario
            {
                SystemId = systemId,
                ExternalSystem = new ExternalSystem
                                 {
                                     Code = ExternalSystems.SystemCode(source)
                                 }
                                 .In(Db)
                                 .WithKnownId(systemId),
                MapStructure = structure,
                StructureId = structure.Id
            }.In(Db);

            var subject = new ConfigurableDataSources(Db);

            var result = subject.Retrieve();

            Assert.NotEmpty(result);
            Assert.Equal(KnownMapStructures.Events, result[source].Single());
        }

        [Theory]
        [MemberData(nameof(AllSources), MemberType = typeof(ConfigurableDataSourcesFacts))]
        public void ReturnsDocumentsAsMapStructureForDataSource(DataSourceType source)
        {
            var structure = new MapStructure()
                            .In(Db)
                            .WithKnownId((short) KnownMapStructures.Documents);

            var systemId = Convert.ToInt16(ExternalSystems.Id(source));

            new MapScenario
            {
                SystemId = systemId,
                ExternalSystem = new ExternalSystem
                                 {
                                     Code = ExternalSystems.SystemCode(source)
                                 }
                                 .In(Db)
                                 .WithKnownId(systemId),
                MapStructure = structure,
                StructureId = structure.Id
            }.In(Db);

            var subject = new ConfigurableDataSources(Db);

            var result = subject.Retrieve();

            Assert.NotEmpty(result);
            Assert.Equal(KnownMapStructures.Documents, result[source].Single());
        }

        [Theory]
        [MemberData(nameof(AllSources), MemberType = typeof(ConfigurableDataSourcesFacts))]
        public void ReturnsBothDocumentsAndEventsAsMapStructureForDataSource(DataSourceType source)
        {
            var eventMapStructure = new MapStructure()
                                    .In(Db)
                                    .WithKnownId((short) KnownMapStructures.Events);

            var documentMapStructure = new MapStructure()
                                       .In(Db)
                                       .WithKnownId((short) KnownMapStructures.Documents);

            var systemId = Convert.ToInt16(ExternalSystems.Id(source));

            new MapScenario
            {
                SystemId = systemId,
                ExternalSystem = new ExternalSystem
                                 {
                                     Code = ExternalSystems.SystemCode(source)
                                 }
                                 .In(Db)
                                 .WithKnownId(systemId),
                MapStructure = eventMapStructure,
                StructureId = eventMapStructure.Id
            }.In(Db);

            new MapScenario
            {
                SystemId = systemId,
                ExternalSystem = new ExternalSystem
                                 {
                                     Code = ExternalSystems.SystemCode(source)
                                 }
                                 .In(Db)
                                 .WithKnownId(systemId),
                MapStructure = documentMapStructure,
                StructureId = documentMapStructure.Id
            }.In(Db);

            var subject = new ConfigurableDataSources(Db);

            var result = subject.Retrieve();

            Assert.NotEmpty(result);
            Assert.Equal(new short[]
            {
                KnownMapStructures.Events,
                KnownMapStructures.Documents
            }, result[source].ToArray());
        }

        [Fact]
        public void ReturnsEmptyDueToDataSourcesNotHavingSupportedMapStructures()
        {
            var subject = new ConfigurableDataSources(Db);

            Assert.Empty(subject.Retrieve());
        }
    }
}