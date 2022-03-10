using InprotechKaizen.Model.Components.Names;
using Xunit;

namespace Inprotech.Tests.Model.Components.Names
{
    public class FormattedNameFacts
    {
        [Theory]
        // Organisations
        [InlineData("Asparagus Holding Company", "Asparagus Holding Company", null, null, null)]
        [InlineData("Asparagus Holding Company", "Asparagus Holding Company", null, null, NameStyles.FamilyNameThenFirstNames)]
        [InlineData("Asparagus Holding Company", "Asparagus Holding Company", null, null, NameStyles.FirstNameThenFamilyName)]
        [InlineData("Asparagus Holding Company", "Asparagus Holding Company", null, null, NameStyles.Default)]

        // Individuals
        [InlineData("Smith, John", "Smith", "John", null, null)]
        [InlineData("Smith John", "Smith", "John", null, NameStyles.FamilyNameThenFirstNames)]
        [InlineData("John Smith", "Smith", "John", null, NameStyles.FirstNameThenFamilyName)]
        [InlineData("Smith, John", "Smith", "John", null, NameStyles.Default)]
        [InlineData("Smith, John", "Smith", "John", "Prof.", null)]
        [InlineData("Smith John Prof.", "Smith", "John", "Prof.", NameStyles.FamilyNameThenFirstNames)]
        [InlineData("Prof. John Smith", "Smith", "John", "Prof.", NameStyles.FirstNameThenFamilyName)]
        [InlineData("Smith, John", "Smith", "John", "Prof.", NameStyles.Default)]
        public void ShouldFormatNamesAccordingly(string expectedFormattedName, string name, string firstName, string title, NameStyles? nameStyle)
        {
            var formattedName = FormattedName.For(name, firstName, title, null, null, nameStyle ?? NameStyles.Default);
            Assert.Equal(expectedFormattedName, formattedName);
        }

        [Theory]
        [InlineData("Smith Jr., John Hancock", "Smith", "John", "Mrs", "Hancock", "Jr.", null)]
        [InlineData("Smith Jr. John Hancock Mrs", "Smith", "John", "Mrs", "Hancock", "Jr.", NameStyles.FamilyNameThenFirstNames)]
        [InlineData("Mrs John Hancock Smith Jr.", "Smith", "John", "Mrs", "Hancock", "Jr.", NameStyles.FirstNameThenFamilyName)]
        [InlineData("Smith Jr., John", "Smith", "John", "Mrs", null, "Jr.", null)]
        [InlineData("Smith, John Hancock", "Smith", "John", "Mrs", "Hancock", null, null)]
        public void ShouldFormatMiddleAndSuffixAccordingly(string expectedFormattedName, string name, string firstName, string title, string middleName, string suffix, NameStyles? nameStyle)
        {
            var formattedName = FormattedName.For(name, firstName, title, middleName, suffix, nameStyle ?? NameStyles.Default);
            Assert.Equal(expectedFormattedName, formattedName);
        }

        [Theory]
        [InlineData("Smith", "John", "Mrs", "Hancock", "Jr.")]
        [InlineData("Smith", "John", "Ms", null, null)]
        public void DefaultsNameStyle(string name, string firstName, string title, string middleName, string suffix)
        {
            var benchmarkName = FormattedName.For(name, firstName, title, middleName, suffix, NameStyles.Default);
            var formattedName = FormattedName.For(name, firstName, title, middleName, suffix);
            Assert.Equal(benchmarkName, formattedName);
        }
    }
}