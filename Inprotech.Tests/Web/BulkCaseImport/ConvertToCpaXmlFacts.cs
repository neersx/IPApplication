using System;
using System.Linq;
using System.Xml.Linq;
using CPAXML;
using Inprotech.Contracts;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BulkCaseImport;
using Inprotech.Web.BulkCaseImport.CustomColumnsResolution;
using Inprotech.Web.BulkCaseImport.Validators;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Names;
using Newtonsoft.Json.Linq;
using NSubstitute;
using Xunit;
using Name = InprotechKaizen.Model.Names.Name;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class ConvertToCpaXmlFacts
    {
        public class ConvertToCpaXmlFixture : IFixture<ConvertToCpaXml>
        {
            readonly InMemoryDbContext _db;

            public ConvertToCpaXmlFixture(InMemoryDbContext db)
            {
                _db = db;

                SiteConfiguration = Substitute.For<ISiteConfiguration>();

                CustomColumnsResolver = Substitute.For<ICustomColumnsResolver>();

                SenderDetailsValidator = Substitute.For<ISenderDetailsValidator>();

                Clock = Substitute.For<Func<DateTime>>();
                Clock().Returns(Fixture.Today());

                Logger = Substitute.For<ILogger<ConvertToCpaXml>>();
                XmlIllegalCharSanitiser = Substitute.For<IXmlIllegalCharSanitiser>();

                Subject = new ConvertToCpaXml(db, SiteConfiguration, Clock, CustomColumnsResolver, Logger, SenderDetailsValidator, XmlIllegalCharSanitiser);
            }

            public ISiteConfiguration SiteConfiguration { get; set; }

            public ICustomColumnsResolver CustomColumnsResolver { get; set; }

            public ISenderDetailsValidator SenderDetailsValidator { get; set; }

            public IXmlIllegalCharSanitiser XmlIllegalCharSanitiser { get; set; }

            public ILogger<ConvertToCpaXml> Logger { get; set; }

            public Func<DateTime> Clock { get; }

            public ConvertToCpaXml Subject { get; }

            public ConvertToCpaXmlFixture WithEdeIdentifier(string alias, bool setInSiteControl = true)
            {
                var homeNameAlias = new NameAlias
                {
                    AliasType = new NameAliasType
                    {
                        Code = KnownAliasTypes.EdeIdentifier
                    }.In(_db),
                    Name = new Name {NameCode = alias}.In(_db),
                    Alias = alias
                }.In(_db);

                if (setInSiteControl)
                {
                    SiteConfiguration.HomeName().Returns(homeNameAlias.Name);
                }

                return this;
            }

            public ConvertToCpaXmlFixture WithCustomColumnResolverResult(bool result)
            {
                CustomColumnsResolver.ResolveCustomColumns(Arg.Any<CaseDetails>(), Arg.Any<JToken>(), out _)
                                     .Returns(result);

                return this;
            }

            public ConvertToCpaXmlFixture WithRequestTypeInPrefixAs(bool valid)
            {
                SenderDetailsValidator.IsValidRequestType(Arg.Any<string>()).Returns(valid);

                return this;
            }
        } // ReSharper disable PossibleNullReferenceException
        public class FromMethod : FactBase
        {
            readonly XNamespace _ns = "http://www.cpasoftwaresolutions.com";

            [Theory]
            [InlineData("a", null, null, null, null, null, null, null, null, null, null, null)]
            [InlineData("AU", "Trademark", "Normal", "Re-registration", "Convention", "Device", "123", "Large", 1, 2, "sydney", "1234")]
            public void PopulatesCaseDetails(string country, string property, string caseCategory, string subType, string basis,
                                             string typeOfMark, string caseRefStem, string entitySize, int? numberDesigns, int? numberClaims,
                                             string caseOffice, string family)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(
                                      new JObject
                                      {
                                          {Fields.Country, country},
                                          {Fields.PropertyType, property},
                                          {Fields.CaseCategory, caseCategory},
                                          {Fields.Basis, basis},
                                          {Fields.SubStype, subType},
                                          {Fields.TypeOfMark, typeOfMark},
                                          {Fields.CaseReferenceStem, caseRefStem},
                                          {Fields.EntitySize, entitySize},
                                          {Fields.NumberOfDesigns, numberDesigns},
                                          {Fields.NumberOfClaims, numberClaims},
                                          {Fields.CaseOffice, caseOffice},
                                          {Fields.Family, family}
                                      });
                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCase = cpaxml.Descendants(_ns + "CaseDetails").Single();

                Assert.Equal(country, (string) theCase.Element(_ns + "CaseCountryCode"));
                Assert.Equal(property, (string) theCase.Element(_ns + "CasePropertyTypeCode"));
                Assert.Equal("Property", (string) theCase.Element(_ns + "CaseTypeCode")); /* defaulted */
                Assert.Equal(caseCategory, (string) theCase.Element(_ns + "CaseCategoryCode"));
                Assert.Equal(subType, (string) theCase.Element(_ns + "CaseSubTypeCode"));
                Assert.Equal(basis, (string) theCase.Element(_ns + "CaseBasisCode"));
                Assert.Equal(typeOfMark, (string) theCase.Element(_ns + "TypeOfMark"));
                Assert.Equal(caseRefStem, (string) theCase.Element(_ns + "CaseReferenceStem"));
                Assert.Equal(numberDesigns, (int?) theCase.Element(_ns + "NumberDesigns"));
                Assert.Equal(numberClaims, (int?) theCase.Element(_ns + "NumberClaims"));
                Assert.Equal(family, (string) theCase.Element(_ns + "Family"));
                Assert.Equal(caseOffice, (string) theCase.Element(_ns + "CaseOffice"));

                Assert.Null(theCase.Element(_ns + "DescriptionDetails"));
            }

            [Theory]
            [InlineData("{ 'Case Type': 'Jack' }", "Jack")]
            [InlineData("{ 'Case Type': '' ,  'Client Name': 'n'}", "Property")]
            [InlineData("{ 'Client Name': 'n'}", "Property")]
            public void PopulatesCaseType(string json, string expectedCaseType)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(JToken.Parse(json));

                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                Assert.Equal(expectedCaseType, (string) theCaseDetails.Element(_ns + "CaseTypeCode"));
            }

            [Theory]
            [InlineData("{ 'Client Name': 'n', 'Client Given Names': 'g', 'Client Name Code': '1234', 'Client Case Reference': 'Y27' }", NameTypes.Client)]
            [InlineData("{ 'Agent Name': 'n', 'Agent Given Names': 'g', 'Agent Name Code': '1234', 'Agent Case Reference': 'Y27' }", NameTypes.Agent)]
            public void PopulatesDifferentKindsOfIndividualNamesWithReference(string json, string expectedNameTypeCode)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(JToken.Parse(json));

                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var theNameDetails = theCaseDetails.Element(_ns + "NameDetails");
                var theName = theNameDetails.Descendants(_ns + "Name").Single();
                var theFormattedName = theName.Element(_ns + "FormattedName");

                Assert.Equal(expectedNameTypeCode, (string) theNameDetails.Element(_ns + "NameTypeCode"));
                Assert.Equal("Y27", (string) theNameDetails.Element(_ns + "NameReference"));
                Assert.Equal("1234", (string) theName.Element(_ns + "ReceiverNameIdentifier"));
                Assert.Null(theFormattedName.Element(_ns + "OrganizationName"));
                Assert.Equal("g", (string) theFormattedName.Element(_ns + "FirstName"));
                Assert.Equal("n", (string) theFormattedName.Element(_ns + "LastName"));
            }

            [Theory]
            [InlineData("{ 'Applicant Name': 'n', 'Applicant Given Names': 'g', 'Applicant Name Code': '1234' }", NameTypes.Applicant)]
            [InlineData("{ 'Staff Name': 'n', 'Staff Given Names': 'g', 'Staff Name Code': '1234' }", NameTypes.Staff)]
            public void PopulatesDifferentKindsOfIndividualNames(string json, string expectedNameTypeCode)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(JToken.Parse(json));
                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();

                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var theNameDetails = theCaseDetails.Element(_ns + "NameDetails");
                var theName = theNameDetails.Descendants(_ns + "Name").Single();
                var theFormattedName = theName.Element(_ns + "FormattedName");

                Assert.Equal(expectedNameTypeCode, (string) theNameDetails.Element(_ns + "NameTypeCode"));
                Assert.Null(theNameDetails.Element(_ns + "NameReference"));
                Assert.Equal("1234", (string) theName.Element(_ns + "ReceiverNameIdentifier"));
                Assert.Equal("g", (string) theFormattedName.Element(_ns + "FirstName"));
                Assert.Equal("n", (string) theFormattedName.Element(_ns + "LastName"));
                Assert.Null(theFormattedName.Element(_ns + "OrganizationName"));
            }

            [Theory]
            [InlineData("{ 'Applicant Name': 'n', 'Applicant Name Code': '1234' }", NameTypes.Applicant)]
            [InlineData("{ 'Client Name': 'n', 'Client Name Code': '1234' }", NameTypes.Client)]
            [InlineData("{ 'Agent Name': 'n', 'Agent Name Code': '1234' }", NameTypes.Agent)]
            public void PopulatesDifferentKindsOfOrgNames(string json, string expectedNameTypeCode)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(JToken.Parse(json));
                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();

                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var theNameDetails = theCaseDetails.Element(_ns + "NameDetails");
                var theName = theNameDetails.Descendants(_ns + "Name").Single();
                var theFormattedName = theName.Element(_ns + "FormattedName");

                Assert.Equal(expectedNameTypeCode, (string) theNameDetails.Element(_ns + "NameTypeCode"));
                Assert.Equal("1234", (string) theName.Element(_ns + "ReceiverNameIdentifier"));
                Assert.Equal("n", (string) theFormattedName.Element(_ns + "OrganizationName"));
                Assert.Null(theFormattedName.Element(_ns + "FirstName"));
                Assert.Null(theFormattedName.Element(_ns + "LastName"));
            }

            [Theory]
            [InlineData("{ 'Inventor Name Code': '1234', 'Inventor Name': 'n', 'Inventor Given Names': 'b' }", NameTypes.Inventor)]
            public void PopulateInventors(string json, string expectedNameTypeCode)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(JToken.Parse(json));
                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();

                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var theNameDetails = theCaseDetails.Element(_ns + "NameDetails");
                var theName = theNameDetails.Descendants(_ns + "Name").Single();
                var theFormattedName = theName.Element(_ns + "FormattedName");

                Assert.Equal(expectedNameTypeCode, (string) theNameDetails.Element(_ns + "NameTypeCode"));
                Assert.Equal("1234", (string) theName.Element(_ns + "ReceiverNameIdentifier"));
                Assert.Equal("b", (string) theFormattedName.Element(_ns + "FirstName"));
                Assert.Equal("n", (string) theFormattedName.Element(_ns + "LastName"));
            }

            [Theory]
            [InlineData("{ 'Applicant Name': '', 'Applicant Name Code': '1234' }", NameTypes.Applicant)]
            [InlineData("{ 'Client Name': '', 'Client Name Code': '1234' }", NameTypes.Client)]
            [InlineData("{ 'Agent Name': '', 'Agent Name Code': '1234' }", NameTypes.Agent)]
            public void PopulatesIfNameCodeOnly(string json, string expectedNameTypeCode)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(JToken.Parse(json));
                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();

                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var theNameDetails = theCaseDetails.Element(_ns + "NameDetails");
                var theName = theNameDetails.Descendants(_ns + "Name").Single();

                Assert.Equal(expectedNameTypeCode, (string) theNameDetails.Element(_ns + "NameTypeCode"));
                Assert.Equal("1234", (string) theName.Element(_ns + "ReceiverNameIdentifier"));
                Assert.Null(theName.Element(_ns + "FormattedName"));
            }

            [Theory]
            [InlineData(Fields.ApplicationNumber, "1234", Fields.ApplicationDate, "1999-01-02", NumberTypes.Application, Events.Application)]
            [InlineData(Fields.PublicationNumber, "1234", Fields.PublicationDate, "1999-01-02", NumberTypes.Publication, Events.Publication)]
            [InlineData(Fields.RegistrationNumber, "1234", Fields.RegistrationDate, "1999-01-02", NumberTypes.RegistrationOrGrant, Events.RegistrationOrGrant)]
            public void PopulatesOfficialNumbersAndDates(string numberField, string number, string eventField, string date, string expectedNumberType, string expectedEventCode)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JObject();
                data[numberField] = number;
                data[eventField] = date;
                var fields = new[] {numberField, eventField};

                var r = f.Subject.From(new JArray(data), "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var theIdentifierNumberDetails = theCaseDetails.Element(_ns + "IdentifierNumberDetails");
                var theEventDetails = theCaseDetails.Element(_ns + "EventDetails");

                Assert.Equal(expectedNumberType, (string) theIdentifierNumberDetails.Element(_ns + "IdentifierNumberCode"));
                Assert.Equal("1234", (string) theIdentifierNumberDetails.Element(_ns + "IdentifierNumberText"));

                Assert.Equal(expectedEventCode, (string) theEventDetails.Element(_ns + "EventCode"));
                Assert.Equal("1999-01-02", (string) theEventDetails.Element(_ns + "EventDate"));
            }

            static string AddSuffix(string stringValue, string suffix)
            {
                return string.IsNullOrEmpty(stringValue) ? stringValue : stringValue + suffix;
            }

            [Theory]
            [InlineData("SG", "1234", "1999-01-02")]
            [InlineData("SG", null, null)]
            [InlineData(null, "1234", null)]
            [InlineData(null, null, "1999-01-02")]
            public void PopulatesPriorityDetails(string priorityCountry, string priorityNumber, string priorityDate)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(
                                      new JObject
                                      {
                                          {Fields.RelatedCase.PriorityCountry, priorityCountry},
                                          {Fields.RelatedCase.PriorityNumber, priorityNumber},
                                          {Fields.RelatedCase.PriorityDate, priorityDate}
                                      });

                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var theAssociatedCaseDetails = theCaseDetails.Element(_ns + "AssociatedCaseDetails");

                CheckRelatedCaseData(theAssociatedCaseDetails, priorityCountry, priorityNumber, priorityDate);
            }

            [Theory]
            [InlineData("SG", "1234", "1999-01-02")]
            [InlineData("SG", null, null)]
            [InlineData(null, "1234", null)]
            [InlineData(null, null, "1999-01-02")]
            public void PopulatesMultiplePriorityDetails(string priorityCountry, string priorityNumber, string priorityDate)
            {
                const string suffix1 = "- A";
                const string suffix2 = "- B";
                const string suffix3 = "- C";

                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");
                var data = new JArray(
                                      new JObject
                                      {
                                          {Fields.RelatedCase.PriorityCountry + suffix1, AddSuffix(priorityCountry, suffix1)},
                                          {Fields.RelatedCase.PriorityNumber + suffix1, AddSuffix(priorityNumber, suffix1)},
                                          {Fields.RelatedCase.PriorityDate + suffix1, priorityDate},
                                          {Fields.RelatedCase.PriorityCountry + suffix2, AddSuffix(priorityCountry, suffix2)},
                                          {Fields.RelatedCase.PriorityNumber + suffix2, AddSuffix(priorityNumber, suffix2)},
                                          {Fields.RelatedCase.PriorityDate + suffix2, priorityDate},
                                          {" " + Fields.RelatedCase.PriorityCountry + suffix3 + " ", AddSuffix(priorityCountry, suffix3)},
                                          {" " + Fields.RelatedCase.PriorityNumber + suffix3 + " ", AddSuffix(priorityNumber, suffix3)},
                                          {" " + Fields.RelatedCase.PriorityDate + suffix3 + " ", priorityDate}
                                      });

                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var associatedCaseDetails = theCaseDetails.Elements(_ns + "AssociatedCaseDetails").ToArray();

                CheckRelatedCaseData(associatedCaseDetails.ElementAt(0), AddSuffix(priorityCountry, suffix1), AddSuffix(priorityNumber, suffix1), priorityDate);
                CheckRelatedCaseData(associatedCaseDetails.ElementAt(1), AddSuffix(priorityCountry, suffix2), AddSuffix(priorityNumber, suffix2), priorityDate);
                CheckRelatedCaseData(associatedCaseDetails.ElementAt(2), AddSuffix(priorityCountry, suffix3), AddSuffix(priorityNumber, suffix3), priorityDate);
            }

            void CheckRelatedCaseData(XElement caseDetails, string priorityCountry, string priorityNumber, string priorityDate)
            {
                Assert.Equal(Relations.Priority, (string) caseDetails.Element(_ns + "AssociatedCaseRelationshipCode"));
                var theNumber = caseDetails.Element(_ns + "AssociatedCaseIdentifierNumberDetails");
                var theEvent = caseDetails.Element(_ns + "AssociatedCaseEventDetails");

                if (!string.IsNullOrEmpty(priorityCountry))
                {
                    Assert.Equal(priorityCountry, (string) caseDetails.Element(_ns + "AssociatedCaseCountryCode"));
                }
                else
                {
                    Assert.Null((string) caseDetails.Element(_ns + "AssociatedCaseCountryCode"));
                }

                if (!string.IsNullOrWhiteSpace(priorityNumber))
                {
                    Assert.Equal(NumberTypes.Application, (string) theNumber.Element(_ns + "IdentifierNumberCode"));
                    Assert.Equal(priorityNumber, (string) theNumber.Element(_ns + "IdentifierNumberText"));
                }
                else
                {
                    Assert.Null(theNumber);
                }

                if (!string.IsNullOrWhiteSpace(priorityDate))
                {
                    Assert.Equal(Events.EarliestPriority, (string) theEvent.Element(_ns + "EventCode"));
                    Assert.Equal(priorityDate, (string) theEvent.Element(_ns + "EventDate"));
                }
                else
                {
                    Assert.Null(theEvent);
                }
            }

            [Theory]
            [InlineData("1999-01-02")]
            [InlineData(null)]
            public void PopulatesEarliestPriorityEvent(string earliestPriorityDate)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithCustomColumnResolverResult(true)
                        .WithEdeIdentifier("MYAC");

                var data = new JArray(
                                      new JObject
                                      {
                                          {"a", "b"},
                                          {Fields.EarliestPriorityDate, earliestPriorityDate}
                                      });

                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var earliestPriorityEvent = theCaseDetails.Element(_ns + "EventDetails");

                if (earliestPriorityDate != null)
                {
                    Assert.Equal(Events.EarliestPriority, (string) earliestPriorityEvent.Element(_ns + "EventCode"));
                    Assert.Equal(earliestPriorityDate, (string) earliestPriorityEvent.Element(_ns + "EventDate"));
                }
                else
                {
                    Assert.Null(earliestPriorityEvent);
                }
            }

            [Theory]
            [InlineData("Parent of Divisional", "SG", "1234", "1999-01-02")]
            [InlineData("Parent of Divisional", "SG", null, null)]
            public void PopulatesParentDetails(string parentRelationship, string parentCountry, string parentNumber, string parentDate)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(
                                      new JObject
                                      {
                                          {Fields.RelatedCase.ParentRelationship, parentRelationship},
                                          {Fields.RelatedCase.ParentCountry, parentCountry},
                                          {Fields.RelatedCase.ParentNumber, parentNumber},
                                          {Fields.RelatedCase.ParentDate, parentDate}
                                      });

                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var theAssociatedCaseDetails = theCaseDetails.Element(_ns + "AssociatedCaseDetails");
                CheckParentCaseData(theAssociatedCaseDetails, parentRelationship, parentCountry, parentNumber, parentDate);
            }

            [Theory]
            [InlineData("Parent of Divisional", "SG", "1234", "1999-01-02")]
            [InlineData("Parent of Divisional", "SG", null, null)]
            public void PopulatesMultipleParentDetails(string parentRelationship, string parentCountry, string parentNumber, string parentDate)
            {
                const string suffix1 = " - 1";
                const string suffix2 = " - 2";
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(
                                      new JObject
                                      {
                                          {Fields.RelatedCase.ParentRelationship + suffix1, AddSuffix(parentRelationship, suffix1)},
                                          {Fields.RelatedCase.ParentCountry + suffix1, AddSuffix(parentCountry, suffix1)},
                                          {Fields.RelatedCase.ParentNumber + suffix1, AddSuffix(parentNumber, suffix1)},
                                          {Fields.RelatedCase.ParentDate + suffix1, parentDate},
                                          {Fields.RelatedCase.ParentRelationship + suffix2, AddSuffix(parentRelationship, suffix2)},
                                          {Fields.RelatedCase.ParentCountry + suffix2, AddSuffix(parentCountry, suffix2)},
                                          {Fields.RelatedCase.ParentNumber + suffix2, AddSuffix(parentNumber, suffix2)},
                                          {Fields.RelatedCase.ParentDate + suffix2, parentDate}
                                      });

                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var associatedCaseDetails = theCaseDetails.Elements(_ns + "AssociatedCaseDetails").ToList();
                CheckParentCaseData(associatedCaseDetails.First(), AddSuffix(parentRelationship, suffix1), AddSuffix(parentCountry, suffix1), AddSuffix(parentNumber, suffix1), parentDate);
                CheckParentCaseData(associatedCaseDetails.Last(), AddSuffix(parentRelationship, suffix2), AddSuffix(parentCountry, suffix2), AddSuffix(parentNumber, suffix2), parentDate);
            }

            void CheckParentCaseData(XElement caseDetails, string parentRelationship, string parentCountry, string parentNumber, string parentDate)
            {
                var theNumber = caseDetails.Element(_ns + "AssociatedCaseIdentifierNumberDetails");
                var theEvent = caseDetails.Element(_ns + "AssociatedCaseEventDetails");

                Assert.Equal(parentRelationship, (string) caseDetails.Element(_ns + "AssociatedCaseRelationshipCode"));
                Assert.Equal(parentCountry, (string) caseDetails.Element(_ns + "AssociatedCaseCountryCode"));

                if (!string.IsNullOrWhiteSpace(parentNumber))
                {
                    Assert.Equal(NumberTypes.Application, (string) theNumber.Element(_ns + "IdentifierNumberCode"));
                    Assert.Equal(parentNumber, (string) theNumber.Element(_ns + "IdentifierNumberText"));
                }
                else
                {
                    Assert.Null(theNumber);
                }

                if (!string.IsNullOrWhiteSpace(parentDate))
                {
                    Assert.Equal(Events.Application, (string) theEvent.Element(_ns + "EventCode"));
                    Assert.Equal(parentDate, (string) theEvent.Element(_ns + "EventDate"));
                }
                else
                {
                    Assert.Null(theEvent);
                }
            }

            [Theory]
            [InlineData("A New Column")]
            [InlineData("A New Column    ")]
            [InlineData("    A New Column")]
            public void CallCustomColumnResolver(string columnName)
            {
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithEdeIdentifier("MYAC")
                        .WithCustomColumnResolverResult(true);

                var data = new JArray(new JObject
                {
                    {"Property Type", "Patent"},
                    {"Country", "AU"},
                    {columnName, "1234"}
                });

                var fields = new[] {"Property Type", "Country", "A New Column"};

                f.Subject.From(data, "input.csv", fields);

                f.CustomColumnsResolver
                 .Received(1)
                 .ResolveCustomColumns(Arg.Any<CaseDetails>(), Arg.Is<JToken>(x => x.Value<string>("A New Column") == "1234"), out _);
            }

            [Fact]
            public void AssignsTransactionIdentifierForEachCase()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithCustomColumnResolverResult(true)
                        .WithEdeIdentifier("MYAC");

                var fields = new[] {"a"};
                var r = f.Subject.From(JToken.Parse("[{'a':'b'},{'a':'b'},{'a':'b'}]"), "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var transactionBodies = cpaxml.Descendants(_ns + "TransactionBody").ToArray();

                Assert.Equal(3, transactionBodies.Count());
                Assert.Equal("2", transactionBodies.First().Element(_ns + "TransactionIdentifier").Value);
                Assert.Equal("4", transactionBodies.Last().Element(_ns + "TransactionIdentifier").Value);
            }

            [Fact]
            public void CaseDetailsFieldNamesWithTrailingSpacesAreAccepted()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(
                                      new JObject
                                      {
                                          {" " + Fields.Country + " ", "AU"},
                                          {" " + Fields.PropertyType + " ", "Trademark"},
                                          {" " + Fields.CaseCategory + " ", "Normal"},
                                          {" " + Fields.Basis + " ", "Re-registration"},
                                          {" " + Fields.SubStype + " ", "Convention"},
                                          {" " + Fields.TypeOfMark + " ", "Device"},
                                          {" " + Fields.CaseReferenceStem + " ", "123"},
                                          {" " + Fields.EntitySize + " ", "Large"},
                                          {" " + Fields.NumberOfDesigns + " ", 1},
                                          {" " + Fields.NumberOfClaims + " ", 2},
                                          {" " + Fields.Title + " ", "rondon shoes"},
                                          {" " + Fields.CaseOffice + " ", "sydney"},
                                          {" " + Fields.Family + " ", "1234"}
                                      });
                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCase = cpaxml.Descendants(_ns + "CaseDetails").Single();

                Assert.Equal("AU", (string) theCase.Element(_ns + "CaseCountryCode"));
                Assert.Equal("Trademark", (string) theCase.Element(_ns + "CasePropertyTypeCode"));
                Assert.Equal("Property", (string) theCase.Element(_ns + "CaseTypeCode")); /* defaulted */
                Assert.Equal("Normal", (string) theCase.Element(_ns + "CaseCategoryCode"));
                Assert.Equal("Convention", (string) theCase.Element(_ns + "CaseSubTypeCode"));
                Assert.Equal("Re-registration", (string) theCase.Element(_ns + "CaseBasisCode"));
                Assert.Equal("Device", (string) theCase.Element(_ns + "TypeOfMark"));
                Assert.Equal("123", (string) theCase.Element(_ns + "CaseReferenceStem"));
                Assert.Equal(1, (int?) theCase.Element(_ns + "NumberDesigns"));
                Assert.Equal(2, (int?) theCase.Element(_ns + "NumberClaims"));
                Assert.Equal("1234", (string) theCase.Element(_ns + "Family"));
                Assert.Equal("sydney", (string) theCase.Element(_ns + "CaseOffice"));

                var title = theCase.Element(_ns + "DescriptionDetails");

                Assert.Equal("Short Title", (string) title.Element(_ns + "DescriptionCode"));
                Assert.Equal("rondon shoes", (string) title.Element(_ns + "DescriptionText"));
            }

            [Fact]
            public void FilterOutBlankRowsFromCsv()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithCustomColumnResolverResult(true)
                        .WithEdeIdentifier("MYAC");
                var fields = new[] {"a", string.Empty};
                var r = f.Subject.From(JToken.Parse("[{}, {'':''}, {'a':'b'}]"), "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var transactionBodies = cpaxml.Descendants(_ns + "TransactionBody").ToArray();

                Assert.Single(transactionBodies);
            }

            [Fact]
            public void PopulateGoodsServices()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var data = new JArray(
                                      new JObject
                                      {
                                          {Fields.Classes, "01, 02"},
                                          {Fields.GoodsServicesDescription, "text1 | text2"}
                                      },
                                      new JObject
                                      {
                                          {Fields.Classes, "01"},
                                          {Fields.GoodsServicesDescription, "text1|text2"}
                                      },
                                      new JObject
                                      {
                                          {Fields.Classes, "01,02"},
                                          {Fields.GoodsServicesDescription, "text1"}
                                      });

                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var caseGoods1 = cpaxml.Descendants(_ns + "CaseDetails").ElementAt(0).Descendants(_ns + "GoodsServicesDetails").ToArray();
                var caseGoods2 = cpaxml.Descendants(_ns + "CaseDetails").ElementAt(1).Descendants(_ns + "GoodsServicesDetails").ToArray();
                var caseGoods3 = cpaxml.Descendants(_ns + "CaseDetails").ElementAt(2).Descendants(_ns + "GoodsServicesDetails").ToArray();

                Assert.True(caseGoods1.Elements(_ns + "ClassificationTypeCode").All(a => a.Value == "Domestic"));
                Assert.Equal("01", (string) caseGoods1[0].Descendants(_ns + "ClassNumber").First());
                Assert.Equal("text1", (string) caseGoods1[0].Descendants(_ns + "GoodsServicesDescription").First());

                Assert.Equal("02", (string) caseGoods1[1].Descendants(_ns + "ClassNumber").First());
                Assert.Equal("text2", (string) caseGoods1[1].Descendants(_ns + "GoodsServicesDescription").First());

                Assert.Equal("01", (string) caseGoods2[0].Descendants(_ns + "ClassNumber").First());
                Assert.Equal("text1", (string) caseGoods2[0].Descendants(_ns + "GoodsServicesDescription").First());

                Assert.Empty(caseGoods2[1].Descendants(_ns + "ClassNumber"));
                Assert.Equal("text2", (string) caseGoods2[1].Descendants(_ns + "GoodsServicesDescription").First());

                Assert.Equal("01", (string) caseGoods3[0].Descendants(_ns + "ClassNumber").First());
                Assert.Equal("text1", (string) caseGoods3[0].Descendants(_ns + "GoodsServicesDescription").First());

                Assert.Equal("02", (string) caseGoods3[1].Descendants(_ns + "ClassNumber").First());
                Assert.Equal(string.Empty, (string) caseGoods3[1].Descendants(_ns + "GoodsServicesDescription").First());
            }

            [Fact]
            public void PopulatesDesignatedCountries()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithCustomColumnResolverResult(true)
                        .WithEdeIdentifier("MYAC");

                var data = new JArray(
                                      new JObject
                                      {
                                          {Fields.DesignatedCountries, "AU, UK, US"}
                                      },
                                      new JObject
                                      {
                                          {"a", "b"},
                                          {Fields.DesignatedCountries, null}
                                      });
                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var firstCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").First();
                var nextCaseDetails = cpaxml.Descendants(_ns + "CaseDetails").Last();

                var theDesignatedCountries = firstCaseDetails.Elements(_ns + "DesignatedCountryDetails").ToArray();

                Assert.Equal(3, theDesignatedCountries.Count());
                Assert.Equal("AU", (string) theDesignatedCountries.Elements(_ns + "DesignatedCountryCode").First());
                Assert.Equal("US", (string) theDesignatedCountries.Elements(_ns + "DesignatedCountryCode").Last());

                Assert.Null(nextCaseDetails.Element(_ns + "DesignatedCountryDetails"));
            }

            [Fact]
            public void PopulatesRequiredIdsFromFileName_AgentInput()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithCustomColumnResolverResult(true)
                        .WithEdeIdentifier("ABC", false)
                        .WithRequestTypeInPrefixAs(true);

                var fields = new[] {"a"};
                var r = f.Subject.From(JToken.Parse("[{'a':'b'}]"), "Agent Input~ABC~input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var senderDetails = cpaxml.Element(_ns + "TransactionHeader")
                                          .Element(_ns + "SenderDetails");

                Assert.Equal("ABC", senderDetails.Element(_ns + "Sender").Value);
                Assert.Equal("Agent Input", senderDetails.Element(_ns + "SenderRequestType").Value);
                Assert.Equal("input", senderDetails.Element(_ns + "SenderRequestIdentifier").Value);
                Assert.Equal("Agent Input~ABC~input.xml", senderDetails.Element(_ns + "SenderFilename").Value);
                Assert.Equal("Agent Input~ABC~input.xml", r.InputFileName);
            }

            [Fact]
            public void PopulatesSenderRequestType()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithCustomColumnResolverResult(true)
                        .WithEdeIdentifier("MYAC")
                        .WithRequestTypeInPrefixAs(true);

                var fields = new[] {"a"};
                var r = f.Subject.From(JToken.Parse("[{'a':'b'}]"), "Agent Input~MYAC~input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var senderDetails = cpaxml.Element(_ns + "TransactionHeader")
                                          .Element(_ns + "SenderDetails");

                Assert.Equal("Agent Input", senderDetails.Element(_ns + "SenderRequestType").Value);
            }

            [Fact]
            public void PopulatesShortTitle()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var cases = new JArray(
                                       new JObject
                                       {
                                           {Fields.Title, "rondon shoes"}
                                       });

                var fields = cases[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(cases, "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var theCase = cpaxml.Descendants(_ns + "CaseDetails").Single();
                var title = theCase.Element(_ns + "DescriptionDetails");

                Assert.Equal("Short Title", (string) title.Element(_ns + "DescriptionCode"));
                Assert.Equal("rondon shoes", (string) title.Element(_ns + "DescriptionText"));
            }

            [Fact]
            public void PopulatesTransactionHeader()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithCustomColumnResolverResult(true)
                        .WithEdeIdentifier("MYAC");
                var fields = new[] {"a"};
                var r = f.Subject.From(JToken.Parse("[{'a':'b'}]"), "input.csv", fields);

                XElement cpaxml = XElement.Parse(r.CpaXml);

                var senderDetails = cpaxml.Element(_ns + "TransactionHeader")
                                          .Element(_ns + "SenderDetails");

                Assert.Equal("MYAC", senderDetails.Element(_ns + "Sender").Value);
                Assert.Equal("Case Import", senderDetails.Element(_ns + "SenderRequestType").Value);
                Assert.Equal("input", senderDetails.Element(_ns + "SenderRequestIdentifier").Value);
                Assert.Equal("input.xml", senderDetails.Element(_ns + "SenderFilename").Value);
                Assert.Equal(Fixture.Today().ToString("yyyy-MM-dd"), senderDetails.Element(_ns + "SenderProducedDate").Value);
                Assert.Equal("Inprotech Web Applications", senderDetails.Element(_ns + "SenderSoftware").Element(_ns + "SenderSoftwareName").Value);
                Assert.Matches("([0-9].{4,4}).([0-9]*).([0-9]*)", senderDetails.Element(_ns + "SenderSoftware").Element(_ns + "SenderSoftwareVersion").Value);
                Assert.Equal("input.xml", r.InputFileName);
            }

            [Fact]
            public void ReturnsErrrorForInvalidSenderRequestType()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithEdeIdentifier("MYAC")
                        .WithRequestTypeInPrefixAs(false);

                var fields = new[] {"a"};
                var r = f.Subject.From(JToken.Parse("[{'a':'b'}]"), "Agent Response~input.csv", fields);

                Assert.Equal("invalid-input", r.Result);
                Assert.Equal(1, r.Errors.Length);
                Assert.Equal("Invalid sender request type used - 'Agent Response'. Rectify and try again.", r.Errors[0].ErrorMessage);
            }

            [Fact]
            public void ReturnsErrrorIfSenderidRequiredAndNotProvided()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithEdeIdentifier("MYAC")
                        .WithRequestTypeInPrefixAs(true);

                var fields = new[] {"a"};
                var r = f.Subject.From(JToken.Parse("[{'a':'b'}]"), "Agent Input~input.csv", fields);

                Assert.Equal("invalid-input", r.Result);
                Assert.Equal(1, r.Errors.Length);
                Assert.Equal("Sender Id needs to be provided as part of filename for sender request type - 'Agent Input'. Rectify and try again.", r.Errors[0].ErrorMessage);
            }

            [Fact]
            public void ReturnsResultAsSuccess()
            {
                const string inputString = "{ 'Property Type': 'patent', 'Country': 'AU'}";
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithEdeIdentifier("MYAC")
                        .WithCustomColumnResolverResult(true);

                var data = new JArray(JToken.Parse(inputString));
                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();
                var r = f.Subject.From(data, "input.csv", fields);

                Assert.Equal(r.Result, "success");
                Assert.NotNull(r.CpaXml);
                Assert.NotNull(r.InputFileName);
            }

            [Fact]
            public void ReturnsResultWithErrors()
            {
                const string inputString = "{ 'Property Type': 'patent', 'Country': 'AU', 'A new column' : 'A'}";
                var f = new ConvertToCpaXmlFixture(Db)
                        .WithEdeIdentifier("MYAC")
                        .WithCustomColumnResolverResult(false);

                var data = new JArray(JToken.Parse(inputString));
                var fields = data[0].Select(_ => ((JProperty) _).Name).ToArray();

                var r = f.Subject.From(data, "input.csv", fields);

                Assert.Equal(r.Result, "duplicate-mapping");
                Assert.NotEmpty(r.Errors);
            }

            [Fact]
            public void ReturnValidationErrorForNoCases()
            {
                var f = new ConvertToCpaXmlFixture(Db)
                    .WithEdeIdentifier("MYAC");

                var fields = new string[] { };
                var r = f.Subject.From(JToken.Parse("[{}]"), "input.csv", fields);

                Assert.Equal("no-cases", r.Result);
            }
        }
    }
}