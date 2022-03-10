using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Integration.AutomaticDocketing;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping.Builders;
using Inprotech.Tests.Web;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Ede.DataMapping;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.AutomaticDocketing
{
    public class DocumentMappingsFacts
    {
        public class ResolveMethod : FactBase
        {
            readonly EventComparisonScenarioBuilder _builder =
                new EventComparisonScenarioBuilder
                {
                    Event = new EventBuilder
                    {
                        EventDescription = "hello"
                    }.Build()
                };

            [Theory]
            [InlineData("USPTO.PrivatePAIR")]
            [InlineData("USPTO.TSDR")]
            [InlineData("EPO")]
            public void ReturnsMappedScenarios(string sourceSystem)
            {
                var source = _builder.Build();

                var inputDescription = source.ComparisonSource.EventDescription;

                var f = new DocumentMappingsFixture(Db)
                        .WithMapScenarioFor(sourceSystem)
                        .ReturnsMapping(new MappedValue(new Source
                        {
                            Description = inputDescription,
                            TypeId = KnownMapStructures.Documents
                        }, new Mapping {OutputValue = "999"}));

                var r = f.Subject.Resolve(new[]
                {
                    source
                }, sourceSystem).ToArray();

                f.MappingResolver.Received(1).Resolve(
                                                      sourceSystem,
                                                      Arg.Any<MapScenario>(),
                                                      Arg.Is<IEnumerable<Source>>(
                                                                                  x => x.Any(_ => _.Description.Contains(inputDescription) && _.TypeId == KnownMapStructures.Documents)));

                Assert.Single(r);
                Assert.Equal(999, r.First().Mapped.Id);
            }

            [Fact]
            public void DoesNotSendDuplicateDescriptionsForMapping()
            {
                var f = new DocumentMappingsFixture(Db)
                        .WithMapScenarioFor("USPTO.TSDR")
                        .ReturnsMapping();

                var r = f.Subject.Resolve(new[]
                {
                    _builder.Build(),
                    _builder.Build(),
                    _builder.Build()
                }, "USPTO.TSDR");

                f.MappingResolver.Received(1).Resolve(
                                                      "USPTO.TSDR",
                                                      Arg.Any<MapScenario>(),
                                                      Arg.Is<IEnumerable<Source>>(
                                                                                  x => x.Count(_ => _.Description.Contains("hello") && _.TypeId == KnownMapStructures.Documents) == 1));

                Assert.Equal(3, r.Count());
            }

            [Fact]
            public void PublishesEachFailedMapping()
            {
                var f = new DocumentMappingsFixture(Db)
                        .WithMapScenarioFor("USPTO.TSDR")
                        .ReturnsMapping(new FailedMapping(new Source(), "Documents"));

                var r = f.Subject.Resolve(new[]
                {
                    _builder.Build()
                }, "USPTO.TSDR");

                f.Bus.Received(1).Publish(Arg.Any<BackgroundDocumentMappingFailed>());

                Assert.Single(r);
            }
        }

        public class DocumentMappingsFixture : IFixture<DocumentMappings>
        {
            readonly InMemoryDbContext _db;

            public DocumentMappingsFixture(InMemoryDbContext db)
            {
                _db = db;

                Bus = Substitute.For<IBus>();

                MappingResolver = Substitute.For<IMappingResolver>();

                Subject = new DocumentMappings(db, MappingResolver, Bus);
            }

            public IBus Bus { get; set; }

            public IMappingResolver MappingResolver { get; set; }

            public DocumentMappings Subject { get; set; }

            public DocumentMappingsFixture ReturnsMapping(params MappedValue[] mappedValues)
            {
                MappingResolver.Resolve(Arg.Any<string>(), Arg.Any<MapScenario>(), Arg.Any<IEnumerable<Source>>())
                               .Returns(mappedValues);
                return this;
            }

            public DocumentMappingsFixture WithMapScenarioFor(string sourceSystem)
            {
                new MapScenario
                {
                    MapStructure = new MapStructure().WithKnownId((short) KnownMapStructures.Documents).In(_db),
                    ExternalSystem = new ExternalSystem
                    {
                        Code = sourceSystem
                    }.In(_db)
                }.In(_db);
                return this;
            }
        }
    }
}