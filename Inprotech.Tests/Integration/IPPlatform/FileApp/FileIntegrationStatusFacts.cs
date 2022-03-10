using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.IPPlatform.FileApp;
using Inprotech.Integration.IPPlatform.FileApp.Models;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;
using FileCaseEntity = InprotechKaizen.Model.Integration.FileCase;

namespace Inprotech.Tests.Integration.IPPlatform.FileApp
{
    public class FileIntegrationStatusFacts : FactBase
    {
        readonly IFileIntegrationEvent _fileIntegrationEvent = Substitute.For<IFileIntegrationEvent>();
        readonly FileSettings _fileSettings = new FileSettings();

        [Theory]
        [InlineData(IpTypes.PatentPostPct)]
        [InlineData(IpTypes.DirectPatent)]
        [InlineData(IpTypes.TrademarkDirect)]
        public async Task ShouldAddOrUpdateFileCaseRecordForEachMatchingCountrySelection(string ipType)
        {
            var subject = new FileIntegrationStatus(Db, _fileIntegrationEvent);

            var parentCaseId = Fixture.Integer();
            var auCaseId = Fixture.Integer();
            var usCaseId = Fixture.Integer();
            var cnCaseId = Fixture.Integer();

            var inprotechSelection = new FileCaseModel
            {
                ParentCaseId = parentCaseId.ToString(),
                CountrySelections = new[]
                {
                    new CountrySelection
                    {
                        CaseId = auCaseId,
                        Code = "AU"
                    },
                    new CountrySelection
                    {
                        CaseId = usCaseId,
                        Code = "US"
                    },
                    new CountrySelection
                    {
                        CaseId = cnCaseId,
                        Code = "CN"
                    }
                }
            };

            var selectionResultFromFile = new FileCase
            {
                IpType = ipType,
                Id = parentCaseId.ToString(),
                Countries = new List<Country>
                {
                    new Country
                    {
                        Code = "AU"
                    },
                    new Country
                    {
                        Code = "SG"
                    },
                    new Country
                    {
                        Code = "CN"
                    }
                }
            };

            await subject.Update(_fileSettings, inprotechSelection, selectionResultFromFile);

            _fileIntegrationEvent.Received(0).AddOrUpdate(Arg.Any<int>(), _fileSettings)
                                 .IgnoreAwaitForNSubstituteAssertion();

            var db = Db.Set<FileCaseEntity>();

            Assert.Equal(parentCaseId, db.Single(_ => _.ParentCaseId == null && _.IpType == ipType).CaseId);
            Assert.Equal(auCaseId, db.Single(_ => _.ParentCaseId == parentCaseId && _.IpType == ipType && _.CountryCode == "AU").CaseId);
            Assert.Equal(cnCaseId, db.Single(_ => _.ParentCaseId == parentCaseId && _.IpType == ipType && _.CountryCode == "CN").CaseId);
        }

        [Theory]
        [InlineData(IpTypes.PatentPostPct)]
        [InlineData(IpTypes.DirectPatent)]
        [InlineData(IpTypes.TrademarkDirect)]
        public async Task ShouldAddOrUpdateFileIntegrationEventForEachMatchingCountrySelection(string ipType)
        {
            var subject = new FileIntegrationStatus(Db, _fileIntegrationEvent);

            var parentCaseId = Fixture.Integer();
            var auCaseId = Fixture.Integer();
            var usCaseId = Fixture.Integer();
            var cnCaseId = Fixture.Integer();

            var inprotechSelection = new FileCaseModel
            {
                ParentCaseId = parentCaseId.ToString(),
                CountrySelections = new[]
                {
                    new CountrySelection
                    {
                        CaseId = auCaseId,
                        Code = "AU"
                    },
                    new CountrySelection
                    {
                        CaseId = usCaseId,
                        Code = "US"
                    },
                    new CountrySelection
                    {
                        CaseId = cnCaseId,
                        Code = "CN"
                    }
                }
            };

            var selectionResultFromFile = new FileCase
            {
                IpType = ipType,
                Id = parentCaseId.ToString(),
                Countries = new List<Country>
                {
                    new Country
                    {
                        Code = "AU"
                    },
                    new Country
                    {
                        Code = "SG"
                    },
                    new Country
                    {
                        Code = "CN"
                    }
                }
            };

            _fileSettings.FileIntegrationEvent = Fixture.Integer();

            await subject.Update(_fileSettings, inprotechSelection, selectionResultFromFile);

            _fileIntegrationEvent.Received(1).AddOrUpdate(auCaseId, _fileSettings)
                                 .IgnoreAwaitForNSubstituteAssertion();

            _fileIntegrationEvent.Received(1).AddOrUpdate(cnCaseId, _fileSettings)
                                 .IgnoreAwaitForNSubstituteAssertion();

            var db = Db.Set<FileCaseEntity>();

            Assert.Equal(parentCaseId, db.Single(_ => _.ParentCaseId == null && _.IpType == ipType).CaseId);
            Assert.Equal(auCaseId, db.Single(_ => _.ParentCaseId == parentCaseId && _.IpType == ipType && _.CountryCode == "AU").CaseId);
            Assert.Equal(cnCaseId, db.Single(_ => _.ParentCaseId == parentCaseId && _.IpType == ipType && _.CountryCode == "CN").CaseId);
        }
    }
}