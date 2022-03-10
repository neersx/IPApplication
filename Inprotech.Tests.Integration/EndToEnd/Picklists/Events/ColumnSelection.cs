using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.PageObjects;
using Inprotech.Tests.Integration.Utils;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.Events
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ColumnSelection : IntegrationTest
    {
        [TestCase(BrowserType.Chrome)]
        [TestCase(BrowserType.Ie)]
        [TestCase(BrowserType.FireFox)]
        public void TogglePicklistColumns(BrowserType browserType)
        {
            DbSetup.Do(setup =>
            {
                var eventBuilder = new EventBuilder(setup.DbContext);
                var event1 = eventBuilder.Create("event");
                var event2 = eventBuilder.Create("event1");
                var event3 = eventBuilder.Create("event2");

                return new
                {
                    Event1 = event1.Description,
                    Event2 = event2.Description,
                    Event3 = event3.Description
                };
            });

            var driver = BrowserProvider.Get(browserType);

            SignIn(driver, "/#/configuration/rules/workflows");
            driver.FindRadio("search-by-event").Click();

            var eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            var eventsGrid = eventsPicklist.SearchGrid;

            eventsPicklist.SearchButton.ClickWithTimeout();
            
            eventsPicklist.ColumnMenuButton().WithJs().Click();
            Assert.IsTrue(eventsPicklist.IsColumnChecked("code"), "The column appears checked in the menu");

            eventsPicklist.ToggleGridColumn("code");
            eventsPicklist.ColumnMenuButton().WithJs().Click();
            Assert.AreEqual(false, eventsGrid.HeaderColumn("code").Displayed, "Column is not displayed");

            eventsPicklist.ColumnMenuButton().WithJs().Click(); // Close the menu TODO: can be removed when menu is hidden onblur
            Assert.IsFalse(eventsPicklist.IsColumnChecked("code"), "The column is unchecked in the menu");
            driver.HoverOff();
            eventsPicklist.Close();
            eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.SearchButton.ClickWithTimeout();
            Assert.AreEqual(false, eventsGrid.HeaderColumn("code").Displayed, "Column remains hidden");
            eventsPicklist.ColumnMenuButton().WithJs().Click();
            Assert.IsFalse(eventsPicklist.IsColumnChecked("code"), "The column remains unchecked in the menu");

            eventsPicklist.ToggleGridColumn("code");
            eventsPicklist.ColumnMenuButton().ClickWithTimeout(); // Close the menu TODO: can be removed when menu is hidden onblur

            eventsPicklist.ColumnMenuButton().WithJs().Click();
            Assert.IsTrue(eventsPicklist.IsColumnChecked("code"), "The column appears checked in the menu");
            driver.HoverOff();
            eventsPicklist.Close();

            eventsPicklist = new PickList(driver).ByName(string.Empty, "event");
            eventsPicklist.SearchButton.ClickWithTimeout();

            eventsGrid = eventsPicklist.SearchGrid;
            Assert.AreEqual(true, eventsGrid.HeaderColumn("code").Displayed, "Column is displayed");
            eventsPicklist.ColumnMenuButton().WithJs().Click();
            Assert.IsTrue(eventsPicklist.IsColumnChecked("code"), "The column remains checked in the menu");

        }
    }
}
