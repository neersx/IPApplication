using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Properties;
using NSubstitute;
using Xunit;
using Entity = InprotechKaizen.Model.Ede.DataMapping;
using Components = Inprotech.Web.Configuration.Ede.DataMapping.Mappings;

namespace Inprotech.Tests.Web.Configuration.Ede.DataMapping.Mappings
{
    public class MappingPersistenceFacts
    {
        const int SystemId = 1111;
        const int StructureId = 3333;

        public class AddMethod : FactBase
        {
            [Theory]
            [InlineData(true, false)]
            [InlineData(false, true)]
            public void ThrowsWhenArgumentsNotProvided(bool setStructure, bool setDataSource)
            {
                var mapStructure = new Entity.MapStructure().In(Db);
                var source = new Entity.DataSource
                {
                    SystemId = Fixture.Short()
                }.In(Db);

                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     var systemId = setDataSource ? source.SystemId : 0;
                                                     var structureId = setStructure ? mapStructure.Id : 0;
                                                     IEnumerable<string> errors;
                                                     int? newId;
                                                     new MappingPersistenceFixture(Db)
                                                         .Subject
                                                         .Add(new Components.Mapping(), structureId, systemId, out errors, out newId);
                                                 });
            }

            [Fact]
            public void PropogatesValidationErrorFromMappingHandler()
            {
                IEnumerable<string> errors;
                int? newId;
                IEnumerable<string> handlerErrors;
                Components.IMappingHandler handler;
                var mapping = new Components.Mapping
                {
                    InputDesc = "A"
                };

                var f = new MappingPersistenceFixture(Db)
                        .WithValidEnvironment()
                        .WithMappingHandler(out handler);

                handler.TryValidate(f.DataSource, f.MapStructure, mapping, out handlerErrors)
                       .Returns(x =>
                       {
                           x[3] = new[] {"hello from handler"};
                           return false;
                       });

                var r = f.Subject.Add(mapping, f.MapStructure.Id, f.DataSource.SystemId, out errors, out newId);

                Assert.Equal("hello from handler", errors.Single());
                Assert.False(r);
            }

            [Fact]
            public void ResolvesMappingHandlerForSpecificValidation()
            {
                IEnumerable<string> errors;
                int? newId;
                Components.IMappingHandler handler;
                var mapping = new Components.Mapping
                {
                    InputDesc = "A"
                };

                var f = new MappingPersistenceFixture(Db)
                        .WithValidEnvironment()
                        .WithMappingHandler(out handler);

                handler.TryValidate(f.DataSource, f.MapStructure, mapping, out errors)
                       .Returns(true);

                var r = f.Subject.Add(mapping, f.MapStructure.Id, f.DataSource.SystemId, out errors, out newId);
                Assert.True(r);
            }

            [Fact]
            public void ReturnsValidationErrorForNonUniqueCode()
            {
                var f = new MappingPersistenceFixture(Db)
                    .WithValidEnvironment();

                new Entity.Mapping
                {
                    DataSource = f.DataSource,
                    StructureId = f.MapStructure.Id,
                    InputCode = "A"
                }.In(Db);

                IEnumerable<string> errors;
                int? newId;
                var r = f.Subject.Add(new Components.Mapping
                {
                    InputDesc = "A"
                }, f.MapStructure.Id, f.DataSource.SystemId, out errors, out newId);

                Assert.Equal(string.Format(Resources.DataMappingDescriptionNotUnique, "A"), errors.Single());
                Assert.False(r);
            }

            [Fact]
            public void ReturnsValidationErrorWithMissingInputDescription()
            {
                var f = new MappingPersistenceFixture(Db)
                    .WithValidEnvironment();

                IEnumerable<string> errors;
                int? newId;
                var r = f.Subject.Add(new Components.Mapping(),
                                      f.MapStructure.Id, f.DataSource.SystemId, out errors, out newId);

                Assert.Equal(string.Format(Resources.DataMappingDescriptionMandatory, "description"), errors.Single());
                Assert.False(r);
            }

            [Fact]
            public void SavesTheMapping()
            {
                IEnumerable<string> errors;
                int? newId;
                var mapping = new Components.Mapping
                {
                    InputDesc = "A"
                };

                var f = new MappingPersistenceFixture(Db)
                        .WithValidEnvironment()
                        .WithMappingHandlerThatValidatesOkay();

                var r = f.Subject.Add(mapping, f.MapStructure.Id, f.DataSource.SystemId, out errors, out newId);
                Assert.True(r);
                Assert.NotNull(
                               Db.Set<Entity.Mapping>()
                                 .SingleOrDefault(_ => _.InputDescription == "A"
                                                       && _.DataSource == f.DataSource
                                                       && _.MapStructure == f.MapStructure));
            }

