using System.Collections.Generic;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Characteristics
{
    public class ValidCharacteristicsReaderFacts : FactBase
    {
        public class GetValidPropertyType
        {
            [Fact]
            public void ShouldCallCharacteristicsValidatorAndReturnIfValid()
            {
                var validProperty = new ValidatedCharacteristic("P", "P");
                var f = new ValidCharacteristicsReaderFixture();
                f.ValidateCharacteristicsValidator.ValidatePropertyType().ReturnsForAnyArgs(validProperty);

                var data = new
                {
                    PropertyType = "P"
                };

                var result = f.Subject.GetPropertyType(data.PropertyType);

                f.ValidateCharacteristicsValidator.Received(1).ValidatePropertyType(data.PropertyType);
                Assert.True(result.IsValid);
                Assert.Equal(result.Key, validProperty.Key);
                Assert.Equal(result.Value, validProperty.Value);
            }

            [Fact]
            public void ShouldFetchBaseValueAndReturnInvalid()
            {
                var invalidProperty = new ValidatedCharacteristic("P", "P", false);
                var f = new ValidCharacteristicsReaderFixture();
                f.ValidateCharacteristicsValidator.ValidatePropertyType().ReturnsForAnyArgs(invalidProperty);
                f.PropertyTypes.Get(Arg.Any<string>(), Arg.Any<string[]>()).ReturnsForAnyArgs(new[] {new KeyValuePair<string, string>("P1", "Value")});

                var data = new
                {
                    PropertyType = "P1"
                };

                var result = f.Subject.GetPropertyType(data.PropertyType);

                f.ValidateCharacteristicsValidator.Received(1).ValidatePropertyType(data.PropertyType);
                f.PropertyTypes.Received(1).Get(null, Arg.Any<string[]>());
                Assert.False(result.IsValid);
                Assert.Equal("P1", result.Code);
                Assert.Equal("Value", result.Value);
            }
        }

        public class GetValidCaseCategory
        {
            [Fact]
            public void ShouldCallCharacteristicsValidatorAndReturnIfValid()
            {
                var validCaseCategory = new ValidatedCharacteristic("P", "P");
                var f = new ValidCharacteristicsReaderFixture();
                f.ValidateCharacteristicsValidator.ValidateCaseCategory().ReturnsForAnyArgs(validCaseCategory);

                var data = new
                {
                    PropertyType = "P",
                    CaseCategory = "CC",
                    CaseType = "CT",
                    Jurisdiction = "J"
                };

                var result = f.Subject.GetCaseCategory(data.CaseCategory, data.CaseType, data.Jurisdiction, data.PropertyType);

                f.ValidateCharacteristicsValidator.Received(1).ValidateCaseCategory(data.CaseCategory, data.CaseType, data.Jurisdiction, data.PropertyType);
                Assert.True(result.IsValid);
                Assert.Equal(result.Key, validCaseCategory.Key);
                Assert.Equal(result.Value, validCaseCategory.Value);
            }

            [Fact]
            public void ShouldFetchBaseValueAndReturnInvalid()
            {
                var invalidCaseCategory = new ValidatedCharacteristic("P", "P", false);
                var f = new ValidCharacteristicsReaderFixture();
                f.ValidateCharacteristicsValidator.ValidateCaseCategory().ReturnsForAnyArgs(invalidCaseCategory);
                f.CaseCategories.Get(null, null, Arg.Any<string[]>(), Arg.Any<string[]>()).ReturnsForAnyArgs(new[] {new KeyValuePair<string, string>("CC", "Value")});

                var data = new
                {
                    PropertyType = "P",
                    CaseCategory = "CC",
                    CaseType = "CT",
                    Jurisdiction = "J"
                };

                var result = f.Subject.GetCaseCategory(data.CaseCategory, data.CaseType, data.Jurisdiction, data.PropertyType);

                f.CaseCategories.Received(1).Get(null, data.CaseType, Arg.Is<string[]>(x => x.Length == 0), Arg.Is<string[]>(x => x.Length == 0));
                Assert.False(result.IsValid);
                Assert.Equal("CC", result.Code);
                Assert.Equal("Value", result.Value);
            }
        }

        public class GetValidSubType
        {
            [Fact]
            public void ShouldCallCharacteristicsValidatorAndReturnIfValid()
            {
                var validSubType = new ValidatedCharacteristic("P", "P");
                var f = new ValidCharacteristicsReaderFixture();
                f.ValidateCharacteristicsValidator.ValidateSubType().ReturnsForAnyArgs(validSubType);

                var data = new
                {
                    PropertyType = "P",
                    SubType = "ST",
                    Jurisdiction = "J"
                };

                var result = f.Subject.GetSubType(data.SubType, null, data.Jurisdiction, data.PropertyType);

                f.ValidateCharacteristicsValidator.Received(1).ValidateSubType(data.SubType, null, data.Jurisdiction, data.PropertyType);
                Assert.True(result.IsValid);
                Assert.Equal(result.Key, validSubType.Key);
                Assert.Equal(result.Value, validSubType.Value);
            }

            [Fact]
            public void ShouldFetchBaseValueAndReturnInvalid()
            {
                var invalidSubType = new ValidatedCharacteristic("P", "P", false);
                var f = new ValidCharacteristicsReaderFixture();
                f.ValidateCharacteristicsValidator.ValidateSubType().ReturnsForAnyArgs(invalidSubType);
                f.SubTypes.Get(null, Arg.Any<string[]>(), Arg.Any<string[]>(), Arg.Any<string[]>())
                 .ReturnsForAnyArgs(new[] {new KeyValuePair<string, string>("ST", "Value"), new KeyValuePair<string, string>("ST1", "Value1")});

                var data = new
                {
                    PropertyType = "P1",
                    CaseCategory = "CT",
                    SubType = "ST"
                };

                var result = f.Subject.GetSubType(data.SubType, null, null, data.PropertyType, data.CaseCategory);

                f.SubTypes.Received(1).Get(null, Arg.Is<string[]>(s1 => s1.Length == 0), Arg.Is<string[]>(s2 => s2.Length == 0), Arg.Is<string[]>(s3 => s3.Length == 0));
                Assert.False(result.IsValid);
                Assert.Equal("ST", result.Code);
                Assert.Equal("Value", result.Value);
            }
        }

        public class GetValidAction
        {
            [Fact]
            public void ShouldCallCharacteristicsValidatorAndReturnIfValid()
            {
                var validAction = new ValidatedCharacteristic("P", "P");
                var f = new ValidCharacteristicsReaderFixture();
                f.ValidateCharacteristicsValidator.ValidateAction().ReturnsForAnyArgs(validAction);

                var data = new
                {
                    Action = "A",
                    PropertyType = "P"
                };

                var result = f.Subject.GetAction(data.Action, null, null, data.PropertyType);

                f.ValidateCharacteristicsValidator.Received(1).ValidateAction(data.Action, null, null, data.PropertyType);
                Assert.True(result.IsValid);
                Assert.Equal(result.Key, validAction.Key);
                Assert.Equal(result.Value, validAction.Value);
            }

            [Fact]
            public void ShouldFetchBaseValueAndReturnInvalid()
            {
                var invalidAction = new ValidatedCharacteristic("P", "P", false);
                var f = new ValidCharacteristicsReaderFixture();
                f.ValidateCharacteristicsValidator.ValidateAction().ReturnsForAnyArgs(invalidAction);
                f.Actions.Get(null, null, null).ReturnsForAnyArgs(new[] {new ActionData {Code = "A", Name = "action name"}});

                var data = new
                {
                    Action = "A",
                    PropertyType = "P1"
                };

                var result = f.Subject.GetAction(data.Action, null, null, data.PropertyType);

                f.Actions.Received(1).Get(null, null, null);
                Assert.False(result.IsValid);
                Assert.Equal("A", result.Code);
                Assert.Equal("action name", result.Value);
            }
        }

        public class GetValidBasis
        {
            [Fact]
            public void ShouldCallCharacteristicsValidatorAndReturnIfValid()
            {
                var validBasis = new ValidatedCharacteristic("P", "P");
                var f = new ValidCharacteristicsReaderFixture();
                f.ValidateCharacteristicsValidator.ValidateBasis().ReturnsForAnyArgs(validBasis);

                var data = new
                {
                    Basis = "B",
                    PropertyType = "P"
                };

                var result = f.Subject.GetBasis(data.Basis, null, null, data.PropertyType);

                f.ValidateCharacteristicsValidator.Received(1).ValidateBasis(data.Basis, null, null, data.PropertyType);
                Assert.True(result.IsValid);
                Assert.Equal(result.Key, validBasis.Key);
                Assert.Equal(result.Value, validBasis.Value);
            }

            [Fact]
            public void ShouldFetchBaseValueAndReturnInvalid()
            {
                var invalidBasis = new ValidatedCharacteristic("P", "P", false);
                var f = new ValidCharacteristicsReaderFixture();
                f.ValidateCharacteristicsValidator.ValidateBasis().ReturnsForAnyArgs(invalidBasis);
                f.Basis.Get(null, new string[0], new string[0], null)
                 .ReturnsForAnyArgs(new[] {new KeyValuePair<string, string>("B", "Value"), new KeyValuePair<string, string>("B1", "Value1")});

                var data = new
                {
                    Basis = "B",
                    Jurisidiction = "J",
                    PropertyType = "P1"
                };

                var result = f.Subject.GetBasis(data.Basis, null, null, data.PropertyType, data.Jurisidiction);

                Assert.False(result.IsValid);
                Assert.Equal("B", result.Code);
                Assert.Equal("Value", result.Value);
            }
        }
    }

    public class ValidCharacteristicsReaderFixture : IFixture<ValidCharacteristicsReader>
    {
        public ValidCharacteristicsReaderFixture()
        {
            ValidateCharacteristicsValidator = Substitute.For<IValidateCharacteristicsValidator>();
            PropertyTypes = Substitute.For<IPropertyTypes>();
            CaseCategories = Substitute.For<ICaseCategories>();
            SubTypes = Substitute.For<ISubTypes>();
            Basis = Substitute.For<IBasis>();
            Actions = Substitute.For<IActions>();

            PropertyTypes.WhenForAnyArgs(c => c.Get(null, null)).Do(c => PropertyTypesArgs = c.Args());
            CaseCategories.WhenForAnyArgs(c => c.Get(null, null, null, null)).Do(c => CaseCategoriesArgs = c.Args());
            SubTypes.WhenForAnyArgs(c => c.Get(null, null, null, null)).Do(c => SubTypesArgs = c.Args());
            Basis.WhenForAnyArgs(c => c.Get(null, null, null, null)).Do(c => BasisArgs = c.Args());
            Actions.WhenForAnyArgs(c => c.Get(null, null, null)).Do(c => ActionsArgs = c.Args());

            Subject = new ValidCharacteristicsReader(ValidateCharacteristicsValidator, PropertyTypes, CaseCategories, SubTypes, Basis, Actions);
        }

        public IValidateCharacteristicsValidator ValidateCharacteristicsValidator { get; }

        public IPropertyTypes PropertyTypes { get; set; }
        public ICaseCategories CaseCategories { get; set; }
        public ISubTypes SubTypes { get; set; }
        public IBasis Basis { get; set; }
        public IActions Actions { get; set; }

        public dynamic PropertyTypesArgs { get; set; }
        public dynamic CaseCategoriesArgs { get; set; }
        public dynamic SubTypesArgs { get; set; }
        public dynamic BasisArgs { get; set; }
        public dynamic ActionsArgs { get; set; }
        public ValidCharacteristicsReader Subject { get; }
    }
}