using System.Collections.Generic;
using System.Linq;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search.Case.CaseSearch;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.CaseSearch
{
    public class CaseDetailsSelectionVerificationFacts
    {
        public class PropertyType
        {
            [Theory]
            [InlineData("CaseType")]
            [InlineData("PropertyType")]
            [InlineData("CaseCategory")]
            public void ChangingAnUnrelatedFieldShouldNotUpdateSelection(string unrelatedField)
            {
                var selection = new CaseDetailsSelection
                {
                    ChangingField = unrelatedField,
                    PropertyTypes =
                        new[]
                        {
                            new KeyValuePair<string, string>()
                        }
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.Subject.Verify(selection);

                fixture.PropertyTypes.DidNotReceiveWithAnyArgs().Get(null, null);
            }

            [Fact]
            public void ChangingCountryShouldNotUpdateSelectionIfThereIsNoPropertyTypesSelected()
            {
                var selection = new CaseDetailsSelection
                {
                    ChangingField = "Country",
                    PropertyTypes = new KeyValuePair<string, string>[0]
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.Subject.Verify(selection);

                fixture.PropertyTypes.DidNotReceiveWithAnyArgs().Get(null, null);
            }

            [Fact]
            public void ChangingCountryShouldUpdateSelection()
            {
                var selection = new CaseDetailsSelection
                {
                    ChangingField = "Country",
                    Countries = new[] {"c"},
                    PropertyTypes =
                        new[]
                        {
                            new KeyValuePair<string, string>("ka", "va"),
                            new KeyValuePair<string, string>("kb", "vb")
                        }
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.PropertyTypes.Get(null, selection.Countries)
                       .Returns(
                                new[]
                                {
                                    new KeyValuePair<string, string>("ka", "va1"),
                                    new KeyValuePair<string, string>("kc", "vc")
                                });

                var result = fixture.Subject.Verify(selection);

                Assert.Equal("va1", result.PropertyTypes.Single().Value);
            }
        }

        public class CaseCategory
        {
            [Theory]
            [InlineData("CaseCategory")]
            public void ChangingAnUnrelatedFieldShouldNotUpdateSelection(string unrelatedField)
            {
                var selection = new CaseDetailsSelection
                {
                    ChangingField = unrelatedField,
                    CaseCategories =
                        new[]
                        {
                            new KeyValuePair<string, string>()
                        }
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.Subject.Verify(selection);

                fixture.CaseCategories.DidNotReceiveWithAnyArgs().Get(
                                                                      null,
                                                                      null,
                                                                      Arg.Is<string[]>(
                                                                                       a => a.Length == 0),
                                                                      Arg.Is<string[]>(
                                                                                       a => a.Length == 0));
            }

            [Fact]
            public void ChangingCaseTypeShouldUpdateSelection()
            {
                var selection = new CaseDetailsSelection
                {
                    ChangingField = "CaseType",
                    CaseType = "a",
                    CaseCategories =
                        new[]
                        {
                            new KeyValuePair<string, string>("ka", "va"),
                            new KeyValuePair<string, string>("kb", "vb")
                        }
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.CaseCategories.Get(
                                           null,
                                           "a",
                                           Arg.Is<string[]>(a => a.Length == 0),
                                           Arg.Is<string[]>(a => a.Length == 0))
                       .Returns(
                                new[]
                                {
                                    new KeyValuePair<string, string>("ka", "va1"),
                                    new KeyValuePair<string, string>("kc", "vc")
                                });

                var result = fixture.Subject.Verify(selection);

                Assert.Equal("va1", result.CaseCategories.Single().Value);
            }

            [Fact]
            public void ChangingCountryShouldUpdateSelection()
            {
                var selection = new CaseDetailsSelection
                {
                    ChangingField = "Country",
                    CaseType = "a",
                    Countries = new[] {"c"},
                    CaseCategories =
                        new[]
                        {
                            new KeyValuePair<string, string>("ka", "va"),
                            new KeyValuePair<string, string>("kb", "vb")
                        }
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.CaseCategories.Get(
                                           null,
                                           "a",
                                           selection.Countries,
                                           Arg.Is<string[]>(a => a.Length == 0))
                       .Returns(
                                new[]
                                {
                                    new KeyValuePair<string, string>("ka", "va1"),
                                    new KeyValuePair<string, string>("kc", "vc")
                                });

                var result = fixture.Subject.Verify(selection);

                Assert.Equal("va1", result.CaseCategories.Single().Value);
            }

            [Fact]
            public void ChangingPropertyTypeShouldUpdateSelection()
            {
                var selection = new CaseDetailsSelection
                {
                    CaseType = "a",
                    ChangingField = "PropertyType",
                    PropertyTypes = new[] {new KeyValuePair<string, string>("k", "v")},
                    CaseCategories =
                        new[]
                        {
                            new KeyValuePair<string, string>("ka", "va"),
                            new KeyValuePair<string, string>("kb", "vb")
                        }
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.CaseCategories.Get(
                                           null,
                                           "a",
                                           Arg.Is<string[]>(a => a.Length == 0),
                                           Arg.Is<string[]>(a => a.SequenceEqual(new[] {"k"})))
                       .Returns(
                                new[]
                                {
                                    new KeyValuePair<string, string>("ka", "va1"),
                                    new KeyValuePair<string, string>("kc", "vc")
                                });

                var result = fixture.Subject.Verify(selection);

                Assert.Equal("va1", result.CaseCategories.Single().Value);
            }

            [Fact]
            public void ShouldNotUpdateSelectionIfCaseCategoryNotSelected()
            {
                var selection = new CaseDetailsSelection
                {
                    CaseType = "a",
                    ChangingField = "Country",
                    CaseCategories = new KeyValuePair<string, string>[0]
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.Subject.Verify(selection);

                fixture.CaseCategories.DidNotReceiveWithAnyArgs()
                       .Get(
                            null,
                            "a",
                            Arg.Is<string[]>(a => a.Length == 0),
                            Arg.Is<string[]>(a => a.Length == 0));
            }

            [Fact]
            public void ShouldNotUpdateSelectionIfCaseTypeNotSelected()
            {
                var selection = new CaseDetailsSelection
                {
                    ChangingField = "Country",
                    CaseCategories =
                        new[]
                        {
                            new KeyValuePair<string, string>()
                        }
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.Subject.Verify(selection);

                fixture.CaseCategories.DidNotReceiveWithAnyArgs()
                       .Get(
                            null,
                            null,
                            Arg.Is<string[]>(a => a.Length == 0),
                            Arg.Is<string[]>(a => a.Length == 0));
            }
        }

        public class SubType
        {
            [Theory]
            [InlineData("Country")]
            [InlineData("CaseType")]
            [InlineData("PropertyType")]
            [InlineData("CaseCategory")]
            public void ChangingRelatedFieldShouldUpdateSelection(string relatedField)
            {
                var selection = new CaseDetailsSelection
                {
                    ChangingField = relatedField
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.Subject.Verify(selection);

                fixture.SubTypes.Received(1).Get(
                                                 null,
                                                 Arg.Is<string[]>(a => a.Length == 0),
                                                 Arg.Is<string[]>(a => a.Length == 0),
                                                 Arg.Is<string[]>(a => a.Length == 0));
            }
        }

        public class Basis
        {
            [Theory]
            [InlineData("Country")]
            [InlineData("CaseType")]
            [InlineData("PropertyType")]
            [InlineData("CaseCategory")]
            public void ChangingRelatedFieldShouldUpdateSelection(string relatedField)
            {
                var selection = new CaseDetailsSelection
                {
                    ChangingField = relatedField
                };

                var fixture = new CaseDetailsSelectionVerificationFixture();

                fixture.Subject.Verify(selection);

                fixture.Basis.Received(1).Get(null,
                                              Arg.Is<string[]>(a => a.Length == 0),
                                              Arg.Is<string[]>(a => a.Length == 0),
                                              Arg.Is<string[]>(a => a.Length == 0));
            }
        }
    }

    public class CaseDetailsSelectionVerificationFixture : IFixture<CaseDetailsSelectionVerification>
    {
        public CaseDetailsSelectionVerificationFixture()
        {
            PropertyTypes = Substitute.For<IPropertyTypes>();
            CaseCategories = Substitute.For<ICaseCategories>();
            SubTypes = Substitute.For<ISubTypes>();
            Basis = Substitute.For<IBasis>();
        }

        public IBasis Basis { get; set; }

        public ISubTypes SubTypes { get; set; }

        public ICaseCategories CaseCategories { get; set; }

        public IPropertyTypes PropertyTypes { get; set; }

        public CaseDetailsSelectionVerification Subject => new CaseDetailsSelectionVerification(PropertyTypes, CaseCategories, SubTypes, Basis);
    }
}