using Inprotech.Web.Characteristics;
using Inprotech.Web.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Configuration.Rules
{
    public class CharacteristicsValidatorFacts : FactBase
    {
        public class Validate
        {
            [Fact]
            public void ShouldReturnAllValidKeysAndDescriptions()
            {
                var f = new CharacteristicsValidatorFixture();

                var criteria = new WorkflowCharacteristics
                {
                    PropertyType = "P",
                    CaseType = "A",
                    Jurisdiction = "AU",
                    CaseCategory = "C",
                    SubType = "N",
                    Basis = "Y",
                    Action = "XX"
                };

                var validAction = new ValidatedCharacteristic("XX", "ValidAction");
                var validBasis = new ValidatedCharacteristic("Y", "ValidBasis");
                var validCaseCategory = new ValidatedCharacteristic("C", "ValidCaseCategory");
                var validPropertyType = new ValidatedCharacteristic("P", "ValidProperty");
                var validSubType = new ValidatedCharacteristic("N", "ValidSubType");

                f.ValidateCharacteristicsValidator.ValidateAction().ReturnsForAnyArgs(validAction);
                f.ValidateCharacteristicsValidator.ValidateBasis().ReturnsForAnyArgs(validBasis);
                f.ValidateCharacteristicsValidator.ValidateCaseCategory().ReturnsForAnyArgs(validCaseCategory);
                f.ValidateCharacteristicsValidator.ValidatePropertyType().ReturnsForAnyArgs(validPropertyType);
                f.ValidateCharacteristicsValidator.ValidateSubType().ReturnsForAnyArgs(validSubType);

                var result = f.Subject.Validate(criteria);

                var item = result.PropertyType;
                Assert.Equal("P", item.Code);
                Assert.Equal("ValidProperty", item.Value);

                item = result.Action;
                Assert.Equal("XX", item.Code);
                Assert.Equal("ValidAction", item.Value);

                item = result.CaseCategory;
                Assert.Equal("C", item.Code);
                Assert.Equal("ValidCaseCategory", item.Value);

                item = result.SubType;
                Assert.Equal("N", item.Code);
                Assert.Equal("ValidSubType", item.Value);

                item = result.Basis;
                Assert.Equal("Y", item.Code);
                Assert.Equal("ValidBasis", item.Value);
            }

            [Fact]
            public void ShouldValidateAllCharacteristics()
            {
                var f = new CharacteristicsValidatorFixture();

                var returnAny = new ValidatedCharacteristic();
                f.ValidateCharacteristicsValidator.ValidateAction().ReturnsForAnyArgs(returnAny);
                f.ValidateCharacteristicsValidator.ValidateBasis().ReturnsForAnyArgs(returnAny);
                f.ValidateCharacteristicsValidator.ValidateCaseCategory().ReturnsForAnyArgs(returnAny);
                f.ValidateCharacteristicsValidator.ValidatePropertyType().ReturnsForAnyArgs(returnAny);
                f.ValidateCharacteristicsValidator.ValidateSubType().ReturnsForAnyArgs(returnAny);

                var criteria = new WorkflowCharacteristics
                {
                    PropertyType = "P",
                    CaseType = "A",
                    Jurisdiction = "AU",
                    CaseCategory = "C",
                    SubType = "N",
                    Basis = "Y",
                    Action = "XX"
                };
                var result = f.Subject.Validate(criteria);

                Assert.NotNull(result.PropertyType);
                Assert.NotNull(result.CaseCategory);
                Assert.NotNull(result.SubType);
                Assert.NotNull(result.Basis);
                Assert.NotNull(result.Action);
            }
        }

        public class CharacteristicsValidatorFixture : IFixture<WorkflowCharacteristicsValidator>
        {
            public CharacteristicsValidatorFixture()
            {
                ValidateCharacteristicsValidator = Substitute.For<IValidateCharacteristicsValidator>();
                Subject = new WorkflowCharacteristicsValidator(ValidateCharacteristicsValidator);
            }

            public IValidateCharacteristicsValidator ValidateCharacteristicsValidator { get; set; }
            public WorkflowCharacteristicsValidator Subject { get; }
        }
    }
}