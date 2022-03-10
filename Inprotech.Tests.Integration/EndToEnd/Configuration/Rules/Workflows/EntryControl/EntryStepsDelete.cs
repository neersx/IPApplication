using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.Screens;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EntryControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class EntryStepsDelete : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEntryStep(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            Criteria criteria;
            DataEntryTask entry;
            TopicControl officialNumberStep;
            const string title = "Official Number Title";
            using (var setup = new EntryControlDbSetup())
            {
                criteria = setup.InsertWithNewId(new Criteria
                                                 {
                                                     Description = Fixture.Prefix("parent"),
                                                     PurposeCode = CriteriaPurposeCodes.EventsAndEntries,
                                                     Country = new CountryBuilder(setup.DbContext).Create("e2eCountry" + Fixture.Prefix("step")),
                                                     PropertyType = setup.InsertWithNewId(new PropertyType {Name = "e2ePropertyType" + Fixture.Prefix("setp")}),
                                                     CaseType = setup.InsertWithNewId(new CaseType {Name = "e2eCaseType" + Fixture.Prefix("step")})
                                                 });

                entry = setup.Insert<DataEntryTask>(new DataEntryTask(criteria.Id, 1) {Description = "Entry 1"});

                setup.AddNameStepWithFilter(criteria, entry);
                setup.AddOfficialNumberWithFilter(criteria, entry, null);
                officialNumberStep = setup.AddOfficialNumberWithFilter(criteria, entry, title);
            }

            SignIn(driver, $"#/configuration/rules/workflows/{criteria.Id}/entrycontrol/{entry.Id}");

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              entrycontrol.Steps.Grid.ToggleDelete(0);
                                              entrycontrol.Steps.Grid.ToggleDelete(1);

                                              entrycontrol.Save();

                                              Assert.AreEqual(1, entrycontrol.Steps.GridRowsCount);
                                              Assert.AreEqual(1, entrycontrol.Steps.NumberOfRecords(), "Topic displays the count");

                                              Assert.AreEqual(officialNumberStep.Title, entrycontrol.Steps.GetDataForRow(0).Title);
                                          });
        }
    }
}
