using Inprotech.Tests.Integration.PageObjects;
using OpenQA.Selenium;
using Protractor;

namespace Inprotech.Tests.Integration.EndToEnd.Picklists.DateOfLaw
{
   public class ValidDateOfLawDetailPage : DetailPage
    {
        ValidDateOflawDefaultsTopic _defaultsTopic;

        public ValidDateOfLawDetailPage(NgWebDriver driver) : base(driver)
        {
        }

        public ValidDateOflawDefaultsTopic DefaultsTopic => _defaultsTopic ?? (_defaultsTopic = new ValidDateOflawDefaultsTopic(Driver));
    }

   public class ValidDateOflawDefaultsTopic : Topic
    {
        const string TopicKey = "defaults";

        public ValidDateOflawDefaultsTopic(NgWebDriver driver) : base(driver, TopicKey)
        {
            Jurisdiction = new PickList(driver).ByName(string.Empty, "jurisdiction");

            PropertyType = new PickList(driver).ByName(string.Empty, "propertyType");

            DateOfLaw = new PickList(driver).ByName(string.Empty, "dateOfLaw");

            DeterminingEvent = new PickList(driver).ByName(string.Empty, "determiningEvent");

            RetrospectiveEvent = new PickList(driver).ByName(string.Empty, "retrospectiveEvent");

            RetrospectiveAction = new PickList(driver).ByName(string.Empty, "retrospectiveAction");

            Grid = new KendoGrid(driver, "affectedActions");
        }

        public NgWebElement AddButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("plus-circle"));
        }

        public NgWebElement DateOfLawDatePicker(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("datepicker"));
        }

        public NgWebElement JurisdictionTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("jurisdiction")).FindElement(By.TagName("input"));
        }

        public NgWebElement PropertyTypeTextBox(NgWebDriver driver)
        {
            return driver.FindElement(By.Id("propertyType")).FindElement(By.TagName("input"));
        }

        public NgWebElement AddAffectedActionButton(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("add-affected-actions"));
        }

        public NgWebElement DeleteAction(NgWebDriver driver)
        {
            return driver.FindElement(By.Name("trash-o"));
        }

        public PickList Jurisdiction { get; set; }

        public PickList PropertyType { get; set; }

        public PickList DateOfLaw { get; set; }

        public PickList DeterminingEvent { get; set; }

        public PickList RetrospectiveEvent { get; set; }

        public PickList RetrospectiveAction { get; set; }

        public KendoGrid Grid { get; }
    }

}
