using System;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases.Events;
using InprotechKaizen.Model.Ede.DataMapping;
using NSubstitute;
using Xunit;
using Components = Inprotech.Web.Configuration.Ede.DataMapping.Mappings;

namespace Inprotech.Tests.Web.Configuration.Ede.DataMapping.Mappings
{
    public class EventMappingHandlerFacts
    {
        public class FetchByMethod : FactBase
        {
            [Fact]
            public void RequestsTheCorrectStructureId()
            {
                var f = new EventMappingHandlerFixture(Db);
                var structure = Fixture.Integer();

                Assert.Empty(f.Subject.FetchBy(1, structure).ToArray());

                f.Mappings.Received(1)
                 .Fetch(1, structure,
                        Arg.Any<Func<Mapping, string, Components.Mapping>>());
            }

            [Fact]
            public void ReturnsCodeMapping()
            {
                var f = new EventMappingHandlerFixture(Db)
                    .Fetches(new Mapping
                    {
                        InputCode = "this one",
                        InputDescription = "not this one"
                    });

                var r = f.Subject.FetchBy(Fixture.Integer(), Fixture.Integer()).ToArray();

                Assert.Single(r);
                Assert.Equal("this one", r.Single().InputDesc);
                Assert.False(r.Single().NotApplicable);
            }

            [Fact]
            public void ReturnsDescriptionMapping()
            {
                var f = new EventMappingHandlerFixture(Db)
                    .Fetches(new Mapping
                    {
                        InputDescription = "hello world"
                    });

                var r = f.Subject.FetchBy(Fixture.Integer(), Fixture.Integer()).ToArray();

                Assert.Single(r);
                Assert.Equal("hello world", r.Single().InputDesc);
                Assert.False(r.Single().NotApplicable);
            }

            [Fact]
            public void ReturnsErrorIfSystemIdNotProvided()
            {
                Assert.Throws<ArgumentNullException>(
                                                     () =>
                                                     {
                                                         // ReSharper disable once UnusedVariable
                                                         var r = new EventMappingHandlerFixture(Db).Subject.FetchBy(null, 0).ToArray();
                                                     });
            }

            [Fact]
            public void ReturnsMappingId()
            {
                var mapping = new Mapping().In(Db);

                var f = new EventMappingHandlerFixture(Db)
                    .Fetches(mapping);

                Assert.Equal(mapping.Id, f.Subject.FetchBy(Fixture.Integer(), Fixture.Integer()).Single().Id);
            }

            [Fact]
            public void ReturnsNonApplicableMapping()
            {
                var f = new EventMappingHandlerFixture(Db)
                    .Fetches(new Mapping
                    {
                        IsNotApplicable = true
                    });

                Assert.True(f.Subject.FetchBy(Fixture.Integer(), Fixture.Integer()).Single().NotApplicable);
            }
        }

        public class TryValidateMethod : FactBase
        {
            [Theory]
            [InlineData(true, false, false)]
            [InlineData(false, true, false)]
            [InlineData(false, false, true)]
            public void ThrowsWhenArgsNotProvided(bool setDataSource, bool setMapStructure, bool setMapping)
            {
                var dataSource = setDataSource ? new DataSource() : null;
                var mapStructure = setMapStructure ? new MapStructure() : null;
                var mapping = setMapping ? new Components.EventMapping() : null;

                Assert.Throws<ArgumentNullException>(
                                                     () =>
                                                     {
                                                         new EventMappingHandlerFixture(Db)
                                                             .Subject
                                                             .TryValidate(dataSource, mapStructure, mapping, out _);
                                                     });
            }

            [Fact]
            public void ReturnsNotOkayWithBadEventAsOutputValue()
            {
                var eventMapping = new Components.EventMapping
                {
                    Output = new Components.Output<int?>
                    {
                        Key = Fixture.Integer(),
                        Value = "The event does not exists"
                    }
                };

                var r = new EventMappingHandlerFixture(Db)
                        .Subject
                        .TryValidate(new DataSource(), new MapStructure(), eventMapping, out var errors);

                Assert.False(r);
                Assert.Equal("invalid-output-value", errors.Single());
            }

            [Fact]
            public void ReturnsOkayWithNoOutputValue()
            {
                var r = new EventMappingHandlerFixture(Db)
                        .Subject
                        .TryValidate(new DataSource(), new MapStructure(), new Components.EventMapping(), out _);

                Assert.True(r);
            }

            [Fact]
            public void ReturnsOkayWithRealEventAsOutputValue()
            {
                var @event = new EventBuilder().Build().In(Db);
                var eventMapping = new Components.EventMapping
                {
                    Output = new Components.Output<int?>
                    {
                        Key = @event.Id,
                        Value = @event.Description
                    }
                };

                var r = new EventMappingHandlerFixture(Db)
                        .Subject
                        .TryValidate(new DataSource(), new MapStructure(), eventMapping, out _);

                Assert.True(r);
            }
        }

        public class EventMappingHandlerFixture : IFixture<Components.EventMappingHandler>
        {
            public EventMappingHandlerFixture(InMemoryDbContext db)
            {
                var cultureResolver = Substitute.For<IPreferredCultureResolver>();

                Mappings = Substitute.For<Components.IMappings>();

                Subject = new Components.EventMappingHandler(db, Mappings, cultureResolver);
            }

            public Components.IMappings Mappings { get; }

            public Components.EventMappingHandler Subject { get; }

            public EventMappingHandlerFixture Fetches(Mapping mapping, string output = null)
            {
                Mappings
                    .Fetch(Arg.Any<int?>(), Arg.Any<int>(), Arg.Any<Func<Mapping, string, Components.Mapping>>())
                    .Returns(x =>
                    {
                        var f = (Func<Mapping, string, Components.Mapping>) x[2];
                        return new[]
                        {
                            f(mapping, output)
                        };
                    });
                return this;
            }
        }
    }
}