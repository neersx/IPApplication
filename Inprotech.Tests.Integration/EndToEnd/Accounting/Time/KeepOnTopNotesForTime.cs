using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.KeepOnTopNotes;
using NUnit.Framework;
using OpenQA.Selenium;

namespace Inprotech.Tests.Integration.EndToEnd.Accounting.Time
{
    [Category(Categories.E2E)]
    [TestFixture]
    [ChangeAppSettings(AppliesTo.InprotechServer, "InprotechVersion", "16.0")]
    [TestFrom(DbCompatLevel.Release16)]
    public class KeepOnTopNotesForTime : IntegrationTest
    {
        [SetUp]
        public void Setup()
        {
            _dbData = TimeRecordingDbHelper.Setup();
        }

        [TearDown]
        public void CleanUpModifiedData()
        {
            TimeRecordingDbHelper.Cleanup();
        }

        TimeRecordingData _dbData;

        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.FireFox)]
        [TestCase(BrowserType.Ie)]
        public void ShowKeepOnTopNotes(BrowserType browserType)
        {
            var dbData = DbSetup.Do(d =>
            {
                var @case = _dbData.Case2;
                var tt = d.DbContext.Set<TextType>().FirstOrDefault(x => x.Id == "D");
                var tt1 = d.DbContext.Set<TextType>().FirstOrDefault(x => x.Id == "R");
                var tt2 = d.Insert(new TextType { Id = "TT", TextDescription = "E2E Test CaseView" });

                var kot = d.Insert(new KeepOnTopTextType { TextTypeId = tt?.Id, TextType = tt, CaseProgram = true, NameProgram = false, TimeProgram = true, IsRegistered = false, IsPending = false, IsDead = false, Type = KnownKotTypes.Case, BackgroundColor = "#b9d87b" });
                var kot1 = d.Insert(new KeepOnTopTextType { TextTypeId = tt1?.Id, TextType = tt1, CaseProgram = true, NameProgram = false, TimeProgram = true, IsRegistered = false, IsPending = false, IsDead = false, Type = KnownKotTypes.Case, BackgroundColor = "#b9d87b" });
                var kot2 = d.Insert(new KeepOnTopTextType { TextTypeId = tt2?.Id, TextType = tt2, TimeProgram = true, CaseProgram = true, Type = KnownKotTypes.Case, BackgroundColor = "#b9d87b" });

                var kotCt = d.DbContext.Set<KeepOnTopCaseType>().FirstOrDefault(x => x.CaseTypeId == @case.Type.Code);
                kot.KotCaseTypes = new List<KeepOnTopCaseType>
                {
                    kotCt
                };
                kot1.KotCaseTypes = new List<KeepOnTopCaseType>
                {
                    kotCt
                };
                kot2.KotCaseTypes = new List<KeepOnTopCaseType>
                {
                    kotCt
                };

                d.Insert(new CaseText(@case.Id, tt?.Id, 0, null)
                {
                    Language = null,
                    Text = "Case Text e2e",
                    TextType = tt
                });
                d.Insert(new CaseText(@case.Id, tt1?.Id, 0, null)
                {
                    Language = null,
                    Text = "Case Text1 e2e",
                    TextType = tt1
                });
                d.Insert(new CaseText(@case.Id, tt2?.Id, 0, null)
                {
                    Language = null,
                    Text = "Case Text 3 test e2e",
                    TextType = tt2
                });

                @case.CaseStatus = d.DbContext.Set<Status>().FirstOrDefault(x => x.Id == -210);

                d.DbContext.SaveChanges();
                var IeColor = "rgba(185, 216, 123, 1)";
                var OtherBrowserColor = "rgb(185, 216, 123)";
                return new { kot, tt, tt1, kot1, @case, IeColor, OtherBrowserColor };
            });
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/accounting/time", _dbData.User.Username, _dbData.User.Password);

            var data = dbData.kot;
            var page = new TimeRecordingPage(driver);

            page.AddButton.ClickWithTimeout();
            var casePicker = new AngularPicklist(driver).ByName("caseRef");
            casePicker.Typeahead.WithJs().Focus();
            casePicker.Typeahead.Clear();
            casePicker.Typeahead.SendKeys(_dbData.Case2.Irn);
            casePicker.Typeahead.SendKeys(Keys.ArrowDown);
            casePicker.Typeahead.SendKeys(Keys.Enter);

            var kotItem = driver.FindElement(By.CssSelector(".kot-block"));
            var colorBlock = driver.FindElement(By.CssSelector(".kot-block")).GetCssValue("background-color");
            var kotCaseRefHeader = driver.FindElement(By.Id("caseRef"));
            var kotTextTypeHeader = driver.FindElement(By.Id("textType"));
            Assert.AreEqual(colorBlock.Contains("rgba") ? dbData.IeColor : dbData.OtherBrowserColor, colorBlock);
            Assert.IsTrue(kotItem.Displayed);
            Assert.AreEqual(dbData.@case.Irn, kotCaseRefHeader.Text);
            Assert.AreEqual(data.TextType.TextDescription, kotTextTypeHeader.Text);
        }
    }
}