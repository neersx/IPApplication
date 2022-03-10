using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases.Details;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases.Details
{
    public class CaseViewOfficialNumbersControllerFacts : FactBase
    {
        class CaseViewOfficialNumbersControllerFixture : IFixture<CaseViewOfficialNumbersController>
        {
            readonly ICaseViewOfficialNumbers _caseViewOfficialNumbers;
            readonly IExternalPatentInfoLinkResolver _externalPatentInfoLink;

            public CaseViewOfficialNumbersControllerFixture(InMemoryDbContext db)
            {
                CaseKey = Fixture.Integer();
                _caseViewOfficialNumbers = Substitute.For<ICaseViewOfficialNumbers>();
                _externalPatentInfoLink = Substitute.For<IExternalPatentInfoLinkResolver>();
                _externalPatentInfoLink.ResolveOfficialNumbers(Arg.Any<string>(), Arg.Any<int[]>()).Returns(new Dictionary<int, Uri>());
                Subject = new CaseViewOfficialNumbersController(_caseViewOfficialNumbers, _externalPatentInfoLink, db);
            }

            public int CaseKey { get; }

            public CaseViewOfficialNumbersController Subject { get; }

            public CaseViewOfficialNumbersControllerFixture WithIpOfficeNumbers(params int?[] docItemId)
            {
                var officialNumbers = new List<OfficialNumbersData>
                {
                    new OfficialNumbersData
                    {
                        CaseId = CaseKey,
                        DateInForce = Fixture.Today(),
                        DisplayPriority = Fixture.Short(),
                        EventDate = Fixture.Today(),
                        IsCurrent = true,
                        IssuedByIpOffice = true
                    }
                };
                if (docItemId.Any())
                {
                    officialNumbers.AddRange(docItemId.Select(_ => new OfficialNumbersData
                    {
                        CaseId = CaseKey,
                        DateInForce = Fixture.Today(),
                        DisplayPriority = Fixture.Short(),
                        EventDate = Fixture.Today(),
                        IsCurrent = true,
                        IssuedByIpOffice = true,
                        DocItemId = _
                    }).ToArray());
                }

                _caseViewOfficialNumbers.IpOfficeNumbers(CaseKey).Returns(officialNumbers.AsDbAsyncEnumerble());
                return this;
            }

            public CaseViewOfficialNumbersControllerFixture WithOtherNumbers()
            {
                _caseViewOfficialNumbers.OtherNumbers(CaseKey).Returns(new[]
                {
                    new OfficialNumbersData
                    {
                        CaseId = CaseKey,
                        DateInForce = Fixture.Today(),
                        DisplayPriority = Fixture.Short(),
                        EventDate = Fixture.Today(),
                        IsCurrent = true,
                        IssuedByIpOffice = false
                    }
                }.AsDbAsyncEnumerble());
                return this;
            }

            public CaseViewOfficialNumbersControllerFixture WithExternalPatenetInfoLink(Dictionary<int, Uri> externalLinks)
            {
                _externalPatentInfoLink.ResolveOfficialNumbers(Arg.Any<string>(), Arg.Any<int[]>()).Returns(externalLinks);
                return this;
            }
        }

        [Fact]
        public async Task GetIpOfficeNumbers()
        {
            var f = new CaseViewOfficialNumbersControllerFixture(Db).WithIpOfficeNumbers();
            var r = await f.Subject.GetIpOfficeNumbers(f.CaseKey, new CommonQueryParameters());
            Assert.True(r.Count() == 1);
        }

        [Fact]
        public async Task GetIpOfficeNumbersReturnsValidExternalLink()
        {
            var docitemId = Fixture.Integer();
            var externalLink = new Uri("http://www.google.com");
            var f = new CaseViewOfficialNumbersControllerFixture(Db)
                    .WithIpOfficeNumbers(docitemId, docitemId + 1)
                    .WithExternalPatenetInfoLink(new Dictionary<int, Uri>
                    {
                        {docitemId, externalLink}
                    });
            var r = (await f.Subject.GetIpOfficeNumbers(f.CaseKey, new CommonQueryParameters())).ToArray();
            Assert.True(r.Length == 3);
            Assert.True(r.Single(_ => _.DocItemId == docitemId).ExternalInfoLink == externalLink);
            Assert.Null(r.Single(_ => _.DocItemId == docitemId + 1).ExternalInfoLink);
        }

        [Fact]
        public async Task GetOtherNumbers()
        {
            var f = new CaseViewOfficialNumbersControllerFixture(Db).WithOtherNumbers();
            var r = await f.Subject.GetOtherNumbers(f.CaseKey, new CommonQueryParameters());
            Assert.True(r.Count() == 1);
        }
    }
}