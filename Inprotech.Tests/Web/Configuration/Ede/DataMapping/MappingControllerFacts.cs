using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Integration;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Ede.DataMapping;
using Inprotech.Web.Configuration.Ede.DataMapping.Mappings;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Ede.DataMapping;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;
using Mapping = Inprotech.Web.Configuration.Ede.DataMapping.Mappings.Mapping;

namespace Inprotech.Tests.Web.Configuration.Ede.DataMapping
{
    public class EdeMappingControllerFacts
    {
        public class ViewData : FactBase
        {
            [Fact]
            public void Return404WhenDataSourceInvalid()
            {
                var f = new EdeMappingControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.ViewData("eap"));

                Assert.IsType<HttpResponseException>(e);
            }

            [Fact]
            public void ReturnDataSourceDetailsAndStructures()
            {
                var f = new EdeMappingControllerFixture(Db);

                var configurableDataSources = new Dictionary<DataSourceType, IEnumerable<short>> {{DataSourceType.Epo, new[] {(short) KnownMapStructures.Events, (short) KnownMapStructures.Documents}}, {DataSourceType.UsptoPrivatePair, new[] {(short) KnownMapStructures.Events, (short) KnownMapStructures.Documents}}};
                f.ConfigurableDataSources.Retrieve().Returns(configurableDataSources);

                f.SetUpMapStructures();

                var viewData = f.Subject.ViewData(DataSourceType.UsptoPrivatePair.ToString());

                Assert.Equal("USPTO Private PAIR", viewData.displayText);
                Assert.Equal(2, ((IEnumerable<string>) viewData.structures).Count());
            }
        }

        public class FetchMethod : FactBase
        {
            [Fact]
            public void Returns404WithUnknownDataSource()
            {
                var r = new EdeMappingControllerFixture(Db).Subject.Fetch("Vulcan", "Events");

                Assert.IsType<HttpResponseException>(r);
            }

            [Fact]
            public void Returns404WithUnknownStructure()
            {
                var r = new EdeMappingControllerFixture(Db).Subject.Fetch("UsptoTsdr", "Cube");

                Assert.IsType<HttpResponseException>(r);
            }

            [Fact]
            public void ReturnsErrorWithoutDataSource()
            {
                Assert.Throws<ArgumentNullException>(
                                                     () => { new EdeMappingControllerFixture(Db).Subject.Fetch(null, "Events"); });
            }

            [Fact]
            public void ReturnsErrorWithoutStructure()
            {
                Assert.Throws<ArgumentNullException>(
                                                     () => { new EdeMappingControllerFixture(Db).Subject.Fetch("UsptoPrivatePair", null); });
            }

            [Fact]
            public void ReturnsResult()
            {
                IMappingHandler mappingHandler;

                var f = new EdeMappingControllerFixture(Db)
                        .WithMapStructure(KnownMapStructures.Events, "Events", (int) KnownExternalSystemIds.UsptoTsdr)
                        .WithMappingHandler(KnownMapStructures.Events, out mappingHandler);

                var r = f.Subject.Fetch("UsptoTsdr", "Events");

                Assert.True(r.StructureDetails.IgnoreUnmapped);
                Assert.Empty(r.StructureDetails.Mappings.Data);

                mappingHandler.Received(1).FetchBy((int) KnownExternalSystemIds.UsptoTsdr, KnownMapStructures.Events);
            }
        }

        public class PostMethod : FactBase
        {
            [Fact]
            public void PassesArgsForAdding()
            {
                IMappingHandler mappingHandler;

                var f = new EdeMappingControllerFixture(Db)
                    .WithMappingHandler(KnownMapStructures.Events, out mappingHandler);

                mappingHandler.MappingType.Returns(typeof(EventMapping));

                var e = Record.Exception(() => f.Subject.Post(new JObject
                {
                    {"systemId", "usepo"},
                    {"structureId", "Events"},
                    {
                        "mapping", new JObject
                        {
                            {"InputDesc", "blah"}
                        }
                    }
                }));

                Assert.IsType<HttpResponseException>(e);
            }
        }

        public class PutMethod : FactBase
        {
            [Fact]
            public void PassesArgsForUpdating()
            {
                IMappingHandler mappingHandler;

                var f = new EdeMappingControllerFixture(Db)
                    .WithMappingHandler(KnownMapStructures.Events, out mappingHandler);

                mappingHandler.MappingType.Returns(typeof(EventMapping));

                var e = Record.Exception(() => f.Subject.Put(new JObject
                {
                    {"systemId", "usepo"},
                    {"structureId", "Events"},
                    {
                        "mapping", new JObject
                        {
                            {"Id", 5},
                            {"InputDesc", "blah"}
                        }
                    }
                }));

                Assert.IsType<HttpResponseException>(e);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void PassesArgsForDeleting()
            {
                var id = Fixture.Integer();

                var f = new EdeMappingControllerFixture(Db);
                var r = f.Subject.Delete(new DeleteRequestModel {Ids = new List<int> {id}});

                f.MappingPersistence.Received(1).Delete(id);

                Assert.Equal("success", r.Result);
            }
        }

        public class EdeMappingControllerFixture : IFixture<EdeMappingController>
        {
            readonly InMemoryDbContext _db;

            public EdeMappingControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                MappingHandlerResolver = Substitute.For<IMappingHandlerResolver>();

                MappingPersistence = Substitute.For<IMappingPersistence>();

                ConfigurableDataSources = Substitute.For<IConfigurableDataSources>();

                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new EdeMappingController(db, MappingHandlerResolver, MappingPersistence, ConfigurableDataSources, PreferredCultureResolver);
            }

            public IMappingHandlerResolver MappingHandlerResolver { get; }

            public IMappingPersistence MappingPersistence { get; }

            public IConfigurableDataSources ConfigurableDataSources { get; }

            public IPreferredCultureResolver PreferredCultureResolver { get; }

            public EdeMappingController Subject { get; }

            public void SetUpMapStructures()
            {
                new MapStructure
                {
                    Id = 5,
                    Name = "Events",
                    TableName = "EVENTS",
                    KeyColumnName = "EVENTNO"
                }.In(_db);

                new MapStructure
                {
                    Id = 14,
                    Name = "Documents",
                    TableName = "EVENTS",
                    KeyColumnName = "EVENTNO"
                }.In(_db);
            }

            public EdeMappingControllerFixture WithMappingHandler(int structureId, out IMappingHandler mappingHandler)
            {
                mappingHandler = Substitute.For<IMappingHandler>();
                mappingHandler.FetchBy(Arg.Any<int?>(), Arg.Any<int>())
                              .Returns(Enumerable.Empty<Mapping>());

                MappingHandlerResolver.Resolve(structureId)
                                      .Returns(mappingHandler);

                return this;
            }

            public EdeMappingControllerFixture WithMapStructure(int structureId, string name, int systemId,
                                                                bool canIgnoreUnmapped = true)
            {
                var structure = new MapStructure
                                {
                                    Name = name
                                }
                                .In(_db)
                                .WithKnownId((short) structureId);

                structure.MapScenarios.Add(new MapScenario
                {
                    StructureId = structure.Id,
                    SystemId = (short) systemId,
                    IgnoreUnmapped = canIgnoreUnmapped
                }.In(_db));
                return this;
            }
        }
    }
}