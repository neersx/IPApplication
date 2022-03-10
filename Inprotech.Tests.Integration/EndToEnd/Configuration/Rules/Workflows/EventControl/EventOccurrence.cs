using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EventOccurrence : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void View(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var countryBuilder = new CountryBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);
                var officeBuilder = new OfficeBuilder(setup.DbContext);
                var caseType = setup.InsertWithNewId(new CaseType(Fixture.String(1), Fixture.String(5)));

                var evet = eventBuilder.Create("event");
                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();
                var office = officeBuilder.Create(Fixture.String(5));
                var country = countryBuilder.Create("country");

                var validEvent = new ValidEvent(criteria, evet, "Apple")
                {
                    NumberOfCyclesAllowed = 2,
                    Inherited = 1,
                    Importance = importance,
                    SaveDueDate = 4, // On Due Date
                    OfficeId = office.Id,
                    CaseTypeId = caseType.Code,
                    CountryCode = country.Id,
                    PropertyTypeIsThisCase = true,
                    CaseCategoryIsThisCase = true,
                    SubTypeIsThisCase = true,
                    BasisIsThisCase = true
                };
                setup.Insert(validEvent);

                var nt1 = new NameTypeBuilder(setup.DbContext).Create();
                var nt2 = new NameTypeBuilder(setup.DbContext).Create();
                setup.Insert(new NameTypeMap(validEvent, nt1.NameTypeCode, nt2.NameTypeCode, 0) {Inherited = true, MustExist = true});

                var reqEvent1 = new EventBuilder(setup.DbContext).Create();
                var reqEvent2 = new EventBuilder(setup.DbContext).Create();
                setup.Insert(new RequiredEventRule(validEvent, reqEvent1));
                setup.Insert(new RequiredEventRule(validEvent, reqEvent2));

                return new
                {
                    Event = evet.Description,
                    EventId = evet.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    Country = country,
                    Office = office,
                    CaseType = caseType,
                    NameType1 = nt1,
                    NameType2 = nt2,
                    Event1 = reqEvent1,
                    Event2 = reqEvent2
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.EventOccurrence.NavigateTo();

            Assert.IsTrue(eventControlPage.EventOccurrence.OnDueDateCheckBox.IsChecked);
            Assert.IsTrue(eventControlPage.EventOccurrence.WhenAnotherCaseExists.IsChecked);
            Assert.AreEqual(data.Office.Name, eventControlPage.EventOccurrence.Office.GetText());
            Assert.AreEqual(data.CaseType.Name, eventControlPage.EventOccurrence.CaseType.GetText());
            Assert.AreEqual(data.Country.Name, eventControlPage.EventOccurrence.Jurisdiction.GetText());
            Assert.IsTrue(eventControlPage.EventOccurrence.MatchPropertyType.IsChecked);
            Assert.IsTrue(eventControlPage.EventOccurrence.MatchCaseCategory.IsChecked);
            Assert.IsTrue(eventControlPage.EventOccurrence.MatchSubType.IsChecked);
            Assert.IsTrue(eventControlPage.EventOccurrence.MatchBasis.IsChecked);

            Assert.True(eventControlPage.EventOccurrence.MatchNames.NameType(0).GetText().Contains(data.NameType1.Name));
            Assert.True(eventControlPage.EventOccurrence.MatchNames.CurrentCaseNameType(0).GetText().Contains(data.NameType2.Name));
            Assert.True(eventControlPage.EventOccurrence.MatchNames.MustExists(0).IsChecked);
            Assert.True(eventControlPage.EventOccurrence.MatchNames.IsInherited(0));

            Assert.True(eventControlPage.EventOccurrence.Events.Tags.Contains(data.Event1.Description));
            Assert.True(eventControlPage.EventOccurrence.Events.Tags.Contains(data.Event2.Description));
        }
    }
}
