using System;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.ValidCombinations;
using Inprotech.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using NSubstitute;
using Xunit;
using Action = Inprotech.Web.Picklists.Action;
using EntityModel = InprotechKaizen.Model.ValidCombinations;

namespace Inprotech.Tests.Web.Picklists
{
    public class DateOfLawPicklistMaintenanceFacts
    {
        public class SaveMethod : FactBase
        {
            public SaveMethod()
            {
                _anyDateOfLaw = new DateOfLawBuilder {CountryCode = "AU", PropertyTypeId = "P", Date = DateTime.Now}.Build();
                _existing = new DateOfLawBuilder {CountryCode = "IN", PropertyTypeId = "T", Date = DateTime.Now, IsDefault = true}.Build().In(Db);
            }

            readonly EntityModel.DateOfLaw _anyDateOfLaw;
            readonly EntityModel.DateOfLaw _existing;

            [Fact]
            public void AddsDateOfLaw()
            {
                var fixture = new DateOfLawsPicklistMaintenanceFixture(Db);

                var subject = fixture.Subject;

                var model = new DefaultDateOfLaw
                {
                    Date = _anyDateOfLaw.Date,
                    PropertyType = new PropertyType(_anyDateOfLaw.PropertyType.Code, _anyDateOfLaw.PropertyType.Name),
                    Jurisdiction = new Jurisdiction {Code = _anyDateOfLaw.CountryId},
                    DefaultEventForLaw = new Event {Code = _anyDateOfLaw.LawEvent.Code, Key = _anyDateOfLaw.LawEvent.Id}
                };

                var r = subject.Save(model, null, Operation.Add);

                var justAdded = Db.Set<EntityModel.DateOfLaw>().Last();

                Assert.Equal("success", r.Result);
                Assert.NotEqual(justAdded, _existing);
                Assert.Equal(model.Date, justAdded.Date);
                Assert.Equal(model.PropertyType.Code, justAdded.PropertyTypeId);
                Assert.Equal(model.Jurisdiction.Code, justAdded.CountryId);
                Assert.Equal(model.DefaultEventForLaw.Key, justAdded.LawEventId);
            }

            [Fact]
            public void DoesNotAllowAddingDuplicate()
            {
                var f = new DateOfLawsPicklistMaintenanceFixture(Db);

                var model = new DefaultDateOfLaw(_existing, f.FormatDateOfLaw);

                new DateOfLawBuilder {CountryCode = "IN", PropertyTypeId = "T", Date = _existing.Date, RetroActionId = "A", LawEvent = _existing.LawEvent}.Build().In(Db);

                var affectedActions = new Delta<AffectedActions>();

                affectedActions.Added.Add(new AffectedActions
                {
                    Date = model.Date,
                    DefaultEventForLaw = model.DefaultEventForLaw,
                    PropertyType = model.PropertyType,
                    Jurisdiction = model.Jurisdiction,
                    RetrospectiveAction = new Action("A", Fixture.String())
                });

                var errors = f.Subject.Save(model, affectedActions, Operation.Update).ToArray();

                Assert.True(errors.Length == 1);
                Assert.True(errors[0].DisplayMessage);
                Assert.Equal(errors[0].Message, "row.field.errors.notunique");
                Assert.Equal(errors[0].Field, "dateOfLaw");
            }

            [Fact]
            public void DoesNotAllowAddingNullRetrospectiveActionWithSameDeterminingEvent()
            {
                var f = new DateOfLawsPicklistMaintenanceFixture(Db);

                var model = new DefaultDateOfLaw(_existing, f.FormatDateOfLaw);

                var affectedActions = new Delta<AffectedActions>();

                affectedActions.Added.Add(new AffectedActions
                {
                    Date = model.Date,
                    DefaultEventForLaw = model.DefaultEventForLaw,
                    PropertyType = model.PropertyType,
                    Jurisdiction = model.Jurisdiction,
                    RetrospectiveAction = null
                });

                var errors = f.Subject.Save(model, affectedActions, Operation.Update);

                Assert.True(errors.Errors.Length == 1);
                Assert.True(errors.Errors[0].DisplayMessage);
                Assert.Equal(errors.Errors[0].Message, "field.errors.invaliddateoflaw");
                Assert.Equal(errors.Errors[0].Field, "dateOfLaw");
            }

