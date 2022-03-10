using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EntryControl
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "12.1")]
    public class UserAccess : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddDeleteUserRole(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            Criteria criteria;
            DataEntryTask entry;

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
            }

            SignIn(driver, $"#/configuration/rules/workflows/{criteria.Id}/entrycontrol/{entry.Id}");

            driver.With<EntryControlPage>((entryControl, popups) =>
            {
                Assert.AreEqual(0, entryControl.UserAccess.Grid.Rows.Count, "Grid should initially be empty");
                Assert.False(entryControl.SaveButton.Enabled, "Save button should be disabled");
                Assert.False(entryControl.RevertButton.Enabled, "Discard button should be disabled");
                
                entryControl.UserAccess.NavigateTo();
                entryControl.UserAccess.Add();
                Assert.IsTrue(entryControl.UserAccess.RolesPickList.ModalDisplayed, "Clicking ADD should open picklist");

                entryControl.UserAccess.RolesPickList.SelectRow(0);
                entryControl.UserAccess.RolesPickList.SelectRow(1);
                entryControl.UserAccess.RolesPickList.Apply();

                Assert.AreEqual(2, entryControl.UserAccess.Grid.Rows.Count, "Two rows should be added");
                Assert.False(entryControl.SaveButton.WithJs().IsDisabled(), "Save button should be enabled");
                Assert.False(entryControl.RevertButton.WithJs().IsDisabled(), "Discard button should be enabled");
                
                entryControl.UserAccess.Grid.ToggleDelete(0);
                Assert.AreEqual(1, entryControl.UserAccess.Grid.Rows.Count, "One item should remain after other item deleted");
                
                entryControl.Save();

                Assert.AreEqual(1, entryControl.UserAccess.Grid.Rows.Count, "One item should be reloaded after save");
                Assert.AreEqual(1, entryControl.UserAccess.NumberOfRecords(), "Topic displays the count");
            });
        }
    }
}