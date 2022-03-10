using System;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.EndToEnd.HostedComponents.ContactActivity;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.CommonPageObjects;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;
using OpenQA.Selenium;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Tests.Integration.EndToEnd.TaskPlanner
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class TaskPlannerAttachments : IntegrationTest
    {
        public string Folder { get; private set; }
        public string File { get; private set; }

        [SetUp]
        public void Setup()
        {
            (Folder, File) = AttachmentSetup.Setup();
        }

        [TearDown]
        public void CleanupFiles()
        {
            StorageServiceSetup.Delete();
        }

        (string casePrefix, string Irn, string attachmentName1, string attachmentName2, string eventDesc) CreateAttachmentInDb(bool withAttachment = true)
        {
            var data = DbSetup.Do(setup =>
            {
                var casePrefix = Fixture.AlphaNumericString(15);
                var property = setup.InsertWithNewId(new PropertyType
                {
                    Name = RandomString.Next(5)
                }, x => x.Code);
                var case1 = new CaseBuilder(setup.DbContext).Create(casePrefix + "TaskPlanner", true, propertyType: property);

                var mainRenewalActionSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.MainRenewalAction);
                var renewalAction = setup.DbContext.Set<Action>().Single(_ => _.Code == mainRenewalActionSiteControl.StringValue);
                var criticalDatesSiteControl = setup.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.CriticalDates_Internal);
                var criticalDatesCriteria = setup.DbContext.Set<Criteria>().First(_ => _.ActionId == criticalDatesSiteControl.StringValue);

                setup.Insert(new OpenAction(renewalAction, @case1, 1, null, criticalDatesCriteria, true));
                setup.Insert(new OpenAction(renewalAction, @case1, 2, null, criticalDatesCriteria, true));

                var eventDesc = setup.DbContext.Set<ValidEvent>().SingleOrDefault(_ => _.EventId == (int) KnownEvents.NextRenewalDate && _.CriteriaId == criticalDatesCriteria.Id)?.Description;

                var attachment1 = AddCaseEvent(1);
                var attachment2 = AddCaseEvent(2);

                ActivityAttachment AddCaseEvent(short cycle)
                {
                    var ce = setup.Insert(new CaseEvent(@case1.Id, (int) KnownEvents.NextRenewalDate, cycle) {EventDueDate = DateTime.Today.AddDays(-2).AddDays(1 * cycle), IsOccurredFlag = 0, CreatedByCriteriaKey = criticalDatesCriteria.Id});
                    var tableCodeId = setup.DbContext.Set<TableCode>().Max(_ => _.Id) + 1;
                    var tcActivityType = new TableCode(tableCodeId++, (short) TableTypes.ContactActivityType, "tmpTableCodeActivityType");
                    var tcActivityCategory = new TableCode(tableCodeId++, (short) TableTypes.ContactActivityCategory, "tmpTableCodeActivityCategory");

                    var tcLanguage = new TableCode(tableCodeId, (short) TableTypes.Language, "tmpTableCodeLanguage");

                    setup.DbContext.Set<TableCode>().Add(tcActivityType);
                    setup.DbContext.Set<TableCode>().Add(tcActivityCategory);

                    ActivityAttachment attachment = null;
                    if (withAttachment)
                    {
                        var lastSequence = setup.DbContext.Set<LastInternalCode>().SingleOrDefault(_ => _.TableName == KnownInternalCodeTable.Activity) ?? new LastInternalCode(KnownInternalCodeTable.Activity) {InternalSequence = 0};
                        var activityId = lastSequence.InternalSequence + 1;
                        lastSequence.InternalSequence++;
                        var activity = setup.Insert(new Activity(activityId, "summary", tcActivityCategory, tcActivityType)
                        {
                            CaseId = case1.Id,
                            Cycle = ce.Cycle,
                            EventId = (int) KnownEvents.NextRenewalDate
                        });
                        attachment = setup.Insert(new ActivityAttachment(activity.Id, 0) {AttachmentName = "abcName" + cycle, FileName = @"\\Server1\path1\file1.pdf", Language = tcLanguage, AttachmentType = null, PublicFlag = 0m});
                    }

                    return attachment;
                }

                return new
                {
                    CasePrefix = casePrefix,
                    CaseIrn = case1.Irn,
                    AttachmentName1 = attachment1?.AttachmentName,
                    AttachmentName2 = attachment2?.AttachmentName,
                    EventDesc = eventDesc
                };
            });

            return (data.CasePrefix, data.CaseIrn, data.AttachmentName1, data.AttachmentName2, data.EventDesc);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ViewAttachments(BrowserType browserType)
        {
            var data = CreateAttachmentInDb();

            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithSubjectPermission(ApplicationSubject.Attachments)
                       .Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);

            var page = new TaskPlannerPageObject(driver);
            var page1 = new TaskPlannerSearchBuilderPageObject(driver);
            page.FilterButton.ClickWithTimeout();
            page1.IncludeDueDatesCheckbox.Click();
            page.Cases.CaseReference.SendKeys(data.Irn);
            page.AllNamesInBelongingToDropDown.Click();
            page.AdvancedSearchButton.ClickWithTimeout();

            Assert.AreEqual(2, page.Grid.Rows.Count);
            Assert.AreEqual(2, page.Grid.AttachmentIcons.Count);
            var icon = page.Grid.AttachmentIcons.First();
            CheckHover(data.attachmentName1);
            CheckPopup(data.attachmentName1, 1);

            icon = page.Grid.AttachmentIcons.Skip(1).First();
            CheckHover(data.attachmentName2);
            CheckPopup(data.attachmentName2, 2);

            void CheckHover(string attachmentName)
            {
                driver.Hover(icon);
                driver.WaitForAngular();
                var popup = driver.FindElements(By.ClassName("popover-content")).FirstOrDefault();
                Assert.NotNull(popup);
                Assert.True(popup.Text.Contains("Showing 1 of 1"));
                Assert.True(popup.Text.Contains(attachmentName));
            }

            void CheckPopup(string attachmentName, int cycle)
            {
                icon.ClickWithTimeout();
                var attachments = new AttachmentListObj(driver);
                Assert.AreEqual(1, attachments.AttachmentsGrid.Rows.Count);
                Assert.AreEqual(attachmentName, attachments.AttachmentName(0));
                Assert.AreEqual(cycle.ToString(), attachments.Cycle(0));
                attachments.Close();
            }
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void InsertAttachment(BrowserType browserType)
        {
            var data = CreateAttachmentInDb(false);

            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithSubjectPermission(ApplicationSubject.Attachments)
                       .Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);

            var page = new TaskPlannerPageObject(driver);
            var page1 = new TaskPlannerSearchBuilderPageObject(driver);
            page.FilterButton.ClickWithTimeout();
            page1.IncludeDueDatesCheckbox.Click();
            page.Cases.CaseReference.SendKeys(data.Irn);
            page.AllNamesInBelongingToDropDown.Click();
            page.AdvancedSearchButton.ClickWithTimeout();

            Assert.AreEqual(2, page.Grid.Rows.Count);
            Assert.AreEqual(0, page.Grid.AttachmentIcons.Count);

            page.ContextMenu.AddAttachment(0);

            var attachmentMaintenancePage = new AttachmentPageObj(driver);
            Assert.IsTrue(attachmentMaintenancePage.SelectedEntityLabelText.Contains(data.Irn), $"Expected label to display {data.Irn} but was {attachmentMaintenancePage.SelectedEntityLabelText}");
            Assert.AreEqual(data.eventDesc, attachmentMaintenancePage.ActivityEvent.GetText());

            attachmentMaintenancePage.AttachmentName.Input.SendKeys($"test{data.Irn}");
            attachmentMaintenancePage.FilePath.Input.SendKeys("iwl:abcde");
            attachmentMaintenancePage.ActivityType.Input.SelectByIndex(0);
            attachmentMaintenancePage.ActivityCategory.Input.SelectByIndex(0);
            attachmentMaintenancePage.ActivityDate.GoToDate(-1);
            attachmentMaintenancePage.AttachmentType.Clear();
            attachmentMaintenancePage.AttachmentType.SelectByIndex(0);

            attachmentMaintenancePage.Language.Clear();
            attachmentMaintenancePage.Language.SelectByIndex(0);

            attachmentMaintenancePage.Save();

            driver.WaitForAngular();

            Assert.AreEqual(1, page.Grid.AttachmentIcons.Count, "Newly added attachment is displayed");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void UpdateAttachment(BrowserType browserType)
        {
            var data = CreateAttachmentInDb();

            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithSubjectPermission(ApplicationSubject.Attachments)
                       .Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);

            var page = new TaskPlannerPageObject(driver);
            var page1 = new TaskPlannerSearchBuilderPageObject(driver);
            page.FilterButton.ClickWithTimeout();
            page1.IncludeDueDatesCheckbox.Click();
            page.Cases.CaseReference.SendKeys(data.Irn);
            page.AllNamesInBelongingToDropDown.Click();
            page.AdvancedSearchButton.ClickWithTimeout();

            Assert.AreEqual(2, page.Grid.Rows.Count);
            Assert.AreEqual(2, page.Grid.AttachmentIcons.Count);

            page.Grid.AttachmentIcons.First().Click();

            driver.WaitForAngular();

            var attachmentList = new AttachmentListObj(driver);
            Assert.AreEqual(1, attachmentList.AttachmentsGrid.Rows.Count, "One attachment is displayed");

            attachmentList.OpenContextMenuForRow(0);
            attachmentList.ContextMenu.Edit();

            var attachmentMaintenancePage = new AttachmentPageObj(driver);
            attachmentMaintenancePage.ActivityDate.GoToDate(-1);

            attachmentMaintenancePage.AttachmentName.Input.Clear();
            attachmentMaintenancePage.AttachmentName.Input.SendKeys($"testNewName{data.Irn}");

            attachmentMaintenancePage.Save();

            var popups = new CommonPopups(driver);
            Assert.True(popups.FlashAlertIsDisplayed());

            attachmentList.Close();

            driver.WaitForAngular();

            page.Grid.AttachmentIcons.First().Click();
            attachmentList = new AttachmentListObj(driver);

            var attachmentName = attachmentList.AttachmentsGrid.CellText(0, "Attachment Name");
            Assert.AreEqual($"testNewName{data.Irn}", attachmentName, "Attachment name is updated");

            attachmentList.Close();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void DeleteAttachment(BrowserType browserType)
        {
            var data = CreateAttachmentInDb();

            var user = new Users()
                       .WithLicense(LicensedModule.CasesAndNames)
                       .WithSubjectPermission(ApplicationSubject.Attachments)
                       .Create();

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/task-planner", user.Username, user.Password);

            var page = new TaskPlannerPageObject(driver);
            page.FilterButton.ClickWithTimeout();
            var page1 = new TaskPlannerSearchBuilderPageObject(driver);
            page1.IncludeDueDatesCheckbox.Click();
            page.Cases.CaseReference.SendKeys(data.Irn);
            page.AllNamesInBelongingToDropDown.Click();
            page.AdvancedSearchButton.ClickWithTimeout();

            Assert.AreEqual(2, page.Grid.Rows.Count);
            Assert.AreEqual(2, page.Grid.AttachmentIcons.Count);

            page.Grid.AttachmentIcons.First().Click();

            driver.WaitForAngular();

            var attachmentList = new AttachmentListObj(driver);
            Assert.AreEqual(1, attachmentList.AttachmentsGrid.Rows.Count, "One attachment is displayed");

            attachmentList.OpenContextMenuForRow(0);
            attachmentList.ContextMenu.Delete();

            var popups = new CommonPopups(driver);
            popups.ConfirmNgDeleteModal.Delete.ClickWithTimeout();
            driver.WaitForAngularWithTimeout();

            Assert.True(popups.FlashAlertIsDisplayed());

            attachmentList.Close();

            driver.WaitForAngular();

            Assert.AreEqual(1, page.Grid.AttachmentIcons.Count, "attachment is now removed");
        }
    }
}