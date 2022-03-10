using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using NUnit.Framework;

namespace Inprotech.Tests.Integration.EndToEnd.Portfolio.PriorArt
{
    class PriorArtDataSetup : DbSetup
    {
        [SetUp]
        public dynamic CreateData(bool withCase = true, bool withAssociatedArt = false, bool withAssociatedSource = false, bool withLinkedCases = false)
        {
            var fixture = new
            {
                Number = "1780036",
                Country = "EP",
                KindCode = "A3"
            };

            var data = Do(db =>
            {
                var ctx = db.DbContext;

                var country = ctx.Set<Country>().Single(_ => _.Id == fixture.Country);

                var sourceType = db.InsertWithNewId(new TableCode
                {
                    TableTypeId = (short) TableTypes.PriorArtSource,
                    Name = RandomString.Next(20)
                });

                var priorArtStatusCode = db.InsertWithNewId(new TableCode
                {
                    TableTypeId = (short) TableTypes.PriorArtCaseStatus,
                    Name = RandomString.Next(20)
                });

                var c = CreateCase(db, fixture.Number, fixture.Country);

                var source = CreateSource(db, sourceType, country);

                CreateActivity(db, source.Id);

                var nonPatentLiterature = db.InsertWithNewId(new InprotechKaizen.Model.PriorArt.PriorArt
                {
                    IsSourceDocument = false,
                    IsIpDocument = false,
                    Description = "Non Patent Literature Description",
                    CountryId = country.Id,
                    Title = "Literature-Title",
                    Name = "Literature-Inventor",
                    Publisher = "Literature-Publisher",
                    PublishedDate = Fixture.PastDate()
                });

                var ipo = db.InsertWithNewId(new InprotechKaizen.Model.PriorArt.PriorArt(sourceType, country)
                {
                    IsSourceDocument = false,
                    IsIpDocument = true,
                    Description = "IPO" + Fixture.String(10),
                    Name = Fixture.String(10),
                    OfficialNumber = Fixture.AlphaNumericString(10),
                    Kind = Fixture.String(2),
                    Title = Fixture.String(10),
                    RefDocumentParts = Fixture.String(10),
                    Abstract = Fixture.String(10),
                    Citation = Fixture.String(10),
                    Comments = Fixture.String(10)
                });

                db.InsertWithNewId(new InprotechKaizen.Model.PriorArt.PriorArt(sourceType, country)
                {
                    IsSourceDocument = false,
                    CountryId = country.Id,
                    OfficialNumber = fixture.Number,
                    Kind = fixture.KindCode,
                    Comments = "Comments",
                    Description = "Desc"
                });

                if (withAssociatedArt)
                {
                    var associatedIpArt = db.InsertWithNewId(new InprotechKaizen.Model.PriorArt.PriorArt(sourceType, country)
                    {
                        IsSourceDocument = false,
                        CountryId = country.Id,
                        OfficialNumber = $"A{Fixture.AlphaNumericString(9)}",
                        Kind = fixture.KindCode,
                        Comments = Fixture.Prefix("IPO-Comments-"),
                        Description = "IPO-Description",
                        IsIpDocument = true
                    });
                    source.CitedPriorArt.Add(associatedIpArt);

                    var associatedNpl = db.InsertWithNewId(new InprotechKaizen.Model.PriorArt.PriorArt(sourceType, country)
                    {
                        IsSourceDocument = false,
                        CountryId = country.Id,
                        OfficialNumber = $"X{Fixture.AlphaNumericString(9)}",
                        Kind = fixture.KindCode,
                        Comments = Fixture.Prefix("NPL-Comments-"),
                        Description = "NPL-Description",
                        IsIpDocument = false
                    });
                    source.CitedPriorArt.Add(associatedNpl);
                }

                if (withAssociatedSource)
                {
                    ipo.SourceDocuments.Add(source);
                    nonPatentLiterature.SourceDocuments.Add(source);
                }

                if (withLinkedCases)
                {
                    var result1 = db.InsertWithNewId(new CaseSearchResult(c.Id, ipo.Id, true));
                    result1.StatusId = priorArtStatusCode.Id;
                    c.CurrentOfficialNumber = Fixture.AlphaNumericString(5);
                }

                if (withCase)
                {
                    db.Insert(new CaseSearchResult(c.Id, source.Id, true));
                }

                var family = db.InsertWithNewId(new Family {Name = Fixture.AlphaNumericString(20)}, true);
                var familyMember = db.InsertWithNewId(new Case
                {
                    Irn = RandomString.Next(20),
                    Title = RandomString.Next(20),
                    Type = ctx.Set<CaseType>().Single(_ => _.Code == "A"),
                    Country = ctx.Set<Country>().Single(_ => _.Id == country.Id),
                    PropertyType = ctx.Set<PropertyType>().Single(_ => _.Code == "P"),
                    Family = family
                });
                var instructor = new NameBuilder(db.DbContext).CreateClientIndividual();
                var instructorNameType = db.DbContext.Set<NameType>().Single(_ => _.NameTypeCode == KnownNameTypes.Instructor);
                familyMember.CaseNames.Add(new CaseName(familyMember, instructorNameType, instructor, 0));

                var caseList = db.InsertWithNewId(new CaseList {Name = RandomString.Next(50), Description = Fixture.String(254)}, true);
                var caseListMember = db.InsertWithNewId(new Case
                {
                    Irn = RandomString.Next(20),
                    Title = RandomString.Next(20),
                    Type = ctx.Set<CaseType>().Single(_ => _.Code == "A"),
                    Country = ctx.Set<Country>().Single(_ => _.Id == country.Id),
                    PropertyType = ctx.Set<PropertyType>().Single(_ => _.Code == "P")
                });
                db.Insert(new CaseListMember(caseList.Id, caseListMember.Id, true));

                var nameType = ctx.Set<NameType>().First();
                var name = new NameBuilder(ctx).CreateClientIndividual("link");
                var nameSearchCase = db.InsertWithNewId(new Case
                {
                    Irn = RandomString.Next(20),
                    Title = RandomString.Next(20),
                    Type = ctx.Set<CaseType>().Single(_ => _.Code == "A"),
                    Country = ctx.Set<Country>().Single(_ => _.Id == country.Id),
                    PropertyType = ctx.Set<PropertyType>().Single(_ => _.Code == "P")
                });
                db.Insert(new CaseName(nameSearchCase, nameType, name, 0));

                ctx.SaveChanges();
                return (Case: c,
                        Source: source,
                        NonPatentLiterature: nonPatentLiterature,
                        Ipo: ipo,
                        Family: family,
                        CaseList: caseList,
                        PriorArtStatusCode: priorArtStatusCode,
                        Name: name,
                        NameType: nameType, 
                        CaseFamilyMember: familyMember);
            });

            return new
            {
                data.Case,
                data.Source,
                data.NonPatentLiterature,
                data.Ipo,
                searchOption = fixture,
                data.Family,
                data.CaseList,
                data.Name,
                data.NameType,
                data.PriorArtStatusCode,
                data.CaseFamilyMember
            };
        }

