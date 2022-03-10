using Inprotech.Web.Characteristics;
using Inprotech.Web.Policing;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Policing
{
    public class PolicingCharacteristicsServiceFacts
    {
        [Fact]
        public void CallsCharacteristicsValidatorWithCorrectParameters()
        {
            var characteristics = new InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics
            {
                Action = "A",
                CaseCategory = "CC",
                CaseType = "CT",
                Jurisdiction = "J",
                PropertyType = "P",
                SubType = "ST"
            };

            var f = new PolicingCharacteristicsServiceFixture();
            f.Subject.ValidateCharacteristics(characteristics);

            f.ValidateCharacteristicsValidator.Received(1).ValidatePropertyType(characteristics.PropertyType, characteristics.Jurisdiction);
            f.ValidateCharacteristicsValidator.Received(1).ValidateAction(characteristics.Action, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType);
            f.ValidateCharacteristicsValidator.Received(1).ValidateCaseCategory(characteristics.CaseCategory, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType);
            f.ValidateCharacteristicsValidator.Received(1).ValidateSubType(characteristics.SubType, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType, characteristics.CaseCategory);
        }

        [Fact]
        public void CallsCharacteristicsReaderWithCorrectParameters()
        {
            var characteristics = new InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics
            {
                Action = "A",
                CaseCategory = null,
                CaseType = "CT",
                Jurisdiction = "J",
                PropertyType = "P",
                SubType = "ST"
            };

            var f = new PolicingCharacteristicsServiceFixture();
            f.Subject.GetValidatedCharacteristics(characteristics);

            f.CharacteristicsReader.Received(1).GetPropertyType(characteristics.PropertyType, characteristics.Jurisdiction);
            f.CharacteristicsReader.Received(1).GetAction(characteristics.Action, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType);
            f.CharacteristicsReader.Received(1).GetCaseCategory(characteristics.CaseCategory, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType);
            f.CharacteristicsReader.Received(1).GetSubType(characteristics.SubType, characteristics.CaseType, characteristics.Jurisdiction, characteristics.PropertyType, characteristics.CaseCategory);
        }

        [Fact]
        public void ReturnsValidatedCharacteristics()
        {
            var characteristics = new InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics();
            var validedPropertyType = new ValidatedCharacteristic("P", null, false);
            var validedCaseCategory = new ValidatedCharacteristic("CA", "CaseCategory", false);
            var validedSubType = new ValidatedCharacteristic("ST", "SubType");
            var validedAction = new ValidatedCharacteristic("A");

            var f = new PolicingCharacteristicsServiceFixture();
            f.ValidateCharacteristicsValidator.ValidatePropertyType().ReturnsForAnyArgs(validedPropertyType);
            f.ValidateCharacteristicsValidator.ValidateCaseCategory().ReturnsForAnyArgs(validedCaseCategory);
            f.ValidateCharacteristicsValidator.ValidateSubType().ReturnsForAnyArgs(validedSubType);
            f.ValidateCharacteristicsValidator.ValidateAction().ReturnsForAnyArgs(validedAction);

            var result = f.Subject.ValidateCharacteristics(characteristics);
            Assert.Equal(validedPropertyType, result.PropertyType);
            Assert.Equal(validedCaseCategory, result.CaseCategory);
            Assert.Equal(validedSubType, result.SubType);
            Assert.Equal(validedAction, result.Action);
        }

        [Fact]
        public void ReturnsValidCharacteristics()
        {
            var characteristics = new InprotechKaizen.Model.Components.Configuration.Rules.Characteristics.Characteristics();
            var validPropertyType = new ValidatedCharacteristic("P", null, false);
            var validCaseCategory = new ValidatedCharacteristic("CA", "CaseCategory", false);
            var validSubType = new ValidatedCharacteristic("ST", "SubType");
            var validAction = new ValidatedCharacteristic("A");

            var f = new PolicingCharacteristicsServiceFixture();
            f.CharacteristicsReader.GetPropertyType(null).ReturnsForAnyArgs(validPropertyType);
            f.CharacteristicsReader.GetCaseCategory(null).ReturnsForAnyArgs(validCaseCategory);
            f.CharacteristicsReader.GetSubType(null).ReturnsForAnyArgs(validSubType);
            f.CharacteristicsReader.GetAction(null).ReturnsForAnyArgs(validAction);

            var result = f.Subject.GetValidatedCharacteristics(characteristics);
            Assert.Equal(validPropertyType, result.PropertyType);
            Assert.Equal(validCaseCategory, result.CaseCategory);
            Assert.Equal(validSubType, result.SubType);
            Assert.Equal(validAction, result.Action);
        }
    }

    public class PolicingCharacteristicsServiceFixture : IFixture<IPolicingCharacteristicsService>
    {
        public PolicingCharacteristicsServiceFixture()
        {
            CharacteristicsReader = Substitute.For<IValidCharacteristicsReader>();

            ValidateCharacteristicsValidator = Substitute.For<IValidateCharacteristicsValidator>();

            Subject = new PolicingCharacteristicsService(ValidateCharacteristicsValidator, CharacteristicsReader);
        }

        public IValidCharacteristicsReader CharacteristicsReader { get; }

        public IValidateCharacteristicsValidator ValidateCharacteristicsValidator { get; }

        public IPolicingCharacteristicsService Subject { get; }
    }
}