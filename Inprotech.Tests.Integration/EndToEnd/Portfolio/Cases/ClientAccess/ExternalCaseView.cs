using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.PageObjects.Modals;
using Inprotech.Tests.Integration.Utils;
using Inprotech.Web.Cases.Details;
using Inprotech.Web.Cases.Details.DesignatedJurisdiction;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using NUnit.Framework;
using OpenQA.Selenium;
using Protractor;
using RCIndex = Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.CaseRelatedCasesTopic.ExternalUser;
using DJIndex = Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.DesignatedJurisdictionTopic.ExternalUser;
using CNIndex = Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.CaseNameTopic.ExternalUser;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.ClientAccess
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ExternalCaseView : IntegrationTest
    {
        [TearDown]
        public void CleanupModifiedData()
        {
            SiteControlRestore.ToDefault(SiteControls.CriticalDates_External, SiteControls.EnableRichTextFormatting, SiteControls.KEEPSPECIHISTORY, SiteControls.HomeNameNo, SiteControls.CPA_UseClientCaseCode);
            DbSetup.Do(x =>
                       {
                           var forbiddenNameType = x.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Owner);
                           var clientNameTypes = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.ClientNameTypesShown).StringValue.Split(',');

                           x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.ClientNameTypesShown).StringValue
                               = clientNameTypes.Contains(forbiddenNameType.NameTypeCode)
                                   ? string.Join(",", clientNameTypes)
                                   : string.Concat(string.Join(",", clientNameTypes), ",", forbiddenNameType.NameTypeCode);
                          
                           var nameTypes = x.DbContext.Set<NameType>().Where(_ => _.NameTypeCode == KnownNameTypes.Debtor || _.NameTypeCode == KnownNameTypes.RenewalsDebtor)
                                            .ToDictionary(k => k.NameTypeCode, v => v);

                           if (_debtorColumnFlags != nameTypes[KnownNameTypes.Debtor].ColumnFlag)
                           {
                               nameTypes[KnownNameTypes.Debtor].ColumnFlag = _debtorColumnFlags;
                           }

                           if (_renewalDebtorColumnFlags != nameTypes[KnownNameTypes.RenewalsDebtor].ColumnFlag)
                           {
                               nameTypes[KnownNameTypes.RenewalsDebtor].ColumnFlag = _renewalDebtorColumnFlags;
                           }

                           x.DbContext.SaveChanges();
                       });
        }
        short? _debtorColumnFlags;
        short? _renewalDebtorColumnFlags;

        const int CriticalDatesDateColumn = 1;
        const int CriticalDatesEventDescriptionColumn = 2;
        const int CriticalDatesOfficialNumberColumn = 3;

        const int TextTypeColumn = 0;
        const int TextNotesColumn = 2;
        const int TextLanguageColumn = 3;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CaseViewShowWebLinks(BrowserType browserType)
        {
            var user = new Users();
            var externalUser = user.CreateExternalUser();
            var setup = new CaseDetailsDbSetup();
            var data = setup.ReadOnlyDataSetup(true);
            user.EnsureAccessToCase(data.Trademark.Case);

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{data.Trademark.Case.Id}", externalUser.Username, externalUser.Password);

            var linkButton = driver.FindElements(By.CssSelector("after-title button")).SingleOrDefault();
            Assert.Null(linkButton, $"Expect link button to hide without application task");

            var summary = new SummaryTopic(driver);
            Assert.True(summary.Field("clientMainContact.name", true).Displayed, "External User field Your Contact is displayed");
            Assert.True(summary.Field("ourContact.name", true).Displayed, "External User field Our Contact is displayed");

            Assert.Null(summary.LinkField("clientMainContact.name", true), "External User field Your Contact is displayed without link");
            Assert.Null(summary.LinkField("ourContact.name", true), "External User field Our Contact is displayed without link");

        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CaseViewReadOnlyTopics(BrowserType browserType)
        {
            var user = new Users();
            var setup = new CaseDetailsDbSetup();
            var data = setup.ReadOnlyDataSetup(true);

            var externalUser = user.WithPermission(ApplicationTask.ShowLinkstoWeb).CreateExternalUser();

            user.EnsureAccessToCase(data.Trademark.Case);
            user.EnsureAccessToCase(data.Patent.Case);
            user.EnsureAccessToCase(data.Patent.DesignatedJurisdiction.RegisterForAccess);

            DbSetup.Do(x =>
            {
                var nameTypes = x.DbContext.Set<NameType>().Where(_ => _.NameTypeCode == KnownNameTypes.Debtor || _.NameTypeCode == KnownNameTypes.RenewalsDebtor)
                                 .ToDictionary(k => k.NameTypeCode, v => v);

                _debtorColumnFlags = nameTypes[KnownNameTypes.Debtor].ColumnFlag;
                _renewalDebtorColumnFlags = nameTypes[KnownNameTypes.RenewalsDebtor].ColumnFlag;

                if (nameTypes[KnownNameTypes.Debtor].ColumnFlag == null)
                    nameTypes[KnownNameTypes.Debtor].ColumnFlag = 0;

                if (nameTypes[KnownNameTypes.RenewalsDebtor].ColumnFlag == null)
                    nameTypes[KnownNameTypes.RenewalsDebtor].ColumnFlag = 0;

                nameTypes[KnownNameTypes.Debtor].ColumnFlag |= KnownNameTypeColumnFlags.DisplayAddress | KnownNameTypeColumnFlags.DisplayAttention | KnownNameTypeColumnFlags.DisplayRemarks;
                nameTypes[KnownNameTypes.RenewalsDebtor].ColumnFlag |= KnownNameTypeColumnFlags.DisplayAddress | KnownNameTypeColumnFlags.DisplayAttention;

                x.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{data.Trademark.Case.Id}", externalUser.Username, externalUser.Password);
            
            ConfirmNoTasksAreShowing(driver);

            TestPendingTrademarkCaseHeader(driver, data);

            TestPendingTrademarkCaseNames(driver, data.Trademark.Case, data.Trademark.CaseNames.Others);

            TestPendingTrademarkCriticalDates(driver, data.Trademark.CriticalDates);

            TestPendingTrademarkEvents(driver);

            TestPendingTrademarkRelatedCases(driver, data.Trademark.RelatedCases);

            TestOfficialNumbers(driver, data.Trademark.OfficialNumbers.IpOffice, data.Trademark.OfficialNumbers.Other);

            TestPendingTrademarkTexts(driver, data.Trademark.CaseTexts);

            driver.Visit($"{Env.RootUrl}/#/caseview/{data.Patent.Case.Id}");
            driver.WaitForAngularWithTimeout();

            TestDeadPatentCaseHeader(driver, data);

            TestDeadPatentCriticalDates(driver, data.Patent.CriticalDates);

            TestDeadPatentRelatedCases(driver, data.Patent.RelatedCases);

            TestDeadPatentTexts(driver, data.Patent.CaseTexts);

            TestDeadPatentDesignatedJurisdiction(driver, data.Patent.DesignatedJurisdiction);
        }

        static void ConfirmNoTasksAreShowing(NgWebDriver driver)
        {
            var leftMenuTabs = driver.FindElements(By.CssSelector(".topic-menu ul.nav-tabs li"));
            Assert.AreEqual(1, leftMenuTabs.Count);
        }

        static void TestPendingTrademarkCaseNames(NgWebDriver driver, Case @case, dynamic names)
        {
            var caseNameTopic = new CaseNameTopic(driver);
            Assert.True(caseNameTopic.CaseViewNameGrid.Grid.Displayed, "Names section is showing");
            caseNameTopic.CaseViewNameGrid.Grid.WithJs().ScrollIntoView();
            
            var detailsRowCreated = 0;

            void TestCaseNameAndDetails(dynamic row, int rowIndex)
            {
                Assert.AreEqual(row.Type, caseNameTopic.CaseViewNameGrid.MasterCellText(rowIndex, (int) CNIndex.NameType), $"Case name Section: Row {rowIndex}: Should be name type column");
                
                var nameLink = caseNameTopic.CaseViewNameGrid.MasterCell(rowIndex, (int) CNIndex.Name).FindElements(By.CssSelector("ip-ie-only-url a")).SingleOrDefault();
                Assert.NotNull(nameLink, $"Case name Section: Row {rowIndex}: Should be a hyperlink name column");
                Assert.AreEqual(row.FormattedName, nameLink.Text, $"Case name Section: Row {rowIndex}: Should be name column");

                var attentionNameLink = caseNameTopic.CaseViewNameGrid.MasterCell(rowIndex, (int) CNIndex.AttentionName).FindElements(By.CssSelector("ip-ie-only-url a")).SingleOrDefault();
                Assert.NotNull(attentionNameLink, $"Case name Section: Row {rowIndex}: Should be a hyperlink attention name column");
                Assert.AreEqual(row.FormattedAttentionName, attentionNameLink.Text, $"Case name Section: Row {rowIndex}: Should be attention name column");
                
                var nameIsInheritedIcon = caseNameTopic.GetInheritanceIcon(rowIndex, (int) CNIndex.Name);
                Assert.Null(nameIsInheritedIcon, $"Case name Section: Row {rowIndex}: Should not indicate inheritance for the case name. It means nothing to the external user");
                
                var attentionNameIsDerivedIcon = caseNameTopic.GetInheritanceIcon(rowIndex, (int) CNIndex.AttentionName);
                Assert.Null(attentionNameIsDerivedIcon, $"Case name Section: Row {rowIndex}: Should not indicate inheritance icon for attention name. It means nothing to the external user");

                caseNameTopic.CaseViewNameGrid.ToggleDetailsRow(rowIndex);
                var index = detailsRowCreated++;
                var ipTextArea = caseNameTopic.CaseViewNameGrid.DetailRows[index].FindElement(By.TagName("ip-text-area"));
                var addressTextArea = ipTextArea.FindElement(By.TagName("textarea"));
                Assert.AreEqual(row.FormattedAddress, addressTextArea.Text, $"Case name Section: Row {rowIndex}: Should display address");
                Assert.AreEqual(row.IsAddressInherited, ipTextArea.WithJs().HasClass("input-inherited"), $"Case name Section: Row {rowIndex}: Should display address as inherited accordingly");
                var detailSection = new CaseNameTopic.DetailSection(driver, caseNameTopic.CaseViewNameGrid, index);

                Assert.AreEqual(row.Email, detailSection.Email, $"Case name Section: Detail Row {index}: Should have same email");
                Assert.AreEqual(row.Phone, detailSection.Phone, $"Case name Section: Detail Row {index}: Should have same phone");
                Assert.True(string.IsNullOrEmpty(detailSection.Comments), $"Case name Section: Detail Row {index}: Should never have remarks");

                caseNameTopic.CaseViewNameGrid.ToggleDetailsRow(rowIndex);
            }

            TestCaseNameAndDetails(names.DebtorRow, 1);
            TestCaseNameAndDetails(names.RenewalDebtorRow, 2);
        }

        static void TestDeadPatentCaseHeader(NgWebDriver driver, dynamic data)
        {
            var summary = new SummaryTopic(driver);

            var irn = summary.FieldValue("irn");
            var title = summary.FieldValue("title");

            var patentCaseView = new NewCaseViewDetail(driver);
            var patentPropertyStatusClass = patentCaseView.PropertyStatusIcon.GetAttribute("class");
            var patentIconClass = patentCaseView.PropertyTypeIcon.GetAttribute("class");

            Assert.True(patentPropertyStatusClass.Contains("dead"), $"Expect property type icon to have correct style but has these classes instead '{patentPropertyStatusClass}'");
            Assert.True(patentIconClass.Contains("cpa-icon-lightbulb-o"), $"Expect correct property type icon to be displayed but has these classes instead '{patentIconClass}'");

            Assert.AreEqual(data.Patent.Case.Irn, irn, $"Expected correct IRN '{data.Patent.Case.Irn}' to be displayed");
            Assert.AreEqual(data.Patent.Case.Title, title, $"Expected correct Title '{data.Patent.Case.Title}' to be displayed");

            Assert.AreEqual(data.Patent.PatentLabel, summary.FieldLabel("irn"), "Expected customised label to be displayed");
            Assert.False(summary.Field("typeOfMark").Displayed);
            Assert.False(summary.Field("classes").Displayed);
            Assert.False(summary.Field("numberInSeries").Displayed);

            Assert.True(summary.Field("yourReference", true).Displayed, "External User field Your Reference is displayed");
            Assert.True(summary.Field("clientMainContact.name", true).Displayed, "External User field Your Contact is displayed");
            Assert.True(summary.Field("ourContact.name", true).Displayed, "External User field Our Contact is displayed");

            Assert.Throws<NoSuchElementException>(() => { driver.FindElement(By.TagName("ip-case-image")); }, "Case Image placeholder should not be rendered when no image available");
        }

        static void TestPendingTrademarkCaseHeader(NgWebDriver driver, dynamic data)
        {
            var summary = new SummaryTopic(driver);
            var irn = summary.FieldValue("irn");
            var title = summary.FieldValue("title");

            var trademarkCaseView = new NewCaseViewDetail(driver);

            var trademarkPropertyStatusClass = trademarkCaseView.PropertyStatusIcon.GetAttribute("class");
            var trademarkIconClass = trademarkCaseView.PropertyTypeIcon.GetAttribute("class");

            Assert.AreEqual(data.Trademark.Case.Irn, irn, $"Expected correct IRN '{data.Trademark.Case.Irn}' to be displayed");
            Assert.AreEqual(data.Trademark.Case.Title, title, $"Expected correct Title '{data.Trademark.Case.Title}' to be displayed");
            Assert.AreEqual(data.Trademark.TrademarkLabel, summary.FieldLabel("irn"), "Expected customised label to be displayed");
            Assert.True(summary.Field("typeOfMark").Displayed);
            Assert.True(summary.Field("classes").Displayed);
            Assert.True(summary.Field("numberInSeries").Displayed);
            Assert.True(summary.Field("yourReference", true).Displayed, "External User field Your Reference is displayed");
            Assert.True(summary.Field("clientMainContact.name", true).Displayed, "External User field Your Contact is displayed");
            Assert.True(summary.Field("ourContact.name", true).Displayed, "External User field Our Contact is displayed");

            Assert.True(summary.LinkField("clientMainContact.name", true).Displayed, "External User field Your Contact is displayed with link");
            Assert.True(summary.LinkField("ourContact.name", true).Displayed, "External User field Our Contact is displayed with link");

            Assert.True(trademarkPropertyStatusClass.Contains("pending"), $"Expect property type icon to have correct style but has these classes instead '{trademarkPropertyStatusClass}'");
            Assert.True(trademarkIconClass.Contains("cpa-icon-trademark"), $"Expect correct property type icon to be displayed but has these classes instead '{trademarkIconClass}'");
            
            Assert.True(summary.Field("ourContact.name", true).FindElement(By.CssSelector(".cpa-icon-envelope")).Displayed, "External User field Our Contact is displayed with an email icon");

            var image = driver.FindElement(By.TagName("ip-case-image")).FindElement(By.ClassName("case-image-thumbnail"));
            image.ClickWithTimeout();
            var imagePopup = new CommonPopups(driver);
            Assert.True(imagePopup.FindElement(By.TagName("ip-case-image")).Displayed, "Expected image dialog to be displayed");
            imagePopup.FindElement(By.ClassName("btn-discard")).ClickWithTimeout();
        }

        void TestPendingTrademarkCriticalDates(NgWebDriver driver, dynamic criticalDates)
        {
            var caseCriticalDates = new CaseCriticalDatesTopic(driver);
            Assert.True(caseCriticalDates.CriticalDatesGrid.Grid.Displayed, "Critical Dates Section is showing");

            caseCriticalDates.CriticalDatesGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(1, caseCriticalDates.CriticalDatesGrid.Rows.Count, "Critical Dates Section: should show 1 row due to all other events not having required client importance level");

            Assert.AreEqual(criticalDates.Row1.PriorityDate, caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesDateColumn), "Critical Dates Section: Row 1: Should be priority date");
            Assert.AreEqual(criticalDates.Row1.PriorityNumber, caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesOfficialNumberColumn), "Critical Dates Section: Row 1: Should be priority number");
            Assert.Throws<NoSuchElementException>(() => caseCriticalDates.CriticalDatesGrid.Cell(0, CriticalDatesOfficialNumberColumn).FindElement(By.TagName("a")), "hyperlink to innography is not available to external users");
            Assert.AreEqual($"{criticalDates.Row1.EventDescription} ({criticalDates.Row1.PriorityCountry})", caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesEventDescriptionColumn), "Critical Dates Section: Row 1: Should be priority event with country.");
        }

        void TestDeadPatentCriticalDates(NgWebDriver driver, dynamic criticalDates)
        {
            var caseCriticalDates = new CaseCriticalDatesTopic(driver);
            Assert.True(caseCriticalDates.CriticalDatesGrid.Grid.Displayed, "Critical Dates Section is showing");

            caseCriticalDates.CriticalDatesGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(1, caseCriticalDates.CriticalDatesGrid.Rows.Count, "Critical Dates Section: should show 1 row due to all other events not having required client importance level");

            Assert.AreEqual(criticalDates.Row1.PriorityDate, caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesDateColumn), "Critical Dates Section: Row 1: Should be priority date");
            Assert.AreEqual(criticalDates.Row1.PriorityNumber, caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesOfficialNumberColumn), "Critical Dates Section: Row 1: Should be priority number");
            Assert.Throws<NoSuchElementException>(() => caseCriticalDates.CriticalDatesGrid.Cell(0, CriticalDatesOfficialNumberColumn).FindElement(By.TagName("a")), "hyperlink to innography is not available to external users.");
            Assert.AreEqual($"{criticalDates.Row1.EventDescription} ({criticalDates.Row1.PriorityCountry})", caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesEventDescriptionColumn), "Critical Dates Section: Row 1: Should be priority event with country.");
        }

        void TestPendingTrademarkTexts(NgWebDriver driver, dynamic caseTexts)
        {
            var combinedTextTopic = new CaseTextTopic(driver, caseTexts.CombinedText.TopicContextKey);

            Assert.True(combinedTextTopic.CaseTextGrid.Grid.Displayed, "Combined Text Section is showing");
            combinedTextTopic.CaseTextGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(2, combinedTextTopic.CaseTextGrid.Rows.Count, "Combined Section: should show 2 rows");

            Assert.AreEqual(caseTexts.CombinedText.Row1.Type, combinedTextTopic.CaseTextGrid.CellText(0, TextTypeColumn), "Case Text Section: Row 1: Should be text type");
            Assert.AreEqual(caseTexts.CombinedText.Row1.Notes, combinedTextTopic.CaseTextGrid.CellText(0, TextNotesColumn), "Case Text Section: Row 1: Should be note column");

            Assert.AreEqual(caseTexts.CombinedText.Row2.Type, combinedTextTopic.CaseTextGrid.CellText(1, TextTypeColumn), "Case Text Section: Row 2: Should be text type");
            Assert.AreEqual(caseTexts.CombinedText.Row2.Notes, combinedTextTopic.CaseTextGrid.CellText(1, TextNotesColumn), "Case Text Section: Row 2: Should be note column");

            var descriptionTextTopic = new CaseTextTopic(driver, caseTexts.FilteredText.TopicContextKey);

            Assert.True(descriptionTextTopic.CaseTextGrid.Grid.Displayed, "Descriptions Section is showing");
            descriptionTextTopic.CaseTextGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(1, descriptionTextTopic.CaseTextGrid.Rows.Count, "Descriptions Section: should show 1 rows");

            Assert.AreEqual(caseTexts.FilteredText.Row1.Type, descriptionTextTopic.CaseTextGrid.CellText(0, TextTypeColumn), "Case Text Section: Row 1: Should be text type");
            Assert.AreEqual(caseTexts.FilteredText.Row1.Notes, descriptionTextTopic.CaseTextGrid.CellText(0, TextNotesColumn), "Case Text Section: Row 1: Should be note column");
        }

        void TestDeadPatentTexts(NgWebDriver driver, dynamic caseTexts)
        {
            var caseTextTopic = new CaseTextTopic(driver);

            Assert.True(caseTextTopic.CaseTextGrid.Grid.Displayed, "Case Text Section is showing");

            caseTextTopic.CaseTextGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(3, caseTextTopic.CaseTextGrid.Rows.Count, "Case Text Section: should show 3 rows");

            Assert.AreEqual(caseTexts.Row1.Type, caseTextTopic.CaseTextGrid.CellText(0, TextTypeColumn), "Case Text Section: Row 2: Should be text type");
            Assert.AreEqual(caseTexts.Row1.Notes, caseTextTopic.CaseTextGrid.CellText(0, TextNotesColumn), "Case Text Section: Row 2: Should be note column");

            Assert.AreEqual(caseTexts.Row2.Type, caseTextTopic.CaseTextGrid.CellText(1, TextTypeColumn), "Case Text Section: Row 3: Should be text type");
            Assert.AreEqual(caseTexts.Row2.Notes, caseTextTopic.CaseTextGrid.CellText(1, TextNotesColumn), "Case Text Section: Row 3: Should be note column");
            Assert.AreEqual(caseTexts.Row2.Language, caseTextTopic.CaseTextGrid.CellText(1, TextLanguageColumn), "Case Text Section: Row 3: Should be language column");

            Assert.AreEqual(caseTexts.Row3.Type, caseTextTopic.CaseTextGrid.CellText(2, TextTypeColumn), "Case Text Section: Row 4: Should be text type");
            Assert.AreEqual(caseTexts.Row3.Notes, caseTextTopic.CaseTextGrid.CellText(2, TextNotesColumn), "Case Text Section: Row 4: Should be note column");
            Assert.AreEqual(caseTexts.Row3.Language, caseTextTopic.CaseTextGrid.CellText(2, TextLanguageColumn), "Case Text Section: Row 4: Should be language column");
        }

        void TestPendingTrademarkEvents(NgWebDriver driver)
        {
            var caseViewEvents = new CaseEventsTopic(driver);

            Assert.True(caseViewEvents.OccurredDatesGrid.Grid.Displayed, "Events Occurred Dates Section is showing");
            caseViewEvents.OccurredDatesGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(0, caseViewEvents.OccurredDatesGrid.Rows.Count, "Event Occurred Dates Section: should not have any rows minumum importance at critical");

            caseViewEvents.DueDatesGrid.Grid.WithJs().ScrollIntoView();
            Assert.True(caseViewEvents.DueDatesGrid.Grid.Displayed, "Events Due Dates Section is showing");
            Assert.AreEqual(0, caseViewEvents.DueDatesGrid.Rows.Count, "Event Due Dates Section: should not have any rows due to minumum importance at critical");
        }

        void TestPendingTrademarkRelatedCases(NgWebDriver driver, dynamic relatedCases)
        {
            var caseRelatedCases = new CaseRelatedCasesTopic(driver);
            caseRelatedCases.RelatedCasesGrid.Grid.WithJs().ScrollIntoView();

            Assert.True(caseRelatedCases.RelatedCasesGrid.Grid.Displayed, "Related Case Section is showing");
            Assert.AreEqual(1, caseRelatedCases.RelatedCasesGrid.Rows.Count, "Related Case: Should show 1 related case from convention claimed from.");
            Assert.AreEqual(relatedCases.Row1.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(0, (int)RCIndex.Relationship).Text, "Related Case: Should show priority relationship");
            Assert.AreEqual(relatedCases.Row1.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(0, (int)RCIndex.InternalRef).Text, "Related Case: Should not have a case ref");
            Assert.AreEqual(relatedCases.Row1.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(0, (int)RCIndex.OfficialNumber).Text, "Related Case: Should show priority number");
            Assert.AreEqual(relatedCases.Row1.Jurisdiction, caseRelatedCases.RelatedCasesGrid.Cell(0, (int)RCIndex.Jurisdiction).Text, "Related Case: Should show priority jurisdiction");
            Assert.AreEqual(relatedCases.Row1.Date, caseRelatedCases.RelatedCasesGrid.Cell(0, (int)RCIndex.EventDate).Text, "Related Case: Should show priority date");
        }

        void TestDeadPatentRelatedCases(NgWebDriver driver, dynamic relatedCases)
        {
            var caseRelatedCases = new CaseRelatedCasesTopic(driver);
            caseRelatedCases.RelatedCasesGrid.Grid.WithJs().ScrollIntoView();

            Assert.True(caseRelatedCases.RelatedCasesGrid.Grid.Displayed, "Related Case Section is showing");

            Assert.AreEqual(3, caseRelatedCases.RelatedCasesGrid.Rows.Count, "Related Case Section should have 3 rows, as two of the rows are not accessible to the external user");

            Assert.AreEqual(relatedCases.Row1.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(0, (int)RCIndex.Relationship).Text, "Related Case: Should show priority relationship");
            Assert.AreEqual(relatedCases.Row1.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(0, (int)RCIndex.InternalRef).Text, "Related Case: Should not have a case ref");
            Assert.AreEqual(relatedCases.Row1.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(0, (int)RCIndex.OfficialNumber).Text, "Related Case: Should show priority number");
            Assert.AreEqual(relatedCases.Row1.Jurisdiction, caseRelatedCases.RelatedCasesGrid.Cell(0, (int)RCIndex.Jurisdiction).Text, "Related Case: Should show priority jurisdiction");
            Assert.AreEqual(relatedCases.Row1.Date, caseRelatedCases.RelatedCasesGrid.Cell(0, (int)RCIndex.EventDate).Text, "Related Case: Should show priority date");

            Assert.NotNull(caseRelatedCases.RelatedCasesGrid.Cell(1, (int)RCIndex.Direction).FindElement(By.CssSelector(".cpa-icon-arrow-down")), "Related Case: C2 - Should show arrow pointing down");
            Assert.AreEqual(relatedCases.Row4.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(1, (int)RCIndex.Relationship).Text, "Related Case: C2 - Should show second point to child relationship");
            Assert.AreEqual(relatedCases.Row4.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(1, (int)RCIndex.InternalRef).Text, "Related Case: C2 - Should not have a case ref as this is an external case");
            Assert.AreEqual(relatedCases.Row4.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(1, (int)RCIndex.OfficialNumber).Text, "Related Case: C2 - Should have end user entered number");
            Assert.AreEqual(relatedCases.Row4.Jurisdiction, caseRelatedCases.RelatedCasesGrid.Cell(1, (int)RCIndex.Jurisdiction).Text, "Related Case: C2 - Should have end user entered jurisdiction");
            Assert.AreEqual(relatedCases.Row4.Date, caseRelatedCases.RelatedCasesGrid.Cell(1, (int)RCIndex.EventDate).Text, "Related Case: C2 - Should have priority date from relationship");
            Assert.AreEqual(relatedCases.Row4.Classes, caseRelatedCases.RelatedCasesGrid.Cell(1, (int)RCIndex.Classes).Text, "Related Case: C2 - Should have classes from relationship");

            Assert.NotNull(caseRelatedCases.RelatedCasesGrid.Cell(2, (int)RCIndex.Direction).FindElement(By.CssSelector(".cpa-icon-arrow-up")), "Related Case: P2 - Should show arrow pointing up");
            Assert.AreEqual(relatedCases.Row5.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(2, (int)RCIndex.Relationship).Text, "Related Case: P2 - Should show second point to paretn relationship");
            Assert.AreEqual(relatedCases.Row5.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(2, (int)RCIndex.InternalRef).Text, "Related Case: P2 - Should have a case ref from the first case");
            Assert.AreEqual(relatedCases.Row5.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(2, (int)RCIndex.OfficialNumber).Text, "Related Case: P2 - Should not have a number from the first case");
            Assert.AreEqual(relatedCases.Row5.Jurisdiction, caseRelatedCases.RelatedCasesGrid.Cell(2, (int)RCIndex.Jurisdiction).Text, "Related Case: P2 - Should have a jurisdiction from the first case");
            Assert.AreEqual(relatedCases.Row5.Date, caseRelatedCases.RelatedCasesGrid.Cell(2, (int)RCIndex.EventDate).Text, "Related Case: P2 - Should have an event date from the first case");

            caseRelatedCases.RelatedCasesGrid.ToggleDetailsRow(1);
            var detailsC2 = new RelatedCaseOtherDetail(driver, caseRelatedCases.RelatedCasesGrid.DetailRows[0]);
            Assert.AreEqual(relatedCases.Row4.Title, detailsC2.Title, "Related Case: C2 - Should have title from relationship");
            caseRelatedCases.RelatedCasesGrid.ToggleDetailsRow(1); //collapse

            caseRelatedCases.RelatedCasesGrid.ToggleDetailsRow(2);
            var detailsP2 = new RelatedCaseOtherDetail(driver, caseRelatedCases.RelatedCasesGrid.DetailRows[0]);
            Assert.AreEqual(relatedCases.Row5.EventDescription, detailsP2.EventDescription, "Related Case: C2 - Should have event description from relationship");
        }

        void TestOfficialNumbers(NgWebDriver driver, OfficialNumber ipOffice, OfficialNumber other)
        {
            Assert.Throws<NoSuchElementException>(() =>
                                                  {
                                                      var grid = new OfficialNumbersTopic(driver).OtherNumbers.Grid;
                                                  }, "Other number grids should not be rendered for external users by default");

            var officialNumber = new OfficialNumbersTopic(driver);
            var officialNoColIndex = 1;

            officialNumber.IpOfficeNumbers.Grid.WithJs().ScrollIntoView();

            Assert.AreEqual(1, officialNumber.IpOfficeNumbers.Rows.Count);
            Assert.AreEqual(ipOffice.Number, officialNumber.IpOfficeNumbers.CellText(0, officialNoColIndex));
        }

        void TestDeadPatentDesignatedJurisdiction(NgWebDriver driver, dynamic designationJurisdiction)
        {
            var designationRow1 = (DesignatedJurisdictionData)designationJurisdiction.Row1.Case;
            var designationRow2 = (DesignatedJurisdictionData)designationJurisdiction.Row2.Case;
            var designatedJurisdiction = new DesignatedJurisdictionTopic(driver);
            designatedJurisdiction.DesignatedJurisdictionGrid.Grid.WithJs().ScrollIntoView();

            Assert.True(designatedJurisdiction.DesignatedJurisdictionGrid.Grid.Displayed, "Designated Jurisdiction Section is showing");

            Assert.AreEqual(11, designatedJurisdiction.DesignatedJurisdictionGrid.HeaderColumns.Count);
            Assert.AreEqual(2, designatedJurisdiction.DesignatedJurisdictionGrid.Rows.Count, "Designated Jurisdiction Section should have 2 rows");
            Assert.AreEqual((int)DJIndex.ClientReference, designatedJurisdiction.DesignatedJurisdictionGrid.HeaderColumns.ToList().FindIndex(e => e.Text.Equals("Your Reference")));
            Assert.AreEqual(-1, designatedJurisdiction.DesignatedJurisdictionGrid.HeaderColumns.ToList().FindIndex(e => e.Text.Equals("Instructor Reference")));
            Assert.AreEqual(-1, designatedJurisdiction.DesignatedJurisdictionGrid.HeaderColumns.ToList().FindIndex(e => e.Text.Equals("Agent Reference")));

            Assert.AreEqual(designationRow1.Jurisdiction, designatedJurisdiction.DesignatedJurisdictionGrid.Cell(0, (int)DJIndex.Jurisdication).Text, "Designated Jurisdiction: Should show Jurisdiction");
            Assert.AreEqual(designationRow1.DesignatedStatus, designatedJurisdiction.DesignatedJurisdictionGrid.Cell(0, (int)DJIndex.DesignatedStatus).Text, "Designated Jurisdiction: Should show Designated Status");
            Assert.AreEqual(designationRow1.CaseStatus, designatedJurisdiction.DesignatedJurisdictionGrid.Cell(0, (int)DJIndex.CaseStatus).Text, "Designated Jurisdiction: Should show Case Status");
            Assert.AreEqual(designationRow1.ClientReference, designatedJurisdiction.DesignatedJurisdictionGrid.Cell(0, (int)DJIndex.ClientReference).Text, "Designated Jurisdiction: Should show Client Reference");
            Assert.AreEqual(designationRow1.InternalReference, designatedJurisdiction.DesignatedJurisdictionGrid.Cell(0, (int)DJIndex.InternalReference).Text, "Designated Jurisdiction: Should show Internal Reference");
            Assert.NotNull(designatedJurisdiction.DesignatedJurisdictionGrid.Cell(0, (int)DJIndex.InternalReference).FindElements(By.TagName("a")).FirstOrDefault());

            Assert.AreEqual(designationRow2.Jurisdiction, designatedJurisdiction.DesignatedJurisdictionGrid.Cell(1, (int)DJIndex.Jurisdication).Text, "Designated Jurisdiction: Should show Jurisdiction");
            Assert.AreEqual(designationRow2.DesignatedStatus, designatedJurisdiction.DesignatedJurisdictionGrid.Cell(1, (int)DJIndex.DesignatedStatus).Text, "Designated Jurisdiction: Should show Designated Status");
            Assert.AreEqual(designationRow2.CaseStatus, designatedJurisdiction.DesignatedJurisdictionGrid.Cell(1, (int)DJIndex.CaseStatus).Text, "Designated Jurisdiction: Should show Case Status");
            Assert.AreEqual(designationRow2.ClientReference, designatedJurisdiction.DesignatedJurisdictionGrid.Cell(1, (int)DJIndex.ClientReference).Text, "Designated Jurisdiction: Should show Client Reference");
            Assert.Null(designatedJurisdiction.DesignatedJurisdictionGrid.Cell(1, (int)DJIndex.InternalReference).FindElements(By.TagName("a")).FirstOrDefault());
            Assert.NotNull(designatedJurisdiction.DesignatedJurisdictionGrid.Cell(1, (int)DJIndex.InternalReference).FindElements(By.CssSelector(".cpa-icon-ban")).FirstOrDefault());

            TestColumnSelection();
            TestDetailNames();

            void TestColumnSelection()
            {
                AssertColumnsNotDisplayed("classes", "priorityDate", "isExtensionState");

                designatedJurisdiction.ColumnSelector.ColumnMenuButtonClick();
                Assert.IsTrue(designatedJurisdiction.ColumnSelector.IsColumnChecked("jurisdiction"), "The column appears checked in the menu");

                designatedJurisdiction.ColumnSelector.ToggleGridColumn("jurisdiction");
                designatedJurisdiction.ColumnSelector.ColumnMenuButtonClick();
                AssertColumnsNotDisplayed("jurisdiction");

                designatedJurisdiction.ColumnSelector.ColumnMenuButtonClick();
                Assert.IsFalse(designatedJurisdiction.ColumnSelector.IsColumnChecked("jurisdiction"), "The column is unchecked in the menu");
                designatedJurisdiction.ColumnSelector.ToggleGridColumn("classes");
                designatedJurisdiction.ColumnSelector.ColumnMenuButtonClick();
                AssertColumnsIsVisible("classes");
                Assert.AreEqual(designationRow1.Classes.Replace(",", ", "), designatedJurisdiction.DesignatedJurisdictionGrid.Cell(0, (int)DJIndex.Classes).Text, "Classes should be shown with space in comma");

                ReloadPage(driver);
                designatedJurisdiction.DesignatedJurisdictionGrid.Grid.WithJs().ScrollIntoView();
                AssertColumnsNotDisplayed("jurisdiction");
                AssertColumnsIsVisible("classes");

                designatedJurisdiction.ColumnSelector.ColumnMenuButtonClick();
                designatedJurisdiction.ColumnSelector.ToggleGridColumn("jurisdiction");
                designatedJurisdiction.ColumnSelector.ToggleGridColumn("isExtensionState");
                designatedJurisdiction.ColumnSelector.ColumnMenuButtonClick();
                AssertColumnsIsVisible("isExtensionState");
                Assert.True(designatedJurisdiction.DesignatedJurisdictionGrid.CellIsSelected(0, (int)DJIndex.IsExtensionState));
            }

            void TestDetailNames()
            {
                var caseSummary1 = (OverviewSummary)designationJurisdiction.Row1.Details;
                var caseNames = caseSummary1.Names.ToDictionary(k => k.NameType, v => v);

                int rowIndex = 0;
                designatedJurisdiction.DesignatedJurisdictionGrid.ToggleDetailsRow(rowIndex);

                var namesDiv = designatedJurisdiction.DesignatedJurisdictionGrid.DetailRows[rowIndex].FindElement(By.Name("names")).FindElements(By.ClassName("row"));
                foreach (var name in namesDiv)
                {
                    var label = name.FindElement(By.TagName("label")).Text;
                    var span = (name.FindElements(By.TagName("a")).FirstOrDefault() ?? name.FindElements(By.TagName("span")).FirstOrDefault())?.Text;

                    Assert.True(caseNames.TryGetValue(label, out var expectedName));
                    Assert.AreEqual(expectedName.Name, span);
                }
            }

            void AssertColumnsNotDisplayed(params string[] columnHeader)
            {
                foreach (var column in columnHeader) Assert.AreEqual(false, designatedJurisdiction.DesignatedJurisdictionGrid.HeaderColumn(column).Displayed, $"Hidden Column '{column}' should not be displayed");
            }

            void AssertColumnsIsVisible(params string[] columnHeader)
            {
                foreach (var column in columnHeader) Assert.AreEqual(true, designatedJurisdiction.DesignatedJurisdictionGrid.HeaderColumn(column).WithJs().IsVisible(), $"'{column}' Column should be displayed");
            }
        }
    }
}