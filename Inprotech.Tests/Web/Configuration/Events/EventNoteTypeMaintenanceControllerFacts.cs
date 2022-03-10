using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Configuration.Core;
using Inprotech.Web.Configuration.Events;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Profiles;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Events
{
    public class EventNoteTypeMaintenanceControllerFacts : FactBase
    {
        static EventNoteTypeModel GetEventNoteTypeSaveDetails()
        {
            return new EventNoteTypeModel
            {
                Description = "New Text Type",
                SharingAllowed = true,
                IsExternal = true
            };
        }

        class EventNoteTypeMaintenanceControllerFixture : IFixture<EventNoteTypeMaintenanceController>
        {
            public EventNoteTypeMaintenanceControllerFixture(InMemoryDbContext db)
            {
                DbContext = db;
                PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

                Subject = new EventNoteTypeMaintenanceController(DbContext, PreferredCultureResolver);
            }

            IPreferredCultureResolver PreferredCultureResolver { get; }

            InMemoryDbContext DbContext { get; }
            public EventNoteTypeMaintenanceController Subject { get; }
        }

        public class SearchMethod : FactBase
        {
            List<EventNoteType> PrepareData()
            {
                var eventNoteType1 = new EventNoteType("Billing", true, true).In(Db);
                var eventNoteType2 = new EventNoteType("Attorney", false, false).In(Db);

                var eventNoteType3 = new EventNoteType("General", true, false).In(Db);
                var eventNoteTypelist = new List<EventNoteType> {eventNoteType1, eventNoteType2, eventNoteType3};

                return eventNoteTypelist;
            }

            [Fact]
            public void ShouldReturnListOfEventNoteTypessWhenSearchOptionIsNotProvided()
            {
                var eventNoteTypes = PrepareData();
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(null);
                Assert.NotNull(e);
                Assert.Equal(e.Count(), eventNoteTypes.Count);
            }

            [Fact]
            public void ShouldReturnListOfMatchingEventNoteTypesWhenSearchOptionIsProvided()
            {
                var eventNoteTypes = PrepareData();
                var searchOptions = new SearchOptions
                {
                    Text = "Billing"
                };
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);

                var e = (IEnumerable<object>) f.Subject.Search(searchOptions);
                dynamic eventNoteType = e.SingleOrDefault();
                Assert.NotNull(e);
                Assert.NotNull(eventNoteType);
                Assert.Equal(eventNoteType.Description, eventNoteTypes[0].Description);
                Assert.Equal(eventNoteType.SharingAllowed, eventNoteTypes[0].SharingAllowed);
                Assert.Equal(eventNoteType.IsExternal, eventNoteTypes[0].IsExternal);
                Assert.Equal(eventNoteType.Id, eventNoteTypes[0].Id);
            }
        }

        public class GetEventNoteTypeMethod : FactBase
        {
            [Fact]
            public void ShouldReturnEventNoteTypeDetails()
            {
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);

                var eventNoteType = new EventNoteType(Fixture.String(), true, false).In(Db);

                var r = f.Subject.GetEventNoteType(eventNoteType.Id.ToString());
                Assert.Equal(eventNoteType.Id, r.Id);
                Assert.Equal(eventNoteType.Description, r.Description);
                Assert.Equal(eventNoteType.IsExternal, r.IsExternal);
                Assert.Equal(eventNoteType.SharingAllowed, r.SharingAllowed);
            }

            [Fact]
            public void ShouldThrowErrorIfEventNoteTypeNotFound()
            {
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.GetEventNoteType("1"));
                Assert.IsType<HttpResponseException>(e);
            }
        }

        public class SaveMethod : FactBase
        {
            [Fact]
            public void ShouldCreateNewEventNoteTypeWithGivenDetails()
            {
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);
                var saveDetails = GetEventNoteTypeSaveDetails();
                var result = f.Subject.Save(saveDetails);

                var eventNoteType =
                    Db.Set<EventNoteType>().FirstOrDefault(nt => nt.Description == saveDetails.Description);

                Assert.NotNull(eventNoteType);
                Assert.Equal(saveDetails.Description, eventNoteType.Description);
                Assert.Equal(saveDetails.SharingAllowed, eventNoteType.SharingAllowed);
                Assert.Equal(saveDetails.IsExternal, eventNoteType.IsExternal);
                Assert.Equal("success", result.Result);
                Assert.Equal(eventNoteType.Id, result.UpdatedId);
            }

            [Fact]
            public void ShouldReturnErrorResultWhenEventNoteTypeDescriptionAlreadyExist()
            {
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);

                var saveDetails = GetEventNoteTypeSaveDetails();
                new EventNoteType(saveDetails.Description, true, true).In(Db);

                var result = f.Subject.Save(saveDetails);
                Assert.Equal(1, result.Errors.Length);
                Assert.Equal("field.errors.notunique", result.Errors[0].Message);
                Assert.Equal("description", result.Errors[0].Field);
            }

            [Fact]
            public void ShouldThrowErrorIfEventNoteTypeDetailsNotFound()
            {
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Save(null));
                Assert.IsType<ArgumentNullException>(e);
            }
        }

        public class UpdateMethod : FactBase
        {
            [Fact]
            public void ShouldThrowErrorIfEventNoteTypeDetailsNull()
            {
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);

                var e = Record.Exception(() => f.Subject.Update(Fixture.Short(), null));
                Assert.IsType<ArgumentNullException>(e);
            }

            [Fact]
            public void ShouldThrowErrorIfEventNoteTypeToBeEditedNotFound()
            {
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);
                var saveDetails = GetEventNoteTypeSaveDetails();
                var e = Record.Exception(() => f.Subject.Update(Fixture.Short(), saveDetails));
                Assert.IsType<HttpResponseException>(e);
            }

            [Fact]
            public void ShoulReturnSuccessWhenSaved()
            {
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);

                var saveDetails = GetEventNoteTypeSaveDetails();

                var eventNote = new EventNoteType("EventNoteType", false, false).In(Db);
                saveDetails.Id = eventNote.Id;
                var result = f.Subject.Update(saveDetails.Id, saveDetails);
                var eventNoteType =
                    Db.Set<EventNoteType>()
                      .First(nt => nt.Id == saveDetails.Id);

                Assert.Equal("success", result.Result);
                Assert.Equal(eventNoteType.Id, result.UpdatedId);
                Assert.Equal(saveDetails.Description, eventNoteType.Description);
                Assert.Equal(saveDetails.IsExternal, eventNoteType.IsExternal);
                Assert.Equal(saveDetails.SharingAllowed, eventNoteType.SharingAllowed);
            }
        }

        public class DeleteMethod : FactBase
        {
            [Fact]
            public void ShouldDeleteSuccessfully()
            {
                var model = new EventNoteType("Billing", true, false).In(Db);

                var deleteIds = new List<short> {model.Id};

                var deleteRequestModel = new EventNoteTypeDeleteRequestModel {Ids = deleteIds};
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);
                var r = f.Subject.Delete(deleteRequestModel);

                Assert.Empty(r.InUseIds);
                Assert.False(Db.Set<EventNoteType>().Any());
            }

            [Fact]
            public void ShouldReturnInUseIdsIfEventNoteTypeIsInUseAsEventText()
            {
                var model = new EventNoteType("Billing", true, false).In(Db);

                new EventText {Text = "test", EventNoteType = model}.In(Db);

                var deleteIds = new List<short> {model.Id};

                var deleteRequestModel = new EventNoteTypeDeleteRequestModel {Ids = deleteIds};
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);
                var r = f.Subject.Delete(deleteRequestModel);

                Assert.Single(r.InUseIds);
                Assert.True(Db.Set<EventNoteType>().Any(_ => _.Id == model.Id));
            }

            [Fact]
            public void ShouldReturnInUseIdsIfEventNoteTypeIsInUseAsSettings()
            {
                var model = new EventNoteType("Billing", true, false).In(Db);

                new SettingValues {SettingId = KnownSettingIds.DefaultEventNoteType, IntegerValue = model.Id}.In(Db);

                var deleteIds = new List<short> {model.Id};

                var deleteRequestModel = new EventNoteTypeDeleteRequestModel {Ids = deleteIds};
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);
                var r = f.Subject.Delete(deleteRequestModel);

                Assert.Single(r.InUseIds);
                Assert.True(Db.Set<EventNoteType>().Any(_ => _.Id == model.Id));
            }

            [Fact]
            public void ShouldThrowErrorIfInvalidEventNoteTypeIdIsProvided()
            {
                var f = new EventNoteTypeMaintenanceControllerFixture(Db);
                var ids = new List<short> {Fixture.Short()};
                var deleteRequestModel = new EventNoteTypeDeleteRequestModel {Ids = ids};
                var e = Record.Exception(() => f.Subject.Delete(deleteRequestModel));
                Assert.IsType<HttpResponseException>(e);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) e).Response.StatusCode);
            }
        }
    }
}