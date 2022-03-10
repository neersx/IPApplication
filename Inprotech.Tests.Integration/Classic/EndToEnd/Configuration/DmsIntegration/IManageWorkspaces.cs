using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.Dms;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Documents;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.Configuration.DmsIntegration
{
    [TestFixture]
    [Category(Categories.E2E)]
    [TestFrom(DbCompatLevel.Release15)]
    public class IManageWorkSpaces : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            using (var db = new DbSetup())
            {
                var siteControls = db.DbContext.Set<SiteControl>().Where(_ => _siteControlsKeys.Contains(_.ControlId)).ToArray();
                _originalCaseSearchSiteControl = siteControls.Single(_ => _.ControlId == SiteControls.DMSCaseSearchDocItem).StringValue;
                _originalNameSearchSiteControl = siteControls.Single(_ => _.ControlId == SiteControls.DMSNameSearchDocItem).StringValue;
            }
        }

        [TearDown]
        public void Cleanup()
        {
            using (var db = new DbSetup())
            {
                var siteControls = db.DbContext.Set<SiteControl>().Where(_ => _siteControlsKeys.Contains(_.ControlId)).ToArray();

                var caseSearch = siteControls.Single(_ => _.ControlId == SiteControls.DMSCaseSearchDocItem);
                if (_originalCaseSearchSiteControl != caseSearch.StringValue) caseSearch.StringValue = _originalCaseSearchSiteControl;

                var nameSearch = siteControls.Single(_ => _.ControlId == SiteControls.DMSNameSearchDocItem);
                if (_originalNameSearchSiteControl != nameSearch.StringValue) nameSearch.StringValue = _originalNameSearchSiteControl;

                db.DbContext.SaveChanges();
            }
        }

        string _originalCaseSearchSiteControl;
        string _originalNameSearchSiteControl;

        readonly string[] _siteControlsKeys =
        {
            SiteControls.DMSCaseSearchDocItem,
            SiteControls.DMSNameSearchDocItem
        };

        [TestCase(BrowserType.Chrome)]
        public void Workspace(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var popup = new CommonPopups(driver);
            NameType nameType1 = null;
            NameType nameType2 = null;
            DocItem caseDocItem = null;
            DocItem nametypeDocItem = null;

            new DocumentManagementDbSetup().Setup(dmsSettings: new DocumentManagementDbSetup.DmsSettingsModel()
            {
                SubType = "work"
            });

            using (var x = new DbSetup())
            {
                nameType1 = x.DbContext.Set<NameType>().First();
                nameType2 = x.DbContext.Set<NameType>().OrderByDescending(_ => _.NameTypeCode).First();

                caseDocItem = x.DbContext.Set<DocItem>().First();
                nametypeDocItem = x.DbContext.Set<DocItem>().OrderByDescending(_ => _.Id).First();

                var caseSearch = x.DbContext.Set<SiteControl>().First(_ => _.ControlId == SiteControls.DMSCaseSearchDocItem);
                caseSearch.StringValue = caseDocItem.Name;

                x.DbContext.SaveChanges();
            }

            SignIn(driver, "/#/configuration/dmsintegration");

            void Save(DmsIntegrationPage page)
            {
                Assert.False(page.IsSaveDisabled);
                Assert.True(page.RevertButton.Enabled);

                page.Save();
                Assert.NotNull(popup.FlashAlertIsDisplayed());
            }

            driver.With<DmsIntegrationPage>(page =>
            {
                var topic = new DmsIntegrationPage.WorkSpaceTopic(driver);

                Assert.AreEqual("work", topic.Subtype.Input.Value());

                topic.SearchField.Input.SelectByIndex(0);
                topic.SubClass.Input.SendKeys("Subclass");
                topic.Subtype.Input.Clear();
                topic.Subtype.Input.SendKeys("Subtype");

                Save(page);

                Assert.AreEqual("Subclass", topic.SubClass.Input.Value());
                Assert.AreEqual("Subtype", topic.Subtype.Input.Value());

                topic.NameTypesGrid.Add();
                var editableRow = new DmsIntegrationPage.WorkSpaceTopic.EditableNameRow(driver, topic.NameTypesGrid, 0);
                editableRow.NameType.EnterAndSelect(nameType1.Name);
                editableRow.SubClass.Input.SendKeys("Subclass");

                Save(page);

                Assert.AreEqual("Subclass", topic.SubClass.Input.Value());
                Assert.AreEqual("Subtype", topic.Subtype.Input.Value());
                Assert.AreEqual(nameType1.Name, topic.NameTypesGrid.CellText(0, 1));
                Assert.AreEqual("Subclass", topic.NameTypesGrid.CellText(0, 2));

                topic.NameTypesGrid.Add();
                var editableRow2 = new DmsIntegrationPage.WorkSpaceTopic.EditableNameRow(driver, topic.NameTypesGrid, 1);
                editableRow2.NameType.EnterAndSelect(nameType1.Name);
                editableRow2.SubClass.Input.SendKeys("Subclass");

                Assert.True(page.IsSaveDisabled, "Duplicates Not Valid");
                editableRow2.NameType.Clear();
                editableRow2.NameType.EnterAndSelect(nameType2.Name);
                Save(page);
            });

            driver.With<DmsIntegrationPage>(page =>
            {
                var topic = new DmsIntegrationPage.DataItemTopic(driver);
                Assert.AreEqual(caseDocItem.Name, topic.CaseSearch.InputValue);

                topic.NameSearch.EnterAndSelect(nametypeDocItem.Name);
                Save(page);
                Assert.AreEqual(caseDocItem.Name, topic.CaseSearch.InputValue);
                Assert.AreEqual(nametypeDocItem.Name, topic.NameSearch.InputValue);
            });
        }
    }
}