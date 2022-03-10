using System.Linq;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Search.Export;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Integration.Jobs;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Activities
{
    public class VerificationRequiredFacts
    {
        public class FromInnographyMethod : FactBase
        {
            readonly DataDownload _d1 = new DataDownload
            {
                Case = new EligibleCase
                {
                    ApplicationNumber = Fixture.String(),
                    PublicationNumber = Fixture.String(),
                    RegistrationNumber = Fixture.String(),
                    CaseKey = Fixture.Integer(),
                    PropertyType = KnownPropertyTypes.Patent
                }
            };

            readonly DataDownload _d2 = new DataDownload
            {
                Case = new EligibleCase
                {
                    ApplicationNumber = Fixture.String(),
                    PublicationNumber = Fixture.String(),
                    RegistrationNumber = Fixture.String(),
                    CaseKey = Fixture.Integer(),
                    PropertyType = KnownPropertyTypes.TradeMark
                }
            };

            [Theory]
            [InlineData(KnownPropertyTypes.Patent)]
            [InlineData(KnownPropertyTypes.TradeMark)]
            public async Task DataDownloadExtendedWithResultsIfMatched(string propertyType)
            {
                var dataDownload = propertyType == KnownPropertyTypes.Patent ? _d1 : _d2;
               
                var fixture = new VerificationRequiredFixture(Db)
                    .WithDataToDownload(dataDownload);

                var r = (ActivityGroup)await fixture.Subject.FromInnography(Fixture.String());
                var activities = ((ActivityGroup) r.Items.Single()).Items.ToArray();
                Assert.Equal(activities.Length, 2);

                var a1 = (SingleActivity) activities[0];

                var tempStorageId = a1.Arguments[0];
                Assert.NotNull(tempStorageId);

                var data = Db.Set<InprotechKaizen.Model.TempStorage.TempStorage>().FirstOrDefault(_ => _.Id == (long) tempStorageId)?.Value;

                Assert.NotNull(data);
                var downLoadData = JsonConvert.DeserializeObject<DataDownload[]>(data);
                Assert.Equal(1, downLoadData.Length);
                Assert.Equal(downLoadData[0].Case.CaseKey, dataDownload.Case.CaseKey);

                Assert.Equal(a1.Name, "Process");
                Assert.Equal(a1.Type.Name, propertyType == KnownPropertyTypes.Patent ? typeof(IPatentsVerification).Name : typeof(ITrademarksVerification).Name);
                Assert.Equal(0, a1.ExceptionFilters.Length);

                var a2 = (SingleActivity) activities[1];
                Assert.Equal(a2.Name, "CleanUpTempStorage");
                Assert.Equal(r.Items.Single().ExceptionFilters[0].Type.Name , "ErrorLogger");
            }
        }

        public class VerificationRequiredFixture : IFixture<VerificationRequired>
        {
            public VerificationRequiredFixture(InMemoryDbContext db)
            {
                BufferedStringReader = Substitute.For<IBufferedStringReader>();

                Subject = new VerificationRequired(BufferedStringReader, new JobArgsStorage(db));
            }

            public IBufferedStringReader BufferedStringReader { get; set; }
            public VerificationRequired Subject { get; }

            public VerificationRequiredFixture WithDataToDownload(params DataDownload[] dataDownloads)
            {
                BufferedStringReader.Read(Arg.Any<string>())
                                    .Returns(JsonConvert.SerializeObject(dataDownloads));

                return this;
            }
        }
    }
}