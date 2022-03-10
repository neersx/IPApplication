using System.Collections.Generic;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Characteristics;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Characteristics
{
    public class CharacteristicsValidatorFacts : FactBase
    {
        public class ValidatePropertyType
        {
            [Fact]
            public void ShouldGetValidPropertyTypes()
            {
                var f = new CharacteristicsValidatorFixture();

                var data = new
                {
                    Jurisdiction = "AU",
                    PropertyType = "P"
                };

                f.Subject.ValidatePropertyType(data.PropertyType, data.Jurisdiction);
                f.PropertyTypes.Received(1);
                Assert.Equal(data.Jurisdiction, f.PropertyTypesArgs[1][0]);
            }

            [Fact]
            public void ShouldReturnNotValid()
            {
                var f = new CharacteristicsValidatorFixture();

                var propertyTypes = new[]
                {
                    new KeyValuePair<string, string>("A", "DEFGHI"),
                    new KeyValuePair<string, string>("B", "ABCDEFG")
                };
                f.PropertyTypes.Get(null, null).ReturnsForAnyArgs(propertyTypes);

                var data = new
                {
                    PropertyType = "P"
                };

                var result = f.Subject.ValidatePropertyType(data.PropertyType);
                Assert.False(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }

            [Fact]
            public void ShouldReturnValid()
            {
                var f = new CharacteristicsValidatorFixture();

                var propertyTypes = new[]
                {
                    new KeyValuePair<string, string>("A", "DEFGHI"),
                    new KeyValuePair<string, string>("B", "ABCDEFG"),
                    new KeyValuePair<string, string>("P", "GHIJKL")
                };
                f.PropertyTypes.Get(null, null).ReturnsForAnyArgs(propertyTypes);

                var data = new
                {
                    PropertyType = "P"
                };

                var result = f.Subject.ValidatePropertyType(data.PropertyType);
                Assert.True(result.IsValid);
                Assert.Equal("P", result.Code);
                Assert.Equal("GHIJKL", result.Value);
            }

            [Fact]
            public void ShouldReturnValidIfNull()
            {
                var f = new CharacteristicsValidatorFixture();

                var data = new
                {
                    PropertyType = string.Empty
                };

                var result = f.Subject.ValidatePropertyType(data.PropertyType);

                Assert.True(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }
        }

        public class ValidateCaseCategory
        {
            [Fact]
            public void ShouldGetValidCaseCategories()
            {
                var f = new CharacteristicsValidatorFixture();

                var data = new
                {
                    CaseType = "A",
                    Jurisdiction = "AU",
                    PropertyType = "P",
                    CaseCategory = "C"
                };
                f.Subject.ValidateCaseCategory(data.CaseCategory, data.CaseType, data.Jurisdiction, data.PropertyType);

                f.CaseCategories.Received(1);
                Assert.Null(f.CaseCategoriesArgs[0]);
                Assert.Equal(data.CaseType, f.CaseCategoriesArgs[1]);
                Assert.Equal(data.Jurisdiction, f.CaseCategoriesArgs[2][0]);
                Assert.Equal(data.PropertyType, f.CaseCategoriesArgs[3][0]);
            }

            [Fact]
            public void ShouldReturnInvalidIfNoCaseType()
            {
                var f = new CharacteristicsValidatorFixture();

                var caseCategories = new[]
                {
                    new KeyValuePair<string, string>("A", "DEFGHI")
                };
                f.CaseCategories.Get(null, null, null, null).ReturnsForAnyArgs(caseCategories);

                var data = new
                {
                    CaseCategory = "C"
                };

                var result = f.Subject.ValidateCaseCategory(data.CaseCategory);
                Assert.False(result.IsValid);
            }

            [Fact]
            public void ShouldReturnNotValid()
            {
                var f = new CharacteristicsValidatorFixture();

                var caseCategories = new[]
                {
                    new KeyValuePair<string, string>("A", "DEFGHI"),
                    new KeyValuePair<string, string>("B", "ABCDEFG")
                };
                f.CaseCategories.Get(null, null, null, null).ReturnsForAnyArgs(caseCategories);

                var data = new
                {
                    CaseCategory = "C"
                };

                var result = f.Subject.ValidateCaseCategory(data.CaseCategory);
                Assert.False(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }

            [Fact]
            public void ShouldReturnValid()
            {
                var f = new CharacteristicsValidatorFixture();

                var caseCategories = new[]
                {
                    new KeyValuePair<string, string>("A", "DEFGHI"),
                    new KeyValuePair<string, string>("B", "ABCDEFG"),
                    new KeyValuePair<string, string>("C", "GHIJKL")
                };
                f.CaseCategories.Get(null, null, null, null).ReturnsForAnyArgs(caseCategories);

                var data = new
                {
                    CaseType = "A",
                    CaseCategory = "C"
                };

                var result = f.Subject.ValidateCaseCategory(data.CaseCategory, data.CaseType);
                Assert.True(result.IsValid);
                Assert.Equal("C", result.Code);
                Assert.Equal("GHIJKL", result.Value);
            }

            [Fact]
            public void ShouldReturnValidIfNull()
            {
                var f = new CharacteristicsValidatorFixture();

                var data = new
                {
                    CaseCategory = string.Empty
                };

                var result = f.Subject.ValidateCaseCategory(data.CaseCategory);

                Assert.True(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }
        }

        public class ValidateSubType
        {
            [Fact]
            public void ShouldGetValidSubTypes()
            {
                var f = new CharacteristicsValidatorFixture();

                var data = new
                {
                    CaseType = "A",
                    Jurisdiction = "AU",
                    PropertyType = "P",
                    SubType = "N",
                    CaseCategory = "C"
                };
                f.Subject.ValidateSubType(data.SubType, data.CaseType, data.Jurisdiction, data.PropertyType, data.CaseCategory);

                f.SubTypes.Received(1);
                Assert.Equal(data.CaseType, f.SubTypesArgs[0]);
                Assert.Equal(data.Jurisdiction, f.SubTypesArgs[1][0]);
                Assert.Equal(data.PropertyType, f.SubTypesArgs[2][0]);
                Assert.Equal(data.CaseCategory, f.SubTypesArgs[3][0]);
            }

            [Fact]
            public void ShouldReturnNotValid()
            {
                var f = new CharacteristicsValidatorFixture();

                var subTypes = new[]
                {
                    new KeyValuePair<string, string>("A", "DEFGHI"),
                    new KeyValuePair<string, string>("B", "ABCDEFG")
                };
                f.SubTypes.Get(null, null, null, null).ReturnsForAnyArgs(subTypes);

                var data = new
                {
                    SubType = "N"
                };

                var result = f.Subject.ValidateSubType(data.SubType);
                Assert.False(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }

            [Fact]
            public void ShouldReturnValid()
            {
                var f = new CharacteristicsValidatorFixture();

                var subTypes = new[]
                {
                    new KeyValuePair<string, string>("A", "DEFGHI"),
                    new KeyValuePair<string, string>("B", "ABCDEFG"),
                    new KeyValuePair<string, string>("N", "GHIJKL")
                };
                f.SubTypes.Get(null, null, null, null).ReturnsForAnyArgs(subTypes);

                var data = new
                {
                    CaseType = "A",
                    SubType = "N"
                };

                var result = f.Subject.ValidateSubType(data.SubType, data.CaseType);
                Assert.True(result.IsValid);
                Assert.Equal("N", result.Code);
                Assert.Equal("GHIJKL", result.Value);
            }

            [Fact]
            public void ShouldReturnValidIfNull()
            {
                var f = new CharacteristicsValidatorFixture();

                var data = new
                {
                    SubType = string.Empty
                };

                var result = f.Subject.ValidateSubType(data.SubType);

                Assert.True(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }
        }

        public class ValidateBasis
        {
            [Fact]
            public void ShouldGetValidBasis()
            {
                var f = new CharacteristicsValidatorFixture();

                var data = new
                {
                    CaseType = "A",
                    Jurisdiction = "AU",
                    PropertyType = "P",
                    CaseCategory = "C",
                    Basis = "Y"
                };
                f.Subject.ValidateBasis(data.Basis, data.CaseType, data.Jurisdiction, data.PropertyType, data.CaseCategory);

                f.Basis.Received(1);
                Assert.Equal(data.CaseType, f.BasisArgs[0]);
                Assert.Equal(data.Jurisdiction, f.BasisArgs[1][0]);
                Assert.Equal(data.PropertyType, f.BasisArgs[2][0]);
                Assert.Equal(data.CaseCategory, f.BasisArgs[3][0]);
            }

            [Fact]
            public void ShouldReturnNotValid()
            {
                var f = new CharacteristicsValidatorFixture();

                var basis = new[]
                {
                    new KeyValuePair<string, string>("A", "DEFGHI"),
                    new KeyValuePair<string, string>("B", "ABCDEFG")
                };
                f.Basis.Get(null, null, null, null).ReturnsForAnyArgs(basis);

                var data = new
                {
                    Basis = "Y"
                };

                var result = f.Subject.ValidateBasis(data.Basis);
                Assert.False(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }

            [Fact]
            public void ShouldReturnValid()
            {
                var f = new CharacteristicsValidatorFixture();

                var basis = new[]
                {
                    new KeyValuePair<string, string>("A", "DEFGHI"),
                    new KeyValuePair<string, string>("B", "ABCDEFG"),
                    new KeyValuePair<string, string>("Y", "GHIJKL")
                };
                f.Basis.Get(null, null, null, null).ReturnsForAnyArgs(basis);

                var data = new
                {
                    Basis = "Y"
                };

                var result = f.Subject.ValidateBasis(data.Basis);
                Assert.True(result.IsValid);
                Assert.Equal("Y", result.Code);
                Assert.Equal("GHIJKL", result.Value);
            }

            [Fact]
            public void ShouldReturnValidIfNull()
            {
                var f = new CharacteristicsValidatorFixture();

                var data = new
                {
                    Basis = string.Empty
                };

                var result = f.Subject.ValidateBasis(data.Basis);

                Assert.True(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }
        }

        public class ValidateAction
        {
            [Fact]
            public void ShouldGetValidActions()
            {
                var f = new CharacteristicsValidatorFixture();

                var data = new
                {
                    CaseType = "A",
                    Jurisdiction = "AU",
                    PropertyType = "P",
                    Action = "XX"
                };
                f.Subject.ValidateAction(data.Action, data.CaseType, data.Jurisdiction, data.PropertyType);

                f.Actions.Received(1);
                Assert.Equal(data.Jurisdiction, f.ActionsArgs[0]);
                Assert.Equal(data.PropertyType, f.ActionsArgs[1]);
                Assert.Equal(data.CaseType, f.ActionsArgs[2]);
            }

            [Fact]
            public void ShouldReturnNotValid()
            {
                var f = new CharacteristicsValidatorFixture();

                var actions = new[]
                {
                    new ActionData {Code = "A", Name = "DEFGHI"},
                    new ActionData {Code = "B", Name = "ABCDEFG"}
                };
                f.Actions.Get(null, null, null).ReturnsForAnyArgs(actions);

                var data = new
                {
                    Action = "P"
                };

                var result = f.Subject.ValidateAction(data.Action);
                Assert.False(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }

            [Fact]
            public void ShouldReturnValid()
            {
                var f = new CharacteristicsValidatorFixture();

                var actions = new[]
                {
                    new ActionData {Code = "A", Name = "DEFGHI"},
                    new ActionData {Code = "B", Name = "ABCDEFG"},
                    new ActionData {Code = "XX", Name = "GHIJKL"}
                };
                f.Actions.Get(null, null, null).ReturnsForAnyArgs(actions);

                var data = new
                {
                    CaseType = "A",
                    Action = "XX"
                };

                var result = f.Subject.ValidateAction(data.Action, data.CaseType);
                Assert.True(result.IsValid);
                Assert.Equal("XX", result.Code);
                Assert.Equal("GHIJKL", result.Value);
            }

            [Fact]
            public void ShouldReturnValidIfNull()
            {
                var f = new CharacteristicsValidatorFixture();

                var data = new
                {
                    Action = string.Empty
                };

                var result = f.Subject.ValidateAction(data.Action);

                Assert.True(result.IsValid);
                Assert.Null(result.Code);
                Assert.Null(result.Value);
            }
        }
    }

    public class CharacteristicsValidatorFixture : IFixture<ValidateCharacteristicsValidator>
    {
        public CharacteristicsValidatorFixture()
        {
            PropertyTypes = Substitute.For<IPropertyTypes>();
            CaseCategories = Substitute.For<ICaseCategories>();
            SubTypes = Substitute.For<ISubTypes>();
            Basis = Substitute.For<IBasis>();
            Actions = Substitute.For<IActions>();
            Checklists = Substitute.For<IChecklists>();

            PropertyTypes.WhenForAnyArgs(c => c.Get(null, null)).Do(c => PropertyTypesArgs = c.Args());
            CaseCategories.WhenForAnyArgs(c => c.Get(null, null, null, null)).Do(c => CaseCategoriesArgs = c.Args());
            SubTypes.WhenForAnyArgs(c => c.Get(null, null, null, null)).Do(c => SubTypesArgs = c.Args());
            Basis.WhenForAnyArgs(c => c.Get(null, null, null, null)).Do(c => BasisArgs = c.Args());
            Actions.WhenForAnyArgs(c => c.Get(null, null, null)).Do(c => ActionsArgs = c.Args());
            Checklists.WhenForAnyArgs(c => c.Get(null, null, null)).Do(c => ChecklistsArgs = c.Args());

            Subject = new ValidateCharacteristicsValidator(PropertyTypes, CaseCategories, SubTypes, Basis, Actions, Checklists);
        }

        public IPropertyTypes PropertyTypes { get; set; }
        public ICaseCategories CaseCategories { get; set; }
        public ISubTypes SubTypes { get; set; }
        public IBasis Basis { get; set; }
        public IActions Actions { get; set; }
        public IChecklists Checklists { get; set; }

        public dynamic PropertyTypesArgs { get; set; }
        public dynamic CaseCategoriesArgs { get; set; }
        public dynamic SubTypesArgs { get; set; }
        public dynamic BasisArgs { get; set; }
        public dynamic ActionsArgs { get; set; }
        public dynamic ChecklistsArgs { get; set; }
        public ValidateCharacteristicsValidator Subject { get; }
    }
}