using System;
using System.Linq;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web;
using Inprotech.Web.Picklists;
using Inprotech.Web.Properties;
using Xunit;
using EntityModel = InprotechKaizen.Model.Cases;

namespace Inprotech.Tests.Web.Picklists
{
    public class RelationshipPicklistMaintenanceFacts
    {
        public class DeleteMethod : FactBase
        {
            [Fact]
            public void CannotDeleteInUseCaseRelation()
            {
                var model = new EntityModel.CaseRelation("ABC", null).In(Db);

                new ValidRelationshipBuilder
                {
                    Country = new CountryBuilder {Id = "NZ", Name = "New Zealand"}.Build(),
                    PropertyType = new PropertyTypeBuilder {Id = "D", Name = "Design"}.Build(),
                    Relation = new CaseRelationBuilder {RelationshipCode = model.Relationship, RelationshipDescription = Fixture.String(model.Relationship)}.Build().In(Db)
                }.Build().In(Db);

                var f = new RelationshipPicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Relationship);

                Assert.NotNull(r.Errors);
                Assert.Equal(KnownSqlErrors.CannotDelete, ((ValidationError[]) r.Errors).First().Message);
            }

            [Fact]
            public void DeletesCaseRelation()
            {
                var model = new EntityModel.CaseRelation("ABC", null).In(Db);

                var f = new RelationshipPicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Relationship);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.CaseRelation>().Any());
            }
        }

        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _existing = new EntityModel.CaseRelation("~MK", null)
                {
                    Description = "Marketing Activity"
                }.In(Db);
            }

            readonly EntityModel.CaseRelation _existing;

            [Theory]
            [InlineData("")]
            [InlineData(null)]
            [InlineData("B")]
            public void PreventUnknownFromBeingSaved(string relationshipCode)
            {
                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     new RelationshipPicklistMaintenanceFixture(Db).Subject.Save(
                                                                                                                 new Relationship
                                                                                                                 {
                                                                                                                     Code = relationshipCode
                                                                                                                 }, Operation.Update);
                                                 });
            }

            [Fact]
            public void AddsCaseRelation()
            {
                var subject = new RelationshipPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new Relationship
                {
                    Code = "ABC",
                    Value = "blah",
                    ToEvent = new Event
                    {
                        Key = Fixture.Integer(),
                        Code = Fixture.String("ToEventCode"),
                        Value = Fixture.String("ToEventDescription")
                    },
                    FromEvent = new Event
                    {
                        Key = Fixture.Integer(),
                        Code = Fixture.String("FromEventCode"),
                        Value = Fixture.String("FromEventDescription")
                    }
                };

                var r = subject.Save(model, Operation.Add);

                var justAdded = Db.Set<EntityModel.CaseRelation>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(model.Code, justAdded.Relationship);
                Assert.Equal(model.Value, justAdded.Description);
                Assert.Equal(model.ToEvent.Key, justAdded.ToEventId);
                Assert.Equal(model.FromEvent.Key, justAdded.FromEventId);
            }

            [Fact]
            public void RequiresCode()
            {
                var subject = new RelationshipPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Relationship
                {
                    Code = string.Empty,
                    Value = "abc"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresCodeToBeNoGreaterThan3Characters()
            {
                var subject = new RelationshipPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Relationship
                {
                    Code = "abcd",
                    Value = "abc"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 3), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresDescription()
            {
                var subject = new RelationshipPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Relationship
                {
                    Code = _existing.Relationship,
                    Value = string.Empty
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresDescriptionToBeNoGreaterThan50Characters()
            {
                var subject = new RelationshipPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Relationship
                {
                    Code = _existing.Relationship,
                    Value = "123456789012345678901234567890123456789012345678901234567890"
                }, Operation.Update);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal(string.Format(Resources.ValidationErrorMaxLengthExceeded, 50), r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueCode()
            {
                var subject = new RelationshipPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Relationship
                {
                    Code = _existing.Relationship,
                    Value = "abc"
                }, Operation.Add);

                Assert.Equal("code", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void RequiresUniqueDescription()
            {
                var subject = new RelationshipPicklistMaintenanceFixture(Db)
                    .Subject;

                var r = subject.Save(new Relationship
                {
                    Code = "B",
                    Value = _existing.Description
                }, Operation.Add);

                Assert.Equal("value", r.Errors[0].Field);
                Assert.Equal("field.errors.notunique", r.Errors[0].Message);
            }

            [Fact]
            public void UpdatesCaseRelation()
            {
                var subject = new RelationshipPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new Relationship
                {
                    Code = _existing.Relationship,
                    Value = "blah",
                    ToEvent = new Event
                    {
                        Key = Fixture.Integer(),
                        Code = Fixture.String("ToEventCode"),
                        Value = Fixture.String("ToEventDescription")
                    },
                    FromEvent = new Event
                    {
                        Key = Fixture.Integer(),
                        Code = Fixture.String("FromEventCode"),
                        Value = Fixture.String("FromEventDescription")
                    }
                };

                var r = subject.Save(model, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.Equal(model.Code, _existing.Relationship);
                Assert.Equal(model.Value, _existing.Description);
                Assert.Equal(model.ToEvent.Key, _existing.ToEventId);
                Assert.Equal(model.FromEvent.Key, _existing.FromEventId);
            }

            [Fact]
            public void ValidatesIfBothFromAndToEventAreSupplied()
            {
                var subject = new RelationshipPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new Relationship
                {
                    Code = _existing.Relationship,
                    Value = "blah",
                    FromEvent = new Event
                    {
                        Key = Fixture.Integer(),
                        Code = Fixture.String("FromEventCode"),
                        Value = Fixture.String("FromEventDescription")
                    }
                };

                var r = subject.Save(model, Operation.Update);

                Assert.Equal("toEvent", r.Errors[0].Field);
                Assert.Equal("Both 'To Event' and 'From Event' fields must either be entered or left blank.", r.Errors[0].Message);
            }
        }

        public class RelationshipPicklistMaintenanceFixture : IFixture<RelationshipPicklistMaintenance>
        {
            public RelationshipPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                Subject = new RelationshipPicklistMaintenance(db);
            }

            public RelationshipPicklistMaintenance Subject { get; set; }
        }
    }
}