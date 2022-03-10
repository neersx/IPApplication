using System;
using System.Globalization;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;
using Inprotech.Web.Policing;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Policing;
using NSubstitute;
using Xunit;
using DateOfLaw = InprotechKaizen.Model.ValidCombinations.DateOfLaw;

// ReSharper disable PossibleInvalidOperationException
#pragma warning disable 618

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingRequestReaderFacts : FactBase
    {
        public class FetchAndConvertMethod : FactBase
        {
            [Fact]
            public void FetchesAction()
            {
                var validAction = new ValidatedCharacteristic("AA", "Action Description").In(Db);
                var f = new PolicingRequestReaderFixture(Db)
                    .WithValidatedCharacteristics(new ValidatedCharacteristics {Action = validAction});

                new PolicingRequest {RequestId = 1, Action = "AA"}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                f.PolicingCharacteristicsService.ReceivedWithAnyArgs(1).GetValidatedCharacteristics(Arg.Any<InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics>());
                Assert.Equal(1, result.RequestId.Value);
                Assert.Equal(validAction.Key, result.Attributes.Action.Key);
                Assert.Equal(validAction.Value, result.Attributes.Action.Value);
            }

            [Fact]
            public void FetchesBasicDetails()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();

                var request = new PolicingRequest
                {
                    RequestId = 1,
                    Notes = "My Notes",
                    Name = "Poling Request Name",
                    FromDate = Fixture.Monday,
                    UntilDate = Fixture.Tuesday,
                    IsDueDateOnly = 1,
                    NoOfDays = 10
                }.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(request.RequestId, result.RequestId.Value);
                Assert.Equal(request.Notes, result.Notes);
                Assert.Equal(request.Name, result.Title);
                Assert.Equal(request.FromDate.Value, result.StartDate.Value);
                Assert.Equal(request.UntilDate.Value, result.EndDate.Value);
                Assert.True(result.DueDateOnly);
                Assert.Equal(request.NoOfDays, result.ForDays);
            }

            [Fact]
            public void FetchesCaseCategory()
            {
                var caseCategory = new ValidatedCharacteristic("CaseCategory1", "CaseCategoryDescription").In(Db);
                var f = new PolicingRequestReaderFixture(Db)
                    .WithValidatedCharacteristics(new ValidatedCharacteristics {CaseCategory = caseCategory});

                new PolicingRequest {RequestId = 1, CaseCategory = "caseCategory", CaseType = "CaseType"}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(caseCategory.Key, result.Attributes.CaseCategory.Key);
                Assert.Equal(caseCategory.Value, result.Attributes.CaseCategory.Value);
            }

            [Fact]
            public void FetchesCaseReference()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();
                var caseDetails = new Case(1, "1234/A", new Country("A", "A"), new CaseType("T", "T"), new PropertyType("P", "P")) {Title = "my case"}.In(Db);

                new PolicingRequest {RequestId = 1, Irn = "1234/A"}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(1, result.RequestId.Value);
                Assert.Equal(caseDetails.Irn, result.Attributes.CaseReference.Code);
                Assert.Equal(caseDetails.Id, result.Attributes.CaseReference.Key);
                Assert.Equal(caseDetails.Title, result.Attributes.CaseReference.Value);
            }

            [Fact]
            public void ReturnsNullCaseReference()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();

                new PolicingRequest {RequestId = 1, Irn = null}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(1, result.RequestId.Value);
                Assert.Null(result.Attributes.CaseReference);
            }

            [Fact]
            public void ReturnsNotFoundCaseReference()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();

                new PolicingRequest {RequestId = 1, Irn = "1234/A"}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(1, result.RequestId.Value);
                Assert.Equal("1234/A", result.Attributes.CaseReference.Code);
                Assert.Equal(0, result.Attributes.CaseReference.Key);
                Assert.Equal("NOTFOUND", result.Attributes.CaseReference.Value);
            }

            [Fact]
            public void FetchesCaseType()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();
                var caseTypeDetails = new CaseType("A", "NewCaseType").In(Db);
                new PolicingRequest {RequestId = 1, CaseTypeRecord = caseTypeDetails}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(caseTypeDetails.Code, result.Attributes.CaseType.Key);
                Assert.Equal(caseTypeDetails.Code, result.Attributes.CaseType.Code);
                Assert.Equal(caseTypeDetails.Name, result.Attributes.CaseType.Value);
            }

            [Fact]
            public void FetchesDateOfLaw()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();
                var dateOfLaw = new DateOfLaw {Date = Fixture.Monday, CountryId = "AU", PropertyTypeId = "P"}.In(Db);
                new PolicingRequest {RequestId = 1, DateOfLaw = Fixture.Monday, Jurisdiction = "AU", PropertyType = "P"}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(dateOfLaw.Date, result.Attributes.DateOfLaw.Date);
            }

            [Fact]
            public void FetchesEvent()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();
                var eventDetails = new Event(1) {Description = "New Event"}.In(Db);
                new PolicingRequest {RequestId = 1, Event = eventDetails}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(eventDetails.Id, result.Attributes.Event.Key);
                Assert.Equal(eventDetails.Id.ToString(), result.Attributes.Event.Code);
                Assert.Equal(eventDetails.Description, result.Attributes.Event.Value);
            }

            [Fact]
            public void FetchesJurisdiction()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();
                var jurisdiction = new Country("AU", "AUS").In(Db);
                new PolicingRequest {RequestId = 1, JurisdictionRecord = jurisdiction}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(jurisdiction.Id, result.Attributes.Jurisdiction.Key);
                Assert.Equal(jurisdiction.Id, result.Attributes.Jurisdiction.Code);
                Assert.Equal(jurisdiction.Name, result.Attributes.Jurisdiction.Value);
            }

            [Fact]
            public void FetchesNameRecord()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();
                var name = new Name(1) {FirstName = "First Name"}.In(Db);
                new PolicingRequest {RequestId = 1, NameRecord = name}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(name.Id, result.Attributes.Name.Key);
                Assert.Equal(name.NameCode, result.Attributes.Name.Code);
                Assert.Equal(name.Formatted(), result.Attributes.Name.DisplayName);
            }

            [Fact]
            public void FetchesNameType()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();
                var nameType = new NameType("NameType", "New NameType").In(Db);
                new PolicingRequest {RequestId = 1, NameTypeRecord = nameType, NameType = "NameType"}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(nameType.Id, result.Attributes.NameType.Key);
                Assert.Equal(nameType.NameTypeCode, result.Attributes.NameType.Code);
                Assert.Equal(nameType.Name, result.Attributes.NameType.Value);
            }

            [Fact]
            public void FetchesOffice()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();
                var office = new Office(1, "NewOffice").In(Db);
                new PolicingRequest {RequestId = 1, Office = "1"}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(office.Id, result.Attributes.Office.Key);
                Assert.Equal(office.Id.ToString(), result.Attributes.Office.Code);
                Assert.Equal(office.Name, result.Attributes.Office.Value);
            }

            [Fact]
            public void FetchesOptions()
            {
                var f = new PolicingRequestReaderFixture(Db).WithValidatedCharacteristics();

                var request = new PolicingRequest
                {
                    RequestId = 1,
                    IsAdhocReminder = 1,
                    IsLetter = null,
                    IsUpdate = 0,
                    IsRecalculateCriteria = 1,
                    IsRecalculateDueDate = null,
                    IsRecalculateReminder = 0,
                    IsReminder = 1,
                    IsRecalculateEventDate = true,
                    IsEmailFlag = false
                }.In(Db);

                var result = f.Subject.FetchAndConvert(1);

                Assert.Equal(request.RequestId, result.RequestId.Value);
                Assert.True(result.Options.AdhocReminders);
                Assert.False(result.Options.Documents);
                Assert.False(result.Options.Update);
                Assert.True(result.Options.RecalculateCriteria);
                Assert.False(result.Options.RecalculateDueDates);
                Assert.False(result.Options.RecalculateReminderDates);
                Assert.True(result.Options.Reminders);
                Assert.True(result.Options.RecalculateEventDates);
                Assert.False(result.Options.EmailReminders);
            }

            [Fact]
            public void FetchesPropertyType()
            {
                var propertyTypeDetails = new ValidatedCharacteristic("A", "NewPropertyType");
                var f = new PolicingRequestReaderFixture(Db)
                    .WithValidatedCharacteristics(new ValidatedCharacteristics {PropertyType = propertyTypeDetails});

                new PolicingRequest {RequestId = 1, PropertyType = "A"}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(propertyTypeDetails.Key, result.Attributes.PropertyType.Key);
                Assert.Equal(propertyTypeDetails.Value, result.Attributes.PropertyType.Value);
            }

            [Fact]
            public void FetchesSubType()
            {
                var subType = new ValidatedCharacteristic("A", "NewSubType");
                var f = new PolicingRequestReaderFixture(Db)
                    .WithValidatedCharacteristics(new ValidatedCharacteristics {SubType = subType});

                new PolicingRequest {RequestId = 1, SubType = "A"}.In(Db);

                var result = f.Subject.FetchAndConvert(1);
                Assert.Equal(subType.Key, result.Attributes.SubType.Key);
                Assert.Equal(subType.Value, result.Attributes.SubType.Value);
            }
        }

        public class Fetch : FactBase
        {
            [Fact]
            public void ReturnsNullIfNoRecords()
            {
                var f = new PolicingRequestReaderFixture(Db);
                var result = f.Subject.Fetch(1);

                Assert.Null(result);
            }

            [Fact]
            public void ReturnsPolicingRequest()
            {
                var f = new PolicingRequestReaderFixture(Db);
                var request = new PolicingRequest {RequestId = 1, Name = "Policing Request name"}.In(Db);
                var result = f.Subject.Fetch(1);

                Assert.Equal(request, result);
            }
        }

        public class FetchAll : FactBase
        {
            [Fact]
            public void ReturnsAllPolicingRequests()
            {
                var f = new PolicingRequestReaderFixture(Db)
                    .WithPolicingRequests();

                var result = f.Subject.FetchAll().ToArray();
                Assert.Equal(2, result.Length);
                Assert.NotNull(result.SingleOrDefault(_ => _.RequestId == 1));
                Assert.NotNull(result.SingleOrDefault(_ => _.RequestId == 2));
            }

            [Fact]
            public void ReturnsPolicingRequestsForProvidedIds()
            {
                var f = new PolicingRequestReaderFixture(Db)
                    .WithPolicingRequests();

                var result = f.Subject.FetchAll(new[] {1}).ToArray();
                Assert.Single(result);

                Assert.NotNull(result.SingleOrDefault(_ => _.RequestId == 1));
                Assert.Null(result.SingleOrDefault(_ => _.RequestId == 2));
            }
        }

        public class IsTitleUnique : FactBase
        {
            [Fact]
            public void ReturnsFalseIfNotUniqueTitleWhileAdding()
            {
                var f = new PolicingRequestReaderFixture(Db).WithRequest(1, "A");

                var result = f.Subject.IsTitleUnique("A");
                Assert.False(result);
            }

            [Fact]
            public void ReturnsFalseIfNotUniqueTitleWhileUpdating()
            {
                var f = new PolicingRequestReaderFixture(Db).WithRequest(1, "A")
                                                            .WithRequest(2, "B");

                var result = f.Subject.IsTitleUnique("B", 1);
                Assert.False(result);
            }

            [Fact]
            public void ReturnsTrueIfUniqueTitleWhileAdding()
            {
                var f = new PolicingRequestReaderFixture(Db).WithRequest(1, "A");

                var result = f.Subject.IsTitleUnique("B");
                Assert.True(result);
            }

            [Fact]
            public void ReturnsTrueIfUniqueTitleWhileUpdating()
            {
                var f = new PolicingRequestReaderFixture(Db).WithRequest(1, "A")
                                                            .WithRequest(2, "B");

                var result = f.Subject.IsTitleUnique("B", 2);
                Assert.True(result);
            }
        }
    }

    public class PolicingRequestReaderFixture : IFixture<IPolicingRequestReader>
    {
        readonly InMemoryDbContext _db;

        public PolicingRequestReaderFixture(InMemoryDbContext db)
        {
            _db = db;
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            PreferredCultureResolver.Resolve().Returns(string.Empty);

            PolicingCharacteristicsService = Substitute.For<IPolicingCharacteristicsService>();
            PolicingCharacteristicsService.GetValidatedCharacteristics(Arg.Any<InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics>())
                                          .ReturnsForAnyArgs(new ValidatedCharacteristics());

            FormatDateOfLaw = Substitute.For<IFormatDateOfLaw>();
            FormatDateOfLaw.AsId(Arg.Any<DateTime>()).Returns(_ => _.ArgAt<DateTime>(0).ToString(CultureInfo.InvariantCulture));
            FormatDateOfLaw.Format(Arg.Any<DateTime>()).Returns(_ => _.ArgAt<DateTime>(0).ToString("dd-MMM-yyyy"));

            Subject = new PolicingRequestReader(db, PreferredCultureResolver, PolicingCharacteristicsService, FormatDateOfLaw);
        }

        IPreferredCultureResolver PreferredCultureResolver { get; }

        public IPolicingCharacteristicsService PolicingCharacteristicsService { get; }

        public IFormatDateOfLaw FormatDateOfLaw { get; }
        public IPolicingRequestReader Subject { get; }

        public PolicingRequestReaderFixture WithPolicingRequests()
        {
            new PolicingRequest {RequestId = 1, Name = "PolicingRequest1", IsSystemGenerated = null}.In(_db);
            new PolicingRequest {RequestId = 2, Name = "PolicingRequest2", IsSystemGenerated = 0}.In(_db);
            new PolicingRequest {RequestId = 3, Name = "PolicingRequest3", IsSystemGenerated = 1}.In(_db);

            return this;
        }

        public PolicingRequestReaderFixture WithRequest(int id, string title)
        {
            new PolicingRequest {RequestId = id, Name = title, IsSystemGenerated = 0}.In(_db);

            return this;
        }

        public PolicingRequestReaderFixture WithValidatedCharacteristics(ValidatedCharacteristics characteristic = null)
        {
            if (characteristic == null)
            {
                characteristic = new ValidatedCharacteristics();
            }

            PolicingCharacteristicsService.GetValidatedCharacteristics(Arg.Any<InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics>())
                                          .ReturnsForAnyArgs(characteristic);
            return this;
        }
    }
}