        public Case CreateCase(DbSetup db, string number, string countryId)
        {
            var country = db.DbContext.Set<Country>().Single(_ => _.Id == countryId);

            var @case = db.InsertWithNewId(new Case
            {
                Irn = RandomString.Next(20),
                Title = RandomString.Next(20),
                Type = db.DbContext.Set<CaseType>().Single(_ => _.Code == "A"),
                Country = db.DbContext.Set<Country>().Single(_ => _.Id == country.Id),
                PropertyType = db.DbContext.Set<PropertyType>().Single(_ => _.Code == "P")
            });
            var nt = db.DbContext.Set<NumberType>().Single(_ => _.NumberTypeCode == "A");
            @case.OfficialNumbers.Add(new OfficialNumber(nt, @case, number));
            @case.CurrentOfficialNumber = @case.OfficialNumbers.First().Number;

            return @case;
        }

        public InprotechKaizen.Model.PriorArt.PriorArt CreateSource(DbSetup db, TableCode sourceType, Country country)
        {
            var source = db.InsertWithNewId(new InprotechKaizen.Model.PriorArt.PriorArt(sourceType, country)
            {
                IsSourceDocument = true,
                Description = "Source-Desc"
            });

            return source;
        }

        Activity CreateActivity(DbSetup db, int? sourceId)
        {
            var activity = db.InsertWithNewId(new Activity
            {
                PriorartId = sourceId,
                ActivityCategory = db.InsertWithNewId(new TableCode {TableTypeId = (short) TableTypes.ContactActivityCategory, Name = RandomString.Next(20)}),
                ActivityType = db.InsertWithNewId(new TableCode {TableTypeId = (short) TableTypes.ContactActivityType, Name = RandomString.Next(20)}),
                Summary = RandomString.Next(20)
            });

            db.Insert(new ActivityAttachment(activity.Id, 0) {AttachmentName = RandomString.Next(20), FileName = "C:\\'" + RandomString.Next(20)});

            return activity;
        }
    }
}