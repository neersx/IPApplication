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
    public class EntryStepsUpdate : IntegrationTest
    {
        
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void UpdateEntrySteps(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            Criteria criteria;
            DataEntryTask entry;
            string[] screens;
            var picklistFilterDescription = new Dictionary<string, string>();
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

                screens = setup.AddStepForAllScreensTypes(criteria, entry);

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

            SignIn(driver, $"#/configuration/rules/workflows/{criteria.Id}/entrycontrol/{entry.Id}");

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              //Filter - Action
                                              entrycontrol.Steps.Grid.ClickEdit(0);
                                              Assert.AreEqual(screens[0], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["action"]);
                                              entrycontrol.CreateOrEditStepModal.NavigateToNext();

                                              //Filter - Checklist
                                              Assert.AreEqual(screens[1], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["checklist"]);
                                              entrycontrol.CreateOrEditStepModal.NavigateToNext();

                                              //Filter - Country Flag 
                                              Assert.AreEqual(screens[2], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["countryflag"]);
                                              entrycontrol.CreateOrEditStepModal.NavigateToNext();

                                              //No filter type - General Screen type
                                              Assert.AreEqual(screens[3], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              Assert.False((bool) entrycontrol.CreateOrEditStepModal.IsMandatory.IsChecked);

                                              entrycontrol.CreateOrEditStepModal.Title.Input.Clear();
                                              entrycontrol.CreateOrEditStepModal.Title.Input.SendKeys(screens[0] + "modify");
                                              entrycontrol.CreateOrEditStepModal.UserTip.Input.SendKeys("This is new user Tip");
                                              entrycontrol.CreateOrEditStepModal.IsMandatory.Click();
                                              entrycontrol.CreateOrEditStepModal.NavigateToNext();

                                              //Filter - Relationship
                                              Assert.AreEqual(screens[4], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["relationship"]);
                                              entrycontrol.CreateOrEditStepModal.NavigateToNext();

                                              //Filter - Names
                                              Assert.AreEqual(screens[5], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["name"]);
                                              entrycontrol.CreateOrEditStepModal.NavigateToNext();

                                              //Filter - Official numbers
                                              Assert.AreEqual(screens[6], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["officialnumber"]);
                                              entrycontrol.CreateOrEditStepModal.NavigateToNext();

                                              //Filter - Name Group
                                              Assert.AreEqual(screens[7], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["namegroup"]);
                                              entrycontrol.CreateOrEditStepModal.NavigateToNext();

                                              //Filter - Relationship
                                              Assert.AreEqual(screens[8], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["relationship"]);
                                              entrycontrol.CreateOrEditStepModal.NavigateToNext();

                                              //Filter - textType
                                              Assert.AreEqual(screens[9], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["texttype"]);
                                              entrycontrol.CreateOrEditStepModal.NavigateToNext();

                                              //Filter - NameText 
                                              Assert.AreEqual(screens[10], entrycontrol.CreateOrEditStepModal.Title.Text);
                                              entrycontrol.CreateOrEditStepModal.Category1.EnterAndSelect(picklistFilterDescription["name"]);
                                              entrycontrol.CreateOrEditStepModal.Category2.EnterAndSelect(picklistFilterDescription["texttype"]);
                                              entrycontrol.CreateOrEditStepModal.Apply();
                                              entrycontrol.Save();
                                          });

            driver.With<EntryControlPage>((entrycontrol, popups) =>
                                          {
                                              var screenCaseEventsRow = entrycontrol.Steps.GetDataForRow(0);
                                              Assert.True(screenCaseEventsRow.Categories.Contains(picklistFilterDescription["valid-action"]));

                                              var screenChecklistRow = entrycontrol.Steps.GetDataForRow(1);
                                              Assert.True(screenChecklistRow.Categories.Contains(picklistFilterDescription["valid-checklist"]));

                                              var screenCountryFlagRow = entrycontrol.Steps.GetDataForRow(2);
                                              Assert.True(screenCountryFlagRow.Categories.Contains(picklistFilterDescription["countryflag"]));

                                              var screenGeneralRow = entrycontrol.Steps.GetDataForRow(3);
                                              Assert.AreEqual(screens[0] + "modify", screenGeneralRow.Title);
                                              Assert.AreEqual("This is new user Tip", screenGeneralRow.UserTip);
                                              Assert.True(screenGeneralRow.Mandatory);

                                              var screenMRelationshipRow = entrycontrol.Steps.GetDataForRow(4);
                                              Assert.True(screenMRelationshipRow.Categories.Contains(picklistFilterDescription["relationship"]));

                                              var screenNamesRow = entrycontrol.Steps.GetDataForRow(5);
                                              Assert.True(screenNamesRow.Categories.Contains(picklistFilterDescription["name"]));

                                              var screenOfficalNumbersRow = entrycontrol.Steps.GetDataForRow(6);
                                              Assert.True(screenOfficalNumbersRow.Categories.Contains(picklistFilterDescription["officialnumber"]));

                                              var screenNameGroupRow = entrycontrol.Steps.GetDataForRow(7);
                                              Assert.True(screenNameGroupRow.Categories.Contains(picklistFilterDescription["namegroup"]));

                                              var screenRelationshipRow = entrycontrol.Steps.GetDataForRow(8);
                                              Assert.True(screenRelationshipRow.Categories.Contains(picklistFilterDescription["relationship"]));

                                              var screenTextRow = entrycontrol.Steps.GetDataForRow(9);
                                              Assert.True(screenTextRow.Categories.Contains(picklistFilterDescription["texttype"]));

                                              var screenNameTextRow = entrycontrol.Steps.GetDataForRow(10);
                                              Assert.True(screenNameTextRow.Categories.Contains(picklistFilterDescription["texttype"]));
                                              Assert.True(screenNameTextRow.Categories.Contains(picklistFilterDescription["name"]));
                                          });
        }
    }
}
