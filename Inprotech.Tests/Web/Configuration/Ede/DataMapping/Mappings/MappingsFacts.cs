using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model.Ede.DataMapping;
using Xunit;
using Components = Inprotech.Web.Configuration.Ede.DataMapping.Mappings;

namespace Inprotech.Tests.Web.Configuration.Ede.DataMapping.Mappings
{
    public class MappingsFacts
    {
        public class ViewModel : Components.Mapping<object>
        {
            public Mapping Mapping { get; set; }

            public string OutputValue { get; set; }
        }

        public class Fetch : FactBase
        {
            const int SystemId = 999;
            const int StructureId = 100;

            [Theory]
            [InlineData("abc", "def", true, "ghi")]
            [InlineData("abc", null, true, "ghi")]
            [InlineData(null, "def", true, null)]
            public void ReturnsDataForConsumption(string code, string desc, bool isNotApplicable, string outputValue)
            {
                DataSource dataSource;
                MapStructure mapStructure;

                var f = new MappingsFixture(Db)
                        .WithDataSourceFor(SystemId, out dataSource)
                        .WithMapStructureFor(StructureId, out mapStructure)
                        .WithMapping(dataSource, mapStructure,
                                     desc,
                                     code,
                                     isNotApplicable,
                                     outputValue);

                var r = f.Subject.Fetch(SystemId, StructureId, CreateMapping).ToArray();

                var viewModel = (ViewModel) r.Single();

                Assert.Equal(desc, viewModel.Mapping.InputDescription);
                Assert.Equal(code, viewModel.Mapping.InputCode);
                Assert.Equal(outputValue, viewModel.Mapping.OutputValue);
                Assert.Equal(isNotApplicable, viewModel.Mapping.IsNotApplicable);

                Assert.Equal(outputValue, viewModel.OutputValue);
            }

            static Components.Mapping CreateMapping(Mapping m, string o)
            {
                return new ViewModel
                {
                    Mapping = m,
                    OutputValue = o
                };
            }

            [Fact]
            public void ResolvesOutputEncodedValue()
            {
                DataSource dataSource;
                MapStructure mapStructure;

                var f = new MappingsFixture(Db)
                        .WithDataSourceFor(SystemId, out dataSource)
                        .WithMapStructureFor(StructureId, out mapStructure)
                        .WithMapping(dataSource, mapStructure, "hello",
                                     outputEncodedValue: "world");

                var r = f.Subject.Fetch(SystemId, StructureId, CreateMapping).ToArray();

                var viewModel = (ViewModel) r.Single();

                Assert.NotNull(viewModel.Mapping.OutputCodeId);
                Assert.Equal("hello", viewModel.Mapping.InputDescription);
                Assert.Equal("world", viewModel.OutputValue);
            }

            [Fact]
            public void ReturnsErrorIfMappingCreationFuncNotProvided()
            {
                Assert.Throws<ArgumentNullException>(
                                                     () =>
                                                     {
                                                         var r = new MappingsFixture(Db).Subject.Fetch(SystemId, StructureId, null).ToArray();
                                                     });
            }

            [Fact]
            public void ReturnsErrorIfSystemIdNotProvided()
            {
                Assert.Throws<ArgumentNullException>(
                                                     () =>
                                                     {
                                                         var r = new MappingsFixture(Db).Subject.Fetch(null, StructureId, CreateMapping).ToArray();
                                                     });
            }
        }

        public class MappingsFixture : IFixture<Components.Mappings>
        {
            readonly InMemoryDbContext _db;

            public MappingsFixture(InMemoryDbContext db)
            {
                _db = db;

                Subject = new Components.Mappings(db);
            }

            public Components.Mappings Subject { get; set; }

            public MappingsFixture WithDataSourceFor(short systemId, out DataSource dataSource)
            {
                dataSource = new DataSource
                {
                    SystemId = systemId
                }.In(_db);
                return this;
            }

            public MappingsFixture WithMapStructureFor(short structureId, out MapStructure mapStructure)
            {
                mapStructure = new MapStructure
                {
                    Id = structureId
                }.In(_db);
                return this;
            }

            public MappingsFixture WithMapping(DataSource dataSource, MapStructure mapStructure,
                                               string inputDescription, string code = null, bool? notApplicable = false, string outputValue = null,
                                               string outputEncodedValue = null)
            {
                int? inputCodeId = null;

                if (!string.IsNullOrWhiteSpace(outputEncodedValue))
                {
                    new Mapping
                    {
                        InputCodeId = inputCodeId = Fixture.Integer(),
                        StructureId = mapStructure.Id,
                        MapStructure = mapStructure,
                        OutputValue = outputEncodedValue
                    }.In(_db);
                }

                new Mapping
                {
                    InputCode = code,
                    InputDescription = inputDescription,
                    StructureId = mapStructure.Id,
                    MapStructure = mapStructure,
                    DataSource = dataSource,
                    OutputValue = outputValue,
                    OutputCodeId = inputCodeId,
                    IsNotApplicable = notApplicable.GetValueOrDefault()
                }.In(_db);

                return this;
            }
        }
    }
}