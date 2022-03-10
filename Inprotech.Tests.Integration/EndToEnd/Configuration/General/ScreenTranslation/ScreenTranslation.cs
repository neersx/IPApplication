using Inprotech.Tests.Integration.Extensions;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.ScreenTranslation
{
    [Category(Categories.E2E)]
    [TestFixture]
    public class ScreenTranslation : IntegrationTest
    {
        [TestCase(BrowserType.Chrome, Ignore = "Flakey, To Be reinstated with DR-55243")]
        [TestCase(BrowserType.Ie, Ignore = "Flakey, To Be reinstated with DR-55243")]
        [TestCase(BrowserType.FireFox, Ignore = "Flakey, To Be reinstated with DR-55243")]
        public void UpdateScreenTranslation(BrowserType browserType)
        {
            var driver = BrowserProvider.Get(browserType);
            SignIn(driver, "/#/configuration/system/mui/screen-translations-utility");
            var screenTranslation = new ScreenTranslationPageObject(driver);

            screenTranslation.LanguageAndCultureDropdown.SelectByIndex(1);
            screenTranslation.TextContainingInput.SendKeys("save");
            Assert.True(screenTranslation.UntranslatedCheckbox.IsChecked);

            screenTranslation.SearchOptions.ResetButton.ClickWithTimeout();
            Assert.IsEmpty(screenTranslation.LanguageAndCultureDropdown.SelectedOption.Text);
            Assert.IsEmpty(screenTranslation.TextContainingInput.Text);

            screenTranslation.LanguageAndCultureDropdown.SelectByIndex(1);
            screenTranslation.TextContainingInput.SendKeys("save");
            screenTranslation.SearchOptions.SearchButton.ClickWithTimeout();

            var grid = screenTranslation.SearchGrid;
            Assert.IsNotEmpty(grid.Rows);

            grid.TranslationField(0).SendKeys("save test");
            screenTranslation.RevertButton.ClickWithTimeout();
            screenTranslation.ModalDiscard.ClickWithTimeout();

            Assert.AreEqual(string.Empty, grid.TranslationField(0).Text);
            grid.TranslationField(0).SendKeys("save test");
            screenTranslation.SaveButton.ClickWithTimeout();

            grid = screenTranslation.SearchGrid;
            Assert.AreEqual(string.Empty, grid.TranslationField(0).Text);

            screenTranslation.UntranslatedCheckbox.Click();
            screenTranslation.SearchOptions.SearchButton.ClickWithTimeout(3);

            grid = screenTranslation.SearchGrid;
            Assert.AreEqual("save test", grid.TranslationField(0).GetAttribute("value"));
            grid.TranslationField(0).Clear();
            screenTranslation.SaveButton.ClickWithTimeout();
        }
    }
}
