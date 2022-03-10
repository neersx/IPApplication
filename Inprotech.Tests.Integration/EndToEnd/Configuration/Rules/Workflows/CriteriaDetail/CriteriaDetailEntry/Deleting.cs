using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Rules;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.Rules.Workflows.CriteriaDetail.CriteriaDetailEntry
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class Deleting : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEntriesAndPropogateDeleteToChildren(BrowserType browserType)
        {
            dynamic data;
            var entryDescription1 = "E2EEntry1" + RandomString.Next(6);
            var entryDescription2 = "E2EEntry2" + RandomString.Next(6);
            var entryDescription3 = "E2EEntry3" + RandomString.Next(6);
            var entryDescription4 = "E2EEntry4" + RandomString.Next(6);

            using (var setup = new CriteriaDetailDeletingDbSetup())
            {
                var parentCriteria = setup.AddCriteria("E2ECriteriaParent" + RandomString.Next(6));
                var parentEntry1 = setup.Insert(new DataEntryTask(parentCriteria, 1) {Description = entryDescription1});
                var parentEntry2 = setup.Insert(new DataEntryTask(parentCriteria, 2) {Description = entryDescription2});
                var parentEntry3 = setup.Insert(new DataEntryTask(parentCriteria, 3) {Description = entryDescription3});
                setup.AddAvailableEvent(parentEntry3);
                setup.Insert(new DataEntryTask(parentCriteria, 4) {Description = entryDescription4});

                var childCriteria1 = setup.AddChildCriteria(parentCriteria, "E2ECriteriaChild1" + RandomString.Next(6));
                setup.AddEntry(childCriteria1, entryDescription1, parentEntry1.Id);
                setup.AddEntry(childCriteria1, "#" + entryDescription2, parentEntry2.Id);
                setup.AddEntry(childCriteria1, entryDescription3 + "*");

                var childCriteria2 = setup.AddChildCriteria(parentCriteria, "E2ECriteriaChild2" + RandomString.Next(6));
                var childEntry3 = setup.AddEntry(childCriteria2, entryDescription3 + "*", parentEntry3.Id);
                setup.AddAvailableEvent(childEntry3, true);
                setup.AddAvailableEvent(childEntry3);

                data = new
                {
                    ParentCriteriaId = parentCriteria.Id,
                    ChildCriteria1Id = childCriteria1.Id,
                    ChildCriteria2Id = childCriteria2.Id
                };
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows/" + data.ParentCriteriaId);

            //Delete non-inherited
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                var rowCount = entriesTopic.Grid.Rows.Count;

                driver.WaitForAngular();
                entriesTopic.Grid.SelectIpCheckbox(3);

                entriesTopic.Grid.ActionMenu.OpenOrClose();
                entriesTopic.Grid.ActionMenu.Option("delete").ClickWithTimeout();

                popups.ConfirmDeleteModal.Delete().ClickWithTimeout();
                driver.WaitForAngularWithTimeout();
                Assert.AreEqual(rowCount - 1, entriesTopic.Grid.Rows.Count);
            });

            //Check entries from child criteria are deleted
            driver.Visit($"/#/configuration/rules/workflows/{data.ChildCriteria1Id}");
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                var rowCount = entriesTopic.Grid.Rows.Count;
                Assert.AreEqual(3, rowCount);
            });

            driver.Visit($"/#/configuration/rules/workflows/{data.ChildCriteria2Id}");
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                var rowCount = entriesTopic.Grid.Rows.Count;
                Assert.AreEqual(1, rowCount);
            });

            driver.Visit($"/#/configuration/rules/workflows/{data.ParentCriteriaId}", true);
            //Delete inherited
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;
                var rowCount = entriesTopic.Grid.Rows.Count;

                driver.WaitForAngular();
                entriesTopic.Grid.Rows[rowCount - 1].WithJs().ScrollIntoView();
                entriesTopic.Grid.SelectIpCheckbox(0);

                entriesTopic.Grid.ActionMenu.OpenOrClose();
                entriesTopic.Grid.ActionMenu.Option("delete").ClickWithTimeout();

                workflowDetails.InheritanceDeleteModal.Delete();

                Assert.AreNotEqual(entryDescription1, entriesTopic.Grid.CellText(0, 1));
                Assert.AreEqual(rowCount - 1, entriesTopic.Grid.Rows.Count);
            });

            //Delete multiple - one inherited, one partially inherited
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                driver.WaitForAngular();
                entriesTopic.Grid.SelectIpCheckbox(0);
                entriesTopic.Grid.SelectIpCheckbox(1);

                entriesTopic.Grid.ActionMenu.OpenOrClose();
                entriesTopic.Grid.ActionMenu.Option("delete").ClickWithTimeout();

                workflowDetails.InheritanceDeleteModal.Delete();
                Assert.AreEqual(0, entriesTopic.Grid.Rows.Count);
            });

            //Check entries from child criteria are deleted
            driver.Visit($"/#/configuration/rules/workflows/{data.ChildCriteria1Id}");
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                var rowCount = entriesTopic.Grid.Rows.Count;
                Assert.AreEqual(1, rowCount);
                Assert.IsTrue(entriesTopic.Grid.CellText(0, 2).Contains(entryDescription3));
            });

            driver.Visit($"/#/configuration/rules/workflows/{data.ChildCriteria2Id}");
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                var rowCount = entriesTopic.Grid.Rows.Count;
                Assert.AreEqual(0, rowCount);
            });
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void DeleteEntriesAndDoNotPropogateDeleteToChildren(BrowserType browserType)
        {
            dynamic data;
            var entryDescription1 = "E2EEntry1" + RandomString.Next(6);
            var entryDescription2 = "E2EEntry2" + RandomString.Next(6);
            var entryDescription3 = "E2EEntry3" + RandomString.Next(6);
            var entryDescription4 = "E2EEntry4" + RandomString.Next(6);

            using (var setup = new CriteriaDetailDeletingDbSetup())
            {
                var parentCriteria = setup.AddCriteria("E2ECriteriaParent" + RandomString.Next(6));
                var parentEntry1 = setup.Insert<DataEntryTask>(new DataEntryTask(parentCriteria, 1) {Description = entryDescription1});
                var parentEntry2 = setup.Insert<DataEntryTask>(new DataEntryTask(parentCriteria, 2) {Description = entryDescription2});
                var parentEntry3 = setup.Insert<DataEntryTask>(new DataEntryTask(parentCriteria, 3) {Description = entryDescription3});
                setup.Insert<DataEntryTask>(new DataEntryTask(parentCriteria, 4) {Description = entryDescription4});

                var childCriteria1 = setup.AddChildCriteria(parentCriteria, "E2ECriteriaChild1" + RandomString.Next(6));
                setup.AddEntry(childCriteria1, entryDescription1, parentEntry1.Id);
                setup.AddEntry(childCriteria1, "#" + entryDescription2, parentEntry2.Id);
                setup.AddEntry(childCriteria1, entryDescription3 + "*");

                var childCriteria2 = setup.AddChildCriteria(parentCriteria, "E2ECriteriaChild1" + RandomString.Next(6));
                setup.AddEntry(childCriteria2, entryDescription3 + "*", parentEntry3.Id);

                data = new
                {
                    ParentCriteriaId = parentCriteria.Id,
                    ChildCriteria1Id = childCriteria1.Id,
                    ChildCriteria2Id = childCriteria2.Id
                };
            }

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/rules/workflows/" + data.ParentCriteriaId);

            //Check entries from child criteria are deleted
            driver.Visit($"/#/configuration/rules/workflows/{data.ChildCriteria1Id}");
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                var rowCount = entriesTopic.Grid.Rows.Count;
                Assert.AreEqual(3, rowCount);
            });

            driver.Visit($"/#/configuration/rules/workflows/{data.ChildCriteria2Id}");
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                var rowCount = entriesTopic.Grid.Rows.Count;
                Assert.AreEqual(1, rowCount);
            });

            driver.Visit($"/#/configuration/rules/workflows/{data.ParentCriteriaId}");

            //Delete multiple entries
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                driver.WaitForAngular();
                entriesTopic.Grid.SelectIpCheckbox(0);
                entriesTopic.Grid.SelectIpCheckbox(1);
                entriesTopic.Grid.SelectIpCheckbox(2);

                entriesTopic.Grid.ActionMenu.OpenOrClose();
                entriesTopic.Grid.ActionMenu.Option("delete").ClickWithTimeout();

                workflowDetails.InheritanceDeleteModal.WithoutApplyToChildren();
                workflowDetails.InheritanceDeleteModal.Delete();
                Assert.AreEqual(1, entriesTopic.Grid.Rows.Count);
            });

            //Check entries from child criteria are not deleted
            driver.Visit($"/#/configuration/rules/workflows/{data.ChildCriteria1Id}");
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                var rowCount = entriesTopic.Grid.Rows.Count;
                Assert.AreEqual(3, rowCount);
            });

            driver.Visit($"/#/configuration/rules/workflows/{data.ChildCriteria2Id}");
            driver.With<CriteriaDetailPage>((workflowDetails, popups) =>
            {
                var entriesTopic = workflowDetails.EntriesTopic;

                var rowCount = entriesTopic.Grid.Rows.Count;
                Assert.AreEqual(1, rowCount);
            });
        }
    }
}