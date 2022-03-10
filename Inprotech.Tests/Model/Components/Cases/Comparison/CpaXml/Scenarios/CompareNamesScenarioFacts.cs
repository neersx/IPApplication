using System;
using System.Collections.Generic;
using System.Linq;
using CPAXML;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml.Scenarios;
using InprotechKaizen.Model.Components.Cases.Comparison.DataMapping;
using Xunit;
using ComparisonModel = InprotechKaizen.Model.Components.Cases.Comparison.Models;

namespace Inprotech.Tests.Model.Components.Cases.Comparison.CpaXml.Scenarios
{
    public class CompareNamesScenarioFacts
    {
        readonly CompareNamesScenario _subject = new CompareNamesScenario();
        readonly CaseDetails _caseDetails = new CaseDetails("P", "AU");
        readonly IEnumerable<TransactionMessageDetails> _messageDetails = new TransactionMessageDetails[0];

        [Theory]
        [InlineData("Applicant")]
        [InlineData("Inventor")]
        public void ReturnsFormattedAddress(string nameType)
        {
            var formattedNameAddress = new FormattedNameAddress();
            formattedNameAddress.Address = new Address
            {
                FormattedAddress = new FormattedAddress
                {
                    AddressCity = "New York",
                    AddressCountryCode = "US",
                    AddressPostcode = "1",
                    AddressState = "NY",
                    AddressStreet = "Broadway"
                }
            };

            _caseDetails.NameDetails = new List<NameDetails>
            {
                new NameDetails(nameType)
                {
                    AddressBook = new AddressBook
                    {
                        FormattedNameAddress = formattedNameAddress
                    }
                }
            };

            var r =
                (ComparisonScenario<ComparisonModel.Name>)
                _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("New York", r.ComparisonSource.City);
            Assert.Equal("US", r.ComparisonSource.CountryCode);
            Assert.Equal("1", r.ComparisonSource.Postcode);
            Assert.Equal("Broadway", r.ComparisonSource.Street);
            Assert.Equal("NY", r.ComparisonSource.StateName);
        }

        [Theory]
        [InlineData("Applicant")]
        [InlineData("Inventor")]
        public void ReturnsFormattedAddressFromAddressLines(string nameType)
        {
            var formattedNameAddress = new FormattedNameAddress();
            formattedNameAddress.Address = new Address
            {
                FormattedAddress = new FormattedAddress
                {
                    AddressCountryCode = "AU",
                    AddressLine = new List<string>
                    {
                        "Level 3",
                        "York St",
                        "Sydney"
                    },
                    AddressPostcode = "2000"
                }
            };

            _caseDetails.NameDetails = new List<NameDetails>
            {
                new NameDetails(nameType)
                {
                    AddressBook = new AddressBook
                    {
                        FormattedNameAddress = formattedNameAddress
                    }
                }
            };

            var r = (ComparisonScenario<ComparisonModel.Name>)
                _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal(string.Format("Level 3{0}York St{0}Sydney", Environment.NewLine), r.ComparisonSource.Street);
            Assert.Equal("AU", r.ComparisonSource.CountryCode);
        }

        [Theory]
        [InlineData("Examiner")]
        [InlineData("Agent")]
        public void DoesNotReturnsFormattedAddressForOtherNames(string nameType)
        {
            var formattedNameAddress = new FormattedNameAddress();
            formattedNameAddress.Address = new Address
            {
                FormattedAddress = new FormattedAddress
                {
                    AddressCounty = "Australia",
                    AddressBuilding = "AMP Building",
                    AddressCity = "Sydney",
                    AddressRoom = "4",
                    AddressPostOfficeBox = "123",
                    AddressState = "NSW",
                    AddressPostcode = "2000",
                    AddressCountryCode = "AU",
                    AddressLine = new List<string>
                    {
                        "Level 3",
                        "York St",
                        "Sydney"
                    }
                }
            };

            _caseDetails.NameDetails = new List<NameDetails>
            {
                new NameDetails(nameType)
                {
                    AddressBook = new AddressBook
                    {
                        FormattedNameAddress = formattedNameAddress
                    }
                }
            };

            var r = (ComparisonScenario<ComparisonModel.Name>)
                _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Null(r.ComparisonSource.Street);
            Assert.Null(r.ComparisonSource.CountryCode);
            Assert.Null(r.ComparisonSource.Street);
            Assert.Null(r.ComparisonSource.Postcode);
            Assert.Null(r.ComparisonSource.StateName);
            Assert.Null(r.ComparisonSource.City);
        }

        [Fact]
        public void IsWrappedAroundComparisonScenarioForName()
        {
            _caseDetails.NameDetails = new List<NameDetails>
            {
                new NameDetails("Applicant")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.IsType<ComparisonScenario<ComparisonModel.Name>>(r.Single());
        }

        [Fact]
        public void ReturnsAllNames()
        {
            _caseDetails.NameDetails = new List<NameDetails>
            {
                new NameDetails("Applicant"),
                new NameDetails("Inventor")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(2, r.Count());
        }

        [Fact]
        public void ReturnsFormattedName()
        {
            var formattedNameAddress = new FormattedNameAddress
            {
                Name = new CPAXML.Name
                {
                    FormattedName =
                        new FormattedName
                        {
                            FirstName = "Tony",
                            LastName = "Stark"
                        }
                }
            };

            _caseDetails.NameDetails = new List<NameDetails>
            {
                new NameDetails("Applicant")
                {
                    AddressBook = new AddressBook
                    {
                        FormattedNameAddress = formattedNameAddress
                    }
                }
            };

            var r =
                (ComparisonScenario<ComparisonModel.Name>)
                _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("Applicant", r.ComparisonSource.NameTypeCode);
            Assert.Equal("Tony", r.ComparisonSource.FirstName);
            Assert.Equal("Stark", r.ComparisonSource.LastName);
        }

        [Fact]
        public void ReturnsFreeFormattedName()
        {
            var formattedNameAddress = new FormattedNameAddress
            {
                Name = new CPAXML.Name
                {
                    FreeFormatName = new FreeFormatName
                    {
                        FreeFormatNameDetails =
                            new FreeFormatNameDetails
                            {
                                FreeFormatNameLine = new List<string>
                                {
                                    "Stark Industries"
                                }
                            },
                        NameKind = NameKindType.Organisation
                    }
                }
            };
            _caseDetails.NameDetails = new List<NameDetails>
            {
                new NameDetails("Applicant")
                {
                    AddressBook = new AddressBook
                    {
                        FormattedNameAddress = formattedNameAddress
                    }
                }
            };

            var r = (ComparisonScenario<ComparisonModel.Name>)
                _subject.Resolve(_caseDetails, _messageDetails).Single();

            Assert.Equal("Applicant", r.ComparisonSource.NameTypeCode);
            Assert.Equal("Stark Industries", r.ComparisonSource.FreeFormatName);
            Assert.False(r.ComparisonSource.IsIndividual.GetValueOrDefault());
        }

        [Fact]
        public void ShouldReturnNameComparisonType()
        {
            _caseDetails.NameDetails = new List<NameDetails>
            {
                new NameDetails("Applicant")
            };

            var r = _subject.Resolve(_caseDetails, _messageDetails).ToArray();

            Assert.Equal(ComparisonType.Names, r.Single().ComparisonType);
        }
        
        [Fact]
        public void AllowsAllSourceSystem()
        {
            Assert.True(_subject.IsAllowed(Fixture.String()));
        }
    }
}