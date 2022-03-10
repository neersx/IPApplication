using System.Collections.Generic;
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
    public class EntryStepsAdd : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void AddEntrySteps(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            Criteria criteria;
            DataEntryTask entry;
            var picklistFilterDescription = new Dictionary<string, string>();
            string[] screenTypes;
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
                screenTypes = setup.GetAllScreenTypes();

                var action = setup.AddValidAction(criteria.Country, criteria.CaseType, criteria.PropertyType);

                var checklist = setup.AddValidChecklist(criteria.Country, criteria.CaseType, criteria.PropertyType);

                picklistFilterDescription.Add("action", action.Base);
                picklistFilterDescription.Add("valid-action", action.Valid);
                picklistFilterDescription.Add("checklist", checklist.Base);
                picklistFilterDescription.Add("valid-checklist", checklist.Valid);
                picklistFilterDescription.Add("relationship", setup.AddRelationship(criteria.Country, criteria.PropertyType));
                picklistFilterDescription.Add("name", setup.AddName());
                picklistFilterDescription.Add("officialnumber", setup.AddOfficialNumber());
                picklistFilterDescription.Add("texttype", setup.AddTextType());
                picklistFilterDescription.Add("countryflag", setup.AddCountryFlag(criteria.Country));
                picklistFilterDescription.Add("namegroup", setup.AddNameGroup());
            }

            //GotoEntryControlPage(driver, criteria.Id.ToString());
            SignIn(driver, $"#/configuration/rules/workflows/{criteria.Id}/entrycontrol/{entry.Id}");

            driver.With<EntryControlPage>((entrycontrol, popups) =>
            {
                //Filter - Action
                entrycontrol.Steps.Add();
                entrycontrol.CreateOrEditStepModal.Screen.EnterAndSelect(screenTypes[0]);
                entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["action"]);
                entrycontrol.CreateOrEditStepModal.Apply();

                //Filter - Checklist
                entrycontrol.Steps.Add();
                entrycontrol.CreateOrEditStepModal.Screen.EnterAndSelect(screenTypes[1]);
                entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["checklist"]);
                entrycontrol.CreateOrEditStepModal.Apply();

                //Filter - Country Flag
                entrycontrol.Steps.Add();
                entrycontrol.CreateOrEditStepModal.Screen.EnterAndSelect(screenTypes[2]);
                entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["countryflag"]);
                entrycontrol.CreateOrEditStepModal.Apply();

                //No filter type - General Screen type
                entrycontrol.Steps.Add();
                entrycontrol.CreateOrEditStepModal.Screen.EnterAndSelect(screenTypes[3]);
                Assert.False(entrycontrol.CreateOrEditStepModal.IsMandatory.IsChecked);

                entrycontrol.CreateOrEditStepModal.Title.Input.Clear();
                entrycontrol.CreateOrEditStepModal.Title.Input.SendKeys(screenTypes[3] + "modify");
                entrycontrol.CreateOrEditStepModal.UserTip.Input.SendKeys("This is new user Tip");
                entrycontrol.CreateOrEditStepModal.IsMandatory.Click();
                entrycontrol.CreateOrEditStepModal.Apply();

                //Filter - Official numbers
                entrycontrol.Steps.Add();
                entrycontrol.CreateOrEditStepModal.Screen.EnterAndSelect(screenTypes[6]);
                entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["officialnumber"]);
                entrycontrol.CreateOrEditStepModal.Apply();

                //Filter - Name Group
                entrycontrol.Steps.Add();
                entrycontrol.CreateOrEditStepModal.Screen.EnterAndSelect(screenTypes[7]);
                entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["namegroup"]);
                entrycontrol.CreateOrEditStepModal.Apply();

                //Filter - Relationship
                entrycontrol.Steps.Add();
                entrycontrol.CreateOrEditStepModal.Screen.EnterAndSelect(screenTypes[8]);
                entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["relationship"]);
                entrycontrol.CreateOrEditStepModal.Apply();

                //Filter - NameText 
                entrycontrol.Steps.Add();
                entrycontrol.CreateOrEditStepModal.Screen.EnterAndSelect(screenTypes[10]);
                entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["name"]);
                entrycontrol.CreateOrEditStepModal.Category2.EnterAndSelect(picklistFilterDescription["texttype"]);
                entrycontrol.CreateOrEditStepModal.Apply();

                entrycontrol.Save();
            });

            driver.With<EntryControlPage>((entrycontrol, popups) =>
            {
                var screenCaseEventsRow = entrycontrol.Steps.GetDataForRow(0);
                Assert.AreEqual(screenTypes[0], screenCaseEventsRow.StepTitle);
                Assert.True(screenCaseEventsRow.Categories.Contains(picklistFilterDescription["valid-action"]));

                var screenChecklistRow = entrycontrol.Steps.GetDataForRow(1);
                Assert.AreEqual(screenTypes[1], screenChecklistRow.StepTitle);
                Assert.True(screenChecklistRow.Categories.Contains(picklistFilterDescription["valid-checklist"]));

                var screenCountryFlagRow = entrycontrol.Steps.GetDataForRow(2);
                Assert.AreEqual(screenTypes[2], screenCountryFlagRow.StepTitle);
                Assert.True(screenCountryFlagRow.Categories.Contains(picklistFilterDescription["countryflag"]));

                var screenGeneralRow = entrycontrol.Steps.GetDataForRow(3);
                Assert.AreEqual(screenTypes[3], screenGeneralRow.StepTitle);
                Assert.AreEqual(screenTypes[3] + "modify", screenGeneralRow.Title);
                Assert.AreEqual("This is new user Tip", screenGeneralRow.UserTip);
                Assert.True(screenGeneralRow.Mandatory);

                var screenOfficalNumbersRow = entrycontrol.Steps.GetDataForRow(4);
                Assert.AreEqual(screenTypes[6], screenOfficalNumbersRow.StepTitle);
                Assert.True(screenOfficalNumbersRow.Categories.Contains(picklistFilterDescription["officialnumber"]));

                var screenNameGroupRow = entrycontrol.Steps.GetDataForRow(5);
                Assert.AreEqual(screenTypes[7], screenNameGroupRow.StepTitle);
                Assert.True(screenNameGroupRow.Categories.Contains(picklistFilterDescription["namegroup"]));

                var screenRelationshipRow = entrycontrol.Steps.GetDataForRow(6);
                Assert.AreEqual(screenTypes[8], screenRelationshipRow.StepTitle);
                Assert.True(screenRelationshipRow.Categories.Contains(picklistFilterDescription["relationship"]));

                var screenNameTextRow = entrycontrol.Steps.GetDataForRow(7);
                Assert.AreEqual(screenTypes[10], screenNameTextRow.StepTitle);
                Assert.True(screenNameTextRow.Categories.Contains(picklistFilterDescription["name"]));
                Assert.True(screenNameTextRow.Categories.Contains(picklistFilterDescription["texttype"]));
            });
        }
    }
}