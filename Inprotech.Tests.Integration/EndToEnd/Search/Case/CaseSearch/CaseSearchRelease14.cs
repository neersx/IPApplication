using System.Linq;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Queries;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Search.Case.CaseSearch
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "16.0")]
    [TestFrom(DbCompatLevel.Release14)]
    public class CaseSearchRelease14 : IntegrationTest
    {
        [SetUp]
        public void PrepareData()
        {
            _summaryData = DbSetup.Do(setup =>
            {
                var irnPrefix = Fixture.UriSafeString(5);
                var caseBuilder = new CaseSearchCaseBuilder(setup.DbContext);
                var data = caseBuilder.Build(irnPrefix);

                var textType = setup.InsertWithNewId(new TextType(Fixture.String(5)));
                data.Case.CaseTexts.Add(new CaseText(data.Case.Id, textType.Id, 0, null) { Text = Fixture.String(10), TextType = textType });

                var family = setup.InsertWithNewId(new Family
                {
                    Name = $"{RandomString.Next(3)},{RandomString.Next(3)}"
                });

                data.Case.Family = family;
                setup.DbContext.SaveChanges();

                return data;
            });
        }

        CaseSearchCaseBuilder.SummaryData _summaryData;

        void ClickCaseSearchBuilder(CaseSearchPageObject searchPage)
        {
            searchPage.CaseSearchMenuItem().WithJs().Click();
            Assert.IsTrue(searchPage.CaseSubMenu.Displayed);
            searchPage.CaseSearchBuilder().WithJs().Click();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchDataPatentTermAdjustments(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/portal2");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");

            searchPage.PatentTermAdjustments.NavigateTo();

            searchPage.PatentTermAdjustments.FromIpOfficeDelay.Input.SendKeys("1");
            searchPage.PatentTermAdjustments.ToIpOfficeDelay.Input.SendKeys("11");

            searchPage.PatentTermAdjustments.FromApplicantDelay.Input.SendKeys("11");
            searchPage.PatentTermAdjustments.ToApplicantDelay.Input.SendKeys("15");

            searchPage.CaseSearchButton.Click();
            Assert.AreEqual("/search-result?queryContext=2", driver.Location, "Should navigate to case search result page");

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "1 record is returned by search");
            searchResultPageObject.CloseButton().ClickWithTimeout();

            SearchResultWithNoRecord(searchPage, searchResultPageObject);
            CheckSearchResultForPtaDiscrepancies(searchPage, searchResultPageObject);

            searchPage.PatentTermAdjustments.NavigateTo();
            searchPage.PatentTermAdjustments.FromSuppliedPta.Input.SendKeys("10");
            searchPage.PatentTermAdjustments.ToSuppliedPta.Input.SendKeys("1");

            searchPage.PatentTermAdjustments.NavigateTo();
            searchPage.PatentTermAdjustments.FromSuppliedPta.Input.Clear();
            searchPage.PatentTermAdjustments.FromSuppliedPta.Input.SendKeys("abc");
        }

        void CheckSearchResultForPtaDiscrepancies(CaseSearchPageObject searchPage, SearchPageObject searchResultPageObject)
        {
            searchPage.PatentTermAdjustments.NavigateTo();

            searchPage.PatentTermAdjustments.FromIpOfficeDelay.Input.Clear();
            searchPage.PatentTermAdjustments.ToIpOfficeDelay.Input.Clear();

            searchPage.PatentTermAdjustments.FromApplicantDelay.Input.Clear();
            searchPage.PatentTermAdjustments.ToApplicantDelay.Input.Clear();

            searchPage.PatentTermAdjustments.PtaDiscrepancies.Click();
            searchPage.CaseSearchButton.Click();
            var grid = searchResultPageObject.ResultGrid;

            // e2e: HasDiscrepancy = TRUE if (coalesce(IPODELAY, 0) - coalesce(APPLICANTDELAY, 0)) != coalesce(IPOPTA, 0)
            if ((_summaryData.Case.IpoDelay ?? 0) - (_summaryData.Case.ApplicantDelay ?? 0) != (_summaryData.Case.IpoPta ?? 0))
            {
                Assert.AreEqual(1, grid.Rows.Count, "A single record is returned by search via PTA Discrepancy");
            }
            else
            {
                Assert.AreEqual(0, grid.Rows.Count, "Expected no records with PTA Discrepancy");
            }

            searchResultPageObject.CloseButton().ClickWithTimeout();
        }

        void SearchResultWithNoRecord(CaseSearchPageObject searchPage, SearchPageObject searchResultPageObject)
        {
            searchPage.PatentTermAdjustments.NavigateTo();

            searchPage.PatentTermAdjustments.FromApplicantDelay.Input.Clear();
            searchPage.PatentTermAdjustments.FromApplicantDelay.Input.SendKeys("13");
            searchPage.CaseSearchButton.Click();

            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(0, grid.Rows.Count, "No record is returned by search via Applicant Delay");
            searchResultPageObject.CloseButton().ClickWithTimeout();
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchResult(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            CaseSearchHelper.TestCaseSearchResults(_summaryData, driver);
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void CaseSearchDesignElements(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var caseId = _summaryData.Case.Id;

                return setup.Insert(new DesignElement(caseId, 0)
                {
                    ClientElementId = "ClientElement",
                    Description = "E2EDesignElementDesc",
                    FirmElementId = "FirmElement",
                    IsRenew = true,
                    OfficialElementId = "OfficialElement",
                    RegistrationNo = "RegNo"
                });
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#");

            var searchPage = new CaseSearchPageObject(driver);
            ClickCaseSearchBuilder(searchPage);
            Assert.AreEqual("/case/search", driver.Location, "Should navigate to case search page");
            searchPage.DesignElements.NavigateTo();

            searchPage.DesignElements.FirmElement.SendKeys(data.FirmElementId);
            searchPage.DesignElements.ClientElementReference.SendKeys(data.ClientElementId);
            searchPage.DesignElements.OfficialElement.SendKeys(data.OfficialElementId);
            searchPage.DesignElements.RegistrationNo.SendKeys(data.RegistrationNo);
            searchPage.DesignElements.Typeface.SendKeys(data.Typeface.ToString());
            searchPage.DesignElements.IsRenew.Click();
            searchPage.DesignElements.Description.SendKeys(data.Description);

            searchPage.CaseSearchButton.Click();
            Assert.AreEqual("/search-result?queryContext=2", driver.Location, "Should navigate to case search result page");

            var searchResultPageObject = new SearchPageObject(driver);
            var grid = searchResultPageObject.ResultGrid;
            Assert.AreEqual(1, grid.Rows.Count, "One record is returned by search");
            Assert.AreEqual(_summaryData.Case.Irn, grid.Cell(0, 2).Text, "Correct record is returned");
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void NamePickListFiltering(BrowserType browserType)
        {
            var data = DbSetup.Do(setup =>
            {
                var nameType = new NameTypeBuilder(setup.DbContext).Create();
                nameType.PickListFlags += KnownNameTypeAllowedFlags.SameNameType;
                var name = new NameBuilder(setup.DbContext).CreateClientOrg("AAA");
                name.NameTypeClassifications.Add(new NameTypeClassification(name, nameType) {IsAllowed = 1});

                var notSuitableForTheNameType = new NameBuilder(setup.DbContext).CreateClientOrg("AA");

                var ceasedName = new NameBuilder(setup.DbContext).CreateClientOrg("CEA");
                ceasedName.NameTypeClassifications.Add(new NameTypeClassification(ceasedName, nameType) {IsAllowed = 1});
                ceasedName.DateCeased = Fixture.PastDate();

                setup.DbContext.SaveChanges();

                return new
                {
                    NameType = nameType.Name,
                    ValidName = name.NameCode,
                    UnclassifiedName = notSuitableForTheNameType.NameCode,
                    CeasedName = ceasedName.NameCode
                };
            });

            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/case/search");

            var searchPage = new CaseSearchPageObject(driver);

            TestValidNameSelection();

            TestNameTypeClassificationFilter();

            TestCeasedNameFilterAndPreviewPaneToggle();

            void TestNameTypeClassificationFilter()
            {
                searchPage.Names.OtherName.EnterAndSelect(data.UnclassifiedName);

                searchPage.Names.OtherName.OpenPickList();
                Assert.AreEqual(0, searchPage.Names.OtherName.SearchGrid.Rows.Count, "Should not list names that are not classified for the name type");

                var removeNameTypeClassificationFilter = new AngularCheckbox(driver).ByName("filterNameTypes");
                removeNameTypeClassificationFilter.Click();

                Assert.AreEqual(1, searchPage.Names.OtherName.SearchGrid.Rows.Count, "Should list the name as name type filter has been turned off");

                removeNameTypeClassificationFilter.Click();
                Assert.AreEqual(0, searchPage.Names.OtherName.SearchGrid.Rows.Count, "Should unlist the name as name type filter has been turned back on");

                searchPage.Names.OtherName.Close();
                searchPage.Names.OtherName.Clear();
            }

            void TestCeasedNameFilterAndPreviewPaneToggle()
            {
                searchPage.Names.OtherName.EnterAndSelect(data.CeasedName);

                searchPage.Names.OtherName.OpenPickList();
                Assert.AreEqual(0, searchPage.Names.OtherName.SearchGrid.Rows.Count, "Should not list names that are ceased");

                Assert.True(searchPage.Names.OtherName.InfoBubble.Displayed, "Should display Info Bubble");
                var includeCeasedNameCheckBox = new AngularCheckbox(driver).ByName("includeCeased");
                includeCeasedNameCheckBox.Click();

                Assert.True(searchPage.Names.OtherName.SearchGrid.Rows[0].WithJs().HasClass("dim"), "Should show ceased name row dimmed");

                searchPage.Names.OtherName.TogglePreviewSwitch.Click();

                var rightPane = searchPage.Names.OtherName.ShowPreviewPane();
                Assert.AreEqual(true, rightPane.Displayed);

                searchPage.Names.OtherName.SearchGrid.SelectRow(0);
                searchPage.Names.OtherName.Apply();
                Assert.AreEqual(1, searchPage.Names.OtherName.Tags.Count(), "Should apply ceased name selection into the field");
            }

            void TestValidNameSelection()
            {
                searchPage.Names.NavigateTo();
                searchPage.Names.NameType.Input.SelectByText(data.NameType);
                searchPage.Names.OtherName.EnterAndSelect(data.ValidName);
                Assert.AreEqual(1, searchPage.Names.OtherName.Tags.Count());
            }
        }

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void NamePicklistFilteringForExternalUser(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            var externalUser = new Users().CreateExternalUser();
            SignIn(driver, "/#/case/search", externalUser.Username, externalUser.Password);
            var externalNamesTopic = new NamesTopic(driver);
            externalNamesTopic.NavigateTo();
            externalNamesTopic.Instructor.OpenPickList();
            externalNamesTopic.Instructor.SearchFor("a");
            externalNamesTopic.Instructor.SearchGrid.ClickRow(0);
            externalNamesTopic.Instructor.TogglePreviewSwitch.Click();
            var externalRightPane = externalNamesTopic.Instructor.ShowPreviewPane();
            driver.WaitForAngularWithTimeout();
            var email = externalRightPane.FindElement(By.CssSelector("span[translate='caseSearch.topics.names.email']"));

            Assert.True(email.Displayed, "Email is displayed for external users.");
            Assert.Throws<NoSuchElementException>(() => externalRightPane.FindElement(By.CssSelector("span[translate='caseSearch.topics.names.profitCenter']")), "Profit center is not displayed for external users.");
          }
    }
}
