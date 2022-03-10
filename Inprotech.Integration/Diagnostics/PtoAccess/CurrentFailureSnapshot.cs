using System;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Integration.Schedules;
using Newtonsoft.Json;

namespace Inprotech.Integration.Diagnostics.PtoAccess
{
    public class CurrentFailureSnapshot : IDiagnosticsArtefacts
    {
        readonly IFailureSummaryProvider _failureSummaryProvider;
        readonly IFileSystem _fileSystem;
        readonly ICompressionHelper _compressionHelper;

        const string ArtefactName = "CurrentFailureSnapshot.json";
        const string FailedItemArtefacts = "FailedItemArtefacts.zip";
        const string UnrecoverableArtifacts = "UnrecoverableArtifacts.zip";
        const string FailedItemArtefactIndexLists = "FailedItemArtefactIndexLists.zip";

        public CurrentFailureSnapshot(IFailureSummaryProvider failureSummaryProvider, IFileSystem fileSystem, ICompressionHelper compressionHelper)
        {
            _failureSummaryProvider = failureSummaryProvider;
            _fileSystem = fileSystem;
            _compressionHelper = compressionHelper;
        }

        public string Name => ArtefactName;

        public async Task Prepare(string basePath)
        {
            var allDataSources = Enum.GetValues(typeof(DataSourceType))
                                     .Cast<DataSourceType>()
                                     .ToArray();

            var r = _failureSummaryProvider.RecoverableItemsByDataSource(allDataSources, ArtifactInclusion.Include).ToArray();
            var failedItemArtifactArchive = Path.Combine(basePath, FailedItemArtefacts);
            var relevantIndexListArchive = Path.Combine(basePath, FailedItemArtefactIndexLists);
            var unrecoverableArtifacts = Path.Combine(basePath, UnrecoverableArtifacts);

            var artifactTypeMap = Enum.GetValues(typeof(ArtifactType)).Cast<ArtifactType>()
                                      .ToDictionary(k => k, v => Enum.GetName(typeof(ArtifactType), v));

            foreach (var execution in r.SelectMany(_ => _.IndexList))
            {
                if (execution.ExecutionArtefact == null)
                    continue;

                var entryName =
                    string.Format("EA-{0}-{1:s}.zip", execution.ExecutionId, execution.Started);

                await _compressionHelper.AddToArchive(
                                                      relevantIndexListArchive,
                                                      new MemoryStream(execution.ExecutionArtefact), entryName);
            }

            foreach (dynamic unrecoverable in await _failureSummaryProvider.AllUnrecoverableArtifacts(ArtifactInclusion.Include))
            {
                var txtFileName = $"UA-{unrecoverable.scheduleExecutionId}-{unrecoverable.lastUpdate:yyyy-dd-M--HH-mm-ss}.txt";
                var txtAbsolutePath = _fileSystem.AbsolutePath(txtFileName);

                using (var ci = _fileSystem.OpenWrite(txtAbsolutePath))
                {
                    byte[] data = Encoding.UTF8.GetBytes(unrecoverable.artifact);
                    await ci.WriteAsync(data, 0, data.Length);
                    ci.Close();
                }

                await _compressionHelper.AddToArchive(unrecoverableArtifacts,
                                                      txtAbsolutePath);
                _fileSystem.DeleteFile(txtFileName);
            }

            foreach (var failedItem in r.SelectMany(_ => _.Cases))
            {
                if (failedItem.Artifact == null)
                    continue;

                var entryName =
                    string.Format("EA-{3}-Schedule-{0}-{1}-{2}.zip", failedItem.ScheduleId,
                                  artifactTypeMap[failedItem.ArtifactType], failedItem.ArtifactId,
                                  failedItem.Id);

                await _compressionHelper.AddToArchive(
                                                      failedItemArtifactArchive,
                                                      new MemoryStream(failedItem.Artifact), entryName);
            }

            _fileSystem.WriteAllText(
                                     Path.Combine(basePath, ArtefactName),
                                     JsonConvert.SerializeObject(r, Formatting.Indented));
        }
    }
}