            [Fact]
            public void ShouldEncodeTheInputDescriptionBeforeSaving()
            {
                IEnumerable<string> errors;
                int? newId;
                var mapping = new Components.Mapping
                {
                    InputDesc = "<a href='javascript:void(0)' onmouseover= javascript:alert(1) >X</a>"
                };

                var f = new MappingPersistenceFixture(Db)
                        .WithValidEnvironment()
                        .WithMappingHandlerThatValidatesOkay();

                var r = f.Subject.Add(mapping, f.MapStructure.Id, f.DataSource.SystemId, out errors, out newId);
                Assert.True(r);
                Assert.NotNull(
                               Db.Set<Entity.Mapping>()
                                 .SingleOrDefault(_ => _.InputDescription == HttpUtility.HtmlEncode("<a href='javascript:void(0)' onmouseover= javascript:alert(1) >X</a>")
                                                       && _.DataSource == f.DataSource
                                                       && _.MapStructure == f.MapStructure));
            }

            [Fact]
            public void ThrowsWhenMappingNotProvided()
            {
                Assert.Throws<ArgumentNullException>(
                                                     () =>
                                                     {
                                                         IEnumerable<string> errors;
                                                         int? newId;
                                                         new MappingPersistenceFixture(Db)
                                                             .Subject
                                                             .Add(null, Fixture.Integer(), Fixture.Integer(), out errors, out newId);
                                                     });
            }
        }

        public class UpdateMethod : FactBase
        {
            [Theory]
            [InlineData(true, false)]
            [InlineData(false, true)]
            public void ThrowsWhenArgumentsNotProvided(bool setStructure, bool setDataSource)
            {
                var mapStructure = new Entity.MapStructure().In(Db);
                var source = new Entity.DataSource
                {
                    SystemId = Fixture.Short()
                }.In(Db);

                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     var systemId = setDataSource ? source.SystemId : 0;
                                                     var structureId = setStructure ? mapStructure.Id : 0;
                                                     IEnumerable<string> errors;
                                                     new MappingPersistenceFixture(Db)
                                                         .Subject
                                                         .Update(new Components.Mapping(), structureId, systemId, out errors);
                                                 });
            }

            [Fact]
            public void MigratesEncodedValueMappingToOutputValue()
            {
                IEnumerable<string> errors;
                var mapping = new Components.EventMapping
                {
                    InputDesc = "A",
                    Output = new Components.Output<int?>
                    {
                        Key = Fixture.Integer()
                    }
                };

                var f = new MappingPersistenceFixture(Db)
                        .WithValidEnvironment()
                        .WithMappingHandlerThatValidatesOkay();

                var toUpdate = new Entity.Mapping
                {
                    DataSource = f.DataSource,
                    StructureId = f.MapStructure.Id,
                    OutputEncodedValue = new Entity.EncodedValue()
                }.In(Db);

                mapping.Id = toUpdate.Id;

                var r = f.Subject.Update(mapping, f.MapStructure.Id, f.DataSource.SystemId, out errors);
                Assert.True(r);
                Assert.Equal(mapping.InputDesc, toUpdate.InputDescription);
                Assert.Equal(mapping.Output.Key.ToString(), toUpdate.OutputValue);
                Assert.Null(toUpdate.OutputEncodedValue);
            }

            [Fact]
            public void PropogatesValidationErrorFromMappingHandler()
            {
                IEnumerable<string> errors;
                IEnumerable<string> handlerErrors;
                Components.IMappingHandler handler;
                var mapping = new Components.Mapping
                {
                    InputDesc = "A"
                };

                var f = new MappingPersistenceFixture(Db)
                        .WithValidEnvironment()
                        .WithMappingHandler(out handler);

                handler.TryValidate(f.DataSource, f.MapStructure, mapping, out handlerErrors)
                       .Returns(x =>
                       {
                           x[3] = new[] {"hello from handler"};
                           return false;
                       });

                var toUpdate = new Entity.Mapping
                {
                    DataSource = f.DataSource,
                    StructureId = f.MapStructure.Id
                }.In(Db);

                mapping.Id = toUpdate.Id;

                var r = f.Subject.Update(mapping, f.MapStructure.Id, f.DataSource.SystemId, out errors);

                Assert.Equal("hello from handler", errors.Single());
                Assert.False(r);
            }

            [Fact]
            public void ResolvesMappingHandlerForSpecificValidation()
            {
                IEnumerable<string> errors;
                Components.IMappingHandler handler;
                var mapping = new Components.Mapping
                {
                    InputDesc = "A"
                };

                var f = new MappingPersistenceFixture(Db)
                        .WithValidEnvironment()
                        .WithMappingHandler(out handler);

                handler.TryValidate(f.DataSource, f.MapStructure, mapping, out errors)
                       .Returns(true);

                var toUpdate = new Entity.Mapping
                {
                    DataSource = f.DataSource,
                    StructureId = f.MapStructure.Id
                }.In(Db);

                mapping.Id = toUpdate.Id;

                var r = f.Subject.Update(mapping, f.MapStructure.Id, f.DataSource.SystemId, out errors);
                Assert.True(r);
            }

            [Fact]
            public void ReturnsValidationErrorForNonUniqueCode()
            {
                var f = new MappingPersistenceFixture(Db)
                    .WithValidEnvironment();

                var toUpdate = new Entity.Mapping
                {
                    DataSource = f.DataSource,
                    StructureId = f.MapStructure.Id
                }.In(Db);

                new Entity.Mapping
                {
                    DataSource = f.DataSource,
                    StructureId = f.MapStructure.Id,
                    InputCode = "A"
                }.In(Db);

                IEnumerable<string> errors;
                f.Subject.Update(
                                 new Components.Mapping
                                 {
                                     Id = toUpdate.Id,
                                     InputDesc = "A"
                                 }, f.MapStructure.Id, f.DataSource.SystemId, out errors);

                Assert.Equal(string.Format(Resources.DataMappingDescriptionNotUnique, "A"), errors.Single());
            }

            [Fact]
            public void ReturnsValidationErrorWithMissingInputDescription()
            {
                var f = new MappingPersistenceFixture(Db)
                    .WithValidEnvironment();

                var toUpdate = new Entity.Mapping
                {
                    DataSource = f.DataSource,
                    StructureId = f.MapStructure.Id
                }.In(Db);

                IEnumerable<string> errors;
                f.Subject.Update(
                                 new Components.Mapping
                                 {
                                     Id = toUpdate.Id
                                 }, f.MapStructure.Id, f.DataSource.SystemId, out errors);

                Assert.Equal(string.Format(Resources.DataMappingDescriptionMandatory, "description"), errors.Single());
            }

            [Fact]
            public void ThrowsWhenMappingNotProvided()
            {
                Assert.Throws<ArgumentNullException>(
                                                     () =>
                                                     {
                                                         IEnumerable<string> errors;
                                                         new MappingPersistenceFixture(Db)
                                                             .Subject
                                                             .Update(null, Fixture.Integer(), Fixture.Integer(), out errors);
                                                     });
            }

            [Fact]
            public void ThrowsWhenMappingProvidedDoesNotExists()
            {
                var ms = new Entity.MapStructure().In(Db);
                var s = new Entity.DataSource
                {
                    SystemId = Fixture.Short()
                }.In(Db);

                Assert.Throws<HttpException>(
                                             () =>
                                             {
                                                 IEnumerable<string> errors;
                                                 new MappingPersistenceFixture(Db)
                                                     .Subject
                                                     .Update(new Components.Mapping(), ms.Id, s.SystemId, out errors);
                                             });
            }

            [Fact]
            public void UpdatesTheMapping()
            {
                IEnumerable<string> errors;
                var mapping = new Components.Mapping
                {
                    InputDesc = "A"
                };

                var f = new MappingPersistenceFixture(Db)
                        .WithValidEnvironment()
                        .WithMappingHandlerThatValidatesOkay();

                var toUpdate = new Entity.Mapping
                {
                    DataSource = f.DataSource,
                    StructureId = f.MapStructure.Id
                }.In(Db);

                mapping.Id = toUpdate.Id;

                var r = f.Subject.Update(mapping, f.MapStructure.Id, f.DataSource.SystemId, out errors);
                Assert.True(r);
                Assert.Equal(mapping.InputDesc, toUpdate.InputDescription);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void Deletes()
            {
                var m = new Entity.Mapping().In(Db);

                var f = new MappingPersistenceFixture(Db);

                f.Subject.Delete(m.Id);

                Assert.False(
                             Db.Set<Entity.Mapping>()
                               .Any(_ => _.Id == m.Id));
            }

            [Fact]
            public void Throws()
            {
                Assert.Throws<HttpException>(
                                             () =>
                                             {
                                                 new MappingPersistenceFixture(Db)
                                                     .Subject.Delete(Fixture.Integer());
                                             });
            }
        }

        public class MappingPersistenceFixture : IFixture<Components.MappingPersistence>
        {
            readonly InMemoryDbContext _db;

            public MappingPersistenceFixture(InMemoryDbContext db)
            {
                _db = db;

                MappingHandlerResolver = Substitute.For<Components.IMappingHandlerResolver>();

                Subject = new Components.MappingPersistence(db, MappingHandlerResolver);
            }

            public Entity.DataSource DataSource { get; private set; }

            public Entity.MapStructure MapStructure { get; private set; }

            public Components.IMappingHandlerResolver MappingHandlerResolver { get; set; }

            public Components.MappingPersistence Subject { get; }

            public MappingPersistenceFixture WithMappingHandler(
                out Components.IMappingHandler mappingHandler)
            {
                mappingHandler = Substitute.For<Components.IMappingHandler>();

                MappingHandlerResolver.Resolve(MapStructure == null ? StructureId : MapStructure.Id)
                                      .Returns(mappingHandler);

                return this;
            }

            public MappingPersistenceFixture WithMappingHandlerThatValidatesOkay()
            {
                Components.IMappingHandler handler;
                IEnumerable<string> handlerErrors;

                WithMappingHandler(out handler);

                handler.TryValidate(DataSource, MapStructure, Arg.Any<Components.Mapping>(), out handlerErrors)
                       .Returns(true);

                return this;
            }

            public MappingPersistenceFixture WithValidEnvironment()
            {
                DataSource = new Entity.DataSource
                {
                    SystemId = SystemId
                }.In(_db);

                MapStructure = new Entity.MapStructure
                {
                    Id = StructureId
                }.In(_db);
                return this;
            }
        }
    }
}