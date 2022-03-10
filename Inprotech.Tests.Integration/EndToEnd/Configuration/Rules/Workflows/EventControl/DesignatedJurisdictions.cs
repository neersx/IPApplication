using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DesignatedJurisdictionTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddDesignatedJurisdiction(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var groupJurisdiction = new CountryBuilder(setup.DbContext) { Type = "1" }.Create(Fixture.String(5));
                var jurisdiction = new CountryBuilder(setup.DbContext).Create(Fixture.String(5));

                setup.Insert(new CountryFlag(groupJurisdiction.Id, 1, Fixture.String(5)));
                setup.Insert(new CountryFlag(groupJurisdiction.Id, 2, Fixture.String(5)));

                setup.Insert(new CountryGroup(groupJurisdiction, jurisdiction));

                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext) {JurisdictionId = groupJurisdiction.Id };

                var vEvent = eventBuilder.Create("Event");

                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, vEvent, "Apple")
                {
                    Inherited = 1,
                    NumberOfCyclesAllowed = 1,
                    Importance = importance,
                    DatesLogicComparison = 0
                };
                setup.Insert(validEvent);
                
                return new
                {
                    Event = vEvent.Description,
                    EventId = vEvent.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    Jurisdiction = jurisdiction
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);

            eventControlPage.DesignatedJurisdictions.NavigateTo();
            eventControlPage.DesignatedJurisdictions.Add();

            var modal = new PickList(driver);

            modal.SelectRow(0);
            modal.Apply();

            Assert.AreEqual(1, eventControlPage.DesignatedJurisdictions.GridRowsCount);
            
            Assert.IsTrue(eventControlPage.DesignatedJurisdictions.StopCalculatingDropDown.HasError);
            var stopCalculating = eventControlPage.DesignatedJurisdictions.StopCalculatingDropDown.Input.Options[1].Text;
            eventControlPage.DesignatedJurisdictions.StopCalculatingDropDown.Input.SelectByIndex(1);

            eventControlPage.Save();

            Assert.AreEqual(stopCalculating, eventControlPage.DesignatedJurisdictions.StopCalculatingDropDown.Text);
            Assert.AreEqual(data.Jurisdiction.Name, eventControlPage.DesignatedJurisdictions.Grid.CellText(0, 2));
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteDesignatedJurisdiction(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var groupJurisdiction = new CountryBuilder(setup.DbContext) { Type = "1" }.Create(Fixture.String(5));
                var jurisdiction1 = new CountryBuilder(setup.DbContext).Create("A" + Fixture.String(5));
                var jurisdiction2 = new CountryBuilder(setup.DbContext).Create("B" + Fixture.String(5));

                var countryFlag = setup.Insert(new CountryFlag(groupJurisdiction.Id, 1, Fixture.String(5) ));

                setup.Insert(new CountryGroup(groupJurisdiction, jurisdiction1));
                setup.Insert(new CountryGroup(groupJurisdiction, jurisdiction2));

                var eventBuilder = new EventBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext) { JurisdictionId = groupJurisdiction.Id };

                var vEvent = eventBuilder.Create("Event");

                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, vEvent, "Apple")
                {
                    Inherited = 1,
                    NumberOfCyclesAllowed = 1,
                    Importance = importance,
                    DatesLogicComparison = 0,
                    CheckCountryFlag = countryFlag.FlagNumber
                };
                setup.Insert(validEvent);

                setup.Insert(new DueDateCalc(validEvent, 0) { JurisdictionId = jurisdiction1.Id });
                setup.Insert(new DueDateCalc(validEvent, 1) { JurisdictionId = jurisdiction2.Id });

                return new
                {
                    Event = vEvent.Description,
                    EventId = vEvent.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    Jurisdiction1 = jurisdiction1,
                    Jurisdiction2 = jurisdiction2
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);

            eventControlPage.DesignatedJurisdictions.NavigateTo();

            var dj = eventControlPage.DesignatedJurisdictions;

            Assert.AreEqual(2, dj.GridRowsCount, "Initially Two Designated Jurisdictions set up");
            Assert.IsTrue(dj.Grid.ValuesInRow(0).Contains(data.Jurisdiction1.Name), "First row contains first jurisdiction");
            eventControlPage.DesignatedJurisdictions.Grid.ToggleDelete(0);
            eventControlPage.Save();

            Assert.AreEqual(1, dj.GridRowsCount, "Only deletes the first row which was marked as deleted");
            Assert.IsTrue(dj.Grid.ValuesInRow(0).Contains(data.Jurisdiction2.Name));
        }
    }
}