            [Fact]
            public void PreventUnknownFromBeingSaved()
            {
                Assert.Throws<ArgumentException>(
                                                 () =>
                                                 {
                                                     new DateOfLawsPicklistMaintenanceFixture(Db).Subject.Save(
                                                                                                               new DefaultDateOfLaw
                                                                                                               {
                                                                                                                   Key = -9000
                                                                                                               }, null, Operation.Update);
                                                 });
            }

            [Fact]
            public void RequireFields()
            {
                var r = new DateOfLawsPicklistMaintenanceFixture(Db).Subject.Save(
                                                                                  new DefaultDateOfLaw
                                                                                  {
                                                                                      Key = _existing.Id
                                                                                  }, null, Operation.Update);

                Assert.Equal("defaultEventForLaw", r.Errors[0].Field);
                Assert.Equal("jurisdiction", r.Errors[1].Field);
                Assert.Equal("propertyType", r.Errors[2].Field);
                Assert.Equal("field.errors.required", r.Errors[0].Message);
                Assert.Equal("field.errors.required", r.Errors[1].Message);
                Assert.Equal("field.errors.required", r.Errors[2].Message);
            }

            [Fact]
            public void RequiresUniqueValue()
            {
                var r = new DateOfLawsPicklistMaintenanceFixture(Db).Subject.Save(
                                                                                  new DefaultDateOfLaw
                                                                                  {
                                                                                      Date = _existing.Date,
                                                                                      PropertyType = new PropertyType(_existing.PropertyType.Code, _existing.PropertyType.Name),
                                                                                      Jurisdiction = new Jurisdiction {Code = _existing.CountryId},
                                                                                      DefaultEventForLaw = new Event {Code = _existing.LawEvent.Code, Key = _existing.LawEvent.Id}
                                                                                  }, null, Operation.Add);

                Assert.Equal("dateOfLaw", r.Errors[0].Field);
                Assert.Equal("field.errors.invaliddateoflaw", r.Errors[0].Message);
                Assert.Equal("field.errors.notunique", r.Errors[0].CustomValidationMessage);
            }

            [Fact]
            public void ShouldDeleteAffectedAction()
            {
                var f = new DateOfLawsPicklistMaintenanceFixture(Db);

                var model = new DefaultDateOfLaw(_existing, f.FormatDateOfLaw);

                var dateOfLaw = new DateOfLawBuilder {CountryCode = "IN", PropertyTypeId = "T", Date = _existing.Date, RetroActionId = "A", LawEvent = _existing.LawEvent}.Build().In(Db);

                var affectedActions = new Delta<AffectedActions>();

                affectedActions.Deleted.Add(new AffectedActions
                {
                    Key = dateOfLaw.Id
                });

                f.Subject.Save(model, affectedActions, Operation.Update);

                Assert.Empty(Db.Set<EntityModel.DateOfLaw>().Where(_ => _.Id == dateOfLaw.Id));
            }

