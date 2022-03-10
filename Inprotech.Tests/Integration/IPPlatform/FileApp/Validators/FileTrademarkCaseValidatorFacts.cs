using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.Integration.IPPlatform.FileApp.Validators;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Cases;
using Xunit;
using Country = Inprotech.Integration.IPPlatform.FileApp.Models.Country;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp.Validators
{
    public class FileTrademarkCaseValidatorFacts
    {
        public class ValidateMethod : FactBase
        {
            Case _case;

            readonly FileCase _fileCase = new FileCase
            {
                ApplicantName = "Some Inventor",
                BibliographicalInformation = new Biblio
                {
                    Title = Fixture.String(),
                    PriorityDate = Fixture.Today().ToString("yyyy-MM-dd"),
                    PriorityNumber = Fixture.String(),
                    PriorityCountry = Fixture.String(),
                    FilingLanguage = Fixture.String(),
                    Classes = new[]
                    {
                        new BibloClasses
                        {
                            Description = Fixture.String(),
                            Id = Fixture.Integer(),
                            Name = Fixture.String()
                        }
                    }
                }
            };

            FileTrademarkCaseValidator CreateSubject()
            {
                _case = new CaseBuilder().Build().In(Db);
                _case.LocalClasses = string.Join(",", _fileCase.BibliographicalInformation.Classes.Select(_ => _.Name));
                _fileCase.Id = _case.Id.ToString();
                return new FileTrademarkCaseValidator(Fixture.Today, Db);
            }

            [Fact]
            public void ShouldReturnErrorForMissingLanguageCombination()
            {
                var subject = CreateSubject();

                var currentLocalClasses = _case.LocalClasses;

                _case.LocalClasses = currentLocalClasses + ",03";

                Assert.False(subject.TryValidate(_fileCase, out var result));
                Assert.Equal(ErrorCodes.MissingClassTextLanguage, string.Format(result.ErrorCode, currentLocalClasses, _case.LocalClasses));
            }

            [Fact]
            public void ShouldReturnErrorWhenBuiltTrademarkCaseDoesNotHaveCaseTitle()
            {
                var subject = CreateSubject();

                _fileCase.BibliographicalInformation.Title = null;

                Assert.False(subject.TryValidate(_fileCase, out var result));
                Assert.Equal(ErrorCodes.MissingTitle, result.ErrorCode);
            }

            [Fact]
            public void ShouldReturnErrorWhenBuiltTrademarkCaseDoesNotHavePriorityCountry()
            {
                var subject = CreateSubject();

                _fileCase.BibliographicalInformation.PriorityCountry = null;

                Assert.False(subject.TryValidate(_fileCase, out var result));
                Assert.Equal(ErrorCodes.MissingPriorityCountry, result.ErrorCode);
            }

            [Fact]
            public void ShouldReturnErrorWhenBuiltTrademarkCaseDoesNotHavePriorityDate()
            {
                var subject = CreateSubject();

                _fileCase.BibliographicalInformation.PriorityDate = null;

                Assert.False(subject.TryValidate(_fileCase, out var result));
                Assert.Equal(ErrorCodes.MissingPriorityDate, result.ErrorCode);
            }

            [Fact]
            public void ShouldReturnErrorWhenBuiltTrademarkCaseDoesNotHavePriorityNumber()
            {
                var subject = CreateSubject();

                _fileCase.BibliographicalInformation.PriorityNumber = null;

                Assert.False(subject.TryValidate(_fileCase, out var result));
                Assert.Equal(ErrorCodes.MissingPriorityNo, result.ErrorCode);
            }

            [Fact]
            public void ShouldReturnErrorWhenBuiltTrademarkCaseMissingApplicantName()
            {
                var subject = CreateSubject();

                _fileCase.ApplicantName = null;

                Assert.False(subject.TryValidate(_fileCase, out var result));
                Assert.Equal(ErrorCodes.MissingPriorityApplicantName, result.ErrorCode);
            }

            [Fact]
            public void ShouldReturnErrorWhenBuiltTrademarkCasePassedDeadlineDate()
            {
                var subject = CreateSubject();

                var lastYear = Fixture.Today().Subtract(TimeSpan.FromDays(366));

                _fileCase.BibliographicalInformation.PriorityDate = lastYear.ToString("yyyy-MM-dd"); /* more than 12 months */

                Assert.False(subject.TryValidate(_fileCase, out var result));
                Assert.Equal(ErrorCodes.PassedPriorityDeadline, result.ErrorCode);
            }

            [Fact]
            public void ShouldReturnErrorWhenBuiltTrademarkCaseWithIncompleteClasses()
            {
                var subject = CreateSubject();

                _fileCase.BibliographicalInformation.Classes.First().Name = null;
                _fileCase.BibliographicalInformation.Classes.First().Description = Fixture.String();

                Assert.False(subject.TryValidate(_fileCase, out var result1));
                Assert.Equal(ErrorCodes.IncompleteClasses, result1.ErrorCode);

                _fileCase.BibliographicalInformation.Classes.First().Name = Fixture.String();
                _fileCase.BibliographicalInformation.Classes.First().Description = null;

                Assert.False(subject.TryValidate(_fileCase, out var result2));
                Assert.Equal(ErrorCodes.IncompleteClasses, result2.ErrorCode);
            }

            [Fact]
            public void ShouldReturnErrorWhenBuiltTrademarkCaseWithoutClasses()
            {
                var subject = CreateSubject();

                _fileCase.BibliographicalInformation.Classes = null;

                Assert.False(subject.TryValidate(_fileCase, out var result));
                Assert.Equal(ErrorCodes.MissingClasses, result.ErrorCode);

                _fileCase.BibliographicalInformation.Classes = new List<BibloClasses>();

                Assert.False(subject.TryValidate(_fileCase, out result));
                Assert.Equal(ErrorCodes.MissingClasses, result.ErrorCode);
            }

            [Fact]
            public void ShouldReturnValidated()
            {
                var subject = CreateSubject();

                Assert.True(subject.TryValidate(_fileCase, out _));
            }
        }

        public class ValidateCountrySelectionMethod : FactBase
        {
            readonly FileCase _fileCase = new FileCase
            {
                ApplicantName = "Some Inventor",
                BibliographicalInformation = new Biblio
                {
                    Title = Fixture.String(),
                    PriorityDate = Fixture.Today().ToString("yyyy-MM-dd"),
                    PriorityNumber = Fixture.String(),
                    PriorityCountry = Fixture.String(),
                    FilingLanguage = Fixture.String(),
                    Classes = new[]
                    {
                        new BibloClasses
                        {
                            Description = Fixture.String(),
                            Id = Fixture.Integer(),
                            Name = "A"
                        },
                        new BibloClasses
                        {
                            Description = Fixture.String(),
                            Id = Fixture.Integer(),
                            Name = "B"
                        },
                        new BibloClasses
                        {
                            Description = Fixture.String(),
                            Id = Fixture.Integer(),
                            Name = "C"
                        }
                    }
                }
            };

            FileTrademarkCaseValidator CreateSubject()
            {
                return new FileTrademarkCaseValidator(Fixture.Today, Db);
            }

            [Fact]
            public void ShoulAllowSameNumberOfClassesToCountriesSent()
            {
                var subject = CreateSubject();

                InstructResult ir;
                var r = subject.TryValidateCountrySelection(
                                                            _fileCase,
                                                            new[]
                                                            {
                                                                new Country("AU"),
                                                                new Country("BR", "A", Fixture.String()),
                                                                new Country("BR", "B", Fixture.String()),
                                                                new Country("BR", "C", Fixture.String()),
                                                                new Country("US"),
                                                                new Country("CN", "A", Fixture.String()),
                                                                new Country("CN", "B", Fixture.String()),
                                                                new Country("CN", "C", Fixture.String())
                                                            }, out ir);

                Assert.True(r);
                Assert.Null(ir);
            }

            [Fact]
            public void ShouldAllowAnySingleCountrySelections()
            {
                var subject = CreateSubject();

                InstructResult ir;
                var r = subject.TryValidateCountrySelection(
                                                            _fileCase,
                                                            new[]
                                                            {
                                                                new Country("AU"),
                                                                new Country("US")
                                                            }, out ir);

                Assert.True(r);
                Assert.Null(ir);
            }

            [Fact]
            public void ShouldRaiseErrorForMismatchedClassCodeForCountriesSent()
            {
                new InprotechKaizen.Model.Cases.Country
                {
                    Id = "BR",
                    Name = "Brazil"
                }.In(Db);

                var wrongClassCode = Fixture.String();

                var subject = CreateSubject();

                InstructResult ir;
                var r = subject.TryValidateCountrySelection(
                                                            _fileCase,
                                                            new[]
                                                            {
                                                                new Country("AU"),
                                                                new Country("BR", "A", Fixture.String()),
                                                                new Country("BR", "B", Fixture.String()),
                                                                new Country("BR", wrongClassCode, Fixture.String()),
                                                                new Country("US")
                                                            }, out ir);

                Assert.False(r);
                Assert.Equal("priority-case-country-class-mismatch-by-class-code", ir.ErrorCode);
                Assert.Equal("Brazil", ir.ErrorArgs.ElementAt(0));
                Assert.Equal("A, B, " + wrongClassCode, ir.ErrorArgs.ElementAt(1));
                Assert.Equal("A, B, C", ir.ErrorArgs.ElementAt(2));
            }

            [Fact]
            public void ShouldRaiseErrorForMismatchedNumberOfCountriesToClassesSent()
            {
                new InprotechKaizen.Model.Cases.Country
                {
                    Id = "BR",
                    Name = "Brazil"
                }.In(Db);

                var subject = CreateSubject();

                InstructResult ir;
                var r = subject.TryValidateCountrySelection(
                                                            _fileCase,
                                                            new[]
                                                            {
                                                                new Country("AU"),
                                                                new Country("BR", "A", Fixture.String()),
                                                                new Country("BR", "C", Fixture.String()),
                                                                new Country("US")
                                                            }, out ir);

                Assert.False(r);
                Assert.Equal("priority-case-country-class-mismatch-by-country", ir.ErrorCode);
                Assert.Equal("Brazil", ir.ErrorArgs.ElementAt(0));
                Assert.Equal("A, B, C", ir.ErrorArgs.ElementAt(1));
            }
        }
    }
}