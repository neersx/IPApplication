using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using InprotechKaizen.Model.Ede.DataMapping;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.DataMapping
{
    public class MappingResolverFacts
    {
        public class ResolveMethod : FactBase
        {
            [Theory]
            [InlineData("B")]
            [InlineData("b")]
            public void MapsByCode(string inputCode)
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithDataSourceMapping("A", "NotThisOne", "DESC")
                        .WithDataSourceMapping("B", "ThisOne");

                var source = new Source { Code = inputCode, Description = "DESC" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source });

                Assert.Equal("ThisOne", result.First().Output);
            }

            [Fact]
            public void IfNoStandardSourceMappingWithMatchingCodeReturnsFailedMapping()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithDataSourceMapping("A", "NotThisOne", "DESC")
                        .WithDataSourceMapping("B", "ThisOne");

                var source = new Source { Code = "C" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source }).ToArray();

                Assert.Single(result);
                Assert.IsType<FailedMapping>(result.Single());
            }

            [Theory]
            [InlineData("DESC")]
            [InlineData("DesC")]
            [InlineData("desc")]
            public void MapsByDescription(string inputDescription)
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithDataSourceMapping(string.Empty, "NotThisOne", "OtherDesc")
                        .WithDataSourceMapping(string.Empty, "ThisOne", "DESC");

                var source = new Source { Description = inputDescription };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source });

                Assert.Equal("ThisOne", result.First().Output);
            }

            [Theory]
            [InlineData("B")]
            [InlineData("b")]
            public void MapsByDescriptionToCode(string inputCode)
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithDataSourceMapping(string.Empty, "NotThisOne", "A")
                        .WithDataSourceMapping(string.Empty, "ThisOne", "B");

                var source = new Source { Code = inputCode, Description = "DESC" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source });

                Assert.Equal("ThisOne", result.First().Output);
            }

            [Fact]
            public void DefaultsEncodingToCpaInproStandard()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario);

                var standardMapping =
                    new Mapping { MapStructure = f.MapStructure, InputCodeId = 1, OutputValue = "ThisOne" };
                f.MapScenario.MapStructure.Mappings.Add(standardMapping);

                mapScenario.MapStructure.EncodedValues.Add(
                                                           new EncodedValue
                                                           {
                                                               Id = 1,
                                                               StructureId = f.MapStructure.Id,
                                                               SchemeId = KnownEncodingSchemes.CpaInproStandard,
                                                               Code = "A"
                                                           });

                var source = new Source { Code = "A" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source });

                Assert.Equal("ThisOne", result.First().Output);
            }

            [Fact]
            public void IgnoresDataSourceMappingErrorsWhenMarked()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 }, IgnoreUnmapped = true };
                var f = new MappingResolverFixture(mapScenario)
                    .WithDataSourceMapping("A", "ThisOne", string.Empty, true);

                var source = new Source { Code = "B" };

                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source }).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void IgnoresEncodedMappingErrorsWhenMarked()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 }, IgnoreUnmapped = true };
                var f = new MappingResolverFixture(mapScenario)
                    .WithEncodedDefaultMapping("A", "ThisOne");

                var source = new Source { Code = "B" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source }).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void IgnoresMappingIfDataSourceMappingNotApplicable()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                    .WithDataSourceMapping("A", "ThisOne", string.Empty, true);

                var source = new Source { Code = "A" };

                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source }).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void IgnoresMappingIfEncodedDataSourceMappingNotApplicable()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                    .WithDataSourceEncodedMapping("A", "ThisOne", true);

                var source = new Source { Code = "A" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source }).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void IgnoresMappingIfEncodingSchemeMappingNotApplicable()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                    .WithEncodedMapping("A", "ThisOne", string.Empty, true);

                var source = new Source { Code = "A" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source }).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void IgnoresMappingIfEncodingSchemeWithEncodedValueMappingNotApplicable()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                    .WithEncodedDefaultMapping("A", "ThisOne", true);

                var source = new Source { Code = "A" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source }).ToArray();

                Assert.Empty(result);
            }

            [Fact]
            public void MapsByEncodedValueCode()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithEncodedMapping("A", "NotThisOne", "DESC")
                        .WithEncodedMapping("B", "ThisOne");

                var source = new Source { Code = "B", Description = "DESC" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source });

                Assert.Equal("ThisOne", result.First().Output);
            }

            [Fact]
            public void MapsByEncodedValueDescription()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithEncodedMapping(string.Empty, "NotThisOne", "OtherDesc")
                        .WithEncodedMapping(string.Empty, "ThisOne", "DESC");

                var source = new Source { Description = "DESC" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source });

                Assert.Equal("ThisOne", result.First().Output);
            }

            [Fact]
            public void ResolvesFromDataSource()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithDataSourceMapping("A", "ThisOne")
                        .WithEncodedMapping("A", "NotThisOne");

                var source = new Source { Code = "A" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source });

                Assert.Equal("ThisOne", result.First().Output);
            }

            [Fact]
            public void ResolvesFromDataSourceWithEncodedValue()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithDataSourceEncodedMapping("A", "ThisOne")
                        .WithEncodedMapping("A", "NotThisOne");

                var source = new Source { Code = "A" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source });

                Assert.Equal("ThisOne", result.First().Output);
            }

            [Fact]
            public void ResolvesFromEncodingScheme()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithEncodedMapping("A", "ThisOne")
                        .WithEncodedMapping("B", "NotThisOne");

                var source = new Source { Code = "A" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source });

                Assert.Equal("ThisOne", result.First().Output);
            }

            [Fact]
            public void ResolvesFromEncodingSchemeWithEncodedValue()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithEncodedDefaultMapping("A", "ThisOne")
                        .WithEncodedMapping("B", "NotThisOne");

                var source = new Source { Code = "A" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source });

                Assert.Equal("ThisOne", result.First().Output);
            }

            [Fact]
            public void ResolvesMultipleSources()
            {
                var mapScenario = new MapScenario { MapStructure = new MapStructure { Id = 1 } };
                var f = new MappingResolverFixture(mapScenario)
                        .WithDataSourceMapping("A", "ThisOne")
                        .WithEncodedMapping("B", "ThatOne");

                var source1 = new Source { Code = "A" };
                var source2 = new Source { Code = "B" };
                var result = f.Subject.Resolve("EPO", mapScenario, new[] { source1, source2 }).ToArray();

                Assert.Equal(2, result.Count());
                Assert.Equal("ThisOne", result.First().Output);
                Assert.Equal("ThatOne", result.Last().Output);
            }
        }
    }

    public class MappingResolverFixture : IFixture<IMappingResolver>
    {
        public MappingResolverFixture(MapScenario mapScenario)
        {
            MapStructure = new MapStructure { Id = 1, Name = Fixture.String() };
            MapScenario = mapScenario;
            mapScenario.MapStructure.EncodedValues = new List<EncodedValue>();
            Subject = new MappingResolver();
        }

        public MapStructure MapStructure { get; set; }

        public MapScenario MapScenario { get; set; }
        public IMappingResolver Subject { get; }
    }

    public static class MappingResolverFixtureExt
    {
        public static MappingResolverFixture WithDataSourceMapping(
            this MappingResolverFixture f, string inputCode, string outputValue, string inputDescription = null,
            bool isNotApplicable = false)
        {
            var dsMapping = new Mapping
            {
                DataSource = new DataSource { DataSourceCode = "EPO", Id = 1 },
                MapStructure = f.MapStructure,
                InputCode = inputCode,
                InputDescription = inputDescription,
                OutputValue = outputValue,
                IsNotApplicable = isNotApplicable
            };
            f.MapScenario.MapStructure.Mappings.Add(dsMapping);
            return f;
        }

        public static MappingResolverFixture WithDataSourceEncodedMapping(
            this MappingResolverFixture f, string inputCode, string outputValue, bool isNotApplicable = false)
        {
            var dsMapping = new Mapping
            {
                DataSource = new DataSource { DataSourceCode = "EPO", Id = 1 },
                MapStructure = f.MapStructure,
                InputCode = inputCode,
                OutputCodeId = 1
            };
            var dsEncodedMapping = new Mapping
            {
                MapStructure = f.MapStructure,
                InputCodeId = 1,
                OutputValue = outputValue,
                IsNotApplicable = isNotApplicable
            };
            f.MapScenario.MapStructure.Mappings.AddRange(
                                                         new[]
                                                         {
                                                             dsMapping,
                                                             dsEncodedMapping
                                                         });
            return f;
        }

        public static MappingResolverFixture WithEncodedMapping(this MappingResolverFixture f, string inputCode,
                                                                string outputValue, string inputDescription = null, bool isNotApplicable = false)
        {
            var encodedValueId = Fixture.Integer();
            var standardMapping =
                new Mapping
                {
                    MapStructure = f.MapStructure,
                    InputCodeId = encodedValueId,
                    OutputValue = outputValue,
                    IsNotApplicable = isNotApplicable
                };
            f.MapScenario.MapStructure.Mappings.Add(standardMapping);

            var cpaXmlEncodingScheme = new EncodingScheme
            {
                Id = KnownEncodingSchemes.CpaXml
            };

            f.MapScenario.EncodingScheme = cpaXmlEncodingScheme;

            f.MapScenario.MapStructure.EncodedValues.Add(new EncodedValue
            {
                Id = encodedValueId,
                StructureId = f.MapStructure.Id,
                SchemeId = cpaXmlEncodingScheme.Id,
                Code = inputCode,
                Description = inputDescription
            });

            return f;
        }

        public static MappingResolverFixture WithEncodedDefaultMapping(this MappingResolverFixture f,
                                                                       string inputCode, string outputValue, bool isNotApplicable = false)
        {
            var cpaXmlEncodedEncodedValueId = Fixture.Integer();
            var cpaInproEncodedValueId = Fixture.Integer();
            var cpaXmlMapping =
                new Mapping
                {
                    MapStructure = f.MapStructure,
                    InputCodeId = cpaXmlEncodedEncodedValueId,
                    OutputCodeId = cpaInproEncodedValueId
                };

            var cpaInproMapping =
                new Mapping
                {
                    MapStructure = f.MapStructure,
                    InputCodeId = cpaInproEncodedValueId,
                    OutputValue = outputValue,
                    IsNotApplicable = isNotApplicable
                };

            f.MapScenario.MapStructure.Mappings.AddRange(new[] { cpaXmlMapping, cpaInproMapping });

            var cpaXmlEncodingScheme = new EncodingScheme
            {
                Id = KnownEncodingSchemes.CpaXml
            };

            f.MapScenario.EncodingScheme = cpaXmlEncodingScheme;

            f.MapScenario.MapStructure.EncodedValues.Add(
                                                         new EncodedValue
                                                         {
                                                             Id = cpaXmlEncodedEncodedValueId,
                                                             StructureId = f.MapStructure.Id,
                                                             SchemeId = cpaXmlEncodingScheme.Id,
                                                             Code = inputCode
                                                         });

            return f;
        }
    }
}