            [Fact]
            public void ShouldSaveAndUpdateAffectedActions()
            {
                var f = new DateOfLawsPicklistMaintenanceFixture(Db);

                var model = new DefaultDateOfLaw(_existing, f.FormatDateOfLaw);

                var affectedAction = new DateOfLawBuilder {CountryCode = "IN", PropertyTypeId = "T", Date = _existing.Date, RetroActionId = "A", LawEvent = _existing.LawEvent}.Build().In(Db);

                var affectedActions = new Delta<AffectedActions>();

                affectedActions.Added.Add(new AffectedActions
                {
                    Date = model.Date,
                    DefaultEventForLaw = model.DefaultEventForLaw,
                    PropertyType = model.PropertyType,
                    Jurisdiction = model.Jurisdiction,
                    RetrospectiveAction = new Action("B", Fixture.String())
                });
                affectedActions.Added.Add(new AffectedActions
                {
                    Date = model.Date,
                    DefaultEventForLaw = new Event {Code = _anyDateOfLaw.LawEvent.Code, Key = _anyDateOfLaw.LawEvent.Id},
                    PropertyType = model.PropertyType,
                    Jurisdiction = model.Jurisdiction,
                    RetrospectiveAction = null
                });
                affectedActions.Updated.Add(new AffectedActions
                {
                    Date = model.Date,
                    Key = affectedAction.Id,
                    DefaultEventForLaw = model.DefaultEventForLaw,
                    PropertyType = model.PropertyType,
                    Jurisdiction = model.Jurisdiction,
                    RetrospectiveAction = new Action("C", Fixture.String())
                });

                f.Subject.Save(model, affectedActions, Operation.Update);

                Assert.Equal("C", Db.Set<EntityModel.DateOfLaw>().First(_ => _.Id == affectedAction.Id).RetroActionId);
                Assert.Equal(4, Db.Set<EntityModel.DateOfLaw>().Count(_ => _.Date == model.Date && _.PropertyTypeId == model.PropertyType.Code));
                Assert.NotNull(Db.Set<EntityModel.DateOfLaw>().FirstOrDefault(_ => _.RetroActionId == "B"));
                Assert.Equal(2, Db.Set<EntityModel.DateOfLaw>().Count(_ => _.Date == model.Date && _.RetroAction == null && _.RetroActionId == null));
                Assert.True(true);
            }

            [Fact]
            public void UpdatesDateOfLaw()
            {
                var subject = new DateOfLawsPicklistMaintenanceFixture(Db)
                    .Subject;

                var model = new DefaultDateOfLaw
                {
                    Key = _existing.Id,
                    Date = _anyDateOfLaw.Date,
                    PropertyType = new PropertyType(_anyDateOfLaw.PropertyType.Code, _anyDateOfLaw.PropertyType.Name),
                    Jurisdiction = new Jurisdiction {Code = _anyDateOfLaw.CountryId},
                    DefaultEventForLaw = new Event {Code = _anyDateOfLaw.LawEvent.Code, Key = _anyDateOfLaw.LawEvent.Id}
                };

                var updated = Db.Set<EntityModel.DateOfLaw>().First(_ => _.Id == model.Key);

                var r = subject.Save(model, null, Operation.Update);

                Assert.Equal("success", r.Result);
                Assert.NotEqual(model.PropertyType.Code, updated.PropertyTypeId);
                Assert.NotEqual(model.Jurisdiction.Code, updated.CountryId);
                Assert.Equal(model.DefaultEventForLaw.Key, updated.LawEventId);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void DeletesDateOfLaw()
            {
                var model = new DateOfLawBuilder().Build().In(Db);

                var f = new DateOfLawsPicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.Equal("success", r.Result);
                Assert.False(Db.Set<EntityModel.DateOfLaw>().Any());
            }

            [Fact]
            public void DeletesInUseDateOfLaw()
            {
                var model = new DateOfLawBuilder().Build().In(Db);

                new Criteria
                {
                    Description = Fixture.String(),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                    CountryId = model.CountryId,
                    PropertyTypeId = model.PropertyTypeId,
                    DateOfLaw = model.Date
                }.In(Db);

                var f = new DateOfLawsPicklistMaintenanceFixture(Db);
                var r = f.Subject.Delete(model.Id);

                Assert.Equal("entity.cannotdelete", r.Errors[0].Message);
            }
        }

        public class DateOfLawsPicklistMaintenanceFixture : IFixture<DateOfLawPicklistMaintenance>
        {
            readonly InMemoryDbContext _db;

            public DateOfLawsPicklistMaintenanceFixture(InMemoryDbContext db)
            {
                _db = db;

                Subject = new DateOfLawPicklistMaintenance(_db);
                FormatDateOfLaw = Substitute.For<IFormatDateOfLaw>();
            }

            public IFormatDateOfLaw FormatDateOfLaw { get; set; }
            public DateOfLawPicklistMaintenance Subject { get; set; }

            public DateOfLawsPicklistMaintenanceFixture WithDateOfLaw()
            {
                new DateOfLawBuilder().Build().In(_db);

                return this;
            }
        }
    }
}