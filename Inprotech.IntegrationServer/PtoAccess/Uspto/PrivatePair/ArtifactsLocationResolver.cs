using System;
using System.Collections.Generic;
using System.IO;
using Inprotech.Infrastructure.IO;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class ArtifactsLocationResolver : IArtifactsLocationResolver
    {
        readonly IResolveScheduleExecutionRootFolder _rootResolver;

        public ArtifactsLocationResolver(IResolveScheduleExecutionRootFolder rootResolver)
        {
            _rootResolver = rootResolver;
        }

        public string Resolve(Session session, string fileName = "")
        {
            if (session == null) throw new ArgumentNullException(nameof(session));

            var parts = new List<string>(new[] { _rootResolver.Resolve(session.Id) });

            if (!string.IsNullOrWhiteSpace(fileName))
                parts.Add(fileName);

            return Path.Combine(parts.ToArray());
        }

        public string Resolve(ApplicationDownload application, string fileName = "")
        {
            if (application == null) throw new ArgumentNullException(nameof(application));
            const string applicationFolder = "applications";

            var parts = new List<string>(new[] { _rootResolver.Resolve(application.SessionId), applicationFolder });

            if (!string.IsNullOrWhiteSpace(application.ApplicationId))
                parts.Add(StorageHelpers.EnsureValid(application.ApplicationId));

            if (!string.IsNullOrWhiteSpace(fileName))
                parts.Add(fileName);

            return Path.Combine(parts.ToArray());
        }

        public string ResolveFiles(ApplicationDownload application, string fileName = "")
        {
            const string filesFolder = "files";
            var parts = new List<string> { Resolve(application, filesFolder) };

            if (!string.IsNullOrWhiteSpace(fileName))
                parts.Add(fileName);

            return Path.Combine(parts.ToArray());
        }

        public string ResolveBiblio(ApplicationDownload application)
        {
            return ResolveFiles(application, KnownFileNames.BiblioFileName(application));
        }
    }
}
