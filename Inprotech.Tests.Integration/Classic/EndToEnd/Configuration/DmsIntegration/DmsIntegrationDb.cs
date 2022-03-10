using System;
using System.Linq;
using Inprotech.Integration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Settings;
using Inprotech.Tests.Integration.Classic.EndToEnd.CaseComparison.Extensions;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using Newtonsoft.Json;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.Configuration.DmsIntegration
{
    public class DmsIntegrationDb : IntegrationDbSetup
    {
        public DmsIntegrationDb WithDisabled()
        {
            Do(x =>
            {
                var enabled = x.IntegrationDbContext.Set<ConfigSetting>().SingleOrDefault(_ => _.Key == "DmsIntegration.PrivatePairIntegrationEnabled");
                var location = x.IntegrationDbContext.Set<ConfigSetting>().SingleOrDefault(_ => _.Key == "DmsIntegration.PrivatePairLocation");
                if (enabled != null) enabled.Value = false.ToString();
                if (location != null) location.Value = string.Empty;

                x.IntegrationDbContext.SaveChanges();
            });
            return this;
        }

        public int SetupDocument()
        {
            var doc = Insert(new Document
            {
                ApplicationNumber = Fixture.Prefix("1234casecomparison"),
                Status = DocumentDownloadStatus.Downloaded,
                MailRoomDate = DateTime.Now,
                Source = DataSourceType.UsptoPrivatePair,
                FileWrapperDocumentCode = "A",
                DocumentDescription = RandomString.Next(10)
            }.WithDefaults());
            return doc.Id;
        }

        public long SetupJob()
        {
            var job = IntegrationDbContext.Set<Job>().Single(_ => _.Type == "SendPrivatePairDocumentsToDms");
            var execution = Insert(new JobExecution
            {
                Job = job,
                Started = DateTime.Now,
                Status = Status.Completed,
                State = JsonConvert.SerializeObject(new object())
            });

            return execution.Id;
        }

        public void Setup()
        {
            var docs = IntegrationDbContext.Set<Document>().Where(_ => _.Source == DataSourceType.UsptoPrivatePair).ToList();
            foreach (var doc in docs)
            {
                IntegrationDbContext.Set<Document>().Remove(doc);
            }

            var job = IntegrationDbContext.Set<Job>().Single(j => j.Type == "SendPrivatePairDocumentsToDms");
            job.IsActive = false;
            var jobExecutions = IntegrationDbContext.Set<JobExecution>().Where(_ => _.JobId == job.Id && _.Started > job.NextRun);

            foreach (var item in jobExecutions)
            {
                IntegrationDbContext.Set<JobExecution>().Remove(item);
            }

            IntegrationDbContext.SaveChanges();
        }
    }
}