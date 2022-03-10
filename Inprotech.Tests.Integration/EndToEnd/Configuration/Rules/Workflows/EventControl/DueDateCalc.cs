using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.PageObjects;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EventControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class DueDateCalcTest : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateDueDateCalc(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var countryBuilder = new CountryBuilder(setup.DbContext);
                var documentBuilder = new DocumentBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var criteria = criteriaBuilder.Create("criteria");
                var event1 = eventBuilder.Create("event1");
                var event2 = eventBuilder.Create("event2");
                var country1 = countryBuilder.Create("country1");
                var country2 = countryBuilder.Create("country2");
                var doc1 = documentBuilder.Create("doc1");
                var doc2 = documentBuilder.Create("doc2");

                var importance = importanceBuilder.Create();
                setup.Insert(new ValidEvent(criteria, event1, "event1")
                {
                    NumberOfCyclesAllowed = 2,
                    Importance = importance
                });

                setup.Insert(new ValidEvent(criteria, event2, "event2")
                {
                    NumberOfCyclesAllowed = 2,
                    Importance = importance
                });

                setup.Insert(new DueDateCalc
                {
                    Cycle = 1,
                    CriteriaId = criteria.Id,
                    EventId = event1.Id,
                    JurisdictionId = country1.Id,
                    FromEventId = event1.Id,
                    Operator = "S",
                    PeriodType = "D",
                    DeadlinePeriod = 1,
                    EventDateFlag = 1,
                    RelativeCycle = 0,
                    MustExist = 0,
                    OverrideLetterId = doc1.Id,
                    Message2Flag = 0
                });

                return new
                {
                    CriteriaId = criteria.Id.ToString(),
                    EventId = event1.Id.ToString(),
                    NewEvent = event2.Description,
                    NewEventId = event2.Id.ToString(),
                    NewCountry = country2,
                    NewDocument = doc2.Name
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DueDateCalc.Grid.ClickEdit(0);

            var modal = new DueDateCalcModal(driver);

            modal.Event.EnterAndSelect(data.NewEvent);

            modal.DueDate.Click();

            modal.MustExist.Click();

            modal.Add.Click();

            modal.Period.Text = "2";

            modal.Period.OptionText = "Weeks";

            modal.RelativeCycle.Text = "Previous Cycle";

            modal.AdjustBy.Input.SelectByIndex(1);

            modal.NonWorkDay.Input.SelectByIndex(1);

            Assert.AreEqual("1", modal.ToCycle.Text, "Defaults cycle to 1");
            modal.ToCycle.Text = "2";

            modal.Jurisdiction.EnterAndSelect(data.NewCountry.Name);

            modal.Document.EnterAndSelect(data.NewDocument);

            modal.UseAlternateReminder.Click();

            modal.Apply();
            eventControlPage.Save();

            var dueDateCalc = eventControlPage.DueDateCalc;

            Assert.AreEqual(1, dueDateCalc.GridRowsCount);
            Assert.AreEqual("2", dueDateCalc.FirstCycle);
            Assert.AreEqual(data.NewCountry.Id, dueDateCalc.FirstJurisdiction);
            Assert.AreEqual("Add", dueDateCalc.FirstOperator);
            Assert.AreEqual("2 Weeks", dueDateCalc.FirstPeriod);
            Assert.IsTrue(dueDateCalc.Event.Contains(data.NewEvent));
            Assert.IsTrue(dueDateCalc.Event.Contains(data.NewEventId));
            Assert.AreEqual("Due Date", dueDateCalc.FirstFromTo);
            Assert.AreEqual("Previous Cycle", dueDateCalc.FirstRelativeCycle);
            Assert.IsTrue(dueDateCalc.FirstMustExist);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteDueDateCalc(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var countryBuilder = new CountryBuilder(setup.DbContext);
                var documentBuilder = new DocumentBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var criteria = criteriaBuilder.Create("criteria");
                var evt = eventBuilder.Create("event");
                var country = countryBuilder.Create("country");
                var doc = documentBuilder.Create("doc");

                var importance = importanceBuilder.Create();
                setup.Insert(new ValidEvent(criteria, evt, "event1")
                {
                    NumberOfCyclesAllowed = 2,
                    Importance = importance
                });

                setup.Insert(new DueDateCalc
                {
                    Cycle = 1,
                    Sequence = 0,
                    CriteriaId = criteria.Id,
                    EventId = evt.Id,
                    JurisdictionId = country.Id,
                    FromEventId = evt.Id,
                    Operator = "S",
                    PeriodType = "D",
                    DeadlinePeriod = 1,
                    EventDateFlag = 1,
                    RelativeCycle = 0,
                    MustExist = 0,
                    OverrideLetterId = doc.Id,
                    Message2Flag = 0
                });

                setup.Insert(new DueDateCalc
                {
                    Cycle = 2,
                    Sequence = 1,
                    CriteriaId = criteria.Id,
                    EventId = evt.Id,
                    JurisdictionId = country.Id,
                    FromEventId = evt.Id,
                    Operator = "A",
                    PeriodType = "D",
                    DeadlinePeriod = 1,
                    EventDateFlag = 1,
                    RelativeCycle = 0,
                    MustExist = 0,
                    OverrideLetterId = doc.Id,
                    Message2Flag = 0
                });

                return new
                {
                    CriteriaId = criteria.Id.ToString(),
                    EventId = evt.Id.ToString()
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DueDateCalc.Grid.ToggleDelete(0);

            eventControlPage.Save();

            var dueDateCalc = eventControlPage.DueDateCalc;

            Assert.AreEqual(1, eventControlPage.DueDateCalc.GridRowsCount, "only deletes the first row which was marked as deleted");
            Assert.AreEqual("2", dueDateCalc.FirstCycle, "the second row should still stay in the grid");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DefaultCountry(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
                                      {
                                          var eventBuilder = new EventBuilder(setup.DbContext);
                                          var countryBuilder = new CountryBuilder(setup.DbContext);
                                          var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                                          var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                                          //

                                          var criteriaNoCountry = criteriaBuilder.Create("criteria1");

                                          var country = countryBuilder.Create("country");
                                          criteriaBuilder.JurisdictionId = country.Id;
                                          var criteriaWithCountry = criteriaBuilder.Create("criteria2");

                                          var eventWithCountry = eventBuilder.Create("event1");
                                          var eventNoCountry = eventBuilder.Create("event2");

                                          var importance = importanceBuilder.Create();

                                          setup.Insert(new ValidEvent(criteriaWithCountry, eventWithCountry, "event1")
                                          {
                                              NumberOfCyclesAllowed = 2,
                                              Importance = importance
                                          });

                                          setup.Insert(new ValidEvent(criteriaNoCountry, eventNoCountry, "event2")
                                          {
                                              NumberOfCyclesAllowed = 2,
                                              Importance = importance
                                          });

                                          return new
                                          {
                                              CriteriaNoCountryId = criteriaNoCountry.Id.ToString(),
                                              CriteriaWithCountryId = criteriaWithCountry.Id.ToString(),
                                              eventWithCountry,
                                              eventNoCountry,
                                              NewEvent = eventNoCountry.Description,
                                              NewEventId = eventNoCountry.Id.ToString(),
                                              Country = country
                                          };
                                      });

            var driver = BrowserProvider.Get(browserType);

            // event with country

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaWithCountryId}");

            var page = new CriteriaDetailPage(driver);
            Assert.AreEqual(data.Country.Name, page.CharacteristicsTopic.JurisdictionPickList.GetText(), "country must be correctly selected in picklist");

            driver.Visit(Env.RootUrl + $"/#/configuration/rules/workflows/{data.CriteriaWithCountryId}/eventcontrol/{data.eventWithCountry.Id}");

            var eventControlPage = new EventControlPage(driver);
            var headers = eventControlPage.DueDateCalc.Grid.HeaderColumns
                                          .Select(x => x.Text)
                                          .ToList();

            Assert.IsFalse(headers.Contains("Jurisdiction"), "since criteria has jurisdiction, event should not show it");

            eventControlPage.DueDateCalc.Add();

            var modal = new DueDateCalcModal(driver);
            Assert.IsFalse(modal.Jurisdiction.Enabled, "since criteria has jurisdiction, picklist should be disabled");

            // event withOUT country

            driver.Visit(Env.RootUrl + $"/#/configuration/rules/workflows/{data.CriteriaNoCountryId}");

            page = new CriteriaDetailPage(driver);
            Assert.IsTrue(string.IsNullOrEmpty(page.CharacteristicsTopic.JurisdictionPickList.GetText()), "country must be empty");

            driver.Visit(Env.RootUrl + $"/#/configuration/rules/workflows/{data.CriteriaNoCountryId}/eventcontrol/{data.eventNoCountry.Id}");

            eventControlPage = new EventControlPage(driver);
            headers = eventControlPage.DueDateCalc.Grid.HeaderColumns
                                          .Select(x => x.Text)
                                          .ToList();

            Assert.IsTrue(headers.Contains("Jurisdiction"), "since criteria has NO jurisdiction, grid should have a column");

            eventControlPage.DueDateCalc.Add();

            modal = new DueDateCalcModal(driver);
            Assert.IsTrue(modal.Jurisdiction.Enabled, "since criteria has NO jurisdiction, picklist should be enabled");
        }

    }

    [Category(Categories.E2E)]
    [TestFixture]
    public class DueDateCalcTestAdd : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddDueDateCalc(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var countryBuilder = new CountryBuilder(setup.DbContext);
                var documentBuilder = new DocumentBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var evet = eventBuilder.Create("event");
                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, evet, "Apple")
                {
                    NumberOfCyclesAllowed = 2,
                    Inherited = 1,
                    Importance = importance
                };
                setup.Insert(validEvent);

                var country = countryBuilder.Create("country");

                var doc = documentBuilder.Create("doc");

                return new
                {
                    Event = evet.Description,
                    EventId = evet.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    Country = country,
                    Document = doc
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DueDateCalc.Add();

            var modal = new DueDateCalcModal(driver);

            modal.Event.EnterAndSelect(data.Event);

            modal.DueDate.Click();

            modal.MustExist.Click();

            modal.Add.Click();

            modal.Period.Text = "2";

            modal.Period.OptionText = "Days";

            modal.RelativeCycle.Text = "Current Cycle";

            Assert.AreEqual("1", modal.ToCycle.Text, "Defaults cycle to 1");
            modal.ToCycle.Text = "2";

            modal.AdjustBy.Input.SelectByIndex(1);

            modal.NonWorkDay.Input.SelectByIndex(1);

            modal.Jurisdiction.EnterAndSelect(data.Country.Name);

            modal.Document.EnterAndSelect(data.Document.Code);

            modal.UseAlternateReminder.Click();

            modal.Apply();

            eventControlPage.Save();

            var dueDateCalc = eventControlPage.DueDateCalc;

            Assert.AreEqual(1, dueDateCalc.GridRowsCount);
            Assert.AreEqual("2", dueDateCalc.FirstCycle);
            Assert.AreEqual(data.Country.Id, dueDateCalc.FirstJurisdiction);
            Assert.AreEqual("Add", dueDateCalc.FirstOperator);
            Assert.AreEqual("2 Days", dueDateCalc.FirstPeriod);
            Assert.IsTrue(dueDateCalc.Event.Contains(data.Event));
            Assert.IsTrue(dueDateCalc.Event.Contains(data.EventId));
            Assert.AreEqual("Due Date", dueDateCalc.FirstFromTo);
            Assert.AreEqual("Current Cycle", dueDateCalc.FirstRelativeCycle);
            Assert.IsTrue(dueDateCalc.FirstMustExist);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void CheckPlus1DayAdjustByOption(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var countryBuilder = new CountryBuilder(setup.DbContext);
                var documentBuilder = new DocumentBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var evet = eventBuilder.Create("event");
                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, evet, "Apple")
                {
                    NumberOfCyclesAllowed = 2,
                    Inherited = 1,
                    Importance = importance
                };
                setup.Insert(validEvent);

                var country = countryBuilder.Create("country");

                var doc = documentBuilder.Create("doc");

                return new
                {
                    Event = evet.Description,
                    EventId = evet.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    Country = country,
                    Document = doc
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DueDateCalc.Add();
            var modal = new DueDateCalcModal(driver);

            modal.AdjustBy.Input.SelectByText("Plus 1 day", true);
            Assert.AreEqual(modal.AdjustBy.Text, "Plus 1 day");
            modal.Close();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddAnotherDueDateCalc(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var countryBuilder = new CountryBuilder(setup.DbContext);
                var documentBuilder = new DocumentBuilder(setup.DbContext);
                var importanceBuilder = new ImportanceBuilder(setup.DbContext);
                var criteriaBuilder = new CriteriaBuilder(setup.DbContext);

                var evet = eventBuilder.Create("event");
                var evet2 = eventBuilder.Create("event2");
                var criteria = criteriaBuilder.Create("criteria");
                var importance = importanceBuilder.Create();

                var validEvent = new ValidEvent(criteria, evet, "Apple")
                {
                    NumberOfCyclesAllowed = 2,
                    Inherited = 1,
                    Importance = importance
                };
                setup.Insert(validEvent);

                var validEvent2 = new ValidEvent(criteria, evet2, "Banana")
                {
                    NumberOfCyclesAllowed = 2,
                    Inherited = 1,
                    Importance = importance
                };
                setup.Insert(validEvent2);

                var country = countryBuilder.Create("country");

                var doc = documentBuilder.Create("doc");

                return new
                {
                    Event = evet.Description,
                    EventId = evet.Id.ToString(),
                    Event2 = evet2.Description,
                    EventId2 = evet2.Id.ToString(),
                    CriteriaId = criteria.Id.ToString(),
                    Country = country,
                    Document = doc
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"/#/configuration/rules/workflows/{data.CriteriaId}/eventcontrol/{data.EventId}");

            var eventControlPage = new EventControlPage(driver);
            eventControlPage.DueDateCalc.Add();

            var modal = new DueDateCalcModal(driver);

            modal.Event.EnterAndSelect(data.Event);
            FillModal(modal, data);
            modal.ToggleAddAnother();
            modal.Apply();

            var dueDateCalc = eventControlPage.DueDateCalc;

            Assert.IsTrue(modal.Event.Displayed, "Test the modal still there by checking event picklist there");
            Assert.AreEqual(1, dueDateCalc.GridRowsCount);

            modal.Event.EnterAndSelect(data.Event2);
            FillModal(modal, data);
            modal.ToggleAddAnother();
            modal.Apply();

            Assert.AreEqual(2, dueDateCalc.GridRowsCount);

            Assert.AreEqual("2", dueDateCalc.FirstCycle);
            Assert.AreEqual(data.Country.Id, dueDateCalc.FirstJurisdiction);
            Assert.AreEqual("Add", dueDateCalc.FirstOperator);
            Assert.AreEqual("2 Days", dueDateCalc.FirstPeriod);
            Assert.IsTrue(dueDateCalc.Event.Contains(data.Event));
            Assert.IsTrue(dueDateCalc.Event.Contains(data.EventId));
            Assert.AreEqual("Due Date", dueDateCalc.FirstFromTo);
            Assert.AreEqual("Current Cycle", dueDateCalc.FirstRelativeCycle);
            Assert.IsTrue(dueDateCalc.FirstMustExist);

            eventControlPage.Save();
        }

        void FillModal(DueDateCalcModal modal, dynamic data)
        {
            modal.DueDate.Click();

            modal.MustExist.Click();

            modal.Add.Click();

            modal.Period.Text = "2";

            modal.Period.OptionText = "Days";

            modal.RelativeCycle.Text = "Current Cycle";

            modal.ToCycle.Text = "2";

            modal.AdjustBy.Input.SelectByIndex(1);

            modal.NonWorkDay.Input.SelectByIndex(1);

            modal.Jurisdiction.EnterAndSelect(data.Country.Name);

            modal.Document.EnterAndSelect(data.Document.Code);

            modal.UseAlternateReminder.Click();
        }

    }

}
