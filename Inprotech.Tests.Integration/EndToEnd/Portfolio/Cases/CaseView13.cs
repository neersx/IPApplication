using System;
using System.Collections.Generic;
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
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using NUnit.Framework;
using OpenQA.Selenium;
using OpenQA.Selenium.Interactions;
using Protractor;
using ClassesIndex = Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.DesignatedJurisdictionTopic.ClassesColumns;
using CNIndex = Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.CaseNameTopic.InternalUser;
using DJIndex = Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.DesignatedJurisdictionTopic.InternalUser;
using RCIndex = Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases.CaseRelatedCasesTopic.InternalUser;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.Cases
{
    [Category(Categories.E2E)]
    [TestFixture]
    [TestFrom(DbCompatLevel.Release13)]
    public class CaseView13 : IntegrationTest
    {
        [TearDown]
        public void CleanupModifiedData()
        {
            SiteControlRestore.ToDefault(SiteControls.CriticalDates_Internal, SiteControls.EnableRichTextFormatting, SiteControls.KEEPSPECIHISTORY, SiteControls.HomeNameNo, SiteControls.CPA_UseClientCaseCode);
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

                nameTypes[KnownNameTypes.RenewalsDebtor].IsNameRestricted = null;

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
        public void CaseViewReadOnlyTopicsNameCaseRowAccess(BrowserType browserType)
        {
            var setup = new CaseDetailsDbSetup();
            var data = setup.ReadOnlyDataSetup();

            var caseId = (int) data.Trademark.Case.Id;
            var caseIdPatent = (int) data.Patent.Case.Id;

            var rowSecurity = DbSetup.Do(x =>
            {
                var @case = x.DbContext.Set<Case>().Single(_ => _.Id == caseId);
                var case2 = x.DbContext.Set<Case>().Single(_ => _.Id == caseIdPatent);
                var nameToBlock = (string) data.Trademark.CaseNames.CombinedNames.Row1.NameCode;
                var nameTypeCodeToBlock = (string) data.Trademark.CaseNames.CombinedNames.Row1.NameTypeCode;
                var nameType = x.DbContext.Set<NameType>()
                                .Single(_ => _.NameTypeCode == nameTypeCodeToBlock);
                var debtorType = x.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Debtor);

                if (debtorType.ColumnFlag == null)
                {
                    debtorType.ColumnFlag = 0;
                }

                debtorType.ColumnFlag |= KnownNameTypeColumnFlags.DisplayAddress | KnownNameTypeColumnFlags.DisplayTelecom;
                nameType.ColumnFlag |= KnownNameTypeColumnFlags.DisplayAddress | KnownNameTypeColumnFlags.DisplayTelecom;

                var name = x.DbContext.Set<Name>().Single(n => n.NameCode.Equals(nameToBlock));
                var attnToBlock = (string) data.Trademark.CaseNames.CombinedNames.Row2.attentionNameCode;
                var attention = x.DbContext.Set<Name>().Single(n => n.NameCode.Equals(attnToBlock));

                var propertyType = @case.PropertyType;
                var caseType = @case.Type;
                name.NameTypeClassifications.Add(new NameTypeClassification(name, nameType) {IsAllowed = 1});
                attention.NameTypeClassifications.Add(new NameTypeClassification(attention, debtorType) {IsAllowed = 1});

                var rowAccessDetail = new RowAccess("ra1", "row access one")
                {
                    Details = new List<RowAccessDetail>
                    {
                        new RowAccessDetail("ra1")
                        {
                            SequenceNo = 0,
                            Office = @case.Office,
                            AccessType = RowAccessType.Case,
                            CaseType = caseType,
                            PropertyType = propertyType,
                            AccessLevel = 15
                        },
                        new RowAccessDetail("ra1")
                        {
                            SequenceNo = 1,
                            Office = case2.Office,
                            AccessType = RowAccessType.Case,
                            CaseType = case2.Type,
                            PropertyType = case2.PropertyType,
                            AccessLevel = 15
                        },
                        new RowAccessDetail("ra1")
                        {
                            SequenceNo = 2,
                            Office = null,
                            AccessType = RowAccessType.Name,
                            AccessLevel = 15
                        },
                        new RowAccessDetail("ra1")
                        {
                            SequenceNo = 3,
                            Office = null,
                            AccessType = RowAccessType.Name,
                            AccessLevel = 0,
                            NameType = nameType
                        },
                        new RowAccessDetail("ra1")
                        {
                            SequenceNo = 4,
                            Office = null,
                            AccessType = RowAccessType.Name,
                            AccessLevel = 0,
                            NameType = debtorType
                        }
                    }
                };

                var user = new Users(x.DbContext).WithRowLevelAccess(rowAccessDetail).Create();

                return new
                {
                    user,
                    rowAccessDetail
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, $"/#/caseview/{data.Trademark.Case.Id}", rowSecurity.user.Username, rowSecurity.user.Password);

            var caseViewEvents = new CaseEventsTopic(driver);
            caseViewEvents.OccurredDatesGrid.Rows[0].FindElements(By.TagName("td"))[0].FindElement(By.TagName("a")).ClickWithTimeout();
            var otherDetails = caseViewEvents.OccurredDatesGrid.DetailRows[0].FindElement(By.CssSelector("ipx-event-other-details div.content"));

            var spans = otherDetails.FindElements(By.TagName("span")).Select(s => s.Text).ToList();
            var labels = otherDetails.FindElements(By.TagName("label"));
            Assert.AreEqual(2, labels.Count, "correct number of labels showing");
            Assert.False(spans.Contains(data.Trademark.Events.Row3.FromCaseIrn), "shouldn't display case text");

            var namesTopic = new CaseNameTopic(driver);
            var namesForbiddenIcon = namesTopic.CaseViewNameGrid.Cell(0, 3).FindElements(By.CssSelector("span.cpa-icon-ban")).FirstOrDefault();
            Assert.NotNull(namesForbiddenIcon, "Name should be blocked");

            var expandButton = namesTopic.CaseViewNameGrid.Cell(0, 0).FindElements(By.CssSelector("a")).SingleOrDefault();
            Assert.Null(expandButton, "Name details should hide");

            var attentionForbiddenIcon = namesTopic.CaseViewNameGrid.Cell(1, 5).FindElements(By.CssSelector("span.cpa-icon-ban")).FirstOrDefault();
            Assert.Null(attentionForbiddenIcon, "Attention Name should not blocked");
            Assert.True(namesTopic.CaseViewNameGrid.CellText(1, 5).Contains((string) data.Trademark.CaseNames.CombinedNames.Row2.attentionFirstName), "Case name Section: Row 1: Should be name column");

            namesTopic.CaseViewNameGrid.ToggleDetailsRow(1);
            var detailSection = new CaseNameTopic.DetailSection(driver, namesTopic.CaseViewNameGrid, 0);

            Assert.AreEqual((string) data.Trademark.CaseNames.CombinedNames.Row2.attnEmail, detailSection.Email, "Case name Section: Detail Row 1: Should have email from main name");
            Assert.True(detailSection.Phone.IndexOf((string) data.Trademark.CaseNames.CombinedNames.Row2.TelecomNumber, StringComparison.Ordinal) > 0, "Case name Section: Detail Row 1: Should have email from main name");

            var renewalsNameTopic = new RenewalTopic(driver);
            var renewalNamesForbiddenIcon = renewalsNameTopic.RenewalNames.Cell(2, 3).FindElements(By.CssSelector("span.cpa-icon-ban")).FirstOrDefault();
            Assert.NotNull(renewalNamesForbiddenIcon, "Renewal Name should be blocked");

            var renewalExpandButton = renewalsNameTopic.RenewalNames.Cell(2, 0).FindElements(By.CssSelector("a")).SingleOrDefault();
            Assert.Null(renewalExpandButton, "Renewal Name details should hide");

            var renewalAttentionForbiddenIcon = renewalsNameTopic.RenewalNames.Cell(2, 4).FindElements(By.CssSelector("span.cpa-icon-ban")).FirstOrDefault();
            Assert.Null(renewalAttentionForbiddenIcon, "Attention Name should not blocked");

            driver.Visit($"{Env.RootUrl}/#/caseview/{data.Patent.Case.Id}");
            driver.WaitForAngularWithTimeout();
            var jurisdictionTopic = new DesignatedJurisdictionTopic(driver);
            jurisdictionTopic.DesignatedJurisdictionGrid.Grid.WithJs().ScrollIntoView();

            var caseSummary1 = (OverviewSummary) data.Patent.DesignatedJurisdiction.Row1.Details;
            var caseNames = caseSummary1.Names.ToDictionary(k => k.NameType, v => v);
            const int rowIndex = 0;
            jurisdictionTopic.DesignatedJurisdictionGrid.ToggleDetailsRow(rowIndex);

            var namesDiv = jurisdictionTopic.DesignatedJurisdictionGrid.DetailRows[rowIndex].FindElement(By.Name("names")).FindElements(By.ClassName("row"));
            foreach (var name in namesDiv)
            {
                var label = name.FindElement(By.TagName("label")).Text;
                var span = (name.FindElements(By.TagName("a")).FirstOrDefault() ?? name.FindElements(By.TagName("span")).FirstOrDefault())?.Text;
                var forbiddenIcon = name.FindElements(By.CssSelector("span.cpa-icon-ban")).FirstOrDefault();

                Assert.True(caseNames.TryGetValue(label, out _));
                Assert.False(string.IsNullOrWhiteSpace(span));
                Assert.Null(forbiddenIcon);
            }
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        public void CaseViewReadOnlyTopics(BrowserType browserType)
        {
            var setup = new CaseDetailsDbSetup();
            var data = setup.ReadOnlyDataSetup();

            DbSetup.Do(x =>
            {
                var enableRichTextSiteControl = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.EnableRichTextFormatting);
                enableRichTextSiteControl.BooleanValue = true;

                var textHistorySiteControl = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.KEEPSPECIHISTORY);
                textHistorySiteControl.BooleanValue = true;

                var language = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.LANGUAGE);
                language.IntegerValue = null;

                var nameTypes = x.DbContext.Set<NameType>().Where(_ => _.NameTypeCode == KnownNameTypes.Debtor || _.NameTypeCode == KnownNameTypes.RenewalsDebtor)
                                 .ToDictionary(k => k.NameTypeCode, v => v);

                _debtorColumnFlags = nameTypes[KnownNameTypes.Debtor].ColumnFlag;
                _renewalDebtorColumnFlags = nameTypes[KnownNameTypes.RenewalsDebtor].ColumnFlag;

                if (nameTypes[KnownNameTypes.Debtor].ColumnFlag == null)
                {
                    nameTypes[KnownNameTypes.Debtor].ColumnFlag = 0;
                }

                if (nameTypes[KnownNameTypes.RenewalsDebtor].ColumnFlag == null)
                {
                    nameTypes[KnownNameTypes.RenewalsDebtor].ColumnFlag = 0;
                }

                nameTypes[KnownNameTypes.Debtor].ColumnFlag |= KnownNameTypeColumnFlags.DisplayAddress | KnownNameTypeColumnFlags.DisplayAttention | KnownNameTypeColumnFlags.DisplayRemarks;
                nameTypes[KnownNameTypes.RenewalsDebtor].ColumnFlag |= KnownNameTypeColumnFlags.DisplayAddress | KnownNameTypeColumnFlags.DisplayAttention;
                nameTypes[KnownNameTypes.RenewalsDebtor].IsNameRestricted = 1;
                x.DbContext.SaveChanges();
            });

            var driver = BrowserProvider.Get(browserType);

            var user = new Users().WithPermission(ApplicationTask.MaintainCase, Allow.Select)
                                  .WithPermission(ApplicationTask.ViewFileCase)
                                  .WithPermission(ApplicationTask.CreateFileCase)
                                  .WithPermission(ApplicationTask.LaunchScreenDesigner)
                                  .CreateIpPlatformUser(true, true);

            SignIn(driver, $"/#/caseview/{data.Trademark.Case.Id}", user.Username, user.Password);

            TestCaseDesignElements(driver, data.Trademark.DesignElements);

            TestCaseFileLocations(driver, data.Trademark.FileLocations);

            TestCaseFileLocationHistory(driver, data.Trademark.FileLocations);

            PageTitleContainsIrn(driver, data.Trademark.Case.Irn);

            TestChecklistTopic(driver, data.Trademark.Checklists);

            TestContextNav(driver, data.Trademark.Case);

            TestPendingTrademarkCaseHeader(driver, data);

            TestPendingTrademarkCaseNames(driver, data.Trademark.Case, data.Trademark.CaseNames.Others);

            TestPendingTrademarkCombinedCaseNames(driver, data.Trademark.CaseNames.CombinedNames);

            TestPendingTrademarkCriticalDates(driver, data.Trademark.CriticalDates);

            TestPendingTrademarkEvents(driver, data.Trademark.Events, data.Trademark.EventsDue, "Critical");

            TestPendingTrademarkRelatedCases(driver, data.Trademark.RelatedCases);

            TestPendingTrademarkTexts(driver, data.Trademark.CaseTexts);

            TestHistoryPopupModal(driver, data.Trademark.CaseTexts, data.Trademark.Case.Irn);

            TestOfficialNumbers(driver, data.Trademark.OfficialNumbers.IpOffice, data.Trademark.OfficialNumbers.Other);

            TestImages(driver);

            TestRenewals(driver, data.Trademark);

            TestStandingInstructions(driver, data.Trademark);

            TestCustomContentTopic(driver);

            TestProgramId(driver, data.Trademark.Case.Id);

            driver.Visit($"{Env.RootUrl}/#/caseview/{data.Patent.Case.Id}");
            driver.WaitForAngularWithTimeout();

            TestContextNav(driver, data.Patent.Case);

            TestDeadPatentCaseHeader(driver, data);

            TestDeadPatentCriticalDates(driver, data.Patent.CriticalDates);

            TestDeadPatentRelatedCases(driver, data.Patent.RelatedCases);

            TestOfficialNumbers(driver, data.Patent.OfficialNumbers.IpOffice, data.Patent.OfficialNumbers.Other, true);

            TestDeadPatentTexts(driver, data.Patent.CaseTexts);

            TestDeadPatentDesignatedJurisdiction(driver, data.Patent.DesignatedJurisdiction);

            TestRenewalsPatent(driver, data.Patent);
        }

        void TestContextNav(NgWebDriver driver, Case @case)
        {
            var setup = new CaseDetailsDbSetup();
            var links = setup.CaseWebLinks(@case).ToList();
            var q = new QuickLinks(driver);
            q.Open("contextQuickLinks");
            var onScreenLinks = new CaseWebLinks(driver, q.SlideContainer).Links().ToList();
            foreach (var link in links)
            {
                var url = link.Url;
                if (string.IsNullOrEmpty(url))
                {
                    url = $"/api/case/{@case.Id}/weblinks/{link.Id}/{link.DocItemId.GetValueOrDefault()}";
                }

                Assert.True(onScreenLinks.Any(_ => _.Contains(url)));
            }

            q.Close();

            q.Open("contextCaseDetails");
            Assert.AreEqual(@case.Id.ToString(), q.SlideContainer.FindElement(By.Name("internalCaseId")).Text, "Generated Internal Case detail with the same case Id");
            Assert.True(q.SlideContainer.FindElement(By.TagName("a")).Displayed, "Should generate link on criteria");
            q.Close();
        }

        static void TestPendingTrademarkCaseNames(NgWebDriver driver, Case @case, dynamic names)
        {
            var caseNameTopic = new CaseNameTopic(driver);
            Assert.True(caseNameTopic.CaseViewNameGrid.Grid.Displayed, "Names section is showing");
            Assert.False(caseNameTopic.CaseViewNameGrid.HeaderColumns.Any(x => x.Text == "Bill Percentage"));

            caseNameTopic.CaseViewNameGrid.Grid.WithJs().ScrollIntoView();
            foreach (var caseCaseName in @case.CaseNames)
            {
                int rowId;
                if (caseCaseName.NameType.ShowNameCode == 1m)
                {
                    var nameToFind = $"{{{caseCaseName.Name.NameCode}}} {caseCaseName.Name.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName)}";
                    caseNameTopic.CaseViewNameGrid.FindRow((int) CNIndex.Name, nameToFind, out rowId);
                    Assert.AreNotEqual(-1, rowId, $"Should be able to find name code formatted first, i.e. {nameToFind}, but not found.");
                }
                else if (caseCaseName.NameType.ShowNameCode == 2m)
                {
                    var nameToFind = $"{caseCaseName.Name.Formatted(fallbackNameStyle: NameStyles.FirstNameThenFamilyName)} {{{caseCaseName.Name.NameCode}}}";
                    caseNameTopic.CaseViewNameGrid.FindRow((int) CNIndex.Name, nameToFind, out rowId);
                    Assert.AreNotEqual(-1, rowId, $"Should be able to find name code formatted last, i.e. {nameToFind}, but not found.");
                }
            }

            var detailsRowCreated = 0;

            void TestCaseNameAndDetails(dynamic row, int rowIndex)
            {
                Assert.AreEqual(row.Type, caseNameTopic.CaseViewNameGrid.MasterCellText(rowIndex, (int) CNIndex.NameType), $"Case name Section: Row {rowIndex}: Should be name type column");

                var nameLink = caseNameTopic.CaseViewNameGrid.MasterCell(rowIndex, (int) CNIndex.Name).FindElements(By.CssSelector("ip-ie-only-url a")).SingleOrDefault();
                Assert.NotNull(nameLink, $"Case name Section: Row {rowIndex}: Should be a hyperlink name column");
                Assert.AreEqual(row.FormattedName, nameLink.Text, $"Case name Section: Row {rowIndex}: Should be name column");

                if (string.IsNullOrWhiteSpace(row.FormattedAttentionName))
                {
                    Assert.AreEqual(row.FormattedAttentionName, caseNameTopic.CaseViewNameGrid.MasterCellText(rowIndex, (int) CNIndex.AttentionName), $"Case name Section: Row {rowIndex}: Should be attention name column");
                }
                else
                {
                    var attentionNameLink = caseNameTopic.CaseViewNameGrid.MasterCell(rowIndex, (int) CNIndex.AttentionName).FindElements(By.CssSelector("ip-ie-only-url a")).SingleOrDefault();
                    Assert.NotNull(attentionNameLink, $"Case name Section: Row {rowIndex}: Should be a hyperlink attention name column");
                    Assert.AreEqual(row.FormattedAttentionName, attentionNameLink.Text, $"Case name Section: Row {rowIndex}: Should be attention name column");
                }

                var nameIsInheritedIcon = caseNameTopic.GetInheritanceIcon(rowIndex, (int) CNIndex.Name);

                if (row.IsInherited)
                {
                    Assert.NotNull(nameIsInheritedIcon, $"Case name Section: Row {rowIndex}: Should indicate inheritance");
                }
                else
                {
                    Assert.Null(nameIsInheritedIcon, $"Case name Section: Row {rowIndex}: Should indicate there were no inheritance");
                }

                var attentionNameIsDerivedIcon = caseNameTopic.GetInheritanceIcon(rowIndex, (int) CNIndex.AttentionName);

                if (row.IsAttentionNameDerived)
                {
                    Assert.NotNull(attentionNameIsDerivedIcon, $"Case name Section: Row {rowIndex}: Should indicate attention name is derived");
                }
                else
                {
                    Assert.Null(attentionNameIsDerivedIcon, $"Case name Section: Row {rowIndex}: Should indicate attention name was not derived");
                }

                var debtorRestrictionFlag = caseNameTopic.GetDebtorRestrictionFlag(rowIndex, (int) CNIndex.DebtorRestrictionIndicator);
                if (row.DebtorStatus == null)
                {
                    Assert.True(debtorRestrictionFlag == null || !debtorRestrictionFlag.Displayed, $"Case name Section: Row {rowIndex}: Should not have a debtor status icon");
                }
                else
                {
                    Assert.True(debtorRestrictionFlag.FindElement(By.TagName("span")).WithJs().HasClass(row.DebtorStatus), $"Case name Section: Row {rowIndex}: Should not have a debtor status icon");
                }

                caseNameTopic.CaseViewNameGrid.ToggleDetailsRow(rowIndex);

                var index = detailsRowCreated++;
                var ipTextArea = caseNameTopic.CaseViewNameGrid.DetailRows[index].FindElement(By.TagName("ip-text-area"));
                var addressTextArea = ipTextArea.FindElement(By.TagName("textarea"));
                Assert.AreEqual(row.FormattedAddress, addressTextArea.Text, $"Case name Section: Row {rowIndex}: Should display address");
                Assert.AreEqual(row.IsAddressInherited, ipTextArea.WithJs().HasClass("input-inherited"), $"Case name Section: Row {rowIndex}: Should display address as inherited accordingly");

                var detailSection = new CaseNameTopic.DetailSection(driver, caseNameTopic.CaseViewNameGrid, index);

                Assert.AreEqual(row.Email, detailSection.Email, $"Case name Section: Detail Row {index}: Should have same email");
                Assert.IsTrue(detailSection.EmailMailtoHref.StartsWith(row.EmailHref), $"Case name Section: Detail Row {index}: Should have formatted mailto {row.EmailHref} but is {detailSection.EmailMailtoHref} instead");
                Assert.AreEqual(row.Phone, detailSection.Phone, $"Case name Section: Detail Row {index}: Should have same phone");
                Assert.AreEqual(row.Website, detailSection.Website, $"Case name Section: Detail Row {index}: Should have same website");
                Assert.AreEqual(row.Remarks, detailSection.Comments ?? string.Empty, $"Case name Section: Detail Row {index}: Should have same comments");

                caseNameTopic.CaseViewNameGrid.ToggleDetailsRow(rowIndex);
            }

            TestCaseNameAndDetails(names.Row0, 0);
            TestCaseNameAndDetails(names.Row1, 1);
            TestCaseNameAndDetails(names.DebtorRow, 6);
            TestCaseNameAndDetails(names.RenewalDebtorRow, 7);
        }

        static void TestPendingTrademarkCombinedCaseNames(NgWebDriver driver, dynamic combinedNames)
        {
            var combinedNameTopic = new CaseNameTopic(driver, combinedNames.TopicContextKey);

            Assert.True(combinedNameTopic.CaseViewNameGrid.Grid.Displayed, "Combined Name Section is showing");
            combinedNameTopic.CaseViewNameGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(3, combinedNameTopic.CaseViewNameGrid.MasterRows.Count, "Combined Section: should show 3 rows");
            Assert.AreEqual(3, combinedNameTopic.NumberOfRecords(), "Number of records is shown correctly");

            Assert.AreEqual(combinedNames.Row1.Type, combinedNameTopic.CaseViewNameGrid.CellText(0, (int) CNIndex.NameType), "Case name Section: Row 1: Should be name type");
            Assert.True(combinedNameTopic.CaseViewNameGrid.CellText(0, (int) CNIndex.Name).Contains(combinedNames.Row1.FirstName), "Case name Section: Row 1: Should be name column");

            Assert.AreEqual(combinedNames.Row2.Type, combinedNameTopic.CaseViewNameGrid.CellText(1, (int) CNIndex.NameType), "Case name Section: Row 2: Should be name type");
            Assert.True(combinedNameTopic.CaseViewNameGrid.CellText(1, (int) CNIndex.Name).Contains(combinedNames.Row2.FirstName), "Case name Section: Row 2: Should be name column");

            Assert.AreEqual(combinedNames.Row3.Type, combinedNameTopic.CaseViewNameGrid.CellText(2, (int) CNIndex.NameType), "Case name Section: Row 3: Should be name type");
            Assert.True(combinedNameTopic.CaseViewNameGrid.CellText(2, (int) CNIndex.Name).Contains(combinedNames.Row3.FirstName), "Case name Section: Row 3: Should be name column");

            Assert.True(combinedNameTopic.CaseViewNameGrid.HeaderColumns.Any(x => x.Text == "Bill Percentage"));
            Assert.AreEqual(combinedNames.Row1.BillingPercentage?.toString() ?? string.Empty, combinedNameTopic.CaseViewNameGrid.CellText(0, (int) CNIndex.BillPercentage), "Case name Section: Row 1: Should be bill percentage");
            Assert.AreEqual(combinedNames.Row2.BillingPercentage?.toString() ?? string.Empty, combinedNameTopic.CaseViewNameGrid.CellText(1, (int) CNIndex.BillPercentage), "Case name Section: Row 2: Should be bill percentage");
            Assert.AreEqual(combinedNames.Row3.BillingPercentage ?? string.Empty, combinedNameTopic.CaseViewNameGrid.CellText(2, (int) CNIndex.BillPercentage), "Case name Section: Row 3: Should be bill percentage");

            const int detailRowIndex = 2;
            combinedNameTopic.CaseViewNameGrid.ToggleDetailsRow(2);

            var detailSection = new CaseNameTopic.DetailSection(driver, combinedNameTopic.CaseViewNameGrid, 0);

            Assert.AreEqual(combinedNames.Row3.AssignmentDate, detailSection.AssignmentDate, $"Case name Section: Detail Row {detailRowIndex}: Should have same assignment date");
            Assert.AreEqual(combinedNames.Row3.CeaseDate, detailSection.CeaseDate, $"Case name Section: Detail Row {detailRowIndex}: Should not have same cease date");
            Assert.AreEqual(combinedNames.Row3.CommenceDate, detailSection.CommenceDate, $"Case name Section: Detail Row {detailRowIndex}: Should have same commence date");
            Assert.AreEqual(combinedNames.Row3.BillingPercentage, detailSection.BillPercentage, $"Case name Section: Detail Row {detailRowIndex}: Should have same bill percentage");
            Assert.AreEqual(combinedNames.Row3.Nationality, detailSection.Nationality, $"Case name Section: Detail Row {detailRowIndex}: Should have same nationality");
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

            Assert.Throws<NoSuchElementException>(() => summary.Field("yourReference"), "External User field Your Reference is not displayed");
            Assert.Throws<NoSuchElementException>(() => summary.Field("clientMainContact.name"), "External User field Your Contact is not displayed");
            Assert.Throws<NoSuchElementException>(() => summary.Field("ourContact.name"), "External User field Our Contact is not displayed");

            Assert.AreEqual(summary.Field("caseType").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("country").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("propertyType").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("caseCategory").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("subType").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("renewalStatus").GetAttribute("is-first-column"), "true");

            Assert.Throws<NoSuchElementException>(() => { driver.FindElement(By.TagName("ip-case-image")); }, "Case Image placeholder should not be rendered when no image available");
        }

        static void TestBillPercentageHeader(NgWebDriver driver, dynamic data)
        {
            var summary = new SummaryTopic(driver);
            var irn = summary.FieldValue("irn");
            var title = summary.FieldValue("title");

            var trademarkCaseView = new NewCaseViewDetail(driver);
            var pageTitle = trademarkCaseView.PageTitle();
            var pageDescription = trademarkCaseView.PageDescription();

            var trademarkPropertyStatusClass = trademarkCaseView.PropertyStatusIcon.GetAttribute("class");
            var trademarkIconClass = trademarkCaseView.PropertyTypeIcon.GetAttribute("class");

            Assert.AreEqual(data.Trademark.Case.Irn, irn, $"Expected correct IRN '{data.Trademark.Case.Irn}' to be displayed");
            Assert.AreEqual(data.Trademark.Case.Title, title, $"Expected correct Title '{data.Trademark.Case.Title}' to be displayed");
            Assert.AreEqual(data.Trademark.TrademarkLabel, summary.FieldLabel("irn"), "Expected customised label to be displayed");
            Assert.True(pageTitle.Contains(data.Trademark.Case.Irn), "Expected the Case IRN to be in Page Title");
            Assert.True(pageDescription.Contains(data.Trademark.Case.Country.CountryAdjective + ' ' + data.Trademark.Case.PropertyType.Name), "Expected the Short Description to be in the Page Description");
            Assert.True(summary.Field("typeOfMark").Displayed);
            Assert.True(summary.Field("classes").Displayed);
            Assert.True(summary.Field("numberInSeries").Displayed);

            Assert.Throws<NoSuchElementException>(() => summary.Field("yourReference"), "External User field Your Reference is not displayed");
            Assert.Throws<NoSuchElementException>(() => summary.Field("clientMainContact.name"), "External User field Your Contact is not displayed");
            Assert.Throws<NoSuchElementException>(() => summary.Field("ourContact.name"), "External User field Our Contact is not displayed");

            Assert.True(trademarkPropertyStatusClass.Contains("pending"), $"Expect property type icon to have correct style but has these classes instead '{trademarkPropertyStatusClass}'");
            Assert.True(trademarkIconClass.Contains("cpa-icon-trademark"), $"Expect correct property type icon to be displayed but has these classes instead '{trademarkIconClass}'");

            Assert.AreEqual(summary.Field("caseType").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("country").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("propertyType").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("caseCategory").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("subType").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("renewalStatus").GetAttribute("is-first-column"), "true");

            Assert.True(summary.Field("staff").FindElement(By.CssSelector(".cpa-icon-envelope")).Displayed, "Expect email icon is displayed for working attorney");

            var image = driver.FindElement(By.TagName("ip-case-image")).FindElement(By.ClassName("case-image-thumbnail"));
            image.ClickWithTimeout();
            var imagePopup = new CommonPopups(driver);
            Assert.True(imagePopup.FindElement(By.TagName("ip-case-image")).Displayed, "Expected image dialog to be displayed");
            imagePopup.FindElement(By.ClassName("btn-discard")).ClickWithTimeout();
        }

        static void TestPendingTrademarkCaseHeader(NgWebDriver driver, dynamic data)
        {
            var summary = new SummaryTopic(driver);

            var trademarkCaseView = new NewCaseViewDetail(driver);
            var pageTitle = trademarkCaseView.PageTitle();
            var pageDescription = trademarkCaseView.PageDescription();

            Assert.Throws<NoSuchElementException>(() => summary.Field("yourReference"), "External User field Your Reference is not displayed");
            Assert.Throws<NoSuchElementException>(() => summary.Field("clientMainContact.name"), "External User field Your Contact is not displayed");
            Assert.Throws<NoSuchElementException>(() => summary.Field("ourContact.name"), "External User field Our Contact is not displayed");

            Assert.AreEqual(summary.Field("caseType").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("country").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("propertyType").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("caseCategory").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("subType").GetAttribute("is-first-column"), "true");
            Assert.AreEqual(summary.Field("renewalStatus").GetAttribute("is-first-column"), "true");

            Assert.True(summary.Field("staff").FindElement(By.CssSelector(".cpa-icon-envelope")).Displayed, "Expect email icon is displayed for working attorney");

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
            Assert.AreEqual(4, caseCriticalDates.CriticalDatesGrid.Rows.Count, "Critical Dates Section: should show 4 rows");

            Assert.AreEqual(criticalDates.Row1.PriorityDate, caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesDateColumn), "Critical Dates Section: Row 1: Should be priority date");
            Assert.AreEqual(criticalDates.Row1.PriorityNumber, caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesOfficialNumberColumn), "Critical Dates Section: Row 1: Should be priority number");
            Assert.Throws<NoSuchElementException>(() => caseCriticalDates.CriticalDatesGrid.Cell(0, CriticalDatesOfficialNumberColumn).FindElement(By.TagName("a")), "Trademark cases should not have hyperlink to innography, as it is not supported (yet).");
            Assert.AreEqual($"{criticalDates.Row1.EventDescription} ({criticalDates.Row1.PriorityCountry})", caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesEventDescriptionColumn), "Critical Dates Section: Row 1: Should be priority event with country.");

            Assert.AreEqual(criticalDates.Row2.EventDescription, caseCriticalDates.CriticalDatesGrid.CellText(1, CriticalDatesEventDescriptionColumn), "Critical Dates Section: Row 2: Should be the date description in display sequence 2");

            Assert.AreEqual($"Next Event Due ({criticalDates.Row3.EventDescription})", caseCriticalDates.CriticalDatesGrid.CellText(2, CriticalDatesEventDescriptionColumn), "Critical Dates Section: Row 3: Should be the Next Event date description");
            Assert.AreEqual($"Last Event ({criticalDates.Row4.EventDescription})", caseCriticalDates.CriticalDatesGrid.CellText(3, CriticalDatesEventDescriptionColumn), "Critical Dates Section: Row 4: Should be the Last Event date description");
        }

        void TestCaseFileLocations(NgWebDriver driver, dynamic fileLocations)
        {
            var caseFileFileLocationsTopic = new CaseFileLocationsTopic(driver);
            Assert.True(caseFileFileLocationsTopic.FileLocationsGrid.Grid.Displayed, "File Location Section is showing");

            caseFileFileLocationsTopic.FileLocationsGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(2, caseFileFileLocationsTopic.FileLocationsGrid.Rows.Count, "File Location Section: should show 2 rows");
            Assert.AreEqual(fileLocations.caseLocation1.FileLocation.Name, caseFileFileLocationsTopic.FileLocationsGrid.CellText(0, 1), "File Location Section: Row 1: Should be File Location");
            Assert.AreEqual(fileLocations.caseLocation1.BayNo, caseFileFileLocationsTopic.FileLocationsGrid.CellText(1, 2), "File Location Section: Row 1: Should be Bay No");
            Assert.AreEqual(fileLocations.caseLocation2.FileLocation.Name, caseFileFileLocationsTopic.FileLocationsGrid.CellText(1, 1), "File Location Section: Row 1: Should be File Location");
            Assert.AreEqual(fileLocations.caseLocation2.BayNo, caseFileFileLocationsTopic.FileLocationsGrid.CellText(0, 2), "File Location Section: Row 1: Should be Bay No");
        }

        void TestCaseFileLocationHistory(NgWebDriver driver, dynamic fileLocations)
        {
            var history = new CaseFileLocationsHistory(driver);
            Assert.True(history.FileLocationsGrid.Grid.Displayed, "File Location Section is showing");
            Assert.True(history.HistoryButton.Enabled);
            history.ShowHistory();
            driver.WaitForAngular();
            Assert.NotNull(history.Modal);
            Assert.AreEqual(true, history.ModalCancel.Enabled);
            Assert.AreEqual("File Location History", history.ModalTitle.Text);
            history.FileLocationsGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(5, history.FileLocationsGrid.Rows.Count, "File Location Section: should show 5 rows");
            Assert.AreEqual(fileLocations.caseLocation1.FileLocation.Name, history.FileLocationsGrid.CellText(0, 1), "File Location Section: Row 1: Should be File Location");
            history.CloseHistoryModal();
            Assert.Throws<NoSuchElementException>(() => driver.FindElement(By.CssSelector(".modal-dialog")), "Ensure File Location History modal is not visible");
        }

        void TestCaseDesignElements(NgWebDriver driver, dynamic designElements)
        {
            var caseDesignElements = new CaseDesignElementsTopic(driver);
            Assert.True(caseDesignElements.DesignElementsGrid.Grid.Displayed, "Design Element Section is showing");

            caseDesignElements.DesignElementsGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(4, caseDesignElements.DesignElementsGrid.Rows.Count, "Design Element Section: should show 4 rows");

            Assert.AreEqual(designElements.designElement1.FirmElementId, caseDesignElements.DesignElementsGrid.CellText(0, 1), "Design Element Section: Row 1: Should be Firm Element ID");
            Assert.AreEqual(designElements.designElement1.ClientElementId, caseDesignElements.DesignElementsGrid.CellText(0, 2), "Design Element Section: Row 1: Should be Firm Client Ref ID");
            Assert.AreEqual(designElements.designElement2.FirmElementId, caseDesignElements.DesignElementsGrid.CellText(1, 1), "Design Element Section: Row 2: Should be Firm Element ID");
            Assert.AreEqual(designElements.designElement2.ClientElementId, caseDesignElements.DesignElementsGrid.CellText(1, 2), "Design Element Section: Row 2: Should be Firm Client Ref ID");

            /* Need to be looked in detail. Behaviour need to debugged fixed. 
            caseDesignElements.DesignElementsGrid.ToggleDetailsRow(2);
            var imageDetail = new DesignElementsImageDetail(driver, caseDesignElements.DesignElementsGrid.DetailRows[0]);
            Assert.IsTrue(imageDetail.Image.Displayed);
            */
        }

        void TestDeadPatentCriticalDates(NgWebDriver driver, dynamic criticalDates)
        {
            var caseCriticalDates = new CaseCriticalDatesTopic(driver);
            Assert.True(caseCriticalDates.CriticalDatesGrid.Grid.Displayed, "Critical Dates Section is showing");

            caseCriticalDates.CriticalDatesGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(4, caseCriticalDates.CriticalDatesGrid.Rows.Count, "Critical Dates Section: should show 4 rows");

            Assert.AreEqual(criticalDates.Row1.PriorityDate, caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesDateColumn), "Critical Dates Section: Row 1: Should be priority date");
            Assert.AreEqual(criticalDates.Row1.PriorityNumber, caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesOfficialNumberColumn), "Critical Dates Section: Row 1: Should be priority number");
            Assert.NotNull(caseCriticalDates.CriticalDatesGrid.Cell(0, CriticalDatesOfficialNumberColumn).FindElement(By.TagName("a")), "Patent cases should have hyperlink to innography, as it is not supported (yet).");
            Assert.AreEqual($"{criticalDates.Row1.EventDescription} ({criticalDates.Row1.PriorityCountry})", caseCriticalDates.CriticalDatesGrid.CellText(0, CriticalDatesEventDescriptionColumn), "Critical Dates Section: Row 1: Should be priority event with country.");

            Assert.AreEqual(criticalDates.Row2.EventDescription, caseCriticalDates.CriticalDatesGrid.CellText(1, CriticalDatesEventDescriptionColumn), "Critical Dates Section: Row 2: Should be the date description in display sequence 2");

            Assert.AreEqual($"Next Event Due ({criticalDates.Row3.EventDescription})", caseCriticalDates.CriticalDatesGrid.CellText(2, CriticalDatesEventDescriptionColumn), "Critical Dates Section: Row 3: Should be the Next Event date description");
            Assert.AreEqual($"Last Event ({criticalDates.Row4.EventDescription})", caseCriticalDates.CriticalDatesGrid.CellText(3, CriticalDatesEventDescriptionColumn), "Critical Dates Section: Row 4: Should be the Last Event date description");
        }

        void TestHistoryPopupModal(NgWebDriver driver, dynamic caseTexts, string irn)
        {
            var goodsServicesTopic = new CaseTextTopic(driver, caseTexts.GoodsServices.TopicContextKey);
            Assert.True(goodsServicesTopic.CaseTextGrid.Grid.Displayed, "Goods Services  Text Section is showing");

            goodsServicesTopic.CaseTextGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(1, goodsServicesTopic.CaseTextGrid.Rows.Count, "should show 1 row");
            var linkButton = goodsServicesTopic.CaseTextGrid.Cell(0, 1).FindElement(By.TagName("a"));
            Assert.True(linkButton != null, "link button should appear");
            linkButton.Click();

            var goodsServicesModal = new CaseTextHistoryModal(driver);
            Assert.True(goodsServicesModal != null, "history text modal should appear");
            Assert.AreEqual(irn, goodsServicesModal.IrnLabelText, "should display correct case irn");

            var caseHistoryGrid = goodsServicesModal.GoodsServicesGrid;
            Assert.True(caseHistoryGrid.Grid.Displayed, "History Grid is showing");
            Assert.AreEqual(2, caseHistoryGrid.Rows.Count, "should display correct number of history");

            var toggleButton = goodsServicesModal.GoodsServicesGrid.HeaderColumn("text").FindElement(By.TagName("label"));
            var addedText = goodsServicesModal.GoodsServicesGrid.Cell(0, 1).FindElement(By.ClassName("diff-added")).Text;
            var deletedText = goodsServicesModal.GoodsServicesGrid.Cell(0, 1).FindElement(By.ClassName("diff-deleted")).Text;
            Assert.AreEqual(caseTexts.GoodsServices.Row1.Notes, addedText, "Should display added text with styles");
            Assert.AreEqual(caseTexts.GoodsServices.Row2.Notes, deletedText, "Should display added text with styles");
            toggleButton.Click();
            var hasDeleted = goodsServicesModal.GoodsServicesGrid.Cell(0, 1).FindElements(By.ClassName("diff-deleted"));
            Assert.IsTrue(hasDeleted.Count == 0, "should hide comparsion");

            goodsServicesModal.Close();

            DbSetup.Do(x =>
            {
                var textHistorySiteControl = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.KEEPSPECIHISTORY);
                textHistorySiteControl.BooleanValue = false;
                x.DbContext.SaveChanges();
            });

            ReloadPage(driver, true);
            var goodsServicesTopic2 = new CaseTextTopic(driver, caseTexts.GoodsServices.TopicContextKey);
            Assert.True(goodsServicesTopic2.CaseTextGrid.Grid.Displayed, "Goods Services  Text Section is showing");
            goodsServicesTopic.CaseTextGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(1, goodsServicesTopic.CaseTextGrid.Rows.Count, "should show 1 row");
            var linkButton2 = goodsServicesTopic.CaseTextGrid.Cell(0, 1).FindElements(By.TagName("a"));
            Assert.True(linkButton2.Count == 0, "link button shouldn't  appear");
            DbSetup.Do(x =>
            {
                var textHistorySiteControl = x.DbContext.Set<SiteControl>().Single(_ => _.ControlId == SiteControls.KEEPSPECIHISTORY);
                textHistorySiteControl.BooleanValue = true;
                x.DbContext.SaveChanges();
            });
            ReloadPage(driver, true);
        }

        void TestPendingTrademarkTexts(NgWebDriver driver, dynamic caseTexts)
        {
            var combinedTextTopic = new CaseTextTopic(driver, caseTexts.CombinedText.TopicContextKey);

            Assert.True(combinedTextTopic.CaseTextGrid.Grid.Displayed, "Combined Text Section is showing");
            combinedTextTopic.CaseTextGrid.Grid.WithJs().ScrollIntoView();
            Assert.AreEqual(2, combinedTextTopic.CaseTextGrid.Rows.Count, "Combined Section: should show 2 rows");
            Assert.AreEqual(2, combinedTextTopic.NumberOfRecords(), "Number of records is shown correctly");

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
            Assert.AreEqual(4, caseTextTopic.CaseTextGrid.Rows.Count, "Case Text Section: should show 4 rows");

            Assert.AreEqual(caseTexts.Row1.Type, caseTextTopic.CaseTextGrid.CellText(0, TextTypeColumn), "Case Text Section: Row 1: Should be text type");
            Assert.True(caseTextTopic.CaseTextGrid.Cell(0, TextNotesColumn).FindElements(By.CssSelector("span br")).Count == 1, "Case Text Section: Row 1: line break should be changed to <br>");
            Assert.AreEqual(caseTexts.Row1.Notes, caseTextTopic.CaseTextGrid.CellText(0, TextNotesColumn), "Case Text Section: Row 1: Should be note column");

            Assert.AreEqual(caseTexts.Row2.Type, caseTextTopic.CaseTextGrid.CellText(1, TextTypeColumn), "Case Text Section: Row 2: Should be text type");
            Assert.AreEqual(caseTexts.Row2.Notes, caseTextTopic.CaseTextGrid.Cell(1, TextNotesColumn).FindElement(By.CssSelector("span strong")).Text, "Case Text Section: Row 2: Should be note column");

            Assert.AreEqual(caseTexts.Row3.Type, caseTextTopic.CaseTextGrid.CellText(2, TextTypeColumn), "Case Text Section: Row 3: Should be text type");
            Assert.AreEqual(caseTexts.Row3.Notes, caseTextTopic.CaseTextGrid.CellText(2, TextNotesColumn), "Case Text Section: Row 3: Should be note column");
            Assert.AreEqual(caseTexts.Row3.Language, caseTextTopic.CaseTextGrid.CellText(2, TextLanguageColumn), "Case Text Section: Row 3: Should be language column");

            Assert.AreEqual(caseTexts.Row4.Type, caseTextTopic.CaseTextGrid.CellText(3, TextTypeColumn), "Case Text Section: Row 4: Should be text type");
            Assert.AreEqual(caseTexts.Row4.Notes, caseTextTopic.CaseTextGrid.CellText(3, TextNotesColumn), "Case Text Section: Row 4: Should be note column");
            Assert.AreEqual(caseTexts.Row4.Language, caseTextTopic.CaseTextGrid.CellText(3, TextLanguageColumn), "Case Text Section: Row 4: Should be language column");
        }

        void TestPendingTrademarkEvents(NgWebDriver driver, dynamic events, dynamic due, string maxImportanceLevel)
        {
            var caseViewEvents = new CaseEventsTopic(driver);
            var dateColIndex = 4;
            var eventColIndex = 5;
            TestOccurred();
            TestDue();
            ReloadPage(driver, true);
            Assert.AreEqual(maxImportanceLevel, caseViewEvents.OccurredImportanceLevel.Text);
            Assert.AreEqual(maxImportanceLevel, caseViewEvents.DueImportanceLevel.Text);

            void TestOccurred()
            {
                caseViewEvents.OccurredDatesGrid.Grid.WithJs().ScrollIntoView();
                Assert.True(caseViewEvents.OccurredDatesGrid.Grid.Displayed, "Events Occurred Dates Section is showing");

                Assert.AreEqual(3, caseViewEvents.OccurredDatesGrid.Rows.Count, "Event Occurred Dates Section: should show 3 rows");

                Assert.AreEqual(events.Row1.EventDate, caseViewEvents.OccurredDatesGrid.CellText(0, dateColIndex), "Event Occurred Dates Section: Row 1: Should be the most recent occurred event date");
                Assert.AreEqual(events.Row1.EventDescription, caseViewEvents.OccurredDatesGrid.CellText(0, eventColIndex), "Event Occurred Dates Section: Row 1: Should be the most recent occurred event date description");

                Assert.AreEqual(events.Row2.EventDate, caseViewEvents.OccurredDatesGrid.CellText(1, dateColIndex), "Event Occurred Dates Section: Row 2: Should be cycle 2 of the event date");
                Assert.AreEqual(events.Row2.EventDescription, caseViewEvents.OccurredDatesGrid.CellText(1, eventColIndex), "Event Occurred Dates Section: Row 2: Should be cycle 2 of the event date description");

                Assert.AreEqual(events.Row3.EventDate, caseViewEvents.OccurredDatesGrid.CellText(2, dateColIndex), "Event Occurred Dates Section: Row 3: Should be cycle 1 of the event date");
                Assert.AreEqual(events.Row3.EventDescription, caseViewEvents.OccurredDatesGrid.CellText(2, eventColIndex), "Event Occurred Dates Section: Row 3: Should be cycle 1 of the event date description");

                Assert.AreEqual(true, caseViewEvents.OccurredDatesGrid.HeaderColumnsFields.Contains("hasNotes"), "Note column should hide at the begining");
                Assert.AreEqual(false, caseViewEvents.OccurredDatesGrid.HeaderColumnsFields.Contains("defaultEventText"), "Note column should hide at the begining");

                caseViewEvents.OccurredDatesGrid.Rows[0].FindElements(By.TagName("td"))[0].FindElement(By.TagName("a")).ClickWithTimeout();
                var otherDetails = caseViewEvents.OccurredDatesGrid.DetailRows[0].FindElement(By.CssSelector("ipx-event-other-details div.content"));
                Assert.True(otherDetails != null, "Other details should shown");

                var date = otherDetails.FindElements(By.CssSelector("ipx-date")).FirstOrDefault();
                Assert.False(date == null, "due date should be shown for event");

                var links = otherDetails.FindElements(By.TagName("a"));
                Assert.AreEqual(1, links.Count, "correct number of hyperlinks showing");
                Assert.AreEqual(events.Row3.FromCaseIrn, links[0].Text, "should have correct text");

                caseViewEvents.SelectOccurredImportanceLevel(maxImportanceLevel);
                caseViewEvents.OccurredDatesGrid.Grid.WithJs().ScrollIntoView();
                Assert.AreEqual(2, caseViewEvents.OccurredDatesGrid.Rows.Count, "Event Occurred Dates Section: should show 2 rows on higher importance");
            }

            void TestDue()
            {
                caseViewEvents.DueDatesGrid.Grid.WithJs().ScrollIntoView();
                Assert.True(caseViewEvents.DueDatesGrid.Grid.Displayed, "Events Due Dates Section is showing");

                Assert.AreEqual(3, caseViewEvents.DueDatesGrid.Rows.Count, "Event Due Dates Section: should show 3 rows");

                Assert.AreEqual(due.Row1.EventDate, caseViewEvents.DueDatesGrid.CellText(0, dateColIndex), "Event Occurred Dates Section: Row 1: Should be the most recent occurred event date");
                Assert.AreEqual(due.Row1.EventDescription, caseViewEvents.DueDatesGrid.CellText(0, eventColIndex), "Event Occurred Dates Section: Row 1: Should be the most recent occurred event date description");

                Assert.AreEqual(due.Row2.EventDate, caseViewEvents.DueDatesGrid.CellText(1, dateColIndex), "Event Occurred Dates Section: Row 2: Should be cycle 2 of the event date");
                Assert.AreEqual(due.Row2.EventDescription, caseViewEvents.DueDatesGrid.CellText(1, eventColIndex), "Event Occurred Dates Section: Row 2: Should be cycle 2 of the event date description");

                Assert.AreEqual(due.Row3.EventDate, caseViewEvents.DueDatesGrid.CellText(2, dateColIndex), "Event Occurred Dates Section: Row 3: Should be cycle 1 of the event date");
                Assert.AreEqual(due.Row3.EventDescription, caseViewEvents.DueDatesGrid.CellText(2, eventColIndex), "Event Occurred Dates Section: Row 3: Should be cycle 1 of the event date description");

                Assert.AreEqual(true, caseViewEvents.DueDatesGrid.HeaderColumnsFields.Contains("hasNotes"), "Note column should hide at the begining");
                Assert.AreEqual(false, caseViewEvents.DueDatesGrid.HeaderColumnsFields.Contains("defaultEventText"), "Note column should hide at the begining");

                caseViewEvents.DueDatesGrid.Rows[2].FindElements(By.TagName("td"))[0].FindElement(By.TagName("a")).ClickWithTimeout();
                var otherDetails = caseViewEvents.DueDatesGrid.DetailRows[0].FindElement(By.CssSelector("ipx-event-other-details div.content"));
                Assert.True(otherDetails != null, "Other details should shown");

                var labels = otherDetails.FindElements(By.CssSelector("label"));
                Assert.AreEqual(labels.Count, 2, "correct number of labels showing");

                var date = otherDetails.FindElements(By.CssSelector("ipx-date")).FirstOrDefault();
                Assert.True(date == null, "due date shouldn't be shown for for event");

                var links = otherDetails.FindElements(By.TagName("a"));
                Assert.AreEqual(links.Count, 2, "correct number of hyperlinks showing");
                Assert.True(links[0].Text.IndexOf(events.Row3.ResponseFirstName) > -1, "should have correct name");
                Assert.True(links[0].GetAttribute("href").IndexOf(events.Row3.EmployeeNo.ToString()) > -1, "should have correct url value");
                Assert.AreEqual(events.Row3.FromCaseIrn, links[1].Text, "should have correct Case text");

                caseViewEvents.SelectDueImportanceLevel(maxImportanceLevel);
                Assert.AreEqual(0, caseViewEvents.DueDatesGrid.Rows.Count, "Event Due Dates Section: should show 0 rows on higher importance");
            }
        }

        void TestPendingTrademarkRelatedCases(NgWebDriver driver, dynamic relatedCases)
        {
            var caseRelatedCases = new CaseRelatedCasesTopic(driver);
            caseRelatedCases.RelatedCasesGrid.Grid.WithJs().ScrollIntoView();

            Assert.True(caseRelatedCases.RelatedCasesGrid.Grid.Displayed, "Related Case Section is showing");
            Assert.AreEqual(2, caseRelatedCases.RelatedCasesGrid.Rows.Count, "Related Case: Should show 2 relateds cases.");
            Assert.AreEqual(2, caseRelatedCases.NumberOfRecords(), "Number of records is shown correctly");

            Assert.Throws<NoSuchElementException>(() => caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.FileIcon).FindElement(By.CssSelector(".cpa-icon-file-instruct")), "Related Case: Should have not have a file icon");

            Assert.AreEqual(relatedCases.Row1.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.Relationship).Text, "Related Case: Should show priority relationship");
            Assert.AreEqual(relatedCases.Row1.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.InternalRef).Text, "Related Case: Should not have a case ref");
            Assert.AreEqual(relatedCases.Row1.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.OfficialNumber).Text, "Related Case: Should show priority number");
            Assert.AreEqual(relatedCases.Row1.Jurisdiction, caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.Jurisdiction).Text, "Related Case: Should show priority jurisdiction");
            Assert.AreEqual(relatedCases.Row1.Date, caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.EventDate).Text, "Related Case: Should show priority date");

            var fileIcon = caseRelatedCases.RelatedCasesGrid.Cell(1, (int) RCIndex.FileIcon).FindElement(By.CssSelector(".cpa-icon-file-instruct"));
            Assert.NotNull(fileIcon, "Related Case: Should have a file icon");
            Assert.False(fileIcon.GetParent().Enabled, "Related Case: Should have a disabled file icon");
            Assert.AreEqual(relatedCases.Row2.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(1, (int) RCIndex.Relationship).Text, "Related Case: Should show foreign convention claim relationship");
            Assert.AreEqual(relatedCases.Row2.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(1, (int) RCIndex.InternalRef).Text, "Related Case: Should show foreign convention claim case ref");
            Assert.AreEqual(relatedCases.Row2.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(1, (int) RCIndex.OfficialNumber).Text, "Related Case: Should show foreign convention claim number");
        }

        void TestDeadPatentRelatedCases(NgWebDriver driver, dynamic relatedCases)
        {
            var caseRelatedCases = new CaseRelatedCasesTopic(driver);
            caseRelatedCases.RelatedCasesGrid.Grid.WithJs().ScrollIntoView();

            Assert.True(caseRelatedCases.RelatedCasesGrid.Grid.Displayed, "Related Case Section is showing");

            Assert.AreEqual(5, caseRelatedCases.RelatedCasesGrid.Rows.Count, "Related Case Section should have 5 rows");

            Assert.AreEqual(relatedCases.Row1.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.Relationship).Text, "Related Case: Should show priority relationship");
            Assert.AreEqual(relatedCases.Row1.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.InternalRef).Text, "Related Case: Should not have a case ref");
            Assert.AreEqual(relatedCases.Row1.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.OfficialNumber).Text, "Related Case: Should show priority number");
            Assert.AreEqual(relatedCases.Row1.Jurisdiction, caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.Jurisdiction).Text, "Related Case: Should show priority jurisdiction");
            Assert.AreEqual(relatedCases.Row1.Date, caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.EventDate).Text, "Related Case: Should show priority date");
            Assert.True(caseRelatedCases.RelatedCasesGrid.Cell(0, (int) RCIndex.OfficialNumber).FindElements(By.TagName("a")).Count == 1, "Related Case: priority number should be hyperlink");

            Assert.NotNull(caseRelatedCases.RelatedCasesGrid.Cell(1, (int) RCIndex.Direction).FindElement(By.CssSelector(".cpa-icon-arrow-up")), "Related Case: P1 - Should show arrow pointing up");
            Assert.AreEqual(relatedCases.Row2.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(1, (int) RCIndex.Relationship).Text, "Related Case: P1 - Should show first point to parent relationship");
            Assert.AreEqual(relatedCases.Row2.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(1, (int) RCIndex.InternalRef).Text, "Related Case: P1 - Should have a case ref hyperlink");
            Assert.AreEqual(relatedCases.Row2.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(1, (int) RCIndex.OfficialNumber).Text, "Related Case: P1 - Should not have a number");
            Assert.AreEqual(relatedCases.Row2.Jurisdiction, caseRelatedCases.RelatedCasesGrid.Cell(1, (int) RCIndex.Jurisdiction).Text, "Related Case: P1 - Should have jurisdiction against the related case");
            Assert.AreEqual(relatedCases.Row2.Date, caseRelatedCases.RelatedCasesGrid.Cell(1, (int) RCIndex.EventDate).Text, "Related Case: P1 - Should have event date from related case");

            Assert.NotNull(caseRelatedCases.RelatedCasesGrid.Cell(2, (int) RCIndex.Direction).FindElement(By.CssSelector(".cpa-icon-arrow-down")), "Related Case: C1 - Should show arrow pointing down");
            Assert.AreEqual(relatedCases.Row3.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(2, (int) RCIndex.Relationship).Text, "Related Case: C1 - Should show first point to child relationship");
            Assert.AreEqual(relatedCases.Row3.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(2, (int) RCIndex.InternalRef).Text, "Related Case: C1 - Should have a case ref");
            Assert.AreEqual(relatedCases.Row3.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(2, (int) RCIndex.OfficialNumber).Text, "Related Case: C1 - Should not have number");
            Assert.AreEqual(relatedCases.Row3.Jurisdiction, caseRelatedCases.RelatedCasesGrid.Cell(2, (int) RCIndex.Jurisdiction).Text, "Related Case: C1 - Should have jurisdiction against the related case");
            Assert.AreEqual(relatedCases.Row3.Date, caseRelatedCases.RelatedCasesGrid.Cell(2, (int) RCIndex.EventDate).Text, "Related Case: C1 - Should have event date from related case");

            Assert.NotNull(caseRelatedCases.RelatedCasesGrid.Cell(3, (int) RCIndex.Direction).FindElement(By.CssSelector(".cpa-icon-arrow-down")), "Related Case: C2 - Should show arrow pointing down");
            Assert.AreEqual(relatedCases.Row4.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(3, (int) RCIndex.Relationship).Text, "Related Case: C2 - Should show second point to child relationship");
            Assert.AreEqual(relatedCases.Row4.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(3, (int) RCIndex.InternalRef).Text, "Related Case: C2 - Should not have a case ref as this is an external case");
            Assert.AreEqual(relatedCases.Row4.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(3, (int) RCIndex.OfficialNumber).Text, "Related Case: C2 - Should have end user entered number");
            Assert.AreEqual(relatedCases.Row4.Jurisdiction, caseRelatedCases.RelatedCasesGrid.Cell(3, (int) RCIndex.Jurisdiction).Text, "Related Case: C2 - Should have end user entered jurisdiction");
            Assert.AreEqual(relatedCases.Row4.Date, caseRelatedCases.RelatedCasesGrid.Cell(3, (int) RCIndex.EventDate).Text, "Related Case: C2 - Should have priority date from relationship");
            Assert.AreEqual(relatedCases.Row4.Classes, caseRelatedCases.RelatedCasesGrid.Cell(3, (int) RCIndex.Classes).Text, "Related Case: C2 - Should have classes from relationship");

            Assert.NotNull(caseRelatedCases.RelatedCasesGrid.Cell(4, (int) RCIndex.Direction).FindElement(By.CssSelector(".cpa-icon-arrow-up")), "Related Case: P2 - Should show arrow pointing up");
            Assert.AreEqual(relatedCases.Row5.Relationship, caseRelatedCases.RelatedCasesGrid.Cell(4, (int) RCIndex.Relationship).Text, "Related Case: P2 - Should show second point to paretn relationship");
            Assert.AreEqual(relatedCases.Row5.CaseRef, caseRelatedCases.RelatedCasesGrid.Cell(4, (int) RCIndex.InternalRef).Text, "Related Case: P2 - Should have a case ref from the first case");
            Assert.AreEqual(relatedCases.Row5.OfficialNumber, caseRelatedCases.RelatedCasesGrid.Cell(4, (int) RCIndex.OfficialNumber).Text, "Related Case: P2 - Should not have a number from the first case");
            Assert.AreEqual(relatedCases.Row5.Jurisdiction, caseRelatedCases.RelatedCasesGrid.Cell(4, (int) RCIndex.Jurisdiction).Text, "Related Case: P2 - Should have a jurisdiction from the first case");
            Assert.AreEqual(relatedCases.Row5.Date, caseRelatedCases.RelatedCasesGrid.Cell(4, (int) RCIndex.EventDate).Text, "Related Case: P2 - Should have an event date from the first case");

            caseRelatedCases.RelatedCasesGrid.ToggleDetailsRow(3);
            var detailsC2 = new RelatedCaseOtherDetail(driver, caseRelatedCases.RelatedCasesGrid.DetailRows[0]);
            Assert.AreEqual(relatedCases.Row4.Title, detailsC2.Title, "Related Case: C2 - Should have title from relationship");
        }

        void TestOfficialNumbers(NgWebDriver driver, OfficialNumber ipOffice, OfficialNumber other, bool hasInnographyLink = false)
        {
            var officialNumber = new OfficialNumbersTopic(driver);
            var officialNoColIndex = 1;
            officialNumber.OtherNumbers.Grid.WithJs().ScrollIntoView();

            Assert.AreEqual(1, officialNumber.IpOfficeNumbers.Rows.Count);
            Assert.AreEqual(1, officialNumber.OtherNumbers.Rows.Count);
            Assert.AreEqual(ipOffice.Number, officialNumber.IpOfficeNumbers.CellText(0, officialNoColIndex));
            Assert.AreEqual(other.Number, officialNumber.OtherNumbers.CellText(0, officialNoColIndex));

            Assert.NotNull(officialNumber.OtherNumbers.Cell(0, officialNoColIndex).FindElements(By.TagName("a")).Count == 0, "Other Numbers should not have hyperlink to innography");

            Assert.NotNull(officialNumber.IpOfficeNumbers.Cell(0, officialNoColIndex).FindElements(By.TagName("a")).Count == (hasInnographyLink ? 1 : 0), "Patent cases should have hyperlink to innography, others are not supported (yet).");
        }

        void TestDeadPatentDesignatedJurisdiction(NgWebDriver driver, dynamic designationJurisdiction)
        {
            var designationRow1 = (DesignatedJurisdictionData) designationJurisdiction.Row1.Case;
            var designationRow2 = (DesignatedJurisdictionData) designationJurisdiction.Row2.Case;
            var jurisdictionTopic = new DesignatedJurisdictionTopic(driver);
            jurisdictionTopic.DesignatedJurisdictionGrid.Grid.WithJs().ScrollIntoView();

            Assert.True(jurisdictionTopic.DesignatedJurisdictionGrid.Grid.Displayed, "Designated Jurisdiction Section is showing");

            Assert.AreEqual(2, jurisdictionTopic.DesignatedJurisdictionGrid.Rows.Count, "Designated Jurisdiction Section should have 2 rows");
            Assert.AreEqual(2, jurisdictionTopic.NumberOfRecords(), "Number of records is shown correctly");
            Assert.AreEqual(10 + 3, jurisdictionTopic.DesignatedJurisdictionGrid.HeaderColumns.Count);
            Assert.AreEqual(-1, jurisdictionTopic.DesignatedJurisdictionGrid.HeaderColumns.ToList().FindIndex(e => e.Text.Equals("Your Reference")));

            Assert.AreEqual(designationRow1.Jurisdiction, jurisdictionTopic.DesignatedJurisdictionGrid.Cell(0, (int) DJIndex.Jurisdication).Text, "Designated Jurisdiction: Should show Jurisdication");
            Assert.AreEqual(designationRow1.DesignatedStatus, jurisdictionTopic.DesignatedJurisdictionGrid.Cell(0, (int) DJIndex.DesignatedStatus).Text, "Designated Jurisdiction: Should show Designated Status");
            Assert.AreEqual(designationRow1.CaseStatus, jurisdictionTopic.DesignatedJurisdictionGrid.Cell(0, (int) DJIndex.CaseStatus).Text, "Designated Jurisdiction: Should show Case Status");
            Assert.AreEqual(designationRow1.InternalReference, jurisdictionTopic.DesignatedJurisdictionGrid.Cell(0, (int) DJIndex.InternalReference).Text, "Designated Jurisdiction: Should show Internal Reference");
            Assert.NotNull(jurisdictionTopic.DesignatedJurisdictionGrid.Cell(0, (int) DJIndex.InternalReference).FindElements(By.TagName("a")).FirstOrDefault());

            var fileIcon = jurisdictionTopic.DesignatedJurisdictionGrid.Cell(0, (int) DJIndex.FileIcon).FindElement(By.CssSelector(".cpa-icon-file-instruct"));
            Assert.NotNull(fileIcon, "Designated Jurisdiction: Should have a file icon");
            Assert.False(fileIcon.GetParent().Enabled, "Designated Jurisdiction: Should have a disabled file icon");

            Assert.AreEqual(designationRow2.Jurisdiction, jurisdictionTopic.DesignatedJurisdictionGrid.Cell(1, (int) DJIndex.Jurisdication).Text, "Designated Jurisdiction: Should show Jurisdication");
            Assert.AreEqual(designationRow2.DesignatedStatus, jurisdictionTopic.DesignatedJurisdictionGrid.Cell(1, (int) DJIndex.DesignatedStatus).Text, "Designated Jurisdiction: Should show Designated Status");
            Assert.AreEqual(designationRow2.CaseStatus, jurisdictionTopic.DesignatedJurisdictionGrid.Cell(1, (int) DJIndex.CaseStatus).Text, "Designated Jurisdiction: Should show Case Status");
            Assert.AreEqual(designationRow2.InternalReference, jurisdictionTopic.DesignatedJurisdictionGrid.Cell(1, (int) DJIndex.InternalReference).Text, "Designated Jurisdiction: Should show Internal Reference");

            Assert.Throws<NoSuchElementException>(() => jurisdictionTopic.DesignatedJurisdictionGrid.Cell(1, (int) DJIndex.FileIcon).FindElement(By.CssSelector(".cpa-icon-file-instruct")), "Designated Jurisdiction 2: Should have not have a file icon");

            TestFilters();
            var indexes = TestActionGridColumnOrder();
            TestColumnSelection();
            VerifyColumnOrder(indexes.jurisdictionIndexNew, indexes.statusIndexNew);
            TestDetails();

            (int jurisdictionIndexNew, int statusIndexNew) TestActionGridColumnOrder()
            {
                var columns = jurisdictionTopic.DesignatedJurisdictionGrid.HeaderColumns;
                var jurisdictionIndex = columns.ToList().FindIndex(e => e.Text.Equals("Jurisdiction"));
                var statusIndex = columns.ToList().FindIndex(e => e.Text.Equals("Designated Status"));
                Assert.True(jurisdictionIndex < statusIndex);

                if (!driver.Is(BrowserType.Ie)) //TODO: REVIEW
                {
                    new Actions(driver).DragAndDrop(columns[jurisdictionIndex], columns[statusIndex]).Perform();
                }

                var columns2 = jurisdictionTopic.DesignatedJurisdictionGrid.HeaderColumns;
                var jurisdictionIndex2 = columns2.ToList().FindIndex(e => e.Text.Equals("Jurisdiction"));
                var statusIndex2 = columns2.ToList().FindIndex(e => e.Text.Equals("Designated Status"));

                if (!driver.Is(BrowserType.Ie)) //TODO: REVIEW
                {
                    Assert.True(jurisdictionIndex2 > statusIndex2, "should have swap position after column change");
                }

                return (jurisdictionIndex2, statusIndex2);
            }

            void VerifyColumnOrder(int jurisdictionIndexNew, int statusIndexNew)
            {
                var columns = jurisdictionTopic.DesignatedJurisdictionGrid.HeaderColumns;
                var jurisdictionIndex = columns.ToList().FindIndex(e => e.Text.Equals("Jurisdiction"));
                var statusIndex = columns.ToList().FindIndex(e => e.Text.Equals("Designated Status"));
                Assert.AreEqual(jurisdictionIndexNew, jurisdictionIndex, "New Column Order is maintained");
                Assert.AreEqual(statusIndexNew, statusIndex, "New Column Order is maintained");
            }

            void TestColumnSelection()
            {
                AssertColumnsNotDisplayed("classes", "priorityDate", "isExtensionState", "instructorReference", "agentReference");

                jurisdictionTopic.ColumnSelector.ColumnMenuButtonClick();
                Assert.IsTrue(jurisdictionTopic.ColumnSelector.IsColumnChecked("jurisdiction"), "The column appears checked in the menu");

                jurisdictionTopic.ColumnSelector.ToggleGridColumn("jurisdiction");
                jurisdictionTopic.ColumnSelector.ColumnMenuButtonClick();
                AssertColumnsNotDisplayed("jurisdiction");

                jurisdictionTopic.ColumnSelector.ColumnMenuButtonClick();
                Assert.IsFalse(jurisdictionTopic.ColumnSelector.IsColumnChecked("jurisdiction"), "The column is unchecked in the menu");
                jurisdictionTopic.ColumnSelector.ToggleGridColumn("classes");
                jurisdictionTopic.ColumnSelector.ColumnMenuButtonClick();
                AssertColumnsIsVisible("classes");
                Assert.AreEqual(designationRow1.Classes.Replace(",", ", "), jurisdictionTopic.DesignatedJurisdictionGrid.Cell(0, (int) DJIndex.Classes).Text, "Classes should be shown with space in comma");

                ReloadPage(driver);
                jurisdictionTopic.DesignatedJurisdictionGrid.Grid.WithJs().ScrollIntoView();
                AssertColumnsNotDisplayed("jurisdiction");
                AssertColumnsIsVisible("classes");

                jurisdictionTopic.ColumnSelector.ColumnMenuButtonClick();
                jurisdictionTopic.ColumnSelector.ToggleGridColumn("jurisdiction");
                jurisdictionTopic.ColumnSelector.ToggleGridColumn("isExtensionState");
                jurisdictionTopic.ColumnSelector.ColumnMenuButtonClick();
                AssertColumnsIsVisible("isExtensionState");
                Assert.True(jurisdictionTopic.DesignatedJurisdictionGrid.CellIsSelected(0, (int) DJIndex.IsExtensionState));

                jurisdictionTopic.ColumnSelector.ColumnMenuButtonClick();
                jurisdictionTopic.ColumnSelector.ToggleGridColumn("agentReference");
                AssertColumnsIsVisible("agentReference");
                jurisdictionTopic.ColumnSelector.ColumnMenuButtonClick();
            }

            void AssertColumnsNotDisplayed(params string[] columnHeader)
            {
                foreach (var column in columnHeader) Assert.AreEqual(false, jurisdictionTopic.DesignatedJurisdictionGrid.HeaderColumn(column).Displayed, $"Hidden Column '{column}' should not be displayed");
            }

            void AssertColumnsIsVisible(params string[] columnHeader)
            {
                foreach (var column in columnHeader) Assert.AreEqual(true, jurisdictionTopic.DesignatedJurisdictionGrid.HeaderColumn(column).WithJs().IsVisible(), $"'{column}' Column should be displayed");
            }

            void TestFilters()
            {
                jurisdictionTopic.JurisdictionFilter.Open();
                Assert.AreEqual(2, jurisdictionTopic.JurisdictionFilter.ItemCount);

                jurisdictionTopic.JurisdictionFilter.SelectOption(designationRow1.Jurisdiction);
                jurisdictionTopic.JurisdictionFilter.Filter();
                Assert.AreEqual(1, jurisdictionTopic.DesignatedJurisdictionGrid.Rows.Count, "Designated Jurisdiction Section should have 1 rows");
                Assert.AreEqual(1, jurisdictionTopic.NumberOfRecords(), "Number of records is shown correctly");

                jurisdictionTopic.JurisdictionFilter.Open();
                jurisdictionTopic.JurisdictionFilter.Clear();

                jurisdictionTopic.CaseStatusFilter.Open();
                Assert.AreEqual(2, jurisdictionTopic.CaseStatusFilter.ItemCount);
                jurisdictionTopic.CaseStatusFilter.Clear();
                jurisdictionTopic.DesignatedStatusFilter.Open();
                Assert.AreEqual(2, jurisdictionTopic.DesignatedStatusFilter.ItemCount);

                jurisdictionTopic.DesignatedStatusFilter.SelectOption(designationRow1.DesignatedStatus);
                jurisdictionTopic.DesignatedStatusFilter.Filter();
                Assert.AreEqual(1, jurisdictionTopic.DesignatedJurisdictionGrid.Rows.Count, "Designated Jurisdiction Section should have 1 rows");
                Assert.AreEqual(1, jurisdictionTopic.NumberOfRecords(), "Number of records is shown correctly");

                jurisdictionTopic.JurisdictionFilter.Open();
                jurisdictionTopic.JurisdictionFilter.Clear();

                Assert.AreEqual(1, jurisdictionTopic.DesignatedJurisdictionGrid.Rows.Count, "Designated Jurisdiction Section should have 1 rows");
                Assert.AreEqual(1, jurisdictionTopic.NumberOfRecords(), "Number of records is shown correctly");

                jurisdictionTopic.CaseStatusFilter.Open();
                Assert.AreEqual(1, jurisdictionTopic.CaseStatusFilter.ItemCount);

                jurisdictionTopic.DesignatedStatusFilter.Open();
                jurisdictionTopic.DesignatedStatusFilter.Clear();
                Assert.AreEqual(2, jurisdictionTopic.DesignatedJurisdictionGrid.Rows.Count, "Designated Jurisdiction Section should have 2 rows");
                Assert.AreEqual(2, jurisdictionTopic.NumberOfRecords(), "Number of records is shown correctly");
            }

            void TestDetails()
            {
                var caseSummary1 = (OverviewSummary) designationJurisdiction.Row1.Details;
                var caseNames = caseSummary1.Names.ToDictionary(k => k.NameType, v => v);
                var criticalDates = caseSummary1.CriticalDates.Select(_ => _.EventDefinition);
                var classes = (List<CaseTextData>) designationJurisdiction.Row1.ClasssData;

                var rowIndex = 0;
                jurisdictionTopic.DesignatedJurisdictionGrid.ToggleDetailsRow(rowIndex);

                Assert.AreEqual(designationRow1.Notes, jurisdictionTopic.DesignatedJurisdictionGrid.DetailRows[rowIndex].FindElement(By.CssSelector(".full-width")).Text);
                Assert.True(caseSummary1.PropertyType.Contains(jurisdictionTopic.DesignatedJurisdictionGrid.DetailRows[rowIndex].FindElement(By.CssSelector("[translate='.propertyType']")).GetParent().GetSibling("div/span").Text));
                Assert.AreEqual(caseSummary1.CaseCategory ?? string.Empty, jurisdictionTopic.DesignatedJurisdictionGrid.DetailRows[rowIndex].FindElement(By.CssSelector("[translate='.caseCategory']")).GetParent().GetSibling("div/span").Text);
                Assert.AreEqual(caseSummary1.Title, jurisdictionTopic.DesignatedJurisdictionGrid.DetailRows[rowIndex].FindElement(By.CssSelector("[translate='.title']")).GetParent().GetSibling("div/span").Text);

                var namesDiv = jurisdictionTopic.DesignatedJurisdictionGrid.DetailRows[rowIndex].FindElement(By.Name("names")).FindElements(By.ClassName("row"));
                foreach (var name in namesDiv)
                {
                    var label = name.FindElement(By.TagName("label")).Text;
                    var span = (name.FindElements(By.TagName("a")).FirstOrDefault() ?? name.FindElements(By.TagName("span")).FirstOrDefault())?.Text;

                    Assert.True(caseNames.TryGetValue(label, out var expectedName));
                    Assert.AreEqual(expectedName.Name, span);
                }

                var criticalDatesDivs = jurisdictionTopic.DesignatedJurisdictionGrid.DetailRows[rowIndex].FindElements(By.CssSelector(".right-bold-label"));
                foreach (var date in criticalDates) Assert.True(criticalDatesDivs.Any(_ => _.Text == date));

                Assert.AreEqual(classes.Count, jurisdictionTopic.DesignatedJurisdictionClassesGrid.Rows.Count);
                for (var i = 0; i < classes.Count; i++)
                {
                    Assert.AreEqual(classes[i].TextClass, jurisdictionTopic.DesignatedJurisdictionClassesGrid.Cell(i, (int) ClassesIndex.Classes).Text, "Designated Jurisdiction: Should show Classes");
                    Assert.AreEqual(classes[i].Language ?? string.Empty, jurisdictionTopic.DesignatedJurisdictionClassesGrid.Cell(i, (int) ClassesIndex.Language).Text, "Designated Jurisdiction: Should show Language");
                    Assert.AreEqual(classes[i].Notes ?? string.Empty, jurisdictionTopic.DesignatedJurisdictionClassesGrid.Cell(i, (int) ClassesIndex.GoodsAndServices).Text, "Designated Jurisdiction: Should show Notes");
                }

                jurisdictionTopic.DesignatedJurisdictionGrid.ToggleDetailsRow(rowIndex);
            }
        }

        void TestProgramId(NgWebDriver driver, int caseId)
        {
            driver.Visit($"{Env.RootUrl}/#/caseview/{caseId.ToString()}?programId={KnownCasePrograms.CaseEnquiry}");

            var summary = new SummaryTopic(driver);
            Assert.Null(summary.NoScreenControlAlerts);
            var caseNames = new CaseNameTopic(driver);
            Assert.True(caseNames.CaseViewNameGrid.Grid.Displayed, "Names section is showing");

            driver.Visit($"{Env.RootUrl}/#/caseview/{caseId.ToString()}?programId={KnownCasePrograms.CaseOthers}");
            summary = new SummaryTopic(driver);
            Assert.NotNull(summary.NoScreenControlAlerts);
        }

        void TestImages(NgWebDriver driver)
        {
            var imagesTopic = new ImagesTopic(driver);
            Assert.True(imagesTopic.Displayed(), "Case Images section is showing.");

            var firstImage = imagesTopic.Images.First();
            Assert.AreEqual("Trade Mark", firstImage.Header, "Header is displayed correctly.");
            Assert.AreEqual("Firm Element Ref1", firstImage.FirmElement.Text, "Firm Element Case Ref is displayed correctly");
            driver.Hover(firstImage.DisplayedImage);

            Assert.AreEqual(10, imagesTopic.NumberOfRecords());

            var imageDesc = firstImage.Description;
            Assert.IsTrue(imageDesc.StartsWith("Trade Mark Image 1"), imageDesc, "Caption displays on hover over image. Image Desc: " + imageDesc);

            imagesTopic.ShowAllButton.WithJs().Click();
            Assert2.WaitTrue(3, 200, () => imagesTopic.ShowAllButton.Text == "Show Less");

            var lastImage = imagesTopic.Images.Last();
            driver.Hover(lastImage.DisplayedImage);
            var lastImageDesc = lastImage.Description;
            Assert.AreEqual(lastImageDesc, "Trade Mark Image 9", "Checking image 9 is there. Image Desc: " + lastImageDesc);
        }

        void TestRenewals(NgWebDriver driver, dynamic data)
        {
            var renewalTopic = new RenewalTopic(driver);
            Assert.True(renewalTopic.Displayed(), "Renewal section is showing.");

            Assert.AreEqual(data.Case.CaseStatus.Name, renewalTopic.CaseStatus.Text, "Renewal Topic - Case Status is displayed correctly as " + renewalTopic.CaseStatus.Text);
            Assert.AreEqual(data.Case.Property.RenewalStatus.Name, renewalTopic.RenewalStatus.Text, "Renewal Topic - Renew Status is displayed correctly as " + renewalTopic.RenewalStatus.Text);
            Assert.AreEqual(data.Case.ExtendedRenewals.ToString(), renewalTopic.ExtendedRenewalYears.Text, "Renewal Topic - Extended Renewal Years is displayed correctly as " + renewalTopic.ExtendedRenewalYears.Text);
            Assert.NotNull(renewalTopic.RenewalType.Text, "Renewal Topic - Renewal Type is displayed correctly as " + renewalTopic.RenewalType.Text);
            Assert.AreEqual(data.Case.Property.RenewalNotes, renewalTopic.Notes.Value(), "Renewal Notes is displayed correctly as " + renewalTopic.Notes.Value());
            if (renewalTopic.ReportToCpaCheckbox.IsChecked)
            {
                Assert.True(renewalTopic.StartPayingDivElement.Displayed, "On Report to CPA selection, more details are showing.");
            }

            var (date1, text1) = renewalTopic.ReleventDates.GetValueForRow(0);
            Assert.AreEqual(data.RenewalDetailsReleventDates[0].date, Convert.ToDateTime(date1));
            Assert.AreEqual(data.RenewalDetailsReleventDates[0].eventText, text1);

            var (date2, text2) = renewalTopic.ReleventDates.GetValueForRow(1);
            Assert.AreEqual(data.RenewalDetailsReleventDates[1].date, Convert.ToDateTime(date2));
            Assert.AreEqual(data.RenewalDetailsReleventDates[1].eventText, text2);

            var (instructionType, instruction) = renewalTopic.Instructions.GetValueForRow(0);
            Assert.AreEqual(data.RenewalInstructions.InstructionTypeDescription, instructionType);
            Assert.AreEqual(data.RenewalInstructions.Instruction, instruction);

            Assert.True(renewalTopic.RenewalNames.Grid.Displayed, "Renewal names is showing");
            Assert.AreEqual(3, renewalTopic.RenewalNames.Rows.Count, "Renewal names: should show only 3 renewal rows");

            renewalTopic.RenewalNames.ToggleDetailsRow(2);
            var detailSection = new RenewalTopic.DetailSection(driver, renewalTopic.RenewalNames, 0);

            Assert.AreNotEqual(string.Empty, detailSection.Address, "Details should contain address details");
        }

        void TestRenewalsPatent(NgWebDriver driver, dynamic data)
        {
            var renewalTopic = new RenewalTopic(driver);

            Assert.IsTrue(renewalTopic.ReportToCpaCheckbox.IsChecked);
            Assert.IsTrue(renewalTopic.IpPlatformRenewLink.EndsWith(data.IpplatformRenewLink));
        }

        void TestStandingInstructions(NgWebDriver driver, dynamic data)
        {
            var topic = new StandingInstructionsTopic(driver);
            topic.NavigateTo();

            var instructions = data.StandingInstructions;

            Assert.AreEqual(2, topic.NumberOfRecords(), "Standing Instructions Topic count is displayed as 2");
            Assert.AreEqual(2, topic.Grid.Rows.Count, "Standing instructions grid contains 2 records");

            CheckDataForRow(0);
            CheckDataForRow(1);

            topic.Grid.ToggleDetailsRow(0);
            var instructionDetails = topic.GetDetailsFor(0);

            Assert.AreEqual(instructions[0].Period1, topic.Grid.CellText(0, 4), $"Standing instructions - Period1 for row 0 should be displayed as {instructions[0].Period1}");
            Assert.AreEqual(instructions[0].Period2, topic.Grid.CellText(0, 5), $"Standing instructions - Period2 for row 0 should be displayed as {instructions[0].Period2}");
            Assert.AreEqual(instructions[0].Period3, topic.Grid.CellText(0, 6), $"Standing instructions - Period3 for row 0 should be displayed as {instructions[0].Period3}");

            Assert.AreEqual(instructions[0].Adjustment, instructionDetails.Adjustment, $"Standing instructions details, Adjustment should be displayed as {instructions[0].Adjustment}");
            Assert.AreEqual(instructions[0].Text, instructionDetails.StandingInstructionText, $"Standing instructions details, text should be displayed as {instructions[0].Text}");
            Assert.AreEqual(instructions[0].AdjustStartMonth, instructionDetails.AdjustStartMonth, $"Standing instructions details, Adjustmentment start month should be displayed as {instructions[0].AdjustStartMonth}");
            Assert.AreEqual(instructions[0].AdjustDay, instructionDetails.AdjustDay, $"Standing instructions details, Adjustment day should be displayed as {instructions[0].AdjustDay}");

            void CheckDataForRow(int rowIndex)
            {
                Assert.AreEqual(instructions[rowIndex].InstructionTypeDescription, topic.Grid.CellText(rowIndex, 1), $"Standing instructions - Instruction Type text for row {rowIndex} should be displayed as {instructions[rowIndex].InstructionTypeDescription}");
                Assert.AreEqual(instructions[rowIndex].Instruction, topic.Grid.CellText(rowIndex, 2), $"Standing instructions - Instruction text for row {rowIndex} should be displayed as {instructions[rowIndex].Instruction}");
                Assert.AreEqual(instructions[rowIndex].DefaultedFrom, topic.Grid.CellText(rowIndex, 3), $"Standing instructions - Defaulted From row {rowIndex} should be displayed as {instructions[rowIndex].DefaultedFrom}");
                Assert.AreEqual(1, topic.Grid.Cell(rowIndex, 3).FindElements(By.CssSelector("a")).Count, $"Standing instructions Defaulted From for row {rowIndex} should be displayed as a link");
            }
        }

        void PageTitleContainsIrn(NgWebDriver driver, string irn)
        {
            Assert.True(driver.Title.Contains(irn), "Irn is displayed as a prefix in page title");
        }

        void TestCustomContentTopic(NgWebDriver driver)
        {
            var customContentTopic = new CustomContentTopic(driver);
            customContentTopic.NavigateTo(0);
            Assert.IsTrue(customContentTopic.CustomContentTitle("Cpa Global").Displayed);
            customContentTopic.NavigateTo(1);
            Assert.IsTrue(customContentTopic.CustomContentTitle("Custom Content 2").Displayed);
            var errorMessage = driver.FindElement(By.XPath("//span[@class='login-alert login-alert-error']")).Text;
            Assert.AreEqual(errorMessage, "Unable to display the requested page because the url is invalid.");
        }

        void TestChecklistTopic(NgWebDriver driver, dynamic checklistData)
        {
            var caseChecklistTopic = new CaseChecklistTopic(driver);
            caseChecklistTopic.NavigateTo(0);
            Assert.IsTrue(caseChecklistTopic.CaseChecklists.Displayed, "The section is displayed");
            Assert.IsTrue(caseChecklistTopic.ChecklistType.IsDisplayed, "The Checklist Type combo box is displayed");
            Assert.IsTrue(caseChecklistTopic.CaseChecklistGrid.Grid.Displayed, "The Checklist grid is displayed");
            Assert.AreEqual(checklistData.ValidChecklist.ChecklistDescription, caseChecklistTopic.ChecklistType.Text, "The correct Checklist Type is selected");

            Assert.True(caseChecklistTopic.CaseChecklistGrid.HeaderColumns.ToList().Any(v => v.Text == "Yes / No"), "The Yes/ No column is shown");
            Assert.True(caseChecklistTopic.CaseChecklistGrid.HeaderColumns.ToList().Any(v => v.Text == "Date"), "The Date column is shown");
            Assert.True(caseChecklistTopic.CaseChecklistGrid.HeaderColumns.ToList().Any(v => v.Text == "Count"), "The Count column should be shown as it has value");
            Assert.True(caseChecklistTopic.CaseChecklistGrid.HeaderColumns.ToList().Any(v => v.Text == "Text"), "The Text column should not display as it's not configured");
            Assert.AreEqual(checklistData.CaseChecklist.CountAnswer, int.Parse(caseChecklistTopic.CaseChecklistGrid.Cell(0, 4).Text), "The count answer is correctly shown");
            Assert.AreEqual(checklistData.CaseChecklistEvent.EventDate.ToString("dd-MMM-yyyy"), caseChecklistTopic.CaseChecklistGrid.Cell(0, 3).Text, "The event date is correctly shown");

            Assert.AreEqual(checklistData.ChecklistItemQuestion.Question + (checklistData.ChecklistItemQuestion2.YesNoRequired != null ? " *" : string.Empty), caseChecklistTopic.CaseChecklistGrid.CellText(0, 1), "The correct Checklist question is shown");
            Assert.AreEqual(checklistData.ChecklistItemQuestion2.Question + (checklistData.ChecklistItemQuestion2.AmountRequired != null ? " *" : string.Empty), caseChecklistTopic.CaseChecklistGrid.CellText(1, 1), "The correct Checklist question is shown with mandatory sign");
            Assert.True(caseChecklistTopic.CaseChecklistGrid.Cell(0, 0).FindElements(By.ClassName("cpa-icon-check-circle")).Any(), "Processed Icon shown");
            Assert.True(caseChecklistTopic.CaseChecklistGrid.Cell(1, 0).FindElements(By.ClassName("cpa-icon-minus-circle")).Any(), "UnProcessed Icon shown");
            Assert.True(caseChecklistTopic.CaseChecklistGrid.Cell(2, 0).FindElements(By.ClassName("cpa-icon-arrow-right")).Any(), "Processed Icon shown");
            Assert.True(caseChecklistTopic.CaseChecklistGrid.Cell(2, 1).FindElements(By.ClassName("vertical")).Any(), "indent shown for child question");

            var processingInfo = caseChecklistTopic.CaseChecklistGrid.Cell(0, 1).FindElement(By.ClassName("inline-dialog"));
            Assert.True(processingInfo.Displayed, "The processing information tooltip is displayed when hovered over.");
        }
    }
}