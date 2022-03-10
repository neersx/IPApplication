using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;
using Status = InprotechKaizen.Model.Cases.Status;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.EntryControl
{
    public abstract class EntryControl : IntegrationTest
    {
        internal void GotoEntryControlPage(NgWebDriver driver, string criteriaId)
        {
            SignIn(driver, "/#/configuration/rules/workflows");

            driver.FindRadio("search-by-criteria").Label.ClickWithTimeout();

            var searchResults = new KendoGrid(driver, "searchResults");
            var searchOptions = new SearchOptions(driver);
            var pl = new PickList(driver).ByName("ip-search-by-criteria", "criteria");
            pl.EnterAndSelect(criteriaId);

            searchOptions.SearchButton.ClickWithTimeout();

            driver.WaitForAngular();

            Assert2.WaitTrue(3, 500, () => searchResults.LockedRows.Count > 0, "Search should return some results");

            searchResults.LockedCell(0, 3).FindElement(By.TagName("a")).ClickWithTimeout();

            var workflowDetailsPage = new CriteriaDetailPage(driver);

            workflowDetailsPage.EntriesTopic.NavigateToDetailByRowIndex(0);
        }

        internal void AssertDataEntryGrid(EntryControlDbSetup.DataFixture dataFixture, EntryControlPage entryControlPage)
        {
            Assert.AreEqual(CombinedColumns(dataFixture.EventToUpdateInDetails, dataFixture.EventToUpdateNoInDetails), entryControlPage.Details.GetEventDataForRow(0).UpdateEvent);
            Assert.AreEqual(dataFixture.EventDateInDetails, entryControlPage.Details.GetEventDataForRow(0).EventDateAttribute);
            Assert.AreEqual(dataFixture.DueDateInDetails, entryControlPage.Details.GetEventDataForRow(0).DueDateAttribute);
            Assert.AreEqual(dataFixture.PeriodInDetails, entryControlPage.Details.GetEventDataForRow(0).Period);
            Assert.AreEqual(dataFixture.PolicingInDetails, entryControlPage.Details.GetEventDataForRow(0).Policing);
        }

        internal string CombinedColumns(string field, string fieldInBrackets)
        {
            return $"{field} ({fieldInBrackets})";
        }
    }

    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "12.1")]
    public class EntryControlView : EntryControl
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ViewReadonlyEntryControl(BrowserType browserType)
        {
            EntryControlDbSetup.DataFixture dataFixture;

            using (var setup = new EntryControlDbSetup())
            {
                dataFixture = setup.SetUp();
            }

            var driver = BrowserProvider.Get(browserType);

            GotoEntryControlPage(driver, dataFixture.CriteriaId);

            var entryControlPage = new EntryControlPage(driver);

            #region Page Header

            Assert.AreEqual(dataFixture.CriteriaId, entryControlPage.Header.CriteriaNumber);
            Assert.AreEqual(dataFixture.EntryDescription, entryControlPage.Header.Description);

            Assert.True(driver.Title.StartsWith(dataFixture.CriteriaId));
            Assert.True(driver.Title.Contains(dataFixture.EntryDescription));
            #endregion

            #region Definition

            Assert.AreEqual(dataFixture.EntryDescription, entryControlPage.Definition.DescriptionText);
            Assert.AreEqual(dataFixture.UserInstructions, entryControlPage.Definition.UserInstructionsText);

            #endregion

            #region Details

            Assert.AreEqual(1, entryControlPage.Details.GridRowsCount);
            Assert.True(entryControlPage.Details.GetEventDataForRow(0).Inherited);
            Assert.AreEqual(CombinedColumns(dataFixture.EventNameInDetails, dataFixture.EventNoInDetails), entryControlPage.Details.GetEventDataForRow(0).EntryEvent);

            AssertDataEntryGrid(dataFixture, entryControlPage);

            #endregion

            #region Other Details

            Assert.AreEqual(dataFixture.OfficialNumberType, entryControlPage.Details.OfficialNumberTypeDescription);
            Assert.AreEqual(dataFixture.FileLocation, entryControlPage.Details.FileLocationDescription);
            Assert.True(entryControlPage.Details.IsPoliceImmediatelyYesChecked);
            Assert.False(entryControlPage.Details.IsPoliceImmediatelyNoChecked);

            #endregion

            #region Steps

            var firstRow = entryControlPage.Steps.GetDataForRow(0);
            Assert.True(firstRow.Inherited);
            Assert.AreEqual(1, entryControlPage.Steps.GridRowsCount);
            Assert.AreEqual(dataFixture.EntryStepOriginalTitle, firstRow.StepTitle);
            Assert.AreEqual(dataFixture.EntryStepTitle, firstRow.Title);
            Assert.AreEqual(dataFixture.EntryStepScreenTip, firstRow.UserTip);
            Assert.True(firstRow.Mandatory);
            Assert.True(firstRow.Categories.Contains(dataFixture.EntryStepCategory1));
            Assert.True(firstRow.Categories.Contains(dataFixture.EntryStepCategoryValue1));
            Assert.True(firstRow.Categories.Contains(dataFixture.EntryStepCategory2));
            Assert.True(firstRow.Categories.Contains(dataFixture.EntryStepCategoryValue2));

            #endregion

            #region Change Status

            Assert.AreEqual(dataFixture.ChangeCaseStatus, entryControlPage.ChangeStatus.ChangeCaseStatus);
            Assert.AreEqual(dataFixture.ChangeRenewalStatus, entryControlPage.ChangeStatus.ChangeRenewalStatus);

            #endregion

            #region Documents

            Assert.True(entryControlPage.Documents.IsInheritedInFirstRow);
            Assert.AreEqual(1, entryControlPage.Documents.GridRowsCount);
            Assert.AreEqual(dataFixture.DocumentNameInDocuments, entryControlPage.Documents.DocumentName);
            Assert.True(entryControlPage.Documents.IsProduceChecked);

            #endregion

            #region Display Options

            Assert.AreEqual($"({dataFixture.DisplayEventId}) {dataFixture.DisplayEventDescription}", entryControlPage.DisplayConditions.DisplayEventDescription);
            Assert.AreEqual($"({dataFixture.HideEventId}) {dataFixture.HideEventDescription}", entryControlPage.DisplayConditions.HideEventDescription);
            Assert.AreEqual($"({dataFixture.DimEventId}) {dataFixture.DimEventDescription}", entryControlPage.DisplayConditions.DimEventDescription);

            #endregion

            #region User Access

            entryControlPage.UserAccess.NavigateTo();
            Assert.IsTrue(entryControlPage.UserAccess.IsInheritedInFirstRow);
            Assert.AreEqual(dataFixture.UserAccessRoleName, entryControlPage.UserAccess.RoleName);

            entryControlPage.UserAccess.Grid.ToggleDetailsRow(0);
            var fields = driver.FindElements(By.CssSelector("ip-workflows-entry-control-user-access-users div[ng-class]")).Select(f => WithJsExt.WithJs((NgWebElement)f).GetInnerText()).ToArray();
            Assert.Contains(dataFixture.UserLogInInRole, fields);
            Assert.Contains(dataFixture.UserNameInRole, fields);

            #endregion
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ViewEntryControlInheritance(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var parent = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("parent"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                var parentEntry = setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 1) { Description = "Entry", UserInstruction = "Instruction" });

                var child = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("child"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                var childEntry1 = setup.Insert<DataEntryTask>(new DataEntryTask(child.Id, 1)
                {
                    Description = "Entry",
                    UserInstruction = "Instruction",
                    Inherited = 1,
                    ParentCriteriaId = parent.Id,
                    ParentEntryId = parentEntry.Id,
                    DisplayEventNo = 0,
                    HideEventNo = 8,
                    DimEventNo = -700
                });

                var grandChild = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("grandChild"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                setup.Insert<DataEntryTask>(new DataEntryTask(grandChild.Id, 1)
                {
                    Description = "Entry",
                    UserInstruction = "Different Instruction",
                    Inherited = 1,
                    ParentCriteriaId = child.Id,
                    ParentEntryId = childEntry1.Id,
                    DisplayEventNo = 0,
                    HideEventNo = 8,
                    DimEventNo = -700
                });

                setup.Insert(new Inherits { Criteria = child, FromCriteria = parent });
                setup.Insert(new Inherits { Criteria = grandChild, FromCriteria = child });

                return new
                {
                    Parent = parent,
                    Child = child,
                    GrandChild = grandChild
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, $"#/configuration/rules/workflows/{data.GrandChild.Id}/entrycontrol/1");
            driver.With<EntryControlPage>((entrycontrol, popups) =>
            {
                Assert.IsTrue(entrycontrol.Definition.Description.Element.GetParent().GetAttribute("class").Contains("input-inherited"), "Description should be displayed as inherited");
                Assert.IsFalse(entrycontrol.Definition.UserInstruction.Element.GetParent().GetAttribute("class").Contains("input-inherited"), "Diffierent User instruction should be not displayed as inherited");

                entrycontrol.Definition.Description.Input.SendKeys("extra");
                Assert.IsFalse(entrycontrol.Definition.Description.Element.WithJs().GetAttributeValue<string>("class").Contains("input-inherited"), "Edited Case Status pick list should not display as inherited");

                entrycontrol.DisplayConditions.NavigateTo();
                Assert.IsTrue(entrycontrol.DisplayConditions.TopicContainer.FindElement(By.ClassName("input-inherited")).TagName.Equals("div"), "Display conditions pick list should display as inherited");
                var element = entrycontrol.DisplayConditions.TopicContainer.FindElement(By.ClassName("input-inherited"));
                entrycontrol.DisplayConditions.HideEventPl.Typeahead.Clear();
                Assert.IsFalse(element.WithJs().GetAttributeValue<string>("class").Contains("input-inherited"), "Display conditions pick list should not display as inherited");

                //https://github.com/mozilla/geckodriver/issues/1151
                entrycontrol.RevertButton.Click();  //edit mode discard
                entrycontrol.Discard(); // discard confirm.
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void ViewSeparatorEntryControl(BrowserType browserType)
        {
            var separatorDescription = "---------------" + Fixture.Prefix("Filling") + "-----------";
            int? criteriaId;
            using (var setup = new EntryControlDbSetup())
            {
                criteriaId = setup.SetUpSeparatorEntry(separatorDescription);
            }

            var driver = BrowserProvider.Get(browserType);

            GotoEntryControlPage(driver, criteriaId.ToString());
            var entryControlPage = new EntryControlPage(driver);

            Assert.AreEqual(criteriaId.ToString(), entryControlPage.Header.CriteriaNumber);
            Assert.AreEqual(separatorDescription, entryControlPage.Header.Description, $"Separator description is displayed as {separatorDescription}");
            Assert.True(entryControlPage.Header.SeparatorIndicator, "Separator indicator label is displayed");
            Assert.False(entryControlPage.Details.Displayed(), "Details topic is hidden");
            Assert.False(entryControlPage.Steps.Displayed(), "Steps topic is hidden");
            Assert.False(entryControlPage.Documents.Displayed(), "Documents topic is hidden");
        }

    }

    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "12.1")]
    public class EntryControlEditing : EntryControl
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SaveEntryDetails(BrowserType browserType)
        {
            EntryControlDbSetup.DataFixture dataFixture;
            NumberType numberType;
            TableCode fileLocation;
            using (var setup = new EntryControlDbSetup())
            {
                dataFixture = setup.SetUp();
                numberType = setup.InsertWithNewId(new NumberType { Name = Fixture.Prefix("number-type2") }, v => v.NumberTypeCode);
                fileLocation = setup.InsertWithNewId(new TableCode
                {
                    TableTypeId = (int)TableTypes.FileLocation,
                    Name = Fixture.Prefix("file2")
                });
                setup.InsertWithNewId(new Status
                {
                    Name = Fixture.Prefix("case-status-2"),
                    RenewalFlag = 0
                });

                setup.InsertWithNewId(new Status
                {
                    Name = Fixture.Prefix("renewal-case-status-2"),
                    RenewalFlag = 1
                });
            }

            var driver = BrowserProvider.Get(browserType);

            GotoEntryControlPage(driver, dataFixture.CriteriaId);

            var entryControlPage = new EntryControlPage(driver);

            Assert.AreEqual(1, entryControlPage.Details.GridRowsCount);
            Assert.True(entryControlPage.Details.GetEventDataForRow(0).Inherited);
            AssertDataEntryGrid(dataFixture, entryControlPage);

            ReloadPage(driver);

            entryControlPage.Details.OfficialNumberTypePl.Clear();
            entryControlPage.Details.OfficialNumberTypePl.SendKeys(numberType.Name).Blur();
            entryControlPage.Details.FileLocationPl.Clear();
            entryControlPage.Details.FileLocationPl.SendKeys(fileLocation.Name).Blur();
            entryControlPage.Details.AtleastOneEventFlag.WithJs().Click();

            entryControlPage.SaveButton.ClickWithTimeout();

            Assert.NotNull(new CommonPopups(driver).FlashAlertIsDisplayed());
            Assert.True(entryControlPage.Details.AtleastOneEventFlagValue);

            entryControlPage.DisplayConditions.DisplayEventPl.Clear();
            entryControlPage.DisplayConditions.DisplayEventPl.SendKeys(dataFixture.HideEventDescription);
            entryControlPage.DisplayConditions.DisplayEventPl.Blur();

            Assert.False(entryControlPage.SaveButton.Enabled);
            Assert.True(entryControlPage.DisplayConditions.DisplayEventPl.HasError);

            entryControlPage.DisplayConditions.DisplayEventPl.Clear();
            entryControlPage.DisplayConditions.DisplayEventPl.Blur();

            Assert.False(entryControlPage.DisplayConditions.DisplayEventPl.HasError);

            driver.Wait().ForInvisible(By.ClassName("flash_alert"));

            entryControlPage.SaveButton.ClickWithTimeout();

            Assert.NotNull(new CommonPopups(driver).FlashAlertIsDisplayed());
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void SaveEntryDetailsPropagateToChildren(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var existingEntry = "EntryExists";
            var data = DbSetup.Do(setup =>
            {
                var parent = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("parent"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                var parentEntry = setup.Insert<DataEntryTask>(new DataEntryTask(parent.Id, 1) { Description = "Entry 1", UserInstruction = "Instruction" });

                var child = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("child"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                var childEntry1 = setup.Insert<DataEntryTask>(new DataEntryTask(child.Id, 1) { Description = "Entry- 1", UserInstruction = "Instruction", Inherited = 1, ParentCriteriaId = parent.Id, ParentEntryId = parentEntry.Id });
                var childEntry2 = setup.Insert<DataEntryTask>(new DataEntryTask(child.Id, 2) { Description = "Some Other Entry", UserInstruction = "Different Instruction", Inherited = 0 });

                var grandChild = setup.InsertWithNewId(new Criteria
                {
                    Description = Fixture.Prefix("grandChild"),
                    PurposeCode = CriteriaPurposeCodes.EventsAndEntries
                });
                setup.Insert<DataEntryTask>(new DataEntryTask(grandChild.Id, 1) { Description = "Entry: 1", UserInstruction = "Different Instruction", Inherited = 1, ParentCriteriaId = child.Id, ParentEntryId = childEntry1.Id });
                setup.Insert<DataEntryTask>(new DataEntryTask(grandChild.Id, 2) { Description = existingEntry, UserInstruction = "Different Instruction", Inherited = 1, ParentCriteriaId = child.Id, ParentEntryId = childEntry2.Id });

                setup.Insert(new Inherits { Criteria = child, FromCriteria = parent });
                setup.Insert(new Inherits { Criteria = grandChild, FromCriteria = child });

                return new
                {
                    Parent = parent,
                    Child = child,
                    GrandChild = grandChild
                };
            });

            var entryNewDescription = "  EntryA ";

            SignIn(driver, $"/#/configuration/rules/workflows/{data.Parent.Id}/entrycontrol/{1}");
            driver.With<EntryControlPage>((entrycontrol, popups) =>
            {
                entrycontrol.Definition.Description.Input.Clear();
                entrycontrol.Definition.Description.Input.SendKeys(existingEntry);

                entrycontrol.Save();

                Assert.True(entrycontrol.EntryInheritanceConfirmationModal.AffectedSectionIsDisplayed);
                entrycontrol.EntryInheritanceConfirmationModal.IsCriteriaShownAsAffected(data.Child.Id.ToString());

                Assert.True(entrycontrol.EntryInheritanceConfirmationModal.BreakingSectionIsDisplayed);
                entrycontrol.EntryInheritanceConfirmationModal.IsCriteriaShownAsBreaking(data.GrandChild.Id.ToString());

                entrycontrol.EntryInheritanceConfirmationModal.Cancel();

                entrycontrol.Definition.Description.Input.Clear();
                entrycontrol.Definition.Description.Input.SendKeys(entryNewDescription);

                entrycontrol.Definition.UserInstruction.Input.Clear();
                entrycontrol.Definition.UserInstruction.Input.SendKeys("New Instruction");

                entrycontrol.Save();

                Assert.True(entrycontrol.EntryInheritanceConfirmationModal.AffectedSectionIsDisplayed);
                entrycontrol.EntryInheritanceConfirmationModal.IsCriteriaShownAsAffected(data.Child.Id.ToString());
                entrycontrol.EntryInheritanceConfirmationModal.IsCriteriaShownAsAffected(data.GrandChild.Id.ToString());

                Assert.False(entrycontrol.EntryInheritanceConfirmationModal.BreakingSectionIsDisplayed);

                entrycontrol.EntryInheritanceConfirmationModal.Proceed();

                entrycontrol.LevelUpButton.Click();
            });

            driver.With<CriteriaDetailPage>((criteriaPage, popups) =>
            {
                Assert.AreEqual(entryNewDescription, criteriaPage.EntriesTopic.Grid.CellText(0, 2, trim: false));
            });

            driver.Visit($"/#/configuration/rules/workflows/{data.Child.Id}/entrycontrol/{1}");
            driver.With<EntryControlPage>((entrycontrol, popups) =>
            {
                Assert.AreEqual(entryNewDescription, entrycontrol.Definition.DescriptionText);
                Assert.AreEqual("New Instruction", entrycontrol.Definition.UserInstructionsText);
            });

            driver.Visit($"/#/configuration/rules/workflows/{data.GrandChild.Id}/entrycontrol/{1}");

            driver.With<EntryControlPage>((entrycontrol, popups) =>
            {
                Assert.AreEqual(entryNewDescription, entrycontrol.Definition.DescriptionText);
                Assert.AreEqual("Different Instruction", entrycontrol.Definition.UserInstructionsText);
                Assert.IsTrue(entrycontrol.InheritanceIcon.Displayed);

                entrycontrol.Definition.Description.Input.Clear();
                entrycontrol.Definition.Description.Input.SendKeys("EntryB");

                entrycontrol.Save();

                popups.ConfirmModal.PrimaryButton.ClickWithTimeout();
                Assert.True(popups.FlashAlertIsDisplayed());
                Assert.IsNull(entrycontrol.InheritanceIcon);
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteCurrentEntry(BrowserType browserType)
        {
            Criteria parentCriteria, childCriteria1;
            //var entryDescription1 = "E2EEntry1" + RandomString.Next(6);
            var entryDescription1 = "E2EEntry1" + Fixture.Prefix();
            var entryDescription2 = "E2EEntry2" + Fixture.Prefix();
            var entryDescription3 = "E2EEntry3" + Fixture.Prefix();
            var entryDescription4 = "E2EEntry4" + Fixture.Prefix();

            using (var setup = new CriteriaDetailDbSetup())
            {
                parentCriteria = setup.AddCriteria("E2ECriteriaParent" + RandomString.Next(6));
                var p1 = setup.Insert(new DataEntryTask(parentCriteria, 1) { Description = entryDescription1 });
                setup.Insert(new DataEntryTask(parentCriteria, 2) { Description = entryDescription2 });
                setup.Insert(new DataEntryTask(parentCriteria, 3) { Description = entryDescription3 });
                setup.Insert(new DataEntryTask(parentCriteria, 4) { Description = entryDescription4 });

                childCriteria1 = setup.AddChildCriteria(parentCriteria, "E2ECriteriaChild1" + RandomString.Next(6));
                setup.Insert(new DataEntryTask(childCriteria1, 1)
                {
                    Description = entryDescription1,
                    ParentCriteriaId = p1.CriteriaId,
                    ParentEntryId = p1.Id,
                    Inherited = 1
                });
                setup.Insert(new DataEntryTask(childCriteria1, 1) { Description = entryDescription3 + "*", Inherited = 0 });
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows/" + parentCriteria.Id);

            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;
                entriesTopic.NavigateToDetailByRowIndex(0);
            });

            driver.With<EntryControlPage>((entrycontrol, popups) =>
            {
                entrycontrol.Delete();
                //show confirmation dialog if children exist
                entrycontrol.EntryInheritanceDeleteModal.Delete();

                Assert.AreEqual(driver.Location, $"/configuration/rules/workflows/{parentCriteria.Id}/entrycontrol/{parentCriteria.DataEntryTasks.First(_ => _.Description == entryDescription2).Id}", "Should navigate to next entry");

                entrycontrol.LevelUpButton.Click();
                driver.With<CriteriaDetailPage>(workflowDetails =>
                {
                    var entriesTopic = workflowDetails.EntriesTopic;
                    Assert.IsFalse(entriesTopic.Grid.ColumnValues(1).Contains(entryDescription1), "First Entry should be removed from the grid.");
                    entriesTopic.NavigateToDetailByRowIndex(0);
                });

                entrycontrol.Delete();
                //show simple popup for confirmation if no inheritance
                popups.ConfirmDeleteModal.Delete().TryClick();

                Assert.AreEqual(driver.Location, $"/configuration/rules/workflows/{parentCriteria.Id}/entrycontrol/{parentCriteria.DataEntryTasks.First(_ => _.Description == entryDescription3).Id}", "Should navigate to next entry");

                driver.Navigate().Back();
                driver.With<CriteriaDetailPage>(workflowDetails =>
                {
                    var entriesTopic = workflowDetails.EntriesTopic;
                    Assert.IsFalse(entriesTopic.Grid.ColumnValues(1).Contains(entryDescription2), "Second Entry should be removed from the grid.");
                    driver.Navigate().Forward();
                });

                entrycontrol.PageNav.LastPage();
                entrycontrol.Delete();
                //show simple popup for confirmation if no inheritance
                popups.ConfirmDeleteModal.Delete().TryClick();

                Assert.AreEqual(driver.Location, $"/configuration/rules/workflows/{parentCriteria.Id}/entrycontrol/{parentCriteria.DataEntryTasks.First(_ => _.Description == entryDescription3).Id}", "Should navigate to previous entry if last entry deleted");

                entrycontrol.Delete();
                //show confirmation dialog if children exist
                popups.ConfirmDeleteModal.Delete().TryClick();

                Assert.AreEqual(driver.Location, $"/configuration/rules/workflows/{parentCriteria.Id}", "Should navigate back to criteria detail if only remiaining entry is deleted");

                driver.With<CriteriaDetailPage>((workflowDetails) =>
                {
                    var entriesTopic = workflowDetails.EntriesTopic;
                    Assert.AreEqual(0, entriesTopic.Grid.Rows.Count, "Grid should show no entries.");
                });
            });

            driver.Visit("/#/configuration/rules/workflows/" + childCriteria1.Id);
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;
                entriesTopic.NavigateToDetailByRowIndex(0);
            });

            driver.With<EntryControlPage>((entrycontrol, popups) =>
            {
                entrycontrol.Delete();
                //The inherited entry is already deleted when deleting from parent
                popups.ConfirmDeleteModal.Delete().TryClick();

                Assert.AreEqual(driver.Location, $"/configuration/rules/workflows/{childCriteria1.Id}", "Should navigate back to criteria detail after page refresh when no navigation data is available");
            });
        }
    }
}