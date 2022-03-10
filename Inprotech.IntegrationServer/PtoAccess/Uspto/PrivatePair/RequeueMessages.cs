using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Integration.Innography.PrivatePair;
using Newtonsoft.Json;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public interface IRequeueMessageDates
    {
        List<(DateTime startDate, DateTime endDate)> GetDateRanges(Session session);
    }

    class RequeueMessageDates : IRequeueMessageDates
    {
        readonly IFileSystem _fileSystem;
        readonly IArtifactsLocationResolver _artifactsLocationResolver;

        public RequeueMessageDates(IFileSystem fileSystem,
                               IArtifactsLocationResolver artifactsLocationResolver
        )
        {
            _fileSystem = fileSystem;
            _artifactsLocationResolver = artifactsLocationResolver;
        }

        public List<(DateTime startDate, DateTime endDate)> GetDateRanges(Session session)
        {
            var uniqueOrderedDates = ExtractOrderedDates(session);
            return CreateDateRangeSet(uniqueOrderedDates);
        }

        List<DateTime> ExtractOrderedDates(Session session)
        {
            List<DateTime> dates = new List<DateTime>();
            var applicationFolderLocation = _artifactsLocationResolver.Resolve(session, "applications");

            var applications = _fileSystem.Folders(applicationFolderLocation).Select(Path.GetFileName).ToList();

            foreach (var application in applications)
            {
                var applicationDownload = new ApplicationDownload
                {
                    CustomerNumber = session.CustomerNumber,
                    ApplicationId = application,
                    SessionId = session.Id,
                    SessionName = session.Name,
                    SessionRoot = session.Root,
                    Number = application.GetApplicationNumber()
                };

                var applicationFolderLocation2 = _artifactsLocationResolver.Resolve(applicationDownload);
                foreach (var messageFile in _fileSystem.Files(applicationFolderLocation2, "*.json"))
                {
                    var message = JsonConvert.DeserializeObject<Message>(_fileSystem.ReadAllText(messageFile));
                    if (!string.IsNullOrEmpty(message?.Meta?.EventTimeStamp))
                    {
                        dates.Add(message.Meta.EventDateParsed.Date);
                    }
                }
            }

            return dates.Distinct().OrderBy(_ => _).ToList();
        }

        List<(DateTime startDate, DateTime endDate)> CreateDateRangeSet(List<DateTime> dates)
        {
            List<(DateTime, DateTime)> sortedDates = new List<(DateTime, DateTime)>();
            int total = dates.Count;
            var start = dates[0];
            for (int i = 0; i < total - 1; i++)
            {
                if (dates[i].AddDays(1) == dates[i + 1])
                {
                    continue;
                }

                sortedDates.Add((start, dates[i]));
                start = dates[i + 1];
            }

            sortedDates.Add((start, dates[total - 1]));
            return sortedDates;
        }
    }
}